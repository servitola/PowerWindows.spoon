local M = {}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end

-- Empty table = map, so `overrides = {}` merges.
local function isMap(value)
    return type(value) == "table" and value[1] == nil
end

function M.defaults(source)
    return copy(source)
end

M.ACTIONS = {}
for _, name in ipairs({
    "left", "right", "fullscreen", "arrangeAll", "halfLeft", "halfRight", "top60", "bottom40",
    "center", "swapSides", "minimizeAndFocusNext", "minimizeCurrent",
}) do M.ACTIONS[name] = true end

-- keyCode → action, keyCode → true when the key needs the tracked Globe press;
-- macOS itself puts the fn flag on arrows and other named keys, never on a character.
function M.macosKeys(value, actions, keycodes)
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

function M.merge(current, changes)
    for key, value in pairs(changes) do
        if current[key] == nil then
            error("PowerWindows: unknown setting '" .. tostring(key) .. "' (see config/settings.lua)", 3)
        end
        if isMap(current[key]) and isMap(value) then
            for k, v in pairs(value) do current[key][k] = v end
        else
            current[key] = value
        end
    end
    return current
end

return M
