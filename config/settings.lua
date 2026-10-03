-- Every setting and its default; fractions are shares of the screen.
-- configure{} merges maps one level deep (keys.arrows is replaced whole) and replaces lists.
return {
    hotkeys = true,       -- false = no default chords; bindHotkeys still works
    wasd = true,          -- false = arrows only
    keys = {
        mods = { "ctrl", "alt" },
        shiftMods = { "shift", "ctrl", "alt" },
        arrows = { left = "left", right = "right", fullscreen = "up", arrangeAll = "down" },
        shiftedArrows = { halfLeft = "left", halfRight = "right", top60 = "up", bottom40 = "down" },
        letters = { left = "a", right = "d", fullscreen = "w", arrangeAll = "s" },
        shiftedLetters = { halfLeft = "a", halfRight = "d", top60 = "w", bottom40 = "s" },
    },
    macosKeys = false,    -- { key = action }: 🌐⌃key runs the action (docs/macos-keys.md)

    overrides = {},       -- { [bundle] = main/side/corner/stack/dialog, false or a table }
    rule = false,         -- function(window, info) -> slot, table, false, or nil to fall through
    catalog = true,       -- false = ignore config/catalog.lua
    dialogs = true,       -- false = ignore config/dialogs.lua

    split = 0.73,         -- right column start, share of width
    sideHeight = 0.70,    -- upper right slot, share of height
    topShare = 0.60,      -- top60/bottom40 line, share of height
    gap = 0.005,          -- below 1 = share of screen, 1 and up = points; right edge ÷1.5, bottom ×1.5
    screens = {},         -- { [screen name], portrait, ultrawide = { gap, split, sideHeight, topShare, device, dialog } }

    animation = 0.05,     -- seconds; 0 = one clean move, no motion
    rearrangeOnScreenChange = false, -- true = arrangeAllNow() ~1 s after displays change

    focusSets = {},       -- { name = { keep, focus, video, custom } }
    -- lowercase; a front tab titled with one is popped out to PiP by focus sets
    videoTitleMarkers = { "youtube", "youtu.be", "twitch", "vimeo", "rutube", "netflix" },

    device = {            -- windows with device = true (iOS Simulator)
        width = 0.4,      -- share of screen; wider than the column on purpose
        maxHeight = 0.7,  -- share of screen height, aspect kept
        raise = 0.1,      -- above center in main or full, share of height
    },

    dialog = {
        width = 0.9,      -- max, share of column width
        height = 0.4,     -- max, share of sideHeight
    },

    tolerance = 4,        -- points; this close to a slot = already in it (second press cycles)

    experimental = {
        -- { placeOnLaunch = { bundles, finderFirstWindow } }
    },
}
