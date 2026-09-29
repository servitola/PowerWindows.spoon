# Layout

For those who want other proportions: every layout setting and what it moves on screen.

All defaults live in [`config/settings.lua`](../config/settings.lua). Fractions are shares of the screen: `0.73` = 73%.

## The slots

```
gap                    gap split
 |                       |  |
 v                       v  v
+-+---------------------+-+------------+-+
| |                     | |  side      | |
| |                     | |            | |
| |  main               | +------------+ | <- sideHeight
| |                     | |  corner    | |
| |                     | |            | |
+-+---------------------+-+------------+-+
0                                        1
```

- `main`: from the left edge to `split`, full height.
- `side`: from `split` to the right edge, top to `sideHeight`.
- `corner`: under `side`, to the bottom.
- `stack`: from `split`, full height, one cell per window.
- `top60` / `bottom40`: full width, divided at `topShare`.

## Settings

| Setting | Default | What changes |
|---|---|---|
| `gap` | `0.005` | space around and between windows. `0` = edge to edge |
| `split` | `0.73` | where the right column starts. Smaller = wider chat |
| `sideHeight` | `0.70` | where `side` ends and `corner` begins |
| `topShare` | `0.60` | the line between `top60` and `bottom40` |
| `animation` | `0.044` | seconds per move. `0` = instant |
| `tolerance` | `4` | pixels. A window this close to a slot counts as placed: the next press cycles |

## Simulators: `device`

iOS Simulator is sized off the screen, not the column: a phone in a 27% column is too small to read. It is wider than the column on purpose and overlaps `main`.

| Setting | Default | What changes |
|---|---|---|
| `device.width` | `0.4` | phone width, share of screen width |
| `device.maxHeight` | `0.7` | height cap, share of screen height; proportions kept |
| `device.raise` | `0.1` | when centered (`main`, whole screen), how far above center |

## Dialogs: `dialog`

A small dialog goes to the top right corner. It keeps its own size up to these limits.

| Setting | Default | What changes |
|---|---|---|
| `dialog.width` | `0.9` | max width, share of the right column |
| `dialog.height` | `0.4` | max height, share of `sideHeight` |

## Example

Wider chat, no gaps, no animation, a smaller phone:

```lua
spoon.PowerWindows:configure{
  gap = 0,
  split = 0.68,
  sideHeight = 0.6,
  animation = 0,
  device = { width = 0.35 },
}:start()
```

A misspelled setting raises an error naming it. Tables like `device` and `dialog` merge key by key: `device.maxHeight` above stays `0.7`.

## Check a slot

```lua
hs.inspect(spoon.PowerWindows:slotRect("side"))
```

Names: `main`, `side`, `corner`, `video`, `full`, `halfLeft`, `halfRight`, `top60`, `bottom40`, `column`.
