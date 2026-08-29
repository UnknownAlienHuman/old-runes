# Old Runes - ToDo

## Status: NEEDS IN-GAME TESTING

---

## Task: 12.0.7 Personal Resource Display class frame discovery (2026-06-18)

### Root-cause hypothesis
- In 12.0.7, `PersonalResourceDisplayMixin:SetupClassBar()` creates the Death Knight rune frame as `self.classFrame = FrameUtil.CreateFrame(nil, self.ClassFrameContainer, "RuneFrameTemplate")`.
- The previous Old Runes implementation searched for `prdClassFrame` / `DeathKnightResourceOverlayFrame`, but the new PRD class frame has no global name and therefore was not discovered by `GetRuneFrameCandidates()`.
- As a result, the normal player-frame `RuneFrame` continued to work, while the separately enabled Personal Resource Display did not receive the overlay/hook path.

### Plan
1. Add discovery through `PersonalResourceDisplayFrame.classFrame`.
2. Keep a fallback scan of `ClassFrameContainer` children for nameless or future PRD frames.
3. Deduplicate candidates so the same frame is not hooked or processed twice.
4. Update the TOC target to `120007`.
5. Run API, source, static, and lint checks.

### Progress
- [x] Root cause confirmed against `C:\Tools\WoW_Dev_Tools\wow-ui-source/Blizzard_PersonalResourceDisplay/Blizzard_PersonalResourceDisplay.lua`.
- [x] Code changes completed.
- [x] TOC updated for 12.0.7.
- [x] Static checks completed.
- [ ] In-game smoke test on a Death Knight with Personal Resource Display enabled.

### Change History
- 2026-06-18 1: `Core.lua` — `GetRuneFrameCandidates()` now adds `PersonalResourceDisplayFrame.classFrame`, scans `ClassFrameContainer`, and deduplicates discovered rune frames.
- 2026-06-18 2: `Core.lua` — `IsPersonalResourceFrame()` now recognizes the nameless `PersonalResourceDisplayFrame.classFrame`.
- 2026-06-18 3: `Core.lua` — PRD refresh now post-hooks `SetupClassBar` and `SetHideClassInfo`.
- 2026-06-18 4: `OldRunes.toc` — raised `## Interface` to `120007` and version to `2.0.1`.

### Test Log
- 2026-06-18 1: Verified Blizzard source: DK PRD uses `RuneFrameTemplate` through `FrameUtil.CreateFrame(nil, self.ClassFrameContainer, classFrameInfo.template)`.
- 2026-06-18 2: Verified `wow-api`: `GetRuneCooldown`, `C_SpecializationInfo.GetSpecialization`, `UnitClass`, `hooksecurefunc`, `C_Timer.After`; Frame widget methods include `GetChildren` / `GetNumChildren`.
- 2026-06-18 3: `git diff --check -- _Addons/OldRunes` -> clean.
- 2026-06-18 4: `lua-language-server.exe --check=WoWDevAddons --checklevel=Error` -> `Diagnosis completed, no problems found`.
- 2026-06-18 5: Static grep for `layoutIndex\s*=|:Layout\(|UpdateRunes\(false\)` across `OldRunes/*.lua` -> no matches.

---

## Task: Add Specless Rune Style (2026-03-05)

### Root-cause hypothesis
- The current styles (`SPEC/MIXED/DEATH`) work by hiding Blizzard atlas layers and applying an addon-owned texture (`overlay`).
- Blizzard's `specless` runes (gray, `Default`) are produced by the atlas pipeline in `RuneButtonMixin:UpdateSpec(nil)`, so the overlay mechanism is not appropriate for this style.

### Plan
1. Add a new `SPECLESS` style to Core, Options, Localization, and slash commands.
2. For `SPECLESS`, disable the overlay path and explicitly restore Blizzard's `Default` atlas through `rune:UpdateSpec(nil)`.
3. Preserve the taint-safe approach: no layout mutation (`layoutIndex` / `frame:Layout()`).
4. Run static checks and update the history.

### Progress
- [x] Root cause confirmed against Blizzard `RuneFrame.lua` (`DefaultArtType` through `UpdateSpec(nil)`).
- [x] Code changes completed.
- [x] Static verification completed.
- [x] Task closed.

### Change History
- 2026-03-05 1: Opened the task to add a `specless` style based on the Blizzard atlas.
- 2026-03-05 2: `Core.lua` — added `RUNE_STYLE_SPECLESS`, slash aliases (`specless|gray|grey`), and the localized style name.
- 2026-03-05 3: `Core.lua` — added `EnsureBlizzardRuneArt(...)`: for `SPECLESS`, it calls `rune:UpdateSpec(nil)` and disables the overlay path, preserving Blizzard atlas rendering.
- 2026-03-05 4: `Options.lua` — added the `Specless (Blizzard gray atlas)` style checkbox.
- 2026-03-05 5: `Localization.lua` — added `CMD_DESC_STYLE_SPECLESS`, `STYLE_NAME_SPECLESS`, and `OPT_STYLE_SPECLESS_*`; updated `MSG_STYLE_USAGE`.

### Test Log
- 2026-03-05 1: Confirmed in `Blizzard_UnitFrame/Mainline/RuneFrame.lua`: when `specIndex == nil`, `RuneButtonMixin:UpdateSpec` uses `DefaultArtType` (gray specless runes).
- 2026-03-05 2: Verified `wow-api`: `GetRuneCooldown`, `C_SpecializationInfo.GetSpecialization` — signatures are valid for Mainline.
- 2026-03-05 3: Static grep `rg -n "RUNE_STYLE_SPECLESS|style specless|CMD_DESC_STYLE_SPECLESS|OPT_STYLE_SPECLESS" _Addons/OldRunes -g "*.lua"` -> the style is present in Core, Options, and Localization.
- 2026-03-05 4: Static grep `rg -n "EnsureBlizzardRuneArt|UpdateSpec\(nil\)|GetTextureForRune\(" _Addons/OldRunes/Core.lua` -> `SPECLESS` uses the Blizzard atlas path through `UpdateSpec(nil)`.
- 2026-03-05 5: Static grep `rg -n "layoutIndex\s*=|:Layout\(|UpdateRunes\(false\)" _Addons/OldRunes -g "*.lua"` -> no matches; taint-prone mutations were not restored.

---

## Task: Mixed rune order fix without reverse (2026-03-05)

### Root-cause hypothesis
- In mixed mode, `Core.lua` selects the color using the `Runes[i]` array index.
- In Blizzard's `RuneFrameTemplate`, the slots are already reversed through `layoutIndex` (`Rune1=6 ... Rune6=1`), so the visual order becomes reversed.
- After the taint-prone reverse path was disabled, this appeared as `Unholy -> Frost -> Blood` from left to right.

### Plan
1. Base mixed coloring on `rune.layoutIndex` (the visual slot), not the array index.
2. Preserve the taint-safe mode: do not restore `layoutIndex` mutation or `frame:Layout()`.
3. Run static verification and record the result.

### Progress
- [x] Root cause confirmed against `RuneFrame.xml`.
- [x] Code changes completed.
- [x] Static verification completed.
- [x] Task closed.

### Change History
- 2026-03-05 1: Opened a task to correct mixed ordering without re-enabling reverse.
- 2026-03-05 2: `Core.lua` — changed mixed logic from the `Runes[i]` array index to `rune.layoutIndex`, with a fallback to the array index when `layoutIndex` is unavailable.

### Test Log
- 2026-03-05 1: Verified Blizzard source `Blizzard_UnitFrame/Mainline/RuneFrame.xml` — rune `layoutIndex` values are defined in reverse order (`6..1`).
- 2026-03-05 2: Verified `wow-api`: `GetRuneCooldown`, `C_SpecializationInfo.GetSpecialization`, `UnitClass` — signatures are valid for Mainline.
- 2026-03-05 3: Static grep `rg -n "GetMixedTextureByLayout|layoutIndex" _Addons/OldRunes/Core.lua` -> mixed coloring uses `rune.layoutIndex`.
- 2026-03-05 4: Static grep `rg -n "layoutIndex\s*=|:Layout\(" _Addons/OldRunes -g "*.lua"` -> no matches; unsafe layout mutation was not restored.
- 2026-03-05 5: Static grep `rg -n "UpdateRunes\(false\)" _Addons/OldRunes -g "*.lua"` -> no matches; the forced call was not restored.

---

## Task: Taint fix for PlayerFrameBottomManagedFramesContainer (2026-03-04)

### Root-cause hypothesis
- `Core.lua` manually changes `rune.layoutIndex` and calls `frame:Layout()` for runes inheriting `PlayerFrameBottomManagedFrameTemplate`, which is part of a managed/protected path.
- This taints the player managed-container layout chain; later, the secure flow `UIParentManagedFrameMixin.OnHide -> RemoveManagedFrame -> PlayerFrameBottomManagedFramesContainer:Layout` is blocked at `SetSize()` during combat.

### Plan
1. Remove manual layout mutations (`rune.layoutIndex`, `frame:Layout`) from the addon.
2. Remove the forced `frame:UpdateRunes(false)` call from the addon.
3. Keep `reverseRecoveryOrder` in a safe mode that does not alter managed layout.
4. Run static verification and record the result.

### Progress
- [x] Root cause localized from the stack trace and `Core.lua`.
- [x] Code changes completed.
- [x] Static verification completed.
- [x] Incident closed.

### Change History
- 2026-03-04 1: Created a plan for the taint incident with the confirmed root cause: managed-layout mutation.
- 2026-03-04 2: `Core.lua` — removed unsafe `rune.layoutIndex` mutations and the `frame:Layout()` call from `OldRunesUI.UpdateRecoveryOrder`.
- 2026-03-04 3: `Core.lua` — removed the forced `frame:UpdateRunes(false)` call from `ForceUpdateTrackedRuneFrames`.
- 2026-03-04 4: Added a safety comment explaining why layout mutation is disabled.
- 2026-03-04 5: `Core.lua` — removed `PersonalResourceDisplayFrame:HookScript("OnShow")`; retained only `hooksecurefunc(..., "SetupClassBar", ...)` as the safer post-hook.
- 2026-03-04 6: `Core.lua + Options.lua` — moved `reverseRecoveryOrder` into an explicitly disabled taint-safe mode: legacy SavedVariables are forced to `false`, and slash/UI paths show a message instead of pretending to toggle it.

### Test Log
- 2026-03-04 1: Static grep `rg -n "\:Layout\(|layoutIndex\s*=|UpdateRunes\(false\)" _Addons/OldRunes -g "*.lua"` -> no matches (`rg` exit code 1 means not found).
- 2026-03-04 2: Static grep `rg -n "PersonalResourceDisplayFrame:HookScript|hooksecurefunc\(PersonalResourceDisplayFrame" _Addons/OldRunes/Core.lua` -> `HookScript` is absent; only `hooksecurefunc` remains.
- 2026-03-04 3: Static grep `rg -n "reverseRecoveryOrder|MSG_REVERSE_DISABLED|/or reverse" _Addons/OldRunes -g "*.lua"` -> `reverseRecoveryOrder` no longer activates a layout path; slash/options display the taint-safe disabled message.

---

## Code Review (2026-03-03 pass 2)

### ✅ Fixed in this pass

- [x] **Core.lua + Options.lua** — removed the dead `SETTINGS_CATEGORY_ID` string (`"OldRunes"`). It was used as a fallback for `Settings.OpenToCategory()`, but that function expects a numeric ID, so the string fallback could never work.
- [x] **Core.lua** — simplified `/or config`: removed the string-ID fallback chain and the redundant `Settings.GetCategory` call. If `settingsCategoryID == nil`, it now immediately prints `not registered`.
- [x] **Core.lua** — `UpdateCooldownSpiral` now checks dirty state before calling `SetSwipeColor`, matching the other properties in that block.
- [x] **Options.lua** — removed deprecated callbacks `panel.okay`, `panel.default`, and `panel.refresh`; they are not used by `Settings.RegisterCanvasLayoutCategory`.
- [x] **Options.lua** — style checkboxes (Spec/Mixed/Death) now prevent unchecking the active style: clicking the selected style no longer flickers and simply preserves the checked state.

---

## Code Review (2026-03-03)

### ✅ Fixed in this pass

- [x] **Core.lua** — the non-DK early return left the `OldRunesUI` API incomplete; opening Settings on a non-DK character could fail when calling `OldRunesUI.*`.
  - **Fix**: added a database-only mode with safe implementations of `EnsureDBDefaults / GetRuneStyle / SetRuneStyle` and no-op visual update methods.

- [x] **Core.lua + Options.lua** — `/or config` opened Settings through `Settings.GetCategory("Old Runes")`, but Settings uses a numeric `categoryID`.
  - **Fix**: category registration now stores `category:GetID()` in `OldRunesUI.settingsCategoryID`; `/or config` opens the saved numeric ID.

- [x] **Core.lua** — `suppressHookRefresh` could remain `true` if a forced `UpdateRunes` call failed.
  - **Fix**: frame updates were moved into a helper using `pcall` with a guaranteed flag reset.

- [x] **Options.lua** — category registration was hardened: if the `Settings` API is unavailable during file load, registration is retried later on `PLAYER_LOGIN` / `ADDON_LOADED Blizzard_Settings`.

- [x] **Options.lua** — removed the hard dependency on the deprecated checkbox template.
  - **Fix**: `CreateOptionCheckButton()` now uses `UICheckButtonTemplate`; labels and tooltips are rendered directly.

- [x] **Core.lua** — the slash handler could fail on a `nil` message.
  - **Fix**: replaced `msg:lower()` with `(msg or ""):lower()`.

- [x] **Core.lua** — normalized the `DK-BloodUnholy-Rune-CDSpark` path to consistent uppercase `PLAYERFRAME` for better compatibility with case-sensitive file systems.

### ✅ Verified facts (Blizzard source)

- [x] `InterfaceOptionsCheckButtonTemplate` is marked deprecated but is still present in build `12.0.1` (`Blizzard_FrameXML/DeprecatedTemplates.xml`).
- [x] `Settings.RegisterCanvasLayoutCategory` accepts `(frame, name)`; `SettingsCategoryMixin:GetID()` returns the numeric category ID.

### 🔎 Remaining in-game verification

- [ ] Verify `/or config` immediately after login and after `/reload`.
- [ ] Verify Settings can be opened on a non-DK character without Lua errors.
- [ ] Verify rune spiral/timer rendering for every DK specialization in and out of combat.

---

## Code Review (2026-03-02) [Archive]

### 🔴 Bugs / Will Error

- [x] **Options.lua:21,31,41,51,65,70,75** — obsolete after the 2026-03-03 pass.
  - The dependency on `InterfaceOptionsCheckButtonTemplate` was fully removed; `UICheckButtonTemplate` is used instead.

- [x] **Options.lua:133** — fixed in the 2026-03-03 pass.
  - Registration is wrapped in `RegisterOptionsCategory()` with a deferred retry on `PLAYER_LOGIN` / `ADDON_LOADED`.

### 🟡 Potential Issues

- [x] **Core.lua:731** — fixed in the 2026-03-03 pass.
  - `/or config` now uses the stored `category:GetID()` through `OldRunesUI.settingsCategoryID`.

- [x] **Core.lua:40** — fixed in the 2026-03-03 pass.
  - The edge texture path was normalized to `Interface\\PLAYERFRAME\\DK-BloodUnholy-Rune-CDSpark`.

- [x] **OldRunes.toc:1** — verified on the local client.
  - `%WOW_RETAIL%\WTF\Config.wtf` contains `SET lastAddonVersion "120001"`; the current `## Interface` covers that build.

- [x] **Core.lua:5** — intentionally retained.
  - This is a safe bootstrap pattern followed by `EnsureDBDefaults()`; it does not cause errors or data loss.

### 🟢 Code Quality / Nitpicks

- [x] **Options.lua:4-6** — fixed in the 2026-03-03 pass.
  - Constants are exported through `OldRunesUI.RUNE_STYLE_*` in `Core.lua` and reused in `Options.lua`.

- [x] **Core.lua:50** — fixed in the 2026-03-03 pass.
  - Added a helper using `pcall` and a guaranteed reset of `suppressHookRefresh`.

- [x] **Localization.lua** — intentional.
  - `ADDON_NAME` is deliberately not localized because it is the addon's brand/identity.

- [x] **Core.lua:564-566** — verified/fixed.
  - Recursion is blocked by `suppressHookRefresh`; the flag is protected by the `pcall` guard and always reset.

## Fixed Issues
- [x] Wrong rune access: `_G["RuneButtonIndividual"..i]` → `RuneFrame.Runes[i]`
- [x] SetTexture on Frame → CreateTexture overlay on rune frame
- [x] Removed InterfaceOptions_AddCategory fallback (deprecated)
- [x] Removed duplicate defaults initialization
- [x] Proper Settings API: `Settings.RegisterCanvasLayoutCategory()` + `Settings.RegisterAddOnCategory()`
- [x] Atlas layer hiding when custom texture active
- [x] DepleteVisuals layers hidden when custom texture active

## Open Questions (need verification in-game)
- [ ] Old textures still exist in the 12.x client?
  - Path: `Interface\PLAYERFRAME\UI-PlayerFrame-Deathknight-Blood` etc.
  - If not found, the client will show a green/missing texture.
  - Fallback: alternative textures may be required if Blizzard removed them.

## Implementation Notes

### Blizzard Source (build 12.0.1.65867)
- `Blizzard_UnitFrame\RuneFrame.lua:187-210` - ArtTypeBySpec, RuneArtSet
- `Blizzard_UnitFrame\RuneFrame.xml:4-137` - RuneButtonIndividualTemplate layers
- Access: `RuneFrame.Runes[i]` (array of RuneButton frames)
- Each rune has layers: Rune_Grad, Rune_Lines, Rune_Active, Rune_Mid, Rune_Eyes, Glow, Glow2, Smoke

### Settings API (confirmed working)
```lua
local category = Settings.RegisterCanvasLayoutCategory(panel, "Old Runes")
Settings.RegisterAddOnCategory(category)
Settings.OpenToCategory(category:GetID()) -- for slash command
```

## Changelog
- 2026-02-25: Initial refactor for 12.x compatibility

---

## Task: Full rename to "Old Runes" (2026-02-26)

### Plan
1. Read required `_Info` docs and confirm workflow constraints.
2. Rename internal addon identifiers in Lua/TOC (title, addon key, settings key, slash namespace, SavedVariables, frame names).
3. Rename files/folder to final addon name (`Old Runes.toc`, `_Addons/Old Runes`).
4. Run static verification (search for stale `RuneReplacement` references).
5. Record change history and test results.

### Progress
- [x] Read required `_Info` docs (`README`, `BlizzardUI_DevWorkflow`, `BlizzardUI_SubsystemRouter`, `BlizzardUI_Lifecycle_LoadOnDemand`).
- [x] Rename internal identifiers.
- [x] Rename TOC and addon directory.
- [x] Verify and document results.

### Change History
- 2026-02-26 1: Initialized rename task and plan.
- 2026-02-26 2: Updated internal addon identifiers in `Core.lua`, `Options.lua`, and TOC metadata (`Title`, `Notes`, `SavedVariables`) to `Old Runes` / `OldRunes`.
- 2026-02-26 3: Renamed `RuneReplacement.toc` -> `Old Runes.toc`.
- 2026-02-26 4: Renamed addon directory `_Addons/RuneReplacement` -> `_Addons/Old Runes`.
- 2026-02-26 5: Verified no stale `RuneReplacement` references in code files (`rg -n "RuneReplacement" -g "!todo.md"`).
- 2026-02-26 6: Attempted Lua syntax validation with `luac -p`.
- 2026-02-26 7: Hardened `ADDON_LOADED` gate to accept both addon key variants (`Old Runes` and `OldRunes`) for folder-name compatibility.

### Test Log
- 2026-02-26 1: Static structure check: addon now contains `Core.lua`, `Options.lua`, `Old Runes.toc`, `todo.md`.
- 2026-02-26 2: Static grep check: `RuneReplacement` references are absent in functional files (`Core.lua`, `Options.lua`, `Old Runes.toc`).
- 2026-02-26 3: `luac -p` validation could not run (`luac` is not installed in current environment).
- 2026-02-26 4: Verified `ADDON_LOADED` gate supports both keys (`Old Runes`, `OldRunes`) and still has no stale `RuneReplacement` references in code.

---

## Task: Machine-safe rename to "OldRunes" (2026-02-26)

### Plan
1. Keep user-facing naming with spaces where safe (`Title`, printed UI text).
2. Rename machine-critical paths/names to no-space variant (`_Addons/OldRunes`, `OldRunes.toc`).
3. Align addon load gate to strict machine addon key (`ADDON_LOADED == "OldRunes"`).
4. Run static verification and record results.

### Progress
- [x] Read required `_Info` docs (`README`, `BlizzardUI_DevWorkflow`, `BlizzardUI_SubsystemRouter`, `BlizzardUI_Lifecycle_LoadOnDemand`).
- [x] Verified `ADDON_LOADED` payload via `wow-api` (`addOnName, containsBindings`) and Blizzard source pattern (`Blizzard_AuctionHouseFrame.lua`).
- [x] Rename folder/TOC to `OldRunes`.
- [x] Final verification and log update.

### Change History
- 2026-02-26 8: Initialized machine-safe rename task per request.
- 2026-02-26 9: Renamed `Old Runes.toc` -> `OldRunes.toc` and `_Addons/Old Runes` -> `_Addons/OldRunes`.
- 2026-02-26 10: Updated `ADDON_LOADED` guard to strict machine key `OldRunes`.

### Test Log
- 2026-02-26 5: Path check: `_Addons/Old Runes` is absent, `_Addons/OldRunes` exists.
- 2026-02-26 6: Structure check: addon contains `Core.lua`, `Options.lua`, `OldRunes.toc`, `todo.md`.
- 2026-02-26 7: Static code check: `Core.lua` uses `if addonName ~= "OldRunes" then return end`.
- 2026-02-26 8: Display-name check: TOC title remains `Old Runes`.
