# Changelog

## 2.2.0 — 2026-11-06

### Updated

- Targeted Retail 12.1.5 / Interface `120105`.
- Rechecked `RuneFrame` and `PersonalResourceDisplayFrame.classFrame` against source builds `70688` and `70783`.
- Kept exact frame discovery and post-hook-only integration.
- Made the addon strictly Death Knight-scoped: runtime and Settings exit before creating any owner on other classes.

### Fixed

- Player/PRD rebuilds, empty rune lists, and replacement rune objects restore accessible Blizzard art and cooldown defaults before detaching.
- Recycled runes reuse their existing overlay instead of accumulating textures.
- Combat configuration changes and structural ownership changes are reconciled together after combat; the last applied MIXED style still follows native slot movement in combat.
- Retired PRD hooks and inaccessible rune cleanup no longer schedule or perform stale presentation work.
- A new refresh generation cancels previous readiness timers; completed callbacks clear the correct captured timer slot.
- Unchanged readiness no longer rewrites overlay brightness.
- Disabling PRD styling restores Blizzard defaults without affecting the player RuneFrame.

### Cleaned

- Removed the nonfunctional reverse-layout setting from UI, help, defaults, and persistence.
- Removed obsolete compatibility slash-command branches.
- Converted `multicolorRunes` to a one-way data migration and removed the legacy key afterward.
- Removed internal implementation names from user-facing tooltips.
- Kept remaining unknowns in the focused live-client matrix instead of claiming runtime proof.

### Validation

- Lua 5.1 syntax, focused DK runtime tests, Settings wiring, lifecycle invariants, and exact package contents are automated.
- Regression coverage includes release, reuse, empty/missing rune lists, combat reconciliation, bounded timers, stale owners, inaccessible objects, brightness caching, and deferred MIXED style changes.
- Mock tests do not replace live-client taint, forbidden-action, texture, and visual checks.

## 2.1.0 — 2026-08-28

- Updated for Retail 12.1.0 / Interface `120100`.
- Added source-confirmed player RuneFrame and PRD class-frame discovery.
- Added combat deferral, lifecycle refreshes, PRD restoration, and legacy mixed-style migration.
