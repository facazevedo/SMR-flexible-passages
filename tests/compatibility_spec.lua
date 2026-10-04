-- Run from the repository root: lua tests/compatibility_spec.lua
-- Migrated lifecycle regression checks use simulated engine boundaries.
local checks = 0
local function expect(value, message)
    checks = checks + 1
    assert(value, message)
end

local function environment()
    local env = setmetatable({ OnMsg = {}, empty_table = {}, logs = {} }, { __index = _G })
    env._G = env
    env.print = function(message) env.logs[#env.logs + 1] = message end
    return env
end

local function load(env, file)
    assert(loadfile("Code/" .. file .. ".lua", "t", env))()
end

do
    local env = environment()
    local function controller()
        return { Activate = function() return "vanilla" end, UpdateCursor = function() end,
            UpdateVisuals = function() end }
    end
    local old = controller()
    local old_activate = old.Activate
    env.GridConstructionController = old
    env.HexGetNearestCenter = function(pt) return pt end
    for _, file in ipairs({ "fp_version", "fp_config", "fp_debug", "fp_state",
        "fp_validation", "fp_construction_rules", "fp_lifecycle", "FlexiblePassages" }) do
        load(env, file)
    end
    expect(old.Activate == old_activate, "passages do not patch classes during code load")
    local rebuilt = controller()
    local vanilla_activate, vanilla_cursor = rebuilt.Activate, rebuilt.UpdateCursor
    env.GridConstructionController = rebuilt
    env.OnMsg.ClassesBuilt()
    local f = env.FlexiblePassages
    expect(f.State.active and rebuilt.Activate ~= vanilla_activate, "passages patch rebuilt controller")
    expect(f.Lifecycle.Enable("twice"), "passages can reapply without stale ownership")
    f.Lifecycle.Disable("test")
    f.Lifecycle.Disable("twice")
    expect(rebuilt.Activate == vanilla_activate and rebuilt.UpdateCursor == vanilla_cursor, "passages restore both methods")
    f.Config.ENABLE_FLEXIBLE_PASSAGE_CONSTRUCTION = false
    f.Lifecycle.Enable("disabled flag")
    expect(not f.State.active and rebuilt.Activate == vanilla_activate, "disabled passages do not install hooks")
    f.Config.ENABLE_FLEXIBLE_PASSAGE_CONSTRUCTION = true
    env.HexGetNearestCenter = false
    expect(f.Lifecycle.Enable("missing API") == false and not f.State.active, "missing required API prevents activation")
    env.HexGetNearestCenter = function(pt) return pt end
    f.Lifecycle.Enable("test")
    local inner = rebuilt.Activate
    local outer = function(...) return inner(...) end
    rebuilt.Activate = outer
    expect(f.Lifecycle.Disable("later owner") == false, "incomplete restoration is reported")
    expect(rebuilt.Activate == outer and outer({ mode = "passage_grid" }, {}) == "vanilla",
        "passage wrapper goes dormant without overwriting later owner")
    rebuilt.Activate = inner
    expect(f.Lifecycle.Disable("retry") and rebuilt.Activate == vanilla_activate, "restoration can be retried")
    f.Lifecycle.Enable("test")
    env.OnMsg.ModUnloadLua("FlexiblePassages")
    expect(not f.State.active and rebuilt.Activate == vanilla_activate, "passages restore on unload")
    f.Lifecycle.Enable("before reload")
    load(env, "fp_state")
    local reloaded = controller()
    local reloaded_activate = reloaded.Activate
    env.GridConstructionController = reloaded
    env.OnMsg.ClassesBuilt()
    expect(f.State.active and reloaded.Activate ~= reloaded_activate, "reload discards previous class ownership")
    expect(f.Lifecycle.Disable("after reload") and reloaded.Activate == reloaded_activate,
        "reload restores the rebuilt class, not a stale original")
end

print("PASS: " .. checks .. " compatibility regression checks")
