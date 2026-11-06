# Agent guide

## Current contract

- Retail: `12.1.5`
- Interface: `120105`
- Addon: `2.2.0`
- Selected source: `Gethe/wow-ui-source@d07eb00237d8891f153215db98a5df880a26cfe5` (`12.1.5.70688`)
- Latest reviewed relevant endpoint: `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (`12.1.5.70783`)
- Runtime matrix: not complete; see `todo.md`

Read `wow-addon-engineering-kb/AGENTS.md` and `INDEX_MINI.md`, then the current 12.1.5 overlays plus the task-owning SavedVariables, TOC, event/lifecycle, and UnitFrames guides before patch-sensitive changes.

## Non-negotiable invariants

- Every loaded Lua file exits before creating addon runtime state unless `UnitClass("player")` is `DEATHKNIGHT`.
- TOC persistence may still be loaded account-wide; do not claim a Lua return prevents SavedVariables loading.
- Never assign `rune.layoutIndex`.
- Never call `frame:Layout()` or `frame:UpdateRunes(false)`.
- Never replace `UpdateRunes`; use a post-hook.
- Never enumerate frame children to discover rune frames.
- Never create overlay regions or change Blizzard rune-art visibility in combat.
- Keep discovery limited to `RuneFrame` and `PersonalResourceDisplayFrame.classFrame` unless selected source proves a new path.
- Keep exactly one current player owner and one current PRD class-frame owner; release replacements instead of accumulating them.
- Do not use a Lua 5.1 weak-key/strong-value table for overlays whose texture can reference its parent rune. Keep active overlays explicit and bound released overlay reuse to 12 runes.
- Treat `GetRuneCooldown` as `MayReturnNothing`; unknown readiness preserves the current visual state.
- Disabling PRD styling or releasing an accessible rune restores Blizzard art and cooldown defaults.
- Cancel old readiness timers before replacement and clear each completed handle by its captured slot.
- Do not reintroduce reverse layout, compatibility slash-command branches, non-DK runtime scenarios, or dead localization strings.
- Do not persist frames, regions, timers, hooks, presentation caches, or retired overlay entries.
- Release publication is manual and only from `refs/heads/main`; an existing version tag must resolve to the exact release commit before a release is created or updated.

## Local checks

```bash
luac5.1 -p Localization.lua Core.lua Options.lua tests/test_core.lua tests/test_options.lua

for regression in \
  release reuse overlay_cache empty combat timers stale_prd inaccessible \
  brightness combat_mixed database cooldown_unavailable; do
  lua5.1 tests/test_core.lua "$regression"
done

lua5.1 tests/test_options.lua
```

Each core regression runs in a fresh process. Do not replace this with one shared mutable test session.

## Change routing

- Runtime integration and migration: `Core.lua`
- User strings: `Localization.lua`
- Settings controls: `Options.lua`
- Patch/version/package contract: `OldRunes.toc` and `.github/workflows/release.yml`
- Runtime-only unknowns: `todo.md` or a focused issue, never a fabricated PASS

## Required live checks

Capture exact client build/interface and addon commit for login, reload, specialization swap, PRD hide/show and late setup, combat transitions, all four styles, timer/spiral toggles, and coexistence with default UI plus the normal addon stack. Explicitly verify initial rune readiness, classic texture resolution, taint, forbidden-action, and Lua failures.
