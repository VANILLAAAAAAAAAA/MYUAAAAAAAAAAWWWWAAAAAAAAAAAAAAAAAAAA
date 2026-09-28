-- New example script written by wally
-- You can suggest changes with a pull request or something

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()


local Window = Library:CreateWindow({
    Title = 'BY UNKER AND LELOUCH, WITH THANKS TO BIG 30, OTF JAM AND JORDAN',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

Window.ShowInToggleKeybind = false

-- CALLBACK NOTE:
-- Passing in callback functions via the initial element parameters (i.e. Callback = function(Value)...) works
-- HOWEVER, using Toggles/Options.INDEX:OnChanged(function(Value) ... ) is the RECOMMENDED way to do this.
-- I strongly recommend decoupling UI code from logic code. i.e. Create your UI elements FIRST, and THEN setup :OnChanged functions later.

-- You do not have to set your tabs & groups up this way, just a prefrence.
local Tabs = {
    -- Creates a new tab titled Main
    Main = Window:AddTab('Main'),
    ESP = Window:AddTab('ESP'),
    Nuclear = Window:AddTab('Nuclear'),
	PlayerInfo = Window:AddTab('Player Info'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

--TeamSettings
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local TeamSettings = workspace:WaitForChild("TeamSettings")
local TeamsFolder = workspace:WaitForChild("Teams")

local RunService = game:GetService("RunService")
local player = LocalPlayer

-- Shared cache: maps instance → team folder under TeamsFolder.
-- Weak keys so entries get garbage-collected when the instance is destroyed.
TeamFolderCache = setmetatable({}, {__mode = "k"})

local function resolveTeamFolder(instance)
    local cached = TeamFolderCache[instance]
    if cached and cached.Parent then
        return cached
    end
    local obj = instance
    while obj and obj.Parent ~= TeamsFolder do
        obj = obj.Parent
    end
    if obj then
        TeamFolderCache[instance] = obj
    end
    return obj
end

-- ESP TAB GROUPBOXES

-- TOP LEFT: Highlight Control
local ESP_Control = Tabs.ESP:AddLeftGroupbox('HIGHLIGHT CONTROL')

-- Remaining LEFT SIDE groupboxes
local ESP_Soldiers   = Tabs.ESP:AddLeftGroupbox('SOLDIERS')
local ESP_Air        = Tabs.ESP:AddLeftGroupbox('AIR')
local ESP_Tanks      = Tabs.ESP:AddLeftGroupbox('TANKS')
local ESP_Navy       = Tabs.ESP:AddLeftGroupbox('NAVY')

-- RIGHT SIDE
local ESP_ProdBuilds = Tabs.ESP:AddRightGroupbox('PRODUCTION BUILDINGS')
local ESP_Buildings  = Tabs.ESP:AddRightGroupbox('BUILDINGS')

-- Master toggle
ESP_Control:AddToggle('EnableHighlighter', {
    Text = 'Enable Highlighter',
    Default = false
})

-- Highlight mode
ESP_Control:AddDropdown('HighlightMode', {
    Values = { 'RGB', 'Team Color', 'Custom' },
    Default = 'Team Color',
    Multi = false,
    Text = 'Highlight Mode'
})

-- Custom colours (separate fill and outline)
ESP_Control:AddLabel('Custom Fill'):AddColorPicker('HighlightCustomFillColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'Custom Fill Colour'
})
ESP_Control:AddLabel('Custom Outline'):AddColorPicker('HighlightCustomOutlineColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Custom Outline Colour'
})

-- Fill transparency
ESP_Control:AddSlider('HighlightTransparency', {
    Text = 'Fill Transparency',
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false
})

-- Outline thickness
ESP_Control:AddSlider('HighlightOutlineThickness', {
    Text = 'Outline Thickness',
    Default = 1,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false
})

-- RGB Speed
ESP_Control:AddSlider('HighlightRGBSpeed', {
    Text = 'RGB Speed',
    Default = 1,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Compact = false
})

-- RGB Smoothness (lower = smoother, controls update interval in seconds)
ESP_Control:AddSlider('HighlightRGBSmoothness', {
    Text = 'RGB Smoothness',
    Default = 0.01,
    Min = 0.005,
    Max = 0.1,
    Rounding = 3,
    Compact = false
})


-- Global RGB colour provider – used by highlighter, Nuke ESP, Silo ESP, and Predictor
function getGlobalRGBColor()
    local speed = Options.HighlightRGBSpeed and Options.HighlightRGBSpeed.Value or 1
    local hue = (tick() * speed) % 1
    return Color3.fromHSV(hue, 1, 1)
end


-- HELPER: create a unit toggle without colour pickers
local function CreateESPUnitToggle(groupbox, idPrefix, displayName)
    groupbox:AddToggle(idPrefix .. "_Enabled", {
        Text = displayName,
        Default = false
    })
end

-- TEAM CHECKS PER GROUPBOX
ESP_Soldiers:AddToggle('ESP_Soldiers_TeamCheck', { Text = 'Team Check', Default = true })
ESP_Soldiers:AddDivider()
ESP_Air:AddToggle('ESP_Air_TeamCheck', { Text = 'Team Check', Default = true })
ESP_Air:AddDivider()
ESP_Tanks:AddToggle('ESP_Tanks_TeamCheck', { Text = 'Team Check', Default = true })
ESP_Tanks:AddDivider()
ESP_Navy:AddToggle('ESP_Navy_TeamCheck', { Text = 'Team Check', Default = true })
ESP_Navy:AddDivider()
ESP_ProdBuilds:AddToggle('ESP_Prod_TeamCheck', { Text = 'Team Check', Default = true })
ESP_ProdBuilds:AddDivider()
ESP_Buildings:AddToggle('ESP_Buildings_TeamCheck', { Text = 'Team Check', Default = true })
ESP_Buildings:AddDivider()

-- SOLDIERS
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_AntiAir', 'Anti-Air Soldier')
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_Construction', 'Construction Soldier')
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_Hovercraft', 'Hovercraft')
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_Juggernaut', 'Juggernaut')
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_Medic', 'Medic')
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_Sniper', 'Sniper')

-- AIR
CreateESPUnitToggle(ESP_Air, 'ESP_Air_Helicopter', 'Helicopter')
CreateESPUnitToggle(ESP_Air, 'ESP_Air_Mothership', 'Mothership')
CreateESPUnitToggle(ESP_Air, 'ESP_Air_SpaceFighter', 'Space Fighter')
CreateESPUnitToggle(ESP_Air, 'ESP_Air_StealthBomber', 'Stealth Bomber')
CreateESPUnitToggle(ESP_Air, 'ESP_Air_TransportPlane', 'Transport Plane')

-- TANKS
CreateESPUnitToggle(ESP_Tanks, 'ESP_Tank_AntiAir', 'Anti-Air Tank')
CreateESPUnitToggle(ESP_Tanks, 'ESP_Tank_Explosive', 'Explosive Tank')
CreateESPUnitToggle(ESP_Tanks, 'ESP_Tank_Heavy', 'Heavy Tank')

-- NAVY
CreateESPUnitToggle(ESP_Navy, 'ESP_Navy_AircraftCarrier', 'Aircraft Carrier')
CreateESPUnitToggle(ESP_Navy, 'ESP_Navy_TransportShip', 'Transport Ship')

-- PRODUCTION BUILDINGS
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_Airport', 'Airport')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_Barracks', 'Barracks')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_Fort', 'Fort')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_Shipyard', 'Shipyard')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_SpaceLink', 'Space Link')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_TankFactory', 'Tank Factory')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_NuclearPlant', 'Nuclear Plant')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_PowerPlant', 'Power Plant')

-- BUILDINGS
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_AntiAirTurret', 'Anti-Air Turret')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_CommandCenter', 'Command Center')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_Headquarters', 'Headquarters')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_NavalHouse', 'Naval House')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_PlaneHouse', 'Plane House')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_ShieldGen', 'Shield Generator')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_SoldierHouse', 'Soldier House')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_TankHouse', 'Tank House')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_Turret', 'Turret')

-- Building Notifications GROUPBOX FOR BUILDINGS
local NotifyGroup = Tabs.Main:AddRightGroupbox('Building Notifications')

NotifyGroup:AddToggle('NotifyBuildings', {
    Text = 'Notify Building Placements',
    Default = false
})

NotifyGroup:AddToggle('TeamCheck', {
    Text = 'Only Enemy Teams',
    Default = true
})

NotifyGroup:AddDivider()

NotifyGroup:AddToggle('Notify_Airport', { Text = 'Airport', Default = true })
NotifyGroup:AddToggle('Notify_Barracks', { Text = 'Barracks', Default = true })
NotifyGroup:AddToggle('Notify_Fort', { Text = 'Fort', Default = true })
NotifyGroup:AddToggle('Notify_Shipyard', { Text = 'Naval Shipyard', Default = true })
NotifyGroup:AddToggle('Notify_Nuke', { Text = 'Nuclear Silo', Default = true })
NotifyGroup:AddToggle('Notify_ShieldGen', { Text = 'Shield Generator', Default = true })
NotifyGroup:AddToggle('Notify_SpaceLink', { Text = 'Space Link', Default = true })
NotifyGroup:AddToggle('Notify_TankFactory', { Text = 'Tank Factory', Default = true })




function GetMyTeamColor()
    return LocalPlayer.TeamColor and LocalPlayer.TeamColor.Name
end

function GetMyTeamSettingsFolder()
    local myColor = GetMyTeamColor()
    if not myColor then return nil end
    return TeamSettings:FindFirstChild(myColor)
end

function GetMyAlliedColors()
    local folder = GetMyTeamSettingsFolder()
    if not folder then return {} end

    local alliesFolder = folder:FindFirstChild("Allies")
    if not alliesFolder then return {} end

    local allies = {}
    for _, ally in ipairs(alliesFolder:GetChildren()) do
        table.insert(allies, ally.Name)
    end

    return allies
end

function IsEnemyTeamColor(colorName)
    local myColor = GetMyTeamColor()
    local allies = GetMyAlliedColors()

    if colorName == myColor then
        return false
    end

    for _, allyColor in ipairs(allies) do
        if allyColor == colorName then
            return false
        end
    end

    return true
end



ActiveDisplays = ActiveDisplays or {}

local HealthConnections = {}
DirtyBuildings = DirtyBuildings or {} -- [building] = true

local function MarkBuildingDirty(building)
    if ActiveDisplays[building] then
        DirtyBuildings[building] = true
    end
end


-- ============================================================
-- UI LAYOUT CONSTANTS (no scaling, use UIScale only)
-- ============================================================
local BASE_HP_BAR_WIDTH = 480
local BASE_HP_BAR_HEIGHT = 32
local BASE_ROW_HEIGHT = 80
local BASE_PADDING = 8
local BASE_TEXT_SIZE = 75
local BASE_CONTAINER_WIDTH = 800
local PROGRESS_BAR_WIDTH = 400
local PROGRESS_BAR_HEIGHT = 24

-- Desired pixel density (pixels per stud)
local PIXELS_PER_STUD = 400

-- Maximum content size (in pixels) we want to fit without clipping
local CANVAS_WIDTH = 1000
local CANVAS_HEIGHT = 2000

-- Part size derived to match canvas aspect ratio, keeping pixel density uniform
local PART_SIZE = Vector3.new(
    CANVAS_WIDTH / PIXELS_PER_STUD,
    CANVAS_HEIGHT / PIXELS_PER_STUD,
    1
)  -- ≈ Vector3.new(2.5, 5, 1)


local function CalculateRequiredHeight(garrisonCount, productionCount)
    local mode = GARRISON_MODE or "Detailed"
    local prodMode = Options.ProductionMode and Options.ProductionMode.Value or "Detailed"
    local garrisonRowHeight = (mode == "Simple") and (BASE_ROW_HEIGHT * 0.6) or BASE_ROW_HEIGHT
    local productionRowHeight = BASE_ROW_HEIGHT * 0.7

    local height = 0
    if garrisonCount > 0 then
        height = height + garrisonCount * garrisonRowHeight
        height = height + (garrisonCount - 1) * BASE_PADDING
    end
    if productionCount > 0 then
        height = height + productionCount * productionRowHeight
        height = height + (productionCount - 1) * BASE_PADDING
        height = height + PROGRESS_BAR_HEIGHT + 8
    end
    height = height + 20
    return math.max(height, 100)
end


-- ============================================================
-- === GARRISON VIEW GROUPBOX (FINAL ORDERED VERSION)        ===
-- ============================================================

local GarrisonBox = Tabs.Main:AddRightGroupbox('Garrison View')

---------------------------------------------------------------
-- 1. GARRISON VIEW ON/OFF
---------------------------------------------------------------
GarrisonBox:AddToggle('GarrisonViewEnabled', {
    Text = 'Garrison View',
    Default = true,
    Tooltip = 'Enable or disable the entire garrison UI'
}):OnChanged(function(val)
    GARRISON_VIEW_ENABLED = val
end)
GARRISON_VIEW_ENABLED = true

---------------------------------------------------------------
-- TEAM COLORED TEXT TOGGLE
---------------------------------------------------------------
GarrisonBox:AddToggle('GarrisonTeamColors', {
    Text = 'Team Colored Text',
    Default = false,
    Tooltip = 'Color unit names based on team'
}):OnChanged(function(val)
    GARRISON_TEAM_COLORS = val

    -- Mark all displays dirty so they rebuild with new color
    for building in pairs(ActiveDisplays or {}) do
        MarkBuildingDirty(building)
    end
end)
GARRISON_TEAM_COLORS = false

---------------------------------------------------------------
-- 2. IGNORE TARGET (MULTISELECT DROPDOWN)
---------------------------------------------------------------
GarrisonBox:AddDropdown('IgnoreTargets', {
    Values = { 'Self', 'Own Team' },
    Default = {},
    Multi = true,
    Text = 'Ignore Target',
    Tooltip = 'Choose which targets to ignore'
}):OnChanged(function(selected)
    IGNORE_SELF = selected['Self'] == true
    IGNORE_TEAM = selected['Own Team'] == true
end)
IGNORE_SELF = false
IGNORE_TEAM = false

---------------------------------------------------------------
-- 3. MODE (SIMPLE / DETAILED)
---------------------------------------------------------------
GarrisonBox:AddDropdown('GarrisonMode', {
    Values = { 'Simple', 'Detailed' },
    Default = 'Detailed',
    Multi = false,
    Text = 'Mode',
    Tooltip = 'Choose how much information to show'
}):OnChanged(function(val)
    GARRISON_MODE = val

    -- Mark all displays dirty so they rebuild with new mode and resized canvas
    for building in pairs(ActiveDisplays or {}) do
        MarkBuildingDirty(building)
    end
end)

---------------------------------------------------------------
-- 4. DISTANCE CHECK ON/OFF
---------------------------------------------------------------
GarrisonBox:AddToggle('DistanceCheckEnabled', {
    Text = 'Distance Check',
    Default = false,
    Tooltip = 'Hide garrison UI for buildings beyond the distance'
}):OnChanged(function(val)
    DISTANCE_CHECK_ENABLED = val
end)
DISTANCE_CHECK_ENABLED = false

---------------------------------------------------------------
-- 4b. DISTANCE SLIDER (0–500)
---------------------------------------------------------------
GarrisonBox:AddSlider('MaxDistance', {
    Text = 'Max Distance',
    Default = 250,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Compact = false
}):OnChanged(function(val)
    MAX_DISTANCE = val
end)
MAX_DISTANCE = 250

---------------------------------------------------------------
-- 5. DISABLE WHEN NEARBY ON/OFF
---------------------------------------------------------------
GarrisonBox:AddToggle('DisableNearby', {
    Text = 'Disable When Nearby',
    Default = false,
    Tooltip = 'Hide UI when you are too close to the building'
}):OnChanged(function(val)
    DISABLE_NEARBY = val
end)
DISABLE_NEARBY = false

---------------------------------------------------------------
-- 5b. NEARBY SLIDER (0–100)
---------------------------------------------------------------
GarrisonBox:AddSlider('NearbyDistance', {
    Text = 'Nearby Distance',
    Default = 25,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false
}):OnChanged(function(val)
    NEARBY_DISTANCE = val
end)
NEARBY_DISTANCE = 25

---------------------------------------------------------------
-- 6. HEIGHT SLIDER
---------------------------------------------------------------
GarrisonBox:AddSlider('GarrisonHeight', {
    Text = 'Height Offset',
    Default = 0,
    Min = -30,
    Max = 30,
    Rounding = 1,
    Compact = false
}):OnChanged(function(val)
    CURRENT_HEIGHT_OFFSET = val
end)
CURRENT_HEIGHT_OFFSET = 0

---------------------------------------------------------------
-- 7. SCALE SLIDER
---------------------------------------------------------------
GarrisonBox:AddSlider('GarrisonScale', {
    Text = 'Scale',
    Default = 1.0,
    Min = 0.5,
    Max = 10.36,
    Rounding = 2,
    Compact = false
}):OnChanged(function(val)
    CURRENT_SCALE = val

    -- Update UIScale, part size, and canvas size for every display
    for building, display in pairs(ActiveDisplays or {}) do
        if display.uiScale then
            display.uiScale.Scale = val
        end
        if display.part then
            display.part.Size = Vector3.new(
                (CANVAS_WIDTH / PIXELS_PER_STUD) * val,
                ((display.requiredHeight or 100) / PIXELS_PER_STUD) * val,
                1
            )
        end
        if display.gui then
            display.gui.CanvasSize = Vector2.new(
                CANVAS_WIDTH * val,
                (display.requiredHeight or 100) * val
            )
        end
    end
end)

---------------------------------------------------------------
-- PRODUCTION VIEW CONTROLS
---------------------------------------------------------------
GarrisonBox:AddToggle('ProductionViewEnabled', {
    Text = 'Show Production',
    Default = false,
    Tooltip = 'Display production queue above/below garrison units'
})

GarrisonBox:AddDropdown('ProductionMode', {
    Values = { 'Simple', 'Detailed' },
    Default = 'Detailed',
    Multi = false,
    Text = 'Production Mode'
})

GarrisonBox:AddDropdown('ProductionPosition', {
    Values = { 'Above Garrison', 'Below Garrison' },
    Default = 'Below Garrison',
    Multi = false,
    Text = 'Production Position'
})





CURRENT_SCALE = 1.0



Toggles.ProductionViewEnabled:OnChanged(function(val)
    if val then
        -- Turn on: rebuild displays with production
        for building in pairs(ActiveDisplays or {}) do
            MarkBuildingDirty(building)
        end
    else
        -- Turn off: clear all production frames immediately
        for building, display in pairs(ActiveDisplays or {}) do
            if display.productionFrame then
                display.productionFrame:ClearAllChildren()
            end
            if display.productionConnections then
                for _, conn in ipairs(display.productionConnections) do
                    conn:Disconnect()
                end
                display.productionConnections = {}
            end
            display.activeProduction = nil
            if display.separator then
                display.separator.Visible = false
            end
            -- Resize the part after the function is defined (deferred)
            task.defer(function()
                if display and display.part then
                    UpdateDisplaySize(display)
                end
            end)
        end
    end
end)

Options.ProductionMode:OnChanged(function()
    for building in pairs(ActiveDisplays) do
        MarkBuildingDirty(building)
    end
end)

Options.ProductionPosition:OnChanged(function(val)
    for building, display in pairs(ActiveDisplays or {}) do
        if display.garrisonFrame and display.productionFrame then
            if val == 'Above Garrison' then
                display.productionFrame.LayoutOrder = 1
                display.garrisonFrame.LayoutOrder = 2
            else
                display.garrisonFrame.LayoutOrder = 1
                display.productionFrame.LayoutOrder = 2
            end
        end
        MarkBuildingDirty(building)
    end
end)




-- TEAM COLOR FOR GARRISON TEXT
local function GetTeamColorForFolder(teamFolder)
    if not teamFolder then
        return Color3.new(1, 1, 1)
    end

    -- Try BrickColor
    local ok, brick = pcall(BrickColor.new, teamFolder.Name)
    if ok and brick then
        return brick.Color
    end

    -- Try actual Teams
    local TeamsService = game:GetService("Teams")
    for _, team in ipairs(TeamsService:GetChildren()) do
        if team.Name == teamFolder.Name then
            if team.TeamColor then
                return team.TeamColor.Color
            end
        end

        if team.TeamColor and team.TeamColor.Name == teamFolder.Name then
            return team.TeamColor.Color
        end
    end

    return Color3.new(1, 1, 1)
end

-- ============================================================
-- === GARRISON SYSTEM — LINORIA-INTEGRATED VERSION         ===
-- ============================================================



-- Which buildings can have garrison UI
local Garrisonable = {
    ["Bunker"] = true,
    ["Headquarters"] = true,
    ["Command Center"] = true,
    ["Fort"] = true,
    ["Medi-Truck"] = true,
    ["Aircraft Carrier"] = true,
    ["Transport Ship"] = true,
    ["Transport Plane"] = true,
    ["Mothership"] = true,
    ["Helicopter"] = true
}



---------------------------------------------------------------
-- HEALTH BAR
---------------------------------------------------------------

local function MakeHealthBar(parent, current, max)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, BASE_HP_BAR_WIDTH, 0, BASE_HP_BAR_HEIGHT)
	bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bar.BorderColor3 = Color3.new(0, 0, 0)
	bar.BorderSizePixel = 2
	bar.Parent = parent

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(max > 0 and current/max or 0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    return bar, fill
end


local function HookBuildingMovement(display)
    local torso = display.torso
    if not torso then return end

    if display.movementConnection then
        display.movementConnection:Disconnect()
        display.movementConnection = nil
    end

    display.movementConnection = torso:GetPropertyChangedSignal("CFrame"):Connect(function()
        UpdateAllDisplays()
    end)
end

local function CreateDisplay(building, teamFolder)
    local torso = building:FindFirstChild("Torso")
    if not torso then return end

    local part = Instance.new("Part")
    part.Size = PART_SIZE * CURRENT_SCALE
    part.Transparency = 1   -- OLD (part.Transparency = 0.5)
    part.CanCollide = false
    part.CanQuery = false
    part.Anchored = true
    part.Parent = workspace

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    gui.CanvasSize = Vector2.new(CANVAS_WIDTH * CURRENT_SCALE, 100 * CURRENT_SCALE) -- initial small
    gui.Parent = part

    -- Store base sizes for scaling
    local basePartSize = PART_SIZE
    local baseCanvasSize = Vector2.new(CANVAS_WIDTH, CANVAS_HEIGHT)

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = CURRENT_SCALE
    uiScale.Parent = gui

    -- Main container anchored top-center, grows downward
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.AnchorPoint = Vector2.new(0.5, 0)
    mainContainer.Position = UDim2.new(0.5, 0, 0, 0)
    mainContainer.Size = UDim2.new(0, BASE_CONTAINER_WIDTH, 0, 0)
    mainContainer.AutomaticSize = Enum.AutomaticSize.Y
    mainContainer.BackgroundTransparency = 1
    mainContainer.Parent = gui

    local mainLayout = Instance.new("UIListLayout")
    mainLayout.FillDirection = Enum.FillDirection.Vertical
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    mainLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    mainLayout.Padding = UDim.new(0, 12)
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Parent = mainContainer

    -- Garrison frame
    local garrisonFrame = Instance.new("Frame")
    garrisonFrame.Name = "GarrisonFrame"
    garrisonFrame.Size = UDim2.new(1, 0, 0, 0)
    garrisonFrame.AutomaticSize = Enum.AutomaticSize.Y
    garrisonFrame.BackgroundTransparency = 1
    garrisonFrame.LayoutOrder = 1
    garrisonFrame.Parent = mainContainer

    local garrisonLayout = Instance.new("UIListLayout")
    garrisonLayout.FillDirection = Enum.FillDirection.Vertical
    garrisonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    garrisonLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    garrisonLayout.Padding = UDim.new(0, BASE_PADDING)
    garrisonLayout.Parent = garrisonFrame

    -- Production frame
    local productionFrame = Instance.new("Frame")
    productionFrame.Name = "ProductionFrame"
    productionFrame.Size = UDim2.new(1, 0, 0, 0)
    productionFrame.AutomaticSize = Enum.AutomaticSize.Y
    productionFrame.BackgroundTransparency = 1
    productionFrame.LayoutOrder = 2
    productionFrame.Parent = mainContainer
	
	    -- Separator (hidden by default)
    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, 0, 0, 2)
    separator.BackgroundColor3 = Color3.new(1, 1, 1)
    separator.BackgroundTransparency = 0.2
    separator.BorderSizePixel = 0
    separator.LayoutOrder = 1.5  -- between garrison (1) and production (2)
    separator.Visible = false
    separator.Parent = mainContainer
	
	
	
	

    local productionLayout = Instance.new("UIListLayout")
    productionLayout.FillDirection = Enum.FillDirection.Vertical
    productionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    productionLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    productionLayout.Padding = UDim.new(0, BASE_PADDING)
    productionLayout.Parent = productionFrame

    local ownerVal = building:FindFirstChild("Owner")

    ActiveDisplays[building] = {
        part = part,
        gui = gui,
        mainContainer = mainContainer,
        garrisonFrame = garrisonFrame,
        productionFrame = productionFrame,
        uiScale = uiScale,
        torso = torso,
        folder = torso:FindFirstChild("Garrisoned"),
        productionFolder = torso:FindFirstChild("Producing"),
        teamFolder = teamFolder,
        owner = ownerVal,
        productionConnections = {},
        queueOrder = {},
        activeProduction = nil,
		separator = separator,
        basePartSize = PART_SIZE,
        baseCanvasSize = Vector2.new(CANVAS_WIDTH, 100),
        requiredHeight = 100
    }

    -- Hook torso movement so the UI follows the building when it moves
    HookBuildingMovement(ActiveDisplays[building])

    -- defer actual UI build to the throttled loop
    MarkBuildingDirty(building)

    -- Cleanup when the building is removed
    building.AncestryChanged:Connect(function(_, parent)
        if not parent then
            local display = ActiveDisplays[building]
            if display then
                -- Disconnect production UI connections
                for _, conn in ipairs(display.productionConnections or {}) do
                    conn:Disconnect()
                end
                -- Disconnect hook connections (garrison + production folder hooks)
                for _, conn in ipairs(display.hookConnections or {}) do
                    conn:Disconnect()
                end
                -- Disconnect health connections
                if HealthConnections[building] then
                    for _, conn in ipairs(HealthConnections[building]) do
                        conn:Disconnect()
                    end
                    HealthConnections[building] = nil
                end
                -- Disconnect movement connection
                if display.movementConnection then
                    display.movementConnection:Disconnect()
                    display.movementConnection = nil
                end
                if display.part then
                    display.part:Destroy()
                end
                ActiveDisplays[building] = nil
            end
        end
    end)
end

---------------------------------------------------------------
-- UPDATE GARRISON DISPLAY (without scaling)
---------------------------------------------------------------
function UpdateGarrisonDisplay(building, units)
    local display = ActiveDisplays[building]
    if not display then return end

    HealthConnections[building] = HealthConnections[building] or {}
    for _, conn in ipairs(HealthConnections[building]) do
        conn:Disconnect()
    end
    HealthConnections[building] = {}

    local frame = display.garrisonFrame
    frame:ClearAllChildren()

    -- Add layout to stack rows vertically
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, BASE_PADDING)
    layout.Parent = frame

    -- SIMPLE MODE
    if GARRISON_MODE == "Simple" then
        local grouped = {}
        for _, unit in ipairs(units) do
            local name = unit.Name
            if name == "Construction Soldier" then
                name = "⚠ Construction Soldier ⚠"
            end
            grouped[name] = (grouped[name] or 0) + 1
        end

        local sorted = {}
        for name, count in pairs(grouped) do
            table.insert(sorted, { name = name, count = count })
        end
        table.sort(sorted, function(a, b) return a.name:lower() < b.name:lower() end)

        for _, entry in ipairs(sorted) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, BASE_ROW_HEIGHT * 0.6)
            row.BackgroundTransparency = 1
            row.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            if GARRISON_TEAM_COLORS then
                label.TextColor3 = GetTeamColorForFolder(display.teamFolder)
            else
                label.TextColor3 = Color3.new(1,1,1)
            end
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.TextStrokeTransparency = 0
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = BASE_TEXT_SIZE
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.Text = (entry.count > 1) and string.format("• %s (x%d)", entry.name, entry.count) or "• " .. entry.name
            label.Parent = row
        end
        return
    end

    -- DETAILED MODE
    table.sort(units, function(a, b)
        local nameA = a.Name
        local nameB = b.Name
        if nameA == "Construction Soldier" then nameA = "⚠ Construction Soldier ⚠" end
        if nameB == "Construction Soldier" then nameB = "⚠ Construction Soldier ⚠" end
        return nameA:lower() < nameB:lower()
    end)

    for _, unit in ipairs(units) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, BASE_ROW_HEIGHT)
        row.BackgroundTransparency = 1
        row.Parent = frame

        local hp = unit:FindFirstChild("Health")
        local maxhp = unit:FindFirstChild("MaxHealth")

        local hLayout = Instance.new("UIListLayout")
        hLayout.FillDirection = Enum.FillDirection.Horizontal
        hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        hLayout.Padding = UDim.new(0, BASE_PADDING)
        hLayout.Parent = row

        if hp and maxhp and hp:IsA("NumberValue") and maxhp:IsA("NumberValue") then
            local bar, fill = MakeHealthBar(row, hp.Value, maxhp.Value)
            local conn = hp:GetPropertyChangedSignal("Value"):Connect(function()
                if maxhp and maxhp.Value > 0 then
                    fill.Size = UDim2.new(math.clamp(hp.Value / maxhp.Value, 0, 1), 0, 1, 0)
                else
                    fill.Size = UDim2.new(0, 0, 1, 0)
                end
            end)
            table.insert(HealthConnections[building], conn)
        end

        local name = unit.Name
        if name == "Construction Soldier" then name = "⚠ Construction Soldier ⚠" end

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 450, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = GARRISON_TEAM_COLORS and GetTeamColorForFolder(display.teamFolder) or Color3.new(1,1,1)
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = BASE_TEXT_SIZE
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = "• " .. name
        label.Parent = row
    end
end

---------------------------------------------------------------
-- UPDATE PRODUCTION DISPLAY
---------------------------------------------------------------
local function BuildProductionRows(display)
    local frame = display.productionFrame
    frame:ClearAllChildren()

    -- Disconnect old production UI connections
    for _, conn in ipairs(display.productionConnections) do
        conn:Disconnect()
    end
    display.productionConnections = {}
    display.activeProduction = nil

    -- Add layout to stack rows vertically
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, BASE_PADDING)
    layout.Parent = frame

    local queue = display.queueOrder
    if #queue == 0 then return end

    local mode = Options.ProductionMode and Options.ProductionMode.Value or 'Detailed'

    -- Find active item (first with Progress > 0 and < 1)
    local activeItem = nil
    for _, item in ipairs(queue) do
        local prog = item:FindFirstChild("Progress")
        if prog and prog:IsA("NumberValue") and prog.Value > 0 and prog.Value < 1 then
            activeItem = item
            break
        end
    end
    if not activeItem and #queue > 0 then
        activeItem = queue[1]
    end

    -- Build rows depending on mode
    if mode == 'Simple' then
        local typeOrder = {}
        for _, item in ipairs(queue) do
            local itemName = item.Name
            if not typeOrder[itemName] then
                table.insert(typeOrder, itemName)
                typeOrder[itemName] = true
            end
        end

        for i = #typeOrder, 1, -1 do
            local typeName = typeOrder[i]
            local count = 0
            for _, qItem in ipairs(queue) do
                if qItem.Name == typeName then count = count + 1 end
            end

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, BASE_ROW_HEIGHT * 0.7)
            row.BackgroundTransparency = 1
            row.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            if GARRISON_TEAM_COLORS then
                label.TextColor3 = GetTeamColorForFolder(display.teamFolder)
            else
                label.TextColor3 = Color3.new(1,1,1)
            end
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.TextStrokeTransparency = 0
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = BASE_TEXT_SIZE
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.Text = (count > 1) and string.format("(x%d) %s", count, typeName) or typeName
            label.Parent = row
        end
    else
        for i = #queue, 1, -1 do
            local item = queue[i]
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, BASE_ROW_HEIGHT * 0.7)
            row.BackgroundTransparency = 1
            row.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            if GARRISON_TEAM_COLORS then
                label.TextColor3 = GetTeamColorForFolder(display.teamFolder)
            else
                label.TextColor3 = Color3.new(1,1,1)
            end
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.TextStrokeTransparency = 0
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = BASE_TEXT_SIZE
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.Text = item.Name
            label.Parent = row
        end
    end

    -- Progress bar for active item (below bottom row)
    if activeItem then
        local prog = activeItem:FindFirstChild("Progress")
        local pct = prog and prog.Value or 0

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, PROGRESS_BAR_WIDTH, 0, PROGRESS_BAR_HEIGHT)
        bar.AnchorPoint = Vector2.new(0.5, 0)
        bar.Position = UDim2.new(0.5, 0, 1, 8)
        bar.BackgroundColor3 = Color3.new(0,0,0)
        bar.BorderColor3 = Color3.new(0,0,0)
        bar.BorderSizePixel = 2
        bar.Parent = frame

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(math.clamp(pct,0,1), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0,255,0)
        fill.BorderSizePixel = 0
        fill.Parent = bar

        local remaining = Instance.new("Frame")
        remaining.Size = UDim2.new(1 - math.clamp(pct,0,1), 0, 1, 0)
        remaining.Position = UDim2.new(math.clamp(pct,0,1), 0, 0, 0)
        remaining.BackgroundColor3 = Color3.fromRGB(255,0,0)
        remaining.BorderSizePixel = 0
        remaining.Parent = bar

        display.activeProduction = {
            item = activeItem,
            fill = fill,
            remaining = remaining,
            bar = bar
        }

        local progressVal = prog
        if progressVal and progressVal:IsA("NumberValue") then
            local conn = progressVal:GetPropertyChangedSignal("Value"):Connect(function()
                if display.activeProduction and display.activeProduction.item == activeItem then
                    local newPct = progressVal.Value
                    display.activeProduction.fill.Size = UDim2.new(math.clamp(newPct,0,1), 0, 1, 0)
                    display.activeProduction.remaining.Size = UDim2.new(1 - math.clamp(newPct,0,1), 0, 1, 0)
                    display.activeProduction.remaining.Position = UDim2.new(math.clamp(newPct,0,1), 0, 0, 0)
                end
            end)
            table.insert(display.productionConnections, conn)
        end
    end
end


local function UpdateDisplaySize(display)
    local garrisonUnits = display.folder and display.folder:GetChildren() or {}
    local productionUnits = display.productionFolder and display.productionFolder:GetChildren() or {}
    local requiredHeight = CalculateRequiredHeight(#garrisonUnits, #productionUnits)
    display.requiredHeight = requiredHeight
    display.gui.CanvasSize = Vector2.new(CANVAS_WIDTH * CURRENT_SCALE, requiredHeight * CURRENT_SCALE)
    display.part.Size = Vector3.new(
        (CANVAS_WIDTH / PIXELS_PER_STUD) * CURRENT_SCALE,
        (requiredHeight / PIXELS_PER_STUD) * CURRENT_SCALE,
        1
    )

    -- Show separator only if both garrison and production have content
    local hasGarrison = #garrisonUnits > 0
    local hasProduction = Toggles.ProductionViewEnabled.Value and #productionUnits > 0
    if display.separator then
        display.separator.Visible = hasGarrison and hasProduction
    end
end


---------------------------------------------------------------
-- EVENT-BASED GARRISON VISIBILITY + POSITIONING (P3 MODE)
---------------------------------------------------------------

local CAMERA_UPDATE_HZ = 120 -- ~12 updates per second
local CAMERA_UPDATE_INTERVAL = 1 / CAMERA_UPDATE_HZ
local lastCamUpdate = 0

local lastCamCFrame = nil

-- Cache team info once per update
local function GetTeamContext()
    return GetMyTeamColor(), GetMyAlliedColors()
end

-- Apply visibility + position to ONE building
local function UpdateOneDisplay(display, camPos, myTeam, myAllies)
    local torso = display.torso
    if not torso or not torso.Parent then
        display.gui.Enabled = false
        return
    end

    local pos = torso.Position
    local dist = (camPos - pos).Magnitude

    -- read live settings from UI
    local distanceCheck   = Toggles.DistanceCheckEnabled.Value
    local maxDist         = Options.MaxDistance.Value
    local disableNearby   = Toggles.DisableNearby.Value
    local nearbyDist      = Options.NearbyDistance.Value
    local ignoreTable     = Options.IgnoreTargets.Value or {}
    local ignoreSelf      = ignoreTable["Self"] == true
    local ignoreTeam      = ignoreTable["Own Team"] == true
    local heightOffset    = Options.GarrisonHeight.Value

    -- DISTANCE CHECK
    if distanceCheck and dist > maxDist then
        display.gui.Enabled = false
        return
    end

    -- NEARBY CHECK
    if disableNearby and dist < nearbyDist then
        display.gui.Enabled = false
        return
    end

    -- IGNORE LOGIC
    if ignoreSelf or ignoreTeam then
        local buildingTeam = display.teamFolder and display.teamFolder.Name
        local isOwner = (buildingTeam == myTeam)

        local sameTeam = isOwner
        if not sameTeam and buildingTeam then
            for _, ally in ipairs(myAllies) do
                if ally == buildingTeam then
                    sameTeam = true
                    break
                end
            end
        end

        if ignoreSelf and isOwner then
            display.gui.Enabled = false
            return
        end

        if ignoreTeam and sameTeam and not isOwner then
            display.gui.Enabled = false
            return
        end
    end

    -- PASSED ALL CHECKS → SHOW + POSITION (keep upright, only yaw)
    -- PASSED ALL CHECKS → SHOW + POSITION (tilt with camera)
    display.gui.Enabled = true
    local partHeight = display.part.Size.Y
    display.part.CFrame = CFrame.new(
        pos + Vector3.new(0, 4 + heightOffset - partHeight/2, 0),
        camPos
    )
end


-- Update ALL displays (throttled, heals skin‑swapped buildings)
local function UpdateAllDisplays()
		if not Toggles.GarrisonViewEnabled.Value then
			for _, display in pairs(ActiveDisplays or {}) do
				display.gui.Enabled = false
			end
			return
		end

    if next(ActiveDisplays) == nil then
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local camPos = cam.CFrame.Position
    local myTeam, myAllies = GetTeamContext()
	

    -- Scan for any missing displayable buildings (garrison or production)
    local myTeamFolder = TeamsFolder:FindFirstChild(myTeam)
    if myTeamFolder then
        for _, building in ipairs(myTeamFolder:GetChildren()) do
            if building:IsA("Model") and not ActiveDisplays[building] then
                local torso = building:FindFirstChild("Torso")
                if torso then
                    local gFolder = torso:FindFirstChild("Garrisoned")
                    local pFolder = torso:FindFirstChild("Producing")
                    if gFolder or pFolder then
                        CreateDisplay(building, myTeamFolder)
                        if gFolder then Hook(building, gFolder, myTeamFolder) end
                        if pFolder then HookProduction(building, pFolder, myTeamFolder) end
                    end
                end
            end
        end
    end
	
	

    local deadBuildings = {}   -- set: building → true
    local healed = false

	for building, display in pairs(ActiveDisplays or {}) do
		-- 1) Building itself is gone (AncestryChanged cleanup will handle this too)
        if not building or not building.Parent then
            deadBuildings[building] = true
        else
            -- === TORSO HEAL ===
            local torso = display.torso
            local torsoValid = torso and torso.Parent and torso:IsDescendantOf(building)
            if not torsoValid then
                local newTorso = building:FindFirstChild("Torso")
                if newTorso and newTorso:IsA("BasePart") then
                    display.torso = newTorso
                    torso = newTorso
                    HookBuildingMovement(display)
                end
            end

            -- === GARRISON FOLDER HEAL ===
            -- Valid = exists AND is a descendant of the current torso
            local folderValid = display.folder
                and display.folder.Parent
                and torso
                and display.folder:IsDescendantOf(torso)
            if not folderValid and torso then
                local newGarrisoned = torso:FindFirstChild("Garrisoned")
                if newGarrisoned then
                    -- Disconnect old hooks tied to the previous folder
                    for _, conn in ipairs(display.hookConnections or {}) do
                        conn:Disconnect()
                    end
                    display.hookConnections = {}

                    display.folder = newGarrisoned
                    Hook(building, newGarrisoned, display.teamFolder)
                    MarkBuildingDirty(building)
                    healed = true
                end
                -- Do NOT mark as dead if newGarrisoned is nil.
                -- The building may just be mid-rebuild. We'll retry next frame.
            end

            -- === PRODUCTION FOLDER HEAL ===
            local prodValid = display.productionFolder
                and display.productionFolder.Parent
                and torso
                and display.productionFolder:IsDescendantOf(torso)
            if not prodValid and torso then
                local newProduction = torso:FindFirstChild("Producing")
                if newProduction and newProduction ~= display.productionFolder then
                    display.productionFolder = newProduction
                    HookProduction(building, newProduction, display.teamFolder)
                    MarkBuildingDirty(building)
                else
                    display.productionFolder = newProduction
                end
            end

            -- Update visibility / position if still alive
            if not deadBuildings[building] then
                UpdateOneDisplay(display, camPos, myTeam, myAllies)
            end
        end
    end
	
	

    -- Remove dead displays
    for building, _ in pairs(deadBuildings) do
        local display = ActiveDisplays[building]
        if display then
            if display.part then
                display.part:Destroy()
            end
            ActiveDisplays[building] = nil
        end
    end
end

---------------------------------------------------------------
-- CAMERA MOVEMENT EVENT (THROTTLED)
---------------------------------------------------------------

workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(function()
    local now = tick()
    if now - lastCamUpdate < CAMERA_UPDATE_INTERVAL then
        return
    end
    lastCamUpdate = now

    UpdateAllDisplays()
end)


---------------------------------------------------------------
-- SETTINGS CHANGE EVENTS
---------------------------------------------------------------

local function HookSettingRefresh()
    local function refresh()
        UpdateAllDisplays()
    end

    Options.GarrisonHeight:OnChanged(refresh)
    -- DO NOT hook GarrisonScale here (it already rebuilds UI)
    Toggles.GarrisonViewEnabled:OnChanged(refresh)
    Toggles.DistanceCheckEnabled:OnChanged(refresh)
    Toggles.DisableNearby:OnChanged(refresh)
    Options.MaxDistance:OnChanged(refresh)
    Options.NearbyDistance:OnChanged(refresh)
    Options.IgnoreTargets:OnChanged(refresh)
end

HookSettingRefresh()


---------------------------------------------------------------
-- THROTTLED UI UPDATE LOOP (ONCE PER HEARTBEAT, DIRTY ONLY)
---------------------------------------------------------------

local lastDisplayReposition = 0
local DISPLAY_REPOSITION_INTERVAL = 1 / 144

RunService.Heartbeat:Connect(function()
    -- Process dirty buildings (rebuild UI)
    if next(DirtyBuildings) ~= nil then
        for building, _ in pairs(DirtyBuildings) do
            local display = ActiveDisplays[building]
            if display then
                if display.folder then
                    UpdateGarrisonDisplay(building, display.folder:GetChildren())
                end
                if display.productionFolder and Toggles.ProductionViewEnabled.Value then
                    BuildProductionRows(display)
                end
                UpdateDisplaySize(display)
            end
            DirtyBuildings[building] = nil
        end
    end

    -- Ensure new/moved displays are positioned even if the camera is still.
    local now = tick()
    if now - lastDisplayReposition >= DISPLAY_REPOSITION_INTERVAL then
        lastDisplayReposition = now
        UpdateAllDisplays()
    end
end)

---------------------------------------------------------------
-- HOOK + INIT
---------------------------------------------------------------

local function Hook(building, folder, teamFolder)
    local display = ActiveDisplays[building]
    if not display then return end
    display.hookConnections = display.hookConnections or {}

    local function Refresh()
        MarkBuildingDirty(building)
    end

    Refresh()

    table.insert(display.hookConnections, folder.ChildAdded:Connect(function()
        task.defer(Refresh)
    end))

    table.insert(display.hookConnections, folder.ChildRemoved:Connect(function()
        task.defer(Refresh)
    end))
end



---------------------------------------------------------------
-- HOOK PRODUCTION FOLDER
---------------------------------------------------------------
local function HookProduction(building, productionFolder, teamFolder)
    local display = ActiveDisplays[building]
    if not display then return end
    display.hookConnections = display.hookConnections or {}

    display.queueOrder = {}
    for _, child in ipairs(productionFolder:GetChildren()) do
        table.insert(display.queueOrder, child)
    end
    table.sort(display.queueOrder, function(a,b) return a.Name < b.Name end)

    local function refresh()
        MarkBuildingDirty(building)
    end

    table.insert(display.hookConnections, productionFolder.ChildAdded:Connect(function(child)
        table.insert(display.queueOrder, child)
        task.defer(refresh)
    end))

    table.insert(display.hookConnections, productionFolder.ChildRemoved:Connect(function(child)
        for i, item in ipairs(display.queueOrder) do
            if item == child then
                table.remove(display.queueOrder, i)
                break
            end
        end
        task.defer(refresh)
    end))

    refresh()
end








-- ============================================================
-- === GARRISON BUILDING HOOK SYSTEM (STARTUP + RUNTIME)     ===
-- ============================================================

-- STARTUP SCAN (existing buildings)
for _, teamFolder in ipairs(TeamsFolder:GetChildren()) do
    for _, building in ipairs(teamFolder:GetChildren()) do
        if building:IsA("Model") then
            local torso = building:FindFirstChild("Torso")
            if torso then
                local gFolder = torso:FindFirstChild("Garrisoned")
                local pFolder = torso:FindFirstChild("Producing")
                if gFolder or pFolder then
                    CreateDisplay(building, teamFolder)
                    if gFolder then Hook(building, gFolder, teamFolder) end
                    if pFolder then HookProduction(building, pFolder, teamFolder) end
                end
            end
        end
    end
end




-- ==================================================
-- INSERT THE NEW DYNAMIC HOOK BLOCK RIGHT HERE
-- ==================================================

-- Dynamic hook: new buildings spawned after script start
local function AddBuilding(building, teamFolder)
    if not building:IsA("Model") then return end

    -- Wait for Torso
    local torso = nil
    for i = 1, 20 do
        task.wait(0.1)
        torso = building:FindFirstChild("Torso")
        if torso then break end
    end
    if not torso then return end

    -- Wait for either Garrisoned or Producing folder
    local gFolder = torso:FindFirstChild("Garrisoned")
    local pFolder = torso:FindFirstChild("Producing")
    for i = 1, 20 do
        task.wait(0.1)
        if not gFolder then gFolder = torso:FindFirstChild("Garrisoned") end
        if not pFolder then pFolder = torso:FindFirstChild("Producing") end
        if gFolder or pFolder then break end
    end

    if not gFolder and not pFolder then return end

    CreateDisplay(building, teamFolder)
    if gFolder then Hook(building, gFolder, teamFolder) end
    if pFolder then HookProduction(building, pFolder, teamFolder) end
end

-- Hook existing team folders for new buildings
for _, teamFolder in ipairs(TeamsFolder:GetChildren()) do
    teamFolder.ChildAdded:Connect(function(building)
        AddBuilding(building, teamFolder)
    end)
end

-- Hook team folders that are created later
TeamsFolder.ChildAdded:Connect(function(teamFolder)
    for _, building in ipairs(teamFolder:GetChildren()) do
        AddBuilding(building, teamFolder)
    end
    teamFolder.ChildAdded:Connect(function(building)
        AddBuilding(building, teamFolder)
    end)
end)





-- ============================================================
-- NUKE PREDICTOR (Reverse‑Apex) – with ping marker
-- ============================================================
local PredictorGroup = Tabs.Main:AddLeftGroupbox('Nuke Predictor')

PredictorGroup:AddToggle('PredictorEnabled', { Text = 'Enable Predictor', Default = true })
PredictorGroup:AddToggle('PathwayEnabled', { Text = 'Show Pathway', Default = false })
PredictorGroup:AddDropdown('PathwayDisappear', { Values = { 'On Apex', 'On Impact' }, Default = 'On Apex', Multi = false, Text = 'Pathway Disappears' })

-- Marker Color Mode
PredictorGroup:AddDropdown('MarkerColorMode', {
    Values = { 'Custom', 'RGB' },
    Default = 'Custom',
    Multi = false,
    Text = 'Marker Color Mode'
})

-- Marker custom colour (only used in Custom mode)
PredictorGroup:AddLabel('Marker Custom Color'):AddColorPicker('PredictorColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'Prediction Marker Custom'
})

-- Pathway colour
PredictorGroup:AddLabel('Pathway Color'):AddColorPicker('PathwayColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'Pathway Line Color'
})



PredictorGroup:AddSlider('PredictorStayTime', { Text = 'Stay Time (s)', Default = 0, Min = 0, Max = 10, Rounding = 0, Compact = false })

-- ------------------------------------------
-- PREDICTOR FUNCTIONS
-- ------------------------------------------
local function getSiloPosition(missile)
    local siloVal = missile:FindFirstChild("Silo")
    if siloVal and siloVal:IsA("ObjectValue") and siloVal.Value then
        local silo = siloVal.Value
        if silo:IsA("Model") then
            local torso = silo:FindFirstChild("Torso") or silo:FindFirstChildWhichIsA("BasePart")
            if torso then return torso.Position end
        end
    end
    return nil
end

local function getMarkerColor()
    local mode = Options.MarkerColorMode.Value
    if mode == 'RGB' then
        return getGlobalRGBColor()
    else
        return Options.PredictorColor and Options.PredictorColor.Value or Color3.new(1,0,0)
    end
end

-- Create the main predictor disc
local function createPredictorMarker(position, color)
    local part = Instance.new("Part")
    part.Name = "NukePredictor"
    part.Size = Vector3.new(1, 30, 30)
    part.Shape = Enum.PartType.Cylinder
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false          -- ← NEW: allows clicks to pass through
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new(color or getMarkerColor())
    part.Transparency = 0.8
    part.CastShadow = false
    local ray = workspace:Raycast(position + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0))
    local groundY = ray and ray.Position.Y or 0
    part.CFrame = CFrame.new(position.X, groundY + 0.5, position.Z) * CFrame.Angles(0, 0, math.rad(90))
    part.Parent = workspace
    return part
end


local function createPathway(startPos, direction, groundY)
    local length = 1000
    local part = Instance.new("Part")
    part.Name = "NukePathway"
    part.Size = Vector3.new(length, 0.2, 2)
    part.Anchored = true
    part.CanCollide = false
	part.CanQuery = false
    part.Material = Enum.Material.Neon
    local pathwayColor = Options.PathwayColor and Options.PathwayColor.Value or Color3.new(1,0,0)
    part.BrickColor = BrickColor.new(pathwayColor)
    part.Transparency = 0.8
    part.CastShadow = false

    local baseY = groundY or startPos.Y
    local midPoint = startPos + direction * (length / 2)
    local flatPos = Vector3.new(midPoint.X, baseY + 0.1, midPoint.Z)

    local up = Vector3.new(0, 1, 0)
    local right = direction.Unit
    local forward = right:Cross(up).Unit
    part.CFrame = CFrame.fromMatrix(flatPos, right, up, forward)
    part.Parent = workspace
    return part
end

local function getLaunchInfo(missile)
    -- 1) Original method: "Silo" ObjectValue
    local siloVal = missile:FindFirstChild("Silo")
    if siloVal and siloVal:IsA("ObjectValue") and siloVal.Value then
        local silo = siloVal.Value
        if silo:IsA("Model") then
            local torso = silo:FindFirstChild("Torso") or silo:FindFirstChildWhichIsA("BasePart")
            if torso then
                local siloPos = torso.Position
                local root = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dir = (root.Position - siloPos) * Vector3.new(1, 0, 1)
                    if dir.Magnitude > 0.1 then
                        return siloPos, dir.Unit
                    end
                end
            end
        end
    end

    -- 2) Walk parent chain for Nuclear Silo model
    local obj = missile
    while obj do
        if obj:IsA("Model") and obj.Name == "Nuclear Silo" then
            local part = obj:FindFirstChild("Torso") or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local root = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dir = (root.Position - part.Position) * Vector3.new(1, 0, 1)
                    if dir.Magnitude > 0.1 then
                        return part.Position, dir.Unit
                    end
                end
            end
            break
        end
        obj = obj.Parent
    end

    -- 3) Fallback: use missile's BodyVelocity
    local root = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
    if root then
        local vel = root.AssemblyLinearVelocity
        local bodyVel = root:FindFirstChild("BodyVelocity")
        if bodyVel and bodyVel:IsA("BodyVelocity") then
            vel = bodyVel.Velocity
        end
        local horizVel = vel * Vector3.new(1, 0, 1)
        if horizVel.Magnitude > 1 then
            return root.Position, horizVel.Unit
        end
    end

    return nil, nil
end

-- ------------------------------------------
-- PREDICTOR HEARTBEAT (with ping animation)
-- ------------------------------------------
local trackedMissiles = {}
local persistentMarkers = {}
local debugPrint = false

RunService.Heartbeat:Connect(function()
    if not Toggles.PredictorEnabled.Value then
        for _, data in pairs(trackedMissiles) do
            if data.marker then data.marker:Destroy() end
            if data.pathway then data.pathway:Destroy() end
        end
        for marker, _ in pairs(persistentMarkers) do
            if marker.Parent then marker:Destroy() end
        end
        trackedMissiles = {}
        persistentMarkers = {}
        return
    end

    -- Update existing marker colors if RGB mode
    local markerMode = Options.MarkerColorMode.Value
    if markerMode == 'RGB' then
        local speed = Options.RGBSpeed and Options.RGBSpeed.Value or 1
        local rgb = Color3.fromHSV((tick() * speed) % 1, 1, 1)
        for _, data in pairs(trackedMissiles) do
            if data.marker and data.marker.Parent then
                data.marker.BrickColor = BrickColor.new(rgb)
            end
            if data.pathway and data.pathway.Parent then
                data.pathway.BrickColor = BrickColor.new(rgb)
            end
        end
        for marker, _ in pairs(persistentMarkers) do
            if marker.Parent then
                marker.BrickColor = BrickColor.new(rgb)
            else
                persistentMarkers[marker] = nil
            end
        end
    end

    -- Gather current missiles
    local currentMissiles = {}
    for _, teamFolder in ipairs(TeamsFolder:GetChildren()) do
        for _, model in ipairs(teamFolder:GetChildren()) do
            if model:IsA("Model") and (model.Name == "Nuclear Missile" or model.Name == "Fire Missile") then
                currentMissiles[model] = true
            end
        end
    end

    -- Remove dead missiles
    for missile, data in pairs(trackedMissiles) do
        if not currentMissiles[missile] then
            local stay = Options.PredictorStayTime.Value
            if data.marker then
                if stay > 0 then
                    persistentMarkers[data.marker] = true
                    task.delay(stay, function()
                        if data.marker then
                            data.marker:Destroy()
                            persistentMarkers[data.marker] = nil
                        end
                    end)
                else
                    data.marker:Destroy()
                end
            end
            if data.pathway then
                data.pathway:Destroy()
            end
            trackedMissiles[missile] = nil
        end
    end

    -- Process active missiles
    for missile, _ in pairs(currentMissiles) do
        local data = trackedMissiles[missile]
        if not data then
            local siloPos, direction = getLaunchInfo(missile)
            if siloPos and direction then
                local root = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
                if root then
                    data = {
                        startPos = siloPos,
                        direction = direction,
                        maxY = root.Position.Y,
                        apexReached = false,
                        marker = nil,
                        pathway = nil,
                        apexPos = nil
                    }
                    trackedMissiles[missile] = data

                    if Toggles.PathwayEnabled.Value then
                        data.pathway = createPathway(siloPos, direction, siloPos.Y)
                    end
                end
            end
        end

        if data then
            local root = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
            if not root then
                trackedMissiles[missile] = nil
            else
                local currentY = root.Position.Y
                if not data.apexReached then
                    if currentY > data.maxY then
                        data.maxY = currentY
                    end
                    if data.maxY - currentY > 0.5 then
                        data.apexReached = true
                        data.apexPos = root.Position

                        local horizontalOffset = Vector3.new(root.Position.X - data.startPos.X, 0, root.Position.Z - data.startPos.Z)
                        local predictedLand = data.startPos + horizontalOffset * 1.8

                        local markerColor = getMarkerColor()
                        data.marker = createPredictorMarker(predictedLand, markerColor)

                        if debugPrint then print("[Predictor] APEX! Landing:", predictedLand) end

                        if Options.PathwayDisappear.Value == 'On Apex' then
                            if data.pathway then
                                data.pathway:Destroy()
                                data.pathway = nil
                            end
                        end
                    end
                end
            end
        end
    end
end)


-- ============================================================
-- NUKE MISC GROUPBOX & LOGIC (audio alerts)
-- ============================================================
local NukeMiscGroup = Tabs.Main:AddLeftGroupbox('Nuke Misc')

NukeMiscGroup:AddToggle('NotifyNukeLaunch', { Text = 'Notify Nuke Launch', Default = false })
NukeMiscGroup:AddToggle('NotifyNukeTeamCheck', { Text = 'Team Check', Default = true })

NukeMiscGroup:AddLabel('Launch Alert Sound')
NukeMiscGroup:AddDropdown('AlertSound', {
    Values = { 'None', 'UTHINKIMDUMB', 'LLTNT', 'NEW YEAR NEW ME', 'BHAJLSC', 'DOAFTCS', 'HOW U MAKE OAT MEAL', 'FACTORIO', 'FACTORIO OLD', 'LELOUCH',  'NEOH' },
    Default = 'UTHINKIMDUMB',
    Multi = false,
    Text = 'Alert Sound'
})

-- ---------- SOUND DOWNLOAD & CACHE ----------
local soundUrls = {
    ['UTHINKIMDUMB'] = 'https://u.pone.rs/gqtwqctf.mp3',
    ['LLTNT'] = 'https://u.pone.rs/zzjffmnr.mp3',
    ['NEW YEAR NEW ME'] = 'https://u.pone.rs/dfparvyq.mp3',
	['BHAJLSC']  = 'https://u.pone.rs/ldimapzk.mp3',
	['DOAFTCS']  = 'https://u.pone.rs/gfywjrhv.mp3',
	['HOW U MAKE OAT MEAL']  = 'https://u.pone.rs/lfbuhrmc.mp3',
    ['FACTORIO']    = 'https://u.pone.rs/xyypgrho.mp3',
    ['FACTORIO OLD']  = 'https://u.pone.rs/qjxduqcj.mp3', 
	['LELOUCH']  = 'https://u.pone.rs/wstbohkr.mp3',
    ['NEOH']    = 'https://u.pone.rs/cwhtmzkg.ogg',
}
local soundCache = {}

local function getSoundAsset(soundName)
    if soundCache[soundName] then return soundCache[soundName] end
    local url = soundUrls[soundName]
    if not url then return nil end

    local success, data = pcall(function() return game:HttpGet(url) end)
    if not success or not data then
        warn("[NukeMisc] Failed to download: " .. soundName)
        return nil
    end

    local fileName = "CQ3UI/audio/nuke_alert_" .. soundName:gsub(" ", "_") .. ".mp3"
    writefile(fileName, data)
    local assetId = getcustomasset(fileName)
    if not assetId then
        warn("[NukeMisc] getcustomasset failed for: " .. soundName)
        return nil
    end
    soundCache[soundName] = assetId
    return assetId
end

-- Preload all audio assets at script start
for soundName, url in pairs(soundUrls) do
    spawn(function()
        getSoundAsset(soundName)
    end)
end

local function playSound(soundName, volume)
    if soundName == 'None' then return end
    local assetId = getSoundAsset(soundName)
    if not assetId then return end

    local sound = Instance.new("Sound")
    sound.SoundId = assetId
    sound.Volume = volume or 1
    sound.Parent = workspace
    sound:Play()

    -- Cleanup when the sound finishes naturally
    sound.Ended:Connect(function()
        sound:Destroy()
    end)

    -- Safety net: check every second if the sound still exists and has stopped playing
    spawn(function()
        while sound and sound.Parent do
            if sound.IsPlaying then
                task.wait(1)
            else
                sound:Destroy()
                break
            end
        end
    end)
end

-- Test Sound button
NukeMiscGroup:AddButton('Test Sound', function()
    local soundName = Options.AlertSound and Options.AlertSound.Value or 'None'
    local volume = Options.AlertVolume and Options.AlertVolume.Value or 0.5
    playSound(soundName, volume)
end)

-- Volume slider
NukeMiscGroup:AddSlider('AlertVolume', {
    Text = 'Volume',
    Default = 1,
    Min = 0,
    Max = 1.5,
    Rounding = 2,
    Compact = false
})

-- ---------- LOCAL HELPERS (getTeamFolder, etc.) ----------
local function getTeamFolder(instance)
    return resolveTeamFolder(instance)
end

local function getPlayerName(teamColor)
    local folder = TeamSettings:FindFirstChild(teamColor)
    if not folder then return "NO PLAYER" end
    local hist = folder:FindFirstChild("PlayerHistory")
    if hist then
        for _, entry in ipairs(hist:GetChildren()) do
            if Players:FindFirstChild(entry.Name) then return entry.Name end
        end
    end
    return "NO PLAYER"
end

local function shortColorName(teamName)
    teamName = tostring(teamName):lower()
    teamName = teamName:gsub("^bright ", ""):gsub("^really ", ""):gsub("^reddish ", "")
        :gsub("^deep ", ""):gsub("^pastel ", ""):gsub("^medium ", "")
        :gsub("^dark ", ""):gsub("^light ", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return string.upper(teamName)
end

local function sendNotification(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5
    })
end

-- ---------- NUKE LAUNCH NOTIFICATION + AUDIO ----------
local notifiedLaunches = {}
local debugNuke = false   -- set false to hide speed prints

RunService.Heartbeat:Connect(function()
    if not Toggles.NotifyNukeLaunch.Value then return end

    for _, teamFolder in ipairs(TeamsFolder:GetChildren()) do
        for _, model in ipairs(teamFolder:GetChildren()) do
            if model:IsA("Model") and (model.Name == "Nuclear Missile" or model.Name == "Fire Missile") then
                if not notifiedLaunches[model] then
                    local root = model:FindFirstChild("Torso") or model:FindFirstChildWhichIsA("BasePart")
                    if root then
                        local vel = root.AssemblyLinearVelocity
                        local bodyVel = root:FindFirstChild("BodyVelocity")
                        if bodyVel and bodyVel:IsA("BodyVelocity") then vel = bodyVel.Velocity end
                        local speed = vel.Magnitude

                        if debugNuke and speed > 1 then
                            print("[NukeMisc] Missile speed:", speed)
                        end

                        if speed >= 5 then
                            notifiedLaunches[model] = true
                            local teamFolder = getTeamFolder(model)
                            local teamName = teamFolder and teamFolder.Name or "Unknown"

                            local shouldNotify = true
                            if Toggles.NotifyNukeTeamCheck.Value then
                                if not IsEnemyTeamColor(teamName) then shouldNotify = false end
                            end

                            if shouldNotify then
                                local short = shortColorName(teamName)
                                local playerName = getPlayerName(teamName)
                                local missileType = model.Name
                                local text = short .. " (" .. playerName .. ") HAS LAUNCHED " .. missileType:upper()

                                if debugNuke then print("[NukeMisc] Sending notification:", text) end
                                sendNotification("☢️ Nuke Launch", text, 5)

                                -- Play selected sound
                                local soundName = Options.AlertSound and Options.AlertSound.Value or 'None'
                                local volume = Options.AlertVolume and Options.AlertVolume.Value or 0.5
                                playSound(soundName, volume)
                            end
                        end
                    end
                end
            end
        end
    end

    for model, _ in pairs(notifiedLaunches) do
        if not model or not model:IsDescendantOf(TeamsFolder) then
            notifiedLaunches[model] = nil
        end
    end
end)




-- ============================================================
-- SILO ESP GROUPBOX
-- ============================================================
local SiloESPGroup = Tabs.Main:AddLeftGroupbox('Silo ESP')

SiloESPGroup:AddToggle('SiloESPEnabled', { Text = 'Enable Silo ESP', Default = false })
SiloESPGroup:AddToggle('SiloESPTeamCheck', { Text = 'Team Check', Default = true })
SiloESPGroup:AddToggle('SiloESPIgnoreLocal', { Text = 'Ignore Local', Default = true })

SiloESPGroup:AddLabel('Silo Colors')
SiloESPGroup:AddDivider()
SiloESPGroup:AddDropdown('SiloColorMode', { Values = { 'Team Color', 'Custom', 'RGB', 'Green, Yellow, Red - No Nuke, Producing, Nuke' }, Default = 'Team Color', Multi = false, Text = 'Silo Color Mode' })
SiloESPGroup:AddLabel('Silo Outline'):AddColorPicker('SiloOutlineColor', { Default = Color3.fromRGB(255, 100, 100), Title = 'Silo Outline' })
SiloESPGroup:AddLabel('Silo Inner'):AddColorPicker('SiloInnerColor', { Default = Color3.fromRGB(255, 0, 0), Title = 'Silo Inner' })
SiloESPGroup:AddSlider('SiloOutlineThickness', { Text = 'Silo Outline Thickness', Default = 1, Min = 0, Max = 1, Rounding = 2, Compact = false })


-- ============================================================
-- NUKE ESP GROUPBOX
-- ============================================================
local NukeESPGroup = Tabs.Main:AddLeftGroupbox('Nuke ESP')

NukeESPGroup:AddToggle('NukeESPEnabled', { Text = 'Enable Nuke ESP', Default = false })
NukeESPGroup:AddToggle('NukeESPTeamCheck', { Text = 'Team Check', Default = true })
NukeESPGroup:AddToggle('NukeESPIgnoreLocal', { Text = 'Ignore Local', Default = true })

NukeESPGroup:AddLabel('Idle Missile Colors')
NukeESPGroup:AddDivider()
NukeESPGroup:AddDropdown('IdleColorMode', { Values = { 'Team Color', 'Custom', 'RGB' }, Default = 'Team Color', Multi = false, Text = 'Idle Color Mode' })
NukeESPGroup:AddLabel('Idle Outline'):AddColorPicker('IdleOutlineColor', { Default = Color3.fromRGB(255, 100, 100), Title = 'Idle Outline' })
NukeESPGroup:AddLabel('Idle Inner'):AddColorPicker('IdleInnerColor', { Default = Color3.fromRGB(255, 0, 0), Title = 'Idle Inner' })
NukeESPGroup:AddSlider('IdleOutlineThickness', { Text = 'Idle Outline Thickness', Default = 1, Min = 0, Max = 1, Rounding = 2, Compact = false })

NukeESPGroup:AddLabel('Moving Missile Colors')
NukeESPGroup:AddDivider()
NukeESPGroup:AddDropdown('MovingColorMode', { Values = { 'Team Color', 'Custom', 'RGB' }, Default = 'Team Color', Multi = false, Text = 'Moving Color Mode' })
NukeESPGroup:AddLabel('Moving Outline'):AddColorPicker('MovingOutlineColor', { Default = Color3.fromRGB(100, 100, 255), Title = 'Moving Outline' })
NukeESPGroup:AddLabel('Moving Inner'):AddColorPicker('MovingInnerColor', { Default = Color3.fromRGB(0, 0, 255), Title = 'Moving Inner' })
NukeESPGroup:AddSlider('MovingOutlineThickness', { Text = 'Moving Outline Thickness', Default = 1, Min = 0, Max = 1, Rounding = 2, Compact = false })

-- ============================================================
-- ESP HELPERS (shared by Nuke & Silo ESP)
-- ============================================================
local function GetTeamColorForFolder_ESP(teamFolder)
    if not teamFolder then return Color3.new(1,1,1) end
    local ok, brick = pcall(BrickColor.new, teamFolder.Name)
    if ok and brick then return brick.Color end
    local TeamsService = game:GetService("Teams")
    for _, team in ipairs(TeamsService:GetChildren()) do
        if team.Name == teamFolder.Name and team.TeamColor then
            return team.TeamColor.Color
        end
    end
    return Color3.new(1,1,1)
end

local function rgbColor()
    local hue = (tick() * Options.RGBSpeed.Value) % 1
    return Color3.fromHSV(hue, 1, 1)
end

local function isMoving(missile)
    local torso = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
    if not torso then return false end
    local bodyVel = torso:FindFirstChild("BodyVelocity")
    local vel = bodyVel and bodyVel.Velocity or torso.AssemblyLinearVelocity
    return vel.Magnitude > 5
end

local function getTeamFolder(instance)
    return resolveTeamFolder(instance)
end

local function isLocalOwner(missile)
    -- Check if the missile's owning silo is on your team
    local teamName = getTeamFolder(missile) and getTeamFolder(missile).Name
    if not teamName then return false end

    local myTeam = GetMyTeamColor()
    return teamName == myTeam
end

-- Highlight management tables
local nukeHighlights = {}   -- [model] = { highlight, highlight, ... }
local siloHighlights = {}   -- [model] = { highlight, ... }

local function applyHighlight(model, outlineColor, innerColor, outlineTransparency, highlightsTable)
    local highlights = highlightsTable[model]
    if not highlights then
        highlights = {}
        highlightsTable[model] = highlights
    end

    -- Clean up stale highlights (part destroyed or highlight removed)
    local alreadyAdorned = {}
    for i = #highlights, 1, -1 do
        local hl = highlights[i]
        if not hl or not hl.Parent or not hl.Adornee or not hl.Adornee.Parent then
            if hl then hl:Destroy() end
            table.remove(highlights, i)
        else
            alreadyAdorned[hl.Adornee] = true
        end
    end

    -- Add highlights for any new parts that appeared since last check
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") and not alreadyAdorned[child] then
            local hl = Instance.new("Highlight")
            hl.Adornee = child
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency = 0.5
            hl.Parent = child
            table.insert(highlights, hl)
        end
    end

    -- Apply colors to all current highlights
    for _, hl in ipairs(highlights) do
        hl.FillColor = innerColor
        hl.OutlineColor = outlineColor
        hl.OutlineTransparency = outlineTransparency
    end
end

local function removeHighlight(model, highlightsTable)
    local highlights = highlightsTable[model]
    if highlights then
        for _, hl in ipairs(highlights) do
            if hl then hl:Destroy() end
        end
        highlightsTable[model] = nil
    end
end

-- Returns "idle", "producing", or "ready" for a given silo model.
--   idle      → nothing in Producing, no ready missile near this silo
--   producing → a missile is inside Producing with Progress < 1
--   ready     → a missile has finished producing (Progress >= 1 in Producing),
--               OR a stationary missile is sitting near this silo's torso in the team folder
local function siloNukeState(model)
    local torso = model:FindFirstChild("Torso")
    if not torso then return "idle" end

    -- 1) Missile currently in the silo's Producing folder
    local producing = torso:FindFirstChild("Producing")
    if producing then
        for _, child in ipairs(producing:GetChildren()) do
            if child.Name == "Nuclear Missile" or child.Name == "Fire Missile" then
                local prog = child:FindFirstChild("Progress")
                if prog and prog:IsA("NumberValue") then
                    if prog.Value >= 1 then
                        return "ready"
                    else
                        return "producing"
                    end
                else
                    -- No Progress value on the missile → assume it's finished
                    return "ready"
                end
            end
        end
    end

    -- 2) Ready missiles sitting in the team folder near this silo.
    -- Many games don't expose a Silo ObjectValue, so we fall back to proximity:
    -- any stationary missile whose root is within READY_DISTANCE studs of this silo's
    -- torso belongs to this silo.
    local READY_DISTANCE = 40  -- adjust if your silos are larger/smaller
    local teamFolder = model.Parent
    if teamFolder then
        local siloPos = torso.Position
        for _, obj in ipairs(teamFolder:GetChildren()) do
            if obj:IsA("Model") and (obj.Name == "Nuclear Missile" or obj.Name == "Fire Missile") then
                local root = obj:FindFirstChild("Torso") or obj:FindFirstChildWhichIsA("BasePart")
                if root then
                    local vel = root.AssemblyLinearVelocity.Magnitude
                    if vel <= 1 then
                        local dist = (root.Position - siloPos).Magnitude
                        if dist <= READY_DISTANCE then
                            return "ready"
                        end
                    end
                end
            end
        end
    end

    return "idle"
end

-- ============================================================
-- HEARTBEAT: Nuke ESP (missiles) – global RGB sync
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not Toggles.NukeESPEnabled.Value then
        for model, _ in pairs(nukeHighlights) do
            removeHighlight(model, nukeHighlights)
        end
        return
    end

    for _, teamFolder in ipairs(TeamsFolder:GetChildren()) do
        for _, model in ipairs(teamFolder:GetChildren()) do
            if model:IsA("Model") and (model.Name == "Nuclear Missile" or model.Name == "Fire Missile") then
                local shouldShow = true

                if Toggles.NukeESPTeamCheck.Value then
                    local teamCol = getTeamFolder(model)
                    if teamCol and not IsEnemyTeamColor(teamCol.Name) then
                        shouldShow = false
                    end
                end

                if shouldShow and Toggles.NukeESPIgnoreLocal.Value and isLocalOwner(model) then
                    shouldShow = false
                end

                if not shouldShow then
                    removeHighlight(model, nukeHighlights)
                else
                    local moving = isMoving(model)
                    local mode = moving and Options.MovingColorMode.Value or Options.IdleColorMode.Value
                    local outline, inner, outlineTrans

                    if mode == 'Team Color' then
                        local teamCol = GetTeamColorForFolder_ESP(getTeamFolder(model))
                        outline = teamCol:Lerp(Color3.new(0,0,0), 0.3)
                        inner = teamCol
                        outlineTrans = 1 - (moving and Options.MovingOutlineThickness.Value or Options.IdleOutlineThickness.Value)
                    elseif mode == 'RGB' then
                        inner = getGlobalRGBColor()
                        outline = inner:Lerp(Color3.new(0,0,0), 0.3)
                        outlineTrans = 1 - (moving and Options.MovingOutlineThickness.Value or Options.IdleOutlineThickness.Value)
                    else -- Custom
                        outline = moving and Options.MovingOutlineColor.Value or Options.IdleOutlineColor.Value
                        inner = moving and Options.MovingInnerColor.Value or Options.IdleInnerColor.Value
                        outlineTrans = 1 - (moving and Options.MovingOutlineThickness.Value or Options.IdleOutlineThickness.Value)
                    end

                    applyHighlight(model, outline, inner, outlineTrans, nukeHighlights)
                end
            end
        end
    end

    for model, _ in pairs(nukeHighlights) do
        if not model or not model:IsDescendantOf(TeamsFolder) then
            removeHighlight(model, nukeHighlights)
        end
    end
end)

-- Instantly highlight new missiles as they appear
TeamsFolder.DescendantAdded:Connect(function(descendant)
    if not Toggles.NukeESPEnabled.Value then return end
    if not descendant:IsA("Model") then return end
    if descendant.Name ~= "Nuclear Missile" and descendant.Name ~= "Fire Missile" then return end

    local model = descendant
    local shouldShow = true
    if Toggles.NukeESPTeamCheck.Value then
        local teamCol = getTeamFolder(model)
        if teamCol and not IsEnemyTeamColor(teamCol.Name) then
            shouldShow = false
        end
    end
    if shouldShow and Toggles.NukeESPIgnoreLocal.Value and isLocalOwner(model) then
        shouldShow = false
    end

    if shouldShow then
        local moving = isMoving(model)
        local mode = moving and Options.MovingColorMode.Value or Options.IdleColorMode.Value
        local outline, inner, outlineTrans

        if mode == 'Team Color' then
            local teamCol = GetTeamColorForFolder_ESP(getTeamFolder(model))
            outline = teamCol:Lerp(Color3.new(0,0,0), 0.3)
            inner = teamCol
            outlineTrans = 1 - (moving and Options.MovingOutlineThickness.Value or Options.IdleOutlineThickness.Value)
        elseif mode == 'RGB' then
            inner = rgbColor()
            outline = inner:Lerp(Color3.new(0,0,0), 0.3)
            outlineTrans = 1 - (moving and Options.MovingOutlineThickness.Value or Options.IdleOutlineThickness.Value)
        else -- Custom
            outline = moving and Options.MovingOutlineColor.Value or Options.IdleOutlineColor.Value
            inner = moving and Options.MovingInnerColor.Value or Options.IdleInnerColor.Value
            outlineTrans = 1 - (moving and Options.MovingOutlineThickness.Value or Options.IdleOutlineThickness.Value)
        end

        applyHighlight(model, outline, inner, outlineTrans, nukeHighlights)
    end
end)



-- ============================================================
-- HEARTBEAT: Silo ESP – global RGB sync
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not Toggles.SiloESPEnabled.Value then
        for model, _ in pairs(siloHighlights) do
            removeHighlight(model, siloHighlights)
        end
        return
    end

    for _, teamFolder in ipairs(TeamsFolder:GetChildren()) do
        for _, model in ipairs(teamFolder:GetChildren()) do
            if model:IsA("Model") and model.Name == "Nuclear Silo" then
                local shouldShow = true

                if Toggles.SiloESPTeamCheck.Value then
                    local teamCol = getTeamFolder(model)
                    if teamCol and not IsEnemyTeamColor(teamCol.Name) then
                        shouldShow = false
                    end
                end

                if not shouldShow then
                    removeHighlight(model, siloHighlights)
                else
                    local mode = Options.SiloColorMode.Value
                    local outline, inner, outlineTrans
                    if mode == 'Team Color' then
                        local teamCol = GetTeamColorForFolder_ESP(getTeamFolder(model))
                        outline = teamCol:Lerp(Color3.new(0,0,0), 0.3)
                        inner = teamCol
                        outlineTrans = 1 - Options.SiloOutlineThickness.Value
                    elseif mode == 'RGB' then
                        inner = getGlobalRGBColor()
                        outline = inner:Lerp(Color3.new(0,0,0), 0.3)
                        outlineTrans = 1 - Options.SiloOutlineThickness.Value
                    elseif mode == 'Green, Yellow, Red - No Nuke, Producing, Nuke' then
                        local state = siloNukeState(model)
                        if state == "ready" then
                            inner = Color3.fromRGB(255, 0, 0)     -- red
                        elseif state == "producing" then
                            inner = Color3.fromRGB(255, 255, 0)   -- yellow
                        else
                            inner = Color3.fromRGB(0, 255, 0)     -- green
                        end
                        outline = inner:Lerp(Color3.new(0,0,0), 0.3)
                        outlineTrans = 1 - Options.SiloOutlineThickness.Value
                    else
                        -- Custom
                        outline = Options.SiloOutlineColor.Value
                        inner = Options.SiloInnerColor.Value
                        outlineTrans = 1 - Options.SiloOutlineThickness.Value
                    end

                    applyHighlight(model, outline, inner, outlineTrans, siloHighlights)
                end
            end
        end
    end

    for model, _ in pairs(siloHighlights) do
        if not model or not model:IsDescendantOf(TeamsFolder) then
            removeHighlight(model, siloHighlights)
        end
    end
end)

-- Instantly highlight new silos as they appear
TeamsFolder.DescendantAdded:Connect(function(descendant)
    if not Toggles.SiloESPEnabled.Value then return end
    if not descendant:IsA("Model") then return end
    if descendant.Name ~= "Nuclear Silo" then return end

    local model = descendant
    local shouldShow = true
    if Toggles.SiloESPTeamCheck.Value then
        local teamCol = getTeamFolder(model)
        if teamCol and not IsEnemyTeamColor(teamCol.Name) then
            shouldShow = false
        end
    end
    if shouldShow and Toggles.SiloESPIgnoreLocal.Value and isLocalOwner(model) then
        shouldShow = false
    end

    if shouldShow then
        local mode = Options.SiloColorMode.Value
        local outline, inner, outlineTrans
        if mode == 'Team Color' then
            local teamCol = GetTeamColorForFolder_ESP(getTeamFolder(model))
            outline = teamCol:Lerp(Color3.new(0,0,0), 0.3)
            inner = teamCol
            outlineTrans = 1 - Options.SiloOutlineThickness.Value
        elseif mode == 'RGB' then
            inner = rgbColor()
            outline = inner:Lerp(Color3.new(0,0,0), 0.3)
            outlineTrans = 1 - Options.SiloOutlineThickness.Value
        elseif mode == 'Green, Yellow, Red - No Nuke, Producing, Nuke' then
            local state = siloNukeState(model)
            if state == "ready" then
                inner = Color3.fromRGB(255, 0, 0)
            elseif state == "producing" then
                inner = Color3.fromRGB(255, 255, 0)
            else
                inner = Color3.fromRGB(0, 255, 0)
            end
            outline = inner:Lerp(Color3.new(0,0,0), 0.3)
            outlineTrans = 1 - Options.SiloOutlineThickness.Value
        else
            outline = Options.SiloOutlineColor.Value
            inner = Options.SiloInnerColor.Value
            outlineTrans = 1 - Options.SiloOutlineThickness.Value
        end

        applyHighlight(model, outline, inner, outlineTrans, siloHighlights)
    end
end)


-- === NUCLEAR INFORMATION TAB ===

local Alliance1 = Tabs.Nuclear:AddLeftGroupbox("Alliance 1")
local Alliance2 = Tabs.Nuclear:AddLeftGroupbox("Alliance 2")
local Alliance3 = Tabs.Nuclear:AddRightGroupbox("Alliance 3")

local AllianceGroups = { Alliance1, Alliance2, Alliance3 }
local AllianceLabels = {}

for i, group in ipairs(AllianceGroups) do
    AllianceLabels[i] = group:AddLabel("Loading nuclear data...", true)
end

local function ResizeAllianceBox(label, groupbox)
    task.defer(function()
        local text = label.Text or ""
        local _, newlineCount = text:gsub("\n", "")
        local lines = newlineCount + 1
        local height = 20 + (lines * 14)

        local container = groupbox.Container or (groupbox.Frame and groupbox.Frame.Container)
        if container then
            container.Size = UDim2.new(1, 0, 0, height)
        end
    end)
end

----------------------------------------------------------------
-- NUCLEAR ENGINE — MISSILE‑ID VERSION (FINAL)
----------------------------------------------------------------

local HttpService = game:GetService("HttpService")

local function NE_IsSilo(inst)
    return inst.Name == "Nuclear Silo"
end

local function NE_IsMissile(inst)
    return inst.Name == "Nuclear Missile" or inst.Name == "Fire Missile"
end

local function NE_GetMissileRoot(m)
    return m:FindFirstChild("Root") or m:FindFirstChildWhichIsA("BasePart")
end

-- Assign a GUID to each missile once
local function NE_AssignMissileID(m)
    if not m:FindFirstChild("MissileID") then
        local id = Instance.new("StringValue")
        id.Name = "MissileID"
        id.Value = HttpService:GenerateGUID(false)
        id.Parent = m
    end
    return m:FindFirstChild("MissileID").Value
end

local function NE_ScanTeam(teamFolder)
    local state = {
        hasSilo   = false,
        building  = 0,

        -- missileID → pct
        nukeProd  = {},
        fireProd  = {},

        -- missileID → true
        nukeReady = {},
        fireReady = {},

        -- missileID → true
        launched  = {},

        queued    = 0,
    }

    ------------------------------------------------------------
    -- 1) SCAN SILOS + PRODUCING
    ------------------------------------------------------------
    for _, inst in ipairs(teamFolder:GetDescendants()) do
        if NE_IsSilo(inst) then
            state.hasSilo = true

            local torso = inst:FindFirstChild("Torso")
            if torso then
                -- BUILD PROGRESS
                local bp = torso:FindFirstChild("BuildProgress")
                if bp and bp:IsA("NumberValue") then
                    local v = bp.Value
                    if v > 0 and v < 1 then
                        state.building = math.floor(v * 100 + 0.5)
                    elseif v >= 1 then
                        state.building = 100
                    end
                end

                -- PRODUCING
                local producing = torso:FindFirstChild("Producing")
                if producing then
                    for _, missile in ipairs(producing:GetChildren()) do
                        if NE_IsMissile(missile) then
                            state.queued += 1

                            local id = NE_AssignMissileID(missile)

                            local prog = missile:FindFirstChild("Progress")
                            local pct = prog and math.floor((prog.Value or 0) * 100 + 0.5) or 0

                            if pct > 0 and pct < 100 then
                                if missile.Name == "Nuclear Missile" then
                                    state.nukeProd[id] = pct
                                else
                                    state.fireProd[id] = pct
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    ------------------------------------------------------------
    -- 2) READY / LAUNCHED — PER MISSILE, NOT PER TEAM
    ------------------------------------------------------------
    for _, tf in ipairs(TeamsFolder:GetChildren()) do
        for _, obj in ipairs(tf:GetChildren()) do
            if NE_IsMissile(obj) then
                local creator = obj:FindFirstChild("Team")
                local creatorTeam = creator and creator.Value or tf.Name

                -- Only track missiles created by THIS team
                if creatorTeam == teamFolder.Name then
                    local id = NE_AssignMissileID(obj)

                    local root = NE_GetMissileRoot(obj)
                    local vel = root and root.AssemblyLinearVelocity.Magnitude or 0

                    if vel > 1 then
                        state.launched[id] = true
                    else
                        if obj.Name == "Nuclear Missile" then
                            state.nukeReady[id] = true
                        else
                            state.fireReady[id] = true
                        end
                    end
                end
            end
        end
    end

    return state
end

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------

function AggregateTeam(teamColor)
    local teamFolder = TeamsFolder:FindFirstChild(teamColor)
    if not teamFolder then
        return {
            hasSilo   = false,
            building  = 0,
            nukeProd  = {},
            fireProd  = {},
            nukeReady = {},
            fireReady = {},
            launched  = {},
            queued    = 0,
        }
    end

    return NE_ScanTeam(teamFolder)
end


-------------------------------------------------
-- TEAM NAME HELPERS
-------------------------------------------------

local TeamColorEmoji = {
    ["bright red"] = "🟥",
    ["bright blue"] = "🟦",
    ["bright green"] = "🟩",
    ["bright yellow"] = "🟨",
    ["bright orange"] = "🟧",
    ["bright violet"] = "🟪",
    ["reddish brown"] = "🟫",
    ["really black"] = "⬛",
    ["really white"] = "⬜"
}

local function NormalizeTeamName(name)
    return tostring(name):lower():gsub("_", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function ShortColorName(teamName)
    teamName = tostring(teamName):lower()
    teamName = teamName
        :gsub("^bright ", "")
        :gsub("^really ", "")
        :gsub("^reddish ", "")
        :gsub("^deep ", "")
        :gsub("^pastel ", "")
        :gsub("^medium ", "")
        :gsub("^dark ", "")
        :gsub("^light ", "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
    return string.upper(teamName)
end

local function GetTeamEmoji(teamName)
    return TeamColorEmoji[NormalizeTeamName(teamName)] or ""
end

-------------------------------------------------
-- ALLIANCE HELPERS
-------------------------------------------------

local function GetPlayersForTeam(teamColor)
    local folder = TeamSettings:FindFirstChild(teamColor)
    if not folder then return {} end

    local history = folder:FindFirstChild("PlayerHistory")
    if not history then return {} end

    local players = {}
    for _, entry in ipairs(history:GetChildren()) do
        table.insert(players, entry.Name)
    end

    return players
end

local function GetAllAlliances()
    local alliances = {}
    local used = {}

    for _, teamFolder in ipairs(TeamSettings:GetChildren()) do
        local teamColor = teamFolder.Name
        if not used[teamColor] then
            local alliance = { teamColor }
            used[teamColor] = true

            local alliesFolder = teamFolder:FindFirstChild("Allies")
            if alliesFolder then
                for _, ally in ipairs(alliesFolder:GetChildren()) do
                    local allyColor = ally.Name
                    if TeamSettings:FindFirstChild(allyColor) then
                        table.insert(alliance, allyColor)
                        used[allyColor] = true
                    end
                end
            end

            table.insert(alliances, alliance)
        end
    end

    return alliances
end

-------------------------------------------------
-- BUILD TEAM BLOCK (SAFE, SHOWS BUILD %)
-------------------------------------------------

local function BuildTeamBlock(teamColor)
    local state = AggregateTeam(teamColor)
    local short = ShortColorName(teamColor)
    local emoji = GetTeamEmoji(teamColor)

    -- resolve player name
    local normalized = NormalizeTeamName(teamColor)
    local folder = TeamSettings:FindFirstChild(teamColor)
    if not folder then
        for _, child in ipairs(TeamSettings:GetChildren()) do
            if NormalizeTeamName(child.Name) == normalized then
                folder = child
                break
            end
        end
    end

    local playerName = "NO PLAYER"
    if folder then
        local hist = folder:FindFirstChild("PlayerHistory")
        if hist then
            for _, entry in ipairs(hist:GetChildren()) do
                if Players:FindFirstChild(entry.Name) then
                    playerName = entry.Name
                    break
                end
            end
        end
    end

    local lines = {}
    table.insert(lines, string.format("%s%s - %s (%d)", emoji, short, playerName, state.queued or 0))

    if not state.hasSilo then
        table.insert(lines, "NO SILO FOUND")
        return table.concat(lines, "\n")
    end

----------------------------------------------------
-- BUILDING (show only 1–99%)
----------------------------------------------------
		if state.building and state.building > 0 and state.building < 100 then
			table.insert(lines, "SILO BUILDING - (" .. tostring(state.building) .. "%)")
		end


    ----------------------------------------------------
    -- PRODUCING (creator-aware)
    ----------------------------------------------------
    for creatorTeam, pct in pairs(state.nukeProd or {}) do
        local prefix = (creatorTeam ~= teamColor) and "(" .. ShortColorName(creatorTeam) .. ") - " or ""
        table.insert(lines, prefix .. "NUKE PRODUCING - (" .. pct .. "%)")
    end

    for creatorTeam, pct in pairs(state.fireProd or {}) do
        local prefix = (creatorTeam ~= teamColor) and "(" .. ShortColorName(creatorTeam) .. ") - " or ""
        table.insert(lines, prefix .. "FIRE PRODUCING - (" .. pct .. "%)")
    end

    ----------------------------------------------------
    -- READY (creator-aware)
    ----------------------------------------------------
    for creatorTeam in pairs(state.nukeReady or {}) do
        local prefix = (creatorTeam ~= teamColor) and "(" .. ShortColorName(creatorTeam) .. ") - " or ""
        table.insert(lines, prefix .. "✅ NUKE READY")
    end

    for creatorTeam in pairs(state.fireReady or {}) do
        local prefix = (creatorTeam ~= teamColor) and "(" .. ShortColorName(creatorTeam) .. ") - " or ""
        table.insert(lines, prefix .. "✅ FNUKE READY")
    end

    ----------------------------------------------------
    -- LAUNCHED (creator-aware)
    ----------------------------------------------------
    for creatorTeam in pairs(state.launched or {}) do
        local prefix = (creatorTeam ~= teamColor) and "(" .. ShortColorName(creatorTeam) .. ") - " or ""
        table.insert(lines, prefix .. "☢️ NUKE LAUNCHED ☢️")
    end

    ----------------------------------------------------
    -- IDLE (nothing happening)
    ----------------------------------------------------
    local isBuilding = (state.building and state.building > 0 and state.building < 100)
    local nothingHappening =
        not isBuilding and
        next(state.nukeProd or {}) == nil and
        next(state.fireProd or {}) == nil and
        next(state.nukeReady or {}) == nil and
        next(state.fireReady or {}) == nil and
        next(state.launched or {}) == nil

    if nothingHappening then
        table.insert(lines, "SILO IS IDLE")
    end

    return table.concat(lines, "\n")
end

-------------------------------------------------
-- REFRESH UI (NUCLEAR TAB)
-------------------------------------------------

local function RefreshUI()
    local alliances = GetAllAlliances()

    for i = 1, 3 do
        local label = AllianceLabels[i]
        local alliance = alliances[i]

        if not alliance or #alliance == 0 then
            label:SetText("No alliance data.")
        else
            local blocks = {}
            for _, teamColor in ipairs(alliance) do
                table.insert(blocks, BuildTeamBlock(teamColor))
            end
            label:SetText(table.concat(blocks, "\n\n"))
        end

        ResizeAllianceBox(label, AllianceGroups[i])
    end
end

-------------------------------------------------
-- HEARTBEAT UPDATE (NUCLEAR UI ONLY)
-------------------------------------------------

local lastNukeUpdate = 0
local NUKE_INTERVAL = 0.20

RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastNukeUpdate < NUKE_INTERVAL then return end
    lastNukeUpdate = now

    RefreshUI()
end)



-- ============================================================
-- PLAYER INFO TAB
-- ============================================================
local PI_Alliance1 = Tabs.PlayerInfo:AddLeftGroupbox("Alliance 1")
local PI_Alliance2 = Tabs.PlayerInfo:AddLeftGroupbox("Alliance 2")
local PI_Alliance3 = Tabs.PlayerInfo:AddRightGroupbox("Alliance 3")

local PI_Groups = { PI_Alliance1, PI_Alliance2, PI_Alliance3 }
local PI_Labels = {}

for i, group in ipairs(PI_Groups) do
    PI_Labels[i] = group:AddLabel("Loading player data...", true)
end

local function ResizePIBox(label, groupbox)
    task.defer(function()
        local text = label.Text or ""
        local _, newlineCount = text:gsub("\n", "")
        local lines = newlineCount + 1
        local height = 20 + (lines * 14)
        local container = groupbox.Container or (groupbox.Frame and groupbox.Frame.Container)
        if container then
            container.Size = UDim2.new(1, 0, 0, height)
        end
    end)
end

-- ---------- HELPERS ----------
local function formatTime(seconds)
    if not seconds or seconds == 0 then return "0h 0m" end
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    return string.format("%dh %dm", hours, mins)
end

local function safeFormatDate(unix)
    if not unix or unix == 0 then return "N/A" end
    local success, result = pcall(function() return os.date("%d/%m/%y", unix) end)
    if success then return result else return "N/A" end
end

-- ---------- PLAYER STATS FETCH (online only) ----------
local function getPlayerStats()
    local alliances = GetAllAlliances()
    local output = {}

    for i, alliance in ipairs(alliances) do
        local blocks = {}
        local seenPlayers = {}

        -- Collect all player names from PlayerHistory + damage/heal folders
        for _, teamColor in ipairs(alliance) do
            local folder = TeamSettings:FindFirstChild(teamColor)
            if folder then
                local damageFolder = folder:FindFirstChild("DamageDealt")
                local healFolder = folder:FindFirstChild("DamageHealed")
                local history = folder:FindFirstChild("PlayerHistory")

                local playerNames = {}
                if history then
                    for _, entry in ipairs(history:GetChildren()) do
                        table.insert(playerNames, entry.Name)
                    end
                end
                if damageFolder then
                    for _, val in ipairs(damageFolder:GetChildren()) do
                        if not table.find(playerNames, val.Name) then
                            table.insert(playerNames, val.Name)
                        end
                    end
                end
                if healFolder then
                    for _, val in ipairs(healFolder:GetChildren()) do
                        if not table.find(playerNames, val.Name) then
                            table.insert(playerNames, val.Name)
                        end
                    end
                end

                for _, playerName in ipairs(playerNames) do
                    if not seenPlayers[playerName] then
                        seenPlayers[playerName] = { team = teamColor }
                    end
                end
            end
        end

        -- Build stats only for online players
        local playerStats = {}
        for playerName, info in pairs(seenPlayers) do
            local teamColor = info.team
            local player = Players:FindFirstChild(playerName)
            if player then   -- ONLY ONLINE
                -- Damage/Healed from TeamSettings
                local damage, healed = 0, 0
                local teamFolder = TeamSettings:FindFirstChild(teamColor)
                if teamFolder then
                    local dmg = teamFolder:FindFirstChild("DamageDealt")
                    if dmg then
                        local val = dmg:FindFirstChild(playerName)
                        if val and val:IsA("NumberValue") then damage = val.Value end
                    end
                    local hl = teamFolder:FindFirstChild("DamageHealed")
                    if hl then
                        local val = hl:FindFirstChild(playerName)
                        if val and val:IsA("NumberValue") then healed = val.Value end
                    end
                end

                -- Online stats
                local timePlayed = "N/A"
                local firstJoin = "N/A"
                local robuxSpent = "N/A"
                local highestLevel = "N/A"

                local stats = player:FindFirstChild("Stats")
                if stats then
                    local tp = stats:FindFirstChild("timePlayed")
                    if tp and tp:IsA("NumberValue") then timePlayed = formatTime(tp.Value) end
                    local fj = stats:FindFirstChild("firstJoinTime")
                    if fj and fj:IsA("NumberValue") then firstJoin = safeFormatDate(fj.Value) end
                    local rs = stats:FindFirstChild("robuxSpent")
                    if rs and rs:IsA("NumberValue") then robuxSpent = tostring(rs.Value) end
                    local lvls = stats:FindFirstChild("levelsRewarded")
                    if lvls then
                        local maxLvl = 0
                        for _, child in ipairs(lvls:GetChildren()) do
                            if child:IsA("NumberValue") then
                                if child.Value > maxLvl then maxLvl = child.Value end
                            elseif tonumber(child.Name) and tonumber(child.Name) > maxLvl then
                                maxLvl = tonumber(child.Name)
                            end
                        end
                        if maxLvl > 0 then highestLevel = tostring(maxLvl) end
                    end
                end

                table.insert(playerStats, {
                    name = playerName,
                    team = teamColor,
                    damage = damage,
                    healed = healed,
                    timePlayed = timePlayed,
                    firstJoin = firstJoin,
                    robuxSpent = robuxSpent,
                    level = highestLevel
                })
            end
        end

        -- Sort by damage descending
        table.sort(playerStats, function(a, b)
            return a.damage > b.damage
        end)

        -- Build text block
        for _, ps in ipairs(playerStats) do
            local lines = {}
            table.insert(lines, string.format("%s%s [%s]",
                GetTeamEmoji(ps.team),
                ShortColorName(ps.team),
                ps.name
            ))
            table.insert(lines, string.format("  DMG: %d | HEAL: %d", ps.damage, ps.healed))
            table.insert(lines, string.format("  Time: %s", ps.timePlayed))
            table.insert(lines, string.format("  Joined: %s", ps.firstJoin))
            table.insert(lines, string.format("  Robux: %s", ps.robuxSpent))
            table.insert(lines, string.format("  Level: %s", ps.level))
            table.insert(blocks, table.concat(lines, "\n"))
        end

        if #blocks == 0 then
            table.insert(blocks, "No online players.")
        end

        output[i] = table.concat(blocks, "\n\n")
    end

    return output
end

local lastPlayerInfoUpdate = 0
local PI_INTERVAL = 1.0   -- refresh every second

RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastPlayerInfoUpdate < PI_INTERVAL then return end
    lastPlayerInfoUpdate = now

    local allianceTexts = getPlayerStats()
    for i = 1, 3 do
        if PI_Labels[i] then
            PI_Labels[i]:SetText(allianceTexts[i] or "No data.")
            ResizePIBox(PI_Labels[i], PI_Groups[i])
        end
    end
end)


-- === BUILDING NOTIFICATION FEATURE (REWORKED, ROBLOX NOTIFICATIONS) ===

local BuildingMessages = {
    ["Airport"] = {
        msg = "PLACED AN AIRPORT",
        emoji = "✈️",
        toggle = "Notify_Airport"
    },
    ["Barracks"] = {
        msg = "PLACED A BARRACKS",
        emoji = "⚔️",
        toggle = "Notify_Barracks"
    },
    ["Fort"] = {
        msg = "PLACED A FORT",
        emoji = "🏰",
        toggle = "Notify_Fort"
    },
    ["Naval Shipyard"] = {
        msg = "PLACED A NAVAL SHIPYARD",
        emoji = "⚓",
        toggle = "Notify_Shipyard"
    },
    ["Nuclear Silo"] = {
        msg = "PLACED A NUCLEAR SILO",
        emoji = "☢️☢️",
        toggle = "Notify_Nuke"
    },
    ["Shield Generator"] = {
        msg = "PLACED A SHIELD GENERATOR",
        emoji = "🛡️",
        toggle = "Notify_ShieldGen"
    },
    ["Space Link"] = {
        msg = "PLACED A SPACE LINK",
        emoji = "🛰️",
        toggle = "Notify_SpaceLink"
    },
    ["Tank Factory"] = {
        msg = "PLACED A TANK FACTORY",
        emoji = "🚜",
        toggle = "Notify_TankFactory"
    }
}



local function GetBuilderName(teamColor)
    local folder = TeamSettings:FindFirstChild(teamColor)
    if not folder then return "UNKNOWN" end

    local history = folder:FindFirstChild("PlayerHistory")
    if not history then return "UNKNOWN" end

    for _, entry in ipairs(history:GetChildren()) do
        local name = entry.Name
        if Players:FindFirstChild(name) then
            return name
        end
    end

    return "UNKNOWN"
end

local lastPosition = nil

local function WatchTeam(teamFolder)
    teamFolder.ChildAdded:Connect(function(building)
        if not Toggles.NotifyBuildings.Value then return end

        local data = BuildingMessages[building.Name]
        if not data then return end

        if Toggles[data.toggle] and not Toggles[data.toggle].Value then
            return
        end

        local buildingColor = teamFolder.Name

        if Toggles.TeamCheck.Value then
            if not IsEnemyTeamColor(buildingColor) then
                return
            end
        end

        local shortColor = ShortColorName(buildingColor)
        local teamEmoji = GetTeamEmoji(buildingColor)
        local builderName = GetBuilderName(buildingColor)

        local emoji = data.emoji
        local title = emoji .. " Building Placed " .. emoji

        local text = string.format(
            "%s%s | %s %s%s",
            teamEmoji,
            shortColor,
            builderName,
            data.msg,
            teamEmoji
        )

        local tpCallback = Instance.new("BindableFunction")
        tpCallback.OnInvoke = function(btn)
            if btn ~= "TELEPORT" then return end

            local character = LocalPlayer.Character
            if not character then return end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            lastPosition = hrp.CFrame

            local pivot = building:GetPivot()
            hrp.CFrame = CFrame.new(pivot.Position + Vector3.new(0, 5, 0))

            local backCallback = Instance.new("BindableFunction")
            backCallback.OnInvoke = function(b)
                if b == "GO BACK" and lastPosition then
                    local char2 = LocalPlayer.Character
                    if char2 and char2:FindFirstChild("HumanoidRootPart") then
                        char2.HumanoidRootPart.CFrame = lastPosition
                    end
                end
            end

            StarterGui:SetCore("SendNotification", {
                Title = "Return?",
                Text = "Go back to your previous location",
                Duration = 10,
                Button1 = "GO BACK",
                Callback = backCallback
            })
        end

        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 10,
            Button1 = "TELEPORT",
            Callback = tpCallback
        })
    end)
end

for _, folder in ipairs(TeamsFolder:GetChildren()) do
    WatchTeam(folder)
end

TeamsFolder.ChildAdded:Connect(function(folder)
    WatchTeam(folder)
end)


-- === STANDALONE HIGHLIGHTER (CENTRALIZED CONTROLS) ===

local ActiveHighlights = {} -- [BasePart] = Highlight

local function getAnyAdornee(instance)
    if instance:IsA("BasePart") or instance:IsA("MeshPart") or instance:IsA("UnionOperation") then
        return instance
    end
    return instance:FindFirstChildWhichIsA("BasePart", true)
        or instance:FindFirstChildWhichIsA("MeshPart", true)
        or instance:FindFirstChildWhichIsA("UnionOperation", true)
end

local function getModelName(instance)
    local m = instance
    while m and m ~= TeamsFolder do
        if m:IsA("Model") then
            return m.Name
        end
        m = m.Parent
    end
    return nil
end

-- Returns fill and outline colours based on the selected mode
local function getHighlightColors()
    local mode = Options.HighlightMode.Value
    if mode == 'Team Color' then
        return Color3.new(1, 1, 1), Color3.new(0, 0, 0)
    elseif mode == 'RGB' then
        local hue = (tick() * 0.5) % 1
        local rgb = Color3.fromHSV(hue, 1, 1)
        local outline = rgb:Lerp(Color3.new(0, 0, 0), 0.3)
        return rgb, outline
    else -- Custom
        local fill = Options.HighlightCustomFillColor.Value
        local outline = Options.HighlightCustomOutlineColor.Value
        return fill, outline
    end
end

local function createHighlight(adornee, modelName, teamColor)
    if not adornee then return end
    if ActiveHighlights[adornee] and ActiveHighlights[adornee].Parent then
        return ActiveHighlights[adornee]
    end

    local fill, outline = getHighlightColors()

    -- If Team Color mode and we have a team colour, override the placeholders
    if Options.HighlightMode.Value == 'Team Color' and teamColor then
        fill = teamColor
        outline = teamColor:Lerp(Color3.new(0, 0, 0), 0.3)
    end

    local h = Instance.new("Highlight")
    h.Adornee = adornee
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillColor = fill
    h.FillTransparency = Options.HighlightTransparency.Value
    h.OutlineColor = outline
    h.OutlineTransparency = 1 - Options.HighlightOutlineThickness.Value
    h.Parent = adornee

    ActiveHighlights[adornee] = h
    return h
end

function removeHighlightFor(instance)
    local h = ActiveHighlights[instance]
    if h then
        h:Destroy()
        ActiveHighlights[instance] = nil
    end
end

-- HIGHLIGHT REFRESH DEBOUNCE

local highlightDirty = false

local function RefreshAllHighlights()
    for adornee, h in pairs(ActiveHighlights) do
        if h then h:Destroy() end
    end
    ActiveHighlights = {}
    for _, inst in ipairs(TeamsFolder:GetDescendants()) do
        handleInstance(inst)
    end
end

local function QueueHighlightRefresh()
    if highlightDirty then return end
    highlightDirty = true
    task.defer(function()
        highlightDirty = false
        RefreshAllHighlights()
    end)
end

local function HookESPOption(id)
    if Toggles[id] then
        Toggles[id]:OnChanged(function()
            if Toggles.EnableHighlighter.Value then
                QueueHighlightRefresh()
            end
        end)
    end
    if Options[id] then
        Options[id]:OnChanged(function()
            if Toggles.EnableHighlighter.Value then
                QueueHighlightRefresh()
            end
        end)
    end
end

-- Hook only the unit toggles (no more per‑unit colour pickers)
local ESP_IDS = {
    "ESP_Soldier_AntiAir", "ESP_Soldier_Construction", "ESP_Soldier_Hovercraft",
    "ESP_Soldier_Juggernaut", "ESP_Soldier_Medic", "ESP_Soldier_Sniper",

    "ESP_Air_Helicopter", "ESP_Air_Mothership", "ESP_Air_SpaceFighter",
    "ESP_Air_StealthBomber", "ESP_Air_TransportPlane",

    "ESP_Tank_AntiAir", "ESP_Tank_Explosive", "ESP_Tank_Heavy",

    "ESP_Navy_AircraftCarrier", "ESP_Navy_TransportShip",

    "ESP_Prod_Airport", "ESP_Prod_Barracks", "ESP_Prod_Fort",
    "ESP_Prod_Shipyard", "ESP_Prod_SpaceLink", "ESP_Prod_TankFactory",
    "ESP_Prod_NuclearPlant", "ESP_Prod_PowerPlant",

    "ESP_Build_AntiAirTurret", "ESP_Build_CommandCenter", "ESP_Build_Headquarters",
    "ESP_Build_NavalHouse", "ESP_Build_PlaneHouse", "ESP_Build_ShieldGen",
    "ESP_Build_SoldierHouse", "ESP_Build_TankHouse", "ESP_Build_Turret"
}

for _, id in ipairs(ESP_IDS) do
    HookESPOption(id .. "_Enabled")
end

-- Hook team checks
HookESPOption("ESP_Soldiers_TeamCheck")
HookESPOption("ESP_Air_TeamCheck")
HookESPOption("ESP_Tanks_TeamCheck")
HookESPOption("ESP_Navy_TeamCheck")
HookESPOption("ESP_Prod_TeamCheck")
HookESPOption("ESP_Buildings_TeamCheck")

-- Hook the new central highlight controls
HookESPOption("HighlightMode")
HookESPOption("HighlightCustomFillColor")
HookESPOption("HighlightCustomOutlineColor")
HookESPOption("HighlightTransparency")
HookESPOption("HighlightOutlineThickness")

local function shouldHighlight(modelName)
    local name = modelName:lower()

    if name == "anti-air soldier" and Toggles.ESP_Soldier_AntiAir_Enabled.Value then return true end
    if name == "construction soldier" and Toggles.ESP_Soldier_Construction_Enabled.Value then return true end
    if name == "hovercraft" and Toggles.ESP_Soldier_Hovercraft_Enabled.Value then return true end
    if name == "juggernaut" and Toggles.ESP_Soldier_Juggernaut_Enabled.Value then return true end
    if name == "medic" and Toggles.ESP_Soldier_Medic_Enabled.Value then return true end
    if name == "sniper" and Toggles.ESP_Soldier_Sniper_Enabled.Value then return true end

    if name == "helicopter" and Toggles.ESP_Air_Helicopter_Enabled.Value then return true end
    if name == "mothership" and Toggles.ESP_Air_Mothership_Enabled.Value then return true end
    if name == "space fighter" and Toggles.ESP_Air_SpaceFighter_Enabled.Value then return true end
    if name == "stealth bomber" and Toggles.ESP_Air_StealthBomber_Enabled.Value then return true end
    if name == "transport plane" and Toggles.ESP_Air_TransportPlane_Enabled.Value then return true end

    if name == "anti-air tank" and Toggles.ESP_Tank_AntiAir_Enabled.Value then return true end
    if name == "explosive tank" and Toggles.ESP_Tank_Explosive_Enabled.Value then return true end
    if name == "heavy tank" and Toggles.ESP_Tank_Heavy_Enabled.Value then return true end

    if name == "aircraft carrier" and Toggles.ESP_Navy_AircraftCarrier_Enabled.Value then return true end
    if name == "transport ship" and Toggles.ESP_Navy_TransportShip_Enabled.Value then return true end

    if name == "airport" and Toggles.ESP_Prod_Airport_Enabled.Value then return true end
    if name == "barracks" and Toggles.ESP_Prod_Barracks_Enabled.Value then return true end
    if name == "fort" and Toggles.ESP_Prod_Fort_Enabled.Value then return true end
    if name == "naval shipyard" and Toggles.ESP_Prod_Shipyard_Enabled.Value then return true end
    if name == "space link" and Toggles.ESP_Prod_SpaceLink_Enabled.Value then return true end
    if name == "tank factory" and Toggles.ESP_Prod_TankFactory_Enabled.Value then return true end
    if name == "nuclear plant" and Toggles.ESP_Prod_NuclearPlant_Enabled.Value then return true end
    if name == "power plant" and Toggles.ESP_Prod_PowerPlant_Enabled.Value then return true end

    if name == "anti-air turret" and Toggles.ESP_Build_AntiAirTurret_Enabled.Value then return true end
    if name == "command center" and Toggles.ESP_Build_CommandCenter_Enabled.Value then return true end
    if name == "headquarters" and Toggles.ESP_Build_Headquarters_Enabled.Value then return true end
    if name == "naval house" and Toggles.ESP_Build_NavalHouse_Enabled.Value then return true end
    if name == "plane house" and Toggles.ESP_Build_PlaneHouse_Enabled.Value then return true end
    if name == "shield generator" and Toggles.ESP_Build_ShieldGen_Enabled.Value then return true end
    if name == "soldier house" and Toggles.ESP_Build_SoldierHouse_Enabled.Value then return true end
    if name == "tank house" and Toggles.ESP_Build_TankHouse_Enabled.Value then return true end
    if name == "turret" and Toggles.ESP_Build_Turret_Enabled.Value then return true end

    return false
end

local function categoryTeamCheck(modelName)
    local name = modelName:lower()

    if name:find("soldier") or name == "hovercraft" or name == "juggernaut" then
        return Toggles.ESP_Soldiers_TeamCheck.Value
    end
    if name == "helicopter" or name == "mothership" or name == "space fighter"
    or name == "stealth bomber" or name == "transport plane" then
        return Toggles.ESP_Air_TeamCheck.Value
    end
    if name:find("tank") then
        return Toggles.ESP_Tanks_TeamCheck.Value
    end
	if name == "aircraft carrier" or name == "transport ship" then
		return Toggles.ESP_Navy_TeamCheck.Value
	end
    if name == "airport" or name == "barracks" or name == "fort"
    or name == "naval shipyard" or name == "space link" or name == "tank factory"
    or name == "nuclear plant" or name == "power plant" then
        return Toggles.ESP_Prod_TeamCheck.Value
    end
    return Toggles.ESP_Buildings_TeamCheck.Value
end

function GetTeamColorFromInstance(inst)
    local obj = inst
    while obj and obj ~= TeamsFolder do
        if obj.Parent == TeamsFolder then
            return obj.Name
        end
        obj = obj.Parent
    end
    return nil
end

handleInstance = function(instance)
    local adornee = getAnyAdornee(instance)
    if not adornee then return end

    local modelName = getModelName(instance)
    if not modelName then return end

    if categoryTeamCheck(modelName) then
        local teamColor = GetTeamColorFromInstance(instance)
        if teamColor and not IsEnemyTeamColor(teamColor) then
            return
        end
    end

    if not shouldHighlight(modelName) then
        return
    end

    -- Determine team colour for Team Color mode
    local teamColor = nil
    if Options.HighlightMode.Value == 'Team Color' then
        local teamName = GetTeamColorFromInstance(instance)
        if teamName then
            teamColor = GetTeamColorForFolder_ESP(TeamsFolder:FindFirstChild(teamName))
        end
    end

    createHighlight(adornee, modelName, teamColor)
end

-- Immediately highlight new units / buildings as they appear
TeamsFolder.DescendantAdded:Connect(function(descendant)
    if Toggles.EnableHighlighter.Value then
        handleInstance(descendant)
    end
end)

local function startHighlighter()
    RefreshAllHighlights()
end

local function stopHighlighter()
    for adornee, h in pairs(ActiveHighlights) do
        if h then h:Destroy() end
    end
    ActiveHighlights = {}
end

Toggles.EnableHighlighter:OnChanged(function()
    if Toggles.EnableHighlighter.Value then
        startHighlighter()
    else
        stopHighlighter()
    end
end)


-- Continuous RGB animation (uses global speed + smoothness)
local lastRGBUpdate = 0
RunService.Heartbeat:Connect(function()
    if not Toggles.EnableHighlighter.Value then return end
    if Options.HighlightMode.Value ~= 'RGB' then return end

    local interval = Options.HighlightRGBSmoothness and Options.HighlightRGBSmoothness.Value or 0.01
    local now = tick()
    if now - lastRGBUpdate < interval then return end
    lastRGBUpdate = now

    local rgb = getGlobalRGBColor()
    local outline = rgb:Lerp(Color3.new(0, 0, 0), 0.3)

    for adornee, hl in pairs(ActiveHighlights) do
        if hl and hl.Parent then
            hl.FillColor = rgb
            hl.OutlineColor = outline
        else
            ActiveHighlights[adornee] = nil
        end
    end
end)



--watermark
Library:SetWatermarkVisibility(true)

--fps counter and ping

local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;
local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    Library:SetWatermark(('LELOUCHWARE V0.10 | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ));
end);

--keybinds
Library.KeybindFrame.Visible = false;

Library:OnUnload(function()
    WatermarkConnection:Disconnect()

    print('Unloaded!')
    Library.Unloaded = true
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function()
    Library:Unload()
end)

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End',
    NoUI = false,
    Text = 'Menu keybind'
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('CQ3UI/themes')
SaveManager:SetFolder('CQ3UI')

SaveManager:BuildConfigSection(Tabs['UI Settings'])

ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()
