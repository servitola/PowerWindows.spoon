local FULLSCREEN_POLL, FULLSCREEN_TIMEOUT = 0.1, 3
local AFTER_FULLSCREEN = 0.2

return function(obj, geometry, front, screenFrame)
    local function leaveFullscreenThen(pw, win, place)
        win:setFullScreen(false)
        pw:_waitUntil(
            function() return not win:isFullScreen() end,
            function() pw:_after(AFTER_FULLSCREEN, function() place(win) end) end,
            FULLSCREEN_POLL, FULLSCREEN_TIMEOUT)
    end

    function obj:left(win)
        win = win or front()
        if not win then return end
        if win:isFullScreen() then return leaveFullscreenThen(self, win, function(w) self:moveLeft(w) end) end
        if self:_isAt(win, "main") then self:halfLeft(win) else self:moveLeft(win) end
    end

    function obj:right(win)
        win = win or front()
        if not win then return end
        if win:isFullScreen() then return leaveFullscreenThen(self, win, function(w) self:moveRight(w) end) end
        if self:_isAt(win, "side") then self:halfRight(win) else self:moveRight(win) end
    end

    function obj:fullscreen(win)
        win = win or front()
        if not win or win:isFullScreen() then return end
        if self:_isAt(win, "full") then win:setFullScreen(true) else self:moveFull(win) end
    end

    local function simpleMove(name)
        return function(self, win)
            win = win or front()
            local sf = win and screenFrame(win)
            if sf then self:_set(win, geometry.rect(self.config, name, sf)) end
        end
    end
    obj.halfLeft = simpleMove("halfLeft")
    obj.halfRight = simpleMove("halfRight")
    obj.top60 = simpleMove("top60")
    obj.bottom40 = simpleMove("bottom40")

    function obj:center(win)
        win = win or front()
        local sf = win and screenFrame(win)
        if not sf then return end
        local f = win:frame()
        f.x = sf.x + (sf.w - f.w) / 2
        f.y = sf.y + (sf.h - f.h) / 2
        win:setFrame(f, 0)
    end

    --- PowerWindows:arrangeAll()
    --- Method
    --- Puts every window in its slot; a native fullscreen front window only leaves fullscreen.
    function obj:arrangeAll()
        local win = front()
        if win and win:isFullScreen() then
            win:setFullScreen(false)
            return
        end
        self:arrangeAllNow()
    end

    --- PowerWindows:arrangeAllNow()
    --- Method
    --- Same, without the fullscreen check; skips background windows stretched full.
    function obj:arrangeAllNow()
        local frontmost = front()
        local stackScreens = {}
        for _, win in ipairs(hs.window.allWindows()) do
            if not self:_skipped(win) then
                local r = self:resolve(win)
                if r and r.slot == "stack" then
                    local screen = win:screen()
                    if screen then stackScreens[screen:id()] = screen end
                elseif r and not (r.slot == "main" and win ~= frontmost and self:_isAt(win, "full")) then
                    self:_place(win, r)
                end
            end
        end
        for _, screen in pairs(stackScreens) do self:_placeStack(screen) end
    end

    --- PowerWindows:swapSides()
    --- Method
    --- Swaps the two topmost windows of the focused screen, left and right.
    function obj:swapSides()
        local focused = hs.window.focusedWindow()
        local screen = focused and focused:screen() or hs.screen.mainScreen()
        if not screen then return end
        local top = {}
        for _, win in ipairs(hs.window.orderedWindows()) do
            if win:isStandard() and win:isVisible() and not self:isDecoration(win)
                and win:screen() and win:screen():id() == screen:id() then
                top[#top + 1] = win
                if #top == 2 then break end
            end
        end
        if #top < 2 then return end
        local function centerX(win) local f = win:frame() return f.x + f.w / 2 end
        -- Sides by position, not stacking order.
        local leftWin, rightWin = top[1], top[2]
        if centerX(leftWin) > centerX(rightWin) then leftWin, rightWin = rightWin, leftWin end
        self:moveRight(leftWin)
        self:moveLeft(rightWin)
    end
end
