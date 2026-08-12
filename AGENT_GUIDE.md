# Agent guide: OldRunes

## Start here

[`OldRunes.toc`](OldRunes.toc) loads `Localization.lua`, `Core.lua`, and `Options.lua` in that order. `Localization.lua` establishes `OldRunesUI.L` and style constants; `Core.lua` creates the event frame, exports the `OldRunesUI` implementation, owns `OldRunesDB`, and defines the slash commands. `Options.lua` registers the Settings canvas after `PLAYER_LOGIN`/`Blizzard_Settings` availability.

## Runtime map

- `EnsureDBDefaults`, `GetRuneStyle`, and `SetRuneStyle` in `Core.lua` normalize the durable options: timer numbers, cooldown spiral, recovery order (currently forced false), personal resource display, style (`SPEC`, `MIXED`, `DEATH`, `SPECLESS`), and legacy multicolor compatibility.
- `RefreshRuneVisuals` is the orchestration boundary: discover rune frames, install `UpdateRunes` post-hooks, update recovery order, apply textures, timer visibility, cooldown spiral, and optional Personal Resource Display styling.
- Frame discovery is `GetRuneFrameCandidates`/`InitializeRuneFrames`; weak-key state tables track rune frames, overlays, and cooldowns. `ApplyRuneTextures`, `UpdateRecoveryOrder`, `UpdateTimerVisibility`, and `UpdateCooldownSpiral` mutate presentation only.
- Lifecycle events: `ADDON_LOADED` initializes after the addon is loaded, `PLAYER_LOGIN` retries after UI setup, `PLAYER_ENTERING_WORLD`, `PLAYER_SPECIALIZATION_CHANGED`, and `PLAYER_REGEN_ENABLED` refresh. `/or` and `/oldrunes` call the same DB/refresh functions as Settings.
- Slash grammar is implemented at `Core.lua:710-790`: `help`, `timer`, `spiral`, `reverse` (forced disabled in taint-safe mode), `prd`/`personal`, `style spec|mixed|death|specless`, `multicolor`, and `config`.

## State and dependencies

`OldRunesDB` is the only durable table. `OldRunesUI` is the public in-process namespace shared by Localization/Core/Options; tracked frame/overlay/cooldown state is transient. There are no external addon or library dependencies, but the code observes Blizzard rune frames and `PersonalResourceDisplayFrame`/`prdClassFrame` when present.

## Change routing

- Add a setting/default/migration: `Core.lua:EnsureDBDefaults`, then `Options.lua` checkbox/label and slash grammar.
- Change visual style mapping: `GetTextureForRune`, `EnsureBlizzardRuneArt`, and localization/style constants; preserve all four style modes.
- Change frame discovery/hooks: `GetRuneFrameCandidates`, `InitializeRuneFrame(s)`, `HookRuneFrame`, and `HookPersonalResourceDisplay`.
- Change cooldown presentation: `UpdateTimerVisibility`/`UpdateCooldownSpiral`; do not touch core frame discovery.
- Change Settings registration: `Options.lua:RegisterOptionsCategory`; preserve delayed registration for `Blizzard_Settings`.

## Invariants/risks

- The addon uses post-only hooks: `UpdateRunes` for rune frames and, when the personal resource display is available, `SetupClassBar`/`SetHideClassInfo` (`Core.lua:549-599`). It must not replace Blizzard rune update logic or call protected frame operations in combat.
- `EnsureRuneOverlay` and frame styling defer when `InCombatLockdown()` is true. Preserve restore/default visual behavior so toggles and reloads do not accumulate overlays or hidden atlas layers.
- Blizzard frame names/layouts and Personal Resource Display internals are unstable. Candidate discovery must remain nil-safe and idempotent.
- Weak-key tables are intentional to avoid retaining Blizzard frames; do not replace them with unbounded strong-key caches.

## Verification

Static checks:

```powershell
Get-Content _Addons/OldRunes/OldRunes.toc
rg -n "OldRunesDB|RefreshRuneVisuals|InitializeRuneFrames|HookRuneFrame|PersonalResource|Settings.Register|SlashCmdList" _Addons/OldRunes
```

In-game on a Death Knight: `/or`, `/oldrunes`, Settings panel, all style modes, timer/spiral/recovery/PRD toggles, spec change, relog/reload, teleport/world entry, combat start/end, and a client where Personal Resource Display is hidden. Check rune textures, cooldown numbers/spirals, recovery order, and absence of protected/taint errors.

## Unknowns

The exact rune frame and PRD hierarchy differs by Retail build and user UI. Static code identifies the discovery/fallback paths; the target client must prove which candidates are live.
