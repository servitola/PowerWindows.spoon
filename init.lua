--- === PowerWindows ===
---
--- Every window in its place, one key.
local powerWindows = {}
powerWindows.__index = powerWindows

powerWindows.name = "PowerWindows"
powerWindows.version = "0.2.0"
powerWindows.author = "servitola"
powerWindows.homepage = "https://github.com/servitola/PowerWindows.spoon"
powerWindows.license = "MIT - https://opensource.org/licenses/MIT"

local spoonPath = hs.spoons.scriptPath()
local function loadPart(name) return dofile(spoonPath .. name .. ".lua") end
local geometry = loadPart("lib/core/geometry")
local rules = loadPart("lib/core/rules")
local settings = loadPart("lib/core/settings")
local catalog = loadPart("config/catalog")
local dialogs = loadPart("config/dialogs")
local DEFAULTS = loadPart("config/settings")
local createFocusSets = loadPart("lib/features/focus")
local startPlaceOnLaunch = loadPart("lib/features/launch")

local query = loadPart("lib/window/query")(powerWindows, settings)
loadPart("lib/window/timers")(powerWindows)
loadPart("lib/window/place")(powerWindows, geometry, query)
loadPart("lib/window/stack")(powerWindows, geometry, query)
loadPart("lib/window/actions")(powerWindows, geometry, query)
loadPart("lib/window/minimize")(powerWindows, query)
loadPart("lib/features/hotkeys")(powerWindows, settings.ACTIONS)
loadPart("lib/features/globe")(powerWindows, settings)
loadPart("lib/features/screens")(powerWindows, geometry, rules, query)

-- An unknown slot would otherwise surface only when a window of that app is placed.
local function checkOverrides(overrides)
    for _, value in pairs(overrides) do rules.normalize(value, "override") end
end

local function release(self)
    for _, hotkey in ipairs(self._hotkeys) do hotkey:delete() end
    self._hotkeys = {}
    if self._launch then self._launch.stop() self._launch = nil end
    self:_stopGlobe()
    self:_stopScreenWatcher()
end

function powerWindows:init()
    self.config = settings.copy(DEFAULTS)
    self._skip = {}
    self._hotkeys = {}
    self._userHotkeys = {}
    self._focus = createFocusSets(self, catalog)
    return self
end

--- PowerWindows:configure(config) -> self
--- Method
--- Merges `config` into the current settings: maps key by key, one level deep; lists replaced.
--- A typo or a wrong type raises, nested keys included.
function powerWindows:configure(config)
    local merged = settings.merge(settings.copy(self.config), config)
    settings.validate(merged, settings.ACTIONS, hs.keycodes.map)
    checkOverrides(merged.overrides)
    settings.merge(self.config, config)
    return self
end

--- PowerWindows:setOverride(bundle, value)
--- Method
--- Sets where `bundle` goes: a slot, `false`, a table, or `nil` to clear.
function powerWindows:setOverride(bundle, value)
    if value ~= nil then rules.normalize(value, "override") end
    self.config.overrides[bundle] = value
end

--- PowerWindows:addSkipPredicate(predicate)
--- Method
--- Windows for which `predicate(window)` returns true are never moved automatically; a predicate that errors
--- counts as false.
function powerWindows:addSkipPredicate(predicate)
    table.insert(self._skip, predicate)
end

--- PowerWindows:resolve([window]) -> table or false
--- Method
--- `{ slot, source, keepAspect, device, popup }` for `window` (default: focused), or false.
powerWindows.resolve = query.withWindow(function(self, window)
    if not window:application() then return false end
    return rules.resolve(self.config, catalog.apps, dialogs, query.info(window), window)
end, false)

--- PowerWindows:slotRect(name[, screen]) -> rect
--- Method
--- Frame of `name` on `screen` (default: main screen): main, side, corner, video, full, halfLeft, halfRight, top60,
--- bottom40 or column.
function powerWindows:slotRect(name, screen)
    local config, screenFrame = self:_screenLayout(screen or hs.screen.mainScreen())
    return geometry.rect(config, name, screenFrame)
end

--- PowerWindows:start() -> self
--- Method
--- Binds the default chords; starts Globe keys, screen watcher and place-on-launch when enabled. Calling again rebinds.
function powerWindows:start()
    settings.validate(self.config, settings.ACTIONS, hs.keycodes.map)
    release(self)
    if self.config.hotkeys then self:_bind(self:defaultHotkeys(), self._hotkeys) end
    for _, hotkey in ipairs(self._userHotkeys) do hotkey:enable() end
    self:_startGlobe()
    self:_startScreenWatcher()
    local launch = self.config.experimental.placeOnLaunch
    if launch then self._launch = startPlaceOnLaunch(self, geometry, launch) end
    return self
end

--- PowerWindows:stop() -> self
--- Method
--- Deletes the default chords, disables `bindHotkeys` ones until `start()`, gives the Globe keys back,
--- stops the screen watcher and place-on-launch.
function powerWindows:stop()
    release(self)
    for _, hotkey in ipairs(self._userHotkeys) do hotkey:disable() end
    return self
end

--- PowerWindows:focusSet(name) -> boolean
--- Method
--- Applies `config.focusSets[name]`; false if absent, error if `video` is not "main"/"left"/"corner".
function powerWindows:focusSet(name) return self._focus.apply(name) end

return powerWindows
