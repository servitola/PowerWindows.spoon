-- Timers keyed per pid / window id: concurrent launches must not cancel each other.
local POLL_INTERVAL, POLL_TIMEOUT = 0.3, 30 -- Rider (JVM) shows its window slowly
-- Electron re-centers after load: put the window back once, later moves are the user's.
local ENFORCE_INTERVAL, ENFORCE_DURATION, ENFORCE_TOLERANCE = 0.5, 12, 4
-- AX window list is unsettled at windowCreated.
local FINDER_SETTLE = 0.2

return function(pw, opts)
    assert(type(opts.bundles) == "table",
        "PowerWindows: experimental.placeOnLaunch.bundles must be a list of bundle IDs")
    local bundles = {}
    for _, bundle in ipairs(opts.bundles) do bundles[bundle] = true end

    local function target(win)
        local r = pw:resolve(win)
        local screen = win:screen()
        if not r or r.keepAspect or r.device or not screen then return nil end
        if r.slot ~= "main" and r.slot ~= "side" and r.slot ~= "corner" then return nil end
        return pw.geometry.rect(pw.config, r.slot, screen:frame())
    end

    -- Electron recreates the window after load and the old AX object dies: re-fetch each tick.
    local function enforce(app)
        local key, endKey = "launch:enforce:" .. app:pid(), "launch:enforceEnd:" .. app:pid()
        pw:_cancel(endKey)
        pw:_every(ENFORCE_INTERVAL, function()
            if not app:isRunning() then return true end
            local win = app:mainWindow()
            if not win or not win:isStandard() then return end
            local want = target(win)
            local f = win:frame()
            if want and f.w > 0 and not pw.geometry.near(f, want, ENFORCE_TOLERANCE) then
                if not pw:_skipped(win) then pw:placeDefault(win) end
                return true
            end
        end, key)
        pw:_after(ENFORCE_DURATION, function() pw:_cancel(key) end, endKey)
    end

    local function poll(app)
        local key, endKey = "launch:poll:" .. app:pid(), "launch:pollEnd:" .. app:pid()
        pw:_cancel(endKey)
        pw:_every(POLL_INTERVAL, function()
            local win = app:mainWindow()
            if not win or not win:isStandard() then return end
            pw:_cancel(endKey)
            if not pw:_skipped(win) then pw:placeDefault(win) end
            enforce(app)
            return true
        end, key)
        pw:_after(POLL_TIMEOUT, function() pw:_cancel(key) end, endKey)
    end

    local watcher = hs.application.watcher.new(function(_, event, app)
        if event == hs.application.watcher.launched and app and bundles[app:bundleID()] then
            poll(app)
        end
    end):start()

    -- Finder never relaunches: place a window only when it is the only one.
    local finderFilter
    if opts.finderFirstWindow then
        finderFilter = hs.window.filter.new("Finder")
        finderFilter:subscribe(hs.window.filter.windowCreated, function(win)
            pw:_after(FINDER_SETTLE, function()
                if not win:isStandard() then return end
                local app = win:application()
                if not app then return end
                for _, other in ipairs(app:allWindows()) do
                    if other:isStandard() and other:id() ~= win:id() then return end
                end
                if not pw:_skipped(win) then pw:placeDefault(win) end
            end, "launch:finder:" .. tostring(win:id()))
        end)
    end

    return {
        stop = function()
            watcher:stop()
            if finderFilter then finderFilter:delete() end
            pw:_cancelPrefix("launch:")
        end,
    }
end
