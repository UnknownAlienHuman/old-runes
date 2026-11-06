# Code index

| Path | Responsibility |
| --- | --- |
| `OldRunes.toc` | Retail metadata, SavedVariables declaration, and runtime load order. |
| `Localization.lua` | Death Knight gate, base strings, and ruRU/esES/esMX/zhCN/zhTW overrides. |
| `Core.lua` | Death Knight gate, schema migration, commands, exact frame discovery, post-hooks, combat deferral, and rune/cooldown presentation. |
| `Options.lua` | Death Knight gate, Retail Settings canvas, and controls. |
| `tests/test_core.lua` | Mocked DK migration, ownership, lifecycle, PRD, combat, timer, and style regression tests. |
| `tests/test_options.lua` | Settings registration and control wiring tests. |
| `ARCHITECTURE.md` | Runtime ownership and lifecycle design. |
| `AGENT_GUIDE.md` | Current source contract, invariants, and validation commands. |
| `CHANGELOG.md` | Versioned changes and validation record. |
| `todo.md` | Remaining named-client validation only. |
