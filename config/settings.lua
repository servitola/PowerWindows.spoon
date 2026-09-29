-- Every setting and its default. Fractions are shares of the screen.
-- Change with spoon.PowerWindows:configure{ split = 0.7 }; tables merge key by key.
return {
    -- Layout
    gap = 0.005,          -- between windows, share of screen
    split = 0.73,         -- right column start, share of width
    sideHeight = 0.70,    -- upper right slot, share of height
    topShare = 0.60,      -- top60/bottom40 line, share of height
    animation = 0.044,    -- seconds, 0 = instant
    tolerance = 4,        -- pixels, near = already placed

    -- Simulators
    device = {
        width = 0.4,      -- share of screen; wider than the column on purpose
        maxHeight = 0.7,  -- share of screen height, aspect kept
        raise = 0.1,      -- above center, share of height
    },

    -- Dialogs
    dialog = {
        width = 0.9,      -- max, share of column width
        height = 0.4,     -- max, share of sideHeight
    },

    -- Keys
    hotkeys = true,       -- false = no chords
    wasd = true,          -- false = arrows only
    keys = {
        mods = { "ctrl", "alt" },                 -- plain chords
        shiftMods = { "shift", "ctrl", "alt" },   -- shifted chords
        arrows = { left = "left", right = "right", fullscreen = "up", arrangeAll = "down" },
        shiftedArrows = { halfLeft = "left", halfRight = "right", top60 = "up", bottom40 = "down" },
        letters = { left = "a", right = "d", fullscreen = "w", arrangeAll = "s" },
        shiftedLetters = { halfLeft = "a", halfRight = "d", top60 = "w", bottom40 = "s" },
    },
    macosKeys = {         -- 🌐⌃key runs the action; false = macOS keeps them
        left = "left", right = "right", up = "top60", down = "bottom40", f = "fullscreen", c = "center",
    },

    -- Placement
    catalog = true,       -- false = ignore config/catalog.lua
    dialogs = true,       -- false = ignore config/dialogs.lua
    overrides = {},       -- { [bundle] = slot, false or table }
    rule = false,         -- function(win, info) -> slot, false, nil
    focusSets = {},       -- { name = { keep, focus, video } }
    videoTitleMarkers = { "youtube", "youtu.be", "twitch", "vimeo", "rutube", "netflix" }, -- tab title means video

    experimental = {},    -- { placeOnLaunch = { bundles, finderFirstWindow } }
}
