# PowerWindows.spoon
Every window in its place, one key.
For Hammerspoon users: big window left, chat column right, video in the corner.

![demo](docs/demo.gif)

How to live with it: [docs/guide.md](docs/guide.md).

## Install

```lua
hs.loadSpoon("PowerWindows")
spoon.PowerWindows:start()
```

Unzip `PowerWindows.spoon.zip` from the latest release into `~/.hammerspoon/Spoons/`.

| Chord | Action (press again to cycle) |
|---|---|
| `⌃⌥←` / `⌃⌥A` | left column → left half |
| `⌃⌥→` / `⌃⌥D` | right column → right half |
| `⌃⌥↑` / `⌃⌥W` | whole screen → native fullscreen |
| `⌃⌥↓` / `⌃⌥S` | every window to its place |
| `⇧⌃⌥←` `⇧⌃⌥→` | left / right half |
| `⇧⌃⌥↑` `⇧⌃⌥↓` | top 60% / bottom 40% |
| `🌐⌃←` `🌐⌃→` `🌐⌃↑` `🌐⌃↓` `🌐⌃F` `🌐⌃C` | macOS's own window keys, now PowerWindows |

That's it.

## Advanced

### Settings

All defaults: [`config/settings.lua`](config/settings.lua). A typo raises an error; table settings merge key by key.

```lua
spoon.PowerWindows:configure{ gap = 0.005, split = 0.73, device = { width = 0.35 } }:start()
```

### Per-app places

Slots: `main`, `side`, `corner`, `stack`, `dialog`. `false` = never touch. Bundle ID: `osascript -e 'id of app "Name"'`.

```lua
spoon.PowerWindows:configure{
  overrides = {
    ["com.tinyspeck.slackmacgap"] = "main",
    ["com.example.overlay"] = false,
  },
}:start()
```

### Rule

Return a slot, `false`, a table, or `nil` to fall through.

```lua
rule = function(win, info) -- info = { bundle, app, title, w, h }
  if info.app == "Zoom" and info.title == "Zoom Meeting" then return "main" end
  if info.title:find("^Player") then return { slot = "corner", keepAspect = true } end
end,
```

### Decision order

Any `false` wins; an override slot still beats the catalog's `false`.

```
rule → small dialog (dialogs = false) → overrides → catalog (catalog = false) → main
```

### Keys

No default chord: `center`, `swapSides`, `minimizeAndFocusNext`, `minimizeCurrent`.

```lua
spoon.PowerWindows:configure{ wasd = false }      -- arrows only
spoon.PowerWindows:configure{ hotkeys = false }   -- no chords
spoon.PowerWindows:configure{ macosKeys = false } -- Globe keys back to macOS
spoon.PowerWindows:bindHotkeys{ center = { { "ctrl", "alt" }, "c" } }
```

### Swap sides on ⌃⌥A+D

Karabiner: map the simultaneous press to `keypad_8`.

```lua
spoon.PowerWindows:bindHotkeys{ swapSides = { {}, "pad8" } }
```

### Focus sets

Kept apps return to their places, the rest hide, a playing video stays.

```lua
spoon.PowerWindows:configure{
  focusSets = {
    work = { keep = { "com.jetbrains.rider" }, focus = { "com.jetbrains.rider" }, video = "corner" },
  },
}:start()
spoon.PowerWindows:focusSet("work")
```

### Place on launch (experimental)

For apps that open centered.

```lua
experimental = { placeOnLaunch = { bundles = { "com.jetbrains.rider" }, finderFirstWindow = true } },
```

### Add an app or a dialog

One line in `config/catalog.lua` or `config/dialogs.lua`. Pull requests welcome.

### Inside

At most seven entries per folder.

```
init.lua         public API
config/          settings, catalog, dialogs
lib/core/        geometry, rules, settings merge (pure Lua)
lib/window/      place, stack, actions, minimize, timers, query
lib/features/    hotkeys, Globe keys, focus sets, place-on-launch
docs/            guide, keys, apps, layout, macOS keys, changelog
```
