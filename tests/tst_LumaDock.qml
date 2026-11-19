import QtQuick
import QtTest
import ".." as LumaDock
import "../DockModel.js" as Model

TestCase {
    name: "LumaDock"

    Component { id: label; LumaDock.PlainLabel {} }

    function test_markupIsPlainText() {
        const markup = '<img src="https://example.invalid/tracker"><b>Example</b>';
        const item = createTemporaryObject(label, this, { text: markup });
        verify(item !== null);
        compare(item.textFormat, Text.PlainText);
        compare(item.text, markup);
    }

    function test_pinsNormalizeAndReorder() {
        const pins = Model.pinIds(["browser.desktop", " editor ", "browser", null, "", "chat"]);
        compare(pins, ["browser", "editor", "chat"]);
        compare(Model.movePin(pins, "chat", -1), ["browser", "chat", "editor"]);
        compare(Model.movePin(pins, "browser", -1), pins);
    }

    function test_workspaceScopeAndFocus() {
        const windows = [
            { key: "browser", address: "a", workspaceId: 2 },
            { key: "browser", address: "b", workspaceId: 3 },
            { key: "window:terminal", address: "c", workspaceId: 3 },
            { key: "window:notes", address: "d", workspaceId: -98, minimizedFrom: 2 }
        ];
        const pins = ["editor", "browser"];
        const everywhere = Model.groupApps(pins, windows, false, 2, 0);
        compare(everywhere.map(app => app.key), ["editor", "browser", "window:terminal", "window:notes"]);
        compare(everywhere[0].windows.length, 0);
        compare(everywhere[1].windows.length, 2);
        compare(Model.pickWindow(everywhere[1].windows, "", 2, 0).address, "a");
        compare(Model.pickWindow(everywhere[1].windows, "a", 2, 0).address, "b");
        const current = Model.groupApps(pins, windows, true, 2, 0);
        compare(current.map(app => app.key), ["editor", "browser", "window:notes"]);
        compare(current[1].windows.length, 1);
        compare(Model.groupApps(pins, windows, true, 2, -98).length, 3);
    }

    function test_positions() {
        compare(Model.positions, ["top", "bottom", "left", "right"]);
        for (const position of Model.positions)
            compare(Model.normalizePosition(position), position);
        compare(Model.normalizePosition("invalid"), "bottom");
    }

    function test_launchDesktopAndTerminalEntries() {
        compare(Model.launchCommand({ id: "Example With Spaces" }),
            ["uwsm-app", "--", "gtk-launch", "Example With Spaces.desktop"]);
        compare(Model.launchCommand({
            id: "example", runInTerminal: true, command: ["example", "--title", "Name with spaces", "%U"]
        }), ["omarchy-launch-tui", "example", "--title", "Name with spaces"]);
    }

    function test_workspaceOccupancyIgnoresOtherAndMinimizedWindows() {
        const windows = [
            { workspaceId: 3, minimized: false },
            { workspaceId: -98, minimized: true, minimizedFrom: 2 },
            { workspaceId: -99, minimized: false }
        ];
        verify(!Model.hasOpenWindows(windows, 2, 0));
        verify(Model.hasOpenWindows(windows, 3, 0));
        verify(Model.hasOpenWindows(windows, 2, -99));
        verify(!Model.hasOpenWindows(windows, 2, -98));
        verify(!Model.hasOpenWindows([], 2, 0));
    }
}
