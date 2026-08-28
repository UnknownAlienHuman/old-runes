# Old Runes

Old Runes restores the classic Death Knight rune textures and lets the player choose spec-based, mixed, Death, or Blizzard specless art. Cooldown numbers, the cooldown spiral, and styling of the Personal Resource Display are configurable.

## Preview

![Old Runes artwork in game](https://media.forgecdn.net/attachments/1566/212/screenshot-2026-03-05-094329-png.png)

Screenshot from the [CurseForge gallery](https://www.curseforge.com/wow/addons/old-runes).

## Installation

Copy the `OldRunes` directory into `World of Warcraft/_retail_/Interface/AddOns/`, then restart the client or use `/reload`.

## Compatibility and data

- Game: World of Warcraft Retail / Midnight 12.1.0
- Interface: `120100`
- Addon version: `2.1.0`
- Saved variables: `OldRunesDB`
- External libraries: none

## Usage

Open the in-game Settings panel, or use `/or` / `/oldrunes`.

Supported commands:

- `timer` — toggle cooldown numbers;
- `spiral` — toggle the cooldown spiral;
- `prd` — toggle Old Runes styling on the Personal Resource Display;
- `style spec|mixed|death|specless` — select rune art;
- `multicolor` — legacy alias for mixed style;
- `config` — open the Settings category.

`reverse` is retained as a compatibility command but deliberately remains disabled. Mutating Blizzard's managed rune layout taints the PlayerFrame path in Retail.

## 2.1.0 update

The 12.1 update replaces broad PRD child discovery with the two source-confirmed rune frames: `RuneFrame` and `PersonalResourceDisplayFrame.classFrame`. A post-hook on `UpdateRunes` now invalidates presentation-only caches after Blizzard reapplies specialization art, and bounded lifecycle refreshes reassert the persisted style after login, specialization changes, reloads, teleports, and world transitions.

Disabling PRD styling now restores Blizzard atlas art and cooldown defaults. Frame references use weak-key state, creation of addon-owned overlays is deferred in combat, and legacy `multicolorRunes` SavedVariables migrate correctly.

## Validation status

Lua syntax, static safety searches, a mocked 12.1 rune/PRD regression suite, and a non-Death-Knight SavedVariables migration suite pass for version 2.1.0. An actual Retail client smoke test is still required before claiming in-game verification; see the open repository issues for the test matrix.

## Published addon

[CurseForge: Old Runes](https://www.curseforge.com/wow/addons/old-runes)

## Developer documentation

- [Architecture](ARCHITECTURE.md)
- [Agent guide](AGENT_GUIDE.md)
- [Code index](CODE_INDEX.md)
- [Code graph](CODE_GRAPH.md)
- [Changelog](CHANGELOG.md)
- [WoW addon engineering knowledge base](https://github.com/UnknownAlienHuman/wow-addon-engineering-kb)

## License

Licensed under the [MIT License](LICENSE).
