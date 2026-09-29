-- Synthesized chords do not reach Carbon hotkeys: scripts call focusSet() directly.
local ACTIVATE_DELAY, CHORD_DELAY, POPUP_DELAY = 0.18, 0.08, 0.35
local VIDEO_SLOTS = { main = "main", left = "main", corner = "corner" }

return function(pw)
    local M = {}

    local function looksLikeVideo(title)
        local lower = (title or ""):lower()
        for _, marker in ipairs(pw.config.videoTitleMarkers) do
            if lower:find(marker, 1, true) then return true end
        end
        return false
    end

    local function popups(app)
        local list = {}
        for _, win in ipairs(app:allWindows()) do
            local r = pw:resolve(win)
            if r and r.popup then list[#list + 1] = win end
        end
        return list
    end

    local function tidy(app, video, popupBundles)
        local keep = popups(app)
        if #keep == 0 then
            if popupBundles[app:bundleID()] then
                for _, win in ipairs(app:allWindows()) do win:minimize() end
            end
            if not app:isHidden() then app:hide() end
            return
        end
        local kept = {}
        for _, win in ipairs(keep) do
            if win:id() then kept[win:id()] = true end
            if not pw:_skipped(win) then pw:_place(win, pw:resolve(win), video) end
        end
        for _, win in ipairs(app:allWindows()) do
            if not kept[win:id()] and win:isStandard() then win:minimize() end
        end
    end

    -- The PiP window appears with a delay: send the browser's chord, lay out after.
    local function popOut(app, video, popupBundles, done)
        local chord = pw.catalog.pipChords[app:bundleID()]
        local frontWin = app:focusedWindow() or app:mainWindow()
        if not chord or not frontWin or #popups(app) > 0 or not looksLikeVideo(frontWin:title()) then
            return false
        end
        local id = app:bundleID()
        pw:_after(ACTIVATE_DELAY, function()
            app:activate()
            pw:_after(CHORD_DELAY, function()
                hs.eventtap.keyStroke(chord.mods, chord.key, 0)
                pw:_after(POPUP_DELAY, function()
                    tidy(app, video, popupBundles)
                    done()
                end, "focus:tidy:" .. id)
            end, "focus:chord:" .. id)
        end, "focus:activate:" .. id)
        return true
    end

    function M.videoSlot(name, set)
        if set.video == nil then return "main" end
        return VIDEO_SLOTS[set.video]
            or error("PowerWindows: focus set " .. name .. ": video must be \"main\" or \"corner\", not " .. tostring(set.video), 2)
    end

    function M.has(name)
        return pw.config.focusSets[name] ~= nil
    end

    function M.apply(name)
        local set = pw.config.focusSets[name]
        if not set then return false end
        local video = M.videoSlot(name, set)
        local keep, custom = {}, set.custom or {}
        for _, bundle in ipairs(set.keep or {}) do keep[bundle] = true end
        local popupBundles = pw.catalog.popupBundles()

        local function focus()
            for _, bundle in ipairs(set.focus or {}) do
                local app = hs.application.get(bundle)
                if app then app:activate() return end
            end
        end

        for _, app in ipairs(hs.application.runningApplications()) do
            if app:kind() == 1 then
                local bundle = app:bundleID()
                if custom[bundle] then
                    custom[bundle](app, pw)
                elseif keep[bundle] then
                    if app:isHidden() then app:unhide() end
                    for _, win in ipairs(app:allWindows()) do
                        if win:isMinimized() then win:unminimize() end
                        if not pw:_skipped(win) then pw:placeDefault(win) end
                    end
                elseif not popOut(app, video, popupBundles, focus) then
                    tidy(app, video, popupBundles)
                end
            end
        end
        focus()
        return true
    end

    return M
end
