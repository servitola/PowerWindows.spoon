-- { bundle or "*", slot or false, title = pattern, notTitle = pattern, maxTitle = chars,
--   maxSize = { w, h } (strictly less), keepAspect, device, popup, sample = a title the pattern matches (tests) }
-- Unlisted apps go to main. First match wins: title/size entries above the plain one.
-- popup = floats over its app (PiP); focus sets keep it and minimize the app's other windows.
local catalog = {}

local CHROMIUM_PLAYER = { title = "^Picture in Picture$", sample = "Picture in Picture" }
local GECKO_PLAYER = { title = "^Picture%-in%-Picture$", sample = "Picture-in-Picture" }

local function pictureInPicture(bundle, player)
    return { bundle, "corner", title = player.title, sample = player.sample, keepAspect = true, popup = true }
end

catalog.apps = {
    { "ru.keepcoder.Telegram",             "side" },
    { "com.tdesktop.Telegram",             "side" },
    { "one.ayugram.AyuGramDesktop",        "side" },
    { "net.whatsapp.WhatsApp",             "side" },
    { "org.whispersystems.signal-desktop", "side" },
    { "com.tinyspeck.slackmacgap",         "side" },
    { "com.hnc.Discord",                   "side" },
    { "com.apple.MobileSMS",               "side" },
    { "com.microsoft.teams2",              "side" },
    { "im.riot.app",                       "side" },
    { "com.viber.osx",                     "side" },

    { "com.colliderli.iina",               "corner", keepAspect = true },
    { "org.videolan.vlc",                  "corner", keepAspect = true },
    { "com.apple.Music",                   "corner", title = "^Mini Player$", sample = "Mini Player" },

    pictureInPicture("com.google.Chrome", CHROMIUM_PLAYER),
    pictureInPicture("com.vivaldi.Vivaldi", CHROMIUM_PLAYER),
    pictureInPicture("com.microsoft.edgemac", CHROMIUM_PLAYER),
    pictureInPicture("com.operasoftware.Opera", CHROMIUM_PLAYER),
    pictureInPicture("com.brave.Browser", CHROMIUM_PLAYER),
    pictureInPicture("company.thebrowser.Browser", CHROMIUM_PLAYER),
    pictureInPicture("ru.yandex.desktop.yandex-browser", CHROMIUM_PLAYER),
    pictureInPicture("org.mozilla.firefox", GECKO_PLAYER),
    pictureInPicture("app.zen-browser.zen", GECKO_PLAYER),

    { "com.apple.iphonesimulator",         "stack", keepAspect = true, device = true },
    { "*",                                 "stack", title = "^Android Emulator", sample = "Android Emulator - Pixel_8:5554" },

    { "com.apple.ActivityMonitor",         "corner", title = "^CPU History$", sample = "CPU History" },
    { "com.apple.ActivityMonitor",         "corner", title = "^GPU History$", sample = "GPU History" },
    { "com.apple.ActivityMonitor",         "corner", maxSize = { 600, 400 } },

    { "com.raycast.macos",                 false },
    { "com.runningwithcrayons.Alfred",     false },
    -- Notch overlay: moving it leaves a black bar on screen.
    { "theboringteam.boringnotch",         false },
    { "com.servitola.polaska",             false }, -- tab strip pinned under the browser window
}

-- Gecko browser.xhtml key_togglePictureInPicture; Chromium has no default PiP chord.
local GECKO_PLAYER_CHORD = { mods = { "cmd", "alt", "shift" }, key = "]" }

catalog.pipChords = {
    ["org.mozilla.firefox"] = GECKO_PLAYER_CHORD,
    ["app.zen-browser.zen"] = GECKO_PLAYER_CHORD,
}

function catalog.popupBundles()
    local set = {}
    for _, entry in ipairs(catalog.apps) do
        if entry.popup then set[entry[1]] = true end
    end
    return set
end

return catalog
