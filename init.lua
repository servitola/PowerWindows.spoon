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
    self._hotkeys = {}
    self._userHotkeys = {}
    self.catalog = catalog
    self.geometry = geometry
    self._focus = loadPart("lib/features/focus")(self)
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

local function deleteAll(hotkeys)
    for _, hotkey in ipairs(hotkeys) do hotkey:delete() end
    return {}
end

local function release(self)
    self._hotkeys = deleteAll(self._hotkeys)
    if self._launch then self._launch.stop() self._launch = nil end
    self:_stopGlobe()
end

--- PowerWindows:start() -> self
--- Method
--- Binds the default chords, takes macOS's Globe window keys, starts place-on-launch; again = rebind.
function obj:start()
    release(self)
    if self.config.hotkeys then self:_bind(self:defaultHotkeys(), self._hotkeys) end
    self:_startGlobe()
    local launch = self.config.experimental.placeOnLaunch
    if launch then self._launch = loadPart("lib/features/launch")(self, launch) end
    return self
end

--- PowerWindows:stop() -> self
--- Method
--- Deletes all chords, gives the Globe keys back, stops place-on-launch.
function obj:stop()
    release(self)
    self._userHotkeys = deleteAll(self._userHotkeys)
    return self
end

--- PowerWindows:focusSet(name) -> boolean
--- Method
--- Applies `config.focusSets[name]`; false if absent, error if `video` is not "main"/"left"/"corner".
function obj:focusSet(name) return self._focus.apply(name) end
function obj:hasFocusSet(name) return self._focus.has(name) end

loadPart("lib/window/timers")(obj)
loadPart("lib/window/place")(obj, geometry, query.front, query.screenFrame)
loadPart("lib/window/stack")(obj, geometry)
loadPart("lib/window/actions")(obj, geometry, query.front, query.screenFrame)
loadPart("lib/window/minimize")(obj)
loadPart("lib/features/hotkeys")(obj, settings.ACTIONS)
loadPart("lib/features/globe")(obj, settings)

return obj
