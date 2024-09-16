--------------------------
-- Initialize Variables --
--------------------------

UpExperienceBar = {}
UpExperienceBar.name = "UpExperienceBar"
UpExperienceBar.configVersion = 1
UpExperienceBar.saveData = {}
UpExperienceBar.defaults = {
    enabled = true
}

---------------------
--  OnAddOnLoaded  --
---------------------

function OnAddOnLoaded(event, addonName)
    if addonName ~= UpExperienceBar.name then
        return
    end
    UpExperienceBar:Initialize()
end

--------------------------
--  Initialize Function --
--------------------------

function UpExperienceBar:Initialize()
    -- Handle Save Data
    self.saveData = ZO_SavedVars:New(self.name .. "Data", self.configVersion, nil, self.defaults)
    self:RepairSaveData()  -- Ensure saved data is initialized

    -- Handle Startup
    if self.saveData.enabled == true then
        self:Enable()
    end

    -- Unregister the addon loaded event
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
end

--------------------------
--  Repair Save Data --
--------------------------

function UpExperienceBar:RepairSaveData()
    -- Ensure saved data uses default values where necessary
    for key, value in pairs(self.defaults) do
        if self.saveData[key] == nil then
            self.saveData[key] = value
        end
    end
end

------------------------
--  Process Command Arguments --
------------------------

-- Function to process arguments from slash commands
function UpExperienceBar:Arguments(args)
    local arguments = {}
    local searchResult = { string.match(args,"^(%S*)%s*(.-)$") }
    for i,v in pairs(searchResult) do
        if (v ~= nil and v ~= "") then
            arguments[i] = string.lower(v)
        end
    end
    return arguments
end

------------------------
-- Core Functionality --
------------------------

-- Use the existing player XP bar and make it visible permanently
function UpExperienceBar:UseExistingXPBar()
    -- Ensure the player progress bar exists
    if ZO_PlayerProgress then
        -- Make the XP bar permanently visible by adding it to the HUD scene
        SCENE_MANAGER:GetScene("hud"):AddFragment(PLAYER_PROGRESS_BAR_FRAGMENT)
        SCENE_MANAGER:GetScene("hud"):AddFragment(PLAYER_PROGRESS_BAR_CURRENT_FRAGMENT)
        
        -- Create the percentage label with a unique name
        local labelName = "XPBarPercentLabel" .. tostring(GetTimeStamp())
        self.xpLabel = WINDOW_MANAGER:CreateControl(labelName, ZO_PlayerProgress, CT_LABEL)
        self.xpLabel:SetFont("ZoFontGame")
        self.xpLabel:SetColor(1, 1, 1, 1) -- White color
        self.xpLabel:SetAnchor(CENTER, ZO_PlayerProgress, CENTER, 0, 0) -- Center the label on the bar
        self.xpLabel:SetText("0%")

        -- Create the XP progress label below the XP bar
        local progressLabelName = "XPBarProgressLabel" .. tostring(GetTimeStamp())
        self.xpProgressLabel = WINDOW_MANAGER:CreateControl(progressLabelName, ZO_PlayerProgress, CT_LABEL)
        self.xpProgressLabel:SetFont("ZoFontGame")
        self.xpProgressLabel:SetColor(1, 1, 1, 1) -- White color
        self.xpProgressLabel:SetAnchor(TOP, ZO_PlayerProgress, BOTTOM, 0, 5) -- Position it below the XP bar
        self.xpProgressLabel:SetText("XP: 0 / 0")
    end
end

-- Update the XP bar percentage label and XP progress label
function UpExperienceBar:UpdateXPBar()
    -- Check if the label has been created
    if not self.xpLabel or not self.xpProgressLabel then
        return
    end

    -- Get current and maximum XP values
    local currentXP = GetUnitXP("player")
    local maxXP = GetUnitXPMax("player")

    -- Check if values are valid
    if currentXP == nil or maxXP == nil then
        return
    end

    -- Calculate the XP percentage
    local xpPercent = (currentXP / maxXP) * 100

    -- Set color based on the percentage
    if xpPercent <= 40 then
        self.xpLabel:SetColor(1, 0, 0, 1) -- Red
    elseif xpPercent <= 80 then
        self.xpLabel:SetColor(1, 1, 0, 1) -- Yellow
    else
        self.xpLabel:SetColor(0, 1, 0, 1) -- Green
    end

    -- Update the percentage label
    self.xpLabel:SetText(string.format("%.1f%%", xpPercent)) -- Display with one decimal point

    -- Update the XP progress label
    local xpRemaining = maxXP - currentXP
    self.xpProgressLabel:SetText(string.format("XP: %d / %d (Remaining: %d)", currentXP, maxXP, xpRemaining))
end

-- Enable the XP bar and make it visible
function UpExperienceBar:Enable()
    -- Use the existing XP bar
    self:UseExistingXPBar()

    -- Update the XP bar on load
    self:UpdateXPBar()
end

----------------------
--  Register Events --
----------------------

-- Register the addon loaded event
EVENT_MANAGER:RegisterForEvent(UpExperienceBar.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

-- Register for XP update events to update the percentage label
EVENT_MANAGER:RegisterForEvent(UpExperienceBar.name, EVENT_EXPERIENCE_UPDATE, function()
    UpExperienceBar:UpdateXPBar()
end)

------------------------
--  Register Commands --
------------------------

SLASH_COMMANDS["/expbar"] = function (args)
    local arguments = UpExperienceBar:Arguments(args)
    if next(arguments) == nil or arguments[1] == "help" then
        d("--------------------------------------------------")
        d("UpExperienceBar Commands")
        d("--------------------------------------------------")
        d("help - This information")
        d("enable - Enable the experience bar")
        d("disable - Disable the experience bar")
        d("--------------------------------------------------")
    elseif arguments[1] == "enable" then
        UpExperienceBar:Enable()
    elseif arguments[1] == "disable" then
        ZO_PlayerProgress:SetHidden(true)
    else
        d("Command not known: " .. arguments[1])
    end
end
