-- Hammerspoon GCs unreferenced timers mid-chain: hold each until it ends.
-- A new timer under the same key cancels the old one.
return function(obj)
    local pending = {}
    local keyed = {}

    local function hold(timer, key)
        if key then keyed[key] = timer else pending[timer] = true end
    end

    local function drop(timer, key)
        if not key then
            pending[timer] = nil
        elseif keyed[key] == timer then
            keyed[key] = nil
        end
    end

    function obj:_cancel(key)
        local timer = keyed[key]
        if timer then
            timer:stop()
            keyed[key] = nil
        end
    end

    function obj:_cancelPrefix(prefix)
        for key in pairs(keyed) do
            if key:sub(1, #prefix) == prefix then self:_cancel(key) end
        end
    end

    function obj:_after(delay, fn, key)
        if key then self:_cancel(key) end
        local timer
        timer = hs.timer.doAfter(delay, function()
            drop(timer, key)
            fn()
        end)
        hold(timer, key)
    end

    -- fn returns true to stop repeating.
    function obj:_every(interval, fn, key)
        if key then self:_cancel(key) end
        local timer
        timer = hs.timer.doEvery(interval, function()
            if fn() then
                timer:stop()
                drop(timer, key)
            end
        end)
        hold(timer, key)
    end

    function obj:_waitUntil(predicate, action, interval, timeout)
        local waiter = hs.timer.waitUntil(predicate, function(timer)
            pending[timer] = nil
            action()
        end, interval)
        pending[waiter] = true
        self:_after(timeout, function()
            waiter:stop()
            pending[waiter] = nil
        end)
    end
end
