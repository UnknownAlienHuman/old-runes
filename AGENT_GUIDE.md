# Agent guide: OldRunes

## Current contract

- Game: World of Warcraft Retail / Midnight 12.1.0
- Interface: `120100`
- Addon version: `2.1.0`
- Blizzard source baseline: `Gethe/wow-ui-source@027d26c3406d3de2cbd2b1f67d468fe033a1bcd4` (`12.1.0.69497`)
- Shared policy: [`UnknownAlienHuman/wow-addon-engineering-kb`](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)

`OldRunes.toc` loads `Localization.lua`, `Core.lua`, and `Options.lua` in that order. `Localization.lua` establishes `OldRunesUI.L`; `Core.lua` owns `OldRunesDB`, rune integration, lifecycle handling, and slash commands; `Options.lua` registers the Settings canvas.

## Runtime map

- `EnsureDBDefaults`, `GetRuneStyle`, and `SetRuneStyle` normalize durable options and migrate the legacy `multicolorRunes` flag before inserting the modern default style.
- `GetRuneFrameCandidates` deliberately recognizes only the source-confirmed 12.1 player `RuneFrame` and nameless `PersonalResourceDisplayFrame.classFrame`.
- `InitializeRuneFrame(s)` refreshes the six rune references and lazily creates addon-owned overlays outside combat.
- `HookRuneFrame` post-hooks `UpdateRunes`. When Blizzard reports `isSpecChange`, `InvalidateFramePresentation` clears only presentation caches before the selected style is reapplied.
- `RefreshRuneVisuals` is the orchestration boundary: hook PRD construction, discover frames, attach rune hooks, optionally invalidate presentation state, then apply rune and cooldown presentation.
- `QueueRefreshBurst` coalesces login/world/spec/PRD reconstruction races into bounded refreshes at `0`, `0.2`, and `1.0` seconds. A generation token cancels stale bursts.
- `RestoreDefaultFramePresentation` returns an opted-out PRD rune frame to Blizzard specialization art and cooldown defaults.
- `PLAYER_REGEN_ENABLED` processes only work explicitly deferred because combat prevented safe region creation or atlas visibility changes.

## State and dependencies

`OldRunesDB` is the only durable table. `OldRunesUI` is the in-process API shared with Options. Tracked frames, hooks, runes, overlays, and cooldown dirty-state use weak-key tables. There are no external addon or library dependencies.

## Blizzard integration boundary

Source-confirmed paths for 12.1:

- `Blizzard_UnitFrame/Mainline/RuneFrame.lua`: `RuneFrameMixin:UpdateRunes`, `RuneButtonMixin:UpdateSpec`, `RuneButtonMixin:UpdateState`.
- `Blizzard_UnitFrame/Mainline/RuneFrame.xml`: `RuneFrameTemplate`, rune atlas layers, and cooldown defaults.
- `Blizzard_PersonalResourceDisplay/Blizzard_PersonalResourceDisplay.lua`: Death Knight maps to `RuneFrameTemplate`; `SetupClassBar` stores the nameless frame in `self.classFrame`.

Do not restore the removed `GetChildren`/`GetNumChildren` sweep, `prdClassFrame`, or `DeathKnightResourceOverlayFrame` fallbacks without new source and runtime evidence.

## Invariants

- Never assign `rune.layoutIndex`, call `frame:Layout()`, or force `frame:UpdateRunes(false)` from addon code.
- Never override Blizzard globals or replace `UpdateRunes`; use the existing post-hook only.
- Do not create textures or change Blizzard atlas visibility in combat. Queue one bounded reconciliation for `PLAYER_REGEN_ENABLED`.
- Keep frame discovery exact, nil-safe, idempotent, and attach-once.
- `layoutIndex` is read only to map mixed textures to the current visual slot; it is never mutated.
- The `reverseRecoveryOrder` SavedVariable and command are compatibility stubs and must remain non-operative unless Blizzard exposes a supported layout API.
- Disabling PRD styling must restore Blizzard visuals instead of leaving hidden atlas layers or altered cooldown settings behind.

## Change routing

- SavedVariables/default migration: `EnsureDBDefaults`, then Options and slash behavior if the setting is exposed.
- Style mapping: `GetTextureForRune`, `GetMixedTextureByLayout`, and `ApplyFramePresentation`.
- Frame lifecycle/discovery: `GetRuneFrameCandidates`, `InitializeRuneFrame(s)`, `HookRuneFrame`, `HookPersonalResourceDisplay`, and `QueueRefreshBurst`.
- Cooldown presentation: `SetCooldownPresentation`.
- Settings category: `Options.lua:RegisterOptionsCategory`.

## Verification

Static checks:

```powershell
rg -n "layoutIndex\s*=|:Layout\(|UpdateRunes\s*\(\s*false|GetChildren|GetNumChildren|DeathKnightResourceOverlayFrame|prdClassFrame" .
rg -n "UpdateRunes|SetupClassBar|SetHideClassInfo|PLAYER_ENTERING_WORLD|PLAYER_SPECIALIZATION_CHANGED|PLAYER_REGEN_ENABLED" Core.lua
```

Run a Lua parser/compiler against `Core.lua`, `Localization.lua`, and `Options.lua`. Keep test harnesses outside the addon TOC/package.

Required in-client matrix on a Death Knight:

1. Fresh login and `/reload` with PRD both enabled and disabled.
2. Spec, Mixed, Death, and Specless across all three specializations.
3. Specialization change, teleport, instance transition, death/release, and relog.
4. Rune depletion/recovery with timer and spiral combinations.
5. Toggle PRD styling on and off; verify Blizzard art and cooldown defaults are restored.
6. Enter combat before a configuration change, then leave combat; verify deferred reconciliation and no taint/forbidden errors.
7. Open `/or config`; verify SavedVariables survive reload.
8. Repeat with common unit-frame/nameplate addon stacks.

## Unverified runtime boundary

Offline tests prove control flow and invariants, not live texture availability, protected-state behavior, or the exact creation order on the target client. Do not close the live-validation issues or claim the addon is in-game tested until the matrix above is recorded against a named Retail build.
