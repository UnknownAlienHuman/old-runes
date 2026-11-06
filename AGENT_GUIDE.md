# Agent guide

## Current contract

- Retail: `12.1.5`
- Interface: `120105`
- Addon: `2.2.0`
- Selected source: `Gethe/wow-ui-source@d07eb00237d8891f153215db98a5df880a26cfe5` (`12.1.5.70688`)
- Latest reviewed relevant endpoint: `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (`12.1.5.70783`)
- Runtime matrix: not complete; see `todo.md`

Read `wow-addon-engineering-kb/INDEX_MINI.md`, the 12.1.5 live/second-pass overlays, and the addon SavedVariables/TOC guides before patch-sensitive changes.

## Non-negotiable invariants

- Every loaded Lua file must exit before creating any addon state unless `UnitClass("player")` is `DEATHKNIGHT`.
- Never assign `rune.layoutIndex`.
- Never call `frame:Layout()` or `frame:UpdateRunes(false)`.
- Never replace `UpdateRunes`; use a post-hook.
- Never enumerate frame children to discover rune frames.
- Never create overlay regions or change Blizzard rune-art visibility in combat.
- Keep discovery limited to `RuneFrame` and `PersonalResourceDisplayFrame.classFrame` unless selected source proves a new path.
- Keep exactly one current player owner and one current PRD class-frame owner; release replacements instead of accumulating them.
- Disabling PRD styling or releasing an accessible rune must restore Blizzard art and cooldown defaults.
- Cancel old readiness timers before replacement and clear each completed handle by its captured slot.
- Do not reintroduce reverse layout, compatibility slash-command branches, or dead localization strings.
- Do not persist frames, regions, timers, hooks, or presentation caches.

## Local checks

```bash
luac5.1 -p Localization.lua Core.lua Options.lua tests/test_core.lua tests/test_options.lua
lua5.1 tests/test_core.lua
lua5.1 tests/test_options.lua
```

`texlua` can be used for an additional parser/test pass, but the release workflow remains the Lua 5.1 gate.

## Change routing

- Runtime integration and migration: `Core.lua`
- User strings: `Localization.lua`
- Settings controls: `Options.lua`
- Patch/version/package contract: `OldRunes.toc` and `.github/workflows/release.yml`
- Runtime-only unknowns: `todo.md` or a focused issue, never a fabricated PASS

## Required live checks

Capture exact client build/interface and addon commit for login, reload, specialization swap, PRD hide/show/rebuild, combat transitions, all four styles, timer/spiral toggles, and coexistence with default UI plus the normal addon stack. Record Lua, taint, forbidden-action, and texture failures.
