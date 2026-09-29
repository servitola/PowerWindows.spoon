-- { bundle or "*", slot or false, title = pattern, maxSize = { w, h }, keepAspect, device, popup }
-- Unlisted apps go to main. First match wins: title/size entries above the plain one.
-- popup = floats over its app (PiP); focus sets keep it while hiding the rest.
local M = {}

local CHROMIUM_PIP = "^Picture in Picture$"
local GECKO_PIP = "^Picture%-in%-Picture$"

M.apps = {
    -- Messengers
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

    -- Video
    { "com.colliderli.iina",               "corner", keepAspect = true },
    { "org.videolan.vlc",                  "corner", keepAspect = true },
    { "com.apple.Music",                   "corner", title = "^Mini Player$" },

    -- Browser PiP
    { "com.google.Chrome",                 "corner", title = CHROMIUM_PIP, keepAspect = true, popup = true },
    { "com.vivaldi.Vivaldi",               "corner", title = CHROMIUM_PIP, keepAspect = true, popup = true },
    { "com.microsoft.edgemac",             "corner", title = CHROMIUM_PIP, keepAspect = true, popup = true },
    { "com.operasoftware.Opera",           "corner", title = CHROMIUM_PIP, keepAspect = true, popup = true },
    { "com.brave.Browser",                 "corner", title = CHROMIUM_PIP, keepAspect = true, popup = true },
    { "company.thebrowser.Browser",        "corner", title = CHROMIUM_PIP, keepAspect = true, popup = true },
    { "ru.yandex.desktop.yandex-browser",  "corner", title = CHROMIUM_PIP, keepAspect = true, popup = true },
    { "org.mozilla.firefox",               "corner", title = GECKO_PIP,    keepAspect = true, popup = true },
    { "app.zen-browser.zen",               "corner", title = GECKO_PIP,    keepAspect = true, popup = true },

    -- Simulators
    { "com.apple.iphonesimulator",         "stack", keepAspect = true, device = true },
    { "*",                                 "stack", title = "^Android Emulator" },

    -- Utilities
    { "com.apple.ActivityMonitor",         "corner", title = "^CPU History$" },
    { "com.apple.ActivityMonitor",         "corner", title = "^GPU History$" },
    { "com.apple.ActivityMonitor",         "corner", maxSize = { 600, 400 } },

    -- Never touch
    { "com.raycast.macos",                 false },
    { "com.runningwithcrayons.Alfred",     false },
    -- Notch overlay: moved, it leaves a black bar on screen.
    { "theboringteam.boringnotch",         false },
}

-- Gecko browser.xhtml key_togglePictureInPicture; Chromium has no default PiP chord.
local GECKO_PIP_CHORD = { mods = { "cmd", "alt", "shift" }, key = "]" }

M.pipChords = {
    ["org.mozilla.firefox"] = GECKO_PIP_CHORD,
    ["app.zen-browser.zen"] = GECKO_PIP_CHORD,
}

function M.popupBundles()
    local set = {}
    for _, e in ipairs(M.apps) do
        if e.popup then set[e[1]] = true end
    end
    return set
end

return M
