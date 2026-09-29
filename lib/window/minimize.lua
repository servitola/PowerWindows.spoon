local FULLSCREEN_POLL, FULLSCREEN_TIMEOUT = 0.1, 3
local AFTER_FULLSCREEN = 0.6
local RETRY_INTERVAL, RETRIES = 0.3, 4
local MINIMIZED_POLL, MINIMIZED_TIMEOUT = 0.05, 2.5
local REFOCUS_DELAY = 0.35

return function(obj)
    --- PowerWindows:minimizeCurrent()
    --- Method
    --- Minimizes the focused window.
    function obj:minimizeCurrent()
        local win = hs.window.focusedWindow()
        if win then win:minimize() end
    end

    -- macOS does not pass focus on after minimize; Hide is no substitute: refused for the last visible app.
    function obj:_pickNext(ordered, current, sameApp, screenId)
        local app = current:application()
        local pid = app and app:pid()
        for _, win in ipairs(ordered) do
            if win:id() ~= current:id() and win:isStandard() and win:isVisible() and not self:isDecoration(win) then
                local owner = win:application()
                local samePid = owner and owner:pid() == pid
                if samePid == sameApp and (screenId == nil or (win:screen() and win:screen():id() == screenId)) then
                    return win
                end
            end
        end
    end

    --- PowerWindows:minimizeAndFocusNext([win])
    --- Method
    --- Minimizes `win` (default: focused), focuses the next: same app, then same screen first.
    function obj:minimizeAndFocusNext(win)
        -- Not frontmostWindow: that is the always-on-top PiP player.
        win = win or hs.window.focusedWindow()
        if not win then return end

        -- Fullscreen owns its Space and cannot minimize.
        if win:isFullScreen() then
            win:setFullScreen(false)
            self:_waitUntil(
                function() return not win:isFullScreen() end,
                function() self:_after(AFTER_FULLSCREEN, function() self:minimizeAndFocusNext(win) end) end,
                FULLSCREEN_POLL, FULLSCREEN_TIMEOUT)
            return
        end

        local screen = win:screen()
        local screenId = screen and screen:id()
        local ordered = hs.window.orderedWindows()
        local nextWin = self:_pickNext(ordered, win, true, screenId)
            or self:_pickNext(ordered, win, true, nil)
            or self:_pickNext(ordered, win, false, screenId)
            or self:_pickNext(ordered, win, false, nil)

        -- Minimize first: minimizing a background window silently fails.
        win:minimize()
        -- Rejected during the leave-fullscreen animation.
        local tries = 0
        self:_every(RETRY_INTERVAL, function()
            tries = tries + 1
            if win:isMinimized() or tries > RETRIES then return true end
            win:minimize()
        end)

        if not nextWin then return end
        local function takeFocus()
            -- Bare focus() may raise another window of the app (Hammerspoon#370).
            local app = nextWin:application()
            if app then app:activate(true) end
            nextWin:raise():focus()
        end
        self:_waitUntil(
            function() return win:isMinimized() end,
            function()
                takeFocus()
                -- The minimize animation hands activation back to the previous app.
                self:_after(REFOCUS_DELAY, function()
                    local focused = hs.window.focusedWindow()
                    if not focused or focused:id() ~= nextWin:id() then takeFocus() end
                end)
            end,
            MINIMIZED_POLL, MINIMIZED_TIMEOUT)
    end
end
