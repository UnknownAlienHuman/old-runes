# Architecture

## Scope

Old Runes is a presentation addon. Blizzard owns rune identity, order, layout, readiness, cooldown timing, and animation state. The addon owns only:

- SavedVariables-backed preferences;
- addon-created overlay textures;
- visibility of the reviewed Blizzard rune-art regions while a classic overlay is active;
- cooldown number/swipe/edge presentation flags.

## Runtime split

`Core.lua` has two layers:

1. **Shared configuration** — migration, settings API, and slash commands on every character.
2. **Death Knight runtime** — exact frame discovery, hooks, presentation state, lifecycle refreshes, and combat deferral.

Non-DK characters never install RuneFrame or PRD hooks.

## Frame discovery

Only two source-confirmed paths are accepted:

```text
RuneFrame
PersonalResourceDisplayFrame.classFrame
```

No child enumeration, name guessing, or fallback globals are used. Weak-key tables prevent replacement PRD frames from being retained for the session.

## Hooking and lifecycle

- `RuneFrame:UpdateRunes` is post-hooked; it is never replaced or called by the addon.
- PRD `SetupClassBar` and `SetHideClassInfo` are post-hooked to rediscover class-frame replacement/visibility changes.
- Login, world entry, specialization changes, relevant Blizzard addon loads, and `PLAYER_REGEN_ENABLED` feed one generation-gated refresh burst.
- The immediate pass owns invalidation; delayed passes only discover late-created frames and reconcile presentation.

## Combat boundary

Overlay creation and Blizzard atlas visibility changes are deferred during combat. One boolean records pending structural work; `PLAYER_REGEN_ENABLED` performs the newest desired state once. Existing addon-owned overlays may update their texture/brightness when no Blizzard visibility mutation is required.

## Persistence

Schema `2` stores only:

```text
showTimerNumbers
showCooldownSpiral
oldPersonalResourceDisplay
runeStyle
```

`multicolorRunes` migrates once to `runeStyle=MIXED`; `reverseRecoveryOrder` is deleted. Runtime frames, regions, hooks, timers, and caches are never persisted.

## Performance

- At most two candidate frames are checked per refresh.
- One overlay is created lazily per rune and reused.
- Weak-key caches store presentation dirty state.
- No `OnUpdate`, ticker, frame-tree scan, or unbounded retry loop exists.
