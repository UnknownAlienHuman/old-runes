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

No child enumeration, name guessing, or fallback globals are used. The runtime owns exactly one current player frame and one current PRD class frame; replacements and empty rune lists release their presentation outside combat: restore accessible Blizzard art/cooldown defaults, hide the overlay, and clear dirty-state caches. Inaccessible runes are detached without touching their methods or children.

## Hooking and lifecycle

- `RuneFrame:UpdateRunes` is post-hooked; it is never replaced or called by the addon.
- PRD `SetupClassBar` and `SetHideClassInfo` are post-hooked to rediscover class-frame replacement/visibility changes. Hooks from a retired PRD owner do nothing.
- Login, world entry, specialization changes, relevant Blizzard addon loads, and `PLAYER_REGEN_ENABLED` feed one generation-gated refresh burst.
- The immediate pass owns invalidation; delayed passes only discover late-created frames and reconcile presentation. A new burst cancels previous timer handles; at most two readiness timers are live. Generation checks also reject stale callbacks.

## Combat boundary

Discovery, release, native presentation changes, and configuration commits are deferred during combat. No readiness burst is scheduled from a combat refresh. One boolean records pending work; `PLAYER_REGEN_ENABLED` reconciles the current owners and latest desired configuration. Existing overlays keep updating readiness and MIXED slot colors using the last applied style; pending settings cannot partially change that style.

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
- One overlay is created lazily per rune and reused even across detach/reattach. A weak-key/weak-value texture map avoids retaining the owner through its texture in Lua 5.1; the native parent retains the region.
- Unchanged rune readiness does not rewrite the overlay vertex color.
- Exact-owner frame tracking and bounded per-rune caches store presentation dirty state; replaced frames and runes are explicitly detached.
- No `OnUpdate`, ticker, frame-tree scan, or unbounded retry loop exists.
