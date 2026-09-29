# How to live with it

For a new user: what a working day with PowerWindows looks like, and the few keys that carry it.

## The shape

One screen, four places.

```
+------------------------------+----------+
|                              |  side    |
|                              |  chat    |
|  main                        |          |
|  the app you work in         +----------+
|                              |  corner  |
|                              |  video   |
+------------------------------+----------+
```

- `main` — the big left area. Every app goes here unless told otherwise.
- `side` — a narrow strip on the right. Messengers.
- `corner` — under the strip. Video players and picture-in-picture.
- `stack` — the whole right column, split evenly. iOS Simulator and Android Emulator windows.

Which app goes where: [apps.md](apps.md). Proportions: [layout.md](layout.md).

## Morning

Open what you need. Do not arrange anything by hand.

Press `⌃⌥↓`. Every window goes to its place: the editor left, Telegram right, the player in the corner.

If the front window is in native fullscreen, the first `⌃⌥↓` only takes it out. Press again.

## The working loop

Four chords. Each one does something else on the second press.

| Chord | First press | Second press |
|---|---|---|
| `⌃⌥←` | to `main` | left half |
| `⌃⌥→` | to `side` | right half |
| `⌃⌥↑` | whole screen, with gaps | native fullscreen |
| `⌃⌥↓` | every window to its place | — |

Two apps side by side for a while: `⌃⌥←` twice on one, `⌃⌥→` twice on the other. Back to normal: `⌃⌥↓`.

A player or a dialog stays in its own place on `⌃⌥→`: the corner stays the corner.

From native fullscreen, `⌃⌥←` and `⌃⌥→` leave fullscreen first, then move.

The same four on `W A S D`, and halves and 60/40 on `⇧`: [keys.md](keys.md).

## Minimize and go on

macOS minimizes a window and leaves focus nowhere. `minimizeAndFocusNext` minimizes it and focuses the next one: another window of the same app first, then the window behind it. Video in the corner is skipped.

It has no chord by default. The author puts it on `⌘H`:

```lua
spoon.PowerWindows:bindHotkeys{ minimizeAndFocusNext = { { "cmd" }, "h" } }
```

`⌘H` then no longer hides the app.

## Swap sides

`swapSides` swaps the two top windows of the screen: the left one goes right, the right one goes left.

No chord by default. The author presses `⌃⌥A` and `⌃⌥D` together; Karabiner turns that into keypad 8. Recipe: [keys.md](keys.md#swap-sides-on-a-and-d-together).

## Contexts: focus sets

A focus set is a desktop for one kind of work. Kept apps come back and take their places. Everything else hides. A playing picture-in-picture video stays.

```lua
spoon.PowerWindows:configure{
  focusSets = {
    work = {
      keep  = { "com.jetbrains.rider", "com.DanPristupov.Fork", "org.mozilla.firefox", "ru.keepcoder.Telegram" },
      focus = { "org.mozilla.firefox", "com.jetbrains.rider" },
    },
    personal = {
      keep  = { "com.colliderli.iina" },
      focus = { "ru.keepcoder.Telegram" },
      video = "corner",
    },
    comms = {
      keep  = { "ru.keepcoder.Telegram", "us.zoom.xos" },
      focus = { "us.zoom.xos", "ru.keepcoder.Telegram" },
    },
  },
}:start()
```

| Field | Meaning |
|---|---|
| `keep` | bundle IDs: unhidden, unminimized, put in place |
| `focus` | bundle IDs: the first running one gets focus |
| `video` | where a kept video popup goes: `"main"` (default) or `"corner"` |
| `custom` | `{ [bundle] = function(app, pw) }` — your own handling for one app |

With `video = "main"`, the video takes the big area: a film evening. With `"corner"`, it stays small under the chat.

Firefox and Zen: if the front tab looks like a video (title contains a word from `videoTitleMarkers`), the set pops it into picture-in-picture first, so it survives the hiding.

Focus sets have no chords. Bind them yourself. The author uses `⇧⌃⌥⌘` + arrows:

```lua
local pw = spoon.PowerWindows
local sets = { up = "work", left = "personal", right = "comms", down = "only-work" }
for key, name in pairs(sets) do
  hs.hotkey.bind({ "shift", "ctrl", "alt", "cmd" }, key, function() pw:focusSet(name) end)
end
```

`only-work` is one more set: the terminal and the messenger, nothing else. A missing set name returns `false` and does nothing.

## Everything here can be changed

- Chords, rebinding, macOS's own window keys: [keys.md](keys.md)
- Which app goes where, never-touch, rules: [apps.md](apps.md)
- Proportions, gaps, animation: [layout.md](layout.md)
- 🌐⌃F, 🌐⌃C and the arrows: [macos-keys.md](macos-keys.md)
