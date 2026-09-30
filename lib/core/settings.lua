local settings = {}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, field in pairs(value) do result[key] = copy(field) end
    return result
end

-- Empty table = map, so `overrides = {}` merges.
local function isMap(value)
    return type(value) == "table" and value[1] == nil
end

settings.copy = copy

settings.ACTIONS = {}
for _, name in ipairs({
    "left", "right", "fullscreen", "arrangeAll", "halfLeft", "halfRight", "top60", "bottom40",
    "center", "swapSides", "minimizeAndFocusNext", "minimizeCurrent",
}) do settings.ACTIONS[name] = true end

-- keyCode → action, keyCode → true when the key needs the tracked Globe press;
-- macOS itself puts the fn flag on arrows and other named keys, never on a character.
function settings.macosKeys(value, actions, keycodes)
    if not value then return nil end
    local byCode, needsGlobe = {}, {}
    for key, action in pairs(value) do
        if action ~= false then
            if not actions[action] then
                error("PowerWindows: macosKeys." .. tostring(key) .. ": unknown action '" .. tostring(action) .. "'", 0)
            end
            local code = keycodes[key]
                or error("PowerWindows: macosKeys: unknown key '" .. tostring(key) .. "'", 0)
            byCode[code] = action
            if #key > 1 then needsGlobe[code] = true end
        end
    end
    return byCode, needsGlobe
end

-- Level 3 points the error at the configure call.
function settings.merge(current, changes)
    for key, value in pairs(changes) do
        if current[key] == nil then
            error("PowerWindows: unknown setting '" .. tostring(key) .. "' (see config/settings.lua)", 3)
        end
        if isMap(current[key]) and isMap(value) then
            for innerKey, innerValue in pairs(value) do current[key][innerKey] = innerValue end
        else
            current[key] = value
        end
    end
    return current
end

return settings
