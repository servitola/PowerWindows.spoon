return function(powerWindows, settings)
    local query = {}

    -- Not frontmostWindow: that is the always-on-top PiP player, not the window being worked in.
    function query.focused() return hs.window.focusedWindow() end

    -- A method whose window defaults to the focused one; with no window it returns whenNone.
    function query.withWindow(body, whenNone)
        return function(self, window, ...)
            window = window or query.focused()
            if not window then return whenNone end
            return body(self, window, ...)
        end
    end

    function query.isOnScreen(window, screen)
        local own = window:screen()
        return own ~= nil and own:id() == screen:id()
    end

    -- Profile chosen by the full frame (screen shape), layout on the usable frame (no menu bar, no Dock).
    function powerWindows:_screenLayout(screen)
        local full = screen:fullFrame()
        return settings.forScreen(self.config, { name = screen:name(), w = full.w, h = full.h }), screen:frame()
    end

    function powerWindows:_screenLayoutOf(window, screen)
        screen = screen or window:screen()
        if screen then return self:_screenLayout(screen) end
    end

    function query.info(window)
        local app = window:application()
        local frame = window:frame()
        return { bundle = app and app:bundleID(), app = app and app:title() or "",
                 title = window:title() or "", w = frame.w, h = frame.h }
    end

    function powerWindows:_skipped(window)
        for _, predicate in ipairs(self._skip) do
            local ok, skip = pcall(predicate, window)
            if ok and skip then return true end
        end
        return false
    end

    --- PowerWindows:isDecoration([window]) -> boolean
    --- Method
    --- True for never-touched windows and fitted corner video (PiP); swaps and focus-next skip them.
    powerWindows.isDecoration = query.withWindow(function(self, window)
        local resolved = self:resolve(window)
        return resolved == false or (resolved.slot == "corner" and resolved.keepAspect == true)
    end, false)

    -- A window that swaps and focus-next may pick.
    function powerWindows:_isCandidate(window)
        return window:isStandard() and window:isVisible() and not self:isDecoration(window)
    end

    return query
end
