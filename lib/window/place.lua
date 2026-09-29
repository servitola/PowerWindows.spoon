local ASPECT_AREA = { main = "main", full = "full", corner = "video", side = "side" }
local ASPECT_ANCHOR = { main = "topLeft", full = "center", corner = "top", side = "topLeft" }

return function(obj, geometry, front, screenFrame)
    function obj:_set(win, rect)
        win:setFrame(rect, self.config.animation)
    end

    -- Chromium PiP caps at ~80% of the requested area but keeps the top-left: size, read back, position.
    function obj:_fit(win, box, anchor)
        local current = win:frame()
        if current.w == 0 or current.h == 0 then return end
        win:setFrame(geometry.fit(box, current.h / current.w, anchor), 0)
        local actual = win:frame()
        local pos = geometry.anchor(box, actual.w, actual.h, anchor)
        win:setTopLeft({ x = pos.x, y = pos.y })
    end

    function obj:_placeDevice(win, sf, where)
        local current = win:frame()
        if current.w == 0 or current.h == 0 then return end
        local c = self.config
        local w, h = geometry.deviceSize(c, sf, current.h / current.w)
        local raise = sf.h * c.device.raise
        local x, y
        if where == "full" then
            x, y = sf.x + (sf.w - w) / 2, sf.y + (sf.h - h) / 2 - raise
        elseif where == "main" then
            x, y = sf.x + sf.w * c.gap, sf.y + (sf.h - h) / 2 - raise
        else
            x, y = sf.x + sf.w * c.split, sf.y + sf.h * c.gap
        end
        self:_set(win, { x = x, y = y, w = w, h = h })
    end

    function obj:_place(win, r, where)
        local sf = screenFrame(win)
        if not sf then return end
        where = where or r.slot
        local c = self.config
        if where == "dialog" then
            self:_set(win, geometry.smallDialog(c, sf, win:frame()))
        elseif r.device then
            self:_placeDevice(win, sf, where)
        elseif where == "stack" then
            self:_set(win, geometry.rect(c, "side", sf))
        elseif r.keepAspect then
            self:_fit(win, geometry.rect(c, ASPECT_AREA[where], sf), ASPECT_ANCHOR[where])
        else
            self:_set(win, geometry.rect(c, where, sf))
        end
    end

    --- PowerWindows:placeDefault([win])
    --- Method
    --- Puts `win` (default: frontmost) in its slot; a stack window re-lays the column.
    function obj:placeDefault(win)
        win = win or front()
        if not win then return end
        local r = self:resolve(win)
        if not r then return end
        if r.slot == "stack" then
            local screen = win:screen()
            if screen then self:_placeStack(screen) end
            return
        end
        self:_place(win, r)
    end

    --- PowerWindows:moveLeft([win])
    --- Method
    --- Puts `win` (default: frontmost) into the big left slot.
    function obj:moveLeft(win)
        win = win or front()
        if not win then return end
        self:_place(win, self:resolve(win) or { slot = "main" }, "main")
    end

    --- PowerWindows:moveRight([win])
    --- Method
    --- Puts `win` (default: frontmost) into the right column; corner and dialog keep their slot.
    function obj:moveRight(win)
        win = win or front()
        if not win then return end
        local r = self:resolve(win) or { slot = "side" }
        if r.slot == "stack" then
            local screen = win:screen()
            if screen then self:_placeStack(screen) end
            return
        end
        local where = (r.slot == "corner" or r.slot == "dialog") and r.slot or "side"
        self:_place(win, r, where)
    end

    --- PowerWindows:moveFull([win])
    --- Method
    --- Stretches `win` (default: frontmost) over the screen with gaps; not native fullscreen.
    function obj:moveFull(win)
        win = win or front()
        if not win then return end
        self:_place(win, self:resolve(win) or { slot = "main" }, "full")
    end

    function obj:_isAt(win, name)
        local sf = screenFrame(win)
        return sf ~= nil and geometry.near(win:frame(), geometry.rect(self.config, name, sf), self.config.tolerance)
    end
end
