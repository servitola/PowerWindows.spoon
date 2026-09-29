# Apps

For anyone whose app lands in the wrong place: how PowerWindows decides, and how to tell it.

## Slots

| Slot | Where |
|---|---|
| `main` | big area on the left. Default for every app |
| `side` | right strip, upper part |
| `corner` | right strip, under `side` |
| `stack` | whole right column, split evenly between its windows |
| `dialog` | top right corner, small, size kept when it fits |

Shapes and sizes: [layout.md](layout.md).

## Find a bundle ID

```sh
osascript -e 'id of app "Telegram"'
```

## The catalog

[`config/catalog.lua`](../config/catalog.lua) ships with the Spoon: messengers to `side`, players and picture-in-picture to `corner`, simulators to `stack`, launchers never touched. An app not in the catalog goes to `main`.

One line per app:

```lua
{ "com.example.Chat", "side" },
```

| Field | Meaning |
|---|---|
| `[1]` | bundle ID, or `"*"` for any app |
| `[2]` | slot, or `false` = never touch |
| `title` | Lua pattern the window title must match |
| `maxSize` | `{ w, h }`: the window must be smaller |
| `keepAspect` | resize without changing proportions (video) |
| `device` | phone-sized window, see `device` in [layout.md](layout.md) |
| `popup` | a floating player: focus sets keep it while hiding its app |

First match wins. Entries with `title` or `maxSize` go above the plain entry for the same app.

A common app missing, or wrong? Add the line and open a pull request: <https://github.com/servitola/PowerWindows.spoon>.

To ignore the catalog completely:

```lua
spoon.PowerWindows:configure{ catalog = false }:start()
```

## Your own places: `overrides`

Beats the catalog. A slot, `false`, or a table.

```lua
spoon.PowerWindows:configure{
  overrides = {
    ["com.tinyspeck.slackmacgap"] = "main",
    ["org.m0k.transmission"] = "corner",
    ["com.example.overlay"] = false,
    ["com.example.player"] = { slot = "corner", keepAspect = true },
  },
}:start()
```

`overrides` merges bundle by bundle: a second `configure` adds, it does not replace.

From code, one app at a time (`nil` clears):

```lua
spoon.PowerWindows:setOverride("com.example.Chat", "side")
```

## Never touch

`false` in the catalog, in `overrides`, or from a rule. Launchers, overlays, notch apps.

Windows your own code must protect:

```lua
spoon.PowerWindows:addSkipPredicate(function(win) return win:title() == "Scratch" end)
```

## Dialogs

Small Save, Open, Export, Print, Copy windows go to the top right corner, not over your work. The list: [`config/dialogs.lua`](../config/dialogs.lua).

```lua
{ "*", title = "^Save", maxSize = { 800, 600 } },
{ "com.apple.finder", maxSize = { 500, 300 }, maxTitle = 29 },
```

| Field | Meaning |
|---|---|
| `[1]` | bundle ID or `"*"` |
| `title` | title must match |
| `notTitle` | title must not match |
| `maxSize` | `{ w, h }`: strictly smaller |
| `maxTitle` | title at most this many characters |

Any match is a dialog. Missing one? One line, pull request welcome. Turn detection off:

```lua
spoon.PowerWindows:configure{ dialogs = false }:start()
```

## Rule

For what a bundle ID cannot say: a window title, an empty title, a size. `rule(win, info)` runs first for every window.

`info` = `{ bundle, app, title, w, h }`. Return a slot, `false`, a table, or `nil` to let the rest decide.

The author's rule: Hammerspoon's own canvases are untitled windows and must stay where they are.

```lua
spoon.PowerWindows:configure{
  rule = function(win, info)
    if info.bundle == "org.hammerspoon.Hammerspoon" and info.title == "" then return false end
    if info.app == "Zoom" and info.title == "Zoom Meeting" then return "main" end
    if info.title:find("^Player") then return { slot = "corner", keepAspect = true } end
  end,
}:start()
```

## Decision order

For each window, the first answer wins:

1. `rule` returns anything but `nil`.
2. `overrides` says `false`.
3. The catalog says `false`, and there is no override.
4. `config/dialogs.lua` matches: `dialog`.
5. `overrides` gives a slot.
6. The catalog gives a slot.
7. `main`.

An override equal to the catalog's slot keeps the catalog's `keepAspect`, `device` and `popup`.

Check a window:

```lua
hs.inspect(spoon.PowerWindows:resolve())
```

`source` in the answer says who decided: `rule`, `override`, `catalog`, `dialog` or `default`.

## Place on launch (experimental)

Some apps open centered, or re-center after loading (Electron). `placeOnLaunch` watches listed apps start and puts their first window in place.

```lua
spoon.PowerWindows:configure{
  experimental = {
    placeOnLaunch = {
      bundles = { "com.jetbrains.rider" },
      finderFirstWindow = true,
    },
  },
}:start()
```

- `bundles` — apps to watch, up to 30 s for the first window. A `main`, `side` or `corner` window the app moves in the next 12 s is put back once.
- `finderFirstWindow` — a new Finder window is placed when it is the only one.

Experimental: timings are tuned on one machine and may change.
