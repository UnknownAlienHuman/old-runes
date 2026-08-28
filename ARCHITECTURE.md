# Architecture

Old Runes is a three-file addon with no external libraries. `Localization.lua` creates the shared localization table, `Core.lua` owns SavedVariables and Blizzard integration, and `Options.lua` exposes the same state transitions through the Retail Settings UI.

## Data flow

```text
native lifecycle event / Blizzard post-hook
  -> bounded refresh coordinator
  -> exact RuneFrame discovery
  -> optional presentation-cache invalidation
  -> classic overlay or Blizzard specless/default art
  -> cooldown-number and swipe/edge presentation
```

`OldRunesDB` is the only durable state. Frame, hook, rune, overlay, and cooldown caches are transient weak-key tables. Cache entries describe only addon presentation; Blizzard remains the owner of rune state, sorting, animations, and layout.

## 12.1 integration

The player frame is the global `RuneFrame`. The Personal Resource Display creates a nameless `RuneFrameTemplate` and stores it at `PersonalResourceDisplayFrame.classFrame`. The addon post-hooks each frame's `UpdateRunes` and the PRD's `SetupClassBar`/`SetHideClassInfo`; it never replaces those methods.

Blizzard calls `rune:UpdateSpec(specIndex)` inside `UpdateRunes(true)`. The post-hook therefore invalidates cached atlas/art assumptions before reapplying the persisted addon style. Login, world entry, specialization changes, and PRD reconstruction also use a bounded delayed refresh because frame creation can complete after the initiating event.

## Security boundary

The addon does not mutate rune layout, protected attributes, or Blizzard event scripts. Addon-owned overlay creation and Blizzard atlas visibility changes are deferred during combat and reconciled once on `PLAYER_REGEN_ENABLED`. Frame/object access constraints are checked before integration work. Disabling PRD styling restores Blizzard art and cooldown defaults instead of merely hiding the addon overlay.

## Patch-sensitive risks

The internal fields `Runes`, `layoutIndex`, rune atlas region names, `UpdateRunes`, `UpdateSpec`, and `PersonalResourceDisplayFrame.classFrame` are implementation-derived rather than public addon APIs. Every Retail patch requires source comparison and an in-client Death Knight smoke test. The classic texture file paths also require live verification because interface texture manifests are not exhaustive in 12.1.
