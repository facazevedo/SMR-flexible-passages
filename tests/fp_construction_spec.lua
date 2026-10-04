-- Run from the repository root: lua tests/fp_construction_spec.lua
-- Placement behavior checks model the current game's controller state.
local checks = 0
local function expect(value, message)
    checks = checks + 1
    assert(value, message)
end

local function point(x, y)
    local value = { x = x, y = y }
    function value:Equal2D(other) return self.x == other.x and self.y == other.y end
    return value
end

local function fixture()
    local env = setmetatable({ OnMsg = {}, logs = {} }, { __index = _G })
    env._G = env
    env.print = function(message) env.logs[#env.logs + 1] = message end
    env.table = setmetatable({ iappend = function(destination, values)
        for _, value in ipairs(values) do destination[#destination + 1] = value end
        return destination
    end }, { __index = table })
    env.ConstructionStatus = {}
    for _, id in ipairs({ "PassageDomeRequired", "PassageRequiresTwoDomes", "NoDroneHub",
        "PassageAngleToSteep", "BlockingObjects", "UnevenTerrain" }) do
        env.ConstructionStatus[id] = { id = id }
    end
    env.HexGetNearestCenter = function(value)
        return point(math.floor((value.x + 5) / 10) * 10, math.floor((value.y + 5) / 10) * 10)
    end
    env.GridConstructionController = {
        Activate = function(self, pt)
            self.native_calls = self.native_calls + 1
            self.native_point = pt
            return "vanilla"
        end,
        UpdateCursor = function(self, pt) self.cursor_point = pt end,
        UpdateVisuals = function(self, pt)
            self.preview_calls = self.preview_calls + 1
            self.preview_point = pt
        end,
    }
    for _, file in ipairs({ "fp_version", "fp_config", "fp_debug", "fp_state",
        "fp_validation", "fp_construction_rules", "fp_lifecycle", "FlexiblePassages" }) do
        assert(loadfile("Code/" .. file .. ".lua", "t", env))()
    end
    env.OnMsg.ClassesBuilt()
    local controller = setmetatable({
        mode = "passage_grid", starting_point = point(0, 0), placed_points = { point(0, 0) },
        current_points = { point(10, 0), point(20, 10) }, last_placed_points_count = {},
        construction_statuses = { env.ConstructionStatus.PassageDomeRequired },
        current_len = 3, max_hex_distance_to_allow_build = 20,
        native_calls = 0, preview_calls = 0, complete = false,
        CanCompletePassage = function(self) return self.complete end,
    }, { __index = env.GridConstructionController })
    return env, controller
end

do
    local _, controller = fixture()
    controller.starting_point, controller.placed_points, controller.current_points = false, false, {}
    expect(controller:Activate(point(21, 11)) == "vanilla", "first click delegates to native activation")
    expect(controller.preview_calls == 0, "false starting point does not refresh an active passage preview")
end

do
    local env, controller = fixture()
    env.FlexiblePassages.Config.ENABLE_FIXED_POINT_RELEASE = true
    controller.starting_point = false
    controller.placed_points[2] = point(10, 0)
    expect(env.FlexiblePassages.ConstructionRules.TryReleaseFixedPoint(controller, point(10, 0)) == false,
        "fixed-point release rejects the engine's false starting-point sentinel")
    expect(#controller.placed_points == 2, "inactive fixed-point release leaves anchors unchanged")
end

do
    local env, controller = fixture()
    controller.construction_statuses[2] = env.ConstructionStatus.NoDroneHub
    expect(controller:Activate(point(21, 11)) == true, "valid intermediate click anchors the preview")
    expect(#controller.placed_points == 3 and controller.last_placed_points_count[1] == 2,
        "anchor group retains all preview points for native right-click undo")
    expect(controller.native_calls == 0 and #controller.current_points == 0,
        "intermediate anchoring does not construct a passage")
    expect(controller.preview_point:Equal2D(point(20, 10)), "anchoring refreshes at the snapped hex center")
end

do
    local _, controller = fixture()
    controller.placed_points = { point(0, 0), point(10, 0), point(20, 10) }
    controller:Activate(point(20, 10))
    expect(#controller.placed_points == 3 and #controller.last_placed_points_count == 0,
        "coordinate-equal preview points do not duplicate existing anchors")
    expect(controller.native_calls == 1, "duplicate preview delegates to native activation")
end

for _, id in ipairs({ "PassageAngleToSteep", "BlockingObjects", "UnevenTerrain" }) do
    local env, controller = fixture()
    controller.construction_statuses[2] = env.ConstructionStatus[id]
    controller:Activate(point(20, 10))
    expect(#controller.placed_points == 1 and #controller.last_placed_points_count == 0,
        id .. " prevents intermediate anchoring")
    expect(controller.native_calls == 1 and controller.construction_statuses[2] == env.ConstructionStatus[id],
        id .. " remains subject to native validation")
end

do
    local _, controller = fixture()
    controller.current_len = controller.max_hex_distance_to_allow_build
    controller:Activate(point(20, 10))
    expect(#controller.placed_points == 1 and #controller.last_placed_points_count == 0,
        "passage length limit prevents adding anchors")
end

do
    local _, controller = fixture()
    controller.complete = true
    expect(controller:Activate(point(21, 11)) == "vanilla", "complete endpoint uses native construction")
    expect(controller.native_calls == 1 and #controller.placed_points == 1,
        "endpoint validation and construction remain native")
end

for _, mode in ipairs({ "electricity_grid", "life_support_grid", "track_grid" }) do
    local _, controller = fixture()
    controller.mode = mode
    local click = point(21, 11)
    controller:Activate(click)
    expect(controller.native_point == click and controller.preview_calls == 0,
        mode .. " retains its native activation point and preview")
end

do
    local env, controller = fixture()
    local cursor = point(21, 11)
    controller:UpdateCursor(cursor)
    expect(controller.cursor_point:Equal2D(point(20, 10)), "passage cursor snaps to a hex center")
    env.FlexiblePassages.Config.ENABLE_TILE_SNAPPED_CONTROL_POINTS = false
    controller:Activate(cursor)
    expect(controller.native_point == cursor and controller.preview_calls == 0,
        "disabled snapping retains native activation")
    env.FlexiblePassages.Config.ENABLE_TILE_SNAPPED_CONTROL_POINTS = true
    env.FlexiblePassages.Lifecycle.Disable("test")
    controller:Activate(cursor)
    expect(controller.native_point == cursor and controller.preview_calls == 0,
        "disabling the mod restores native activation")
    expect(#env.logs == 0, "construction diagnostics remain off by default")
end

print("PASS: " .. checks .. " construction compatibility checks")
