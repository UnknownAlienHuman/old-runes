# Code index

| Path | Responsibility |
| --- | --- |
| `OldRunes.toc` | Retail metadata, class category/icon, SavedVariables declaration, and runtime load order. |
| `Localization.lua` | Death Knight gate, base strings, and ruRU/esES/esMX/zhCN/zhTW overrides. |
| `Core.lua` | Death Knight gate, schema repair, commands, exact frame ownership, post-hooks, combat deferral, overlay/cooldown presentation, and bounded refresh timers. |
| `Options.lua` | Death Knight-gated Retail Settings canvas and controls. |
| `tests/test_core.lua` | Eleven isolated DK regressions for migration, ownership, release/reuse, PRD lifecycle, combat, timers, inaccessible objects, readiness, and style behavior. |
| `tests/test_options.lua` | Settings registration and control wiring tests. |
| `ARCHITECTURE.md` | Runtime, persistence, release, and ownership design. |
| `AGENT_GUIDE.md` | Current source contract, invariants, and validation commands. |
| `CHANGELOG.md` | Versioned product and validation changes. |
| `todo.md` | Remaining named-client validation only. |
