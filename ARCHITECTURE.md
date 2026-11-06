# Architecture

## Scope

Old Runes is a Death Knight presentation addon. Blizzard owns rune identity, order, layout, readiness, cooldown timing, and animation state. The addon owns only:

- validated SavedVariables preferences;
- addon-created overlay textures;
- visibility of reviewed Blizzard rune-art regions while a classic overlay is active;
- cooldown number/swipe/edge presentation flags.

## Startup gate

`Localization.lua`, `Core.lua`, and `Options.lua` return immediately unless `UnitClass("player")` resolves to `DEATHKNIGHT`. The gate precedes addon-global creation, localization tables, database migration, slash-command registration, Settings construction, events, hooks, timers, and presentation state.

## Frame ownership

Only two source-confirmed paths are accepted:

```text
RuneFrame
PersonalResourceDisplayFrame.classFrame
```

No child enumeration, name guessing, or fallback globals are used. The runtime owns exactly one current player frame and one current PRD class frame. Replacement, an empty/missing rune list, or PRD disablement releases accessible runes by restoring Blizzard art and cooldown defaults, hiding the custom overlay, and clearing presentation caches. Inaccessible objects are detached without invoking their methods or reading their children.

## Hooks and refresh lifecycle

- `RuneFrame:UpdateRunes` is post-hooked; it is never replaced or called by the addon.
- PRD `SetupClassBar` and `SetHideClassInfo` are post-hooked only to rediscover current ownership. Hooks from a retired PRD object reject themselves.
- Login, world entry, specialization changes, relevant Blizzard addon loads, and `PLAYER_REGEN_ENABLED` feed one refresh owner.
- Every new refresh generation cancels older timer handles. At most two delayed readiness probes remain live, and each callback clears only its captured slot.

## Combat boundary

Discovery, release, overlay creation, native-art visibility changes, and configuration commits are deferred during combat. No delayed readiness probes are scheduled by a combat request. One boolean records pending reconciliation; `PLAYER_REGEN_ENABLED` applies the newest desired state once.

Already-applied classic overlays may update readiness brightness and MIXED slot texture while combat is active. Pending settings do not partially replace the last fully applied style.

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

- At most two candidate frames are inspected per refresh.
- One overlay is created lazily per rune and reused across detach/reattach.
- Weak state maps avoid turning borrowed UI objects into permanent addon owners.
- Unchanged readiness does not rewrite vertex color.
- No addon `OnUpdate`, ticker, frame-tree scan, or unbounded retry loop exists.
