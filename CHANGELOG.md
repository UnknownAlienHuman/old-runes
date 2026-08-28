# Changelog

## 2.1.0 — 2026-08-27

Target: World of Warcraft Retail 12.1.0, Interface `120100`.

### Fixed

- Reapply the persisted rune style after Blizzard `UpdateRunes(true)` restores specialization art during specialization and world lifecycle changes.
- Reassert custom atlas hiding when Blizzard presentation state is refreshed.
- Restore Blizzard rune art, hidden countdown-number default, cooldown swipe, and cooldown edge when Personal Resource Display styling is disabled.
- Correct migration of legacy SavedVariables where `multicolorRunes=true` existed without a modern `runeStyle` value.
- Discover replacement player/PRD rune frames during bounded delayed lifecycle refreshes.

### Changed

- Replace broad `ClassFrameContainer` child scanning and legacy fallback globals with the 12.1 source-confirmed `RuneFrame` and `PersonalResourceDisplayFrame.classFrame` paths.
- Keep tracked Blizzard frames and hook guards in weak-key tables.
- Defer creation of addon-owned rune overlays and atlas visibility changes while in combat, then reconcile on `PLAYER_REGEN_ENABLED`.
- Coalesce lifecycle work into a bounded `0 / 0.2 / 1.0` second refresh burst with stale-generation cancellation.
- Preserve the taint-safe prohibition on rune layout mutation and reverse recovery order.

### Source baseline

- `UnknownAlienHuman/wow-addon-engineering-kb`: Retail 12.1.0 engineering contract.
- `Gethe/wow-ui-source@027d26c3406d3de2cbd2b1f67d468fe033a1bcd4`:
  - `Interface/AddOns/Blizzard_UnitFrame/Mainline/RuneFrame.lua`
  - `Interface/AddOns/Blizzard_UnitFrame/Mainline/RuneFrame.xml`
  - `Interface/AddOns/Blizzard_PersonalResourceDisplay/Blizzard_PersonalResourceDisplay.lua`
  - generated `PlayerScriptDocumentation.lua` for `GetRuneCooldown`.

### Verification

Passed offline:

- Lua syntax compilation of the changed `Core.lua` through `loadfile`;
- static rejection searches for layout mutation, forced `UpdateRunes(false)`, PRD child sweeps, and removed fallback globals;
- mocked Death Knight regression suite covering all style transitions, `UpdateRunes(true)`, PRD default restoration, replacement-frame discovery, combat deferral, and attach-once hooks;
- mocked non-Death-Knight/SavedVariables migration suite.

Not performed: an actual Retail 12.1.0 client smoke test. The open validation issues remain the release gate for live behavior and texture availability.
