# Compatibility with Surviving Mars Relaunched 1.1.1.405907

## October 3 compatibility update

Metadata version **13**, runtime **1.0.5**, corrects the mod's inactive
starting-point checks. The current game's controller uses `false` before a
passage starts and after cancellation; checking only for `nil` caused an
extra active-passage preview refresh and could allow fixed-point release
while inactive. Both values now defer to native activation, and inactive
fixed-point release leaves anchors unchanged.

The installed game and a fresh debug session reported **1.1.1.405907**,
Lua revision **405907**. The
[official announcements](https://steamcommunity.com/app/3215050/allnews/)
list patch 1.1.1 on September 23 and a Linux-specific stability patch on
September 30. Windows compatibility targets the installed gameplay build.

Validation completed for this update:

- All **12** lifecycle and **26** construction regression checks pass.
- All **14** Lua files pass `luac -p` syntax checks.
- The existing in-engine lifecycle check passed on build 405907 before the
  v13 guard changes. The additional v13 native construction fixture has not
  completed a full run.
- The test fixture initially read a missing mod global through the engine's
  strict environment, causing an assertion. Its optional state lookup now
  uses `rawget`; loaded/unloaded strict-environment preflight checks pass.
- Read-only inspection of shipped `GridConstruction.lua` confirms the
  `false` starting-point state, current continuation/completion predicates,
  native undo groups and length limits. `UpdateVisuals` retains the game's
  Capital City edge-entry validation. `Construction.lua` confirms the
  current snapping/terrain helpers; `CommonLua/Modding/Mod.lua` confirms
  required/minimum mod Lua revision **350453**, which remains unchanged.
- The v13 payload was copied to `%AppData%/Surviving Mars Relaunched/Mods/flexible-passages`;
  all **16** deployed files and their relative file list were verified by SHA-256.

Changed runtime logic is confined to `Code/fp_construction_rules.lua`.
Version information, metadata, tests and this documentation were updated.
Existing `DEBUG_LOGS`, `DEBUG_CONSTRUCTION` and `DEBUG_VANILLA_CONSTRUCTION`
flags remain false by default. An inactive fixed-point release can now emit
its skip reason through the existing guarded logger. No assets, third-party
code or game-installation files were edited.

Game logs from the October 3 sessions beginning at 19:25:09, 19:33:49,
19:34:07 and 20:22:16 were reviewed, along with the isolated harness log
`daemon-20261004-000901.log`. The initial session loaded v12 from AppData.
The 20:22:16 log includes the test lookup assertion described above. No
logs were deleted. Completed passage construction, Capital City gameplay
placement and colony save/load still require the manual checks below.

## Migrated compatibility results

Metadata version **12**, runtime **1.0.4**, was checked on Windows on
September 26–27, 2026, in the original mod collection. Those historical
results are recorded in its
[compatibility report](https://github.com/facazevedo/surviving-mars-relaunched-mods/blob/fcc823d/COMPATIBILITY.md).

The update installs passage-controller wrappers after `ClassesBuilt` and
recreates runtime ownership state when classes are rebuilt. Unload restores
owned hooks; incomplete restoration is reported. Feature flags and existing
diagnostic flags retain their explicit boolean behavior.

The original checks covered independent and combined loading, enable/disable/
reapply, feature flags, restoration, and reload while enabled. They did not
exercise completed passage construction or colony save/load. No new in-game
validation is implied by this repository migration.

## Repository checks

Run `lua tests/compatibility_spec.lua` from the repository root for the
12 migrated lifecycle regression checks. They use simulated engine boundaries.
Run `lua tests/fp_construction_spec.lua` for 26 construction behavior checks.
Use `luac -p` on individual Lua files for syntax checks.

`tests/game_compatibility.lua` retains the original reversible in-game
lifecycle check for a disposable session with Flexible Passages loaded.

## Manual gameplay checks

1. Enable the mod and fully restart the game.
2. Complete a bent passage between domes and undo intermediate anchors.
3. Check vanilla sharp-bend, length, terrain, object, and reserved-space rules.
4. Save and reload, then disable/re-enable the mod and check for stale hooks.
5. Review fresh game logs for Lua errors and mod diagnostics.
