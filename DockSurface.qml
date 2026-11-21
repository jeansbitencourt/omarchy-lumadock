pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons as Commons
import qs.Ui as Ui
import "DockModel.js" as Model

PanelWindow {
    id: surface

    required property LumaDock dock
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int workspaceId: monitor?.activeWorkspace?.id ?? 0
    readonly property int specialId: monitor?.lastIpcObject?.specialWorkspace?.id ?? 0
    readonly property var apps: Model.groupApps(dock.pinnedIds, dock.windows, dock.currentOnly, workspaceId, specialId)
    readonly property bool occupied: Model.hasOpenWindows(dock.windows, workspaceId, specialId)
    readonly property bool fullscreen: Hyprland.toplevels.values.some(window => window.monitor === monitor
        && (window.workspace?.id === workspaceId || window.workspace?.id === specialId)
        && Number(window.lastIpcObject?.fullscreen) >= 2)
    readonly property string position: dock.position
    readonly property bool vertical: position === "left" || position === "right"
    readonly property bool settingsOpen: dock.settingsScreen === screen
    readonly property bool autoHide: dock.autoHide
    readonly property bool shown: !autoHide || !occupied || settingsOpen || edgeRevealed
    readonly property int slot: Math.min(60, Math.max(48, Math.round(52 * Commons.Style.fontScale)))
    readonly property int thickness: slot + 13
    readonly property int edgeGap: 10
    readonly property int edgeTriggerSize: 2
    // Keep the animated card clear of the edge trigger so the two layer surfaces
    // do not steal pointer focus from each other while the dock is revealing.
    readonly property int revealTravel: Math.max(0, edgeGap - edgeTriggerSize - 1)
    readonly property int cardLength: Math.max(thickness, Math.min(
        (vertical ? height : width) - 24, (apps.length + 1) * slot + 30))
    readonly property bool pointerOverDock: cardHover.hovered
        || (tooltipTile?.hovered ?? false) || (previewLoader.panel?.hovered ?? false)
    onPointerOverDockChanged: updateReveal()

    property bool edgeRevealed: false
    property DockTile tooltipTile: null
    property DockTile previewTile: null

    anchors {
        left: !surface.vertical || surface.position === "left"
        right: !surface.vertical || surface.position === "right"
        top: surface.vertical || surface.position === "top"
        bottom: surface.vertical || surface.position === "bottom"
    }
    implicitWidth: vertical ? thickness + edgeGap + 250 : 0
    implicitHeight: vertical ? 0 : thickness + edgeGap + 144
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: autoHide ? 0 : thickness + edgeGap + 5
    visible: !remap.remapping && (autoHide || !fullscreen)
    WlrLayershell.namespace: "lumadock"
    WlrLayershell.layer: autoHide ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {
        item: surface.shown ? card : null
        Region { item: previewLoader.active ? previewLoader : null }
    }

    onPositionChanged: {
        hideTimer.stop();
        edgeRevealed = false;
        tooltipTile = null;
        closePreview();
    }
    onAutoHideChanged: {
        hideTimer.stop();
        edgeRevealed = false;
    }
    onSettingsOpenChanged: if (settingsOpen) closePreview()

    function revealFromEdge() {
        if (!autoHide || remap.remapping)
            return;
        edgeRevealed = true;
        if (pointerOverDock) {
            hideTimer.stop();
        } else {
            hideTimer.restart();
        }
    }

    function updateReveal() {
        if (!autoHide || remap.remapping)
            return;
        if (pointerOverDock) {
            hideTimer.stop();
            edgeRevealed = true;
        } else {
            hideTimer.restart();
        }
    }

    function updateTooltip(tile) {
        if (tile.hovered) {
            tooltipTile = tile;
            if (tile === previewTile)
                dismissPreview.stop();
            else if (tile.running && !settingsOpen)
                showPreview.restart();
        } else if (tooltipTile === tile) {
            tooltipTile = null;
            showPreview.stop();
        }
        if (previewTile && previewTile !== tooltipTile && !previewLoader.panel?.hovered)
            dismissPreview.restart();
        updateReveal();
    }

    function closePreview() {
        showPreview.stop();
        dismissPreview.stop();
        previewTile = null;
    }

    Timer {
        id: showPreview
        interval: 360
        onTriggered: {
            const tile = surface.tooltipTile;
            if (tile?.running && !viewport.moving && !previewLoader.panel?.hovered) {
                dismissPreview.stop();
                surface.previewTile = tile;
            }
        }
    }

    Timer {
        id: dismissPreview
        interval: 235
        onTriggered: surface.previewTile = null
    }

    Timer {
        id: hideTimer
        // Give the cursor time to cross the gap and a status bar on the same edge.
        interval: 480
        onTriggered: {
            if (surface.pointerOverDock)
                surface.updateReveal();
            else
                surface.edgeRevealed = false;
        }
    }

    Ui.ScreenMoveRemap {
        id: remap
        window: surface
    }

    // A separate layer reaches the physical edge even when another bar reserves it.
    PanelWindow {
        screen: surface.screen
        anchors {
            left: !surface.vertical || surface.position === "left"
            right: !surface.vertical || surface.position === "right"
            top: surface.vertical || surface.position === "top"
            bottom: surface.vertical || surface.position === "bottom"
        }
        implicitWidth: surface.vertical ? surface.edgeTriggerSize : 0
        implicitHeight: surface.vertical ? 0 : surface.edgeTriggerSize
        color: "transparent"
        visible: surface.autoHide && !remap.remapping
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "lumadock-edge"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        HoverHandler {
            id: edgeHover
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onHoveredChanged: {
                if (hovered)
                    surface.revealFromEdge();
                else
                    surface.updateReveal();
            }
        }
    }

    Rectangle {
        id: card
        readonly property real edgeOffset: surface.autoHide ? surface.revealTravel * (1 - opacity) : 0
        visible: surface.shown || opacity > 0
        opacity: surface.shown ? 1 : 0
        transform: Translate {
            x: surface.position === "left" ? -card.edgeOffset : surface.position === "right" ? card.edgeOffset : 0
            y: surface.position === "top" ? -card.edgeOffset : surface.position === "bottom" ? card.edgeOffset : 0
        }
        Behavior on opacity {
            enabled: surface.autoHide && !remap.remapping
            NumberAnimation {
                duration: Commons.Style.duration(surface.shown ? 185 : 120)
                easing.type: Easing.OutCubic
            }
        }
        width: surface.vertical ? surface.thickness : surface.cardLength
        height: surface.vertical ? surface.cardLength : surface.thickness
        x: surface.vertical ? (surface.position === "left" ? surface.edgeGap : parent.width - width - surface.edgeGap)
            : Math.round((parent.width - width) / 2)
        y: surface.vertical ? Math.round((parent.height - height) / 2)
            : (surface.position === "top" ? surface.edgeGap : parent.height - height - surface.edgeGap)
        radius: 23
        border.color: "#45eff8ff"
        gradient: Gradient {
            orientation: surface.vertical ? Gradient.Horizontal : Gradient.Vertical
            GradientStop { position: 0; color: "#30232e39" }
            GradientStop { position: 0.48; color: "#3819232e" }
            GradientStop { position: 1; color: "#50121b25" }
        }

        HoverHandler {
            id: cardHover
            onHoveredChanged: surface.updateReveal()
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: card.radius - 1
            gradient: Gradient {
                orientation: surface.vertical ? Gradient.Horizontal : Gradient.Vertical
                GradientStop { position: 0; color: "#66f8fdff" }
                GradientStop { position: 0.045; color: "#24f8fdff" }
                GradientStop { position: 0.18; color: "#00f8fdff" }
                GradientStop { position: 0.84; color: "#00c5e1f7" }
                GradientStop { position: 1; color: "#29c5e1f7" }
            }
        }

        Flickable {
            id: viewport
            x: surface.vertical ? 0 : 7
            y: surface.vertical ? 7 : 0
            width: surface.vertical ? card.width : Math.max(0, separator.x - x - 7)
            height: surface.vertical ? Math.max(0, separator.y - y - 7) : card.height
            contentWidth: surface.vertical ? width : appGrid.implicitWidth
            contentHeight: surface.vertical ? appGrid.implicitHeight : height
            flickableDirection: surface.vertical ? Flickable.VerticalFlick : Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            interactive: surface.vertical ? contentHeight > height : contentWidth > width
            clip: interactive
            onMovingChanged: if (moving) surface.closePreview()

            WheelHandler {
                enabled: viewport.interactive
                onWheel: event => {
                    const delta = event.angleDelta.x || event.angleDelta.y;
                    const step = delta / 120 * surface.slot * 2;
                    if (surface.vertical) {
                        viewport.contentY = Math.max(0, Math.min(viewport.contentHeight - viewport.height,
                            viewport.contentY - step));
                    } else {
                        viewport.contentX = Math.max(0, Math.min(viewport.contentWidth - viewport.width,
                            viewport.contentX - step));
                    }
                }
            }

            Grid {
                id: appGrid
                columns: surface.vertical ? 1 : Math.max(1, surface.apps.length)
                x: surface.vertical ? Math.round((viewport.width - implicitWidth) / 2) : 0
                y: surface.vertical ? 0 : Math.round((viewport.height - implicitHeight) / 2)

                Repeater {
                    model: surface.apps.length
                    delegate: DockTile {
                        id: appTile
                        required property int index
                        app: surface.apps[index] ?? null
                        readonly property bool focused: app?.windows.some(window => window.address === surface.dock.focusedAddress) ?? false
                        width: surface.slot
                        height: surface.slot
                        label: app ? surface.dock.entryLabel(app) : ""
                        fallback: label.charAt(0).toUpperCase()
                        icon: app ? surface.dock.iconSource(app.desktopId, app.name) : ""
                        running: (app?.windows.length ?? 0) > 0
                        highlighted: focused
                        muted: !running
                        onClicked: {
                            surface.closePreview();
                            if (app)
                                surface.dock.activate(app, surface.workspaceId, surface.specialId);
                        }
                        onHoveredChanged: surface.updateTooltip(appTile)
                    }
                }
            }
        }

        Rectangle {
            id: separator
            width: surface.vertical ? 28 : 1
            height: surface.vertical ? 1 : 28
            x: surface.vertical ? Math.round((card.width - width) / 2) : settingsTile.x - 5
            y: surface.vertical ? settingsTile.y - 5 : Math.round((card.height - height) / 2)
            color: "#55e6f4ff"
            visible: surface.apps.length > 0
        }

        DockTile {
            id: settingsTile
            width: surface.slot
            height: surface.slot
            x: surface.vertical ? Math.round((card.width - width) / 2) : card.width - width - 6
            y: surface.vertical ? card.height - height - 6 : Math.round((card.height - height) / 2)
            label: surface.dock.strings.t("settings")
            fallback: "⚙"
            highlighted: surface.settingsOpen
            onClicked: surface.dock.toggleSettings(surface.screen)
            onHoveredChanged: surface.updateTooltip(settingsTile)
        }
    }

    Rectangle {
        id: tooltip
        readonly property point tileCenter: {
            const tile = surface.tooltipTile;
            return tile ? tile.mapToItem(surface.contentItem, tile.width / 2, tile.height / 2) : Qt.point(0, 0);
        }
        visible: surface.shown && !viewport.moving && !previewLoader.active
            && surface.tooltipTile !== null && tooltipLabel.text !== ""
        width: Math.min(surface.vertical ? 236 : 255, tooltipLabel.implicitWidth + 20)
        height: 27
        x: surface.vertical ? (surface.position === "left" ? card.x + card.width + 5 : card.x - width - 5)
            : Math.max(7, Math.min(surface.width - width - 7, tileCenter.x - width / 2))
        y: surface.vertical ? Math.max(7, Math.min(surface.height - height - 7, tileCenter.y - height / 2))
            : (surface.position === "top" ? card.y + card.height + 5 : card.y - height - 5)
        radius: 9
        color: "#ef192534"
        border.color: "#686f8aa4"

        PlainLabel {
            id: tooltipLabel
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            elide: Text.ElideRight
            color: "#f1f7ff"
            horizontalAlignment: Text.AlignHCenter
            text: surface.tooltipTile?.label ?? ""
        }
    }

    Loader {
        id: previewLoader
        readonly property DockPreview panel: item as DockPreview
        readonly property point tileCenter: {
            const tile = surface.previewTile;
            return tile ? tile.mapToItem(surface.contentItem, tile.width / 2, tile.height / 2) : Qt.point(0, 0);
        }
        active: surface.shown && !surface.settingsOpen && (surface.previewTile?.running ?? false)
        x: surface.vertical ? (surface.position === "left" ? card.x + card.width + 5 : card.x - width - 5)
            : Math.max(7, Math.min(surface.width - width - 7, tileCenter.x - width / 2))
        y: surface.vertical ? Math.max(7, Math.min(surface.height - height - 7, tileCenter.y - height / 2))
            : (surface.position === "top" ? card.y + card.height + 5 : card.y - height - 5)
        sourceComponent: DockPreview {
            windows: surface.previewTile?.app?.windows ?? []
            appName: surface.previewTile?.label ?? ""
            appIcon: surface.previewTile?.icon ?? ""
            focusedAddress: surface.dock.focusedAddress
            closeLabel: surface.dock.strings.t("closeWindow")
            vertical: surface.vertical
            availableLength: (vertical ? surface.height : surface.width) - 14
            onHoveredChanged: {
                if (hovered)
                    dismissPreview.stop();
                else if (surface.tooltipTile !== surface.previewTile)
                    dismissPreview.restart();
                surface.updateReveal();
            }
            onSelected: window => {
                surface.closePreview();
                surface.dock.activateWindow(window, surface.workspaceId);
                surface.updateReveal();
            }
            onCloseRequested: window => {
                if (windows.length === 1)
                    surface.closePreview();
                surface.dock.closeWindow(window);
            }
        }
    }
}
