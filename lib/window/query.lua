return function(obj)
    local M = {}

    function M.front() return hs.window.frontmostWindow() end

    function M.screenFrame(win)
        local screen = win:screen()
        return screen and screen:frame()
    end

    function M.info(win)
        local app = win:application()
        local f = win:frame()
        return { bundle = app and app:bundleID(), app = app and app:title() or "",
                 title = win:title() or "", w = f.w, h = f.h }
    end

    function obj:_skipped(win)
        for _, fn in ipairs(self._skip) do
            local ok, skip = pcall(fn, win)
            if ok and skip then return true end
        end
        return false
    end

    function obj:isDecoration(win)
        win = win or M.front()
        if not win then return false end
        local r = self:resolve(win)
        return r == false or (r.slot == "corner" and r.keepAspect == true)
    end

    return M
end
