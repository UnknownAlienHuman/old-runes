-- Old Runes (Retail 12.1)
-- Author: Dakini, Neomorph
-- Restores classic Death Knight rune textures with taint-safe presentation hooks.

OldRunesDB = OldRunesDB or {}
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

local RUNE_TEXTURES = {
    BLOOD = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Blood",
    FROST = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Frost",
    UNHOLY = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Unholy",
    DEATH = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Death",
}

local SPEC_TO_RUNE = {
    [1] = "BLOOD",
    [2] = "FROST",
    [3] = "UNHOLY",
}

local ATLAS_LAYERS = {
    "Rune_Grad", "Rune_Lines", "Rune_Active", "Rune_Mid",
    "Rune_Eyes", "Glow", "Glow2", "Smoke",
    "Rune_Inactive", "BG_Active", "BG_Inactive", "BG_Shadow",
}

local DEPLETE_LAYERS = {
    "Rune_Inactive", "Rune_Lines", "Glow2", "FB_RuneDeplete",
}

local _, playerClass = UnitClass("player")

local OldRunes = CreateFrame("Frame")
OldRunes:SetScript("OnEvent", function(self, event, ...)
    local handler = self[event]
    if handler then
        handler(self, ...)
    end
end)

-- Blizzard can recreate the PRD class frame. Weak keys prevent stale frames from
-- being retained for the rest of the session.
local trackedRuneFrames = setmetatable({}, { __mode = "k" })
local frameHooks = setmetatable({}, { __mode = "k" })
local prdHooks = setmetatable({}, { __mode = "k" })
local runeState = setmetatable({}, { __mode = "k" })
local cooldownState = setmetatable({}, { __mode = "k" })

local pendingCombatRefresh = false
local refreshGeneration = 0
local RefreshRuneVisuals
local QueueRefreshBurst

local function IsInCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function IsObjectAccessible(object)
    if not object then
        return false
    end

    if type(object.IsForbidden) == "function" and object:IsForbidden() then
        return false
    end

    if type(object.HasAccessConstraints) == "function" and object:HasAccessConstraints() then
        return type(object.CanBeAccessedInContext) == "function"
            and object:CanBeAccessedInContext()
    end

    return true
end

local function MarkCombatRefresh()
    pendingCombatRefresh = true
end

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

local function EnsureDBDefaults()
    OldRunesDB = OldRunesDB or {}

    -- Capture the legacy flag before the default runeStyle is inserted. Older
    -- SavedVariables stored only multicolorRunes, so checking after defaults
    -- would silently migrate those users to SPEC instead of MIXED.
    local migrateLegacyMixed = not VALID_STYLES[OldRunesDB.runeStyle]
        and OldRunesDB.multicolorRunes == true

    for key, value in pairs(defaults) do
        if OldRunesDB[key] == nil then
            OldRunesDB[key] = value
        end
    end

    if migrateLegacyMixed then
        OldRunesDB.runeStyle = RUNE_STYLE_MIXED
    elseif not VALID_STYLES[OldRunesDB.runeStyle] then
        OldRunesDB.runeStyle = RUNE_STYLE_SPEC
    end

    -- Keep the legacy flag synchronized for users upgrading from old releases.
    OldRunesDB.multicolorRunes = (OldRunesDB.runeStyle == RUNE_STYLE_MIXED)

    -- Manual rune layout mutation taints the managed PlayerFrame path in Retail.
    -- The saved option remains only so old SavedVariables migrate cleanly.
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
    if not VALID_STYLES[style] then
        return false
    end

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
    if not specIndex then
        return nil
    end
    return SPEC_TO_RUNE[specIndex]
end

local function IsPersonalResourceFrame(frame)
    local prdFrame = PersonalResourceDisplayFrame
    return prdFrame ~= nil and frame == prdFrame.classFrame
end

local function IsFrameEnabled(frameData)
    if not frameData then
        return false
    end

    if frameData.isPersonal then
        return OldRunesDB.oldPersonalResourceDisplay ~= false
    end

    return true
end

local function EnsureRuneOverlay(rune)
    if not IsObjectAccessible(rune) then
        return nil
    end

    local state = GetOrCreateRuneState(rune)
    if state.overlay then
        return state.overlay
    end

    -- Region creation on Blizzard-managed unit-frame widgets is deferred until
    -- combat ends. Existing addon-owned textures may still be updated in combat.
    if IsInCombat() then
        MarkCombatRefresh()
        return nil
    end

    local overlay = rune:CreateTexture(nil, "ARTWORK")
    overlay:SetAllPoints()
    overlay:Hide()
    state.overlay = overlay
    return overlay
end

local function InitializeRuneFrame(frame)
    if not IsObjectAccessible(frame) then
        return nil
    end

    local sourceRunes = frame.Runes
    if type(sourceRunes) ~= "table" or #sourceRunes == 0 then
        return nil
    end

    local frameData = trackedRuneFrames[frame]
    if not frameData then
        frameData = {
            isPersonal = false,
            runes = {},
            overlays = {},
            count = 0,
        }
        trackedRuneFrames[frame] = frameData
    end

    frameData.isPersonal = IsPersonalResourceFrame(frame)

    local oldCount = frameData.count or 0
    local newCount = #sourceRunes

    for i = 1, newCount do
        local rune = sourceRunes[i]
        if rune and IsObjectAccessible(rune) then
            if frameData.runes[i] ~= rune then
                local oldOverlay = frameData.overlays[i]
                if oldOverlay and oldOverlay:IsShown() then
                    oldOverlay:Hide()
                end
                frameData.runes[i] = rune
                frameData.overlays[i] = EnsureRuneOverlay(rune)
            elseif not frameData.overlays[i] then
                frameData.overlays[i] = EnsureRuneOverlay(rune)
            end
        else
            frameData.runes[i] = nil
            frameData.overlays[i] = nil
        end
    end

    for i = newCount + 1, oldCount do
        local oldOverlay = frameData.overlays[i]
        if oldOverlay and oldOverlay:IsShown() then
            oldOverlay:Hide()
        end
        frameData.runes[i] = nil
        frameData.overlays[i] = nil
    end

    frameData.count = newCount
    return frameData
end

local function GetRuneFrameCandidates()
    local frames = {}
    local seen = {}

    local function AddFrame(frame)
        if not IsObjectAccessible(frame) or seen[frame] then
            return
        end

        if type(frame.Runes) ~= "table" or #frame.Runes == 0 then
            return
        end

        seen[frame] = true
        frames[#frames + 1] = frame
    end

    -- Retail 12.1 source-confirmed frames: the player RuneFrame and the
    -- nameless PersonalResourceDisplayFrame.classFrame created from RuneFrameTemplate.
    AddFrame(RuneFrame)

    local prdFrame = PersonalResourceDisplayFrame
    if IsObjectAccessible(prdFrame) then
        AddFrame(prdFrame.classFrame)
    end

    return frames
end

local function InitializeRuneFrames()
    local frames = GetRuneFrameCandidates()
    for i = 1, #frames do
        InitializeRuneFrame(frames[i])
    end
end

local function SetLayerShown(layer, shown)
    if not layer then
        return
    end

    if shown then
        layer:Show()
    else
        layer:Hide()
    end
end

local function SetAtlasLayersHidden(rune, hidden, force)
    if not rune then
        return false
    end

    local state = GetOrCreateRuneState(rune)
    if not force and state.atlasHidden == hidden then
        return true
    end

    if IsInCombat() then
        MarkCombatRefresh()
        return false
    end

    local shown = not hidden
    for i = 1, #ATLAS_LAYERS do
        SetLayerShown(rune[ATLAS_LAYERS[i]], shown)
    end

    local depleteVisuals = rune.DepleteVisuals
    if depleteVisuals then
        for i = 1, #DEPLETE_LAYERS do
            SetLayerShown(depleteVisuals[DEPLETE_LAYERS[i]], shown)
        end
    end

    state.atlasHidden = hidden
    return true
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
    if style == RUNE_STYLE_MIXED then
        return GetMixedTextureByLayout(rune, fallbackIndex)
    elseif style == RUNE_STYLE_DEATH then
        return RUNE_TEXTURES.DEATH
    elseif style == RUNE_STYLE_SPECLESS then
        return nil
    elseif artType then
        return RUNE_TEXTURES[artType]
    end

    return nil
end

local function ApplySpeclessArt(rune)
    if not rune or type(rune.UpdateSpec) ~= "function" then
        return false
    end

    local state = GetOrCreateRuneState(rune)
    if state.artToken == "DEFAULT" then
        return true
    end

    if IsInCombat() then
        MarkCombatRefresh()
        return false
    end

    rune:UpdateSpec(nil)
    state.artToken = "DEFAULT"
    return true
end

local function DimOverlay(rune, overlay)
    if not rune or not overlay or not overlay:IsShown() then
        return
    end

    local _, _, runeReady = GetRuneCooldown(rune.runeIndex)
    if runeReady then
        overlay:SetVertexColor(1, 1, 1)
    else
        overlay:SetVertexColor(0.4, 0.4, 0.4)
    end
end

local function InvalidateFramePresentation(frameData)
    if not frameData then
        return
    end

    frameData.presentationMode = nil

    for i = 1, frameData.count do
        local rune = frameData.runes[i]
        if rune then
            local state = GetOrCreateRuneState(rune)
            state.artToken = nil
            state.atlasHidden = nil
            state.texturePath = nil

            local cooldown = rune.Cooldown
            if cooldown then
                local cooldownData = GetOrCreateCooldownState(cooldown)
                cooldownData.hideNumbers = nil
                cooldownData.drawSwipe = nil
                cooldownData.drawEdge = nil
            end
        end
    end
end

local function RestoreDefaultFramePresentation(frameData)
    if not frameData then
        return false
    end

    if frameData.presentationMode == "DEFAULT" then
        return true
    end

    if IsInCombat() then
        MarkCombatRefresh()
        return false
    end

    local specIndex = C_SpecializationInfo.GetSpecialization()

    for i = 1, frameData.count do
        local rune = frameData.runes[i]
        local overlay = frameData.overlays[i]

        if rune and IsObjectAccessible(rune) then
            if type(rune.UpdateSpec) == "function" then
                rune:UpdateSpec(specIndex)
            end
            SetAtlasLayersHidden(rune, false, true)

            local state = GetOrCreateRuneState(rune)
            state.artToken = specIndex or "DEFAULT"
            state.texturePath = nil
        end

        if overlay and overlay:IsShown() then
            overlay:Hide()
        end
    end

    frameData.presentationMode = "DEFAULT"
    return true
end

local function ApplyFramePresentation(frameData, artType)
    if not frameData then
        return
    end

    if not IsFrameEnabled(frameData) then
        RestoreDefaultFramePresentation(frameData)
        return
    end

    local style = GetRuneStyle()

    for i = 1, frameData.count do
        local rune = frameData.runes[i]
        if rune and IsObjectAccessible(rune) then
            local overlay = frameData.overlays[i]
            if not overlay then
                overlay = EnsureRuneOverlay(rune)
                frameData.overlays[i] = overlay
            end

            local state = GetOrCreateRuneState(rune)
            local texturePath = GetTextureForRune(rune, i, artType, style)

            if texturePath then
                if overlay and SetAtlasLayersHidden(rune, true, false) then
                    if state.texturePath ~= texturePath then
                        overlay:SetTexture(texturePath)
                        state.texturePath = texturePath
                    end

                    if not overlay:IsShown() then
                        overlay:Show()
                    end
                    DimOverlay(rune, overlay)
                end
            else
                if ApplySpeclessArt(rune) and SetAtlasLayersHidden(rune, false, false) then
                    if overlay and overlay:IsShown() then
                        overlay:Hide()
                    end
                    state.texturePath = nil
                end
            end
        end
    end
end

local function SetCooldownPresentation(frameData)
    if not frameData then
        return
    end

    local enabled = IsFrameEnabled(frameData)
    local hideNumbers
    local showSpiral

    if enabled then
        hideNumbers = not OldRunesDB.showTimerNumbers
        showSpiral = OldRunesDB.showCooldownSpiral ~= false
    else
        -- Blizzard RuneFrameTemplate defaults.
        hideNumbers = true
        showSpiral = true
    end

    for i = 1, frameData.count do
        local rune = frameData.runes[i]
        local cooldown = rune and rune.Cooldown
        if cooldown and IsObjectAccessible(cooldown) then
            local state = GetOrCreateCooldownState(cooldown)

            if state.hideNumbers ~= hideNumbers then
                cooldown:SetHideCountdownNumbers(hideNumbers)
                state.hideNumbers = hideNumbers
            end

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

local function ApplyAllFramePresentation(artType)
    for _, frameData in pairs(trackedRuneFrames) do
        ApplyFramePresentation(frameData, artType)
        SetCooldownPresentation(frameData)
    end
end

function OldRunesUI.UpdateRecoveryOrder(targetFrame)
    EnsureDBDefaults()
    if targetFrame then
        InitializeRuneFrame(targetFrame)
    else
        InitializeRuneFrames()
    end
end

function OldRunesUI.ApplyRuneTextures(artType, targetFrame)
    EnsureDBDefaults()

    if targetFrame then
        local frameData = InitializeRuneFrame(targetFrame)
        ApplyFramePresentation(frameData, artType or GetCurrentArtType())
        return
    end

    InitializeRuneFrames()
    ApplyAllFramePresentation(artType or GetCurrentArtType())
end

function OldRunesUI.UpdateTimerVisibility()
    EnsureDBDefaults()
    InitializeRuneFrames()

    for _, frameData in pairs(trackedRuneFrames) do
        SetCooldownPresentation(frameData)
    end
end

function OldRunesUI.UpdateCooldownSpiral()
    EnsureDBDefaults()
    InitializeRuneFrames()

    for _, frameData in pairs(trackedRuneFrames) do
        SetCooldownPresentation(frameData)
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
    if not IsObjectAccessible(frame) or frameHooks[frame] then
        return
    end

    if type(frame.UpdateRunes) ~= "function" then
        return
    end

    hooksecurefunc(frame, "UpdateRunes", function(updatedFrame, isSpecChange)
        EnsureDBDefaults()

        local frameData = InitializeRuneFrame(updatedFrame)
        local artType = GetCurrentArtType()
        if isSpecChange then
            -- Blizzard UpdateRunes(true) has just called rune:UpdateSpec(specIndex).
            -- Discard presentation-only cache before reasserting the persisted
            -- addon style. Ordinary rune updates do not invalidate atlas setup.
            InvalidateFramePresentation(frameData)
        end

        ApplyFramePresentation(frameData, artType)
        SetCooldownPresentation(frameData)
    end)

    frameHooks[frame] = true
end

local function HookRuneFrames()
    for frame in pairs(trackedRuneFrames) do
        HookRuneFrame(frame)
    end
end

local function HookPersonalResourceDisplay()
    local prdFrame = PersonalResourceDisplayFrame
    if not IsObjectAccessible(prdFrame) or prdHooks[prdFrame] then
        return
    end

    local hooked = false

    if type(prdFrame.SetupClassBar) == "function" then
        hooksecurefunc(prdFrame, "SetupClassBar", function()
            QueueRefreshBurst(true)
        end)
        hooked = true
    end

    if type(prdFrame.SetHideClassInfo) == "function" then
        hooksecurefunc(prdFrame, "SetHideClassInfo", function()
            QueueRefreshBurst(true)
        end)
        hooked = true
    end

    if hooked then
        prdHooks[prdFrame] = true
    end
end

RefreshRuneVisuals = function(forcePresentation)
    EnsureDBDefaults()
    HookPersonalResourceDisplay()
    InitializeRuneFrames()
    HookRuneFrames()

    if forcePresentation then
        for _, frameData in pairs(trackedRuneFrames) do
            InvalidateFramePresentation(frameData)
        end
    end

    ApplyAllFramePresentation(GetCurrentArtType())
end

QueueRefreshBurst = function(forcePresentation)
    refreshGeneration = refreshGeneration + 1
    local generation = refreshGeneration
    local delays = { 0, 0.2, 1.0 }

    for i = 1, #delays do
        C_Timer.After(delays[i], function()
            if generation ~= refreshGeneration then
                return
            end
            RefreshRuneVisuals(forcePresentation)
        end)
    end
end

function OldRunesUI.RefreshAll()
    QueueRefreshBurst(true)
end

function OldRunes:ADDON_LOADED(loadedAddon)
    if loadedAddon == "OldRunes" then
        EnsureDBDefaults()
        QueueRefreshBurst(true)
    elseif loadedAddon == "Blizzard_UnitFrame"
        or loadedAddon == "Blizzard_PersonalResourceDisplay" then
        QueueRefreshBurst(true)
    end
end

function OldRunes:PLAYER_LOGIN()
    QueueRefreshBurst(true)
    self:UnregisterEvent("PLAYER_LOGIN")
end

function OldRunes:PLAYER_ENTERING_WORLD()
    QueueRefreshBurst(true)
end

function OldRunes:PLAYER_SPECIALIZATION_CHANGED(unit)
    if unit and unit ~= "player" then
        return
    end
    QueueRefreshBurst(true)
end

function OldRunes:PLAYER_REGEN_ENABLED()
    if not pendingCombatRefresh then
        return
    end

    pendingCombatRefresh = false
    QueueRefreshBurst(true)
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
    print(("%s: " .. (L.MSG_STYLE_SET or "Style set to %s")):format(
        GetAddonPrefix(),
        GetLocalizedStyleName(style)
    ))
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
        OldRunesUI.RefreshAll()
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
            print(("%s: %s"):format(
                GetAddonPrefix(),
                L.MSG_STYLE_USAGE or "Usage /or style spec|mixed|death|specless"
            ))
            return
        end

        SetRuneStyle(style)
        PrintStyleSet(style)
        OldRunesUI.RefreshAll()
    elseif cmd == "multicolor" then
        if GetRuneStyle() == RUNE_STYLE_MIXED then
            SetRuneStyle(RUNE_STYLE_SPEC)
            PrintStyleSet(RUNE_STYLE_SPEC)
        else
            SetRuneStyle(RUNE_STYLE_MIXED)
            PrintStyleSet(RUNE_STYLE_MIXED)
        end
        OldRunesUI.RefreshAll()
    elseif cmd == "config" then
        if Settings and Settings.OpenToCategory then
            local categoryID = OldRunesUI.settingsCategoryID
            if not categoryID and OldRunesUI.settingsCategory
                and OldRunesUI.settingsCategory.GetID then
                categoryID = OldRunesUI.settingsCategory:GetID()
            end

            if categoryID then
                Settings.OpenToCategory(categoryID)
                return
            end
        end

        print(("%s: %s"):format(
            GetAddonPrefix(),
            L.MSG_SETTINGS_NOT_READY or "Settings not registered yet. Reload UI."
        ))
    end
end
