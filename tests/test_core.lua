local selectedRegression = arg[1]
local unpackValues = table.unpack or unpack

local function fail(message)
    io.stderr:write("FAIL: ", message, "\n")
    os.exit(1)
end

local function assertTrue(value, message)
    if not value then
        fail(message)
    end
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        fail(("%s (expected %s, got %s)"):format(
            message,
            tostring(expected),
            tostring(actual)
        ))
    end
end

local timerQueue = {}
local timerCancelCount = 0
local createdFrames = {}
local hookCount = 0
local inCombat = false
local specialization = 1
local openedCategory
local output = {}

_G.print = function(...)
    local values = {}
    for i = 1, select("#", ...) do
        values[i] = tostring(select(i, ...))
    end
    output[#output + 1] = table.concat(values, " ")
end

_G.GetLocale = function()
    return "enUS"
end

_G.UnitClass = function()
    return "Death Knight", "DEATHKNIGHT", 6
end

_G.InCombatLockdown = function()
    return inCombat
end

local function NewTimer(_, callback)
    local timer = {
        callback = callback,
        cancelled = false,
        fired = false,
    }

    function timer:Cancel()
        if not self.cancelled then
            self.cancelled = true
            timerCancelCount = timerCancelCount + 1
        end
    end

    timerQueue[#timerQueue + 1] = timer
    return timer
end

_G.C_Timer = { NewTimer = NewTimer }

local function PendingTimerCount()
    local count = 0
    for _, timer in ipairs(timerQueue) do
        if not timer.cancelled and not timer.fired then
            count = count + 1
        end
    end
    return count
end

local function FlushTimers()
    local iterations = 0
    while #timerQueue > 0 do
        iterations = iterations + 1
        if iterations > 50 then
            fail("timer queue did not terminate")
        end

        local pending = timerQueue
        timerQueue = {}
        for i = 1, #pending do
            local timer = pending[i]
            if not timer.cancelled and not timer.fired then
                timer.fired = true
                timer.callback()
            end
        end
    end
end

_G.C_SpecializationInfo = {
    GetSpecialization = function()
        return specialization
    end,
}

_G.GetRuneCooldown = function(index)
    local rune = _G.RuneFrame and _G.RuneFrame.Runes[index]
    local ready = not rune or not rune.lastRuneState
        or rune.lastRuneState.runeReady ~= false
    return ready and 0 or 1, ready and 0 or 10, ready
end

_G.SlashCmdList = {}
_G.Settings = {
    OpenToCategory = function(categoryID)
        openedCategory = categoryID
    end,
}

local function NewEventFrame()
    local frame = {
        events = {},
        scripts = {},
    }

    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    function frame:RegisterEvent(event)
        self.events[event] = true
    end

    function frame:UnregisterEvent(event)
        self.events[event] = nil
    end

    function frame:UnregisterAllEvents()
        self.events = {}
    end

    createdFrames[#createdFrames + 1] = frame
    return frame
end

_G.CreateFrame = function()
    return NewEventFrame()
end

_G.hooksecurefunc = function(target, methodName, callback)
    local original = target[methodName]
    assertTrue(type(original) == "function", "hook target must be a function")

    target[methodName] = function(self, ...)
        local results = { original(self, ...) }
        callback(self, ...)
        return unpackValues(results)
    end
    hookCount = hookCount + 1
end

local function NewLayer()
    local layer = { shown = true }

    function layer:Show()
        self.shown = true
    end

    function layer:Hide()
        self.shown = false
    end

    function layer:IsShown()
        return self.shown
    end

    return layer
end

local function NewTexture()
    local texture = NewLayer()
    texture.path = nil
    texture.vertex = { 1, 1, 1 }

    function texture:SetAllPoints(owner)
        self.owner = owner
    end

    function texture:SetTexture(path)
        self.path = path
    end

    function texture:SetVertexColor(r, g, b)
        self.vertex = { r, g, b }
    end

    return texture
end

local function NewCooldown()
    local cooldown = {
        hideNumbers = true,
        drawSwipe = true,
        drawEdge = true,
    }

    function cooldown:SetHideCountdownNumbers(value)
        self.hideNumbers = value
    end

    function cooldown:SetDrawSwipe(value)
        self.drawSwipe = value
    end

    function cooldown:SetDrawEdge(value)
        self.drawEdge = value
    end

    return cooldown
end

local atlasLayers = {
    "Rune_Grad", "Rune_Lines", "Rune_Active", "Rune_Mid",
    "Rune_Eyes", "Glow", "Glow2", "Smoke",
    "Rune_Inactive", "BG_Active", "BG_Inactive", "BG_Shadow",
}

local depleteLayers = {
    "Rune_Inactive", "Rune_Lines", "Glow2", "FB_RuneDeplete",
}

local textureCount = 0

local function NewRune(index)
    local rune = {
        layoutIndex = index,
        runeIndex = index,
        Cooldown = NewCooldown(),
        DepleteVisuals = {},
        lastRuneState = { runeReady = index % 2 == 1 },
        updateSpecCalls = 0,
    }

    for i = 1, #atlasLayers do
        rune[atlasLayers[i]] = NewLayer()
    end
    for i = 1, #depleteLayers do
        rune.DepleteVisuals[depleteLayers[i]] = NewLayer()
    end

    function rune:CreateTexture()
        textureCount = textureCount + 1
        self.overlay = NewTexture()
        return self.overlay
    end

    function rune:UpdateSpec(specIndex)
        self.updateSpecCalls = self.updateSpecCalls + 1
        self.lastSpec = specIndex
        self.lastSpecWasNil = specIndex == nil
    end

    return rune
end

local function NewRuneFrame()
    local frame = { Runes = {} }
    for i = 1, 6 do
        frame.Runes[i] = NewRune(i)
    end

    function frame:UpdateRunes(isSpecChange)
        if isSpecChange then
            for i = 1, #self.Runes do
                self.Runes[i]:UpdateSpec(specialization)
            end
        end
    end

    return frame
end

_G.RuneFrame = NewRuneFrame()
_G.PersonalResourceDisplayFrame = {
    classFrame = NewRuneFrame(),
    SetupClassBar = function() end,
    SetHideClassInfo = function() end,
}

_G.OldRunesDB = {
    multicolorRunes = true,
    reverseRecoveryOrder = true,
}

assert(loadfile("Localization.lua"))("OldRunes", {})
assert(loadfile("Core.lua"))("OldRunes", {})

local eventFrame = createdFrames[1]
assertTrue(eventFrame ~= nil, "core event frame was not created")
assertTrue(eventFrame.events.ADDON_LOADED, "ADDON_LOADED was not registered")
assertTrue(eventFrame.events.PLAYER_LOGIN, "PLAYER_LOGIN was not registered")
eventFrame.scripts.OnEvent(eventFrame, "ADDON_LOADED", "OldRunes")
FlushTimers()

assertEqual(OldRunesDB.schema, 2, "database schema was not migrated")
assertEqual(OldRunesDB.runeStyle, "MIXED", "legacy mixed style migration failed")
assertEqual(OldRunesDB.multicolorRunes, nil, "legacy multicolor key was not removed")
assertEqual(OldRunesDB.reverseRecoveryOrder, nil, "legacy reverse key was not removed")
assertTrue(type(SlashCmdList.OLDRUNES) == "function", "slash command is unavailable")

local player = RuneFrame
local prd = PersonalResourceDisplayFrame.classFrame
local blood = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Blood"
local frost = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Frost"
local unholy = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Unholy"
local death = "Interface\\PLAYERFRAME\\UI-PlayerFrame-Deathknight-Death"

assertTrue(hookCount >= 4, "expected RuneFrame and PRD hooks were not installed")
assertEqual(textureCount, 12, "each initial rune should own exactly one overlay")
assertEqual(player.Runes[1].overlay.path, blood, "mixed slot 1 should be Blood")
assertEqual(player.Runes[3].overlay.path, frost, "mixed slot 3 should be Frost")
assertEqual(player.Runes[5].overlay.path, unholy, "mixed slot 5 should be Unholy")
assertEqual(player.Runes[1].overlay.shown, true, "classic overlay is hidden")
assertEqual(player.Runes[1].Rune_Grad.shown, false, "Blizzard atlas was not hidden")
assertEqual(player.Runes[1].Cooldown.hideNumbers, false, "timer numbers were not enabled")
assertEqual(player.Runes[1].Cooldown.drawSwipe, true, "cooldown spiral default changed")
assertEqual(player.Runes[2].overlay.vertex[1], 0.4, "depleted rune was not dimmed")

local overlaysBeforeRefresh = textureCount
OldRunesUI.RefreshAll()
FlushTimers()
assertEqual(textureCount, overlaysBeforeRefresh, "refresh created duplicate overlays")

OldRunesUI.settingsCategoryID = 42
SlashCmdList.OLDRUNES("config")
assertEqual(openedCategory, 42, "settings command failed")

local styleBeforeUnknown = OldRunesDB.runeStyle
SlashCmdList.OLDRUNES("multicolor")
assertEqual(OldRunesDB.runeStyle, styleBeforeUnknown, "removed legacy command changed state")

OldRunesDB.oldPersonalResourceDisplay = false
OldRunesUI.RefreshAll()
FlushTimers()
assertEqual(prd.Runes[1].overlay.shown, false, "disabled PRD retained the custom overlay")
assertEqual(prd.Runes[1].Rune_Grad.shown, true, "disabled PRD did not restore Blizzard art")
assertEqual(prd.Runes[1].Cooldown.hideNumbers, true, "disabled PRD did not restore timer default")
assertEqual(prd.Runes[1].Cooldown.drawSwipe, true, "disabled PRD did not restore spiral default")
assertEqual(player.Runes[1].overlay.shown, true, "disabling PRD affected player RuneFrame")

OldRunesUI.SetRuneStyle("SPECLESS")
OldRunesUI.RefreshAll()
FlushTimers()
assertEqual(player.Runes[1].overlay.shown, false, "specless style retained custom overlay")
assertEqual(player.Runes[1].Rune_Grad.shown, true, "specless style hid Blizzard art")
assertEqual(player.Runes[1].lastSpecWasNil, true, "specless style did not call UpdateSpec(nil)")

OldRunesUI.SetRuneStyle("MIXED")
OldRunesUI.RefreshAll()
FlushTimers()
assertEqual(player.Runes[1].overlay.path, blood, "mixed slot 1 should be Blood")
assertEqual(player.Runes[3].overlay.path, frost, "mixed slot 3 should be Frost")
assertEqual(player.Runes[5].overlay.path, unholy, "mixed slot 5 should be Unholy")

OldRunesDB.showCooldownSpiral = false
OldRunesUI.RefreshAll()
FlushTimers()
assertEqual(player.Runes[1].Cooldown.drawSwipe, false, "player spiral setting was ignored")
assertEqual(player.Runes[1].Cooldown.drawEdge, false, "player edge setting was ignored")
assertEqual(prd.Runes[1].Cooldown.drawSwipe, true, "disabled PRD inherited addon spiral setting")

OldRunesUI.SetRuneStyle("SPECLESS")
OldRunesUI.RefreshAll()
FlushTimers()
inCombat = true
OldRunesUI.SetRuneStyle("DEATH")
OldRunesUI.RefreshAll()
FlushTimers()
assertEqual(player.Runes[1].overlay.shown, false, "combat transition mutated Blizzard atlas ownership")

inCombat = false
eventFrame.scripts.OnEvent(eventFrame, "PLAYER_REGEN_ENABLED")
FlushTimers()
assertEqual(player.Runes[1].overlay.path, death, "deferred combat refresh did not apply")
assertEqual(player.Runes[1].overlay.shown, true, "deferred classic overlay remained hidden")

OldRunesDB.oldPersonalResourceDisplay = true
OldRunesUI.SetRuneStyle("SPEC")
specialization = 1
OldRunesUI.RefreshAll()
FlushTimers()
specialization = 2
player:UpdateRunes(true)
assertEqual(player.Runes[1].overlay.path, frost, "spec-change hook did not reapply selected style")
assertEqual(player.Runes[1].Rune_Grad.shown, false, "spec-change hook left Blizzard atlas visible")

local oldPlayerRune = player.Runes[1]
local replacementPlayerRune = NewRune(1)
local texturesBeforeRuneReplacement = textureCount
player.Runes[1] = replacementPlayerRune
player:UpdateRunes(false)
assertEqual(oldPlayerRune.overlay.shown, false, "replaced player rune retained its overlay")
assertEqual(replacementPlayerRune.overlay.path, frost, "replacement player rune was not styled")
assertEqual(textureCount, texturesBeforeRuneReplacement + 1, "replacement player rune created an unexpected overlay count")

local replacementPRD = NewRuneFrame()
local texturesBeforePRDReplacement = textureCount
PersonalResourceDisplayFrame.classFrame = replacementPRD
PersonalResourceDisplayFrame:SetupClassBar()
FlushTimers()
assertEqual(prd.Runes[1].overlay.shown, false, "replaced PRD retained its custom overlay")
assertEqual(replacementPRD.Runes[1].overlay.path, frost, "replacement PRD classFrame was not discovered")
assertEqual(textureCount, texturesBeforePRDReplacement + 6, "replacement PRD created an unexpected overlay count")

local texturesBeforeStaleUpdate = textureCount
prd:UpdateRunes(false)
assertEqual(textureCount, texturesBeforeStaleUpdate, "stale PRD hook recreated presentation state")
assertEqual(prd.Runes[1].overlay.shown, false, "stale PRD hook re-enabled its overlay")

local regressions = {
    { "release", function()
        assertEqual(oldPlayerRune.Rune_Grad.shown, true, "released rune kept native art hidden")
        assertEqual(oldPlayerRune.Cooldown.hideNumbers, true, "released rune kept custom timer settings")
        assertEqual(oldPlayerRune.Cooldown.drawSwipe, true, "released rune kept custom spiral settings")
        assertEqual(prd.Runes[1].Rune_Grad.shown, true, "released PRD kept native art hidden")
        assertEqual(prd.Runes[1].Cooldown.hideNumbers, true, "released PRD kept custom timer settings")
    end },
    { "reuse", function()
        local before = textureCount
        collectgarbage("collect")
        for _ = 1, 20 do
            PersonalResourceDisplayFrame.classFrame = prd
            PersonalResourceDisplayFrame:SetupClassBar()
            PersonalResourceDisplayFrame.classFrame = replacementPRD
            PersonalResourceDisplayFrame:SetupClassBar()
        end
        FlushTimers()
        assertEqual(textureCount, before, "reused PRD allocated duplicate overlays")
        assertEqual(replacementPRD.Runes[1].overlay.shown, true, "reused PRD did not regain styling")
    end },
    { "empty", function()
        local owner = PersonalResourceDisplayFrame.classFrame
        local runes = owner.Runes
        local before = textureCount

        owner.Runes = {}
        OldRunesUI.RefreshAll()
        FlushTimers()
        assertEqual(runes[1].overlay.shown, false, "empty rune list retained stale overlays")
        assertEqual(runes[1].Rune_Grad.shown, true, "empty rune list did not release native art")

        owner.Runes = runes
        OldRunesUI.RefreshAll()
        FlushTimers()
        assertEqual(textureCount, before, "repopulated rune list duplicated overlays")

        owner.Runes = nil
        OldRunesUI.RefreshAll()
        FlushTimers()
        assertEqual(runes[1].overlay.shown, false, "missing rune list retained stale overlays")

        owner.Runes = runes
        OldRunesUI.RefreshAll()
        FlushTimers()
    end },
    { "combat", function()
        local oldPRDOwner = PersonalResourceDisplayFrame.classFrame
        local before = textureCount
        local oldRune = player.Runes[1]
        local hideNumbers = oldRune.Cooldown.hideNumbers

        inCombat = true
        SlashCmdList.OLDRUNES("timer")
        assertEqual(oldRune.Cooldown.hideNumbers, hideNumbers, "settings mutated native cooldown in combat")

        local newPRDOwner = NewRuneFrame()
        PersonalResourceDisplayFrame.classFrame = newPRDOwner
        PersonalResourceDisplayFrame:SetupClassBar()
        assertEqual(oldPRDOwner.Runes[1].overlay.shown, true, "PRD replacement hid old overlay in combat")
        assertEqual(textureCount, before, "PRD replacement allocated textures in combat")

        oldRune.lastRuneState.runeReady = false
        player:UpdateRunes(false)
        assertEqual(oldRune.overlay.vertex[1], 0.4, "combat ready-state update was lost")

        player.Runes[1] = NewRune(1)
        player:UpdateRunes(false)
        assertEqual(oldRune.overlay.shown, true, "rune replacement released presentation in combat")
        assertEqual(textureCount, before, "rune replacement allocated an overlay in combat")
        assertEqual(PendingTimerCount(), 0, "combat refresh scheduled readiness retries")

        inCombat = false
        eventFrame.scripts.OnEvent(eventFrame, "PLAYER_REGEN_ENABLED")
        FlushTimers()
        assertEqual(oldRune.overlay.shown, false, "post-combat cleanup missed replaced rune")
        assertEqual(oldRune.Rune_Grad.shown, true, "post-combat cleanup did not restore native art")
        assertEqual(newPRDOwner.Runes[1].overlay.shown, true, "post-combat PRD was not discovered")
        assertEqual(player.Runes[1].Cooldown.hideNumbers, not OldRunesDB.showTimerNumbers,
            "post-combat refresh lost the desired setting")
    end },
    { "timers", function()
        FlushTimers()
        local cancelsBefore = timerCancelCount
        OldRunesUI.RefreshAll()
        assertEqual(timerCancelCount, cancelsBefore, "completed timer handles were retained")

        for _ = 1, 99 do
            OldRunesUI.RefreshAll()
        end
        assertEqual(PendingTimerCount(), 2, "refresh burst accumulated live timers")

        local stale = timerQueue[#timerQueue]
        OldRunesUI.RefreshAll()
        stale.callback()
        assertEqual(PendingTimerCount(), 2, "stale callback interfered with current timers")

        FlushTimers()
        assertEqual(PendingTimerCount(), 0, "readiness timers did not terminate")
    end },
    { "stale_prd", function()
        local oldOwner = PersonalResourceDisplayFrame
        PersonalResourceDisplayFrame = {
            classFrame = NewRuneFrame(),
            SetupClassBar = function() end,
            SetHideClassInfo = function() end,
        }
        OldRunesUI.RefreshAll()
        FlushTimers()

        oldOwner:SetupClassBar()
        oldOwner:SetHideClassInfo()
        assertEqual(PendingTimerCount(), 0, "retired PRD owner scheduled work")
    end },
    { "inaccessible", function()
        local rune = player.Runes[1]
        rune.IsForbidden = function() return true end
        local hide = rune.overlay.Hide
        rune.overlay.Hide = function()
            fail("release touched an inaccessible rune overlay")
        end

        player.Runes[1] = NewRune(1)
        player:UpdateRunes(false)

        rune.overlay.Hide = hide
        rune.IsForbidden = nil
        assertEqual(player.Runes[1].overlay.shown, true, "accessible replacement was not styled")
    end },
    { "brightness", function()
        local rune = player.Runes[1]
        local writes = 0
        local setColor = rune.overlay.SetVertexColor
        rune.overlay.SetVertexColor = function(self, ...)
            writes = writes + 1
            setColor(self, ...)
        end

        for _ = 1, 50 do
            player:UpdateRunes(false)
        end
        assertEqual(writes, 0, "unchanged readiness rewrote overlay brightness")

        rune.lastRuneState.runeReady = not rune.lastRuneState.runeReady
        player:UpdateRunes(false)
        assertEqual(writes, 1, "readiness transition did not update brightness once")
        rune.overlay.SetVertexColor = setColor
    end },
    { "combat_mixed", function()
        OldRunesUI.SetRuneStyle("MIXED")
        OldRunesUI.RefreshAll()
        FlushTimers()

        local rune = player.Runes[1]
        inCombat = true
        rune.layoutIndex = 6
        player:UpdateRunes(false)
        assertEqual(rune.overlay.path, unholy, "mixed art stopped following native slots in combat")

        OldRunesUI.SetRuneStyle("DEATH")
        OldRunesUI.RefreshAll()
        rune.layoutIndex = 3
        player:UpdateRunes(false)
        assertEqual(rune.overlay.path, frost, "pending style interrupted the applied combat style")

        inCombat = false
        eventFrame.scripts.OnEvent(eventFrame, "PLAYER_REGEN_ENABLED")
        FlushTimers()
        assertEqual(rune.overlay.path, death, "pending style did not apply after combat")
    end },
}

local matched = selectedRegression == nil
for _, regression in ipairs(regressions) do
    if not selectedRegression or selectedRegression == regression[1] then
        matched = true
        regression[2]()
        FlushTimers()
        io.write("PASS ", regression[1], "\n")
    end
end

if not matched then
    fail("unknown regression: " .. tostring(selectedRegression))
end

io.write("PASS core\n")
