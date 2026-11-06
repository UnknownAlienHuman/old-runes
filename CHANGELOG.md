# Changelog

## 2.2.0 — 2026-11-06

### Updated

- Targeted Retail 12.1.5 / Interface `120105`.
- Rechecked `RuneFrame` and `PersonalResourceDisplayFrame.classFrame` against source builds `70688` and `70783`.
- Kept exact frame discovery and post-hook-only integration.
- Made the addon strictly Death Knight-scoped: every loaded Lua file exits before creating addon runtime state on another class.
- Restored useful class/category, localized notes, icon, installation, CurseForge, and license metadata removed during earlier cleanup.

### Fixed

- Player/PRD late setup, missing rune lists, and replacement rune objects restore accessible Blizzard art and cooldown defaults before detaching.
- Recycled runes reuse their existing overlay instead of accumulating textures.
- Replaced the Lua 5.1 weak-key/strong-value overlay registry with an explicit retirement cache bounded to 12 runes, preventing both lookup loss and owner-retention cycles.
- `GetRuneCooldown` returning no data no longer fabricates a depleted rune or dims an overlay.
- Combat configuration changes and structural ownership changes are reconciled together after combat; the last applied MIXED style still follows native slot movement in combat.
- Retired PRD hooks and inaccessible rune cleanup no longer schedule or perform stale presentation work.
- A new refresh generation cancels previous readiness timers; completed callbacks clear the correct captured Lua 5.1 timer slot.
- Unchanged readiness no longer rewrites overlay brightness.
- Disabling PRD styling restores Blizzard defaults without affecting the player RuneFrame.
- Manual GitHub release publication is restricted to `main`.
- Existing release tags are resolved and rejected unless their commit equals the workflow `GITHUB_SHA`, including the case where a tag exists but its GitHub Release was deleted.

### Cleaned

- Removed the nonfunctional reverse-layout setting from UI, help, defaults, persistence, and localization.
- Removed obsolete compatibility slash-command branches and the irrelevant non-DK runtime scenario.
- Converted `multicolorRunes` to a one-way data migration and removed the legacy key afterward.
- Removed redundant code-index and code-graph documents; README and Architecture remain the human-facing owners.
- Corrected documentation that overstated PRD recreation and incorrectly claimed the TOC SavedVariables table was not loaded on other classes.
- Kept remaining unknowns in the focused live-client matrix instead of claiming runtime proof.

### Validation

- Lua 5.1 syntax, hard class gates, focused DK runtime tests, Settings wiring, lifecycle invariants, release guards, and exact package contents are automated.
- Twelve core regressions run in separate Lua processes: release, reuse, bounded overlay retirement, empty/missing rune lists, combat reconciliation, bounded timers, stale owners, inaccessible objects, brightness caching, deferred MIXED style changes, database repair, and unavailable cooldown data.
- Mock tests do not replace live-client taint, forbidden-action, texture, and visual checks.

## 2.1.0 — 2026-08-28

- Updated for Retail 12.1.0 / Interface `120100`.
- Added source-confirmed player RuneFrame and PRD class-frame discovery.
- Added combat deferral, lifecycle refreshes, PRD restoration, and legacy mixed-style migration.
