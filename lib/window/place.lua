-- Video in the corner fits the video box, which keeps a gap above the bottom edge.
local ASPECT_AREA = { main = "main", full = "full", corner = "video", side = "side" }
local ASPECT_ANCHOR = { main = "topLeft", full = "center", corner = "top", side = "topLeft" }

return function(powerWindows, geometry, query)
    local withWindow = query.withWindow

    function powerWindows:_write(window, rect) window:setFrame(rect, 0) end

    function powerWindows:_set(window, rect) window:setFrame(rect, self.config.animation) end

    -- Chromium PiP caps at ~80% of the requested area but keeps the top-left: size, read back, position.
    function powerWindows:_fit(window, box, anchor)
        local current = window:frame()
        if current.w == 0 or current.h == 0 then return end
        self:_write(window, geometry.fit(box, current.h / current.w, anchor))
        local actual = window:frame()
        local position = geometry.anchor(box, actual.w, actual.h, anchor)
        window:setTopLeft({ x = position.x, y = position.y })
    end

    function powerWindows:_placeDevice(window, config, screenFrame, slot)
        local current = window:frame()
        if current.w == 0 or current.h == 0 then return end
        self:_set(window, geometry.devicePlace(config, screenFrame, current.h / current.w, slot))
    end

    function powerWindows:_place(window, resolved, slot, screen)
        local config, screenFrame = self:_screenLayoutOf(window, screen)
        if not screenFrame then return end
        slot = slot or resolved.slot
        if slot == "dialog" then
            self:_set(window, geometry.smallDialog(config, screenFrame, window:frame()))
        elseif resolved.device then
            self:_placeDevice(window, config, screenFrame, slot)
        elseif slot == "stack" then
            self:_set(window, geometry.rect(config, "side", screenFrame))
        elseif resolved.keepAspect then
            self:_fit(window, geometry.rect(config, ASPECT_AREA[slot], screenFrame), ASPECT_ANCHOR[slot])
        else
            self:_set(window, geometry.rect(config, slot, screenFrame))
        end
    end

    local function restackColumnOf(self, window)
        local screen = window:screen()
        if screen then self:_placeStack(screen) end
    end

    function powerWindows:_resolveOr(window, slot)
        return self:resolve(window) or { slot = slot }
    end

    --- PowerWindows:placeDefault([window])
    --- Method
    --- Puts `window` (default: frontmost) in its slot; a stack window re-lays the column.
    powerWindows.placeDefault = withWindow(function(self, window)
        local resolved = self:resolve(window)
        if not resolved then return end
        if resolved.slot == "stack" then return restackColumnOf(self, window) end
        self:_place(window, resolved)
    end)

    --- PowerWindows:moveLeft([window])
    --- Method
    --- Puts `window` (default: frontmost) into the big left slot.
    powerWindows.moveLeft = withWindow(function(self, window)
        self:_place(window, self:_resolveOr(window, "main"), "main")
    end)

    --- PowerWindows:moveRight([window])
    --- Method
    --- Puts `window` (default: frontmost) into the right column; corner and dialog keep their slot, a stack window re-lays the column.
    powerWindows.moveRight = withWindow(function(self, window)
        local resolved = self:_resolveOr(window, "side")
        if resolved.slot == "stack" then return restackColumnOf(self, window) end
        local slot = (resolved.slot == "corner" or resolved.slot == "dialog") and resolved.slot or "side"
        self:_place(window, resolved, slot)
    end)

    --- PowerWindows:moveFull([window])
    --- Method
    --- Stretches `window` (default: frontmost) over the screen with gaps; not native fullscreen.
    powerWindows.moveFull = withWindow(function(self, window)
        self:_place(window, self:_resolveOr(window, "main"), "full")
    end)

    function powerWindows:_isAt(window, area)
        local config, screenFrame = self:_screenLayoutOf(window)
        return screenFrame ~= nil
            and geometry.near(window:frame(), geometry.rect(config, area, screenFrame), self.config.tolerance)
    end
end
