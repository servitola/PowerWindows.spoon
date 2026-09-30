-- Video in the corner fits the video box, which keeps a gap above the bottom edge.
local ASPECT_AREA = { main = "main", full = "full", corner = "video", side = "side" }
local ASPECT_ANCHOR = { main = "topLeft", full = "center", corner = "top", side = "topLeft" }

local axuielement = require("hs.axuielement")

local SAME_SIZE_TOLERANCE = 0.5 -- points; sub-point differences are rounding
local CLAMP_TOLERANCE = 2       -- points; a larger miss after a write was clamped
local ANIMATION_FRAME = 1 / 60

local function missed(got, rect)
    return math.abs(got.x - rect.x) > CLAMP_TOLERANCE or math.abs(got.y - rect.y) > CLAMP_TOLERANCE
        or math.abs(got.w - rect.w) > CLAMP_TOLERANCE or math.abs(got.h - rect.h) > CLAMP_TOLERANCE
end

-- One AX write per property: hs.window:setFrame always writes size, position, size, and
-- Telegram and Zap repaint for each (measured 2–3 frames over up to 400 ms, against one).
-- Grow = move first, shrink = resize first, so the window is never oversized in the old spot.
local function writeFrame(window, element, rect, correct)
    local frame = window:frame()
    local position, size = { x = rect.x, y = rect.y }, { w = rect.w, h = rect.h }
    if math.abs(rect.w - frame.w) < SAME_SIZE_TOLERANCE and math.abs(rect.h - frame.h) < SAME_SIZE_TOLERANCE then
        element:setAttributeValue("AXPosition", position)
    elseif rect.w * rect.h > frame.w * frame.h then
        element:setAttributeValue("AXPosition", position)
        element:setAttributeValue("AXSize", size)
    else
        element:setAttributeValue("AXSize", size)
        element:setAttributeValue("AXPosition", position)
    end
    -- A frame clamped by the screen edge (size, or position moved by macOS on a screen change)
    -- lands on a retry, like setFrame's third step, but only when it is needed.
    if correct and missed(window:frame(), rect) then
        element:setAttributeValue("AXSize", size)
        element:setAttributeValue("AXPosition", position)
    end
end

-- correct = false: skip the retry (animation steps, a size that is read back anyway).
local function write(window, rect, correct)
    local application = window:application()
    if not application then return end
    local app = axuielement.applicationElement(application)
    -- Chromium and Electron animate every AX write while AXEnhancedUserInterface is on; Rectangle,
    -- Amethyst, Phoenix and hs.window:setFrame lift it the same way. Restored even when a write
    -- fails: left off, it breaks VoiceOver for that app.
    local enhanced = app and app:attributeValue("AXEnhancedUserInterface")
    if enhanced then app:setAttributeValue("AXEnhancedUserInterface", false) end
    local written, problem = pcall(writeFrame, window, axuielement.windowElement(window), rect, correct ~= false)
    if enhanced then app:setAttributeValue("AXEnhancedUserInterface", true) end
    if not written then error(problem, 0) end
end

return function(powerWindows, geometry, query)
    local withWindow = query.withWindow

    local function moveKey(window) return "move:" .. tostring(window:id()) end

    -- Every direct write first stops a running animation, or its next step drags the window back.
    function powerWindows:_write(window, rect)
        self:_cancel(moveKey(window))
        write(window, rect)
    end

    -- Time-based, so a slow app drops steps instead of stretching the move; every step is one
    -- ordered write, and a new move of the same window cancels the old one.
    function powerWindows:_set(window, rect)
        local key = moveKey(window)
        self:_cancel(key)
        local from = window:frame()
        if geometry.near(from, rect, SAME_SIZE_TOLERANCE) then return end
        local duration = self.config.animation
        if duration <= 0 then return write(window, rect) end
        local start = hs.timer.secondsSinceEpoch()
        self:_every(ANIMATION_FRAME, function()
            local progress = math.min(1, (hs.timer.secondsSinceEpoch() - start) / duration)
            local eased = 1 - (1 - progress) ^ 3
            if progress >= 1 then
                write(window, rect)
                return true
            end
            write(window, {
                x = from.x + (rect.x - from.x) * eased, y = from.y + (rect.y - from.y) * eased,
                w = from.w + (rect.w - from.w) * eased, h = from.h + (rect.h - from.h) * eased,
            }, false)
        end, key)
    end

    -- Chromium PiP caps at ~80% of the requested area but keeps the top-left: size, read back, position.
    function powerWindows:_fit(window, box, anchor)
        local current = window:frame()
        if current.w == 0 or current.h == 0 then return end
        self:_cancel(moveKey(window))
        write(window, geometry.fit(box, current.h / current.w, anchor), false)
        local actual = window:frame()
        write(window, geometry.anchor(box, actual.w, actual.h, anchor))
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
