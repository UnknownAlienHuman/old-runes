-- Old Runes Settings panel

local _, playerClass = UnitClass("player")
if playerClass ~= "DEATHKNIGHT" then
    return
end

local API = OldRunesUI
if not API then
    return
end
local L = API.L or {}

local panel = CreateFrame("Frame")
panel.name = L.ADDON_NAME or "Old Runes"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(L.ADDON_NAME or "Old Runes")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
subtitle:SetJustifyH("LEFT")
subtitle:SetText(L.OPT_SUBTITLE or "Classic Death Knight rune art.")

local function AttachTooltip(control, text)
    if not text or text == "" then
        return
    end

    control:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    control:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateCheckbox(anchor, yOffset, label, tooltip, onClick)
    local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset)
    checkbox.Text:SetText(label)
    checkbox:SetScript("OnClick", function(self)
        onClick(self:GetChecked() == true)
    end)
    AttachTooltip(checkbox, tooltip)
    return checkbox
end

local timerCheckbox = CreateCheckbox(
    subtitle,
    -18,
    L.OPT_TIMER_LABEL or "Show cooldown timer numbers",
    L.OPT_TIMER_TT,
    function(checked)
        API.EnsureDBDefaults()
        OldRunesDB.showTimerNumbers = checked
        API.RefreshAll()
    end
)

local spiralCheckbox = CreateCheckbox(
    timerCheckbox,
    -8,
    L.OPT_SPIRAL_LABEL or "Show cooldown spiral",
    L.OPT_SPIRAL_TT,
    function(checked)
        API.EnsureDBDefaults()
        OldRunesDB.showCooldownSpiral = checked
        API.RefreshAll()
    end
)

local prdCheckbox = CreateCheckbox(
    spiralCheckbox,
    -8,
    L.OPT_PRD_LABEL or "Style the Personal Resource Display",
    L.OPT_PRD_TT,
    function(checked)
        API.EnsureDBDefaults()
        OldRunesDB.oldPersonalResourceDisplay = checked
        API.RefreshAll()
    end
)

local styleTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
styleTitle:SetPoint("TOPLEFT", prdCheckbox, "BOTTOMLEFT", 4, -18)
styleTitle:SetText(L.OPT_STYLE_LABEL or "Rune style")

local styleButtons = {}

local function RefreshStyleButtons()
    local selected = API.GetRuneStyle()
    for style, button in pairs(styleButtons) do
        button:SetChecked(style == selected)
    end
end

local function CreateStyleCheckbox(anchor, label, tooltip, style)
    local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
    checkbox.Text:SetText(label)
    checkbox:SetScript("OnClick", function()
        API.SetRuneStyle(style)
        RefreshStyleButtons()
        API.RefreshAll()
    end)
    AttachTooltip(checkbox, tooltip)
    styleButtons[style] = checkbox
    return checkbox
end

local specCheckbox = CreateStyleCheckbox(
    styleTitle,
    L.OPT_STYLE_SPEC_LABEL or "Spec (Blood/Frost/Unholy)",
    L.OPT_STYLE_SPEC_TT,
    API.RUNE_STYLE_SPEC
)

local mixedCheckbox = CreateStyleCheckbox(
    specCheckbox,
    L.OPT_STYLE_MIXED_LABEL or "Mixed (Blood, Frost, Unholy)",
    L.OPT_STYLE_MIXED_TT,
    API.RUNE_STYLE_MIXED
)

local deathCheckbox = CreateStyleCheckbox(
    mixedCheckbox,
    L.OPT_STYLE_DEATH_LABEL or "Death",
    L.OPT_STYLE_DEATH_TT,
    API.RUNE_STYLE_DEATH
)

CreateStyleCheckbox(
    deathCheckbox,
    L.OPT_STYLE_SPECLESS_LABEL or "Specless (Blizzard gray)",
    L.OPT_STYLE_SPECLESS_TT,
    API.RUNE_STYLE_SPECLESS
)

local function RefreshControls()
    API.EnsureDBDefaults()
    timerCheckbox:SetChecked(OldRunesDB.showTimerNumbers)
    spiralCheckbox:SetChecked(OldRunesDB.showCooldownSpiral)
    prdCheckbox:SetChecked(OldRunesDB.oldPersonalResourceDisplay)
    RefreshStyleButtons()
end

panel:SetScript("OnShow", RefreshControls)
API.optionsPanel = panel

local function RegisterSettings()
    if API.settingsCategory then
        return true
    end

    if not Settings or not Settings.RegisterCanvasLayoutCategory
        or not Settings.RegisterAddOnCategory then
        return false
    end

    local category = Settings.RegisterCanvasLayoutCategory(
        panel,
        L.ADDON_NAME or "Old Runes"
    )
    if not category then
        return false
    end

    Settings.RegisterAddOnCategory(category)
    API.settingsCategory = category
    if category.GetID then
        API.settingsCategoryID = category:GetID()
    end
    return true
end

if not RegisterSettings() then
    local registrationFrame = CreateFrame("Frame")
    registrationFrame:RegisterEvent("PLAYER_LOGIN")
    registrationFrame:RegisterEvent("ADDON_LOADED")
    registrationFrame:SetScript("OnEvent", function(self, event, loadedAddon)
        if event == "ADDON_LOADED" and loadedAddon ~= "Blizzard_Settings" then
            return
        end

        if RegisterSettings() then
            self:UnregisterAllEvents()
        end
    end)
end
