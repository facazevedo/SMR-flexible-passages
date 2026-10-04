# Compatibility with Surviving Mars Relaunched 1.1.1.405907

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
Use `luac -p` on individual Lua files for syntax checks.

`tests/game_compatibility.lua` retains the original reversible in-game
lifecycle check for a disposable session with Flexible Passages loaded.

## Manual gameplay checks

1. Enable the mod and fully restart the game.
2. Complete a bent passage between domes and undo intermediate anchors.
3. Check vanilla sharp-bend, length, terrain, object, and reserved-space rules.
4. Save and reload, then disable/re-enable the mod and check for stale hooks.
5. Review fresh game logs for Lua errors and mod diagnostics.
