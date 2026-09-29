--- === PowerWindows ===
---
--- Every window in its place, one key.
local obj = {}
obj.__index = obj

obj.name = "PowerWindows"
obj.version = "0.1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/servitola/PowerWindows.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local spoonPath = hs.spoons.scriptPath()
local function loadPart(name) return dofile(spoonPath .. name .. ".lua") end
local geometry = loadPart("lib/core/geometry")
local rules = loadPart("lib/core/rules")
local settings = loadPart("lib/core/settings")
local catalog = loadPart("config/catalog")
local DEFAULTS = loadPart("config/settings")
rules.dialogs = loadPart("config/dialogs")
local query = loadPart("lib/window/query")(obj)

function obj:init()
    self.config = settings.defaults(DEFAULTS)
    self._skip = {}
    self.catalog = catalog
    self.geometry = geometry
    return self
end

--- PowerWindows:configure(cfg) -> self
--- Method
--- Merges `cfg` into config/settings.lua defaults; maps merge key by key, a typo raises an error.
function obj:configure(cfg)
    settings.merge(self.config, cfg)
    return self
end

--- PowerWindows:setOverride(bundle, value)
--- Method
--- Sets where `bundle` goes: a slot, `false`, a table, or `nil` to clear.
function obj:setOverride(bundle, value)
    self.config.overrides[bundle] = value
end

--- PowerWindows:addSkipPredicate(fn)
--- Method
--- Windows for which `fn(win)` returns true are never moved.
function obj:addSkipPredicate(fn)
    table.insert(self._skip, fn)
end

--- PowerWindows:resolve([win]) -> table or false
--- Method
--- `{ slot, source, keepAspect, device, popup }` for `win` (default: frontmost), or false.
function obj:resolve(win)
    win = win or query.front()
    if not win then return false end
    if not win:application() then return false end
    return rules.resolve(self.config, catalog.apps, query.info(win), win)
end

--- PowerWindows:slotRect(name[, screen]) -> rect
--- Method
--- Frame of main, side, corner, video, full, halfLeft, halfRight, top60, bottom40 or column.
function obj:slotRect(name, screen)
    return geometry.rect(self.config, name, (screen or hs.screen.mainScreen()):frame())
end

loadPart("lib/window/timers")(obj)
loadPart("lib/window/place")(obj, geometry, query.front, query.screenFrame)
loadPart("lib/window/stack")(obj, geometry)
loadPart("lib/window/actions")(obj, geometry, query.front, query.screenFrame)
loadPart("lib/window/minimize")(obj)

return obj
