# Keys

Every chord and action, and how to change them.

## Default chords

Bound by `start()`.

| Chord | Action | Press again |
|---|---|---|
| `⌃⌥←` `⌃⌥A` | `left` — to `main` | left half |
| `⌃⌥→` `⌃⌥D` | `right` — to `side` | right half |
| `⌃⌥↑` `⌃⌥W` | `fullscreen` — whole screen, with gaps | native fullscreen |
| `⌃⌥↓` `⌃⌥S` | `arrangeAll` — every window to its place | — |
| `⇧⌃⌥←` `⇧⌃⌥A` | `halfLeft` | — |
| `⇧⌃⌥→` `⇧⌃⌥D` | `halfRight` | — |
| `⇧⌃⌥↑` `⇧⌃⌥W` | `top60` — upper part, full width | — |
| `⇧⌃⌥↓` `⇧⌃⌥S` | `bottom40` — lower part, full width | — |
| `🌐⌃←` `🌐⌃→` `🌐⌃↑` `🌐⌃↓` `🌐⌃F` `🌐⌃C` | macOS's own window keys, taken over | see [macos-keys.md](macos-keys.md) |

"Press again" works when the window is already in place, within `tolerance` pixels ([layout.md](layout.md)).

## Actions without a chord

| Action | Does |
|---|---|
| `center` | centers the window, size kept |
| `swapSides` | swaps the two top windows: left goes right, right goes left |
| `minimizeAndFocusNext` | minimizes, focuses the next window: same app first |
| `minimizeCurrent` | minimizes the focused window |

These twelve names are all `bindHotkeys` accepts. Another name raises an error.

## Add a chord

`bindHotkeys` takes `{ action = { mods, key } }`, or a list of chords per action. User chords survive `start()`; `stop()` deletes them.

```lua
spoon.PowerWindows:bindHotkeys{
  center = { { "ctrl", "alt" }, "c" },
  minimizeAndFocusNext = { { "cmd" }, "h" },
  swapSides = { { { "ctrl", "alt" }, "x" }, { {}, "pad8" } },
}
```

Anything else in the API — `focusSet`, `placeDefault`, `moveLeft` — bind with `hs.hotkey`:

```lua
hs.hotkey.bind({ "shift", "ctrl", "alt", "cmd" }, "up", function() spoon.PowerWindows:focusSet("work") end)
```

## Change the default chords

`keys` in [`config/settings.lua`](../config/settings.lua). One table replaces one table: give it whole.

```lua
spoon.PowerWindows:configure{
  keys = {
    mods = { "cmd", "alt" },
    shiftMods = { "shift", "cmd", "alt" },
  },
}:start()
```

```lua
spoon.PowerWindows:configure{
  keys = { letters = { left = "h", right = "l", fullscreen = "k", arrangeAll = "j" } },
}:start()
```

`configure` after `start()` needs another `start()`.

## Arrows only

```lua
spoon.PowerWindows:configure{ wasd = false }:start()
```

## No chords

For those who bind everything themselves: another hotkey Spoon, a launcher, a script.

```lua
spoon.PowerWindows:configure{ hotkeys = false }:start()
hs.hotkey.bind({ "cmd", "alt" }, "left", function() spoon.PowerWindows:left() end)
```

Every action is a method. Call it from anywhere.

## macOS's own window keys

`🌐⌃` + arrows, `F` and `C` run PowerWindows actions. Give them back to macOS:

```lua
spoon.PowerWindows:configure{ macosKeys = false }:start()
```

Details: [macos-keys.md](macos-keys.md).

## Swap sides on A and D together

`hs.hotkey` fires on the first key and cannot see two keys at once. Karabiner-Elements can. It turns `⌃⌥A`+`D` and `⌃⌥←`+`→`, pressed within 50 ms, into keypad 8.

Karabiner rule (Settings › Complex Modifications › Add your own rule):

```json
{
  "description": "Ctrl+Option + A and D together = keypad 8 (PowerWindows swapSides)",
  "manipulators": [
    {
      "type": "basic",
      "from": {
        "modifiers": { "mandatory": ["left_control", "left_option"] },
        "simultaneous": [{ "key_code": "a" }, { "key_code": "d" }]
      },
      "parameters": { "basic.simultaneous_threshold_milliseconds": 50 },
      "to": [{ "key_code": "keypad_8" }]
    },
    {
      "type": "basic",
      "from": {
        "modifiers": { "mandatory": ["left_control", "left_option"] },
        "simultaneous": [{ "key_code": "left_arrow" }, { "key_code": "right_arrow" }]
      },
      "parameters": { "basic.simultaneous_threshold_milliseconds": 50 },
      "to": [{ "key_code": "keypad_8" }]
    }
  ]
}
```

Hammerspoon:

```lua
spoon.PowerWindows:bindHotkeys{ swapSides = { {}, "pad8" } }
```

Cost: a single `⌃⌥A` or `⌃⌥←` waits up to 50 ms for its partner.
