# Old Runes

Old Runes restores the classic rune textures for **Death Knights** on the player RuneFrame and, optionally, the Personal Resource Display (PRD). Blizzard continues to own rune identity, order, layout, cooldown timing, and state transitions.

## Current target

- World of Warcraft Retail **12.1.5**
- TOC Interface **120105**
- Addon version **2.2.0**

The integration is checked against `Gethe/wow-ui-source` build `12.1.5.70688` (`d07eb00237d8891f153215db98a5df880a26cfe5`) and the reviewed `12.1.5.70783` endpoint (`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`). The relevant `RuneFrame` and PRD class-frame contracts are unchanged across those endpoints.

## Features

- Spec, mixed, Death, and Blizzard specless rune styles.
- Independent cooldown-number and cooldown-spiral controls.
- Optional PRD styling through exact `PersonalResourceDisplayFrame.classFrame` discovery.
- Reapplication after login, world entry, specialization changes, PRD rebuilds, and deferred combat changes.
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

## Safety boundary

The first runtime gate exits unless the player is a Death Knight. No database migration, settings registration, slash command, frame hook, timer, or rune presentation owner is created outside that class.

Old Runes does not assign `layoutIndex`, call Blizzard layout methods, replace `UpdateRunes`, or force rune updates. It discovers only the two reviewed frame paths and uses post-hooks. Overlay creation, owner replacement, Blizzard-art visibility changes, and configuration commits are deferred until combat ends.

## Validation

Repository checks cover:

- Lua 5.1 parsing;
- schema migration and malformed-value normalization;
- player and PRD discovery, replacement, release, and overlay reuse;
- all four styles and specialization reapplication;
- PRD disable/restore behavior;
- combat deferral without partial configuration commits;
- bounded refresh timers and stale-owner rejection;
- Settings control wiring;
- exact installable ZIP contents.

Live-client verification remains required for texture assets, taint/forbidden-action behavior, and the full login/reload/combat matrix; see `todo.md` and issues #1–#2.
