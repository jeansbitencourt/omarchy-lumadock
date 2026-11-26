# LumaDock

LumaDock is a floating, translucent glass dock for the Omarchy shell. It groups windows by application, highlights the focused application, and keeps pinned shortcuts available when their applications are closed.

## Requirements

- Omarchy with Hyprland, Quickshell, and shell plugin support. Tested on Omarchy 4.5.0.
- Thumbnails use Hyprland window capture. When a thumbnail is unavailable, the preview displays the application's icon and the window title.

## Installation

To install from a local copy of this repository, run these commands from the project root. The destination must be available for Git to clone into.

```bash
plugins_dir="$HOME/.config/omarchy/plugins"
mkdir -p "$plugins_dir"
git clone -- "$(pwd -P)" "$plugins_dir/jean.lumadock"
omarchy plugin validate "$plugins_dir/jean.lumadock"
omarchy-shell shell rescanPlugins
omarchy plugin enable jean.lumadock
```

### Background blur

Add this rule to `~/.config/hypr/looknfeel.lua` to blur the background behind the dock. The effect uses Hyprland's blur when it is enabled for the session.

```lua
hl.layer_rule({
  match = { namespace = "^lumadock$" },
  blur = true,
  ignore_alpha = 0.08,
})
```

```bash
hyprctl reload
hyprctl configerrors
```

### Styles

Open the settings and choose an option under **Appearance**. The choice applies to the dock, tooltips, window thumbnails, and the settings window, and is saved in `lumadock.ini`.

| Style | Description |
| --- | --- |
| Liquid glass | Default. Translucent card with a specular highlight and bottom reflection. |
| Frosted glass | Milky, evenly tinted card with no highlight, so the blur reads as diffused frost. |
| Clear | Almost no tint, only a thin outline. The card stays below the rule's `ignore_alpha`, so it is not blurred. |
| Solid | Opaque, flat color with a subtle edge. |
| Minimal dark | Flat dark card with smaller corner radii and no border. |

The blur strength comes from Hyprland (`decoration.blur`) and is shared by every style. Styles only change how much of it shows through, so translucent styles look flatter and less legible without the layer rule above.

## Usage

- Click an application icon to launch it or focus a window that is already open.
- Right-click an application icon to launch another instance.
- Hover over an icon with open windows to see one thumbnail per window. Click a thumbnail to focus its window or click **×** in the upper-right corner to close it.
- Click the gear icon to search installed applications, pin shortcuts, and reorder them with the arrow buttons. You can also open settings with `omarchy-shell jean.lumadock settings`.

| Setting | Behavior |
| --- | --- |
| Show open apps | Shows applications from all workspaces by default. You can limit the view to the current workspace. |
| Fixed | Reserves space at the screen edge. This is the default mode. |
| Auto-hide | Reveals the dock when the cursor touches the selected edge. The dock stays visible on empty workspaces. The animation respects Omarchy's motion preference. |
| Screen edge | Places the dock at the top, bottom, left, or right. The default is bottom. |
| Appearance | Selects the visual style. The default is Liquid glass. |

Preferences are stored in `${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lumadock.ini`. On first use, LumaDock imports the built-in dock's pinned shortcuts in their configured order, if available. When enabled, the built-in dock can also appear on floating workspaces.

To disable LumaDock, run `omarchy plugin disable jean.lumadock`.

## Development

- [LumaDock.qml](LumaDock.qml) tracks windows, loads preferences, and launches applications.
- [DockSurface.qml](DockSurface.qml), [DockPreview.qml](DockPreview.qml), and [DockSettings.qml](DockSettings.qml) implement the dock, thumbnails, and settings.
- [DockModel.js](DockModel.js) groups windows, filters by workspace, and orders shortcuts.
- [DockStyles.js](DockStyles.js) defines the color and shape tokens for each style. Add a style by extending `ids` and `themes`, then add its `style<Id>` string in [i18n/](i18n/).
- [i18n/](i18n/) contains the Brazilian Portuguese and English translations.

Validate the manifest and run the QML tests from the project root.

```bash
omarchy plugin validate .
env -u QT_QPA_PLATFORMTHEME QT_QPA_PLATFORM=offscreen \
  /usr/lib/qt6/bin/qmltestrunner -input tests
```
