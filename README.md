# Flexible Passages

A Surviving Mars Relaunched mod for flexible dome passage placement.
Left-click anchors a passage to a tile; right-click undoes the last anchor point.
Vanilla restrictions still apply to sharp bends, passage length, terrain,
objects, and reserved space.

## Install

Copy `metadata.lua`, `items.lua`, `Code/`, and `Images/` into:

```text
%AppData%\Surviving Mars Relaunched\Mods\flexible-passages
```

Enable Flexible Passages in the game's mod manager, then quit and restart
the game to clear cached data.

## Version and compatibility

Current release: metadata version **13**, runtime **1.0.5**, for
Surviving Mars Relaunched **1.1.1.405907** on Windows.
[COMPATIBILITY.md](COMPATIBILITY.md) records the scope of those checks.

Debug logging is disabled by default. Feature and diagnostic flags are in
`Code/fp_config.lua`; runtime version information is in `Code/fp_version.lua`.

## Tests

From the repository root, run:

```text
lua tests/compatibility_spec.lua
lua tests/fp_construction_spec.lua
```

The regression checks cover class initialization, reapplication, restoration,
feature flags, missing APIs, wrapper ownership, unload, and code reload.
The construction checks cover the inactive starting-point state, snapped
anchors, duplicate points, placement restrictions, length limits, native
completion, other construction modes, and disabling snapping/the mod.
`tests/game_compatibility.lua` contains reversible checks for a disposable
game session. `tests/fp_game_construction_spec.lua` is an additional native
API fixture for a disposable debug session; its full run is pending.
Completing a passage and saving/reloading a colony require
manual gameplay checks.

## Feedback and history

Report problems through [GitHub issues](https://github.com/facazevedo/SMR-flexible-passages/issues)
or [anonymous feedback](https://smr-mods-feedback.fredware.app).

The mod and its Git history were moved from
[surviving-mars-relaunched-mods](https://github.com/facazevedo/surviving-mars-relaunched-mods).
The repository also preserves the additional artwork from the local mod folder.

Licensed under the [MIT License](LICENSE).
