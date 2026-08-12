-- Old Runes - Options panel
-- Author: Neomorph

OldRunesUI = OldRunesUI or {}
local L = (OldRunesUI and OldRunesUI.L) or {}
local RUNE_STYLE_SPEC = OldRunesUI.RUNE_STYLE_SPEC or "SPEC"
local RUNE_STYLE_MIXED = OldRunesUI.RUNE_STYLE_MIXED or "MIXED"
local RUNE_STYLE_DEATH = OldRunesUI.RUNE_STYLE_DEATH or "DEATH"
local RUNE_STYLE_SPECLESS = OldRunesUI.RUNE_STYLE_SPECLESS or "SPECLESS"

local panel = CreateFrame("Frame", "OldRunesOptionsPanel", UIParent)
panel.name = L.ADDON_NAME or "Old Runes"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(L.ADDON_NAME or "Old Runes")

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
subtitle:SetText(L.OPT_SUBTITLE or "Customize Death Knight rune appearance (classic design)")

local function PrintAddonMessage(message)
    local prefix = "|cC41F3BFF" .. (L.ADDON_NAME or "Old Runes") .. "|r"
    print(("%s: %s"):format(prefix, message))
end

local function CreateOptionCheckButton(parent, point, relativeTo, relativePoint, xOffset, yOffset, labelText, tooltipText)
    local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    button:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    button.tooltipText = tooltipText

    if button.Text then
        button.Text:SetText(labelText)
    else
        local label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", button, "RIGHT", 0, 1)
        label:SetText(labelText)
        button.OldRunesLabel = label
    end

    button:HookScript("OnEnter", function(self)
        if not self.tooltipText then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipText, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function()
        GameTooltip_Hide()
    end)

    return button
end

local timerCB = CreateOptionCheckButton(
    panel, "TOPLEFT", subtitle, "BOTTOMLEFT", 0, -14,
    L.OPT_TIMER_LABEL or "Show cooldown timer numbers",
    L.OPT_TIMER_TT or "Display countdown numbers on rune cooldowns"
)

timerCB:SetScript("OnClick", function(self)
    OldRunesDB.showTimerNumbers = self:GetChecked()
    OldRunesUI.RefreshAll()
end)

local spiralCB = CreateOptionCheckButton(
    panel, "TOPLEFT", timerCB, "BOTTOMLEFT", 0, -10,
    L.OPT_SPIRAL_LABEL or "Show cooldown spiral",
    L.OPT_SPIRAL_TT or "Use the standard cooldown spiral for rune recovery"
)

spiralCB:SetScript("OnClick", function(self)
    OldRunesDB.showCooldownSpiral = self:GetChecked()
    OldRunesUI.RefreshAll()
end)

local reverseCB = CreateOptionCheckButton(
    panel, "TOPLEFT", spiralCB, "BOTTOMLEFT", 0, -10,
    L.OPT_REVERSE_LABEL or "Reverse rune recovery order",
    L.OPT_REVERSE_TT or "Reverses visual recovery direction (right to left)"
)

reverseCB:SetScript("OnClick", function(self)
    local triedEnable = self:GetChecked()
    OldRunesDB.reverseRecoveryOrder = false
    self:SetChecked(false)
    if triedEnable then
        PrintAddonMessage(L.MSG_REVERSE_DISABLED or "Reverse recovery is disabled in taint-safe mode for 12.x.")
    end
    OldRunesUI.RefreshAll()
end)

local personalCB = CreateOptionCheckButton(
    panel, "TOPLEFT", reverseCB, "BOTTOMLEFT", 0, -10,
    L.OPT_PRD_LABEL or "Old Personal Resource Display",
    L.OPT_PRD_TT or "Apply Old Runes styling to the personal resource display (prdClassFrame)"
)

personalCB:SetScript("OnClick", function(self)
    OldRunesDB.oldPersonalResourceDisplay = self:GetChecked()
    OldRunesUI.RefreshAll()
end)

local styleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
styleLabel:SetPoint("TOPLEFT", personalCB, "BOTTOMLEFT", 0, -16)
styleLabel:SetText(L.OPT_STYLE_LABEL or "Rune style")

local styleSpecCB = CreateOptionCheckButton(
    panel, "TOPLEFT", styleLabel, "BOTTOMLEFT", 0, -8,
    L.OPT_STYLE_SPEC_LABEL or "Spec (Blood/Frost/Unholy)",
    L.OPT_STYLE_SPEC_TT or "Rune color follows your current specialization"
)

local styleMixedCB = CreateOptionCheckButton(
    panel, "TOPLEFT", styleSpecCB, "BOTTOMLEFT", 0, -8,
    L.OPT_STYLE_MIXED_LABEL or "Mixed (Blood, Frost, Unholy)",
    L.OPT_STYLE_MIXED_TT or "Always shows classic mixed set by slot order"
)

local styleDeathCB = CreateOptionCheckButton(
    panel, "TOPLEFT", styleMixedCB, "BOTTOMLEFT", 0, -8,
    L.OPT_STYLE_DEATH_LABEL or "Death (all runes as Death)",
    L.OPT_STYLE_DEATH_TT or "Uses Death rune style for all rune slots"
)

local styleSpeclessCB = CreateOptionCheckButton(
    panel, "TOPLEFT", styleDeathCB, "BOTTOMLEFT", 0, -8,
    L.OPT_STYLE_SPECLESS_LABEL or "Specless (Blizzard gray atlas)",
    L.OPT_STYLE_SPECLESS_TT or "Uses Blizzard's gray pre-specialization rune atlas"
)

local function UpdateStyleCheckboxes()
    local style = OldRunesDB.runeStyle

    styleSpecCB:SetChecked(style == RUNE_STYLE_SPEC)
    styleMixedCB:SetChecked(style == RUNE_STYLE_MIXED)
    styleDeathCB:SetChecked(style == RUNE_STYLE_DEATH)
    styleSpeclessCB:SetChecked(style == RUNE_STYLE_SPECLESS)
end

styleSpecCB:SetScript("OnClick", function(self)
    if OldRunesUI.GetRuneStyle() == RUNE_STYLE_SPEC then
        self:SetChecked(true)
        return
    end
    OldRunesUI.SetRuneStyle(RUNE_STYLE_SPEC)
    UpdateStyleCheckboxes()
    OldRunesUI.RefreshAll()
end)

styleMixedCB:SetScript("OnClick", function(self)
    if OldRunesUI.GetRuneStyle() == RUNE_STYLE_MIXED then
        self:SetChecked(true)
        return
    end
    OldRunesUI.SetRuneStyle(RUNE_STYLE_MIXED)
    UpdateStyleCheckboxes()
    OldRunesUI.RefreshAll()
end)

styleDeathCB:SetScript("OnClick", function(self)
    if OldRunesUI.GetRuneStyle() == RUNE_STYLE_DEATH then
        self:SetChecked(true)
        return
    end
    OldRunesUI.SetRuneStyle(RUNE_STYLE_DEATH)
    UpdateStyleCheckboxes()
    OldRunesUI.RefreshAll()
end)

styleSpeclessCB:SetScript("OnClick", function(self)
    if OldRunesUI.GetRuneStyle() == RUNE_STYLE_SPECLESS then
        self:SetChecked(true)
        return
    end
    OldRunesUI.SetRuneStyle(RUNE_STYLE_SPECLESS)
    UpdateStyleCheckboxes()
    OldRunesUI.RefreshAll()
end)

local function UpdateCheckboxes()
    OldRunesUI.EnsureDBDefaults()

    timerCB:SetChecked(OldRunesDB.showTimerNumbers)
    spiralCB:SetChecked(OldRunesDB.showCooldownSpiral)
    reverseCB:SetChecked(false)
    personalCB:SetChecked(OldRunesDB.oldPersonalResourceDisplay)
    UpdateStyleCheckboxes()
end

panel:SetScript("OnShow", UpdateCheckboxes)

local function RegisterOptionsCategory()
    if OldRunesUI.settingsCategoryID then
        return true
    end

    if not Settings or not Settings.RegisterCanvasLayoutCategory or not Settings.RegisterAddOnCategory then
        return false
    end

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    if not category then
        return false
    end

    Settings.RegisterAddOnCategory(category)

    OldRunesUI.settingsCategory = category
    if category.GetID then
        OldRunesUI.settingsCategoryID = category:GetID()
    end

    return OldRunesUI.settingsCategoryID ~= nil
end

if not RegisterOptionsCategory() then
    local registrar = CreateFrame("Frame")
    registrar:RegisterEvent("PLAYER_LOGIN")
    registrar:RegisterEvent("ADDON_LOADED")
    registrar:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName ~= "Blizzard_Settings" and addonName ~= "OldRunes" then
            return
        end

        if RegisterOptionsCategory() then
            self:UnregisterAllEvents()
        end
    end)
end
