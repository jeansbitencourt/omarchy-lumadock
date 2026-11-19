const positions = ["top", "bottom", "left", "right"];

function normalizePosition(position) {
    return positions.includes(position) ? position : "bottom";
}

function hasOpenWindows(windows, workspaceId, specialId) {
    return windows.some(window => !window.minimized
        && (window.workspaceId === workspaceId || (specialId !== 0 && window.workspaceId === specialId)));
}

function launchCommand(entry) {
    const terminalCommand = entry.runInTerminal
        ? (entry.command || []).filter(argument => !/^%[a-z]$/i.test(argument)) : [];
    return terminalCommand.length ? ["omarchy-launch-tui", ...terminalCommand]
        : ["uwsm-app", "--", "gtk-launch", entry.id + ".desktop"];
}

function pinIds(values) {
    if (!Array.isArray(values))
        return [];
    return [...new Set(values.filter(id => typeof id === "string" && id.trim())
                              .map(id => id.trim().replace(/\.desktop$/, "")))].filter(Boolean);
}

function movePin(pins, id, offset) {
    const from = pins.indexOf(id);
    const to = from + offset;
    if (from < 0 || to < 0 || to >= pins.length)
        return pins;
    const reordered = pins.slice();
    reordered.splice(from, 1);
    reordered.splice(to, 0, id);
    return reordered;
}

function groupApps(pins, windows, currentOnly, workspaceId, specialId) {
    const groups = new Map();
    for (const id of pins) {
        groups.set(id, { key: id, desktopId: id, name: id, windows: [] });
    }
    for (const window of windows) {
        if (currentOnly && window.workspaceId !== workspaceId && window.workspaceId !== specialId
                && window.minimizedFrom !== workspaceId)
            continue;
        if (!groups.has(window.key)) {
            groups.set(window.key, {
                key: window.key, desktopId: window.desktopId, name: window.appId, windows: []
            });
        }
        groups.get(window.key).windows.push(window);
    }
    return Array.from(groups.values());
}

function pickWindow(windows, focusAddress, workspaceId, specialId) {
    const focusedIndex = windows.findIndex(window => window.address === focusAddress);
    if (focusedIndex >= 0)
        return windows[(focusedIndex + 1) % windows.length];
    return windows.find(window => window.workspaceId === workspaceId || window.workspaceId === specialId)
        || windows.find(window => window.minimizedFrom === workspaceId) || windows[0];
}
