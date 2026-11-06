# Architecture

## Scope

Old Runes is a Death Knight presentation addon. Blizzard owns rune identity, order, layout, readiness, cooldown timing, and animation state. The addon owns only:

- validated SavedVariables preferences;
- addon-created overlay textures;
- visibility of reviewed Blizzard rune-art regions while a classic overlay is active;
- cooldown number/swipe/edge presentation flags.

## Startup gate

`Localization.lua`, `Core.lua`, and `Options.lua` return immediately unless `UnitClass("player")` resolves to `DEATHKNIGHT`. The gate precedes addon-global creation, localization tables, database migration, slash-command registration, Settings construction, events, hooks, timers, and presentation state.

`OldRunesDB` is account-wide TOC persistence and may still be loaded by the client on another class. No Old Runes Lua consumer initializes or mutates it there.

## Frame ownership

Only two source-confirmed paths are accepted:

```text
RuneFrame
PersonalResourceDisplayFrame.classFrame
```

Selected source creates the PRD class frame lazily in `SetupClassBar` and normally retains it. The addon nevertheless tolerates late creation, missing rune lists, and object replacement without scanning children or guessing names.

The runtime owns exactly one current player frame and one current PRD class frame. Replacement, an empty/missing rune list, or PRD disablement releases accessible runes by restoring Blizzard art and cooldown defaults, hiding the custom overlay, and clearing presentation caches. Inaccessible objects are detached without invoking their methods or reading their children.

## Overlay and cache ownership

Lua 5.1 weak-key tables are not ephemerons. A texture can reference its parent rune, so a weak-key/strong-value registry can retain the very key it is expected to release. Weak values solve retention but can lose the only addon lookup while the native texture still exists, allowing duplicate textures.

Old Runes therefore uses explicit bounded ownership:

```text
active rune -> one strong overlay lookup
released rune -> tokenized retirement queue
retired queue -> maximum 12 rune overlays
reclaimed rune -> retirement token cleared, existing overlay reused
expired retired rune -> overlay lookup removed
```

Twelve entries cover one complete player plus PRD rune set. The queue is not persisted, cannot grow without bound, and does not mutate Blizzard rune fields.

Presentation caches remain weak-key maps only where their values do not reference the key. No frame, rune, cooldown, texture, hook, or timer is persisted.

## Hooks and refresh lifecycle

- `RuneFrame:UpdateRunes` is post-hooked; it is never replaced or called by the addon.
- PRD `SetupClassBar` and `SetHideClassInfo` are post-hooked only to rediscover current ownership. Hooks from a retired PRD object reject themselves.
- Login, world entry, specialization changes, relevant Blizzard addon loads, and `PLAYER_REGEN_ENABLED` feed one refresh owner.
- Every new refresh generation cancels older timer handles. At most two delayed readiness probes remain live, and each callback clears only its captured slot.

## Combat boundary

Discovery, release, overlay creation, native-art visibility changes, and configuration commits are deferred during combat. No delayed readiness probes are scheduled by a combat request. One boolean records pending reconciliation; `PLAYER_REGEN_ENABLED` applies the newest desired state once.

Already-applied classic overlays may update readable readiness brightness and MIXED slot texture while combat is active. Pending settings do not partially replace the last fully applied style.

## Readiness boundary

Blizzard normally provides `rune.lastRuneState.runeReady`. The fallback `GetRuneCooldown` contract may return nothing. Old Runes therefore has three states:

```text
ready = true   -> full brightness
ready = false  -> dimmed
ready = nil    -> preserve the previous/default brightness
```

Missing data is never converted into a fabricated depleted rune.

## Persistence

Schema `2` stores only:

```text
showTimerNumbers
showCooldownSpiral
oldPersonalResourceDisplay
runeStyle
```

`multicolorRunes` migrates once to `runeStyle=MIXED`; `reverseRecoveryOrder` is deleted. Type and enum validation run before runtime consumers.

## Performance

- At most two candidate frames are inspected per refresh.
- One overlay is created lazily per rune and reused while active or retained in the bounded retirement cache.
- Unchanged readiness does not rewrite vertex color.
- Refresh timers are bounded, replaceable, generation-gated, and terminal.
- No addon `OnUpdate`, ticker, frame-tree scan, or unbounded retry loop exists.

## Release boundary

Validation runs for pull requests and `main`. GitHub release publication is manual and is rejected unless the workflow was dispatched from `refs/heads/main`. An existing tag is resolved to its commit before either release branch and must equal `GITHUB_SHA`. The publish job rebuilds the same minimal archive and verifies its SHA-256 before creating or updating the release.
