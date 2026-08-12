# Old Runes - ToDo

## Status: NEEDS IN-GAME TESTING

---

## Task: 12.0.7 Personal Resource Display class frame discovery (2026-06-18)

### Root-cause hypothesis
- В 12.0.7 `PersonalResourceDisplayMixin:SetupClassBar()` создаёт DK rune frame как `self.classFrame = FrameUtil.CreateFrame(nil, self.ClassFrameContainer, "RuneFrameTemplate")`.
- Старый OldRunes искал `prdClassFrame`/`DeathKnightResourceOverlayFrame`, но новый PRD class frame без глобального имени не попадал в `GetRuneFrameCandidates()`.
- Поэтому `RuneFrame` на фрейме персонажа продолжал работать, а отдельно включаемый Personal Resource Display не получал overlay/hook path.

### Plan
1. Добавить discovery через `PersonalResourceDisplayFrame.classFrame`.
2. Оставить fallback-скан детей `ClassFrameContainer` для nameless/future PRD frames.
3. Дедуплицировать кандидаты, чтобы один frame не хукался/обрабатывался дважды.
4. Обновить TOC target до `120007`.
5. Выполнить API/source/static/lint checks.

### Progress
- [x] Root cause подтверждён по `C:\Tools\WoW_Dev_Tools\wow-ui-source/Blizzard_PersonalResourceDisplay/Blizzard_PersonalResourceDisplay.lua`.
- [x] Кодовые правки выполнены.
- [x] TOC обновлён под 12.0.7.
- [x] Статические проверки выполнены.
- [ ] In-game smoke test на DK с включённым Personal Resource Display.

### Change History
- 2026-06-18 1: `Core.lua` — `GetRuneFrameCandidates()` теперь добавляет `PersonalResourceDisplayFrame.classFrame`, сканирует `ClassFrameContainer` и дедуплицирует найденные rune frames.
- 2026-06-18 2: `Core.lua` — `IsPersonalResourceFrame()` распознаёт nameless `PersonalResourceDisplayFrame.classFrame`.
- 2026-06-18 3: `Core.lua` — PRD refresh теперь пост-хукает `SetupClassBar` и `SetHideClassInfo`.
- 2026-06-18 4: `OldRunes.toc` — `## Interface` поднят до `120007`, версия до `2.0.1`.

### Test Log
- 2026-06-18 1: Проверен Blizzard source: DK PRD использует `RuneFrameTemplate` через `FrameUtil.CreateFrame(nil, self.ClassFrameContainer, classFrameInfo.template)`.
- 2026-06-18 2: Проверен `wow-api`: `GetRuneCooldown`, `C_SpecializationInfo.GetSpecialization`, `UnitClass`, `hooksecurefunc`, `C_Timer.After`; Frame widget methods include `GetChildren`/`GetNumChildren`.
- 2026-06-18 3: `git diff --check -- _Addons/OldRunes` -> clean.
- 2026-06-18 4: `lua-language-server.exe --check=WoWDevAddons --checklevel=Error` -> `Diagnosis completed, no problems found`.
- 2026-06-18 5: Статический grep `layoutIndex\s*=|:Layout\(|UpdateRunes\(false\)` по `OldRunes/*.lua` -> совпадений нет.

---

## Task: Add Specless Rune Style (2026-03-05)

### Root-cause hypothesis
- Текущие стили (`SPEC/MIXED/DEATH`) работают через скрытие Blizzard atlas-слоев и наложение нашей текстуры (`overlay`).
- `specless`-руны Blizzard (серые, `Default`) находятся в atlas-пайплайне `RuneButtonMixin:UpdateSpec(nil)`, поэтому overlay-механизм для этого стиля не подходит.

### Plan
1. Добавить новый стиль `SPECLESS` в Core/Options/Localization/slash.
2. Для `SPECLESS` отключать overlay path и принудительно возвращать Blizzard `Default` atlas через `rune:UpdateSpec(nil)`.
3. Сохранить taint-safe подход: без layout mutation (`layoutIndex`/`frame:Layout()`).
4. Выполнить статические проверки и обновить историю.

### Progress
- [x] Root cause подтвержден по Blizzard `RuneFrame.lua` (`DefaultArtType` через `UpdateSpec(nil)`).
- [x] Кодовые правки выполнены.
- [x] Статическая проверка выполнена.
- [x] Задача закрыта.

### Change History
- 2026-03-05 1: Открыт task на добавление `specless`-стиля на базе Blizzard atlas.
- 2026-03-05 2: `Core.lua` — добавлен стиль `RUNE_STYLE_SPECLESS`, slash aliases (`specless|gray|grey`) и локализованное имя стиля.
- 2026-03-05 3: `Core.lua` — добавлен `EnsureBlizzardRuneArt(...)`: для `SPECLESS` вызывается `rune:UpdateSpec(nil)`, overlay path отключается (atlas-рендер Blizzard сохраняется).
- 2026-03-05 4: `Options.lua` — добавлен новый чекбокс стиля `Specless (Blizzard gray atlas)`.
- 2026-03-05 5: `Localization.lua` — добавлены ключи `CMD_DESC_STYLE_SPECLESS`, `STYLE_NAME_SPECLESS`, `OPT_STYLE_SPECLESS_*`; обновлен `MSG_STYLE_USAGE`.

### Test Log
- 2026-03-05 1: Подтверждено в `Blizzard_UnitFrame/Mainline/RuneFrame.lua`: если `specIndex == nil`, `RuneButtonMixin:UpdateSpec` использует `DefaultArtType` (серые specless-руны).
- 2026-03-05 2: Проверен `wow-api`: `GetRuneCooldown`, `C_SpecializationInfo.GetSpecialization` — сигнатуры валидны для Mainline.
- 2026-03-05 3: Статический grep `rg -n "RUNE_STYLE_SPECLESS|style specless|CMD_DESC_STYLE_SPECLESS|OPT_STYLE_SPECLESS" _Addons/OldRunes -g "*.lua"` -> стиль добавлен в Core/Options/Localization.
- 2026-03-05 4: Статический grep `rg -n "EnsureBlizzardRuneArt|UpdateSpec\(nil\)|GetTextureForRune\(" _Addons/OldRunes/Core.lua` -> `SPECLESS` использует Blizzard atlas path через `UpdateSpec(nil)`.
- 2026-03-05 5: Статический grep `rg -n "layoutIndex\s*=|:Layout\(|UpdateRunes\(false\)" _Addons/OldRunes -g "*.lua"` -> совпадений нет (taint-опасные мутации не возвращены).

---

## Task: Mixed rune order fix without reverse (2026-03-05)

### Root-cause hypothesis
- `Core.lua` в mixed-режиме выбирает цвет по индексу массива `Runes[i]`.
- В Blizzard `RuneFrameTemplate` слоты уже инвертированы через `layoutIndex` (`Rune1=6 ... Rune6=1`), поэтому визуальный порядок получается обратным.
- После отключения taint-опасного reverse это проявилось как `Unholy -> Frost -> Blood` слева направо.

### Plan
1. Перевести mixed-раскраску на `rune.layoutIndex` (визуальный слот), а не на индекс массива.
2. Сохранить taint-safe режим: не возвращать мутацию `layoutIndex` и `frame:Layout()`.
3. Выполнить статическую проверку и зафиксировать результат.

### Progress
- [x] Root cause подтвержден по `RuneFrame.xml`.
- [x] Кодовые правки выполнены.
- [x] Статическая проверка выполнена.
- [x] Задача закрыта.

### Change History
- 2026-03-05 1: Открыт новый task на исправление mixed-порядка без включения reverse.
- 2026-03-05 2: `Core.lua` — mixed-логика переведена с индекса массива `Runes[i]` на `rune.layoutIndex` (fallback на индекс массива, если layoutIndex недоступен).

### Test Log
- 2026-03-05 1: Проверен Blizzard source `Blizzard_UnitFrame/Mainline/RuneFrame.xml` — `layoutIndex` для рун задан в обратном порядке (`6..1`).
- 2026-03-05 2: Проверен `wow-api`: `GetRuneCooldown`, `C_SpecializationInfo.GetSpecialization`, `UnitClass` — сигнатуры валидны для Mainline.
- 2026-03-05 3: Статический grep `rg -n "GetMixedTextureByLayout|layoutIndex" _Addons/OldRunes/Core.lua` -> mixed-раскраска использует `rune.layoutIndex`.
- 2026-03-05 4: Статический grep `rg -n "layoutIndex\s*=|:Layout\(" _Addons/OldRunes -g "*.lua"` -> совпадений нет (unsafe layout mutation не возвращена).
- 2026-03-05 5: Статический grep `rg -n "UpdateRunes\(false\)" _Addons/OldRunes -g "*.lua"` -> совпадений нет (принудительный вызов не возвращен).

---

## Task: Taint fix for PlayerFrameBottomManagedFramesContainer (2026-03-04)

### Root-cause hypothesis
- `Core.lua` вручную меняет `rune.layoutIndex` и вызывает `frame:Layout()` для рун, которые наследуют `PlayerFrameBottomManagedFrameTemplate` (managed/protected path).
- Это taint'ит цепочку layout контейнера игрока; позже secure-flow `UIParentManagedFrameMixin.OnHide -> RemoveManagedFrame -> PlayerFrameBottomManagedFramesContainer:Layout` блокируется на `SetSize()` в бою.

### Plan
1. Удалить ручные мутации layout (`rune.layoutIndex`, `frame:Layout`) из аддона.
2. Удалить принудительный вызов `frame:UpdateRunes(false)` из аддона.
3. Оставить `reverseRecoveryOrder` в безопасном режиме без изменения managed layout.
4. Выполнить статическую проверку и зафиксировать результат.

### Progress
- [x] Root cause локализован по стектрейсу и коду `Core.lua`.
- [x] Кодовые правки выполнены.
- [x] Статическая проверка выполнена.
- [x] Инцидент закрыт.

### Change History
- 2026-03-04 1: Создан план фикса taint-инцидента с подтвержденным корнем проблемы (managed layout mutation).
- 2026-03-04 2: `Core.lua` — удалены unsafe мутации `rune.layoutIndex` и вызов `frame:Layout()` из `OldRunesUI.UpdateRecoveryOrder`.
- 2026-03-04 3: `Core.lua` — удален принудительный вызов `frame:UpdateRunes(false)` из `ForceUpdateTrackedRuneFrames`.
- 2026-03-04 4: Добавлен safety-комментарий по причине отключения layout mutation.
- 2026-03-04 5: `Core.lua` — удален `PersonalResourceDisplayFrame:HookScript("OnShow")`; оставлен только `hooksecurefunc(..., "SetupClassBar", ...)` как более безопасный post-hook.
- 2026-03-04 6: `Core.lua + Options.lua` — `reverseRecoveryOrder` переведен в явно отключенный режим (taint-safe): legacy SV принудительно в `false`, slash/UI показывают сообщение вместо фиктивного переключения.

### Test Log
- 2026-03-04 1: Статический grep `rg -n "\:Layout\(|layoutIndex\s*=|UpdateRunes\(false\)" _Addons/OldRunes -g "*.lua"` -> совпадений нет (exit code 1 у `rg` = not found).
- 2026-03-04 2: Статический grep `rg -n "PersonalResourceDisplayFrame:HookScript|hooksecurefunc\(PersonalResourceDisplayFrame" _Addons/OldRunes/Core.lua` -> `HookScript` отсутствует, остается только `hooksecurefunc`.
- 2026-03-04 3: Статический grep `rg -n "reverseRecoveryOrder|MSG_REVERSE_DISABLED|/or reverse" _Addons/OldRunes -g "*.lua"` -> `reverseRecoveryOrder` больше не активирует layout path; в slash/options выводится сообщение о taint-safe отключении.

---

## Code Review (2026-03-03 pass 2)

### ✅ Fixed in this pass

- [x] **Core.lua + Options.lua** — удалён мёртвый `SETTINGS_CATEGORY_ID` (`"OldRunes"` строка). Он использовался как fallback для `Settings.OpenToCategory()`, но эта функция ожидает числовой ID — строка никогда не срабатывала.
- [x] **Core.lua** — `/or config` упрощён: убрана цепочка fallback на строковый ID и лишний вызов `Settings.GetCategory`. Если `settingsCategoryID == nil`, сразу печатается "not registered".
- [x] **Core.lua** — `UpdateCooldownSpiral` теперь проверяет dirty-state перед вызовом `SetSwipeColor` (аналогично остальным свойствам в этом блоке).
- [x] **Options.lua** — удалены deprecated callbacks `panel.okay`, `panel.default`, `panel.refresh` — они не используются системой `Settings.RegisterCanvasLayoutCategory`.
- [x] **Options.lua** — style checkboxes (Spec/Mixed/Death) теперь предотвращают uncheck: клик по уже активному стилю не мерцает, а просто сохраняет checked-состояние.

---

## Code Review (2026-03-03)

### ✅ Fixed in this pass

- [x] **Core.lua** — non-DK early return оставлял `OldRunesUI` API неполным; при открытии настроек на не-DK могли падать вызовы `OldRunesUI.*`.
  - **Fix**: добавлен `database-only` режим с безопасными реализациями `EnsureDBDefaults / GetRuneStyle / SetRuneStyle` и no-op для визуальных обновлений.

- [x] **Core.lua + Options.lua** — `/or config` открывал настройки через `Settings.GetCategory("Old Runes")`, но в Settings используется числовой `categoryID`.
  - **Fix**: при регистрации категории сохраняется `category:GetID()` в `OldRunesUI.settingsCategoryID`; `/or config` открывает категорию по сохранённому ID.

- [x] **Core.lua** — `suppressHookRefresh` мог остаться `true` при ошибке внутри принудительного `UpdateRunes`.
  - **Fix**: обновление кадров вынесено в helper с `pcall` и гарантированным reset флага.

- [x] **Options.lua** — регистрация категории усилена: если `Settings` API недоступен при file-load, выполняется отложенная повторная регистрация (`PLAYER_LOGIN` / `ADDON_LOADED Blizzard_Settings`).

- [x] **Options.lua** — убрана жесткая зависимость от deprecated-шаблона чекбокса.
  - **Fix**: `CreateOptionCheckButton()` переведен на `UICheckButtonTemplate` (без deprecated template), label/tooltip рендерятся напрямую.

- [x] **Core.lua** — slash handler потенциально падал при `nil`-сообщении.
  - **Fix**: `msg:lower()` заменен на `(msg or ""):lower()`.

- [x] **Core.lua** — путь `DK-BloodUnholy-Rune-CDSpark` приведен к единому регистру (`PLAYERFRAME`) для лучшей совместимости с case-sensitive FS.

### ✅ Verified facts (Blizzard source)

- [x] `InterfaceOptionsCheckButtonTemplate` помечен deprecated, но присутствует в build `12.0.1` (`Blizzard_FrameXML/DeprecatedTemplates.xml`).
- [x] `Settings.RegisterCanvasLayoutCategory` принимает `(frame, name)`; `SettingsCategoryMixin:GetID()` возвращает числовой ID категории.

### 🔎 Remaining in-game verification

- [ ] Проверить `/or config` сразу после логина и после `/reload`.
- [ ] Проверить открытие настроек на non-DK персонаже (без Lua errors).
- [ ] Проверить рендер спирали/таймера рун на всех DK-спеках в бою и вне боя.

---

## Code Review (2026-03-02) [Archive]

### 🔴 Bugs / Will Error

- [x] **Options.lua:21,31,41,51,65,70,75** — obsolete после pass 2026-03-03.
  - Зависимость от `InterfaceOptionsCheckButtonTemplate` полностью убрана; используется `UICheckButtonTemplate`.

- [x] **Options.lua:133** — fixed в pass 2026-03-03.
  - Регистрация обёрнута в `RegisterOptionsCategory()` с отложенной повторной попыткой (`PLAYER_LOGIN`/`ADDON_LOADED`).

### 🟡 Потенциальные проблемы

- [x] **Core.lua:731** — fixed в pass 2026-03-03.
  - `/or config` теперь использует сохранённый `category:GetID()` через `OldRunesUI.settingsCategoryID`.

- [x] **Core.lua:40** — fixed в pass 2026-03-03.
  - Путь edge-текстуры приведен к `Interface\\PLAYERFRAME\\DK-BloodUnholy-Rune-CDSpark`.

- [x] **OldRunes.toc:1** — verified on local client.
  - `%WOW_RETAIL%\WTF\Config.wtf` contains `SET lastAddonVersion "120001"`; the current `## Interface` covers that build.

- [x] **Core.lua:5** — оставлено осознанно.
  - Это безопасный bootstrap-паттерн с последующим `EnsureDBDefaults()`; ошибок/потери данных не даёт.

### 🟢 Качество кода / Нитпики

- [x] **Options.lua:4-6** — fixed в pass 2026-03-03.
  - Константы экспортированы через `OldRunesUI.RUNE_STYLE_*` в `Core.lua` и переиспользуются в `Options.lua`.

- [x] **Core.lua:50** — fixed в pass 2026-03-03.
  - Добавлен helper с `pcall` и гарантированным reset `suppressHookRefresh`.

- [x] **Localization.lua** — intentional.
  - `ADDON_NAME` не локализуется намеренно (бренд/идентичность аддона).

- [x] **Core.lua:564-566** — verified/fixed.
  - Рекурсия блокируется `suppressHookRefresh`; флаг защищён `pcall`-guard и всегда сбрасывается.

## Fixed Issues
- [x] Wrong rune access: `_G["RuneButtonIndividual"..i]` → `RuneFrame.Runes[i]`
- [x] SetTexture on Frame → CreateTexture overlay on rune frame
- [x] Removed InterfaceOptions_AddCategory fallback (deprecated)
- [x] Removed duplicate defaults initialization
- [x] Proper Settings API: `Settings.RegisterCanvasLayoutCategory()` + `Settings.RegisterAddOnCategory()`
- [x] Atlas layer hiding when custom texture active
- [x] DepleteVisuals layers hidden when custom texture active

## Open Questions (need verification in-game)
- [ ] Old textures still exist in 12.x client?
  - Path: `Interface\PLAYERFRAME\UI-PlayerFrame-Deathknight-Blood` etc.
  - If not found, will show green/missing texture
  - Fallback: May need alternative textures if Blizzard removed them

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
