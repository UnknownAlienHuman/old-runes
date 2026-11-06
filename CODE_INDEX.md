# Code index

| Path | Responsibility |
| --- | --- |
| `OldRunes.toc` | Retail metadata, SavedVariables declaration, and runtime load order. |
| `Localization.lua` | Base strings and ruRU/esES/esMX/zhCN/zhTW overrides. |
| `Core.lua` | Schema migration, commands, exact frame discovery, post-hooks, combat deferral, and rune/cooldown presentation. |
| `Options.lua` | Retail Settings canvas and controls. |
| `tests/test_core.lua` | Mocked DK/non-DK migration, lifecycle, PRD, combat, and style regression tests. |
| `tests/test_options.lua` | Settings registration and control wiring tests. |
| `ARCHITECTURE.md` | Runtime ownership and lifecycle design. |
| `AGENT_GUIDE.md` | Current source contract, invariants, and validation commands. |
| `CHANGELOG.md` | Versioned changes and validation record. |
| `todo.md` | Remaining named-client validation only. |
