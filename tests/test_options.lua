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

_G.UnitClass = function()
    return "Death Knight", "DEATHKNIGHT", 6
end

local function NewFontString()
    local font = { text = "" }
    function font:SetPoint() end
    function font:SetJustifyH() end
    function font:SetText(value) self.text = value end
    return font
end

local frames = {}
local function NewFrame(frameType)
    local frame = {
        frameType = frameType,
        scripts = {},
        checked = false,
    }

    function frame:SetPoint() end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    function frame:RegisterEvent() end
    function frame:UnregisterAllEvents() end
    function frame:CreateFontString() return NewFontString() end
    function frame:SetChecked(value) self.checked = value == true end
    function frame:GetChecked() return self.checked end

    if frameType == "CheckButton" then
        frame.Text = NewFontString()
    end

    frames[#frames + 1] = frame
    return frame
end

_G.CreateFrame = function(frameType)
    return NewFrame(frameType)
end

_G.GameTooltip = {
    SetOwner = function() end,
    SetText = function() end,
    Show = function() end,
    Hide = function() end,
}

local registeredCategory
_G.Settings = {
    RegisterCanvasLayoutCategory = function(panel, name)
        assertEqual(name, "Old Runes", "settings category name changed")
        return {
            panel = panel,
            GetID = function() return 7 end,
        }
    end,
    RegisterAddOnCategory = function(category)
        registeredCategory = category
    end,
}

local refreshCount = 0
_G.OldRunesDB = {
    showTimerNumbers = true,
    showCooldownSpiral = false,
    oldPersonalResourceDisplay = true,
    runeStyle = "SPEC",
}

_G.OldRunesUI = {
    L = {
        ADDON_NAME = "Old Runes",
        OPT_TIMER_LABEL = "Timer",
        OPT_SPIRAL_LABEL = "Spiral",
        OPT_PRD_LABEL = "PRD",
        OPT_STYLE_LABEL = "Style",
        OPT_STYLE_SPEC_LABEL = "Spec",
        OPT_STYLE_MIXED_LABEL = "Mixed",
        OPT_STYLE_DEATH_LABEL = "Death",
        OPT_STYLE_SPECLESS_LABEL = "Specless",
    },
    RUNE_STYLE_SPEC = "SPEC",
    RUNE_STYLE_MIXED = "MIXED",
    RUNE_STYLE_DEATH = "DEATH",
    RUNE_STYLE_SPECLESS = "SPECLESS",
    EnsureDBDefaults = function() end,
    GetRuneStyle = function() return OldRunesDB.runeStyle end,
    SetRuneStyle = function(style)
        OldRunesDB.runeStyle = style
        return true
    end,
    RefreshAll = function()
        refreshCount = refreshCount + 1
    end,
}

assert(loadfile("Options.lua"))("OldRunes", {})

assertTrue(registeredCategory ~= nil, "settings category was not registered")
assertEqual(OldRunesUI.settingsCategoryID, 7, "settings category ID was not retained")
assertTrue(OldRunesUI.optionsPanel ~= nil, "options panel was not exported")

OldRunesUI.optionsPanel.scripts.OnShow()

local timer
local spiral
local prd
local mixed
for i = 1, #frames do
    local frame = frames[i]
    if frame.Text then
        if frame.Text.text == "Timer" then timer = frame end
        if frame.Text.text == "Spiral" then spiral = frame end
        if frame.Text.text == "PRD" then prd = frame end
        if frame.Text.text == "Mixed" then mixed = frame end
        assertTrue(frame.Text.text ~= "Reverse", "removed reverse option is still visible")
    end
end

assertTrue(timer and spiral and prd and mixed, "expected controls were not created")
assertEqual(timer.checked, true, "timer checkbox did not load DB state")
assertEqual(spiral.checked, false, "spiral checkbox did not load DB state")
assertEqual(prd.checked, true, "PRD checkbox did not load DB state")

local before = refreshCount
timer.checked = false
timer.scripts.OnClick(timer)
assertEqual(OldRunesDB.showTimerNumbers, false, "timer click did not update DB")
assertEqual(refreshCount, before + 1, "timer click did not refresh runtime")

mixed.scripts.OnClick(mixed)
assertEqual(OldRunesDB.runeStyle, "MIXED", "style click did not update DB")
assertEqual(mixed.checked, true, "selected style checkbox was not restored")

io.write("PASS options\n")
