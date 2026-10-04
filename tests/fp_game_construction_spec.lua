-- Run in a disposable game session via the debug adapter, after classes are built.
-- Uses the current engine's points, snapping, Activate and passage predicates.
-- Preview/map fixtures avoid placing objects or changing a colony/savegame.
local function require_value(value, message)
    if not value then error(message, 2) end
    return value
end

local live_controller = require_value(rawget(_G, "GridConstructionController"), "Grid controller is unavailable")
local live_activate, live_update_cursor = live_controller.Activate, live_controller.UpdateCursor
local original_activate, original_update_cursor = live_activate, live_update_cursor
local loaded_mod = Mods.FlexiblePassages
local loaded_f = rawget(_G, "FlexiblePassages")
if not loaded_f and loaded_mod and type(loaded_mod.env) == "table" then
    loaded_f = rawget(loaded_mod.env, "FlexiblePassages")
end
if loaded_f and live_activate == loaded_f.State.patched_activate then
    original_activate = loaded_f.State.original_activate
end
if loaded_f and live_update_cursor == loaded_f.State.patched_update_cursor then
    original_update_cursor = loaded_f.State.original_update_cursor
end
local controller_class = {
    Activate = original_activate, UpdateCursor = original_update_cursor,
    UpdateVisuals = live_controller.UpdateVisuals,
    CanCompletePassage = live_controller.CanCompletePassage,
    CanContinuePassage = live_controller.CanContinuePassage,
}
local env = setmetatable({
    OnMsg = {}, GridConstructionController = controller_class,
    HexGetNearestCenter = HexGetNearestCenter, FixConstructPos = FixConstructPos,
    GetConstructionTerrainPos = GetConstructionTerrainPos, terrain = terrain,
    ConstructionStatus = ConstructionStatus, logs = {},
}, { __index = _G })
env._G = env
env.print = function(message) env.logs[#env.logs + 1] = message end
local source_path = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/")
local root = require_value(source_path:match("^(.*)tests/[^/]+$"), "Cannot locate the repository root")
for _, file in ipairs({ "fp_version", "fp_config", "fp_debug", "fp_state",
    "fp_validation", "fp_construction_rules", "fp_lifecycle", "FlexiblePassages" }) do
    local chunk, err = loadfile(root .. "Code/" .. file .. ".lua", "t", env)
    require_value(chunk, err)()
end
env.OnMsg.ClassesBuilt()
local f = env.FlexiblePassages
require_value(f.State.active, "Current game API validation failed")
local checks = 0
local function expect(value, message)
    checks = checks + 1
    require_value(value, message)
end

local map = { GetHeight = function() return 0 end }
local function fixture()
    return setmetatable({
        mode = "passage_grid", starting_point = false,
        placed_points = false, current_points = {}, last_placed_points_count = {},
        current_len = 0, max_hex_distance_to_allow_build = 20,
        construction_statuses = {}, current_status = g_PlacementStateToColor.Blocked,
        preview_calls = 0, early_preview_calls = 0, visuals_initialized = false,
        GetMap = function() return map end,
        GetCSGroupAtStartingPoint = function() return false end,
        GetConstructionState = function() return "error" end,
        CanExtendFrom = function(self, pt) self.extension_point = pt; return true end,
        UpdateBlockedPipeConnectionsForHex = function() end,
        InitVisuals = function(self) self.visuals_initialized = true end,
        UpdateVisuals = function(self, pt)
            self.preview_calls = self.preview_calls + 1
            if not self.visuals_initialized then self.early_preview_calls = self.early_preview_calls + 1 end
            self.preview_point = pt
        end,
    }, { __index = controller_class })
end

local controller = fixture()
local raw_point = point(10201, 20401, 0)
local snapped_point = FixConstructPos(map, HexGetNearestCenter(raw_point))
expect(controller:Activate(raw_point) == true, "native Activate starts a snapped passage")
expect(controller.early_preview_calls == 0, "first preview follows native InitVisuals")
expect(controller.starting_point:Equal2D(snapped_point), "start point uses the actual engine hex center")
expect(#controller.placed_points == 1, "native Activate retains one starting anchor")

controller.current_points = { point(11201, 20401, 0), point(12201, 21401, 0) }
controller.construction_statuses = { ConstructionStatus.PassageDomeRequired, ConstructionStatus.NoDroneHub }
controller.current_len = 3
expect(controller:Activate(raw_point) == true, "valid intermediate status permits anchoring")
expect(#controller.placed_points == 3 and controller.last_placed_points_count[1] == 2,
    "anchor group uses the native undo representation")

for _, status in ipairs({ ConstructionStatus.PassageAngleToSteep, ConstructionStatus.BlockingObjects,
    ConstructionStatus.UnevenTerrain }) do
    require_value(status, "Current game construction status is unavailable")
    controller.current_points = { point(13201, 21401, 0) }
    controller.construction_statuses = { ConstructionStatus.PassageDomeRequired, status }
    controller.current_len = 4
    local count = #controller.placed_points
    controller:Activate(raw_point)
    expect(#controller.placed_points == count, "native blocking status prevents anchoring: " .. tostring(status.id))
end

controller.construction_statuses = { ConstructionStatus.PassageDomeRequired }
controller.current_len = controller.max_hex_distance_to_allow_build
local count = #controller.placed_points
controller:Activate(raw_point)
expect(#controller.placed_points == count, "native passage length limit prevents adding anchors")

for _, mode in ipairs({ "electricity_grid", "life_support_grid", "track_grid" }) do
    local other = fixture()
    other.mode = mode
    other:Activate(raw_point)
    expect(other.extension_point == raw_point and other.early_preview_calls == 0,
        mode .. " retains native activation")
end

expect(#env.logs == 0, "diagnostics remain off by default in the actual Lua runtime")
f.Config.DEBUG_LOGS = "true"
f.Config.DEBUG_CONSTRUCTION = true
f.Config.DEBUG_VANILLA_CONSTRUCTION = true
controller:Activate(raw_point)
expect(#env.logs == 0, "string true does not enable construction diagnostics")
f.Config.DEBUG_LOGS = true
controller:Activate(raw_point)
expect(#env.logs > 0, "boolean true enables construction diagnostics")
expect(f.Lifecycle.Disable("native_test") and controller_class.Activate == original_activate
    and controller_class.UpdateCursor == original_update_cursor, "owned native methods restore on disable")
expect(live_controller.Activate == live_activate and live_controller.UpdateCursor == live_update_cursor,
    "isolated checks preserve the live controller's methods")

return "PASS: " .. checks .. " native-engine construction checks on " .. tostring(BuildVersion)
