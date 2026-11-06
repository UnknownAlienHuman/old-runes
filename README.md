# Old Runes

Old Runes restores classic rune textures for **Death Knights** on the player RuneFrame and, optionally, the Personal Resource Display (PRD). Blizzard remains the owner of rune identity, order, layout, cooldown timing, and state transitions.

![Old Runes artwork in game](https://media.forgecdn.net/attachments/1566/212/screenshot-2026-03-05-094329-png.png)

## Current target

- World of Warcraft Retail **12.1.5**
- Interface **120105**
- Addon version **2.2.0**
- External libraries: none

The integration was rechecked against `Gethe/wow-ui-source` build `12.1.5.70688` (`d07eb00237d8891f153215db98a5df880a26cfe5`) and the reviewed `12.1.5.70783` endpoint (`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`). The relevant RuneFrame and PRD class-frame implementations are unchanged across those endpoints.

## Installation

Copy the `OldRunes` directory into `World of Warcraft/_retail_/Interface/AddOns/`, then restart the client or use `/reload`.

## Features

- Spec, mixed, Death, and Blizzard specless rune styles.
- Independent cooldown-number and cooldown-spiral controls.
- Optional PRD styling through the exact `PersonalResourceDisplayFrame.classFrame` path.
- Reapplication after login, world entry, specialization changes, late PRD setup, and deferred combat changes.
- One-way migration from legacy `multicolorRunes`; obsolete reverse-layout state is deleted.

## Commands

```text
/or                     Show help
/or config              Open settings
/or timer               Toggle cooldown numbers
/or spiral              Toggle cooldown spiral
/or prd                  Toggle PRD styling
/or style spec           Classic runes for the current specialization
/or style mixed          Two Blood, two Frost, two Unholy
/or style death          Death runes in every slot
/or style specless       Blizzard gray rune art
```

## Engineering boundary

Each loaded Lua file exits immediately unless `UnitClass("player")` resolves to `DEATHKNIGHT`. On other classes the addon creates no namespace, Settings category, slash commands, event owner, hook, timer, or presentation state. The account-wide `OldRunesDB` table can still be loaded by WoW because it is declared in the TOC, but Old Runes does not initialize or mutate it outside a Death Knight session.

Old Runes never assigns `layoutIndex`, calls Blizzard layout/update methods, replaces `UpdateRunes`, or scans frame children. It discovers only `RuneFrame` and `PersonalResourceDisplayFrame.classFrame` and uses post-hooks. Overlay creation, owner replacement, Blizzard-art visibility changes, and configuration commits are deferred until combat ends.

When rune readiness is temporarily unavailable, the existing visual state is preserved instead of inventing a depleted rune. Addon-created overlays are retained in one weak-key owner map so a live rune cannot accumulate duplicate textures.

## Validation

Automated checks cover Lua 5.1 parsing, schema repair, exact frame ownership, all four styles, specialization changes, PRD release/reuse, combat deferral, stale owners, bounded timers, inaccessible objects, unavailable cooldown data, Settings wiring, release safety, and exact ZIP contents. Every core regression runs in a fresh Lua process.

This is not a substitute for a named Retail-client test. Texture resolution, actual rendering, taint, forbidden-action behavior, login/reload, combat, and PRD lifecycle remain `NOT-RUN`; see `todo.md` and issues #1–#2.

## Published addon

[CurseForge: Old Runes](https://www.curseforge.com/wow/addons/old-runes)

## Developer documentation

- [Architecture](ARCHITECTURE.md)
- [Agent guide](AGENT_GUIDE.md)
- [Code index](CODE_INDEX.md)
- [Code graph](CODE_GRAPH.md)
- [Changelog](CHANGELOG.md)
- [Live-client matrix](todo.md)
- [WoW addon engineering knowledge base](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)

## License

Licensed under the [MIT License](LICENSE).
