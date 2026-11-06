-- Old Runes (Retail 12.1.5)
-- Restores classic Death Knight rune textures without owning Blizzard layout.

local ADDON_NAME = ... or "OldRunes"

OldRunesUI = OldRunesUI or {}

local API = OldRunesUI
local L = API.L or {}

local RUNE_STYLE_SPEC = "SPEC"
local RUNE_STYLE_MIXED = "MIXED"
local RUNE_STYLE_DEATH = "DEATH"
local RUNE_STYLE_SPECLESS = "SPECLESS"
local DB_SCHEMA = 2

API.RUNE_STYLE_SPEC = RUNE_STYLE_SPEC
API.RUNE_STYLE_MIXED = RUNE_STYLE_MIXED
API.RUNE_STYLE_DEATH = RUNE_STYLE_DEATH
API.RUNE_STYLE_SPECLESS = RUNE_STYLE_SPECLESS

local VALID_STYLES = {
    [RUNE_STYLE_SPEC] = true,
    [RUNE_STYLE_MIXED] = true,
    [RUNE_STYLE_DEATH] = true,
    [RUNE_STYLE_SPECLESS] = true,
}

local DEFAULTS = {
    showTimerNumbers = true,
    showCooldownSpiral = true,
    oldPersonalResourceDisplay = true,
    runeStyle = RUNE_STYLE_SPEC,
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

local STYLE_ALIASES = {
    spec = RUNE_STYLE_SPEC,
    mixed = RUNE_STYLE_MIXED,
    death = RUNE_STYLE_DEATH,
    specless = RUNE_STYLE_SPECLESS,
    gray = RUNE_STYLE_SPECLESS,
    grey = RUNE_STYLE_SPECLESS,
}

local database

local function NormalizeBoolean(value, defaultValue)
    if type(value) == "boolean" then
        return value
    end
    return defaultValue
end

local function EnsureDBDefaults()
    if type(OldRunesDB) ~= "table" then
        OldRunesDB = {}
    end

    local db = OldRunesDB
    local migrateLegacyMixed = not VALID_STYLES[db.runeStyle]
        and db.multicolorRunes == true

    db.showTimerNumbers = NormalizeBoolean(
        db.showTimerNumbers,
        DEFAULTS.showTimerNumbers
    )
    db.showCooldownSpiral = NormalizeBoolean(
        db.showCooldownSpiral,
        DEFAULTS.showCooldownSpiral
    )
    db.oldPersonalResourceDisplay = NormalizeBoolean(
        db.oldPersonalResourceDisplay,
        DEFAULTS.oldPersonalResourceDisplay
    )

    if migrateLegacyMixed then
        db.runeStyle = RUNE_STYLE_MIXED
    elseif not VALID_STYLES[db.runeStyle] then
        db.runeStyle = DEFAULTS.runeStyle
    end

    -- One-way compatibility cleanup. These fields no longer own runtime state.
    db.multicolorRunes = nil
    db.reverseRecoveryOrder = nil
    db.schema = DB_SCHEMA

    database = db
    return db
end

local function GetDB()
    if type(database) ~= "table" or database ~= OldRunesDB then
        return EnsureDBDefaults()
    end
    return database
end

local function GetRuneStyle()
    local style = GetDB().runeStyle
    if VALID_STYLES[style] then
        return style
    end
    return RUNE_STYLE_SPEC
end

local function SetRuneStyle(style)
    if not VALID_STYLES[style] then
        return false
    end

    GetDB().runeStyle = style
    return true
end

API.EnsureDBDefaults = EnsureDBDefaults
API.GetRuneStyle = GetRuneStyle
API.SetRuneStyle = SetRuneStyle

local _, playerClass = UnitClass("player")
local isDeathKnight = playerClass == "DEATHKNIGHT"
API.isDeathKnight = isDeathKnight

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

    if type(object.HasAccessConstraints) == "function"
        and object:HasAccessConstraints() then
        return type(object.CanBeAccessedInContext) == "function"
            and object:CanBeAccessedInContext() == true
    end

    return true
end

local function GetAddonPrefix()
    return "|cff4db7ff" .. (L.ADDON_NAME or "Old Runes") .. "|r"
end

local function GetStateText(enabled)
    if enabled then
        return "|cff00ff00" .. (L.STATE_ON or "ON") .. "|r"
    end
    return "|cffff4040" .. (L.STATE_OFF or "OFF") .. "|r"
end

local function PrintToggleStatus(label, enabled)
    print(("%s: %s %s"):format(GetAddonPrefix(), label, GetStateText(enabled)))
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

local function OpenSettings()
    if Settings and Settings.OpenToCategory then
        local categoryID = API.settingsCategoryID
        if not categoryID and API.settingsCategory
            and API.settingsCategory.GetID then
            categoryID = API.settingsCategory:GetID()
        end

        if categoryID then
            Settings.OpenToCategory(categoryID)
            return true
        end
    end

    print(("%s: %s"):format(
        GetAddonPrefix(),
        L.MSG_SETTINGS_NOT_READY or "Settings are not registered yet. Reload the UI."
    ))
    return false
end

local function PrintHelp()
    print(("%s: %s"):format(GetAddonPrefix(), L.CMD_HELP_TITLE or "Commands:"))
    print("  |cff4db7ff/or timer|r - " .. (L.CMD_DESC_TIMER or "Toggle timer numbers"))
    print("  |cff4db7ff/or spiral|r - " .. (L.CMD_DESC_SPIRAL or "Toggle cooldown spiral"))
    print("  |cff4db7ff/or prd|r - " .. (L.CMD_DESC_PRD or "Toggle Personal Resource Display styling"))
    print("  |cff4db7ff/or style spec|r - " .. (L.CMD_DESC_STYLE_SPEC or "Spec-based classic runes"))
    print("  |cff4db7ff/or style mixed|r - " .. (L.CMD_DESC_STYLE_MIXED or "Mixed classic runes"))
    print("  |cff4db7ff/or style death|r - " .. (L.CMD_DESC_STYLE_DEATH or "Death runes"))
    print("  |cff4db7ff/or style specless|r - " .. (L.CMD_DESC_STYLE_SPECLESS or "Blizzard gray runes"))
    print("  |cff4db7ff/or config|r - " .. (L.CMD_DESC_CONFIG or "Open settings"))
end

-- Runtime integration is installed only for Death Knights. Shared configuration,
-- migration and slash commands remain available on every character.
local trackedRuneFrames
local frameHooks
local prdHooks
local runeState
local cooldownState
local pendingCombatRefresh = false
local refreshGeneration = 0
local RefreshRuneVisuals
local QueueRefreshBurst

local function NoopRefresh()
end

API.RefreshAll = NoopRefresh

if isDeathKnight then
    trackedRuneFrames = setmetatable({}, { __mode = "k" })
    frameHooks = setmetatable({}, { __mode = "k" })
    prdHooks = setmetatable({}, { __mode = "k" })
    runeState = setmetatable({}, { __mode = "k" })
    cooldownState = setmetatable({}, { __mode = "k" })

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

    local function IsPersonalResourceFrame(frame)
        local prdFrame = PersonalResourceDisplayFrame
        return prdFrame ~= nil and frame == prdFrame.classFrame
    end

    local function IsFrameEnabled(frameData)
        if frameData.isPersonal then
            return GetDB().oldPersonalResourceDisplay
        end
        return true
    end

    local function GetCurrentSpecIndex()
        if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
            return C_SpecializationInfo.GetSpecialization()
        end
        return nil
    end

    local function GetCurrentArtType()
        return SPEC_TO_RUNE[GetCurrentSpecIndex()]
    end

    local function HideOverlayForRune(rune)
        local state = runeState[rune]
        local overlay = state and state.overlay
        if overlay and overlay:IsShown() then
            overlay:Hide()
        end
    end

    local function EnsureRuneOverlay(rune)
        if not IsObjectAccessible(rune) then
            return nil
        end

        local state = GetOrCreateRuneState(rune)
        if state.overlay then
            return state.overlay
        end

        if IsInCombat() then
            MarkCombatRefresh()
            return nil
        end

        local overlay = rune:CreateTexture(nil, "ARTWORK", nil, 4)
        overlay:SetAllPoints(rune)
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
                frame = frame,
                runes = {},
                count = 0,
                isPersonal = false,
            }
            trackedRuneFrames[frame] = frameData
        end

        frameData.isPersonal = IsPersonalResourceFrame(frame)

        local oldCount = frameData.count
        local newCount = #sourceRunes

        for i = 1, newCount do
            local rune = sourceRunes[i]
            if rune and IsObjectAccessible(rune) then
                if frameData.runes[i] ~= rune then
                    local oldRune = frameData.runes[i]
                    if oldRune then
                        HideOverlayForRune(oldRune)
                    end
                    frameData.runes[i] = rune
                end
            else
                local oldRune = frameData.runes[i]
                if oldRune then
                    HideOverlayForRune(oldRune)
                end
                frameData.runes[i] = nil
            end
        end

        for i = newCount + 1, oldCount do
            local oldRune = frameData.runes[i]
            if oldRune then
                HideOverlayForRune(oldRune)
            end
            frameData.runes[i] = nil
        end

        frameData.count = newCount
        return frameData
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

    local function GetMixedTexture(rune, fallbackIndex)
        local visualIndex = fallbackIndex
        if type(rune.layoutIndex) == "number" and rune.layoutIndex > 0 then
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
            return GetMixedTexture(rune, fallbackIndex)
        elseif style == RUNE_STYLE_DEATH then
            return RUNE_TEXTURES.DEATH
        elseif style == RUNE_STYLE_SPEC and artType then
            return RUNE_TEXTURES[artType]
        end
        return nil
    end

    local function GetRuneReady(rune)
        local lastState = rune.lastRuneState
        if type(lastState) == "table" and type(lastState.runeReady) == "boolean" then
            return lastState.runeReady
        end

        if GetRuneCooldown and rune.runeIndex then
            local _, _, ready = GetRuneCooldown(rune.runeIndex)
            return ready == true
        end
        return true
    end

    local function UpdateOverlayBrightness(rune, overlay)
        if not overlay or not overlay:IsShown() then
            return
        end

        if GetRuneReady(rune) then
            overlay:SetVertexColor(1, 1, 1)
        else
            overlay:SetVertexColor(0.4, 0.4, 0.4)
        end
    end

    local function ApplyBlizzardArt(rune, specIndex, artToken)
        if type(rune.UpdateSpec) ~= "function" then
            return false
        end

        local state = GetOrCreateRuneState(rune)
        if state.artToken ~= artToken then
            if IsInCombat() then
                MarkCombatRefresh()
                return false
            end
            rune:UpdateSpec(specIndex)
            state.artToken = artToken
            state.atlasHidden = nil
        end

        if not SetAtlasLayersHidden(rune, false, false) then
            return false
        end

        local overlay = state.overlay
        if overlay and overlay:IsShown() then
            overlay:Hide()
        end
        state.texturePath = nil
        return true
    end

    local function ApplyClassicArt(rune, texturePath)
        local overlay = EnsureRuneOverlay(rune)
        if not overlay or not SetAtlasLayersHidden(rune, true, false) then
            return false
        end

        local state = GetOrCreateRuneState(rune)
        if state.texturePath ~= texturePath then
            overlay:SetTexture(texturePath)
            state.texturePath = texturePath
        end

        if not overlay:IsShown() then
            overlay:Show()
        end
        UpdateOverlayBrightness(rune, overlay)
        state.artToken = "CLASSIC"
        return true
    end

    local function InvalidateFramePresentation(frameData)
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

    local function ApplyFrameArt(frameData, artType)
        local enabled = IsFrameEnabled(frameData)
        local style = GetRuneStyle()
        local specIndex = GetCurrentSpecIndex()

        for i = 1, frameData.count do
            local rune = frameData.runes[i]
            if rune and IsObjectAccessible(rune) then
                if not enabled then
                    ApplyBlizzardArt(
                        rune,
                        specIndex,
                        "BLIZZARD:" .. tostring(specIndex or "DEFAULT")
                    )
                elseif style == RUNE_STYLE_SPECLESS
                    or (style == RUNE_STYLE_SPEC and not artType) then
                    ApplyBlizzardArt(rune, nil, "SPECLESS")
                else
                    local texturePath = GetTextureForRune(rune, i, artType, style)
                    if texturePath then
                        ApplyClassicArt(rune, texturePath)
                    end
                end
            end
        end
    end

    local function SetCooldownPresentation(frameData)
        local db = GetDB()
        local enabled = IsFrameEnabled(frameData)
        local hideNumbers = true
        local showSpiral = true
        if enabled then
            hideNumbers = not db.showTimerNumbers
            showSpiral = db.showCooldownSpiral
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

    local function ApplyFramePresentation(frameData, artType)
        if not frameData then
            return
        end
        ApplyFrameArt(frameData, artType)
        SetCooldownPresentation(frameData)
    end

    local function HookRuneFrame(frame)
        if frameHooks[frame] or type(frame.UpdateRunes) ~= "function" then
            return
        end

        hooksecurefunc(frame, "UpdateRunes", function(updatedFrame, isSpecChange)
            local frameData = InitializeRuneFrame(updatedFrame)
            if not frameData then
                return
            end

            if isSpecChange then
                InvalidateFramePresentation(frameData)
            end
            ApplyFramePresentation(frameData, GetCurrentArtType())
        end)

        frameHooks[frame] = true
    end

    local function DiscoverRuneFrames()
        local playerFrame = RuneFrame
        if IsObjectAccessible(playerFrame) then
            local frameData = InitializeRuneFrame(playerFrame)
            if frameData then
                HookRuneFrame(playerFrame)
            end
        end

        local prdFrame = PersonalResourceDisplayFrame
        if IsObjectAccessible(prdFrame) then
            local classFrame = prdFrame.classFrame
            if classFrame ~= playerFrame and IsObjectAccessible(classFrame) then
                local frameData = InitializeRuneFrame(classFrame)
                if frameData then
                    HookRuneFrame(classFrame)
                end
            end
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
        DiscoverRuneFrames()

        if forcePresentation then
            for _, frameData in pairs(trackedRuneFrames) do
                InvalidateFramePresentation(frameData)
            end
        end

        local artType = GetCurrentArtType()
        for frame, frameData in pairs(trackedRuneFrames) do
            if IsObjectAccessible(frame) then
                ApplyFramePresentation(frameData, artType)
            end
        end
    end

    local REFRESH_DELAYS = { 0.2, 1.0 }

    QueueRefreshBurst = function(forcePresentation)
        refreshGeneration = refreshGeneration + 1
        local generation = refreshGeneration

        RefreshRuneVisuals(forcePresentation)

        for i = 1, #REFRESH_DELAYS do
            C_Timer.After(REFRESH_DELAYS[i], function()
                if generation == refreshGeneration then
                    RefreshRuneVisuals(false)
                end
            end)
        end
    end

    API.RefreshAll = function()
        QueueRefreshBurst(true)
    end
end

local EventFrame = CreateFrame("Frame")
EventFrame:SetScript("OnEvent", function(self, event, ...)
    local handler = self[event]
    if handler then
        handler(self, ...)
    end
end)

function EventFrame:ADDON_LOADED(loadedAddon)
    if loadedAddon == ADDON_NAME then
        EnsureDBDefaults()
        if isDeathKnight then
            QueueRefreshBurst(true)
        end
    elseif isDeathKnight and (loadedAddon == "Blizzard_UnitFrame"
        or loadedAddon == "Blizzard_PersonalResourceDisplay") then
        QueueRefreshBurst(true)
    end
end

function EventFrame:PLAYER_LOGIN()
    QueueRefreshBurst(true)
    self:UnregisterEvent("PLAYER_LOGIN")
end

function EventFrame:PLAYER_ENTERING_WORLD()
    QueueRefreshBurst(true)
end

function EventFrame:PLAYER_SPECIALIZATION_CHANGED(unit)
    if not unit or unit == "player" then
        QueueRefreshBurst(true)
    end
end

function EventFrame:PLAYER_REGEN_ENABLED()
    if pendingCombatRefresh then
        pendingCombatRefresh = false
        QueueRefreshBurst(true)
    end
end

EventFrame:RegisterEvent("ADDON_LOADED")
if isDeathKnight then
    EventFrame:RegisterEvent("PLAYER_LOGIN")
    EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    EventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

SLASH_OLDRUNES1 = "/or"
SLASH_OLDRUNES2 = "/oldrunes"

SlashCmdList["OLDRUNES"] = function(message)
    local db = EnsureDBDefaults()
    local input = (message or ""):lower():gsub("^%s*(.-)%s*$", "%1")
    local command, argument = input:match("^(%S+)%s*(.-)$")

    if not command or command == "" or command == "help" then
        PrintHelp()
        return
    end

    if command == "timer" then
        db.showTimerNumbers = not db.showTimerNumbers
        PrintToggleStatus(L.MSG_TIMER or "Timer", db.showTimerNumbers)
        API.RefreshAll()
    elseif command == "spiral" then
        db.showCooldownSpiral = not db.showCooldownSpiral
        PrintToggleStatus(L.MSG_COOLDOWN_SPIRAL or "Cooldown spiral", db.showCooldownSpiral)
        API.RefreshAll()
    elseif command == "prd" or command == "personal" then
        db.oldPersonalResourceDisplay = not db.oldPersonalResourceDisplay
        PrintToggleStatus(
            L.MSG_OLD_PRD or "Personal Resource Display styling",
            db.oldPersonalResourceDisplay
        )
        API.RefreshAll()
    elseif command == "style" then
        local style = STYLE_ALIASES[argument]
        if not style then
            print(("%s: %s"):format(
                GetAddonPrefix(),
                L.MSG_STYLE_USAGE or "Usage: /or style spec|mixed|death|specless"
            ))
            return
        end

        SetRuneStyle(style)
        PrintStyleSet(style)
        API.RefreshAll()
    elseif command == "multicolor" then
        -- Hidden compatibility alias for pre-2.0 commands.
        local style = GetRuneStyle() == RUNE_STYLE_MIXED
            and RUNE_STYLE_SPEC or RUNE_STYLE_MIXED
        SetRuneStyle(style)
        PrintStyleSet(style)
        API.RefreshAll()
    elseif command == "reverse" then
        print(("%s: %s"):format(
            GetAddonPrefix(),
            L.MSG_REVERSE_REMOVED
                or "Reverse recovery was removed because it taints Blizzard's managed rune layout."
        ))
    elseif command == "config" or command == "options" then
        OpenSettings()
    else
        PrintHelp()
    end
end
