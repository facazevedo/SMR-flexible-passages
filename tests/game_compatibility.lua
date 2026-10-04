-- Run in a disposable game session after loading Flexible Passages.
-- Migrated reversible lifecycle checks; passage construction remains manual.
local function check()
        local f = Mods.FlexiblePassages.env.FlexiblePassages
        local startup = f.State.active == true and GridConstructionController.Activate == f.State.patched_activate
        local available = f.Validation.CheckRuntimeApi("compatibility_test")
        f.Lifecycle.Disable("compatibility_test")
        local original_activate = GridConstructionController.Activate
        local original_cursor = GridConstructionController.UpdateCursor
        local enabled = f.Lifecycle.Enable("compatibility_test")
        f.Lifecycle.Enable("compatibility_test_twice")
        local active = GridConstructionController.Activate ~= original_activate
        f.Lifecycle.Disable("compatibility_test"); f.Lifecycle.Disable("compatibility_test_twice")
        local restored = GridConstructionController.Activate == original_activate and GridConstructionController.UpdateCursor == original_cursor
        f.Lifecycle.Enable("compatibility_test")
        f.Config.ENABLE_FLEXIBLE_PASSAGE_CONSTRUCTION = false; f.Lifecycle.Enable("feature_disabled")
        local disabled = not f.State.active and GridConstructionController.Activate == original_activate
        f.Config.ENABLE_FLEXIBLE_PASSAGE_CONSTRUCTION = true; f.Lifecycle.Enable("compatibility_test")
        return startup and available and enabled and active and restored and disabled
end

local ok, result = pcall(check)
return "FlexiblePassages: " .. (ok and result == true and "PASS" or "FAIL: " .. tostring(result))
