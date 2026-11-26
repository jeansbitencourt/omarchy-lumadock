import QtQuick
import QtTest
import ".." as LumaDock
import "../DockModel.js" as Model
import "../DockStyles.js" as Styles

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

    function test_styleNormalization() {
        compare(Styles.ids, ["liquid", "frosted", "clear", "solid", "minimal"]);
        for (const id of Styles.ids)
            compare(Styles.normalizeStyle(id), id);
        compare(Styles.normalizeStyle("invalid"), "liquid");
        compare(Styles.normalizeStyle(undefined), "liquid");
        compare(Styles.theme("invalid"), Styles.theme("liquid"));
    }

    function test_styleTokensAreComplete() {
        const base = Styles.theme("liquid");
        for (const id of Styles.ids) {
            const theme = Styles.theme(id);
            compare(Object.keys(theme).sort(), Object.keys(base).sort(), id);
            for (const group of Object.keys(base))
                compare(Object.keys(theme[group]).sort(), Object.keys(base[group]).sort(), id + "." + group);
            compare(theme.card.body.length, 3, id);
            verify(theme.card.highlight === null || theme.card.highlight.length === 5, id);
        }
    }

    function test_liquidKeepsOriginalLook() {
        const liquid = Styles.theme("liquid");
        compare(liquid.card.radius, 23);
        compare(liquid.card.borderColor, "#45eff8ff");
        compare(liquid.card.body, ["#30232e39", "#3819232e", "#50121b25"]);
        compare(liquid.card.highlight[0], "#66f8fdff");
        compare(liquid.settings.panel, "#fb223040");
        compare(liquid.preview.panel, "#fb202c3c");
    }

    function test_styleBlurAndOpacity() {
        // Hyprland's layer rule ignores alpha below 0.08, so the clear card gets no blur.
        for (const color of Styles.theme("clear").card.body)
            verify(Styles.alphaOf(color) < 0.08, color);
        for (const color of Styles.theme("solid").card.body)
            compare(Styles.alphaOf(color), 1);
        for (const color of Styles.theme("frosted").card.body)
            verify(Styles.alphaOf(color) > 0.08 && Styles.alphaOf(color) < 0.6, color);
        for (const id of ["liquid", "frosted", "clear"])
            verify(Styles.theme(id).card.borderWidth > 0, id);
        compare(Styles.theme("frosted").card.highlight, null);
        verify(Styles.theme("liquid").card.highlight !== null);
        compare(Styles.alphaOf("transparent"), 0);
    }
}
