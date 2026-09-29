return function(obj, actions)
    function obj:defaultHotkeys()
        local mapping = {}
        local function add(chords, mods)
            for action, key in pairs(chords) do
                mapping[action] = mapping[action] or {}
                table.insert(mapping[action], { mods, key })
            end
        end
        local keys = self.config.keys
        add(keys.arrows, keys.mods)
        add(keys.shiftedArrows, keys.shiftMods)
        if self.config.wasd then
            add(keys.letters, keys.mods)
            add(keys.shiftedLetters, keys.shiftMods)
        end
        return mapping
    end

    function obj:_bind(mapping, into)
        for action, spec in pairs(mapping) do
            assert(actions[action], "PowerWindows: unknown action " .. tostring(action))
            local chords = type(spec[2]) == "string" and { spec } or spec
            for _, chord in ipairs(chords) do
                table.insert(into, hs.hotkey.bind(chord[1], chord[2], function() self[action](self) end))
            end
        end
    end

    --- PowerWindows:bindHotkeys(mapping)
    --- Method
    --- Binds `{ action = {mods, key} }` or a list of chords per action; survives `start()`.
    function obj:bindHotkeys(mapping)
        self:_bind(mapping, self._userHotkeys)
        return self
    end
end
