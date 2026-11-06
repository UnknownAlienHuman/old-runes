# Changelog

## 2.2.0 — 2026-11-06

### Updated

- Targeted Retail 12.1.5 / Interface `120105`.
- Rechecked `RuneFrame` and `PersonalResourceDisplayFrame.classFrame` against source builds `70688` and `70783`.
- Kept exact frame discovery and post-hook-only integration.

### Fixed

- Slash commands and `/or config` now remain available on non-Death-Knight characters.
- Player/PRD rebuilds detach replaced rune objects and class frames, hide stale overlays, and ignore stale post-hooks.
- Delayed refreshes no longer invalidate presentation state repeatedly.
- Cooldown settings remain addon-owned only while a frame is styled; disabling PRD styling restores Blizzard defaults.

### Cleaned

- Removed the nonfunctional reverse-layout setting from UI, help, defaults, and persistence.
- Converted `multicolorRunes` to a one-way migration and removed the legacy key afterward.
- Removed internal implementation names from user-facing tooltips.
- Replaced the historical work-log dump with a focused live-client validation matrix.

### Validation

- Added mocked DK/non-DK runtime regression tests and Settings wiring tests.
- Release validation runs Lua 5.1 syntax checks, tests, runtime-closure checks, forbidden-pattern checks, and package-content verification.

## 2.1.0 — 2026-08-28

- Updated for Retail 12.1.0 / Interface `120100`.
- Added source-confirmed player RuneFrame and PRD class-frame discovery.
- Added combat deferral, lifecycle refreshes, PRD restoration, and legacy mixed-style migration.
