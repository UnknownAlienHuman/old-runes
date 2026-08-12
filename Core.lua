-- Old Runes (Retail 12.x)
-- Author: Dakini, Neomorph
-- Replaces Death Knight rune textures based on spec with customizable options

OldRunesDB = OldRunesDB or {}
-- Expose namespace for Options
OldRunesUI = OldRunesUI or {}

local L = OldRunesUI.L or {}

local RUNE_STYLE_SPEC = "SPEC"
local RUNE_STYLE_MIXED = "MIXED"
local RUNE_STYLE_DEATH = "DEATH"
local RUNE_STYLE_SPECLESS = "SPECLESS"
OldRunesUI.RUNE_STYLE_SPEC = OldRunesUI.RUNE_STYLE_SPEC or RUNE_STYLE_SPEC
OldRunesUI.RUNE_STYLE_MIXED = OldRunesUI.RUNE_STYLE_MIXED or RUNE_STYLE_MIXED
OldRunesUI.RUNE_STYLE_DEATH = OldRunesUI.RUNE_STYLE_DEATH or RUNE_STYLE_DEATH
OldRunesUI.RUNE_STYLE_SPECLESS = OldRunesUI.RUNE_STYLE_SPECLESS or RUNE_STYLE_SPECLESS

local defaults = {
    showTimerNumbers = true,
    showCooldownSpiral = true,
    reverseRecoveryOrder = false,
    oldPersonalResourceDisplay = true,
    runeStyle = RUNE_STYLE_SPEC,
}

local VALID_STYLES = {
    [RUNE_STYLE_SPEC] = true,
    [RUNE_STYLE_MIXED] = true,
    [RUNE_STYLE_DEATH] = true,
    [RUNE_STYLE_SPECLESS] = true,
}

local _, playerClass = UnitClass("player")

local RUNE_TEXTURES = {
    BLOOD = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Blood",
    FROST = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Frost",
    UNHOLY = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Unholy",
    DEATH = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Death",
}

local SPEC_TO_RUNE = { [1] = "BLOOD", [2] = "FROST", [3] = "UNHOLY" }

-- Dim overlay when rune is on cooldown (replaces Blizzard's atlas-layer animations which we hide)
local function DimOverlay(rune, overlay)
    if not overlay:IsShown() then return end
    local _, _, runeReady = GetRuneCooldown(rune.runeIndex)
    if runeReady then
        overlay:SetVertexColor(1, 1, 1)
    else
        overlay:SetVertexColor(0.4, 0.4, 0.4)
    end
end

local OldRunes = CreateFrame("Frame")
OldRunes:SetScript("OnEvent", function(self, event, ...)
    if self[event] then self[event](self, ...) end
end)

local trackedRuneFrames = {}
local frameHooks = {}
local runeState = setmetatable({}, { __mode = "k" })
local cooldownState = setmetatable({}, { __mode = "k" })

local ATLAS_LAYERS = {
    "Rune_Grad", "Rune_Lines", "Rune_Active", "Rune_Mid",
    "Rune_Eyes", "Glow", "Glow2", "Smoke",
    "Rune_Inactive", "BG_Active", "BG_Inactive", "BG_Shadow"
}

local DEPLETE_LAYERS = { "Rune_Inactive", "Rune_Lines", "Glow2", "FB_RuneDeplete" }

local function GetOrCreateRuneState(rune)
    local state = runeState[rune]
    if not state then
        state = {}
        runeState[rune] = state
    end
    return state
end

local function GetOrCreateCooldownState(cooldown)
    local state = cooldownState[cooldown]
    if not state then
        state = {}
        cooldownState[cooldown] = state
    end
    return state
end

local function EnsureRuneOverlay(rune)
    if not rune then return nil end

    local state = GetOrCreateRuneState(rune)
    if state.overlay then
        return state.overlay
    end

    -- Avoid creating regions on protected Blizzard unit-frame widgets in combat.
    if InCombatLockdown and InCombatLockdown() then
        return nil
    end

    local overlay = rune:CreateTexture(nil, "ARTWORK")
    overlay:SetAllPoints()
    overlay:Hide()
    state.overlay = overlay
    return overlay
end

local function EnsureDBDefaults()
    OldRunesDB = OldRunesDB or {}

    for key, value in pairs(defaults) do
        if OldRunesDB[key] == nil then
            OldRunesDB[key] = value
        end
    end

    if not VALID_STYLES[OldRunesDB.runeStyle] then
        if OldRunesDB.multicolorRunes then
            OldRunesDB.runeStyle = RUNE_STYLE_MIXED
        else
            OldRunesDB.runeStyle = RUNE_STYLE_SPEC
        end
    end

    OldRunesDB.multicolorRunes = (OldRunesDB.runeStyle == RUNE_STYLE_MIXED)

    -- Kept for backward compatibility with old SavedVariables only.
    -- Reversing managed rune layout taints PlayerFrame container paths in 12.x.
    OldRunesDB.reverseRecoveryOrder = false
end

local function GetRuneStyle()
    local style = OldRunesDB.runeStyle
    if VALID_STYLES[style] then
        return style
    end

    return RUNE_STYLE_SPEC
end

local function SetRuneStyle(style)
    if not VALID_STYLES[style] then return false end

    OldRunesDB.runeStyle = style
    OldRunesDB.multicolorRunes = (style == RUNE_STYLE_MIXED)
    return true
end

local function InitializeDatabaseOnlyMode()
    EnsureDBDefaults()

    OldRunesUI.EnsureDBDefaults = EnsureDBDefaults
    OldRunesUI.GetRuneStyle = function()
        EnsureDBDefaults()
        return GetRuneStyle()
    end
    OldRunesUI.SetRuneStyle = function(style)
        EnsureDBDefaults()
        return SetRuneStyle(style)
    end

    OldRunesUI.UpdateRecoveryOrder = function() end
    OldRunesUI.ApplyRuneTextures = function() end
    OldRunesUI.UpdateTimerVisibility = function() end
    OldRunesUI.UpdateCooldownSpiral = function() end
    OldRunesUI.RefreshAll = function() end
end

if playerClass ~= "DEATHKNIGHT" then
    InitializeDatabaseOnlyMode()
    return
end

local function GetCurrentArtType()
    local specIndex = C_SpecializationInfo.GetSpecialization()
    if not specIndex then return nil end

    return SPEC_TO_RUNE[specIndex]
end

local function IsPersonalResourceFrame(frame)
    if not frame then return false end
    if frame == RuneFrame then return false end

    local prdFrame = PersonalResourceDisplayFrame
    if prdFrame and frame == prdFrame.classFrame then
        return true
    end

    local frameName = frame.GetName and frame:GetName() or nil
    if frameName == "prdClassFrame" or frameName == "DeathKnightResourceOverlayFrame" then
        return true
    end

    if prdFrame and prdFrame.ClassFrameContainer and frame.GetParent then
        if frame:GetParent() == prdFrame.ClassFrameContainer then
            return true
        end
    end

    return false
end

local function IsFrameEnabled(frameData)
    if not frameData then return false end

    if frameData.isPersonal then
        return OldRunesDB.oldPersonalResourceDisplay ~= false
    end

    return true
end

local function GetRuneFrameCandidates()
    local frames = {}
    local seen = {}

    local function AddFrame(frame)
        if frame and frame.Runes and not seen[frame] then
            seen[frame] = true
            frames[#frames + 1] = frame
        end
    end

    AddFrame(RuneFrame)
    AddFrame(DeathKnightResourceOverlayFrame)
    AddFrame(prdClassFrame)

    local prdFrame = PersonalResourceDisplayFrame
    if prdFrame then
        -- 12.0.7 creates the PRD class frame as a nameless self.classFrame.
        AddFrame(prdFrame.classFrame)

        local container = prdFrame.ClassFrameContainer
        if container and container.GetChildren and container.GetNumChildren then
            for i = 1, container:GetNumChildren() do
                AddFrame(select(i, container:GetChildren()))
            end
        end
    end

    return frames
end

local function InitializeRuneFrame(frame)
    if not frame or trackedRuneFrames[frame] then return end
    if not frame.Runes then return end

    local frameData = {
        frame = frame,
        isPersonal = IsPersonalResourceFrame(frame),
        runes = {},
        overlays = {},
    }

    for i = 1, #frame.Runes do
        local rune = frame.Runes[i]
        if rune then
            frameData.runes[i] = rune
            frameData.overlays[i] = EnsureRuneOverlay(rune)
        end
    end

    trackedRuneFrames[frame] = frameData
end

local function InitializeRuneFrames()
    local frames = GetRuneFrameCandidates()
    for _, frame in ipairs(frames) do
        InitializeRuneFrame(frame)
    end
end

local function HideAtlasLayers(rune, hide)
    if not rune then return end
    local state = GetOrCreateRuneState(rune)
    if state.atlasHidden == hide then return end

    for _, layerName in ipairs(ATLAS_LAYERS) do
        local layer = rune[layerName]
        if layer then
            if hide then
                layer:Hide()
            else
                layer:Show()
            end
        end
    end

    if rune.DepleteVisuals then
        for _, layerName in ipairs(DEPLETE_LAYERS) do
            local layer = rune.DepleteVisuals[layerName]
            if layer then
                if hide then
                    layer:Hide()
                else
                    layer:Show()
                end
            end
        end
    end

    state.atlasHidden = hide
end

local function GetMixedTextureByLayout(rune, fallbackIndex)
    local visualIndex = fallbackIndex
    if rune and type(rune.layoutIndex) == "number" and rune.layoutIndex > 0 then
        visualIndex = rune.layoutIndex
    end

    if visualIndex <= 2 then
        return RUNE_TEXTURES.BLOOD
    elseif visualIndex <= 4 then
        return RUNE_TEXTURES.FROST
    end

    return RUNE_TEXTURES.UNHOLY
end

local function GetTextureForRune(rune, fallbackIndex, artType, style)
    style = style or GetRuneStyle()

    if style == RUNE_STYLE_MIXED then
        return GetMixedTextureByLayout(rune, fallbackIndex)
    end

    if style == RUNE_STYLE_DEATH then
        return RUNE_TEXTURES.DEATH
    end

    if style == RUNE_STYLE_SPECLESS then
        return nil
    end

    if artType then
        return RUNE_TEXTURES[artType]
    end

    return nil
end

local function EnsureBlizzardRuneArt(rune, style, specIndex)
    if not rune or type(rune.UpdateSpec) ~= "function" then
        return
    end

    local state = GetOrCreateRuneState(rune)
    local desiredArtToken = nil

    if style == RUNE_STYLE_SPECLESS then
        desiredArtToken = "DEFAULT"
    elseif style == RUNE_STYLE_SPEC then
        desiredArtToken = specIndex or "DEFAULT"
    end

    if state.artToken == desiredArtToken then
        return
    end

    if desiredArtToken == "DEFAULT" then
        rune:UpdateSpec(nil)
    elseif type(desiredArtToken) == "number" then
        rune:UpdateSpec(desiredArtToken)
    end

    state.artToken = desiredArtToken
end

local function RestoreDefaultFrameVisuals(frameData)
    if not frameData then return end

    local specIndex = C_SpecializationInfo.GetSpecialization()

    for i = 1, #frameData.runes do
        local rune = frameData.runes[i]
        local overlay = frameData.overlays[i]
        if rune then
            HideAtlasLayers(rune, false)
            if rune.UpdateSpec then
                rune:UpdateSpec(specIndex)
            end
        end

        if overlay then
            if overlay:IsShown() then
                overlay:Hide()
            end
        end

        if rune then
            local state = GetOrCreateRuneState(rune)
            state.texturePath = nil
            state.artToken = specIndex or "DEFAULT"
        end
    end
end

-- Export function so Options.lua can use it
function OldRunesUI.UpdateRecoveryOrder(targetFrame)
    EnsureDBDefaults()
    if targetFrame then
        InitializeRuneFrame(targetFrame)
        return
    end

    InitializeRuneFrames()
end

-- Export function so Options.lua can use it
function OldRunesUI.ApplyRuneTextures(artType, targetFrame)
    EnsureDBDefaults()
    InitializeRuneFrames()
    local style = GetRuneStyle()
    local specIndex = C_SpecializationInfo.GetSpecialization()

    local function ApplyForFrame(frameData)
        if not frameData then return end

        if not IsFrameEnabled(frameData) then
            RestoreDefaultFrameVisuals(frameData)
            return
        end

        for i = 1, #frameData.runes do
            local rune = frameData.runes[i]
            local overlay = frameData.overlays[i]
            if rune and not overlay then
                overlay = EnsureRuneOverlay(rune)
                frameData.overlays[i] = overlay
            end
            if rune then
                EnsureBlizzardRuneArt(rune, style, specIndex)
                local texturePath = GetTextureForRune(rune, i, artType, style)
                local state = GetOrCreateRuneState(rune)

                if texturePath and overlay then
                    HideAtlasLayers(rune, true)

                    if state.texturePath ~= texturePath then
                        overlay:SetTexture(texturePath)
                        state.texturePath = texturePath
                    end

                    if not overlay:IsShown() then
                        overlay:Show()
                    end

                    DimOverlay(rune, overlay)
                else
                    HideAtlasLayers(rune, false)
                    if overlay and overlay:IsShown() then
                        overlay:Hide()
                    end
                    state.texturePath = nil
                end
            end
        end
    end

    if targetFrame then
        InitializeRuneFrame(targetFrame)
        ApplyForFrame(trackedRuneFrames[targetFrame])
        return
    end

    for _, frameData in pairs(trackedRuneFrames) do
        ApplyForFrame(frameData)
    end
end

-- Export function so Options.lua can use it
function OldRunesUI.UpdateTimerVisibility()
    EnsureDBDefaults()
    InitializeRuneFrames()

    for _, frameData in pairs(trackedRuneFrames) do
        local hideNumbers = not OldRunesDB.showTimerNumbers

        if not IsFrameEnabled(frameData) and frameData.isPersonal then
            hideNumbers = true
        end

        for i = 1, #frameData.runes do
            local rune = frameData.runes[i]
            local cooldown = rune and rune.Cooldown
            if cooldown then
                local state = GetOrCreateCooldownState(cooldown)
                if state.hideNumbers ~= hideNumbers then
                    cooldown:SetHideCountdownNumbers(hideNumbers)
                    state.hideNumbers = hideNumbers
                end
            end
        end
    end
end

-- Export function so Options.lua can use it
function OldRunesUI.UpdateCooldownSpiral()
    EnsureDBDefaults()
    InitializeRuneFrames()

    local showSpiral = OldRunesDB.showCooldownSpiral ~= false

    for _, frameData in pairs(trackedRuneFrames) do
        if not IsFrameEnabled(frameData) then
            if frameData.isPersonal then
                RestoreDefaultFrameVisuals(frameData)
            end
        else
            for i = 1, #frameData.runes do
                local rune = frameData.runes[i]
                local cooldown = rune and rune.Cooldown
                if cooldown then
                    local state = GetOrCreateCooldownState(cooldown)
                    if state.drawSwipe ~= showSpiral then
                        cooldown:SetDrawSwipe(showSpiral)
                        state.drawSwipe = showSpiral
                    end
                    if state.drawEdge ~= showSpiral then
                        cooldown:SetDrawEdge(showSpiral)
                        state.drawEdge = showSpiral
                    end
                end
            end
        end
    end
end

function OldRunesUI.GetRuneStyle()
    EnsureDBDefaults()
    return GetRuneStyle()
end

function OldRunesUI.SetRuneStyle(style)
    EnsureDBDefaults()
    return SetRuneStyle(style)
end

function OldRunesUI.EnsureDBDefaults()
    EnsureDBDefaults()
end

local function HookRuneFrame(frame)
    if not frame or frameHooks[frame] then return end
    if type(frame.UpdateRunes) ~= "function" then return end

    hooksecurefunc(frame, "UpdateRunes", function(updatedFrame)
        EnsureDBDefaults()
        OldRunesUI.UpdateRecoveryOrder(updatedFrame)

        local artType = GetCurrentArtType()
        OldRunesUI.ApplyRuneTextures(artType, updatedFrame)

        -- Dim/brighten overlays based on cooldown state
        local fd = trackedRuneFrames[updatedFrame]
        if fd and IsFrameEnabled(fd) then
            for i = 1, #fd.runes do
                local rune = fd.runes[i]
                local overlay = fd.overlays[i]
                if rune and overlay then
                    DimOverlay(rune, overlay)
                end
            end
        end
    end)

    frameHooks[frame] = true
end

local function HookRuneFrames()
    for frame in pairs(trackedRuneFrames) do
        HookRuneFrame(frame)
    end
end

local RefreshRuneVisuals

local function QueuePersonalResourceRefresh()
    C_Timer.After(0, function()
        RefreshRuneVisuals(true)
    end)
end

local function HookPersonalResourceDisplay()
    if OldRunes.personalResourceHooked then return end
    if not PersonalResourceDisplayFrame then return end

    if PersonalResourceDisplayFrame.SetupClassBar then
        hooksecurefunc(PersonalResourceDisplayFrame, "SetupClassBar", QueuePersonalResourceRefresh)
    end

    if PersonalResourceDisplayFrame.SetHideClassInfo then
        hooksecurefunc(PersonalResourceDisplayFrame, "SetHideClassInfo", QueuePersonalResourceRefresh)
    end

    OldRunes.personalResourceHooked = true
end

RefreshRuneVisuals = function(forceRuneUpdate)
    EnsureDBDefaults()
    HookPersonalResourceDisplay()
    InitializeRuneFrames()
    HookRuneFrames()

    OldRunesUI.UpdateRecoveryOrder()

    local artType = GetCurrentArtType()
    OldRunesUI.ApplyRuneTextures(artType)
    OldRunesUI.UpdateTimerVisibility()
    OldRunesUI.UpdateCooldownSpiral()
end

function OldRunesUI.RefreshAll()
    RefreshRuneVisuals(true)
end

local addonLoadedPending = {
    ["OldRunes"] = true,
    ["Blizzard_NamePlates"] = true,
    ["Blizzard_PersonalResourceDisplay"] = true,
}

function OldRunes:ADDON_LOADED(loadedAddon)
    if not addonLoadedPending[loadedAddon] then return end
    addonLoadedPending[loadedAddon] = nil

    if loadedAddon == "OldRunes" then
        EnsureDBDefaults()
    else
        C_Timer.After(0, function()
            RefreshRuneVisuals(true)
        end)
    end

    if not next(addonLoadedPending) then
        OldRunes:UnregisterEvent("ADDON_LOADED")
    end
end

function OldRunes:PLAYER_LOGIN()
    C_Timer.After(0.5, function()
        RefreshRuneVisuals(true)
    end)
    OldRunes:UnregisterEvent("PLAYER_LOGIN")
end

function OldRunes:PLAYER_ENTERING_WORLD()
    RefreshRuneVisuals(true)
end

function OldRunes:PLAYER_SPECIALIZATION_CHANGED(unit)
    if unit ~= "player" then return end

    RefreshRuneVisuals(true)
end

function OldRunes:PLAYER_REGEN_ENABLED()
    RefreshRuneVisuals(true)
end

OldRunes:RegisterEvent("ADDON_LOADED")
OldRunes:RegisterEvent("PLAYER_LOGIN")
OldRunes:RegisterEvent("PLAYER_ENTERING_WORLD")
OldRunes:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
OldRunes:RegisterEvent("PLAYER_REGEN_ENABLED")

SLASH_OLDRUNES1 = "/or"
SLASH_OLDRUNES2 = "/oldrunes"

local function GetAddonPrefix()
    return "|cC41F3BFF" .. (L.ADDON_NAME or "Old Runes") .. "|r"
end

local function GetStateText(isEnabled)
    if isEnabled then
        return "|cff00ff00" .. (L.STATE_ON or "ON") .. "|r"
    end

    return "|cffff0000" .. (L.STATE_OFF or "OFF") .. "|r"
end

local function PrintToggleStatus(label, isEnabled)
    print(("%s: %s %s"):format(GetAddonPrefix(), label, GetStateText(isEnabled)))
end

local function GetLocalizedStyleName(style)
    if style == RUNE_STYLE_SPEC then
        return L.STYLE_NAME_SPEC or "Spec"
    elseif style == RUNE_STYLE_MIXED then
        return L.STYLE_NAME_MIXED or "Mixed"
    elseif style == RUNE_STYLE_DEATH then
        return L.STYLE_NAME_DEATH or "Death"
    elseif style == RUNE_STYLE_SPECLESS then
        return L.STYLE_NAME_SPECLESS or "Specless"
    end

    return tostring(style)
end

local function PrintStyleSet(style)
    print(("%s: " .. (L.MSG_STYLE_SET or "Style set to %s")):format(GetAddonPrefix(), GetLocalizedStyleName(style)))
end

SlashCmdList["OLDRUNES"] = function(msg)
    EnsureDBDefaults()

    local trimmed = (msg or ""):lower():gsub("^%s*(.-)%s*$", "%1")
    local cmd, arg = trimmed:match("^(%S+)%s*(.-)$")

    if not cmd or cmd == "" or cmd == "help" then
        print(("%s: %s"):format(GetAddonPrefix(), L.CMD_HELP_TITLE or "Commands:"))
        print("  |cC41F3BFF/or timer|r - " .. (L.CMD_DESC_TIMER or "Toggle timer numbers"))
        print("  |cC41F3BFF/or spiral|r - " .. (L.CMD_DESC_SPIRAL or "Toggle cooldown spiral"))
        print("  |cC41F3BFF/or reverse|r - " .. (L.CMD_DESC_REVERSE or "Toggle reverse recovery order"))
        print("  |cC41F3BFF/or prd|r - " .. (L.CMD_DESC_PRD or "Toggle old personal resource display"))
        print("  |cC41F3BFF/or style spec|r - " .. (L.CMD_DESC_STYLE_SPEC or "Spec-based rune style"))
        print("  |cC41F3BFF/or style mixed|r - " .. (L.CMD_DESC_STYLE_MIXED or "Mixed rune style"))
        print("  |cC41F3BFF/or style death|r - " .. (L.CMD_DESC_STYLE_DEATH or "Death rune style"))
        print("  |cC41F3BFF/or style specless|r - " .. (L.CMD_DESC_STYLE_SPECLESS or "Blizzard specless (gray) rune style"))
        print("  |cC41F3BFF/or multicolor|r - " .. (L.CMD_DESC_MULTICOLOR or "Legacy alias for mixed style toggle"))
        print("  |cC41F3BFF/or config|r - " .. (L.CMD_DESC_CONFIG or "Open settings"))
    elseif cmd == "timer" then
        OldRunesDB.showTimerNumbers = not OldRunesDB.showTimerNumbers
        PrintToggleStatus(L.MSG_TIMER or "Timer", OldRunesDB.showTimerNumbers)
        OldRunesUI.UpdateTimerVisibility()
    elseif cmd == "spiral" then
        OldRunesDB.showCooldownSpiral = not OldRunesDB.showCooldownSpiral
        PrintToggleStatus(L.MSG_COOLDOWN_SPIRAL or "Cooldown spiral", OldRunesDB.showCooldownSpiral)
        OldRunesUI.UpdateCooldownSpiral()
    elseif cmd == "reverse" then
        OldRunesDB.reverseRecoveryOrder = false
        print(("%s: %s"):format(
            GetAddonPrefix(),
            L.MSG_REVERSE_DISABLED or "Reverse recovery is disabled in taint-safe mode for 12.x."
        ))
    elseif cmd == "prd" or cmd == "personal" then
        OldRunesDB.oldPersonalResourceDisplay = not OldRunesDB.oldPersonalResourceDisplay
        PrintToggleStatus(L.MSG_OLD_PRD or "Old personal resource display", OldRunesDB.oldPersonalResourceDisplay)
        RefreshRuneVisuals(true)
    elseif cmd == "style" then
        local normalized = arg and arg:upper() or ""
        local styleMap = {
            SPEC = RUNE_STYLE_SPEC,
            MIXED = RUNE_STYLE_MIXED,
            DEATH = RUNE_STYLE_DEATH,
            SPECLESS = RUNE_STYLE_SPECLESS,
            GRAY = RUNE_STYLE_SPECLESS,
            GREY = RUNE_STYLE_SPECLESS,
        }

        local style = styleMap[normalized]
        if not style then
            print(("%s: %s"):format(GetAddonPrefix(), L.MSG_STYLE_USAGE or "Usage /or style spec|mixed|death|specless"))
            return
        end

        SetRuneStyle(style)
        PrintStyleSet(style)

        local artType = GetCurrentArtType()
        OldRunesUI.ApplyRuneTextures(artType)
    elseif cmd == "multicolor" then
        if GetRuneStyle() == RUNE_STYLE_MIXED then
            SetRuneStyle(RUNE_STYLE_SPEC)
            PrintStyleSet(RUNE_STYLE_SPEC)
        else
            SetRuneStyle(RUNE_STYLE_MIXED)
            PrintStyleSet(RUNE_STYLE_MIXED)
        end

        local artType = GetCurrentArtType()
        OldRunesUI.ApplyRuneTextures(artType)
    elseif cmd == "config" then
        if Settings and Settings.OpenToCategory then
            local categoryID = OldRunesUI.settingsCategoryID
            if not categoryID and OldRunesUI.settingsCategory and OldRunesUI.settingsCategory.GetID then
                categoryID = OldRunesUI.settingsCategory:GetID()
            end

            if categoryID then
                Settings.OpenToCategory(categoryID)
            else
                print(("%s: %s"):format(GetAddonPrefix(),
                    L.MSG_SETTINGS_NOT_READY or "Settings not registered yet. Reload UI."))
            end
        end
    end
end
