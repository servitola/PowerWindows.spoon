return function(obj, geometry)
    function obj:_stackWindows(screen)
        local list = {}
        for _, win in ipairs(hs.window.visibleWindows()) do
            local s = win:screen()
            if s and s:id() == screen:id() and win:isStandard() and not self:_skipped(win) then
                local r = self:resolve(win)
                if r and r.slot == "stack" then list[#list + 1] = { win = win, r = r } end
            end
        end
        table.sort(list, function(a, b) return a.win:id() < b.win:id() end)
        return list
    end

    function obj:_placeStack(screen)
        local list = self:_stackWindows(screen)
        if #list == 0 then return end
        if #list == 1 then return self:_place(list[1].win, list[1].r, "stack") end
        local cells = geometry.stackCells(self.config, screen:frame(), #list)
        for i, item in ipairs(list) do
            if item.r.keepAspect then
                self:_fit(item.win, cells[i], "topLeft")
            else
                self:_set(item.win, cells[i])
            end
        end
    end
end
