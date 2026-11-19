pragma ComponentBehavior: Bound
import QtQuick
import QtCore
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons as Commons
import "DockModel.js" as Model

Item {
    id: root

    property var settingsScreen: null
    readonly property alias strings: strings
    readonly property alias currentOnly: preferences.currentOnly
    readonly property alias autoHide: preferences.autoHide
    readonly property string position: Model.normalizePosition(preferences.position)
    readonly property var positions: Model.positions
    readonly property string focusedAddress: Hyprland.activeToplevel ? Hyprland.activeToplevel.address : ""
    readonly property var installedApps: DesktopEntries.applications.values
    readonly property var terminalApps: installedApps.filter(entry => entry.runInTerminal || entry.execString.includes("--app-id="))
    readonly property var pinnedIds: {
        try {
            return Model.pinIds(preferences.pinOrder
                ? JSON.parse(preferences.pinOrder) : JSON.parse(nativeConfig.text()).dock?.pinned);
        } catch (error) {
            return [];
        }
    }
    readonly property var windows: {
        // Keep desktop-entry lookup reactive when an app is installed or removed.
        root.installedApps.length;
        const result = [];
        for (const toplevel of Hyprland.toplevels.values) {
            const wayland = toplevel.wayland;
            const info = toplevel.lastIpcObject;
            const workspace = toplevel.workspace;
            if (!workspace || wayland?.parent || info?.mapped === false)
                continue;
            const appId = wayland?.appId || info?.class || info?.initialClass || "";
            const entry = root.entryForWindow(appId, info?.initialClass);
            const minimized = workspace.name === "special:minimized";
            const sourceTag = minimized && Array.isArray(info?.tags)
                ? info.tags.find(tag => /^omarchy-minimized-from-[1-9][0-9]*$/.test(tag)) : null;
            result.push({
                key: entry ? entry.id : "window:" + (appId || toplevel.address),
                desktopId: entry ? entry.id : "",
                appId: appId,
                wayland: wayland,
                title: toplevel.title,
                address: toplevel.address,
                workspaceId: workspace.id,
                minimized: minimized,
                minimizedFrom: sourceTag ? Number(sourceTag.split("-").pop()) : null
            });
        }
        return result;
    }

    readonly property string configDirectory: (Quickshell.env("XDG_CONFIG_HOME")
        || Quickshell.env("HOME") + "/.config") + "/omarchy"

    Commons.Translations {
        id: strings
        directory: Qt.resolvedUrl("i18n")
    }

    Settings {
        id: preferences
        location: "file://" + root.configDirectory + "/lumadock.ini"
        property string pinOrder: ""
        property bool currentOnly: false
        property bool autoHide: false
        property string position: "bottom"
    }

    FileView {
        id: nativeConfig
        path: preferences.pinOrder ? "" : root.configDirectory + "/shell.json"
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: Qt.callLater(function() {
        if (!preferences.pinOrder)
            root.savePins(root.pinnedIds);
    })

    function entryForWindow(appId, initialClass) {
        const entry = (appId && DesktopEntries.heuristicLookup(appId))
            || (initialClass && DesktopEntries.heuristicLookup(initialClass));
        if (entry)
            return entry;
        if (!appId)
            return null;
        const flag = "--app-id=" + appId;
        const terminalCommand = appId.startsWith("org.omarchy.") ? appId.slice(12) : "";
        return root.terminalApps.find(candidate => candidate.execString.split(/\s+/).includes(flag)
            || (terminalCommand && candidate.runInTerminal
                && String(candidate.command[0] || "").split("/").pop() === terminalCommand)) || null;
    }

    function entryLabel(item) {
        return String(DesktopEntries.byId(item.desktopId)?.name || item.name
            || strings.t("unknownApp")).slice(0, 160);
    }

    function iconSource(desktopId, fallback) {
        const entry = DesktopEntries.byId(desktopId);
        if (entry?.icon?.startsWith("/"))
            return Commons.Util.fileUrl(entry.icon);
        const icon = entry?.icon || fallback;
        // Wayland app IDs can be supplied by any app; only try theme icon names.
        return icon && /^[a-zA-Z0-9_.+-]+$/.test(icon) ? Quickshell.iconPath(icon, true) : "";
    }

    function savePins(pins) {
        preferences.pinOrder = JSON.stringify(pins);
        preferences.setValue("pinOrder", preferences.pinOrder);
        preferences.sync();
    }

    function setPinned(desktopId, pinned) {
        const next = root.pinnedIds.filter(id => id !== desktopId);
        if (pinned && !root.pinnedIds.includes(desktopId) && DesktopEntries.byId(desktopId))
            root.savePins([...next, desktopId]);
        else if (!pinned)
            root.savePins(next);
    }

    function movePin(desktopId, offset) {
        root.savePins(Model.movePin(root.pinnedIds, desktopId, offset));
    }

    function setCurrentOnly(value) {
        preferences.currentOnly = value;
        preferences.setValue("currentOnly", value);
        preferences.sync();
    }

    function setAutoHide(value) {
        preferences.autoHide = value;
        preferences.setValue("autoHide", value);
        preferences.sync();
    }

    function setPosition(value) {
        const position = Model.normalizePosition(value);
        preferences.position = position;
        preferences.setValue("position", position);
        preferences.sync();
    }

    function activate(item, workspaceId, specialId) {
        if (!item.windows.length) {
            const entry = DesktopEntries.byId(item.desktopId);
            if (entry)
                Quickshell.execDetached(Model.launchCommand(entry));
            return;
        }
        const window = Model.pickWindow(item.windows, root.focusedAddress, workspaceId, specialId);
        root.activateWindow(window, workspaceId);
    }

    function activateWindow(window, workspaceId) {
        const selector = windowSelector(window);
        if (!selector) {
            window.wayland?.activate();
            return;
        }
        if (window.minimized && Number.isInteger(workspaceId) && workspaceId > 0) {
            Hyprland.dispatch('hl.dsp.window.move({ workspace = "' + workspaceId + '", follow = true, ' + selector + ' })');
        }
        Hyprland.dispatch("hl.dsp.focus({ " + selector + " })");
    }

    function closeWindow(window) {
        if (window.wayland) {
            window.wayland.close();
            return;
        }
        const selector = windowSelector(window);
        if (selector)
            Hyprland.dispatch("hl.dsp.window.close({ " + selector + " })");
    }

    function windowSelector(window) {
        const hex = window.address.replace(/^0x/i, "");
        return /^[a-f0-9]+$/i.test(hex) ? 'window = "address:0x' + hex + '"' : "";
    }

    function toggleSettings(screen) {
        root.settingsScreen = root.settingsScreen === screen ? null : screen;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial" || event.name === "activespecialv2")
                Hyprland.refreshMonitors();
            else if (event.name === "fullscreen")
                Hyprland.refreshToplevels();
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            DockSurface {
                required property var modelData
                screen: modelData
                dock: root
            }
        }
    }

    Loader {
        active: !!root.settingsScreen
        sourceComponent: DockSettings {
            screen: root.settingsScreen
            dock: root
        }
    }

    Commons.ShellIpc {
        target: "jean.lumadock"

        function settings(): void {
            const monitor = Hyprland.focusedMonitor;
            root.toggleSettings(Quickshell.screens.find(screen => monitor && screen.name === monitor.name)
                || Quickshell.screens[0] || null);
        }
    }
}
