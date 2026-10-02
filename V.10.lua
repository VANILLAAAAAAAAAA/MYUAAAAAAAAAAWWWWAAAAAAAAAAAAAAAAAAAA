-- ============================================================
-- LELOUCHWARE V0.11 - RESTRUCTURED
-- One heartbeat. One dispatcher. One highlight manager.
-- ============================================================

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Players      = game:GetService("Players")
local StarterGui   = game:GetService("StarterGui")
local RunService   = game:GetService("RunService")
local HttpService  = game:GetService("HttpService")
local TeamsService = game:GetService("Teams")

local LocalPlayer  = Players.LocalPlayer
local TeamSettings = workspace:WaitForChild("TeamSettings")
local TeamsFolder  = workspace:WaitForChild("Teams")

-- ============================================================
-- WINDOW & TABS
-- ============================================================
local Window = Library:CreateWindow({
    Title = 'BY UNKER AND LELOUCH, WITH THANKS TO BIG 30, OTF JAM AND JORDAN',
    Center = true, AutoShow = true, TabPadding = 8, MenuFadeTime = 0.2
})
Window.ShowInToggleKeybind = false

local Tabs = {
    Nuke          = Window:AddTab('Nuke'),
    NukeInfo      = Window:AddTab('Nuke Info'),
    ESP           = Window:AddTab('ESP'),
    Notifications = Window:AddTab('Notify'),
    Garrison      = Window:AddTab('Misc'),
    RGB           = Window:AddTab('RGB'),
    PlayerInfo    = Window:AddTab('Player Info'),
    ['UI Settings'] = Window:AddTab('UI'),
}

-- ============================================================
-- TEAM DATA - cached team facts (never re-walks folders per frame)
-- ============================================================
local TeamData = {
    _myTeamColor     = nil,
    _myAlliedColors  = nil,
    _alliances       = nil,
    _teamColorByName = {},
    _playerHistory   = {},   -- [teamName] = {names...}
}

function TeamData.invalidateMyTeam()  TeamData._myTeamColor = nil; TeamData._myAlliedColors = nil end
function TeamData.invalidateAlliances() TeamData._alliances = nil end
function TeamData.invalidateTeamColor(name) TeamData._teamColorByName[name] = nil end
function TeamData.invalidatePlayerHistory(name) TeamData._playerHistory[name] = nil end

function TeamData.getMyTeamColor()
    if not TeamData._myTeamColor then
        TeamData._myTeamColor = LocalPlayer.TeamColor and LocalPlayer.TeamColor.Name or nil
    end
    return TeamData._myTeamColor
end

function TeamData.getMyAlliedColors()
    if TeamData._myAlliedColors then return TeamData._myAlliedColors end
    local myColor = TeamData.getMyTeamColor()
    local allies = {}
    if myColor then
        local folder = TeamSettings:FindFirstChild(myColor)
        local alliesFolder = folder and folder:FindFirstChild("Allies")
        if alliesFolder then
            for _, a in ipairs(alliesFolder:GetChildren()) do
                table.insert(allies, a.Name)
            end
        end
    end
    TeamData._myAlliedColors = allies
    return allies
end

function TeamData.isEnemy(colorName)
    if colorName == nil then return false end
    if colorName == TeamData.getMyTeamColor() then return false end
    for _, ally in ipairs(TeamData.getMyAlliedColors()) do
        if ally == colorName then return false end
    end
    return true
end

function TeamData.getColor(teamFolderOrName)
    local name
    if type(teamFolderOrName) == "string" then name = teamFolderOrName
    elseif teamFolderOrName then name = teamFolderOrName.Name else return Color3.new(1,1,1) end
    local cached = TeamData._teamColorByName[name]
    if cached then return cached end

    local ok, brick = pcall(BrickColor.new, name)
    if ok and brick then
        TeamData._teamColorByName[name] = brick.Color
        return brick.Color
    end
    for _, team in ipairs(TeamsService:GetChildren()) do
        if team.Name == name and team.TeamColor then
            TeamData._teamColorByName[name] = team.TeamColor.Color
            return team.TeamColor.Color
        end
        if team.TeamColor and team.TeamColor.Name == name then
            TeamData._teamColorByName[name] = team.TeamColor.Color
            return team.TeamColor.Color
        end
    end
    TeamData._teamColorByName[name] = Color3.new(1,1,1)
    return Color3.new(1,1,1)
end

function TeamData.getPlayerHistory(teamColor)
    local cached = TeamData._playerHistory[teamColor]
    if cached then return cached end
    local folder = TeamSettings:FindFirstChild(teamColor)
    local history = folder and folder:FindFirstChild("PlayerHistory")
    local names = {}
    if history then
        for _, entry in ipairs(history:GetChildren()) do
            table.insert(names, entry.Name)
        end
    end
    TeamData._playerHistory[teamColor] = names
    return names
end


-- Returns the name of the currently-online player on this team, or nil.
-- Scans Players directly — always fresh, no caching, no invalidation needed.
function TeamData.getOnlinePlayer(teamColor)
    if not teamColor then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.TeamColor and plr.TeamColor.Name == teamColor then
            return plr.Name
        end
    end
    return nil
end




function TeamData.getAllAlliances()
    if TeamData._alliances then return TeamData._alliances end
    local alliances, used = {}, {}
    for _, teamFolder in ipairs(TeamSettings:GetChildren()) do
        local color = teamFolder.Name
        if not used[color] then
            local list = { color }; used[color] = true
            local alliesFolder = teamFolder:FindFirstChild("Allies")
            if alliesFolder then
                for _, ally in ipairs(alliesFolder:GetChildren()) do
                    if TeamSettings:FindFirstChild(ally.Name) then
                        table.insert(list, ally.Name); used[ally.Name] = true
                    end
                end
            end
            table.insert(alliances, list)
        end
    end
    TeamData._alliances = alliances
    return alliances
end

-- Invalidation wiring
LocalPlayer:GetPropertyChangedSignal("TeamColor"):Connect(function()
    TeamData.invalidateMyTeam()
end)

TeamSettings.ChildAdded:Connect(function(child)
    TeamData.invalidateAlliances()
    TeamData.invalidateTeamColor(child.Name)
    child.ChildAdded:Connect(function(sub)
        if sub.Name == "Allies" then
            TeamData.invalidateMyTeam(); TeamData.invalidateAlliances()
        elseif sub.Name == "PlayerHistory" then
            TeamData.invalidatePlayerHistory(child.Name)
            sub.ChildAdded:Connect(function() TeamData.invalidatePlayerHistory(child.Name) end)
            sub.ChildRemoved:Connect(function() TeamData.invalidatePlayerHistory(child.Name) end)
        end
    end)
end)
TeamSettings.ChildRemoved:Connect(function(child)
    TeamData.invalidateAlliances()
    TeamData.invalidateTeamColor(child.Name)
    TeamData.invalidatePlayerHistory(child.Name)
end)

-- Watch for any change inside any team's Allies folder.
-- Uses ChildAdded/ChildRemoved on each Allies folder directly — DescendantRemoved
-- is not available in every Roblox/executor environment, but these are.
local _hookedAlliesFolders = setmetatable({}, {__mode = "k"})

local function hookAlliesFolder(alliesFolder)
    if not alliesFolder then return end
    if _hookedAlliesFolders[alliesFolder] then return end
    _hookedAlliesFolders[alliesFolder] = true

    alliesFolder.ChildAdded:Connect(function()
        TeamData.invalidateMyTeam()
        TeamData.invalidateAlliances()
    end)
    alliesFolder.ChildRemoved:Connect(function()
        TeamData.invalidateMyTeam()
        TeamData.invalidateAlliances()
    end)
end

-- Hook every Allies folder that already exists at startup
for _, teamFolder in ipairs(TeamSettings:GetChildren()) do
    local af = teamFolder:FindFirstChild("Allies")
    if af then hookAlliesFolder(af) end
end

-- Hook allies folders for teams that get added later, and handle the case
-- where a team exists but its Allies folder is created after we started.
TeamSettings.ChildAdded:Connect(function(child)
    local af = child:FindFirstChild("Allies")
    if af then
        hookAlliesFolder(af)
    else
        -- Allies folder may appear later; watch for it
        child.ChildAdded:Connect(function(sub)
            if sub.Name == "Allies" then
                hookAlliesFolder(sub)
                TeamData.invalidateMyTeam()
                TeamData.invalidateAlliances()
            end
        end)
    end
end)



-- ============================================================
-- TEAM FOLDER NAME-CHANGE WATCHER
-- When a player switches colors, the game frequently renames the
-- TeamSettings folder in place — same Instance, new .Name. ChildAdded
-- and ChildRemoved do NOT fire for renames, so our name-keyed caches
-- (_alliances, _myAlliedColors, _teamColorByName) go stale and every
-- downstream system (Player Info, Nuke Info, isEnemy, getColor) starts
-- reporting the wrong team. Hook the rename signal and wipe caches.
-- ============================================================
local function onTeamRenameOrAddRemove()
    TeamData._myTeamColor     = nil
    TeamData._myAlliedColors  = nil
    TeamData._alliances       = nil
    TeamData._teamColorByName = {}
    TeamData._playerHistory   = {}
end

local _nameWatched = setmetatable({}, {__mode = "k"})
local function watchTeamName(folder)
    if not folder or _nameWatched[folder] then return end
    _nameWatched[folder] = true
    folder:GetPropertyChangedSignal("Name"):Connect(onTeamRenameOrAddRemove)
end

for _, f in ipairs(TeamSettings:GetChildren()) do
    watchTeamName(f)
end

TeamSettings.ChildAdded:Connect(function(child)
    watchTeamName(child)
    onTeamRenameOrAddRemove()
end)

TeamSettings.ChildRemoved:Connect(function()
    onTeamRenameOrAddRemove()
end)






-- ============================================================
-- GLOBAL RGB PROVIDER (shared by every ESP subsystem)
-- ============================================================
function getGlobalRGBColor()
    local speed = Options.RGBSpeed and Options.RGBSpeed.Value or 1
    return Color3.fromHSV((tick() * speed) % 1, 1, 1)
end

-- ============================================================
-- NOTIFIER - one SendNotification helper
-- ============================================================
local Notifier = {}
function Notifier.send(title, text, buttons, duration)
    -- buttons: optional array of {label = string, callback = function}
    local payload = { Title = title, Text = text, Duration = duration or 5 }
    if buttons and buttons[1] then
        payload.Button1 = buttons[1].label
        local cb = Instance.new("BindableFunction")
        cb.OnInvoke = function(btn)
            for _, b in ipairs(buttons) do
                if btn == b.label then b.callback(); return end
            end
        end
        payload.Callback = cb
    end
    StarterGui:SetCore("SendNotification", payload)
end




-- Walk up the Roblox GUI hierarchy; returns false if any ancestor is hidden.
local function isAncestorVisible(inst)
    local cur = inst
    while cur and cur ~= game do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        cur = cur.Parent
    end
    return true
end

local function getLabelObject(lbl)
    if not lbl then return nil end
    return lbl.TextLabel or lbl.Object or lbl.Frame or lbl.Instance or lbl
end

local function labelIsVisible(lbl)
    local obj = getLabelObject(lbl)
    if not obj then return false end
    if typeof(obj) == "Instance" and obj:IsA("GuiObject") then
        return isAncestorVisible(obj)
    end
    return obj.Visible ~= false
end










-- ============================================================
-- HIGHLIGHT MANAGER - one system, N sources
-- styleFn(modelOrAdornee) -> fill, outline, fillTrans, outlineTrans
-- ============================================================
local HighlightManager = { active = {} }

function HighlightManager.attach(adornee, styleFn)
    local existing = HighlightManager.active[adornee]
    if existing then existing.style = styleFn; return end
    local h = Instance.new("Highlight")
    h.Adornee = adornee
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = adornee
    HighlightManager.active[adornee] = { h = h, style = styleFn }
    HighlightManager._apply(adornee, HighlightManager.active[adornee])
end

function HighlightManager.detach(adornee)
    local entry = HighlightManager.active[adornee]
    if entry then
        if entry.h then entry.h:Destroy() end
        HighlightManager.active[adornee] = nil
    end
end

function HighlightManager._apply(adornee, entry)
    local fill, outline, ft, ot = entry.style(adornee)
    if not fill then return end
    entry.h.FillColor = fill
    entry.h.OutlineColor = outline
    entry.h.FillTransparency = ft
    entry.h.OutlineTransparency = ot
end

function HighlightManager.tick()
    for adornee, entry in pairs(HighlightManager.active) do
        if not adornee.Parent or not entry.h or not entry.h.Parent then
            HighlightManager.detach(adornee)
        else
            HighlightManager._apply(adornee, entry)
        end
    end
end

function HighlightManager.detachAll()
    for adornee in pairs(HighlightManager.active) do HighlightManager.detach(adornee) end
end

-- ============================================================
-- ESP TAB UI
-- ============================================================
local ESP_Control = Tabs.ESP:AddLeftGroupbox('HIGHLIGHT CONTROL')

ESP_Control:AddToggle('EnableHighlighter', { Text = 'Enable Highlighter', Default = false })
ESP_Control:AddDropdown('HighlightMode', {
    Values = { 'RGB', 'Team Color', 'Custom' }, Default = 'Team Color',
    Multi = false, Text = 'Highlight Mode'
})
ESP_Control:AddLabel('Custom Fill'):AddColorPicker('HighlightCustomFillColor',
    { Default = Color3.fromRGB(255,0,0), Title = 'Custom Fill Colour' })
ESP_Control:AddLabel('Custom Outline'):AddColorPicker('HighlightCustomOutlineColor',
    { Default = Color3.fromRGB(255,255,255), Title = 'Custom Outline Colour' })
ESP_Control:AddSlider('HighlightTransparency',
    { Text = 'Fill Transparency', Default = 0.5, Min = 0, Max = 1, Rounding = 2, Compact = false })
ESP_Control:AddSlider('HighlightOutlineThickness',
    { Text = 'Outline Thickness', Default = 1, Min = 0, Max = 1, Rounding = 2, Compact = false })

local ESP_Soldiers   = Tabs.ESP:AddLeftGroupbox('SOLDIERS')
local ESP_Air        = Tabs.ESP:AddLeftGroupbox('AIR')
local ESP_Tanks      = Tabs.ESP:AddLeftGroupbox('TANKS')
local ESP_Navy       = Tabs.ESP:AddLeftGroupbox('NAVY')
local ESP_ProdBuilds = Tabs.ESP:AddRightGroupbox('PRODUCTION BUILDINGS')
local ESP_Buildings  = Tabs.ESP:AddRightGroupbox('BUILDINGS')

local function CreateESPUnitToggle(g, id, text) g:AddToggle(id, { Text = text, Default = false }) end

ESP_Soldiers:AddToggle('ESP_Soldiers_TeamCheck', { Text = 'Team Check', Default = true }); ESP_Soldiers:AddDivider()
ESP_Air:AddToggle('ESP_Air_TeamCheck',          { Text = 'Team Check', Default = true }); ESP_Air:AddDivider()
ESP_Tanks:AddToggle('ESP_Tanks_TeamCheck',      { Text = 'Team Check', Default = true }); ESP_Tanks:AddDivider()
ESP_Navy:AddToggle('ESP_Navy_TeamCheck',        { Text = 'Team Check', Default = true }); ESP_Navy:AddDivider()
ESP_ProdBuilds:AddToggle('ESP_Prod_TeamCheck',  { Text = 'Team Check', Default = true }); ESP_ProdBuilds:AddDivider()
ESP_Buildings:AddToggle('ESP_Buildings_TeamCheck',{ Text = 'Team Check', Default = true }); ESP_Buildings:AddDivider()

CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_AntiAir_Enabled',      'Anti-Air Soldier')
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_Construction_Enabled', 'Construction Soldier')
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_Hovercraft_Enabled',   'Hovercraft')
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_Juggernaut_Enabled',   'Juggernaut')
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_Medic_Enabled',        'Medic')
CreateESPUnitToggle(ESP_Soldiers, 'ESP_Soldier_Sniper_Enabled',       'Sniper')

CreateESPUnitToggle(ESP_Air, 'ESP_Air_Helicopter_Enabled',      'Helicopter')
CreateESPUnitToggle(ESP_Air, 'ESP_Air_Mothership_Enabled',      'Mothership')
CreateESPUnitToggle(ESP_Air, 'ESP_Air_SpaceFighter_Enabled',    'Space Fighter')
CreateESPUnitToggle(ESP_Air, 'ESP_Air_StealthBomber_Enabled',   'Stealth Bomber')
CreateESPUnitToggle(ESP_Air, 'ESP_Air_TransportPlane_Enabled',  'Transport Plane')

CreateESPUnitToggle(ESP_Tanks, 'ESP_Tank_AntiAir_Enabled',    'Anti-Air Tank')
CreateESPUnitToggle(ESP_Tanks, 'ESP_Tank_Explosive_Enabled',  'Explosive Tank')
CreateESPUnitToggle(ESP_Tanks, 'ESP_Tank_Heavy_Enabled',      'Heavy Tank')

CreateESPUnitToggle(ESP_Navy, 'ESP_Navy_AircraftCarrier_Enabled', 'Aircraft Carrier')
CreateESPUnitToggle(ESP_Navy, 'ESP_Navy_TransportShip_Enabled',   'Transport Ship')

CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_Airport_Enabled',      'Airport')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_Barracks_Enabled',     'Barracks')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_Fort_Enabled',         'Fort')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_Shipyard_Enabled',     'Shipyard')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_SpaceLink_Enabled',    'Space Link')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_TankFactory_Enabled',  'Tank Factory')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_NuclearPlant_Enabled', 'Nuclear Plant')
CreateESPUnitToggle(ESP_ProdBuilds, 'ESP_Prod_PowerPlant_Enabled',   'Power Plant')

CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_AntiAirTurret_Enabled',  'Anti-Air Turret')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_CommandCenter_Enabled',  'Command Center')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_Headquarters_Enabled',   'Headquarters')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_NavalHouse_Enabled',     'Naval House')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_PlaneHouse_Enabled',     'Plane House')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_ShieldGen_Enabled',      'Shield Generator')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_SoldierHouse_Enabled',   'Soldier House')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_TankHouse_Enabled',      'Tank House')
CreateESPUnitToggle(ESP_Buildings, 'ESP_Build_Turret_Enabled',         'Turret')




-- ============================================================
-- RANGE INDICATOR - rings cloned from the game's own ring object,
-- captured the first time you hover any friendly unit.
-- Reuses TeamData.isEnemy for team checks.
-- ============================================================
local RANGE_TABLE = {
    ["Scout"]               = 12,
    ["Light Soldier"]       = 15,
    ["Heavy Soldier"]       = 15,
    ["Repairman"]           = 10,
    ["Anti-Air Soldier"]    = 16,
    ["Sniper"]              = 23,
    ["Juggernaut"]          = 15,
    ["Medic"]               = 10,
    ["Hovercraft"]          = 15,

    ["Light Tank"]          = 16,
    ["Heavy Tank"]          = 17,
    ["Anti-Air Tank"]       = 18,
    ["Artillery"]           = 32,

    ["Light Plane"]         = 15,
    ["Heavy Plane"]         = 16,
    ["Helicopter"]          = 14,
    ["Stealth Bomber"]      = 13,

    ["Space Fighter"]       = 16,
    ["Mothership"]          = 18,

    ["Destroyer"]           = 20,
    ["Battleship"]          = 20,
    ["Aircraft Carrier"]    = 27,
    ["Gunboat"]             = 17.5,
    ["Submarine"]           = 16,

    ["Turret"]              = 16,
    ["Anti-Air Turret"]     = 20,
    ["Fort"]                = 25,
    ["Command Center"]      = 27,
    ["Headquarters"]        = 27,
}

-- Category lookup: which group each unit belongs to
local RANGE_CATEGORY = {
    -- Soldiers
    ["Scout"]               = "Soldiers",
    ["Light Soldier"]       = "Soldiers",
    ["Heavy Soldier"]       = "Soldiers",
    ["Repairman"]           = "Soldiers",
    ["Anti-Air Soldier"]    = "Soldiers",
    ["Sniper"]              = "Soldiers",
    ["Juggernaut"]          = "Soldiers",
    ["Medic"]               = "Soldiers",
    ["Hovercraft"]          = "Soldiers",

    -- Tanks
    ["Light Tank"]          = "Tanks",
    ["Heavy Tank"]          = "Tanks",
    ["Anti-Air Tank"]       = "Tanks",
    ["Artillery"]           = "Tanks",

    -- Planes
    ["Light Plane"]         = "Planes",
    ["Heavy Plane"]         = "Planes",
    ["Helicopter"]          = "Planes",
    ["Stealth Bomber"]      = "Planes",

    -- Space
    ["Space Fighter"]       = "Space",
    ["Mothership"]          = "Space",

    -- Naval
    ["Destroyer"]           = "Naval",
    ["Battleship"]          = "Naval",
    ["Aircraft Carrier"]    = "Naval",
    ["Gunboat"]             = "Naval",
    ["Submarine"]           = "Naval",

    -- Defense
    ["Turret"]              = "Defense",
    ["Anti-Air Turret"]     = "Defense",
    ["Fort"]                = "Defense",
    ["Command Center"]      = "Defense",
    ["Headquarters"]        = "Defense",
}

local RangeIndicator = {
    enabled      = false,
    ignoreSelf   = true,
    ignoreTeam   = true,
    distanceCheck  = false,
    maxDistance    = 250,
    disableNearby  = false,
    nearbyDistance = 25,
    categories   = {
        Soldiers = true, Tanks = true, Planes = true,
        Space    = true, Naval = true, Defense = true,
    },
    storedTemplate = nil,
    -- Original template colours, saved on capture for "Default" mode
    defaultOuter       = nil,
    defaultInnerPart   = nil,
    defaultInnerDecal  = nil,
    ringsByUnit  = {},
}

-- Capture the game's ring template on first hover
task.spawn(function()
    while not RangeIndicator.storedTemplate do
        local root   = workspace:FindFirstChild("jliiIij")
        local inner  = root and root:FindFirstChild("jlIilij")
        local ring   = inner and inner:FindFirstChild("Ring")
        local inside = inner and inner:FindFirstChild("Inside")
        if ring and inside then
            RangeIndicator.storedTemplate = inner:Clone()
            RangeIndicator.storedTemplate.Parent = nil

            -- Save original colours from the live game template
            RangeIndicator.defaultOuter = ring.Color
            RangeIndicator.defaultInnerPart = inside.Color
            local decal = inside:FindFirstChildOfClass("Decal")
            RangeIndicator.defaultInnerDecal = decal and decal.Color3 or Color3.new(1,1,1)

            print("[RangeIndicator] template captured")
            if RangeIndicator.enabled then
                task.defer(function() RangeIndicator.rescan() end)
            end
            return
        end
        task.wait(0.25)
    end
end)

local function modelBottomY(model)
    local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
    if ok and cf then return cf.Position.Y - size.Y / 2 end
    local torso = model:FindFirstChild("Torso") or model:FindFirstChildWhichIsA("BasePart")
    return torso and torso.Position.Y or 0
end

function RangeIndicator.attach(unit)
    if not RangeIndicator.storedTemplate then return end
    if RangeIndicator.ringsByUnit[unit] then return end
    if not unit:IsA("Model") then return end
    local r = RANGE_TABLE[unit.Name]
    if not r then return end
    local torso = unit:FindFirstChild("Torso") or unit:FindFirstChildWhichIsA("BasePart")
    if not torso then return end

    if RangeIndicator.ignoreSelf or RangeIndicator.ignoreTeam then
        local tf = unit.Parent
        if not tf or not tf.Parent or tf.Parent ~= TeamsFolder then return end
        local bTeam = tf.Name
        local myTeam = TeamData.getMyTeamColor()
        local isOwner = (bTeam == myTeam)
        local sameTeam = isOwner
        if not sameTeam then
            for _, ally in ipairs(TeamData.getMyAlliedColors()) do
                if ally == bTeam then sameTeam = true; break end
            end
        end
        if RangeIndicator.ignoreSelf and isOwner then return end
        if RangeIndicator.ignoreTeam and sameTeam and not isOwner then return end
    end
	
	    local cat = RANGE_CATEGORY[unit.Name]
    if cat and not RangeIndicator.categories[cat] then return end

    local ring = RangeIndicator.storedTemplate:Clone()
    ring.Name = "RangeRing"
    ring.Parent = workspace

    local entry = { ring = ring, parts = {}, outerPart = nil, innerPart = nil, innerDecal = nil, unit = unit }
    local bottomY = modelBottomY(unit)

    for _, part in ipairs(ring:GetChildren()) do
        if part:IsA("BasePart") then
            part.Anchored    = true
            part.CanCollide  = false
            part.CanQuery    = false
            part.CanTouch    = false
            part.Massless    = true
            part.CastShadow  = false

            part.Size = Vector3.new(r * 2, part.Size.Y * 0.6, r * 2)
            local y = bottomY + part.Size.Y / 2
            local rot = part.CFrame - part.CFrame.Position
            part.CFrame = CFrame.new(torso.Position.X, y, torso.Position.Z) * rot

            table.insert(entry.parts, { part = part, rot = rot })

            if part.Name == "Ring" then
                entry.outerPart = part
            elseif part.Name == "Inside" then
                entry.innerPart = part
                entry.innerDecal = part:FindFirstChildOfClass("Decal")
            end
        end
    end

    entry.yOffset = bottomY - torso.Position.Y
    entry.hidden = false
    RangeIndicator.applyColors(entry)
    RangeIndicator.ringsByUnit[unit] = entry
end

-- Resolve the target colours for the active mode and stamp them on the ring.
function RangeIndicator.applyColors(entry)
    if not entry or not entry.outerPart then return end
    local mode = Options.RangeColorMode and Options.RangeColorMode.Value or 'Default'
    local outerCol, innerCol

    if mode == 'Default' then
        outerCol = RangeIndicator.defaultOuter or Color3.new(1, 0, 0)
        innerCol = RangeIndicator.defaultInnerDecal or Color3.new(1, 1, 1)
    elseif mode == 'Team Colors' then
        local tf = entry.unit and entry.unit.Parent
        local col = (tf and TeamData.getColor(tf.Name)) or Color3.new(1, 0, 0)
        outerCol, innerCol = col, col
    elseif mode == 'Custom' then
        outerCol = Options.RangeOuterColor.Value
        innerCol = Options.RangeInnerColor.Value
    elseif mode == 'RGB' then
        local rgb = getGlobalRGBColor()
        outerCol, innerCol = rgb, rgb
    end

    entry.outerPart.Color = outerCol
    if entry.innerPart then
        entry.innerPart.Color = innerCol
    end
    if entry.innerDecal then
        entry.innerDecal.Color3 = innerCol
    end
end

function RangeIndicator.detach(unit)
    local e = RangeIndicator.ringsByUnit[unit]
    if e then
        if e.ring and e.ring.Parent then e.ring:Destroy() end
        RangeIndicator.ringsByUnit[unit] = nil
    end
end

function RangeIndicator.clearAll()
    for unit in pairs(RangeIndicator.ringsByUnit) do
        RangeIndicator.detach(unit)
    end
end

function RangeIndicator.rescan()
    RangeIndicator.clearAll()
    if not RangeIndicator.enabled then return end
    for _, tf in ipairs(TeamsFolder:GetChildren()) do
        for _, m in ipairs(tf:GetChildren()) do
            if m:IsA("Model") and RANGE_TABLE[m.Name] then
                RangeIndicator.attach(m)
            end
        end
    end
end

function RangeIndicator.onAdded(desc)
    if not RangeIndicator.enabled then return end
    if not desc:IsA("Model") then return end
    if not desc.Parent or desc.Parent.Parent ~= TeamsFolder then return end

    if RANGE_TABLE[desc.Name] then
        RangeIndicator.attach(desc)
    else
        -- name may be a placeholder that gets renamed shortly
        local conn
        conn = desc:GetPropertyChangedSignal("Name"):Connect(function()
            if RANGE_TABLE[desc.Name] then
                conn:Disconnect()
                if RangeIndicator.enabled then RangeIndicator.attach(desc) end
            end
        end)
        task.delay(5, function()
            if conn.Connected then conn:Disconnect() end
        end)
    end
end

-- Reconciles the ring list with reality:
--   * drops rings for units that left Teams (garrisoned, destroyed)
--   * attaches rings to units we're missing (re-deployed, renamed late)
-- Cheap: one pass over Teams per call, short-circuits fast when nothing changed.
function RangeIndicator.maintain()
    if not RangeIndicator.enabled then return end
    if not RangeIndicator.storedTemplate then return end

    -- Detach any unit that's no longer a live descendant of Teams
    for unit in pairs(RangeIndicator.ringsByUnit) do
        if not unit.Parent or not unit:IsDescendantOf(TeamsFolder) then
            RangeIndicator.detach(unit)
        end
    end

    -- Attach any unit we're missing
    for _, tf in ipairs(TeamsFolder:GetChildren()) do
        for _, m in ipairs(tf:GetChildren()) do
            if m:IsA("Model")
               and RANGE_TABLE[m.Name]
               and not RangeIndicator.ringsByUnit[m] then
                RangeIndicator.attach(m)
            end
        end
    end
end


function RangeIndicator.followTick()
    if next(RangeIndicator.ringsByUnit) == nil then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local camPos = cam.CFrame.Position
    local doDist = RangeIndicator.distanceCheck
    local maxD   = RangeIndicator.maxDistance
    local doNear = RangeIndicator.disableNearby
    local nearD  = RangeIndicator.nearbyDistance
    local rgb    = (Options.RangeColorMode and Options.RangeColorMode.Value == 'RGB')

    local dead = nil
    for unit, entry in pairs(RangeIndicator.ringsByUnit) do
        if not unit.Parent then
            dead = dead or {}
            table.insert(dead, unit)
        else
            local torso = unit:FindFirstChild("Torso") or unit:FindFirstChildWhichIsA("BasePart")
            if torso then
                local dist = (camPos - torso.Position).Magnitude
                local shouldHide = (doDist and dist > maxD) or (doNear and dist < nearD)

                -- Toggle visibility by parenting the ring model in/out of workspace
                if shouldHide and not entry.hidden then
                    if entry.ring then entry.ring.Parent = nil end
                    entry.hidden = true
                elseif not shouldHide and entry.hidden then
                    if entry.ring then entry.ring.Parent = workspace end
                    entry.hidden = false
                end

                -- Only update positions while visible
                if not entry.hidden then
                    local x, z = torso.Position.X, torso.Position.Z
                    local baseY = torso.Position.Y + (entry.yOffset or 0)
                    for _, e in ipairs(entry.parts) do
                        local part = e.part
                        local y = baseY + part.Size.Y / 2
                        part.CFrame = CFrame.new(x, y, z) * e.rot
                    end
                    if rgb then
                        RangeIndicator.applyColors(entry)
                    end
                end
            end
        end
    end
    if dead then
        for _, unit in ipairs(dead) do
            RangeIndicator.detach(unit)
        end
    end
end




-- ============================================================
-- NUKE TAB UI
-- ============================================================
local PredictorGroup = Tabs.Nuke:AddLeftGroupbox('Nuke Predictor')
PredictorGroup:AddToggle('PredictorEnabled', { Text = 'Enable Predictor', Default = true })
PredictorGroup:AddToggle('PathwayEnabled',   { Text = 'Show Pathway', Default = false })
PredictorGroup:AddDropdown('PathwayDisappear',
    { Values = { 'On Apex', 'On Impact' }, Default = 'On Apex', Multi = false, Text = 'Pathway Disappears' })
PredictorGroup:AddDropdown('MarkerColorMode',
    { Values = { 'Custom', 'RGB' }, Default = 'Custom', Multi = false, Text = 'Marker Color Mode' })
PredictorGroup:AddLabel('Marker Custom Color'):AddColorPicker('PredictorColor',
    { Default = Color3.fromRGB(255,0,0), Title = 'Prediction Marker Custom' })
PredictorGroup:AddLabel('Pathway Color'):AddColorPicker('PathwayColor',
    { Default = Color3.fromRGB(255,0,0), Title = 'Pathway Line Color' })
PredictorGroup:AddSlider('PredictorStayTime',
    { Text = 'Stay Time (s)', Default = 0, Min = 0, Max = 10, Rounding = 0, Compact = false })

local NukeMiscGroup = Tabs.Nuke:AddLeftGroupbox('Nuke Misc')
NukeMiscGroup:AddToggle('NotifyNukeLaunch',    { Text = 'Notify Nuke Launch', Default = false })
NukeMiscGroup:AddToggle('NotifyNukeTeamCheck', { Text = 'Team Check', Default = true })
NukeMiscGroup:AddLabel('Launch Alert Sound')
NukeMiscGroup:AddDropdown('AlertSound', {
    Values = { 'None', 'UTHINKIMDUMB', 'LLTNT', 'NEW YEAR NEW ME', 'BHAJLSC', 'DOAFTCS',
               'HOW U MAKE OAT MEAL', 'FACTORIO', 'FACTORIO OLD', 'LELOUCH', 'NEOH' },
    Default = 'UTHINKIMDUMB', Multi = false, Text = 'Alert Sound'
})
NukeMiscGroup:AddButton('Test Sound', function()
    playSound(Options.AlertSound.Value, Options.AlertVolume.Value)
end)
NukeMiscGroup:AddSlider('AlertVolume',
    { Text = 'Volume', Default = 1, Min = 0, Max = 1.5, Rounding = 2, Compact = false })

-- Silo ESP
local SiloESPGroup = Tabs.Nuke:AddRightGroupbox('Silo ESP')
SiloESPGroup:AddToggle('SiloESPEnabled',     { Text = 'Enable Silo ESP', Default = false })
SiloESPGroup:AddToggle('SiloESPTeamCheck',   { Text = 'Team Check', Default = true })
SiloESPGroup:AddToggle('SiloESPIgnoreLocal', { Text = 'Ignore Local', Default = true })
SiloESPGroup:AddLabel('Silo Colors'); SiloESPGroup:AddDivider()
SiloESPGroup:AddDropdown('SiloColorMode', {
    Values = { 'Team Color', 'Custom', 'RGB', 'Green, Yellow, Red - No Nuke, Producing, Nuke' },
    Default = 'Team Color', Multi = false, Text = 'Silo Color Mode'
})
SiloESPGroup:AddLabel('Silo Outline'):AddColorPicker('SiloOutlineColor',
    { Default = Color3.fromRGB(255,100,100), Title = 'Silo Outline' })
SiloESPGroup:AddLabel('Silo Inner'):AddColorPicker('SiloInnerColor',
    { Default = Color3.fromRGB(255,0,0), Title = 'Silo Inner' })
SiloESPGroup:AddSlider('SiloOutlineThickness',
    { Text = 'Silo Outline Thickness', Default = 1, Min = 0, Max = 1, Rounding = 2, Compact = false })

-- Nuke ESP
local NukeESPGroup = Tabs.Nuke:AddRightGroupbox('Nuke ESP')
NukeESPGroup:AddToggle('NukeESPEnabled',     { Text = 'Enable Nuke ESP', Default = false })
NukeESPGroup:AddToggle('NukeESPTeamCheck',   { Text = 'Team Check', Default = true })
NukeESPGroup:AddToggle('NukeESPIgnoreLocal', { Text = 'Ignore Local', Default = true })

NukeESPGroup:AddLabel('Idle Missile Colors'); NukeESPGroup:AddDivider()
NukeESPGroup:AddDropdown('IdleColorMode',
    { Values = { 'Team Color', 'Custom', 'RGB' }, Default = 'Team Color', Multi = false, Text = 'Idle Color Mode' })
NukeESPGroup:AddLabel('Idle Outline'):AddColorPicker('IdleOutlineColor',
    { Default = Color3.fromRGB(255,100,100), Title = 'Idle Outline' })
NukeESPGroup:AddLabel('Idle Inner'):AddColorPicker('IdleInnerColor',
    { Default = Color3.fromRGB(255,0,0), Title = 'Idle Inner' })
NukeESPGroup:AddSlider('IdleOutlineThickness',
    { Text = 'Idle Outline Thickness', Default = 1, Min = 0, Max = 1, Rounding = 2, Compact = false })

NukeESPGroup:AddLabel('Moving Missile Colors'); NukeESPGroup:AddDivider()
NukeESPGroup:AddDropdown('MovingColorMode',
    { Values = { 'Team Color', 'Custom', 'RGB' }, Default = 'Team Color', Multi = false, Text = 'Moving Color Mode' })
NukeESPGroup:AddLabel('Moving Outline'):AddColorPicker('MovingOutlineColor',
    { Default = Color3.fromRGB(100,100,255), Title = 'Moving Outline' })
NukeESPGroup:AddLabel('Moving Inner'):AddColorPicker('MovingInnerColor',
    { Default = Color3.fromRGB(0,0,255), Title = 'Moving Inner' })
NukeESPGroup:AddSlider('MovingOutlineThickness',
    { Text = 'Moving Outline Thickness', Default = 1, Min = 0, Max = 1, Rounding = 2, Compact = false })

-- ============================================================
-- NUKE INFO TAB (was Nuclear)
-- ============================================================
local NI_Alliance1 = Tabs.NukeInfo:AddLeftGroupbox("Alliance 1")
local NI_Alliance2 = Tabs.NukeInfo:AddLeftGroupbox("Alliance 2")
local NI_Alliance3 = Tabs.NukeInfo:AddRightGroupbox("Alliance 3")
local NI_Groups    = { NI_Alliance1, NI_Alliance2, NI_Alliance3 }
local NI_Labels    = {}
for i, g in ipairs(NI_Groups) do NI_Labels[i] = g:AddLabel("Loading nuclear data...", true) end

local function ResizeBox(label, groupbox)
    task.defer(function()
        local text = label.Text or ""
        local _, nl = text:gsub("\n", "")
        local h = 20 + ((nl + 1) * 14)
        local container = groupbox.Container or (groupbox.Frame and groupbox.Frame.Container)
        if container then container.Size = UDim2.new(1, 0, 0, h) end
    end)
end

-- ============================================================
-- PLAYER INFO TAB
-- ============================================================
local PI_Alliance1 = Tabs.PlayerInfo:AddLeftGroupbox("Alliance 1")
local PI_Alliance2 = Tabs.PlayerInfo:AddLeftGroupbox("Alliance 2")
local PI_Alliance3 = Tabs.PlayerInfo:AddRightGroupbox("Alliance 3")
local PI_Groups    = { PI_Alliance1, PI_Alliance2, PI_Alliance3 }
local PI_Labels    = {}
for i, g in ipairs(PI_Groups) do PI_Labels[i] = g:AddLabel("Loading player data...", true) end

-- ============================================================
-- NOTIFICATIONS TAB
-- ============================================================
local NotifyGroup = Tabs.Notifications:AddLeftGroupbox('Building Notifications')
NotifyGroup:AddToggle('NotifyBuildings', { Text = 'Notify Building Placements', Default = false })
NotifyGroup:AddToggle('NotifyTeamCheck', { Text = 'Only Enemy Teams', Default = true })
NotifyGroup:AddDivider()
NotifyGroup:AddToggle('Notify_Airport',      { Text = 'Airport', Default = true })
NotifyGroup:AddToggle('Notify_Barracks',     { Text = 'Barracks', Default = true })
NotifyGroup:AddToggle('Notify_Fort',         { Text = 'Fort', Default = true })
NotifyGroup:AddToggle('Notify_Shipyard',     { Text = 'Naval Shipyard', Default = true })
NotifyGroup:AddToggle('Notify_Nuke',         { Text = 'Nuclear Silo', Default = true })
NotifyGroup:AddToggle('Notify_ShieldGen',    { Text = 'Shield Generator', Default = true })
NotifyGroup:AddToggle('Notify_SpaceLink',    { Text = 'Space Link', Default = true })
NotifyGroup:AddToggle('Notify_TankFactory',  { Text = 'Tank Factory', Default = true })

-- ============================================================
-- GARRISON TAB
-- ============================================================
local GarrisonBox = Tabs.Garrison:AddLeftGroupbox('Garrison View')

GarrisonBox:AddToggle('GarrisonViewEnabled', {
    Text = 'Garrison View', Default = true,
    Tooltip = 'Enable or disable the entire garrison UI'
})
GARRISON_VIEW_ENABLED = true
GarrisonBox:AddToggle('GarrisonTeamColors', {
    Text = 'Team Colored Text', Default = false, Tooltip = 'Color unit names based on team'
})
GARRISON_TEAM_COLORS = false
GarrisonBox:AddDropdown('IgnoreTargets', {
    Values = { 'Self', 'Own Team' }, Default = {}, Multi = true,
    Text = 'Ignore Target', Tooltip = 'Choose which targets to ignore'
})
IGNORE_SELF = false; IGNORE_TEAM = false
GarrisonBox:AddDropdown('GarrisonMode', {
    Values = { 'Simple', 'Detailed' }, Default = 'Detailed', Multi = false,
    Text = 'Mode', Tooltip = 'Choose how much information to show'
})
GarrisonBox:AddToggle('DistanceCheckEnabled', { Text = 'Distance Check', Default = false })
DISTANCE_CHECK_ENABLED = false
GarrisonBox:AddSlider('MaxDistance',
    { Text = 'Max Distance', Default = 250, Min = 0, Max = 500, Rounding = 0, Compact = false })
MAX_DISTANCE = 250
GarrisonBox:AddToggle('DisableNearby', { Text = 'Disable When Nearby', Default = false })
DISABLE_NEARBY = false
GarrisonBox:AddSlider('NearbyDistance',
    { Text = 'Nearby Distance', Default = 25, Min = 0, Max = 100, Rounding = 0, Compact = false })
NEARBY_DISTANCE = 25
GarrisonBox:AddSlider('GarrisonHeight',
    { Text = 'Height Offset', Default = 0, Min = -30, Max = 30, Rounding = 1, Compact = false })
CURRENT_HEIGHT_OFFSET = 0
GarrisonBox:AddSlider('GarrisonScale',
    { Text = 'Scale', Default = 1.0, Min = 0.5, Max = 10.36, Rounding = 2, Compact = false })
CURRENT_SCALE = 1.0

GarrisonBox:AddToggle('ProductionViewEnabled',
    { Text = 'Show Production', Default = false, Tooltip = 'Display production queue' })
GarrisonBox:AddDropdown('ProductionMode',
    { Values = { 'Simple', 'Detailed' }, Default = 'Detailed', Multi = false, Text = 'Production Mode' })
GarrisonBox:AddDropdown('ProductionPosition',
    { Values = { 'Above Garrison', 'Below Garrison' }, Default = 'Below Garrison', Multi = false,
      Text = 'Production Position' })
	  
	  -- Right-side groupbox in Misc tab
local RangeGroup = Tabs.Garrison:AddRightGroupbox('Range Indicator')
RangeGroup:AddToggle('RangeIndicatorEnabled', {
    Text = 'Enable Range Indicator', Default = false
})
RangeGroup:AddDropdown('RangeIgnoreTargets', {
    Values = { 'Self', 'Own Team' },
    Default = { 'Self', 'Own Team' },   -- default: enemies only (matches old behavior)
    Multi = true,
    Text = 'Ignore Target',
    Tooltip = 'Hide rings on your own team and/or allies'
})

RangeGroup:AddDivider()
RangeGroup:AddToggle('RangeCat_Soldiers', { Text = 'Soldiers', Default = true })
RangeGroup:AddToggle('RangeCat_Tanks',    { Text = 'Tanks',    Default = true })
RangeGroup:AddToggle('RangeCat_Planes',   { Text = 'Planes',   Default = true })
RangeGroup:AddToggle('RangeCat_Space',    { Text = 'Space',    Default = true })
RangeGroup:AddToggle('RangeCat_Naval',    { Text = 'Naval',    Default = true })
RangeGroup:AddToggle('RangeCat_Defense',  { Text = 'Defense',  Default = true })


RangeGroup:AddDivider()

RangeGroup:AddToggle('RangeDistanceCheck', { Text = 'Distance Check', Default = false })
RangeGroup:AddSlider('RangeMaxDistance',
    { Text = 'Max Distance', Default = 250, Min = 0, Max = 500, Rounding = 0, Compact = false })
RangeGroup:AddToggle('RangeDisableNearby', { Text = 'Disable When Nearby', Default = false })
RangeGroup:AddSlider('RangeNearbyDistance',
    { Text = 'Nearby Distance', Default = 25, Min = 0, Max = 100, Rounding = 0, Compact = false })

RangeGroup:AddDivider()

RangeGroup:AddDropdown('RangeColorMode', {
    Values = { 'Default', 'Team Colors', 'Custom', 'RGB' },
    Default = 'Default',
    Multi = false,
    Text = 'Color Mode'
})

local RangeOuterLabel = RangeGroup:AddLabel('Outer Ring Color')
RangeOuterLabel:AddColorPicker('RangeOuterColor', {
    Default = Color3.fromRGB(255, 60, 60),
    Title = 'Outer Ring Color'
})

local RangeInnerLabel = RangeGroup:AddLabel('Inner Ring Color')
RangeInnerLabel:AddColorPicker('RangeInnerColor', {
    Default = Color3.fromRGB(255, 60, 60),
    Title = 'Inner Ring Color'
})

-- Pickers stay visible at all times. The mode dropdown only affects how the
-- colours are applied, not whether the rows are displayed. This used to try
-- to hide/show them based on mode, but Linoria's label wrapper doesn't
-- expose the row frame in a way we can reliably hide, and hiding it kept
-- taking the whole groupbox with it.
function RangeIndicator.setPickerVisible(_) end



RangeGroup:AddDivider()
local RangeStatusLabel = RangeGroup:AddLabel('Hover a friendly unit once to arm.')

-- ============================================================
-- RGB TAB (consolidated) - speed/smoothness shared by all RGB sources
-- ============================================================
local RGBGroup = Tabs.RGB:AddLeftGroupbox('RGB Customizer')
RGBGroup:AddSlider('RGBSpeed',
    { Text = 'RGB Speed', Default = 1, Min = 0.1, Max = 5, Rounding = 1, Compact = false })
RGBGroup:AddSlider('RGBSmoothness',
    { Text = 'RGB Smoothness', Default = 0.01, Min = 0.005, Max = 0.1, Rounding = 3, Compact = false })

-- ============================================================
-- UI SETTINGS TAB
-- ============================================================
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind',
    { Default = 'End', NoUI = false, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('CQ3UI/themes')
SaveManager:SetFolder('CQ3UI')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

-- ============================================================
-- HOOK TOGGLES -> Refresh dirty garrison displays
-- ============================================================
local ActiveDisplays = {}
local DirtyBuildings = {}
function MarkBuildingDirty(b) if ActiveDisplays[b] then DirtyBuildings[b] = true end end

local function markAllDirty()
    for b in pairs(ActiveDisplays) do DirtyBuildings[b] = true end
    if UpdateAllDisplays then UpdateAllDisplays() end
end

Toggles.GarrisonViewEnabled:OnChanged(function(v) GARRISON_VIEW_ENABLED = v; markAllDirty() end)
Toggles.GarrisonTeamColors:OnChanged(function(v) GARRISON_TEAM_COLORS = v; markAllDirty() end)

Toggles.RangeIndicatorEnabled:OnChanged(function(v)
    RangeIndicator.enabled = v
    if v then
        if not RangeIndicator.storedTemplate then
            Notifier.send("Range Indicator",
                "Hover any friendly unit once to capture the ring template.",
                nil, 6)
        else
            RangeIndicator.rescan()
        end
    else
        RangeIndicator.clearAll()
    end
end)

Options.RangeIgnoreTargets:OnChanged(function(sel)
    RangeIndicator.ignoreSelf = sel['Self'] == true
    RangeIndicator.ignoreTeam = sel['Own Team'] == true
    if RangeIndicator.enabled then RangeIndicator.rescan() end
end)


local function hookRangeCategory(toggleId, catKey)
    Toggles[toggleId]:OnChanged(function(v)
        RangeIndicator.categories[catKey] = v
        if RangeIndicator.enabled then RangeIndicator.rescan() end
    end)
end

hookRangeCategory('RangeCat_Soldiers', 'Soldiers')
hookRangeCategory('RangeCat_Tanks',    'Tanks')
hookRangeCategory('RangeCat_Planes',   'Planes')
hookRangeCategory('RangeCat_Space',    'Space')
hookRangeCategory('RangeCat_Naval',    'Naval')
hookRangeCategory('RangeCat_Defense',  'Defense')


Toggles.RangeDistanceCheck:OnChanged(function(v) RangeIndicator.distanceCheck = v end)
Options.RangeMaxDistance:OnChanged(function(v) RangeIndicator.maxDistance = v end)
Toggles.RangeDisableNearby:OnChanged(function(v) RangeIndicator.disableNearby = v end)
Options.RangeNearbyDistance:OnChanged(function(v) RangeIndicator.nearbyDistance = v end)


Options.RangeColorMode:OnChanged(function(v)
    RangeIndicator.setPickerVisible(v == 'Custom')
    if RangeIndicator.enabled then RangeIndicator.rescan() end
end)

Options.RangeOuterColor:OnChanged(function()
    if RangeIndicator.enabled and Options.RangeColorMode.Value == 'Custom' then
        RangeIndicator.rescan()
    end
end)

Options.RangeInnerColor:OnChanged(function()
    if RangeIndicator.enabled and Options.RangeColorMode.Value == 'Custom' then
        RangeIndicator.rescan()
    end
end)


Options.IgnoreTargets:OnChanged(function(sel)
    IGNORE_SELF = sel['Self'] == true
    IGNORE_TEAM = sel['Own Team'] == true
    markAllDirty()
end)
Options.GarrisonMode:OnChanged(function(v) GARRISON_MODE = v; markAllDirty() end)
local function refreshDisplays()
    if UpdateAllDisplays then UpdateAllDisplays() end
end


Toggles.DistanceCheckEnabled:OnChanged(function(v) DISTANCE_CHECK_ENABLED = v; refreshDisplays() end)
Options.MaxDistance:OnChanged(function(v) MAX_DISTANCE = v; refreshDisplays() end)
Toggles.DisableNearby:OnChanged(function(v) DISABLE_NEARBY = v; refreshDisplays() end)
Options.NearbyDistance:OnChanged(function(v) NEARBY_DISTANCE = v; refreshDisplays() end)
Options.GarrisonHeight:OnChanged(function(v) CURRENT_HEIGHT_OFFSET = v; refreshDisplays() end)
Options.GarrisonScale:OnChanged(function(v)
    CURRENT_SCALE = v
    for _, display in pairs(ActiveDisplays) do
        if display.uiScale then display.uiScale.Scale = v end
        if display.part then
            display.part.Size = Vector3.new(
                (1000 / 400) * v, ((display.requiredHeight or 100) / 400) * v, 1)
        end
        if display.gui then
            display.gui.CanvasSize = Vector2.new(1000 * v, (display.requiredHeight or 100) * v)
        end
    end
end)
Options.ProductionMode:OnChanged(function() markAllDirty() end)
Options.ProductionPosition:OnChanged(function(val)
    for b, d in pairs(ActiveDisplays) do
        if d.garrisonFrame and d.productionFrame then
            if val == 'Above Garrison' then
                d.productionFrame.LayoutOrder = 1; d.garrisonFrame.LayoutOrder = 2
            else
                d.garrisonFrame.LayoutOrder = 1; d.productionFrame.LayoutOrder = 2
            end
        end
        markAllDirty()
    end
end)
Toggles.ProductionViewEnabled:OnChanged(function(val)
    if val then
        markAllDirty()
    else
        for _, d in pairs(ActiveDisplays) do
            if d.productionFrame then d.productionFrame:ClearAllChildren() end
            if d.productionConnections then
                for _, c in ipairs(d.productionConnections) do c:Disconnect() end
                d.productionConnections = {}
            end
            d.activeProduction = nil
            if d.separator then d.separator.Visible = false end
            task.defer(function() if d.part then UpdateDisplaySize(d) end end)
        end
    end
end)

-- ============================================================
-- GARRISON SYSTEM
-- ============================================================
-- State lives in globals (assigned by the OnChanged handlers above).
-- Do NOT re-declare these with `local` — that would shadow the globals
-- for every function defined below and break the UI wiring.
GARRISON_MODE         = GARRISON_MODE         or "Detailed"
GARRISON_VIEW_ENABLED = GARRISON_VIEW_ENABLED or true
GARRISON_TEAM_COLORS  = GARRISON_TEAM_COLORS  or false
IGNORE_SELF           = IGNORE_SELF           or false
IGNORE_TEAM           = IGNORE_TEAM           or false
DISTANCE_CHECK_ENABLED= DISTANCE_CHECK_ENABLED or false
MAX_DISTANCE          = MAX_DISTANCE           or 250
DISABLE_NEARBY        = DISABLE_NEARBY         or false
NEARBY_DISTANCE       = NEARBY_DISTANCE        or 25
CURRENT_HEIGHT_OFFSET = CURRENT_HEIGHT_OFFSET  or 0

local BASE_HP_BAR_WIDTH   = 480
local BASE_HP_BAR_HEIGHT  = 32
local BASE_ROW_HEIGHT     = 80
local BASE_PADDING        = 8
local BASE_TEXT_SIZE      = 75
local BASE_CONTAINER_WIDTH= 800
local PROGRESS_BAR_WIDTH  = 400
local PROGRESS_BAR_HEIGHT = 24

local PIXELS_PER_STUD = 400
local CANVAS_WIDTH    = 1000
local CANVAS_HEIGHT   = 2000
local PART_SIZE       = Vector3.new(CANVAS_WIDTH / PIXELS_PER_STUD,
                                    CANVAS_HEIGHT / PIXELS_PER_STUD, 1)

local Garrisonable = {
    ["Bunker"] = true, ["Headquarters"] = true, ["Command Center"] = true,
    ["Fort"] = true, ["Medi-Truck"] = true, ["Aircraft Carrier"] = true,
    ["Transport Ship"] = true, ["Transport Plane"] = true,
    ["Mothership"] = true, ["Helicopter"] = true
}

local function CalculateRequiredHeight(gc, pc)
    local mode = GARRISON_MODE or "Detailed"
    local prodMode = Options.ProductionMode and Options.ProductionMode.Value or "Detailed"
    local gH = (mode == "Simple") and (BASE_ROW_HEIGHT * 0.6) or BASE_ROW_HEIGHT
    local pH = BASE_ROW_HEIGHT * 0.7
    local h = 0
    if gc > 0 then h = h + gc * gH + (gc - 1) * BASE_PADDING end
    if pc > 0 then
        h = h + pc * pH + (pc - 1) * BASE_PADDING + PROGRESS_BAR_HEIGHT + 8
    end
    h = h + 20
    return math.max(h, 100)
end

local HealthConnections = {}

local function MakeHealthBar(parent, current, max)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, BASE_HP_BAR_WIDTH, 0, BASE_HP_BAR_HEIGHT)
    bar.BackgroundColor3 = Color3.fromRGB(40,40,40)
    bar.BorderColor3 = Color3.new(0,0,0)
    bar.BorderSizePixel = 2
    bar.Parent = parent
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(max > 0 and current/max or 0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0,255,0)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    return bar, fill
end

local function HookBuildingMovement(display)
    local torso = display.torso
    if not torso then return end
    if display.movementConnection then
        display.movementConnection:Disconnect(); display.movementConnection = nil
    end
    display.movementConnection = torso:GetPropertyChangedSignal("CFrame"):Connect(function()
        -- just mark for repositioning on next tick
        display._needsReposition = true
    end)
end

local function CreateDisplay(building, teamFolder)
    local torso = building:FindFirstChild("Torso")
    if not torso then return end

    local part = Instance.new("Part")
    part.Size = PART_SIZE * CURRENT_SCALE
    part.Transparency = 1
    part.CanCollide = false
    part.CanQuery = false
    part.Anchored = true
    part.Parent = workspace

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
    gui.CanvasSize = Vector2.new(CANVAS_WIDTH * CURRENT_SCALE, 100 * CURRENT_SCALE)
    gui.Parent = part

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = CURRENT_SCALE
    uiScale.Parent = gui

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

    local garrisonFrame = Instance.new("Frame")
    garrisonFrame.Name = "GarrisonFrame"
    garrisonFrame.Size = UDim2.new(1, 0, 0, 0)
    garrisonFrame.AutomaticSize = Enum.AutomaticSize.Y
    garrisonFrame.BackgroundTransparency = 1
    garrisonFrame.LayoutOrder = 1
    garrisonFrame.Parent = mainContainer

    local gl = Instance.new("UIListLayout")
    gl.FillDirection = Enum.FillDirection.Vertical
    gl.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gl.VerticalAlignment = Enum.VerticalAlignment.Top
    gl.Padding = UDim.new(0, BASE_PADDING)
    gl.Parent = garrisonFrame

    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Size = UDim2.new(1, 0, 0, 2)
    separator.BackgroundColor3 = Color3.new(1,1,1)
    separator.BackgroundTransparency = 0.2
    separator.BorderSizePixel = 0
    separator.LayoutOrder = 1.5
    separator.Visible = false
    separator.Parent = mainContainer

    local productionFrame = Instance.new("Frame")
    productionFrame.Name = "ProductionFrame"
    productionFrame.Size = UDim2.new(1, 0, 0, 0)
    productionFrame.AutomaticSize = Enum.AutomaticSize.Y
    productionFrame.BackgroundTransparency = 1
    productionFrame.LayoutOrder = 2
    productionFrame.Parent = mainContainer

    local pl = Instance.new("UIListLayout")
    pl.FillDirection = Enum.FillDirection.Vertical
    pl.HorizontalAlignment = Enum.HorizontalAlignment.Center
    pl.VerticalAlignment = Enum.VerticalAlignment.Top
    pl.Padding = UDim.new(0, BASE_PADDING)
    pl.Parent = productionFrame

    ActiveDisplays[building] = {
        part = part, gui = gui, mainContainer = mainContainer,
        garrisonFrame = garrisonFrame, productionFrame = productionFrame,
        uiScale = uiScale, torso = torso,
        folder = torso:FindFirstChild("Garrisoned"),
        productionFolder = torso:FindFirstChild("Producing"),
        teamFolder = teamFolder,
        owner = building:FindFirstChild("Owner"),
        productionConnections = {}, hookConnections = {},
        queueOrder = {}, requiredHeight = 100,
        separator = separator,
    }
    HookBuildingMovement(ActiveDisplays[building])
    MarkBuildingDirty(building)

    building.AncestryChanged:Connect(function(_, parent)
        if not parent then
            local d = ActiveDisplays[building]
            if d then
                for _, c in ipairs(d.productionConnections or {}) do c:Disconnect() end
                for _, c in ipairs(d.hookConnections or {}) do c:Disconnect() end
                if HealthConnections[building] then
                    for _, c in ipairs(HealthConnections[building]) do c:Disconnect() end
                    HealthConnections[building] = nil
                end
                if d.movementConnection then d.movementConnection:Disconnect() end
                if d.part then d.part:Destroy() end
                ActiveDisplays[building] = nil
            end
        end
    end)
end

function UpdateGarrisonDisplay(building, units)
    local display = ActiveDisplays[building]
    if not display then return end
    HealthConnections[building] = HealthConnections[building] or {}
    for _, c in ipairs(HealthConnections[building]) do c:Disconnect() end
    HealthConnections[building] = {}
    local frame = display.garrisonFrame
    frame:ClearAllChildren()

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, BASE_PADDING)
    layout.Parent = frame

    if GARRISON_MODE == "Simple" then
        local grouped = {}
        for _, unit in ipairs(units) do
            local n = unit.Name
            if n == "Construction Soldier" then n = "⚠ Construction Soldier ⚠" end
            grouped[n] = (grouped[n] or 0) + 1
        end
        local sorted = {}
        for n, c in pairs(grouped) do table.insert(sorted, { name = n, count = c }) end
        table.sort(sorted, function(a, b) return a.name:lower() < b.name:lower() end)
        for _, entry in ipairs(sorted) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, BASE_ROW_HEIGHT * 0.6)
            row.BackgroundTransparency = 1
            row.Parent = frame
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = GARRISON_TEAM_COLORS and TeamData.getColor(display.teamFolder) or Color3.new(1,1,1)
            lbl.TextStrokeColor3 = Color3.new(0,0,0)
            lbl.TextStrokeTransparency = 0
            lbl.Font = Enum.Font.SourceSansBold
            lbl.TextSize = BASE_TEXT_SIZE
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.Text = (entry.count > 1) and string.format("• %s (x%d)", entry.name, entry.count)
                                              or "• " .. entry.name
            lbl.Parent = row
        end
        return
    end

    table.sort(units, function(a, b)
        local na, nb = a.Name, b.Name
        if na == "Construction Soldier" then na = "⚠ Construction Soldier ⚠" end
        if nb == "Construction Soldier" then nb = "⚠ Construction Soldier ⚠" end
        return na:lower() < nb:lower()
    end)

    for _, unit in ipairs(units) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, BASE_ROW_HEIGHT)
        row.BackgroundTransparency = 1
        row.Parent = frame

        local hLayout = Instance.new("UIListLayout")
        hLayout.FillDirection = Enum.FillDirection.Horizontal
        hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        hLayout.Padding = UDim.new(0, BASE_PADDING)
        hLayout.Parent = row

        local hp = unit:FindFirstChild("Health")
        local mhp = unit:FindFirstChild("MaxHealth")
        if hp and mhp and hp:IsA("NumberValue") and mhp:IsA("NumberValue") then
            local _, fill = MakeHealthBar(row, hp.Value, mhp.Value)
            local conn = hp:GetPropertyChangedSignal("Value"):Connect(function()
                fill.Size = UDim2.new(mhp.Value > 0 and math.clamp(hp.Value / mhp.Value, 0, 1) or 0, 0, 1, 0)
            end)
            table.insert(HealthConnections[building], conn)
        end

        local n = unit.Name
        if n == "Construction Soldier" then n = "⚠ Construction Soldier ⚠" end
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 450, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = GARRISON_TEAM_COLORS and TeamData.getColor(display.teamFolder) or Color3.new(1,1,1)
        lbl.TextStrokeColor3 = Color3.new(0,0,0)
        lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.SourceSansBold
        lbl.TextSize = BASE_TEXT_SIZE
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = "• " .. n
        lbl.Parent = row
    end
end

local function BuildProductionRows(display)
    local frame = display.productionFrame
    frame:ClearAllChildren()
    for _, c in ipairs(display.productionConnections) do c:Disconnect() end
    display.productionConnections = {}
    display.activeProduction = nil

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, BASE_PADDING)
    layout.Parent = frame

    local queue = display.queueOrder
    if #queue == 0 then return end
    local mode = Options.ProductionMode and Options.ProductionMode.Value or 'Detailed'

    local activeItem = nil
    for _, item in ipairs(queue) do
        local p = item:FindFirstChild("Progress")
        if p and p:IsA("NumberValue") and p.Value > 0 and p.Value < 1 then
            activeItem = item; break
        end
    end
    if not activeItem and #queue > 0 then activeItem = queue[1] end

    if mode == 'Simple' then
        local order, seen = {}, {}
        for _, item in ipairs(queue) do
            if not seen[item.Name] then table.insert(order, item.Name); seen[item.Name] = true end
        end
        for i = #order, 1, -1 do
            local name = order[i]
            local count = 0
            for _, q in ipairs(queue) do if q.Name == name then count = count + 1 end end
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, BASE_ROW_HEIGHT * 0.7)
            row.BackgroundTransparency = 1
            row.Parent = frame
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = GARRISON_TEAM_COLORS and TeamData.getColor(display.teamFolder) or Color3.new(1,1,1)
            lbl.TextStrokeColor3 = Color3.new(0,0,0)
            lbl.TextStrokeTransparency = 0
            lbl.Font = Enum.Font.SourceSansBold
            lbl.TextSize = BASE_TEXT_SIZE
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.Text = (count > 1) and string.format("(x%d) %s", count, name) or name
            lbl.Parent = row
        end
    else
        for i = #queue, 1, -1 do
            local item = queue[i]
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, BASE_ROW_HEIGHT * 0.7)
            row.BackgroundTransparency = 1
            row.Parent = frame
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = GARRISON_TEAM_COLORS and TeamData.getColor(display.teamFolder) or Color3.new(1,1,1)
            lbl.TextStrokeColor3 = Color3.new(0,0,0)
            lbl.TextStrokeTransparency = 0
            lbl.Font = Enum.Font.SourceSansBold
            lbl.TextSize = BASE_TEXT_SIZE
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.Text = item.Name
            lbl.Parent = row
        end
    end

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
        local rem = Instance.new("Frame")
        rem.Size = UDim2.new(1 - math.clamp(pct,0,1), 0, 1, 0)
        rem.Position = UDim2.new(math.clamp(pct,0,1), 0, 0, 0)
        rem.BackgroundColor3 = Color3.fromRGB(255,0,0)
        rem.BorderSizePixel = 0
        rem.Parent = bar
        display.activeProduction = { item = activeItem, fill = fill, remaining = rem, bar = bar }
        if prog and prog:IsA("NumberValue") then
            local conn = prog:GetPropertyChangedSignal("Value"):Connect(function()
                if display.activeProduction and display.activeProduction.item == activeItem then
                    local p = prog.Value
                    display.activeProduction.fill.Size = UDim2.new(math.clamp(p,0,1), 0, 1, 0)
                    display.activeProduction.remaining.Size = UDim2.new(1 - math.clamp(p,0,1), 0, 1, 0)
                    display.activeProduction.remaining.Position = UDim2.new(math.clamp(p,0,1), 0, 0, 0)
                end
            end)
            table.insert(display.productionConnections, conn)
        end
    end
end

function UpdateDisplaySize(display)
    local g = display.folder and display.folder:GetChildren() or {}
    local p = display.productionFolder and display.productionFolder:GetChildren() or {}
    local h = CalculateRequiredHeight(#g, #p)
    display.requiredHeight = h
    display.gui.CanvasSize = Vector2.new(CANVAS_WIDTH * CURRENT_SCALE, h * CURRENT_SCALE)
    display.part.Size = Vector3.new(
        (CANVAS_WIDTH / PIXELS_PER_STUD) * CURRENT_SCALE,
        (h / PIXELS_PER_STUD) * CURRENT_SCALE, 1)
    if display.separator then
        display.separator.Visible = #g > 0 and Toggles.ProductionViewEnabled.Value and #p > 0
    end
end

local function UpdateOneDisplay(display, camPos, myTeam, myAllies)
    local torso = display.torso
    if not torso or not torso.Parent then display.gui.Enabled = false; return end
    local pos = torso.Position
    local dist = (camPos - pos).Magnitude

    if DISTANCE_CHECK_ENABLED and dist > MAX_DISTANCE then display.gui.Enabled = false; return end
    if DISABLE_NEARBY and dist < NEARBY_DISTANCE then display.gui.Enabled = false; return end

    if IGNORE_SELF or IGNORE_TEAM then
        local bTeam = display.teamFolder and display.teamFolder.Name
        local isOwner = (bTeam == myTeam)
        local sameTeam = isOwner
        if not sameTeam and bTeam then
            for _, ally in ipairs(myAllies) do
                if ally == bTeam then sameTeam = true; break end
            end
        end
        if IGNORE_SELF and isOwner then display.gui.Enabled = false; return end
        if IGNORE_TEAM and sameTeam and not isOwner then display.gui.Enabled = false; return end
    end

    display.gui.Enabled = true
    local partHeight = display.part.Size.Y
    display.part.CFrame = CFrame.new(
        pos + Vector3.new(0, 4 + CURRENT_HEIGHT_OFFSET - partHeight/2, 0),
        camPos)
end

local lastReposition = 0



function Hook(building, folder, teamFolder)
    local d = ActiveDisplays[building]
    if not d then return end
    d.hookConnections = d.hookConnections or {}
    local function Refresh() MarkBuildingDirty(building) end
    Refresh()
    table.insert(d.hookConnections, folder.ChildAdded:Connect(function() task.defer(Refresh) end))
    table.insert(d.hookConnections, folder.ChildRemoved:Connect(function() task.defer(Refresh) end))
end

function HookProduction(building, prodFolder, teamFolder)
    local d = ActiveDisplays[building]
    if not d then return end
    d.hookConnections = d.hookConnections or {}
    d.queueOrder = {}
    for _, c in ipairs(prodFolder:GetChildren()) do table.insert(d.queueOrder, c) end
    table.sort(d.queueOrder, function(a,b) return a.Name < b.Name end)
    local function Refresh() MarkBuildingDirty(building) end
    table.insert(d.hookConnections, prodFolder.ChildAdded:Connect(function(c)
        table.insert(d.queueOrder, c); task.defer(Refresh)
    end))
    table.insert(d.hookConnections, prodFolder.ChildRemoved:Connect(function(c)
        for i, item in ipairs(d.queueOrder) do
            if item == c then table.remove(d.queueOrder, i); break end
        end
        task.defer(Refresh)
    end))
    Refresh()
end




function UpdateAllDisplays()
    if not GARRISON_VIEW_ENABLED then
        for _, d in pairs(ActiveDisplays) do d.gui.Enabled = false end
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local camPos = cam.CFrame.Position
    local myTeam = TeamData.getMyTeamColor()
    local myAllies = TeamData.getMyAlliedColors()

    -- Scan ALL teams (not just own) so new buildings anywhere get displays
    for _, teamFolder in ipairs(TeamsFolder:GetChildren()) do
        for _, b in ipairs(teamFolder:GetChildren()) do
            if b:IsA("Model") and not ActiveDisplays[b] then
                local torso = b:FindFirstChild("Torso")
                if torso then
                    local g = torso:FindFirstChild("Garrisoned")
                    local p = torso:FindFirstChild("Producing")
                    if g or p then
                        CreateDisplay(b, teamFolder)
                        if g then Hook(b, g, teamFolder) end
                        if p then HookProduction(b, p, teamFolder) end
                    end
                end
            end
        end
    end

    local dead = {}
    for b, d in pairs(ActiveDisplays) do
        if not b or not b.Parent then
            dead[b] = true
        else
            local torso = d.torso
            if not (torso and torso.Parent and torso:IsDescendantOf(b)) then
                local nt = b:FindFirstChild("Torso")
                if nt and nt:IsA("BasePart") then
                    d.torso = nt; torso = nt; HookBuildingMovement(d)
                end
            end
            local folderValid = d.folder and d.folder.Parent and torso and d.folder:IsDescendantOf(torso)
            if not folderValid and torso then
                local ng = torso:FindFirstChild("Garrisoned")
                if ng then
                    for _, c in ipairs(d.hookConnections or {}) do c:Disconnect() end
                    d.hookConnections = {}
                    d.folder = ng
                    Hook(b, ng, d.teamFolder)
                    MarkBuildingDirty(b)
                end
            end
            local prodValid = d.productionFolder and d.productionFolder.Parent and torso
                and d.productionFolder:IsDescendantOf(torso)
            if not prodValid and torso then
                local np = torso:FindFirstChild("Producing")
                if np and np ~= d.productionFolder then
                    d.productionFolder = np
                    HookProduction(b, np, d.teamFolder)
                    MarkBuildingDirty(b)
                else
                    d.productionFolder = np
                end
            end
            if not dead[b] then
                UpdateOneDisplay(d, camPos, myTeam, myAllies)
            end
        end
    end
    for b in pairs(dead) do
        local d = ActiveDisplays[b]
        if d and d.part then d.part:Destroy() end
        ActiveDisplays[b] = nil
    end
end



-- Startup scan
for _, tf in ipairs(TeamsFolder:GetChildren()) do
    for _, b in ipairs(tf:GetChildren()) do
        if b:IsA("Model") then
            local t = b:FindFirstChild("Torso")
            if t then
                local g = t:FindFirstChild("Garrisoned")
                local p = t:FindFirstChild("Producing")
                if g or p then
                    CreateDisplay(b, tf)
                    if g then Hook(b, g, tf) end
                    if p then HookProduction(b, p, tf) end
                end
            end
        end
    end
end

-- ============================================================
-- NUKE PREDICTOR SYSTEM
-- ============================================================
local trackedMissiles = {}
local persistentMarkers = {}
local Predictor = { pendingMissiles = {} }

function Predictor.onMissileAdded(model)
    if not model:IsA("Model") then return end
    if model.Name ~= "Nuclear Missile" and model.Name ~= "Fire Missile" then return end
    Predictor.pendingMissiles[model] = true
end

local function getLaunchInfo(missile)
    local siloVal = missile:FindFirstChild("Silo")
    if siloVal and siloVal:IsA("ObjectValue") and siloVal.Value then
        local silo = siloVal.Value
        if silo:IsA("Model") then
            local torso = silo:FindFirstChild("Torso") or silo:FindFirstChildWhichIsA("BasePart")
            if torso then
                local root = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dir = (root.Position - torso.Position) * Vector3.new(1,0,1)
                    if dir.Magnitude > 0.1 then return torso.Position, dir.Unit end
                end
            end
        end
    end
    local obj = missile
    while obj do
        if obj:IsA("Model") and obj.Name == "Nuclear Silo" then
            local part = obj:FindFirstChild("Torso") or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local root = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
                if root then
                    local dir = (root.Position - part.Position) * Vector3.new(1,0,1)
                    if dir.Magnitude > 0.1 then return part.Position, dir.Unit end
                end
            end
            break
        end
        obj = obj.Parent
    end
    local root = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
    if root then
        local vel = root.AssemblyLinearVelocity
        local bv = root:FindFirstChild("BodyVelocity")
        if bv and bv:IsA("BodyVelocity") then vel = bv.Velocity end
        local hv = vel * Vector3.new(1,0,1)
        if hv.Magnitude > 1 then return root.Position, hv.Unit end
    end
    return nil, nil
end

local function getMarkerColor()
    if Options.MarkerColorMode.Value == 'RGB' then
        return getGlobalRGBColor()
    end
    return Options.PredictorColor and Options.PredictorColor.Value or Color3.new(1,0,0)
end

local function createPredictorMarker(position, color)
    local part = Instance.new("Part")
    part.Name = "NukePredictor"
    part.Size = Vector3.new(1, 30, 30)
    part.Shape = Enum.PartType.Cylinder
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new(color or getMarkerColor())
    part.Transparency = 0.8
    part.CastShadow = false
    local ray = workspace:Raycast(position + Vector3.new(0,50,0), Vector3.new(0,-100,0))
    local gy = ray and ray.Position.Y or 0
    part.CFrame = CFrame.new(position.X, gy + 0.5, position.Z) * CFrame.Angles(0, 0, math.rad(90))
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
    local col = Options.PathwayColor and Options.PathwayColor.Value or Color3.new(1,0,0)
    part.BrickColor = BrickColor.new(col)
    part.Transparency = 0.8
    part.CastShadow = false
    local baseY = groundY or startPos.Y
    local mid = startPos + direction * (length / 2)
    local flat = Vector3.new(mid.X, baseY + 0.1, mid.Z)
    local up = Vector3.new(0,1,0)
    local right = direction.Unit
    local forward = right:Cross(up).Unit
    part.CFrame = CFrame.fromMatrix(flat, right, up, forward)
    part.Parent = workspace
    return part
end

local function updatePredictor()
    if not Toggles.PredictorEnabled.Value then
        for _, d in pairs(trackedMissiles) do
            if d.marker then d.marker:Destroy() end
            if d.pathway then d.pathway:Destroy() end
        end
        for m in pairs(persistentMarkers) do if m.Parent then m:Destroy() end end
        trackedMissiles = {}
        persistentMarkers = {}
        return
    end

    if Options.MarkerColorMode.Value == 'RGB' then
        local rgb = getGlobalRGBColor()
        for _, d in pairs(trackedMissiles) do
            if d.marker and d.marker.Parent then d.marker.BrickColor = BrickColor.new(rgb) end
            if d.pathway and d.pathway.Parent then d.pathway.BrickColor = BrickColor.new(rgb) end
        end
        for m in pairs(persistentMarkers) do
            if m.Parent then m.BrickColor = BrickColor.new(rgb) else persistentMarkers[m] = nil end
        end
    end

    -- Gather from pending (retry each tick until launch info is available or missile dies)
    for missile in pairs(Predictor.pendingMissiles) do
        if not missile.Parent then
            Predictor.pendingMissiles[missile] = nil
        elseif trackedMissiles[missile] then
            Predictor.pendingMissiles[missile] = nil
        else
            local siloPos, dir = getLaunchInfo(missile)
            if siloPos and dir then
                local root = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
                if root then
                    local data = {
                        startPos = siloPos, direction = dir, maxY = root.Position.Y,
                        apexReached = false, marker = nil, pathway = nil,
                    }
                    trackedMissiles[missile] = data
                    Predictor.pendingMissiles[missile] = nil
                    if Toggles.PathwayEnabled.Value then
                        data.pathway = createPathway(siloPos, dir, siloPos.Y)
                    end
                end
            end
        end
    end

    -- Update active missiles
    for missile, data in pairs(trackedMissiles) do
        if not missile.Parent then
            local stay = Options.PredictorStayTime.Value
            if data.marker then
                if stay > 0 then
                    persistentMarkers[data.marker] = true
                    task.delay(stay, function()
                        if data.marker then data.marker:Destroy(); persistentMarkers[data.marker] = nil end
                    end)
                else
                    data.marker:Destroy()
                end
            end
            if data.pathway then data.pathway:Destroy() end
            trackedMissiles[missile] = nil
        else
            local root = missile:FindFirstChild("Torso") or missile:FindFirstChildWhichIsA("BasePart")
            if not root then
                trackedMissiles[missile] = nil
            else
                local y = root.Position.Y
                if not data.apexReached then
                    if y > data.maxY then data.maxY = y end
                    if data.maxY - y > 0.5 then
                        data.apexReached = true
                        local offset = Vector3.new(root.Position.X - data.startPos.X, 0, root.Position.Z - data.startPos.Z)
                        local land = data.startPos + offset * 1.8
                        data.marker = createPredictorMarker(land, getMarkerColor())
                        if Options.PathwayDisappear.Value == 'On Apex' and data.pathway then
                            data.pathway:Destroy(); data.pathway = nil
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================
-- NUKE MISC - sound cache + launch notification
-- ============================================================
local soundUrls = {
    ['UTHINKIMDUMB']       = 'https://u.pone.rs/gqtwqctf.mp3',
    ['LLTNT']              = 'https://u.pone.rs/zzjffmnr.mp3',
    ['NEW YEAR NEW ME']    = 'https://u.pone.rs/dfparvyq.mp3',
    ['BHAJLSC']            = 'https://u.pone.rs/ldimapzk.mp3',
    ['DOAFTCS']            = 'https://u.pone.rs/gfywjrhv.mp3',
    ['HOW U MAKE OAT MEAL']= 'https://u.pone.rs/lfbuhrmc.mp3',
    ['FACTORIO']           = 'https://u.pone.rs/xyypgrho.mp3',
    ['FACTORIO OLD']       = 'https://u.pone.rs/qjxduqcj.mp3',
    ['LELOUCH']            = 'https://u.pone.rs/wstbohkr.mp3',
    ['NEOH']               = 'https://u.pone.rs/cwhtmzkg.ogg',
}
local soundCache = {}

local function getSoundAsset(name)
    if soundCache[name] then return soundCache[name] end
    local url = soundUrls[name]
    if not url then return nil end
    local ok, data = pcall(function() return game:HttpGet(url) end)
    if not ok or not data then return nil end
    local file = "CQ3UI/audio/nuke_alert_" .. name:gsub(" ", "_") .. ".mp3"
    writefile(file, data)
    local asset = getcustomasset(file)
    soundCache[name] = asset
    return asset
end

function playSound(name, volume)
    if name == 'None' then return end
    local asset = getSoundAsset(name)
    if not asset then return end
    local s = Instance.new("Sound")
    s.SoundId = asset
    s.Volume = volume or 1
    s.Parent = workspace
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

for name in pairs(soundUrls) do
    spawn(function() getSoundAsset(name) end)
end

-- Nuke launch detection - event-driven, not per-frame scanning
local function playerHistoryForTeam(color)
    return TeamData.getPlayerHistory(color)
end

local function getPlayerName(teamColor)
    return TeamData.getOnlinePlayer(teamColor) or "NO PLAYER"
end

local function shortColorName(teamName)
    return string.upper(tostring(teamName):lower()
        :gsub("^bright ", ""):gsub("^really ", ""):gsub("^reddish ", "")
        :gsub("^deep ", ""):gsub("^pastel ", ""):gsub("^medium ", "")
        :gsub("^dark ", ""):gsub("^light ", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function onMissileLaunched(model)
    if not Toggles.NotifyNukeLaunch.Value then return end
    local teamFolder = model:FindFirstAncestorOfClass("Model")
    -- Walk up to the team folder
    local obj = model
    while obj and obj.Parent ~= TeamsFolder do obj = obj.Parent end
    local teamName = obj and obj.Name or "Unknown"

    if Toggles.NotifyNukeTeamCheck.Value and not TeamData.isEnemy(teamName) then return end

    local short = shortColorName(teamName)
    local playerName = getPlayerName(teamName)
    local text = string.format("%s (%s) HAS LAUNCHED %s", short, playerName, model.Name:upper())
    Notifier.send("☢️ Nuke Launch", text, nil, 5)
    playSound(Options.AlertSound.Value, Options.AlertVolume.Value)
end

-- ============================================================
-- SILO / NUKE ESP - both use HighlightManager
-- ============================================================
local function isMoving(model)
    local torso = model:FindFirstChild("Torso") or model:FindFirstChildWhichIsA("BasePart")
    if not torso then return false end
    local bv = torso:FindFirstChild("BodyVelocity")
    local vel = bv and bv.Velocity or torso.AssemblyLinearVelocity
    return vel.Magnitude > 5
end

local function isLocalOwner(model)
    local obj = model
    while obj and obj.Parent ~= TeamsFolder do obj = obj.Parent end
    local teamName = obj and obj.Name
    return teamName == TeamData.getMyTeamColor()
end

-- ============================================================
-- Silo state system — event-driven with safety poll.
--
-- IMPORTANT game quirk:
--   A finished missile spawns in the TEAM FOLDER OF THE PLAYER WHO
--   TRIGGERED PRODUCTION, not the team folder of the silo that built it.
--   So we cannot correlate by missile.Parent == silo.Parent. The only
--   reliable signal is a finish-marker: the moment a silo's Producing
--   folder empties, we timestamp it, and the next new missile is
--   attributed to whichever silo has the most recent marker.
-- ============================================================
local siloState    = setmetatable({}, {__mode = "k"})   -- [silo]    = "idle"|"producing"|"ready"
local missileOwner = setmetatable({}, {__mode = "k"})   -- [missile] = silo
local siloJustFinished = setmetatable({}, {__mode = "k"})   -- [silo] = tick()
local siloProducingSeen = setmetatable({}, {__mode = "k"})  -- [silo] = missile

local FINISH_WINDOW = 15   -- seconds to accept a new missile after a finish

-- Called on every hooked silo per poll. Detects the moment a missile
-- disappears from Producing, and stamps the silo.
local function detectFinishTransition(silo)
    if not silo or not silo.Parent then return end
    local torso = silo:FindFirstChild("Torso")
    if not torso then return end
    local producing = torso:FindFirstChild("Producing")
    local seen = siloProducingSeen[silo]

    local current = nil
    if producing then
        for _, child in ipairs(producing:GetChildren()) do
            if child.Name == "Nuclear Missile" or child.Name == "Fire Missile" then
                current = child
                break
            end
        end
    end

    if current then
        siloProducingSeen[silo] = current
    elseif seen then
        -- Was producing, now empty → production just finished
        siloJustFinished[silo] = tick()
        siloProducingSeen[silo] = nil
    end
end

-- Claim a finished missile for a silo. Cached; runs once per missile.
local function claimMissile(missile)
    local cached = missileOwner[missile]
    if cached and cached.Parent then return cached end

    -- 1. Silo ObjectValue (authoritative when the game sets it)
    local siloVal = missile:FindFirstChild("Silo")
    if siloVal and siloVal:IsA("ObjectValue") and siloVal.Value then
        local v = siloVal.Value
        if typeof(v) == "Instance" and v:IsA("Model") and v.Name == "Nuclear Silo" then
            missileOwner[missile] = v
            siloJustFinished[v] = nil
            return v
        end
    end

    -- 2. Global finish-marker: whichever silo most recently finished
    --    producing within the window. This is the ONLY cross-team-safe
    --    signal — see note above.
    local now = tick()
    local best, bestT = nil, 0
    for silo, t in pairs(siloJustFinished) do
        if silo.Parent and (now - t) < FINISH_WINDOW then
            if t > bestT then bestT = t; best = silo end
        end
    end
    if best then
        missileOwner[missile] = best
        siloJustFinished[best] = nil
        return best
    end

    -- 3. No marker → don't guess. A wrong red silo is worse than a green one.
    return nil
end

-- Idle-missile cache, refreshed once per poll pass (cheap, shared).
local idleMissiles = {}
local function refreshIdleMissiles()
    local list = {}
    for _, tf in ipairs(TeamsFolder:GetChildren()) do
        for _, m in ipairs(tf:GetChildren()) do
            if m:IsA("Model") and (m.Name == "Nuclear Missile" or m.Name == "Fire Missile") then
                local root = m:FindFirstChild("Torso") or m:FindFirstChildWhichIsA("BasePart")
                if root and root.AssemblyLinearVelocity.Magnitude <= 1 then
                    table.insert(list, m)
                end
            end
        end
    end
    idleMissiles = list
end

local function recomputeSiloState(silo)
    if not silo or not silo.Parent then siloState[silo] = nil; return end
    local torso = silo:FindFirstChild("Torso")
    if not torso then siloState[silo] = "idle"; return end

    -- 1. A missile is physically in our Producing folder
    local producing = torso:FindFirstChild("Producing")
    if producing then
        for _, child in ipairs(producing:GetChildren()) do
            if child.Name == "Nuclear Missile" or child.Name == "Fire Missile" then
                missileOwner[child] = silo
                local prog = child:FindFirstChild("Progress")
                if prog and prog:IsA("NumberValue") and prog.Value < 1 then
                    siloState[silo] = "producing"
                else
                    siloState[silo] = "ready"
                end
                return
            end
        end
    end

    -- 2. We own an idle missile sitting somewhere in the world
    for _, m in ipairs(idleMissiles) do
        if missileOwner[m] == silo then
            siloState[silo] = "ready"
            return
        end
    end

    siloState[silo] = "idle"
end

local function siloNukeState(model)
    return siloState[model] or "idle"
end

-- Hooks
local siloHooked = setmetatable({}, {__mode = "k"})

local function hookSilo(silo)
    if siloHooked[silo] then return end
    siloHooked[silo] = true
    recomputeSiloState(silo)

    silo.AncestryChanged:Connect(function(_, parent)
        if not parent then
            siloState[silo] = nil
            siloHooked[silo] = nil
            siloJustFinished[silo] = nil
            siloProducingSeen[silo] = nil
        end
    end)
end

local missileHooked = setmetatable({}, {__mode = "k"})

local function hookMissile(missile)
    if missileHooked[missile] then return end
    missileHooked[missile] = true

    local owner = claimMissile(missile)
    if owner then recomputeSiloState(owner) end

    missile.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if owner then recomputeSiloState(owner) end
            missileOwner[missile] = nil
            missileHooked[missile] = nil
        end
    end)
end

local function scanTeamFolder(teamFolder)
    if not teamFolder or not teamFolder.Parent then return end
    for _, child in ipairs(teamFolder:GetChildren()) do
        if child:IsA("Model") and child.Name == "Nuclear Silo" then
            hookSilo(child)
        elseif child:IsA("Model") and (child.Name == "Nuclear Missile" or child.Name == "Fire Missile") then
            hookMissile(child)
        end
    end
end

-- Initial scan
for _, teamFolder in ipairs(TeamsFolder:GetChildren()) do
    scanTeamFolder(teamFolder)
    teamFolder.ChildAdded:Connect(function(child)
        task.defer(function()
            if child:IsA("Model") and child.Name == "Nuclear Silo" then
                hookSilo(child)
            elseif child:IsA("Model") and (child.Name == "Nuclear Missile" or child.Name == "Fire Missile") then
                hookMissile(child)
            end
        end)
    end)
end

TeamsFolder.ChildAdded:Connect(function(teamFolder)
    scanTeamFolder(teamFolder)
    teamFolder.ChildAdded:Connect(function(child)
        task.defer(function()
            if child:IsA("Model") and child.Name == "Nuclear Silo" then
                hookSilo(child)
            elseif child:IsA("Model") and (child.Name == "Nuclear Missile" or child.Name == "Fire Missile") then
                hookMissile(child)
            end
        end)
    end)
end)

-- Poll loop. Two passes:
--   Pass 1: detect every silo's producing→finished transition and stamp markers.
--   Pass 2: refresh idle cache, try to claim any unclaimed idle missiles,
--           then recompute state for each silo.
task.spawn(function()
    while true do
        task.wait(0.5)

        for silo in pairs(siloHooked) do
            if silo and silo.Parent then
                detectFinishTransition(silo)
            end
        end

        refreshIdleMissiles()

        for _, m in ipairs(idleMissiles) do
            if not missileOwner[m] then
                local owner = claimMissile(m)
                if owner then recomputeSiloState(owner) end
            end
        end

        for silo in pairs(siloHooked) do
            if silo and silo.Parent then
                recomputeSiloState(silo)
            else
                siloHooked[silo] = nil
                siloState[silo] = nil
                siloProducingSeen[silo] = nil
                siloJustFinished[silo] = nil
            end
        end
    end
end)

-- Styles
local function styleSilo(model)
    local mode = Options.SiloColorMode.Value
    local outline, inner, oTrans
    if mode == 'Team Color' then
        local col = TeamData.getColor(model)
        outline = col:Lerp(Color3.new(0,0,0), 0.3)
        inner = col
        oTrans = 1 - Options.SiloOutlineThickness.Value
    elseif mode == 'RGB' then
        inner = getGlobalRGBColor()
        outline = inner:Lerp(Color3.new(0,0,0), 0.3)
        oTrans = 1 - Options.SiloOutlineThickness.Value
    elseif mode:find("Green, Yellow, Red") then
        local state = siloNukeState(model)
        if state == "ready" then inner = Color3.fromRGB(255,0,0)
        elseif state == "producing" then inner = Color3.fromRGB(255,255,0)
        else inner = Color3.fromRGB(0,255,0) end
        outline = inner:Lerp(Color3.new(0,0,0), 0.3)
        oTrans = 1 - Options.SiloOutlineThickness.Value
    else
        outline = Options.SiloOutlineColor.Value
        inner = Options.SiloInnerColor.Value
        oTrans = 1 - Options.SiloOutlineThickness.Value
    end
    return inner, outline, 0.5, oTrans
end

local function styleNuke(model)
    local moving = isMoving(model)
    local mode = moving and Options.MovingColorMode.Value or Options.IdleColorMode.Value
    local outline, inner, oTrans
    if mode == 'Team Color' then
        local col = TeamData.getColor(model)
        outline = col:Lerp(Color3.new(0,0,0), 0.3); inner = col
        oTrans = 1 - (moving and Options.MovingOutlineThickness.Value or Options.IdleOutlineThickness.Value)
    elseif mode == 'RGB' then
        inner = getGlobalRGBColor()
        outline = inner:Lerp(Color3.new(0,0,0), 0.3)
        oTrans = 1 - (moving and Options.MovingOutlineThickness.Value or Options.IdleOutlineThickness.Value)
    else
        outline = moving and Options.MovingOutlineColor.Value or Options.IdleOutlineColor.Value
        inner = moving and Options.MovingInnerColor.Value or Options.IdleInnerColor.Value
        oTrans = 1 - (moving and Options.MovingOutlineThickness.Value or Options.IdleOutlineThickness.Value)
    end
    return inner, outline, 0.5, oTrans
end

local nukeRegistered = {}
local siloRegistered = {}

local function tryRegisterNuke(model)
    if not Toggles.NukeESPEnabled.Value then return end
    if model.Name ~= "Nuclear Missile" and model.Name ~= "Fire Missile" then return end
    if nukeRegistered[model] then return end
    nukeRegistered[model] = true
    HighlightManager.attach(model, styleNuke)
end

local function tryRegisterSilo(model)
    if not Toggles.SiloESPEnabled.Value then return end
    if model.Name ~= "Nuclear Silo" then return end
    if siloRegistered[model] then return end
    siloRegistered[model] = true
    HighlightManager.attach(model, styleSilo)
end

-- Fast rescan (only when toggles flip)
local function rescanNukes()
    for m in pairs(nukeRegistered) do
        HighlightManager.detach(m); nukeRegistered[m] = nil
    end
    if not Toggles.NukeESPEnabled.Value then return end
    for _, tf in ipairs(TeamsFolder:GetChildren()) do
        for _, m in ipairs(tf:GetChildren()) do
            if m:IsA("Model") and (m.Name == "Nuclear Missile" or m.Name == "Fire Missile") then
                local isLocal = isLocalOwner(m)
                local isEnemy = TeamData.isEnemy(tf.Name)
                local hideByTeam  = Toggles.NukeESPTeamCheck.Value and not isEnemy and not isLocal
                local hideByLocal = Toggles.NukeESPIgnoreLocal.Value and isLocal
                if not (hideByTeam or hideByLocal) then
                    tryRegisterNuke(m)
                end
            end
        end
    end
end

local function rescanSilos()
    for m in pairs(siloRegistered) do
        HighlightManager.detach(m); siloRegistered[m] = nil
    end
    if not Toggles.SiloESPEnabled.Value then return end
    for _, tf in ipairs(TeamsFolder:GetChildren()) do
        for _, m in ipairs(tf:GetChildren()) do
            if m:IsA("Model") and m.Name == "Nuclear Silo" then
                local isLocal = isLocalOwner(m)
                local isEnemy = TeamData.isEnemy(tf.Name)
                local hideByTeam  = Toggles.SiloESPTeamCheck.Value and not isEnemy and not isLocal
                local hideByLocal = Toggles.SiloESPIgnoreLocal.Value and isLocal
                if not (hideByTeam or hideByLocal) then
                    tryRegisterSilo(m)
				    recomputeSiloState(m)
                end
            end
        end
    end
end

Toggles.NukeESPEnabled:OnChanged(rescanNukes)
Toggles.NukeESPTeamCheck:OnChanged(rescanNukes)
Toggles.NukeESPIgnoreLocal:OnChanged(rescanNukes)
Toggles.SiloESPEnabled:OnChanged(rescanSilos)
Toggles.SiloESPTeamCheck:OnChanged(rescanSilos)
Toggles.SiloESPIgnoreLocal:OnChanged(rescanSilos)

-- Housekeeping pass: drop highlights for models that no longer exist
local function espTick()
    if Toggles.NukeESPEnabled.Value then
        for m in pairs(nukeRegistered) do
            if not m.Parent or not m:IsDescendantOf(TeamsFolder) then
                HighlightManager.detach(m); nukeRegistered[m] = nil
            end
        end
    end
    if Toggles.SiloESPEnabled.Value then
        for m in pairs(siloRegistered) do
            if not m.Parent or not m:IsDescendantOf(TeamsFolder) then
                HighlightManager.detach(m); siloRegistered[m] = nil
            end
        end
    end
end




-- Unified missile scanner: feeds the predictor AND fires launch notifications.
-- We can't rely on DescendantAdded here because the game often adds the
-- missile with a placeholder name and renames it later.
local notifiedLaunches = {}

local function nukeLaunchTick()
    for _, tf in ipairs(TeamsFolder:GetChildren()) do
        for _, m in ipairs(tf:GetChildren()) do
            if m:IsA("Model")
               and (m.Name == "Nuclear Missile" or m.Name == "Fire Missile") then

                -- 1) Predictor: queue anything we haven't seen yet
                if not trackedMissiles[m] and not Predictor.pendingMissiles[m] then
                    Predictor.pendingMissiles[m] = true
                end

                -- 2) Launch notification: fire once on velocity threshold
                if Toggles.NotifyNukeLaunch.Value and not notifiedLaunches[m] then
                    local root = m:FindFirstChild("Torso") or m:FindFirstChildWhichIsA("BasePart")
                    if root then
                        local bv = root:FindFirstChild("BodyVelocity")
                        local vel = bv and bv.Velocity or root.AssemblyLinearVelocity
                        if vel.Magnitude >= 5 then
                            notifiedLaunches[m] = true
                            onMissileLaunched(m)
                        end
                    end
                end
            end
        end
    end

    for m in pairs(notifiedLaunches) do
        if not m.Parent then notifiedLaunches[m] = nil end
    end
end






-- ============================================================
-- HIGHLIGHTER (main ESP) - via HighlightManager
-- ============================================================
local espHighlighted = {}   -- [part] = {model, team}

local function shouldHighlight(name)
    name = name:lower()
    if name == "anti-air soldier"       and Toggles.ESP_Soldier_AntiAir_Enabled.Value then return true end
    if name == "construction soldier"   and Toggles.ESP_Soldier_Construction_Enabled.Value then return true end
    if name == "hovercraft"             and Toggles.ESP_Soldier_Hovercraft_Enabled.Value then return true end
    if name == "juggernaut"             and Toggles.ESP_Soldier_Juggernaut_Enabled.Value then return true end
    if name == "medic"                  and Toggles.ESP_Soldier_Medic_Enabled.Value then return true end
    if name == "sniper"                 and Toggles.ESP_Soldier_Sniper_Enabled.Value then return true end
    if name == "helicopter"             and Toggles.ESP_Air_Helicopter_Enabled.Value then return true end
    if name == "mothership"             and Toggles.ESP_Air_Mothership_Enabled.Value then return true end
    if name == "space fighter"          and Toggles.ESP_Air_SpaceFighter_Enabled.Value then return true end
    if name == "stealth bomber"         and Toggles.ESP_Air_StealthBomber_Enabled.Value then return true end
    if name == "transport plane"        and Toggles.ESP_Air_TransportPlane_Enabled.Value then return true end
    if name == "anti-air tank"          and Toggles.ESP_Tank_AntiAir_Enabled.Value then return true end
    if name == "explosive tank"         and Toggles.ESP_Tank_Explosive_Enabled.Value then return true end
    if name == "heavy tank"             and Toggles.ESP_Tank_Heavy_Enabled.Value then return true end
    if name == "aircraft carrier"       and Toggles.ESP_Navy_AircraftCarrier_Enabled.Value then return true end
    if name == "transport ship"         and Toggles.ESP_Navy_TransportShip_Enabled.Value then return true end
    if name == "airport"                and Toggles.ESP_Prod_Airport_Enabled.Value then return true end
    if name == "barracks"               and Toggles.ESP_Prod_Barracks_Enabled.Value then return true end
    if name == "fort"                   and Toggles.ESP_Prod_Fort_Enabled.Value then return true end
    if name == "naval shipyard"         and Toggles.ESP_Prod_Shipyard_Enabled.Value then return true end
    if name == "space link"             and Toggles.ESP_Prod_SpaceLink_Enabled.Value then return true end
    if name == "tank factory"           and Toggles.ESP_Prod_TankFactory_Enabled.Value then return true end
    if name == "nuclear plant"          and Toggles.ESP_Prod_NuclearPlant_Enabled.Value then return true end
    if name == "power plant"            and Toggles.ESP_Prod_PowerPlant_Enabled.Value then return true end
    if name == "anti-air turret"        and Toggles.ESP_Build_AntiAirTurret_Enabled.Value then return true end
    if name == "command center"         and Toggles.ESP_Build_CommandCenter_Enabled.Value then return true end
    if name == "headquarters"           and Toggles.ESP_Build_Headquarters_Enabled.Value then return true end
    if name == "naval house"            and Toggles.ESP_Build_NavalHouse_Enabled.Value then return true end
    if name == "plane house"            and Toggles.ESP_Build_PlaneHouse_Enabled.Value then return true end
    if name == "shield generator"       and Toggles.ESP_Build_ShieldGen_Enabled.Value then return true end
    if name == "soldier house"          and Toggles.ESP_Build_SoldierHouse_Enabled.Value then return true end
    if name == "tank house"             and Toggles.ESP_Build_TankHouse_Enabled.Value then return true end
    if name == "turret"                 and Toggles.ESP_Build_Turret_Enabled.Value then return true end
    return false
end

local function categoryTeamCheck(name)
    name = name:lower()
    if name:find("soldier") or name == "hovercraft" or name == "juggernaut" then
        return Toggles.ESP_Soldiers_TeamCheck.Value
    end
    if name == "helicopter" or name == "mothership" or name == "space fighter"
    or name == "stealth bomber" or name == "transport plane" then
        return Toggles.ESP_Air_TeamCheck.Value
    end
    if name:find("tank") then return Toggles.ESP_Tanks_TeamCheck.Value end
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

local function findModelAndTeam(inst)
    local obj = inst
    local model = nil
    while obj and obj ~= TeamsFolder do
        if not model and obj:IsA("Model") then model = obj end
        if obj.Parent == TeamsFolder then return model, obj.Name end
        obj = obj.Parent
    end
    return nil, nil
end

local function styleESP(part)
    local info = espHighlighted[part]
    if not info then return end
    local mode = Options.HighlightMode.Value
    local fill, outline
    if mode == 'Team Color' then
        if info.teamColor then
            fill = info.teamColor
            outline = info.teamColor:Lerp(Color3.new(0,0,0), 0.3)
        else
            fill = Color3.new(1,1,1); outline = Color3.new(0,0,0)
        end
    elseif mode == 'RGB' then
        fill = getGlobalRGBColor()
        outline = fill:Lerp(Color3.new(0,0,0), 0.3)
    else
        fill = Options.HighlightCustomFillColor.Value
        outline = Options.HighlightCustomOutlineColor.Value
    end
    return fill, outline, Options.HighlightTransparency.Value,
           1 - Options.HighlightOutlineThickness.Value
end

local function espHandleInstance(inst)
    if not Toggles.EnableHighlighter.Value then return end
    local part = inst
    if not (part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation")) then return end
    if espHighlighted[part] then return end
    local model, teamName = findModelAndTeam(inst)
    if not model then return end
    local modelName = model.Name
    if categoryTeamCheck(modelName) and teamName and not TeamData.isEnemy(teamName) then return end
    if not shouldHighlight(modelName) then return end
    local teamColor = nil
    if Options.HighlightMode.Value == 'Team Color' and teamName then
        teamColor = TeamData.getColor(teamName)
    end
    espHighlighted[part] = { teamColor = teamColor }
    HighlightManager.attach(part, styleESP)
end

local function espClearAll()
    for part in pairs(espHighlighted) do
        HighlightManager.detach(part)
    end
    espHighlighted = {}
end

local function espRescan()
    espClearAll()
    if not Toggles.EnableHighlighter.Value then return end
    for _, inst in ipairs(TeamsFolder:GetDescendants()) do
        espHandleInstance(inst)
    end
end

Toggles.EnableHighlighter:OnChanged(function()
    if Toggles.EnableHighlighter.Value then espRescan() else espClearAll() end
end)

-- Refresh on option changes
local function hookRefresh(id)
    local t = Toggles[id] or Options[id]
    if t and t.OnChanged then
        t:OnChanged(function()
            if Toggles.EnableHighlighter.Value then espRescan() end
        end)
    end
end
for _, id in ipairs({
    "ESP_Soldier_AntiAir_Enabled","ESP_Soldier_Construction_Enabled","ESP_Soldier_Hovercraft_Enabled",
    "ESP_Soldier_Juggernaut_Enabled","ESP_Soldier_Medic_Enabled","ESP_Soldier_Sniper_Enabled",
    "ESP_Air_Helicopter_Enabled","ESP_Air_Mothership_Enabled","ESP_Air_SpaceFighter_Enabled",
    "ESP_Air_StealthBomber_Enabled","ESP_Air_TransportPlane_Enabled",
    "ESP_Tank_AntiAir_Enabled","ESP_Tank_Explosive_Enabled","ESP_Tank_Heavy_Enabled",
    "ESP_Navy_AircraftCarrier_Enabled","ESP_Navy_TransportShip_Enabled",
    "ESP_Prod_Airport_Enabled","ESP_Prod_Barracks_Enabled","ESP_Prod_Fort_Enabled",
    "ESP_Prod_Shipyard_Enabled","ESP_Prod_SpaceLink_Enabled","ESP_Prod_TankFactory_Enabled",
    "ESP_Prod_NuclearPlant_Enabled","ESP_Prod_PowerPlant_Enabled",
    "ESP_Build_AntiAirTurret_Enabled","ESP_Build_CommandCenter_Enabled","ESP_Build_Headquarters_Enabled",
    "ESP_Build_NavalHouse_Enabled","ESP_Build_PlaneHouse_Enabled","ESP_Build_ShieldGen_Enabled",
    "ESP_Build_SoldierHouse_Enabled","ESP_Build_TankHouse_Enabled","ESP_Build_Turret_Enabled",
    "ESP_Soldiers_TeamCheck","ESP_Air_TeamCheck","ESP_Tanks_TeamCheck","ESP_Navy_TeamCheck",
    "ESP_Prod_TeamCheck","ESP_Buildings_TeamCheck",
    "HighlightMode","HighlightCustomFillColor","HighlightCustomOutlineColor",
    "HighlightTransparency","HighlightOutlineThickness",
}) do hookRefresh(id) end

-- ============================================================
-- BUILDING NOTIFICATIONS
-- ============================================================
local BuildingMessages = {
    ["Airport"]            = { msg = "PLACED AN AIRPORT",           emoji = "✈️",  toggle = "Notify_Airport" },
    ["Barracks"]           = { msg = "PLACED A BARRACKS",           emoji = "⚔️",  toggle = "Notify_Barracks" },
    ["Fort"]               = { msg = "PLACED A FORT",               emoji = "🏰",  toggle = "Notify_Fort" },
    ["Naval Shipyard"]     = { msg = "PLACED A NAVAL SHIPYARD",     emoji = "⚓",  toggle = "Notify_Shipyard" },
    ["Nuclear Silo"]       = { msg = "PLACED A NUCLEAR SILO",       emoji = "☢️☢️", toggle = "Notify_Nuke" },
    ["Shield Generator"]   = { msg = "PLACED A SHIELD GENERATOR",   emoji = "🛡️",  toggle = "Notify_ShieldGen" },
    ["Space Link"]         = { msg = "PLACED A SPACE LINK",         emoji = "🛰️",  toggle = "Notify_SpaceLink" },
    ["Tank Factory"]       = { msg = "PLACED A TANK FACTORY",       emoji = "🚜",  toggle = "Notify_TankFactory" },
}

local function getBuilderName(teamColor)
    return TeamData.getOnlinePlayer(teamColor) or "UNKNOWN"
end

local lastPlayerPosition = nil

local function watchTeam(teamFolder)
    teamFolder.ChildAdded:Connect(function(building)
        if not Toggles.NotifyBuildings.Value then return end
        local data = BuildingMessages[building.Name]
        if not data then return end
        if Toggles[data.toggle] and not Toggles[data.toggle].Value then return end

        local color = teamFolder.Name
        if Toggles.NotifyTeamCheck.Value and not TeamData.isEnemy(color) then return end

        local short = shortColorName(color)
        local emoji = GetTeamEmoji and GetTeamEmoji(color) or ""
        local builder = getBuilderName(color)

        local title = data.emoji .. " Building Placed " .. data.emoji
        local text = string.format("%s%s | %s %s%s", emoji, short, builder, data.msg, emoji)

        Notifier.send(title, text, {
            {
                label = "TELEPORT",
                callback = function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    lastPlayerPosition = hrp.CFrame
                    local pivot = building:GetPivot()
                    hrp.CFrame = CFrame.new(pivot.Position + Vector3.new(0,5,0))
                    Notifier.send("Return?", "Go back to your previous location", {
                        { label = "GO BACK", callback = function()
                            if lastPlayerPosition then
                                local c2 = LocalPlayer.Character
                                if c2 and c2:FindFirstChild("HumanoidRootPart") then
                                    c2.HumanoidRootPart.CFrame = lastPlayerPosition
                                end
                            end
                        end }
                    }, 10)
                end
            }
        }, 10)
    end)
end

for _, tf in ipairs(TeamsFolder:GetChildren()) do watchTeam(tf) end
TeamsFolder.ChildAdded:Connect(watchTeam)

-- ============================================================
-- NUKE INFO TAB LOGIC (event-driven refresh)
-- ============================================================
local TeamColorEmoji = {
    ["bright red"]="🟥", ["bright blue"]="🟦", ["bright green"]="🟩",
    ["bright yellow"]="🟨", ["bright orange"]="🟧", ["bright violet"]="🟪",
    ["reddish brown"]="🟫", ["really black"]="⬛", ["really white"]="⬜",
}
local function NormalizeTeamName(n) return tostring(n):lower():gsub("_"," "):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","") end
function GetTeamEmoji(name) return TeamColorEmoji[NormalizeTeamName(name)] or "" end

local function NE_IsMissile(i) return i.Name == "Nuclear Missile" or i.Name == "Fire Missile" end
local function NE_IsSilo(i) return i.Name == "Nuclear Silo" end

local function NE_ScanTeam(teamFolder)
    local state = {
        hasSilo = false, building = 0,
        nukeProd = {}, fireProd = {},
        nukeReady = {}, fireReady = {},
        launched = {}, queued = 0,
    }
    for _, inst in ipairs(teamFolder:GetDescendants()) do
        if NE_IsSilo(inst) then
            state.hasSilo = true
            local torso = inst:FindFirstChild("Torso")
            if torso then
                local bp = torso:FindFirstChild("BuildProgress")
                if bp and bp:IsA("NumberValue") then
                    local v = bp.Value
                    if v > 0 and v < 1 then state.building = math.floor(v * 100 + 0.5)
                    elseif v >= 1 then state.building = 100 end
                end
                local producing = torso:FindFirstChild("Producing")
                if producing then
                    for _, missile in ipairs(producing:GetChildren()) do
                        if NE_IsMissile(missile) then
                            state.queued = state.queued + 1
                            local prog = missile:FindFirstChild("Progress")
                            local pct = prog and math.floor((prog.Value or 0) * 100 + 0.5) or 0
                            if pct > 0 and pct < 100 then
                                if missile.Name == "Nuclear Missile" then
                                    state.nukeProd[missile] = pct
                                else
                                    state.fireProd[missile] = pct
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    for _, tf in ipairs(TeamsFolder:GetChildren()) do
        for _, obj in ipairs(tf:GetChildren()) do
            if NE_IsMissile(obj) then
                local creator = obj:FindFirstChild("Team")
                local creatorTeam = creator and creator.Value or tf.Name
                if creatorTeam == teamFolder.Name then
                    local root = obj:FindFirstChild("Root") or obj:FindFirstChildWhichIsA("BasePart")
                    local vel = root and root.AssemblyLinearVelocity.Magnitude or 0
                    if vel > 1 then state.launched[obj] = true
                    elseif obj.Name == "Nuclear Missile" then state.nukeReady[obj] = true
                    else state.fireReady[obj] = true end
                end
            end
        end
    end
    return state
end

local function BuildTeamBlock(teamColor)
    local state = NE_ScanTeam(TeamsFolder:FindFirstChild(teamColor) or { GetDescendants = function() return {} end, Name = "" })
    local short = shortColorName(teamColor)
    local emoji = GetTeamEmoji(teamColor)
    local playerName = TeamData.getOnlinePlayer(teamColor) or "NO PLAYER"
    local lines = {}
    table.insert(lines, string.format("%s%s - %s (%d)", emoji, short, playerName, state.queued or 0))
    if not state.hasSilo then
        table.insert(lines, "NO SILO FOUND")
        return table.concat(lines, "\n")
    end
    if state.building > 0 and state.building < 100 then
        table.insert(lines, "SILO BUILDING - (" .. state.building .. "%)")
    end
    local nukeProdCount = 0
    for _ in pairs(state.nukeProd) do nukeProdCount = nukeProdCount + 1 end
    local fireProdCount = 0
    for _ in pairs(state.fireProd) do fireProdCount = fireProdCount + 1 end
    local nukeReadyCount, fireReadyCount, launchedCount = 0, 0, 0
    for _ in pairs(state.nukeReady) do nukeReadyCount = nukeReadyCount + 1 end
    for _ in pairs(state.fireReady) do fireReadyCount = fireReadyCount + 1 end
    for _ in pairs(state.launched) do launchedCount = launchedCount + 1 end

    if nukeProdCount > 0 then table.insert(lines, "NUKE PRODUCING - (" .. state.nukeProd[next(state.nukeProd)] .. "%)") end
    if fireProdCount > 0 then table.insert(lines, "FIRE PRODUCING - (" .. state.fireProd[next(state.fireProd)] .. "%)") end
    if nukeReadyCount > 0 then table.insert(lines, "✅ NUKE READY") end
    if fireReadyCount > 0 then table.insert(lines, "✅ FNUKE READY") end
    if launchedCount > 0 then table.insert(lines, "☢️ NUKE LAUNCHED ☢️") end

    local nothing = state.building == 0 and nukeProdCount == 0 and fireProdCount == 0
        and nukeReadyCount == 0 and fireReadyCount == 0 and launchedCount == 0
    if nothing then table.insert(lines, "SILO IS IDLE") end
    return table.concat(lines, "\n")
end

local function RefreshNukeInfo()
    if not labelIsVisible(NI_Labels[1]) then return end
    local alliances = TeamData.getAllAlliances()
    for i = 1, 3 do
        local lbl, alliance = NI_Labels[i], alliances[i]
        if not alliance or #alliance == 0 then
            lbl:SetText("No alliance data.")
        else
            local blocks = {}
            for _, c in ipairs(alliance) do table.insert(blocks, BuildTeamBlock(c)) end
            lbl:SetText(table.concat(blocks, "\n\n"))
        end
        ResizeBox(lbl, NI_Groups[i])
    end
end

-- ============================================================
-- PLAYER INFO TAB LOGIC
-- ============================================================
local function formatTime(s)
    if not s or s == 0 then return "0h 0m" end
    return string.format("%dh %dm", math.floor(s/3600), math.floor((s%3600)/60))
end
local function safeFormatDate(u)
    if not u or u == 0 then return "N/A" end
    local ok, r = pcall(function() return os.date("%d/%m/%y", u) end)
    return ok and r or "N/A"
end

local function RefreshPlayerInfo()
    if not labelIsVisible(PI_Labels[1]) then return end
    local alliances = TeamData.getAllAlliances()
    local output = {}
    for i, alliance in ipairs(alliances) do
        local blocks = {}
        local seen = {}
        for _, teamColor in ipairs(alliance) do
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.TeamColor and plr.TeamColor.Name == teamColor and not seen[plr.Name] then
                    seen[plr.Name] = teamColor
                end
            end
        end

        local stats = {}
        for name, teamColor in pairs(seen) do
            local player = Players:FindFirstChild(name)
            if player then
                local damage, healed = 0, 0
                local folder = TeamSettings:FindFirstChild(teamColor)
                if folder then
                    local d = folder:FindFirstChild("DamageDealt")
                    if d then local v = d:FindFirstChild(name); if v and v:IsA("NumberValue") then damage = v.Value end end
                    local h = folder:FindFirstChild("DamageHealed")
                    if h then local v = h:FindFirstChild(name); if v and v:IsA("NumberValue") then healed = v.Value end end
                end
                local timePlayed, firstJoin, robuxSpent, level = "N/A", "N/A", "N/A", "N/A"
                local s = player:FindFirstChild("Stats")
                if s then
                    local tp = s:FindFirstChild("timePlayed"); if tp and tp:IsA("NumberValue") then timePlayed = formatTime(tp.Value) end
                    local fj = s:FindFirstChild("firstJoinTime"); if fj and fj:IsA("NumberValue") then firstJoin = safeFormatDate(fj.Value) end
                    local rs = s:FindFirstChild("robuxSpent"); if rs and rs:IsA("NumberValue") then robuxSpent = tostring(rs.Value) end
                    local lv = s:FindFirstChild("levelsRewarded")
                    if lv then
                        local mx = 0
                        for _, c in ipairs(lv:GetChildren()) do
                            local v = c:IsA("NumberValue") and c.Value or tonumber(c.Name)
                            if v and v > mx then mx = v end
                        end
                        if mx > 0 then level = tostring(mx) end
                    end
                end
                table.insert(stats, {
                    name = name, team = teamColor, damage = damage, healed = healed,
                    timePlayed = timePlayed, firstJoin = firstJoin,
                    robuxSpent = robuxSpent, level = level,
                })
            end
        end
        table.sort(stats, function(a, b) return a.damage > b.damage end)
        for _, ps in ipairs(stats) do
            local lines = {}
            table.insert(lines, string.format("%s%s [%s]", GetTeamEmoji(ps.team), shortColorName(ps.team), ps.name))
            table.insert(lines, string.format("  DMG: %d | HEAL: %d", ps.damage, ps.healed))
            table.insert(lines, string.format("  Time: %s", ps.timePlayed))
            table.insert(lines, string.format("  Joined: %s", ps.firstJoin))
            table.insert(lines, string.format("  Robux: %s", ps.robuxSpent))
            table.insert(lines, string.format("  Level: %s", ps.level))
            table.insert(blocks, table.concat(lines, "\n"))
        end
        if #blocks == 0 then table.insert(blocks, "No online players.") end
        output[i] = table.concat(blocks, "\n\n")
    end
    for i = 1, 3 do
        if PI_Labels[i] then
            PI_Labels[i]:SetText(output[i] or "No data.")
            ResizeBox(PI_Labels[i], PI_Groups[i])
        end
    end
end

-- ============================================================
-- SINGLE HEARTBEAT SCHEDULER
-- ============================================================
local INTERVALS = {
    predictor    = 1/60,
    espTick      = 1/15,
    nukeInfo     = 0.2,
    playerInfo   = 1.0,
    garrisonSlow = 2.0,   -- fallback for when camera is still
}
local accum = { predictor=0, espTick=0, nukeInfo=0, playerInfo=0, garrisonSlow=0 }


-- Predictor RGB updates inline (cheap)
local lastRGBAnim = 0

RunService.Heartbeat:Connect(function(dt)
    -- Unified highlight tick (applies styles to every registered highlight)
    HighlightManager.tick()

    -- Subsystem scheduling
    accum.predictor = accum.predictor + dt
    if accum.predictor >= INTERVALS.predictor then
        accum.predictor = 0
        updatePredictor()
    end

    accum.espTick = accum.espTick + dt
    if accum.espTick >= INTERVALS.espTick then
        accum.espTick = 0
        espTick()
    end

    accum.nukeInfo = accum.nukeInfo + dt
    if accum.nukeInfo >= INTERVALS.nukeInfo then
        accum.nukeInfo = 0
        RefreshNukeInfo()
    end

    accum.playerInfo = accum.playerInfo + dt
    if accum.playerInfo >= INTERVALS.playerInfo then
        accum.playerInfo = 0
        RefreshPlayerInfo()
    end

    accum.garrisonSlow = accum.garrisonSlow + dt
    if accum.garrisonSlow >= INTERVALS.garrisonSlow then
        accum.garrisonSlow = 0
        UpdateAllDisplays()
    end
	
	
    accum.nukeNotify = (accum.nukeNotify or 0) + dt
    if accum.nukeNotify >= 0.3 then
        accum.nukeNotify = 0
        nukeLaunchTick()
        RangeIndicator.maintain()
    end


    -- Garrison dirty rebuild
    if next(DirtyBuildings) ~= nil then
        for b in pairs(DirtyBuildings) do
            local d = ActiveDisplays[b]
            if d then
                if d.folder then UpdateGarrisonDisplay(b, d.folder:GetChildren()) end
                if d.productionFolder and Toggles.ProductionViewEnabled.Value then
                    BuildProductionRows(d)
                end
                UpdateDisplaySize(d)
            end
            DirtyBuildings[b] = nil
        end
    end
end)


-- RenderStep follow: garrison + range indicator both update at render rate
RunService:BindToRenderStep("GarrisonFollow", Enum.RenderPriority.Camera.Value + 1, function()
    if GARRISON_VIEW_ENABLED and next(ActiveDisplays) ~= nil then
        local cam = workspace.CurrentCamera
        if cam then
            local camPos = cam.CFrame.Position
            local myTeam = TeamData.getMyTeamColor()
            local myAllies = TeamData.getMyAlliedColors()
            for _, d in pairs(ActiveDisplays) do
                UpdateOneDisplay(d, camPos, myTeam, myAllies)
            end
        end
    end

    -- Range rings follow their units every frame
    RangeIndicator.followTick()
end)

-- ============================================================
-- SINGLE DescendantAdded DISPATCHER
-- ============================================================
TeamsFolder.DescendantAdded:Connect(function(desc)
    -- Nuke / silo ESP
    if desc:IsA("Model") then
        if desc.Name == "Nuclear Missile" or desc.Name == "Fire Missile" then
            -- check conditions
            local tf = desc.Parent
            if Toggles.NukeESPEnabled.Value then
                local isLocal = isLocalOwner(desc)
                local isEnemy = tf and TeamData.isEnemy(tf.Name)
                local hideByTeam  = Toggles.NukeESPTeamCheck.Value and not isEnemy and not isLocal
                local hideByLocal = Toggles.NukeESPIgnoreLocal.Value and isLocal
                if not (hideByTeam or hideByLocal) then
                    tryRegisterNuke(desc)
                end
            end
            -- Predictor tracking
            Predictor.onMissileAdded(desc)
			
        elseif desc.Name == "Nuclear Silo" then
            if Toggles.SiloESPEnabled.Value then
                local tf = desc.Parent
                local isLocal = isLocalOwner(desc)
                local isEnemy = tf and TeamData.isEnemy(tf.Name)
                local hideByTeam  = Toggles.SiloESPTeamCheck.Value and not isEnemy and not isLocal
                local hideByLocal = Toggles.SiloESPIgnoreLocal.Value and isLocal
                if not (hideByTeam or hideByLocal) then
                    tryRegisterSilo(desc)
                end
            end
        end
    end
	
	    -- Range Indicator
    RangeIndicator.onAdded(desc)

    -- Main highlighter
    if Toggles.EnableHighlighter.Value then
        espHandleInstance(desc)
    end
end)

-- ============================================================
-- WATERMARK + UNLOAD
-- ============================================================
Library:SetWatermarkVisibility(true)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60
local WatermarkConnection = RunService.RenderStepped:Connect(function()
    FrameCounter = FrameCounter + 1
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    Library:SetWatermark(('LELOUCHWARE V0.11 | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ))
end)

Library.KeybindFrame.Visible = false

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    HighlightManager.detachAll()
    print('Unloaded!')
    Library.Unloaded = true
end)


task.delay(2, function()
    RefreshNukeInfo()
    RefreshPlayerInfo()
end)




SaveManager:LoadAutoloadConfig()
