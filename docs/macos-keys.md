# macOS window keys

For Mac users who know 🌐⌃F: what happens to macOS's own window keys, and how to keep them.

## What macOS has

Since macOS Sequoia, every app's Window menu has tiling commands with keys. `Fn` is the 🌐 Globe key on newer keyboards. Source: [Apple, Mac window tiling icons & keyboard shortcuts](https://support.apple.com/guide/mac-help/tile-app-windows-mchl9674d0b0/mac).

| Keys | macOS |
|---|---|
| `🌐⌃F` | Fill |
| `🌐⌃C` | Center |
| `🌐⌃←` `🌐⌃→` | left / right half |
| `🌐⌃↑` `🌐⌃↓` | top / bottom half |
| `🌐⌃R` | return to previous size |
| `🌐⌃⇧` + arrows | two windows: left & right, right & left, top & bottom, bottom & top |
| `🌐⌥⌃⇧` + arrows | one window and quarters |

## What PowerWindows does with them

By default six of them run PowerWindows actions on the front window. The windows land in PowerWindows' places, with its gaps.

| Keys | Action | PowerWindows |
|---|---|---|
| `🌐⌃←` | `left` | to `main`; again: left half |
| `🌐⌃→` | `right` | to `side`; again: right half |
| `🌐⌃↑` | `top60` | upper part, full width |
| `🌐⌃↓` | `bottom40` | lower part, full width |
| `🌐⌃F` | `fullscreen` | whole screen with gaps; again: native fullscreen |
| `🌐⌃C` | `center` | centered, size kept |

`🌐⌃R`, the `⇧` and `⌥` variants go to macOS untouched. Any key can join: `macosKeys = { r = "arrangeAll" }`. So does `⌃←` without 🌐: Mission Control keeps its Spaces keys.

The setting, in [`config/settings.lua`](../config/settings.lua):

```lua
macosKeys = { left = "left", right = "right", up = "top60", down = "bottom40", f = "fullscreen", c = "center" }
```

The arrows need the physical 🌐 key held. A script sending 🌐⌃← is not caught.

## Give them all back

```lua
spoon.PowerWindows:configure{ macosKeys = false }:start()
```

## Give back one key

`false` for that key. The rest stay.

```lua
spoon.PowerWindows:configure{ macosKeys = { f = false } }:start()
```

`🌐⌃F` is macOS Fill again; the other five are PowerWindows.

## Another action on a key

Any action from [keys.md](keys.md) works. An unknown name raises an error at `start()` naming the key.

```lua
spoon.PowerWindows:configure{ macosKeys = { up = "fullscreen", down = "arrangeAll" } }:start()
```

The table merges key by key. After `macosKeys = false`, a new table replaces it whole.

## Turn macOS tiling off instead

The drag gestures live in System Settings › Desktop & Dock › Windows ([Apple, Change window tiling settings on Mac](https://support.apple.com/guide/mac-help/mchl118087b0/mac)):

- Drag windows to left or right edge of screen to tile
- Drag windows to menu bar to fill screen
- Hold ⌥ key while dragging windows to tile
- Tiled windows have margins

Older versions name the first one "Drag windows to screen edges to tile".

These switches cover dragging only. The keys have no switch there: they belong to each app's Window menu. To free one without PowerWindows, give its menu item another shortcut in System Settings › Keyboard › Keyboard Shortcuts › App Shortcuts (All Applications, menu title `Fill`).
