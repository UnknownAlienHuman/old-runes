# Architecture

`Localization.lua` is loaded before `Core.lua`, which owns defaults, the `OldRunesDB` compatibility path, rune-frame discovery, texture/overlay state, and lifecycle handling. `Options.lua` supplies the Settings and command-facing configuration surface.

The core uses weak-key tables for tracked rune-frame and cooldown presentation state. Durable user choices live in `OldRunesDB`; localization and style constants are shared through `OldRunesUI`.

The main risks are version-dependent frame discovery and protected-frame work during combat. Validate DK rune presentation and the Personal Resource Display both after login and after reload, with every configured display option.
