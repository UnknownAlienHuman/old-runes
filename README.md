# Old Runes

Old Runes restores the classic Death Knight rune textures on the player RuneFrame and, optionally, the Personal Resource Display (PRD). Blizzard continues to own rune order, layout, cooldown timing, and state transitions.

## Current target

- World of Warcraft Retail **12.1.5**
- TOC Interface **120105**
- Addon version **2.2.0**

The integration is checked against `Gethe/wow-ui-source` build `12.1.5.70688` (`d07eb00237d8891f153215db98a5df880a26cfe5`) and the reviewed `12.1.5.70783` endpoint (`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`). The relevant `RuneFrame` and PRD class-frame contracts are unchanged across those endpoints.

## Features

- Spec, mixed, Death, and Blizzard specless rune styles.
- Independent cooldown numbers and spiral controls.
- Optional PRD styling with exact `PersonalResourceDisplayFrame.classFrame` discovery.
- Automatic reapplication after login, world entry, specialization changes, PRD rebuilds, and combat deferral.
- One-way migration from legacy `multicolorRunes`; obsolete reverse-layout state is removed.

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

The legacy `/or multicolor` alias remains accepted but is intentionally omitted from help.

## Safety boundary

Old Runes does not assign `layoutIndex`, call Blizzard layout methods, replace `UpdateRunes`, or force rune updates. It uses exact frame paths and post-hooks only. Creation of addon-owned overlays and Blizzard atlas visibility changes are deferred until combat ends.

## Validation

Repository tests cover:

- Lua source parsing;
- non-DK configuration and SavedVariables migration;
- player and PRD frame discovery;
- style transitions and specialization reapplication;
- PRD disable/restore behavior;
- combat deferral;
- duplicate-overlay prevention;
- Settings control wiring.

Live-client verification remains required for the texture assets and full login/reload/combat matrix; see `todo.md` and issues #1–#2.
