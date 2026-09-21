
-- Script access control
-- Only these Roblox UserIds are allowed to use the script.
local ALLOWED_USER_IDS = {
    [8793354147] = true,
    [11195516193] = true,
    [5198136088] = true,
    [8619380916] = true,
    [5525930098] = true,
    [242352065] = true,
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer or not ALLOWED_USER_IDS[LocalPlayer.UserId] then
    if LocalPlayer then
        LocalPlayer:Kick("Buy The Script First !")
    end
    return
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local currentThemeColor = Color3.fromRGB(170, 0, 255)

local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local player = Players.LocalPlayer or Players:FindFirstChildOfClass("Player")

local camera = workspace.CurrentCamera
local mouse = nil
pcall(function() mouse = player and player:GetMouse() end)

local playerGui = nil
pcall(function() 
    if player then
        playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
    end
end)

function _decodeUrl(b)
    local s = {}
    for i = 1, #b do
        local a, k = b[i], 0x5A
        local r, p = 0, 1
        while a > 0 or k > 0 do
            local ra, rk = a % 2, k % 2
            if ra ~= rk then r = r + p end
            a, k, p = (a - ra) / 2, (k - rk) / 2, p * 2
        end
        s[i] = string.char(r)
    end
    return table.concat(s)
end

scriptStartTime = os.time()
totalExecutions = 0
startBounty = 0
accumulatedBountyGained = 0

pcall(function()
    if isfile and readfile and isfile("ProdigyAHK_Bounty.json") then
        local bData = HttpService:JSONDecode(readfile("ProdigyAHK_Bounty.json"))
        if bData and bData.Gained then accumulatedBountyGained = bData.Gained end
    end
end)

function SaveLocalBounty(gained)
    accumulatedBountyGained = gained
    pcall(function()
        if writefile then
            writefile("ProdigyAHK_Bounty.json", HttpService:JSONEncode({Gained = gained}))
        end
    end)
end

SoruAimbotEnabled = false
soruMaxDist = 1000 
AimlockPlayerEnabled = false
AimlockNpcEnabled = false
SilentAimPlayersEnabled = false
SilentAimNPCsEnabled = false
PlayerWidgetActive = false
NpcWidgetActive = false
SelectedSoruTarget = "Nearest"
maxRange = 4000 -- capped at 4250
SilentAimTargetMode = "Nearest" -- Nearest / Lowest Health
CamLockFloatingEnabled = false
CamLockButtonWidth = 110
CamLockButtonHeight = 40
CamLockFloatingGui = nil
CamLockFloatingButton = nil
-- Floating button placement / interaction controls.
UIButtonMode = "Use" -- Use = tap actions, Move = reposition without triggering.
LockAllUIButtons = false -- locks Cam Lock movement.
CamLockButtonX, CamLockButtonY = 0.82, 0.62
FloatingX, FloatingY = 0.03, 0.5
PlayersPosition = nil
NPCPosition = nil

_G.G_AttackMobs = true
_G.G_AttackPlayers = true

_G.G_SilentAimSkill = false
_G.G_SilentAimPart = "HumanoidRootPart"
_G.G_SilentAimTargetPlayers = false
_G.G_SilentAimTargetMobs = false
_G.G_TargetRainbowBodyESP = false
_G.G_SilentAim360 = true 
_G.G_MaxAccuracyMode = false 
_G.G_SilentAimTeamCheck = false
_G.G_SilentAimSelectedPlayer = ""
_G.G_AimbotMelee = false
_G.G_AimbotFruit = false
_G.G_AimbotSword = false
_G.G_AimbotGun = false
_G.G_BlacklistFruitM1 = true
_G.G_UIAccentColor = "00FFFF"
_G.G_UITextScale = 1.0

local BLACKLIST_CATEGORIES = {"Melee", "Fruit", "Sword", "Gun"}
local BLACKLIST_MOVES_BY_CATEGORY = {
    Melee = {"Z", "X", "C", "V"},
    Fruit = {"M1", "Z", "X", "C", "V", "F"},
    Gun = {"M1", "Z", "X"},
    Sword = {"Z", "X"},
}
local BLACKLIST_MOVES = {"M1", "Z", "X", "C", "V", "F"}
for _, cat in ipairs(BLACKLIST_CATEGORIES) do
    for _, move in ipairs(BLACKLIST_MOVES) do
        _G["G_Blacklist_" .. cat .. "_" .. move] = _G["G_Blacklist_" .. cat .. "_" .. move] == true
    end
end

_G.G_Blacklist_Fruit_M1 = true
-- Gun M1 silent aim is permanently disabled.
_G.G_Blacklist_Gun_M1 = false
_G.G_SilentAimGunAutoFire = false
_G.G_GunM1SilentAim = true
_G.G_DragonGunM1 = false
_G.G_Blacklist_Sword_X = false
_G.G_BuddyXMode = "Off" -- Off / Auto / Manual

SuperJumpEnabled = false 
SuperJumpPower = 500 
noCDCharConnection = nil
SoulGuitarJumpEnabled = false
SoulGuitarWidgetVisible = false
SoulGuitarDashLength = 121 
soulGuitarBusy = false
fflagsThread = nil

BlacklistedPlayers = {}
FakeKorbloxEnabled = false
FakeHeadlessEnabled = false
currentFPS = 0
currentPing = 0
currentLang = "EN"

FPSBoostEnabled = false
local FPSBoostSaved = {}
function SetFPSBoost(enabled)
    FPSBoostEnabled = enabled == true
    if FPSBoostEnabled then
        FPSBoostSaved = {}
        pcall(function() FPSBoostSaved.GlobalShadows=Lighting.GlobalShadows; Lighting.GlobalShadows=false end)
        pcall(function() FPSBoostSaved.Diffuse=Lighting.EnvironmentDiffuseScale; FPSBoostSaved.Specular=Lighting.EnvironmentSpecularScale; Lighting.EnvironmentDiffuseScale=0; Lighting.EnvironmentSpecularScale=0 end)
        pcall(function()
            local terrain=workspace:FindFirstChildOfClass("Terrain")
            if terrain then FPSBoostSaved.Decoration=terrain.Decoration; terrain.Decoration=false end
        end)
        for _,obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                    FPSBoostSaved[obj]=obj.Enabled; obj.Enabled=false
                end
            end)
        end
    else
        pcall(function()
            if FPSBoostSaved.GlobalShadows~=nil then Lighting.GlobalShadows=FPSBoostSaved.GlobalShadows end
            if FPSBoostSaved.Diffuse~=nil then Lighting.EnvironmentDiffuseScale=FPSBoostSaved.Diffuse end
            if FPSBoostSaved.Specular~=nil then Lighting.EnvironmentSpecularScale=FPSBoostSaved.Specular end
            local terrain=workspace:FindFirstChildOfClass("Terrain")
            if terrain and FPSBoostSaved.Decoration~=nil then terrain.Decoration=FPSBoostSaved.Decoration end
        end)
        for obj,old in pairs(FPSBoostSaved) do
            if typeof(obj)=="Instance" and obj.Parent and type(old)=="boolean" then pcall(function() obj.Enabled=old end) end
        end
        FPSBoostSaved={}
    end
    pcall(SaveConfig)
end

workspace.DescendantAdded:Connect(function(obj)
    if not FPSBoostEnabled then return end
    pcall(function()
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            FPSBoostSaved[obj]=obj.Enabled; obj.Enabled=false
        end
    end)
end)

DashEnabled = false
DashLengthDist = 1
DashRunning = false
prevDashLength = 1 
prevDashEnabled = false 

UI_Toggle_Refreshes = {}
ToggleRegistryMap = {}

local function _jsonWrite(name, data)
    pcall(function()
        if writefile then writefile(name, HttpService:JSONEncode(data)) end
    end)
end

local function _jsonRead(name)
    local result
    pcall(function()
        if isfile and readfile and isfile(name) then
            result = HttpService:JSONDecode(readfile(name))
        end
    end)
    return result
end




function SaveConfig()
    local conf = {
        ESPMaster=_G.G_ESPEnabled, ESPName=_G.G_ESP_Name, ESPLevel=_G.G_ESP_Level,
        ESPBounty=_G.G_ESP_Bounty, ESPFruit=_G.G_ESP_Fruit, ESPDist=_G.G_ESP_Distance,
        ESPHealth=_G.G_ESP_HP, ESPHighlight=_G.G_ESP_Highlight, ESPTextSize=_G.G_ESP_TextSize, ESPLineThickness=_G.G_ESP_LineThickness, ESPLineColor=_G.G_ESP_LineColor,
        FastAttack=FastAttackEnabled, WalkSpeed=WalkSpeedEnabled, WSpeedVal=WalkSpeedValue,
        Dash=DashEnabled, DashDist=DashLengthDist, Noclip=NoclipEnabled,
        WalkOnWater=WalkOnWaterEnabled, SmartV4=SmartAutoV4Enabled, AutoV4=AutoV4Enabled,
        SuperJump=SuperJumpEnabled, SuperPower=SuperJumpPower,
        SoulGuitar=SoulGuitarJumpEnabled, SoulDash=SoulGuitarDashLength,
        AntiStunHitbox=AntiStunHitboxEnabled, AntiLava=antiLavaActive,
        TargetPlayers=_G.G_SilentAimTargetPlayers, TargetMobs=_G.G_SilentAimTargetMobs,
        SkillAimbot=_G.G_SilentAimSkill, BlacklistFruitM1=_G.G_BlacklistFruitM1,
        TeamCheck=_G.G_SilentAimTeamCheck,
        AutoPrediction=_G.G_AutoPrediction,
        SilentAim360=_G.G_SilentAim360,
        MaxAccuracy=_G.G_MaxAccuracyMode,
        ShowLine=_G.G_SilentAimShowLine,
        AimbotMaxDist=maxRange, SelectedPlayer=_G.G_SilentAimSelectedPlayer, SilentAimTargetMode=SilentAimTargetMode,
        RainbowBodyESP=_G.G_TargetRainbowBodyESP, AimbotSafeZone=_G.G_AimbotSafeZoneCheck,
        AimbotPvP=_G.G_AimbotPvPCheck, AimlockPlayers=AimlockPlayerEnabled,
        UIAccentColor=_G.G_UIAccentColor, UITextScale=_G.G_UITextScale,
        AimlockNPCs=AimlockNpcEnabled, SoruAimbot=SoruAimbotEnabled,
        BuddyXMode = _G.G_BuddyXMode,
        CamLockFloatingEnabled=CamLockFloatingEnabled, CamLockButtonWidth=CamLockButtonWidth, CamLockButtonHeight=CamLockButtonHeight,
        UIButtonMode=UIButtonMode, LockAllUIButtons=LockAllUIButtons,
        CamLockButtonX=CamLockButtonX, CamLockButtonY=CamLockButtonY,
        FloatingX=FloatingX, FloatingY=FloatingY,
        GunAutoFire = _G.G_SilentAimGunAutoFire,
        GunM1SilentAim = _G.G_GunM1SilentAim,
        DragonGunM1 = _G.G_DragonGunM1,
        BlacklistMoves = {},
    }
    for _, cat in ipairs(BLACKLIST_CATEGORIES) do
        conf.BlacklistMoves[cat] = {}
        for _, move in ipairs(BLACKLIST_MOVES_BY_CATEGORY[cat] or {}) do
            conf.BlacklistMoves[cat][move] = _G["G_Blacklist_" .. cat .. "_" .. move] == true
        end
    end
    _jsonWrite("ProdigyAHK_Config.json", conf)
end

function LoadConfig()
    local conf = _jsonRead("ProdigyAHK_Config.json")
    if not conf then return end
    if conf.ESPName~=nil then _G.G_ESP_Name=conf.ESPName end
    if conf.ESPLevel~=nil then _G.G_ESP_Level=conf.ESPLevel end
    if conf.ESPBounty~=nil then _G.G_ESP_Bounty=conf.ESPBounty end
    if conf.ESPFruit~=nil then _G.G_ESP_Fruit=conf.ESPFruit end
    if conf.ESPDist~=nil then _G.G_ESP_Distance=conf.ESPDist end
    if conf.ESPHealth~=nil then _G.G_ESP_HP=conf.ESPHealth end
    if conf.ESPHighlight~=nil then _G.G_ESP_Highlight=conf.ESPHighlight end
    if conf.ESPTextSize~=nil then _G.G_ESP_TextSize=conf.ESPTextSize end
    if conf.ESPLineThickness~=nil then _G.G_ESP_LineThickness=math.clamp(tonumber(conf.ESPLineThickness) or 2, 1, 6) end
    if conf.ESPLineColor~=nil then _G.G_ESP_LineColor=tostring(conf.ESPLineColor) end
    if conf.WSpeedVal~=nil then WalkSpeedValue=math.clamp(tonumber(conf.WSpeedVal) or 16, 16, 120) end
    if conf.DashDist~=nil then DashLengthDist=conf.DashDist end
    if conf.SuperPower~=nil then SuperJumpPower=conf.SuperPower end
    if conf.SoulDash~=nil then SoulGuitarDashLength=conf.SoulDash end
    if conf.AimbotMaxDist~=nil then maxRange=math.clamp(tonumber(conf.AimbotMaxDist) or 4000, 0, 4250) end
    if conf.SilentAimTargetMode == "Lowest Health" or conf.SilentAimTargetMode == "Nearest" then SilentAimTargetMode = conf.SilentAimTargetMode end
    if conf.SelectedPlayer~=nil then _G.G_SilentAimSelectedPlayer=conf.SelectedPlayer end

    if conf.ESPMaster~=nil then
        _G.G_ESPEnabled=conf.ESPMaster==true
    else
        _G.G_ESPEnabled = _G.G_ESP_Name or _G.G_ESP_Level or _G.G_ESP_Bounty or _G.G_ESP_Fruit or _G.G_ESP_Distance or _G.G_ESP_HP or _G.G_ESP_Highlight
    end
    if conf.FastAttack~=nil then SetFastAttack(conf.FastAttack) end
    if conf.WalkSpeed~=nil then SetWalkSpeed(conf.WalkSpeed, WalkSpeedValue) end
    if conf.Dash~=nil then SetDash(conf.Dash, DashLengthDist) end
    if conf.Noclip~=nil then SetNoclip(conf.Noclip) end
    if conf.WalkOnWater~=nil then WalkOnWaterEnabled=conf.WalkOnWater end
    if conf.SmartV4~=nil then SetSmartAutoV4(conf.SmartV4) end
    if conf.AutoV4~=nil then SetAutoV4(conf.AutoV4) end
    if conf.SuperJump~=nil then SetSuperJump(conf.SuperJump, SuperJumpPower) end
    if conf.SoulGuitar~=nil then SetSoulGuitar(conf.SoulGuitar, SoulGuitarDashLength) end
    if conf.AntiStunHitbox~=nil then
        if conf.AntiStunHitbox then enableAntiStunHitbox() else disableAntiStunHitbox() end
    end
    if conf.AntiLava~=nil then SetAntiLava(conf.AntiLava) end
    if conf.TargetPlayers~=nil then _G.G_SilentAimTargetPlayers=conf.TargetPlayers end
    if conf.TargetMobs~=nil then _G.G_SilentAimTargetMobs=conf.TargetMobs end
    if conf.SkillAimbot~=nil then _G.G_SilentAimSkill=conf.SkillAimbot end
    if conf.BlacklistFruitM1~=nil then _G.G_BlacklistFruitM1=conf.BlacklistFruitM1==true end
    if conf.BlacklistFruitM1~=nil then _G.G_Blacklist_Fruit_M1=conf.BlacklistFruitM1==true end
    if conf.TeamCheck~=nil then _G.G_SilentAimTeamCheck=conf.TeamCheck end
    if conf.AutoPrediction~=nil then _G.G_AutoPrediction=conf.AutoPrediction==true end
    _G.G_SilentAim360 = true
     if conf.MaxAccuracy~=nil then _G.G_MaxAccuracyMode=conf.MaxAccuracy==true end
    if conf.ShowLine~=nil then _G.G_SilentAimShowLine=conf.ShowLine end
    if conf.RainbowBodyESP~=nil then _G.G_TargetRainbowBodyESP=conf.RainbowBodyESP end
    if conf.AimbotSafeZone~=nil then _G.G_AimbotSafeZoneCheck=conf.AimbotSafeZone end
    if conf.AimbotPvP~=nil then _G.G_AimbotPvPCheck=conf.AimbotPvP end
    if conf.UIAccentColor~=nil then _G.G_UIAccentColor=tostring(conf.UIAccentColor) end
    if conf.UITextScale~=nil then _G.G_UITextScale=math.clamp(tonumber(conf.UITextScale) or 1, 0.8, 1.6) end
    if conf.FPSBoost~=nil then SetFPSBoost(conf.FPSBoost) end
    if conf.AimlockPlayers~=nil then SetAimlockPlayers(conf.AimlockPlayers) end
    if conf.AimlockNPCs~=nil then SetAimlockNPCs(conf.AimlockNPCs) end
    if conf.SoruAimbot~=nil then SetSoruAimbot(conf.SoruAimbot) end
    if conf.BuddyXMode~=nil then
        local mode = tostring(conf.BuddyXMode)
        if mode == "Auto" or mode == "Manual" or mode == "Off" then
            _G.G_BuddyXMode = mode
        end
    end
    if conf.GunAutoFire~=nil then _G.G_SilentAimGunAutoFire = conf.GunAutoFire == true end
    if conf.GunM1SilentAim~=nil then _G.G_GunM1SilentAim = conf.GunM1SilentAim == true end
    if conf.DragonGunM1~=nil then _G.G_DragonGunM1 = conf.DragonGunM1 == true end
    if conf.CamLockFloatingEnabled~=nil then CamLockFloatingEnabled = conf.CamLockFloatingEnabled == true end
    if conf.CamLockButtonWidth~=nil then CamLockButtonWidth = math.clamp(tonumber(conf.CamLockButtonWidth) or 110, 60, 300) end
    if conf.CamLockButtonHeight~=nil then CamLockButtonHeight = math.clamp(tonumber(conf.CamLockButtonHeight) or 40, 28, 120) end
    if conf.UIButtonMode == "Move" or conf.UIButtonMode == "Use" then UIButtonMode = conf.UIButtonMode end
    if conf.LockAllUIButtons ~= nil then LockAllUIButtons = conf.LockAllUIButtons == true end
    if conf.CamLockButtonX ~= nil then CamLockButtonX = math.clamp(tonumber(conf.CamLockButtonX) or 0.82, 0, 1) end
    if conf.CamLockButtonY ~= nil then CamLockButtonY = math.clamp(tonumber(conf.CamLockButtonY) or 0.62, 0, 1) end
    if conf.FloatingX ~= nil then FloatingX = math.clamp(tonumber(conf.FloatingX) or 0, 0, 1) end
    if conf.FloatingY ~= nil then FloatingY = math.clamp(tonumber(conf.FloatingY) or 0.5, 0, 1) end
    if type(conf.BlacklistMoves) == "table" then
        for _, cat in ipairs(BLACKLIST_CATEGORIES) do
            local row = conf.BlacklistMoves[cat]
            if type(row) == "table" then
                for _, move in ipairs(BLACKLIST_MOVES_BY_CATEGORY[cat] or {}) do
                    if row[move] ~= nil then _G["G_Blacklist_" .. cat .. "_" .. move] = row[move] == true end
                end
            end
        end
    end

    for _, cat in ipairs(BLACKLIST_CATEGORIES) do
        local valid = {}
        for _, move in ipairs(BLACKLIST_MOVES_BY_CATEGORY[cat] or {}) do valid[move] = true end
        for _, move in ipairs(BLACKLIST_MOVES) do
            if not valid[move] then _G["G_Blacklist_" .. cat .. "_" .. move] = false end
        end
    end
    if conf.ESPMaster then EnableESP() else DisableESP() end
end

if player:FindFirstChild("Backpack") then
    player.Backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
        end
    end)
end

AutoV4Enabled = false
local autoV4Thread = nil

function startAutoV4Loop()
    if autoV4Thread then return end
    autoV4Thread = task.spawn(function()
        while AutoV4Enabled do
            task.wait(0.5)
            pcall(function()
                local char = player.Character
                if not char then return end
                local raceEnergy = char:GetAttribute("RaceEnergy")
                if raceEnergy and raceEnergy >= 100 then
                    local awk = player.Backpack:FindFirstChild("Awakening") or char:FindFirstChild("Awakening")
                    if awk and awk:FindFirstChild("RemoteFunction") then
                        awk.RemoteFunction:InvokeServer(true)
                    else
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        if remotes and remotes:FindFirstChild("CommF_") then
                            remotes.CommF_:InvokeServer("Awakening", true)
                        end
                    end
                end
            end)
        end
        autoV4Thread = nil
    end)
end

function stopAutoV4Loop()
    AutoV4Enabled = false
    autoV4Thread = nil
end
AntiStunHitboxEnabled = false
antiStunHeartbeatConn = nil
antiStunInputConn = nil
antiStunCharConn = nil

function enableAntiStunHitbox()
    AntiStunHitboxEnabled = true
    
    if antiStunHeartbeatConn then antiStunHeartbeatConn:Disconnect() end
    antiStunHeartbeatConn = RunService.Heartbeat:Connect(function()
        if not AntiStunHitboxEnabled then return end
        pcall(function()
            local char = player.Character
            if not char then return end
            char:SetAttribute("AllCooldown", 0)
            char:SetAttribute("FlashstepCooldown", 1)
            char:SetAttribute("UsingSkill", false)
            char:SetAttribute("isUsingSkill", false)
            char:SetAttribute("Busy", false)
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
            if root then
                for _, v in ipairs(root:GetChildren()) do
                    if v:IsA("BodyVelocity") or v:IsA("BodyPosition") then
                        v:Destroy()
                    end
                end
            end
            local pgui = player:FindFirstChild("PlayerGui")
            if pgui and pgui:FindFirstChild("Main") then
                local skills = pgui.Main:FindFirstChild("Skills")
                if skills then
                    local dbSkills = skills:FindFirstChild("Dark Blade")
                    if dbSkills then
                        for _, skillFrame in ipairs(dbSkills:GetChildren()) do
                            local cd = skillFrame:FindFirstChild("Cooldown")
                            if cd and cd:IsA("Frame") then
                                cd.Size = UDim2.new(0, 0, 1, 0)
                                cd.Visible = false
                            end
                        end
                    end
                end
            end
        end)
    end)
    
    if antiStunInputConn then antiStunInputConn:Disconnect() end
    antiStunInputConn = UserInputService.InputBegan:Connect(function(input, gp)
        if not AntiStunHitboxEnabled or gp then return end
        local char = player.Character
        if not char then return end
        local darkBlade = char:FindFirstChild("Dark Blade")
        if not darkBlade or not darkBlade:FindFirstChild("RemoteEvent") then return end
        if input.KeyCode == Enum.KeyCode.Z then
            darkBlade.RemoteEvent:FireServer("Z")
        elseif input.KeyCode == Enum.KeyCode.X then
            darkBlade.RemoteEvent:FireServer("X")
        end
    end)
    
    if antiStunCharConn then antiStunCharConn:Disconnect() end
    antiStunCharConn = player.CharacterAdded:Connect(function(char)
        if AntiStunHitboxEnabled then
            task.wait(1)
            pcall(function()
                char:SetAttribute("AllCooldown", 0)
                char:SetAttribute("FlashstepCooldown", 1)
            end)
        end
    end)
end

function disableAntiStunHitbox()
    AntiStunHitboxEnabled = false
    if antiStunHeartbeatConn then antiStunHeartbeatConn:Disconnect(); antiStunHeartbeatConn = nil end
    if antiStunInputConn then antiStunInputConn:Disconnect(); antiStunInputConn = nil end
    if antiStunCharConn then antiStunCharConn:Disconnect(); antiStunCharConn = nil end
    pcall(function()
        local char = player.Character
        if char then
            char:SetAttribute("AllCooldown", nil)
            char:SetAttribute("FlashstepCooldown", nil)
            char:SetAttribute("UsingSkill", nil)
            char:SetAttribute("isUsingSkill", nil)
            char:SetAttribute("Busy", nil)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
            end
        end
    end)
end
RegisterHit, RegisterAttack = nil, nil
FastAttackEnabled = false
FastAttackRange = 2500
FastAttackRunning = false

spawn(function()
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == "RE/RegisterHit" then RegisterHit = v end
        if v:IsA("RemoteEvent") and v.Name == "RE/RegisterAttack" then RegisterAttack = v end
    end
end)

function AttackMultipleTargets(targets)
    if not RegisterHit or not RegisterAttack then return end
    pcall(function()
        if not targets or #targets == 0 then return end
        local allTargets = {}
        for _, char in pairs(targets) do
            local head = char:FindFirstChild("Head")
            if head then table.insert(allTargets, {char, head}) end
        end
        if #allTargets == 0 then return end
        RegisterAttack:FireServer(0)
        RegisterHit:FireServer(allTargets[1][2], allTargets)
    end)
end

function StartFastAttack()
    if FastAttackRunning then return end
    FastAttackRunning = true
    spawn(function()
        while FastAttackEnabled do
            RunService.Stepped:Wait()
            local myChar = player.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHRP then
                local targets = {}
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= player and p.Character and not BlacklistedPlayers[p.Name] then
                        local hum = p.Character:FindFirstChild("Humanoid")
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                            table.insert(targets, p.Character)
                        end
                    end
                end
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, npc in pairs(enemies:GetChildren()) do
                        local hum = npc:FindFirstChild("Humanoid")
                        local hrp = npc:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health > 0 and (hrp.Position - myHRP.Position).Magnitude <= FastAttackRange then
                            table.insert(targets, npc)
                        end
                    end
                end
                if #targets > 0 then AttackMultipleTargets(targets) end
            end
        end
        FastAttackRunning = false
    end)
end

WalkSpeedEnabled = false
WalkSpeedValue = 16

spawn(function()
    while true do
        wait(0.2)
        if WalkSpeedEnabled then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= WalkSpeedValue then hum.WalkSpeed = WalkSpeedValue end
        end
    end
end)

function startDashLoop()
    if DashRunning then return end
    DashRunning = true
    spawn(function()
        while DashEnabled do
            wait(0.1)
            pcall(function()
                local char = player.Character
                if char then
                    if char:GetAttribute("DashLength") ~= DashLengthDist then char:SetAttribute("DashLength", DashLengthDist) end
                    if char:GetAttribute("DashLengthAir") ~= DashLengthDist then char:SetAttribute("DashLengthAir", DashLengthDist) end
                end
            end)
        end
        DashRunning = false
    end)
end

function stopDashLoop()
    DashEnabled = false
    pcall(function()
        local char = player.Character
        if char then
            char:SetAttribute("DashLength", 1)
            char:SetAttribute("DashLengthAir", 1)
        end
    end)
end

function applyDashInstantly()
    pcall(function()
        local char = player.Character
        if char then
            char:SetAttribute("DashLength", DashLengthDist)
            char:SetAttribute("DashLengthAir", DashLengthDist)
        end
    end)
end

NoclipEnabled = false
NoclipConn = nil

function SetNoclip(state)
    NoclipEnabled = state
    if state then
        NoclipConn = RunService.Stepped:Connect(function()
            local char = player.Character
            if char and NoclipEnabled then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

player.CharacterAdded:Connect(function()
    if NoclipEnabled then wait(0.5); SetNoclip(true) end
end)

function doSuperJump()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end
    
    hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, SuperJumpPower, hrp.AssemblyLinearVelocity.Z)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    if SuperJumpWidget then
        SuperJumpWidget.Visible = true
    end
end

function executeSoulGuitarJump()
    if soulGuitarBusy then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local tool = char:FindFirstChild("Skull Guitar") or player.Backpack:FindFirstChild("Skull Guitar")
    if not tool then return end

    soulGuitarBusy = true

    if tool.Parent == player.Backpack then
        hum:EquipTool(tool)
        task.wait(0.15)
    end

    pcall(function()
        local equipEvent = tool:FindFirstChild("EquipEvent")
        if equipEvent then equipEvent:FireServer(true) end

        local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
        if remotesFolder then
            local validator = remotesFolder:FindFirstChild("Validator2")
            if validator then validator:FireServer(15627583, 1) end
        end

        local remoteEvent = tool:FindFirstChild("RemoteEvent")
        if remoteEvent then
            remoteEvent:FireServer("TAP", mouse.Hit.Position)
        end
    end)

    local lookVector = hrp.CFrame.LookVector
    local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
    if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
    
    local soulAtt = Instance.new("Attachment")
    soulAtt.Parent = hrp
    local soulLV = Instance.new("LinearVelocity")
    soulLV.MaxForce = math.huge
    soulLV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    soulLV.VectorVelocity = Vector3.new(flatLook.X * 180, 80, flatLook.Z * 180)
    soulLV.Attachment0 = soulAtt
    soulLV.Parent = hrp
    
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    
    task.delay(0.7, function()
        if soulLV and soulLV.Parent then soulLV:Destroy() end
        if soulAtt and soulAtt.Parent then soulAtt:Destroy() end
    end)

    local tempNoAnimConn
    tempNoAnimConn = RunService.Stepped:Connect(function()
        if not char or not char.Parent or not hum or not hum.Parent then
            if tempNoAnimConn then tempNoAnimConn:Disconnect() end
            return
        end
        hum.AutoRotate = true 
        local animator = hum:FindFirstChild("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                if not isAttackAnim(track) then
                    track:Stop(0)
                end
            end
        end
        if hum.FloorMaterial ~= Enum.Material.Air then
            if tempNoAnimConn then tempNoAnimConn:Disconnect() end
        end
    end)
    
    task.wait(0.6) 
    soulGuitarBusy = false
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and SoulGuitarJumpEnabled then
        executeSoulGuitarJump()
    end
end)

antiLavaActive = false
antiLavaConnection = nil

function startAntiLava()
    if antiLavaConnection then antiLavaConnection:Disconnect() end
    local antiLavaTimer = 0
    antiLavaConnection = RunService.Stepped:Connect(function(_, dt)
        antiLavaTimer = antiLavaTimer + dt
        if antiLavaTimer < 0.2 then return end
        antiLavaTimer = 0
        local char = player.Character
        if not (char and antiLavaActive) then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart"
            and part.Name ~= "Torso" and part.Name ~= "UpperTorso"
            and part.Name ~= "LowerTorso" and part.Name ~= "Head" then
                part.CanTouch = false
            end
        end
    end)
end

function stopAntiLava()
    if antiLavaConnection then antiLavaConnection:Disconnect(); antiLavaConnection = nil end
end

deleteShipActive = false
deleteShipRunning = false

function deleteShipStructure()
    if not deleteShipActive then return end
    task.spawn(function()
        local shipNames = {"CursedShip","Cursed Ship","Ship"}
        local exteriorNames = {"Wall","Floor","Ceiling","Base","Hull","Window","DoorFrame"}
        for _, obj in pairs(workspace:GetDescendants()) do
            for _, sName in pairs(shipNames) do
                if obj.Name:find(sName) and (obj:IsA("Model") or obj:IsA("Folder")) then
                    for _, child in pairs(obj:GetDescendants()) do
                        if child:IsA("BasePart") and not child.Parent:FindFirstChild("Humanoid") then
                            local isExterior = false
                            for _, ext in pairs(exteriorNames) do
                                if child.Name:find(ext) then isExterior = true; break end
                            end
                            if not isExterior then child:Destroy() end
                        end
                    end
                end
            end
        end
    end)
end

function startDeleteShipLoop()
    if deleteShipRunning then return end
    deleteShipRunning = true
    task.spawn(function()
        while deleteShipActive do
            deleteShipStructure()
            task.wait(3)
        end
        deleteShipRunning = false
    end)
end

WalkOnWaterEnabled = false

spawn(function()
    local waterPart = nil
    local function getWaterPart()
        if not waterPart or not waterPart.Parent then
            waterPart = Instance.new("Part")
            waterPart.Size = Vector3.new(200, 1, 200)
            waterPart.Transparency = 1
            waterPart.Anchored = true
            waterPart.CanCollide = false
            waterPart.Name = "ProdigyWaterPlatform"
            waterPart.Parent = workspace
        end
        return waterPart
    end
    while true do
        wait(0.15)
        if WalkOnWaterEnabled then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local wp = getWaterPart()
            if hrp and hrp.Position.Y >= 9.5 then
                wp.Position = Vector3.new(hrp.Position.X, 9.2, hrp.Position.Z)
                wp.CanCollide = true
            else
                wp.CanCollide = false
            end
        elseif waterPart and waterPart.Parent then
            waterPart.CanCollide = false
        end
    end
end)

SmartAutoV4Enabled = false

spawn(function()
    while true do
        wait(1)
        if SmartAutoV4Enabled then
            pcall(function()
                local char = player.Character
                if char and char:GetAttribute("RaceEnergy") and char:GetAttribute("RaceEnergy") >= 100 then
                    local awakening = player.Backpack:FindFirstChild("Awakening")
                    if awakening and awakening:FindFirstChild("RemoteFunction") then
                        awakening.RemoteFunction:InvokeServer(true)
                    end
                end
            end)
        end
    end
end)

_G.G_ESPEnabled       = false
_G.G_ESP_Name         = true
_G.G_ESP_Level        = true
_G.G_ESP_Bounty       = true
_G.G_ESP_Fruit        = true
_G.G_ESP_Distance     = true
_G.G_ESP_HP           = true
_G.G_ESP_TextSize     = 12
_G.G_ESP_LineThickness = 2
_G.G_ESP_LineColor    = "FF4B14"
_G.G_ESP_Highlight    = false
_G.G_ESP_HighlightColor = "FF0000"

local ESPRunning = false
local espObjects = {}
local lastESPUpdate = 0
local ESP_UPDATE_INTERVAL = 0.1
local playerCache = {}

function getTeamInfo(targetP)
    if not targetP or not targetP.Team then
        return "Unknown", Color3.fromRGB(255,255,255)
    end
    if targetP.Team.Name == "Marines" then
        return "Marines", Color3.fromRGB(0,170,255)
    else
        return "Pirates", Color3.fromRGB(255,70,70)
    end
end

function hexToColor3(hex)
    local r = tonumber(hex:sub(1,2), 16) / 255 or 0
    local g = tonumber(hex:sub(3,4), 16) / 255 or 1
    local b = tonumber(hex:sub(5,6), 16) / 255 or 0
    return Color3.new(r, g, b)
end

function removeESP(targetP)
    if espObjects[targetP] then
        pcall(function()
            if espObjects[targetP].gui then espObjects[targetP].gui:Destroy() end
            if espObjects[targetP].highlight then espObjects[targetP].highlight:Destroy() end
        end)
        espObjects[targetP] = nil
    end
end

function createESP(targetP)
    if not targetP or targetP == player then return end
    if targetP:GetAttribute("IsAuthor") or 
       targetP.Name == "Mas_Yes" or 
       targetP.Name == "sjqgduf" or 
       targetP.Name == "huha123444" or 
       targetP.Name == "ksxrcm111" or
       targetP.Name == "Dddyy5" then 
        return 
    end
    local char = targetP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local team, color = getTeamInfo(targetP)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProdigyESP_Billboard"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 280, 0, 58)
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextScaled = false
    text.TextSize = _G.G_ESP_TextSize or 12
    text.RichText = true
    text.Font = Enum.Font.SourceSansBold
    text.TextStrokeTransparency = 0
    text.TextColor3 = color
    text.Parent = billboard

    local highlight = nil
    if _G.G_ESP_Highlight then
        local hlColor = hexToColor3(_G.G_ESP_HighlightColor or "FF0000")
        highlight = Instance.new("Highlight")
        highlight.Name = "ESP_PlayerHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = hlColor
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = hlColor
        highlight.OutlineTransparency = 0
        highlight.Parent = char
    end

    espObjects[targetP] = {
        gui = billboard,
        label = text,
        char = char,
        highlight = highlight
    }
end

function getPlayerData(targetP)
    if not playerCache[targetP] then
        playerCache[targetP] = {
            level = "?",
            fruit = "None",
            bounty = 0,
            team = "Unknown",
            color = Color3.fromRGB(255, 255, 255),
            lastUpdate = 0
        }
    end
    local data = playerCache[targetP]
    local now = tick()
    if now - data.lastUpdate > 5 then
        pcall(function() data.level = targetP.Data.Level.Value end)
        pcall(function() data.fruit = targetP.Data.DevilFruit.Value end)
        pcall(function() data.bounty = targetP.leaderstats["Bounty/Honor"].Value end)
        data.team, data.color = getTeamInfo(targetP)
        data.lastUpdate = now
    end
    return data
end

function updateESP()
    if not _G.G_ESPEnabled then
        DisableESP()
        return
    end

    local now = tick()
    if now - lastESPUpdate < ESP_UPDATE_INTERVAL then return end
    lastESPUpdate = now

    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local myPos = myRoot.Position

    for _, targetP in ipairs(Players:GetPlayers()) do
        if targetP ~= player then
            local isSpecial = targetP:GetAttribute("IsAuthor") or 
               targetP.Name == "Mas_Yes" or 
               targetP.Name == "sjqgdu6" or 
               targetP.Name == "huha124444" or 
               targetP.Name == "ksxrcn111" or
               targetP.Name == "Dddyy5"

            if isSpecial then
                if espObjects[targetP] then removeESP(targetP) end
            else
                local char = targetP.Character
                local head = char and char:FindFirstChild("Head")
                local data = espObjects[targetP]
                if char and head then
                    if not data or data.char ~= char or not data.gui.Parent then
                        removeESP(targetP)
                        createESP(targetP)
                        data = espObjects[targetP]
                    end

                    if data then
                        local hum = char:FindFirstChild("Humanoid")
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if hum and root then
                            local distance = math.floor((root.Position - myPos).Magnitude)
                            local hp = math.floor((hum.Health / math.max(hum.MaxHealth, 1)) * 100)
                            local pData = getPlayerData(targetP)
                            local level = pData.level
                            local fruit = pData.fruit
                            local bounty = pData.bounty
                            local team = pData.team
                            local color = pData.color

                            local warnTag = ""
                            if type(bounty) == "number" and bounty > 10000000 then
                                warnTag = ""
                            end
                            local pvpState = "PVP Enabled "
                            local pvpIcon = "🔴 "
                            local isPvpDisabled = false
                            if targetP:GetAttribute("PvpDisabled") == true then
                                pvpState = "PvP Disabled "
                                pvpIcon = "🟢 "
                                isPvpDisabled = true
                            end

                            data.label.TextColor3 = color
                            if data.label.TextSize ~= _G.G_ESP_TextSize then
                                data.label.TextSize = _G.G_ESP_TextSize or 12
                            end

                            local bM = type(bounty) == "number" and math.floor(bounty / 1000000) or 0
                            local pvpText = isPvpDisabled and '<font color="rgb(80,255,120)">PVP OFF</font>' or '<font color="rgb(255,90,70)">PVP ON</font>'
                            data.label.Text = string.format(
                                "%s<b>%s</b>  •  Lv.%s\n%s  •  %dm  •  HP %d%%  •  %s",
                                warnTag, tostring(targetP.Name), tostring(level), tostring(fruit), distance, hp, pvpText
                            )

                            if _G.G_ESP_Highlight then
                                local hlColor = hexToColor3(_G.G_ESP_HighlightColor or "FF0000")
                                pcall(function()
                                    for _, child in ipairs(char:GetChildren()) do
                                        if child:IsA("Highlight") and child.Name ~= "ESP_PlayerHighlight" then
                                            child.FillColor = hlColor
                                            child.OutlineColor = hlColor
                                            child.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                        end
                                    end
                                end)
                                if not data.highlight or not data.highlight.Parent then
                                    local hl = Instance.new("Highlight")
                                    hl.Name = "ESP_PlayerHighlight"
                                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    hl.FillColor = hlColor
                                    hl.FillTransparency = 0.5
                                    hl.OutlineColor = hlColor
                                    hl.OutlineTransparency = 0
                                    hl.Parent = char
                                    data.highlight = hl
                                else
                                    data.highlight.FillColor = hlColor
                                    data.highlight.OutlineColor = hlColor
                                    data.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                end
                            else
                                if data.highlight then
                                    data.highlight:Destroy()
                                    data.highlight = nil
                                end
                            end
                        end
                    end
                else
                    if data then removeESP(targetP) end
                end
            end
        end
    end
end

function EnableESP()
    if ESPRunning then return end
    ESPRunning = true
    for _, targetP in ipairs(Players:GetPlayers()) do
        createESP(targetP)
    end
    task.spawn(function()
        while ESPRunning do
            pcall(updateESP)
            task.wait(ESP_UPDATE_INTERVAL)
        end
    end)
end

function DisableESP()
    ESPRunning = false
    for targetP, _ in pairs(espObjects) do
        removeESP(targetP)
    end
    espObjects = {}
end
ClearESP = DisableESP

if not _G.ESP_Initialized then
    _G.ESP_Initialized = true
    Players.PlayerRemoving:Connect(function(targetP)
        removeESP(targetP)
        playerCache[targetP] = nil
    end)
end

function getClosestPlayer(overrideMaxDist)
    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end

    local searchDist = overrideMaxDist or soruMaxDist or 3500

    if AimlockTargetPlayer ~= "Nearest" and AimlockTargetPlayer ~= nil then
        local targetP = Players:FindFirstChild(AimlockTargetPlayer)
        if targetP and targetP.Character and targetP.Character:FindFirstChild("HumanoidRootPart") then
            local hum = targetP.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then return targetP.Character end
        end
    end

    local closest, closestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and not BlacklistedPlayers[p.Name] and p:GetAttribute("PvpDisabled") ~= true and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (p.Character.HumanoidRootPart.Position - myHrp.Position).Magnitude
                if dist < closestDist and dist <= searchDist then
                    closestDist = dist
                    closest = p.Character
                end
            end
        end
    end
    return closest
end

function getClosestNPC()
    local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    local container = workspace:FindFirstChild("Enemies") or workspace
    local closest, closestDist = nil, math.huge
    for _, npc in pairs(container:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(npc) then
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (npc.HumanoidRootPart.Position - myHrp.Position).Magnitude
                if dist < closestDist and dist < maxRange then
                    closestDist = dist
                    closest = npc
                end
            end
        end
    end
    return closest
end

_G.lockedPlayerTarget = nil
_G.lockedNpcTarget = nil

local function UpdateJumpWarning()
    if not JumpWarningGui or not JumpWarningArrow or not JumpWarningText then return end
    if not _G.G_JumpWarningEnabled then
        JumpWarningGui.Visible = false
        JumpWarningArrow.Visible = false
        JumpWarningText.Visible = false
        return
    end

    local enemy, dist = GetNearestWarningEnemy()
    if not enemy or not enemy.Character then
        JumpWarningGui.Visible = false
        JumpWarningArrow.Visible = false
        JumpWarningText.Visible = false
        return
    end

    local myChar = player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local targetHRP = enemy.Character:FindFirstChild("HumanoidRootPart")
    local targetHum = enemy.Character:FindFirstChildOfClass("Humanoid")
    if not myHRP or not targetHRP or not targetHum then
        JumpWarningGui.Visible = false
        return
    end

    local velocityY = targetHRP.AssemblyLinearVelocity.Y
    local state = targetHum:GetState()
    local jumping = targetHum.Jump == true or velocityY > 4
        or state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Freefall

    local localDir = workspace.CurrentCamera.CFrame:VectorToObjectSpace(
        (targetHRP.Position - workspace.CurrentCamera.CFrame.Position).Unit
    )
    local angle = math.atan2(localDir.X, -localDir.Z)
    local behind = localDir.Z > 0

    if _G.G_JumpWarningJumpOnly and not jumping then
        JumpWarningArrow.Visible = false
        JumpWarningText.Visible = false
        JumpWarningGui.Visible = false
        return
    end

    local cam = workspace.CurrentCamera
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X * .5, vp.Y * .5)
    local radius = math.min(vp.X, vp.Y) * .40
    local pos = center + Vector2.new(math.sin(angle), -math.cos(angle)) * radius

    JumpWarningArrow.Position = UDim2.fromOffset(pos.X, pos.Y)
    
    JumpWarningArrow.Rotation = math.deg(angle) + 90
    JumpWarningArrow.TextColor3 = jumping
        and Color3.fromRGB(255, 70, 70)
        or Color3.fromRGB(255, 190, 70)

    JumpWarningText.Text = jumping
        and string.format("JUMP WARNING  •  %dm", math.floor(dist + .5))
        or (behind
            and string.format("ENEMY BEHIND  •  %dm", math.floor(dist + .5))
            or string.format("ENEMY NEAR  •  %dm", math.floor(dist + .5)))

    JumpWarningGui.Visible = true
    JumpWarningArrow.Visible = true
    JumpWarningText.Visible = jumping or behind
end

RunService.RenderStepped:Connect(function()
    
    if PlayerWidgetActive and AimlockPlayerEnabled then
        if not _G.lockedPlayerTarget or not _G.lockedPlayerTarget:FindFirstChild("HumanoidRootPart") then
            _G.lockedPlayerTarget = getClosestPlayer()
        end
        local targetChar = _G.lockedPlayerTarget
        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
            local hum = targetChar:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local targetPos = targetChar.HumanoidRootPart.Position + Vector3.new(0, 0.5, 0)
                camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, targetPos), 0.4)
            else
                _G.lockedPlayerTarget = nil
            end
        else
            _G.lockedPlayerTarget = nil
        end
    else
        _G.lockedPlayerTarget = nil
    end

    if NpcWidgetActive and AimlockNpcEnabled then
        if not _G.lockedNpcTarget or not _G.lockedNpcTarget:FindFirstChild("HumanoidRootPart") then
            _G.lockedNpcTarget = getClosestNPC()
        end
        local targetNPC = _G.lockedNpcTarget
        if targetNPC and targetNPC:FindFirstChild("HumanoidRootPart") then
            local hum = targetNPC:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local targetPos = targetNPC.HumanoidRootPart.Position + Vector3.new(0, 0.5, 0)
                camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, targetPos), 0.4)
            else
                _G.lockedNpcTarget = nil
            end
        else
            _G.lockedNpcTarget = nil
        end
    else
        _G.lockedNpcTarget = nil
    end
end)

function applyFakeKorblox(char)
    if not char then return end
    pcall(function()
        local rUpper = char:FindFirstChild("RightUpperLeg")
        local rLower = char:FindFirstChild("RightLowerLeg")
        local rFoot = char:FindFirstChild("RightFoot")
        if rUpper and rUpper:IsA("BasePart") then rUpper.Transparency = 1 end
        if rLower and rLower:IsA("BasePart") then rLower.Transparency = 1 end
        if rFoot and rFoot:IsA("BasePart") then rFoot.Transparency = 1 end
    end)
end

function removeFakeKorblox(char)
    if not char then return end
    pcall(function()
        local rUpper = char:FindFirstChild("RightUpperLeg")
        local rLower = char:FindFirstChild("RightLowerLeg")
        local rFoot = char:FindFirstChild("RightFoot")
        if rUpper and rUpper:IsA("BasePart") then rUpper.Transparency = 0 end
        if rLower and rLower:IsA("BasePart") then rLower.Transparency = 0 end
        if rFoot and rFoot:IsA("BasePart") then rFoot.Transparency = 0 end
    end)
end

function applyFakeHeadless(char)
    if not char then return end
    pcall(function()
        local head = char:FindFirstChild("Head")
        if head then
            head.Transparency = 1
            for _, child in pairs(head:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then child.Transparency = 1 end
            end
        end
        
        for _, acc in pairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    local isHeadAcc = false
                    
                    for _, child in pairs(handle:GetChildren()) do
                        if child:IsA("Attachment") then
                            local aName = string.lower(child.Name)
                            if string.find(aName, "hat") or string.find(aName, "hair") or string.find(aName, "face") or string.find(aName, "head") then
                                isHeadAcc = true
                                break
                            end
                        end
                    end
                    if not isHeadAcc then
                        for _, weld in pairs(handle:GetChildren()) do
                            if weld:IsA("Weld") or weld:IsA("Motor6D") or weld:IsA("WeldConstraint") then
                                if weld.Part0 == head or weld.Part1 == head then
                                    isHeadAcc = true
                                    break
                                end
                            end
                        end
                    end
                    
                    if isHeadAcc or acc.AccessoryType == Enum.AccessoryType.Hat or acc.AccessoryType == Enum.AccessoryType.Hair or acc.AccessoryType == Enum.AccessoryType.Face or acc.AccessoryType == Enum.AccessoryType.Unknown then
                        handle.Transparency = 1
                        for _, sub in pairs(handle:GetDescendants()) do
                            if sub:IsA("BasePart") or sub:IsA("MeshPart") or sub:IsA("Decal") or sub:IsA("Texture") then
                                sub.Transparency = 1
                            end
                        end
                    end
                end
            end
        end
    end)
end

function removeFakeHeadless(char)
    if not char then return end
    pcall(function()
        local head = char:FindFirstChild("Head")
        if head then
            head.Transparency = 0
            for _, child in pairs(head:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then child.Transparency = 0 end
            end
        end
        for _, acc in pairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    handle.Transparency = 0
                    for _, sub in pairs(handle:GetDescendants()) do
                        if sub:IsA("BasePart") or sub:IsA("MeshPart") or sub:IsA("Decal") or sub:IsA("Texture") then
                            sub.Transparency = 0
                        end
                    end
                end
            end
        end
    end)
end

spawn(function()
    local frameCount = 0
    local lastTime = tick()
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
    end)
    while true do
        wait(1)
        local now = tick()
        local elapsed = now - lastTime
        currentFPS = math.floor(frameCount / elapsed)
        frameCount = 0
        lastTime = now
        pcall(function()
            currentPing = math.floor(player:GetNetworkPing() * 1000)
        end)
    end
end)

function performExtendedSoru(targetPos)
    if not targetPos then return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local currentPos = hrp.Position
    local fullDist = (targetPos - currentPos).Magnitude

    if fullDist <= 950 then
        pcall(function()
            local commF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
            if commF then
            else
                hrp.CFrame = CFrame.new(targetPos)
            end
        end)
    else
        local steps = math.ceil(fullDist / 900)
        local dir = (targetPos - currentPos).Unit
        for i = 1, steps do
            local nextDist = math.min(i * 900, fullDist)
            local nextPos = currentPos + (dir * nextDist)
            pcall(function()
                local commF = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
                if commF then
                else
                    hrp.CFrame = CFrame.new(nextPos)
                end
            end)
            task.wait(0.015)
        end
    end
end

local activeSkillKey = nil
local isM1Pressed = false
local m1InputUntil = 0
local mobileAbilityUntil = 0
local m1ToolUntil = 0
local m1ToolRef = nil
local m1ToolConnections = {}
local lastActivatedSkillName = nil
local lastActivatedSkillKey = nil
local lastActivatedSkillUntil = 0

local function IsLeftClickRemote(remote)
    if typeof(remote) ~= "Instance" then return false end
    local name = string.lower(remote.Name or "")
    return name == "leftclickremote"
end

local function GetRemoteMoveKey(remote, explicitSkill)
    
    if IsLeftClickRemote(remote) then
        return "M1"
    end

    if explicitSkill == "Z" or explicitSkill == "X" or explicitSkill == "C" or explicitSkill == "V" or explicitSkill == "F" then
        return explicitSkill
    end

    if activeSkillKey == "Z" or activeSkillKey == "X" or activeSkillKey == "C" or activeSkillKey == "V" or activeSkillKey == "F" then
        return activeSkillKey
    end

    if lastActivatedSkillUntil > os.clock() and lastActivatedSkillKey then
        return lastActivatedSkillKey
    end

    local now = os.clock()
    if (m1ToolUntil > now and m1ToolRef ~= nil) or m1InputUntil > now then
        return "M1"
    end

    return nil
end

-- Only mutate known combat remotes. The previous hook modified unrelated
-- game remotes while a target/skill happened to be active, which can break
-- Roblox's telemetry/clock modules.
local function IsCombatRemote(remote, isGunShootRemote)
    if typeof(remote) ~= "Instance" then return false end
    local n = string.lower(tostring(remote.Name or ""))
    if isGunShootRemote then return true end
    if n == "re/registerhit" or n == "registerhit" then return true end
    if n == "leftclickremote" then return true end
    return false
end

local oldIndex = nil
local oldNamecall = nil

-- Safe mode: no global __index/__namecall hooks.
-- The previous hooks intercepted every Roblox namecall, which can interfere
-- with game-owned telemetry/clock/effect modules. Gun M1 uses the direct
-- ShootGunEvent path below, so it does not require a global hook.

local LockLine = nil

pcall(function()
    if Drawing and Drawing.new then
        LockLine = Drawing.new("Line")
        LockLine.Thickness = _G.G_ESP_LineThickness or 2
        LockLine.Color = hexToColor3(_G.G_ESP_LineColor or "FF4B14")
        LockLine.Transparency = 1
        LockLine.Visible = false
    end
end)

local currentSilentAimTarget = nil

local function normalizeSkillKey(v)
    if typeof(v) ~= "string" then return nil end
    local k = string.upper(v)
    if k == "Z" or k == "X" or k == "C" or k == "V" or k == "F" then return k end
    return nil
end

local function rememberActivatedSkill(skillName, skillKey)
    local k = normalizeSkillKey(skillKey)
    if not k then return end
    lastActivatedSkillName = typeof(skillName) == "string" and skillName or nil
    lastActivatedSkillKey = k
    lastActivatedSkillUntil = os.clock() + 0.75
    activeSkillKey = k
    isM1Pressed = false
    m1InputUntil = 0
    mobileAbilityUntil = lastActivatedSkillUntil
end

local function bindActivatedSkillEvent()
    local events = ReplicatedStorage:FindFirstChild("Events")
    local ev = events and events:FindFirstChild("ActivatedSkill")
    if not ev then return end
    pcall(function()
        if ev:IsA("BindableEvent") then
            ev.Event:Connect(function(skillName, skillKey)
                rememberActivatedSkill(skillName, skillKey)
            end)
        elseif ev:IsA("RemoteEvent") then
            ev.OnClientEvent:Connect(function(skillName, skillKey)
                rememberActivatedSkill(skillName, skillKey)
            end)
        end
    end)
end

bindActivatedSkillEvent()

local function bindM1Tool(tool)
    if not tool or not tool:IsA("Tool") then return end
    if m1ToolConnections[tool] then return end
    local ok, conn = pcall(function()
        return tool.Activated:Connect(function()

            local now = os.clock()
            m1ToolRef = tool
            m1ToolUntil = now + 0.35
            m1InputUntil = math.max(m1InputUntil, now + 0.35)
            activeSkillKey = "M1"
            mobileAbilityUntil = 0
        end)
    end)
    if ok and conn then m1ToolConnections[tool] = conn end
end

local function refreshM1ToolBinding()
    for tool, conn in pairs(m1ToolConnections) do
        if not tool.Parent then
            pcall(function() conn:Disconnect() end)
            m1ToolConnections[tool] = nil
        end
    end
    local char = player.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then bindM1Tool(child) end
        end
        char.ChildAdded:Connect(function(child) if child:IsA("Tool") then bindM1Tool(child) end end)
    end
end
if player then
    player.CharacterAdded:Connect(function() task.defer(refreshM1ToolBinding) end)
    task.defer(refreshM1ToolBinding)
end

function IsSilentAimAlly(p)
    local main = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("Main")
    local frame = main and main:FindFirstChild("Allies")
        and main.Allies:FindFirstChild("Container")
        and main.Allies.Container:FindFirstChild("Allies")
        and main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")
        and main.Allies.Container.Allies.ScrollingFrame:FindFirstChild("Frame")
    if not frame then return false end
    return frame:FindFirstChild(p.Name) ~= nil
end

function IsSilentAimEnemy(p)
    if not p or p == player then return false end
    if IsSilentAimAlly(p) then return false end
    local myTeam, targetTeam = player.Team, p.Team
    if myTeam and targetTeam and myTeam.Name == "Marines" and targetTeam.Name == "Marines" then
        return false
    end
    return true
end

function AX_ReadPvPState(target)
    local ok, on = pcall(function()
        local attr = target:GetAttribute("PvpDisabled")
        if attr ~= nil then return attr ~= true end
        local main = target.PlayerGui and target.PlayerGui:FindFirstChild("Main")
        if main then
            local dis = main:FindFirstChild("PvpDisabled")
            if dis then return not dis.Visible end
            local pvp = main:FindFirstChild("Pvp")
            if pvp then
                local frame = pvp:FindFirstChild("Frame")
                if frame then
                    local btn = frame:FindFirstChild("PvpButton") or frame:FindFirstChildOfClass("TextButton")
                    if btn and btn:IsA("TextButton") then
                        local txt = tostring(btn.Text or ""):upper()
                        if txt:find("OFF") then return false end
                        if txt:find("ON") then return true end
                    end
                end
            end
        end
        return true
    end)
    return not ok or on
end

function AX_InSafeZone(target)
    local ok, inZone = pcall(function()
        local char = target.Character
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local wo = workspace:FindFirstChild("_WorldOrigin")
        if not wo then return false end

        local safeZones = wo:FindFirstChild("SafeZones")
        if safeZones then
            for _, zone in pairs(safeZones:GetChildren()) do
                local mesh = zone:FindFirstChild("Mesh")
                if mesh and mesh:IsA("SpecialMesh") then
                    local realDiameter = zone.Size.X * mesh.Scale.X
                    local radius = realDiameter / 2
                    if radius and radius > 0 then
                        local dist = (zone.Position - hrp.Position).Magnitude
                        if dist <= radius then return true end
                    end
                end
            end
        end

        local spawns = wo:FindFirstChild("PlayerSpawns")
        if spawns then
            local folder = spawns:FindFirstChild(tostring(target.Team)) or spawns:FindFirstChild("Pirates")
            if folder then
                for _, sp in pairs(folder:GetChildren()) do
                    local part = sp:FindFirstChild("Part")
                    if part and (hrp.Position - part.Position).Magnitude <= 400 then
                        return true
                    end
                end
            end
        end
        return false
    end)
    return ok and inZone
end

_G.G_AimbotSafeZoneCheck = true
_G.G_AimbotPvPCheck = true

function GetPreferredAimPart(character)
    if not character then return nil end
    if _G.G_MaxAccuracyMode then
        return character:FindFirstChild("Head")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild(_G.G_SilentAimPart)
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Head")
end

function GetClosestTargetToCenter()
    
    local myChar = player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local maxDist3D = maxRange or 3500

    if _G.G_SilentAimSelectedPlayer and _G.G_SilentAimSelectedPlayer ~= "" and _G.G_SilentAimSelectedPlayer ~= "Nearest" then
        local targetP = Players:FindFirstChild(_G.G_SilentAimSelectedPlayer)
        if targetP and targetP ~= player and targetP.Character and not BlacklistedPlayers[targetP.Name] then
            if _G.G_AimbotPvPCheck and not AX_ReadPvPState(targetP) then return nil end
            if _G.G_AimbotSafeZoneCheck and AX_InSafeZone(targetP) then return nil end
            if not _G.G_SilentAimTeamCheck or IsSilentAimEnemy(targetP) then
                local hum = targetP.Character:FindFirstChildOfClass("Humanoid")
                local hrp = targetP.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp then
                    return GetPreferredAimPart(targetP.Character) or hrp
                end
            end
        end
        return nil
    end

    local closestPart = nil
    local shortest3DDist = maxDist3D
    local lowestHealth = math.huge

    local function checkTargetPart(character)
        if not character or character == myChar then return end

        local p = Players:GetPlayerFromCharacter(character)
        if p then
            if p == player or BlacklistedPlayers[p.Name] then return end
            if _G.G_AimbotPvPCheck and not AX_ReadPvPState(p) then return end
            if _G.G_AimbotSafeZoneCheck and AX_InSafeZone(p) then return end
            if _G.G_SilentAimTeamCheck and not IsSilentAimEnemy(p) then return end
        end

        local hum = character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local part = GetPreferredAimPart(character)
        if not part then return end

        local worldDist = (part.Position - myHRP.Position).Magnitude
        if worldDist > maxDist3D then return end
        if SilentAimTargetMode == "Lowest Health" then
            if hum.Health < lowestHealth or (hum.Health == lowestHealth and worldDist < shortest3DDist) then
                lowestHealth = hum.Health
                shortest3DDist = worldDist
                closestPart = part
            end
        elseif worldDist <= shortest3DDist then
            shortest3DDist = worldDist
            closestPart = part
        end
    end

    local wantPlayers = _G.G_SilentAimTargetPlayers
    local wantMobs = _G.G_SilentAimTargetMobs

    if wantPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                checkTargetPart(p.Character)
            end
        end
    end

    if wantMobs then
        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            for _, enemy in ipairs(enemies:GetChildren()) do
                checkTargetPart(enemy)
            end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj ~= myChar and obj:FindFirstChildOfClass("Humanoid") then
                checkTargetPart(obj)
            end
        end
    end

    return closestPart
end

if _G.G_AutoPrediction == nil then _G.G_AutoPrediction = true end
function GetPredictedAimPosition(part)
    if not part or not part:IsA("BasePart") then return nil end
    local pos = part.Position
    if not _G.G_AutoPrediction then return pos end
    local pingMs = 0
    pcall(function() pingMs = player:GetNetworkPing() * 1000 end)
    if pingMs <= 0 then pingMs = currentPing or 0 end
    local leadTime = math.clamp((pingMs / 1000) * 0.55, 0.02, 0.22)
    local velocity = part.AssemblyLinearVelocity
    if velocity.Magnitude > 0.05 then
        pos = pos + velocity * leadTime
    end
    return pos
end

UserInputService.InputBegan:Connect(function(input, gp)
    local now = os.clock()

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isM1Pressed = true
        m1InputUntil = now + 0.10
        activeSkillKey = "M1"
        return
    end

    if input.UserInputType == Enum.UserInputType.Keyboard and not gp then
        if input.KeyCode == Enum.KeyCode.Z then activeSkillKey = "Z"
        elseif input.KeyCode == Enum.KeyCode.X then activeSkillKey = "X"
        elseif input.KeyCode == Enum.KeyCode.C then activeSkillKey = "C"
        elseif input.KeyCode == Enum.KeyCode.V then activeSkillKey = "V"
        elseif input.KeyCode == Enum.KeyCode.F then activeSkillKey = "F"
        else return end
        mobileAbilityUntil = now + 0.60
        isM1Pressed = false
        m1InputUntil = 0
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch then
        local overButton = false
        pcall(function()
            local pg = player:FindFirstChildOfClass("PlayerGui")
            if pg then
                for _, gui in ipairs(pg:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)) do
                    if gui:IsA("GuiButton") and gui.Visible and gui.Active then
                        overButton = true
                        break
                    end
                end
            end
        end)

        if overButton or gp then
            activeSkillKey = "ABILITY"
            mobileAbilityUntil = now + 0.60
            isM1Pressed = false
        else
            isM1Pressed = true
            m1InputUntil = now + 0.10
            activeSkillKey = "M1"
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isM1Pressed = false
        if activeSkillKey == "M1" then activeSkillKey = nil end
    end
    if input.KeyCode == Enum.KeyCode.Z and activeSkillKey == "Z" then activeSkillKey = nil
    elseif input.KeyCode == Enum.KeyCode.X and activeSkillKey == "X" then activeSkillKey = nil
    elseif input.KeyCode == Enum.KeyCode.C and activeSkillKey == "C" then activeSkillKey = nil
    elseif input.KeyCode == Enum.KeyCode.V and activeSkillKey == "V" then activeSkillKey = nil
    elseif input.KeyCode == Enum.KeyCode.F and activeSkillKey == "F" then activeSkillKey = nil
    elseif input.UserInputType == Enum.UserInputType.Touch and activeSkillKey == "ABILITY" then activeSkillKey = nil
    end
end)

function GetEquippedToolCategory()
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return "Melee" end

    local tName = string.lower(tool.Name)
    local tt = ""
    pcall(function() tt = string.lower(tool.ToolTip or tool:GetAttribute("Type") or "") end)

    local isFruit = string.find(tName, "fruit") or string.find(tt, "fruit") or string.find(tt, "bloxfruit") or tool:FindFirstChild("Fruit") ~= nil
    if not isFruit and string.find(tName, "-") then
        local firstPart, secondPart = tName:match("^([%w%s]+)%-(%w+)$")
        if firstPart and secondPart and (firstPart:find(secondPart) or secondPart:find(firstPart)) then
            isFruit = true
        end
    end

    local fruitKeywords = {"blade-blade", "bladeblade", "portal", "dough", "dragon", "leopard", "kitsune", "buddha", "t-rex", "trex", "mammoth", "sound", "blizzard", "spirit", "venom", "shadow", "control", "gravity", "rumble", "paw", "spider", "love", "quake", "magma", "light", "ice", "flame", "dark", "sand", "falcon", "diamond", "rubber", "barrier", "ghost", "spin", "chop", "spring", "bomb", "smoke", "rocket"}
    if not isFruit then
        for _, kw in ipairs(fruitKeywords) do
            if string.find(tName, kw) and not string.find(tName, "sword") and not string.find(tName, "blade") and not string.find(tName, "gun") then
                isFruit = true
                break
            end
        end
    end

    if isFruit then
        return "Fruit"
    elseif string.find(tName, "blade") or string.find(tName, "sword") or string.find(tName, "katana") or string.find(tName, "yoru") or string.find(tName, "cursed") or string.find(tName, "scythe") or string.find(tName, "saber") or string.find(tName, "pole") or string.find(tName, "bisento") or string.find(tName, "trident") or string.find(tName, "dagger") or string.find(tt, "sword") then
        return "Sword"
    elseif string.find(tName, "gun") or string.find(tName, "rifle") or string.find(tName, "flintlock") or string.find(tName, "kabucha") or string.find(tName, "slingshot") or string.find(tName, "bazooka") or string.find(tName, "cannon") or string.find(tName, "guitar") or string.find(tt, "gun") then
        return "Gun"
    end
    return "Melee"
end

function IsCurrentToolAimbotAllowed()
    return true
end

function GetCurrentAimMoveKey()
    local now = os.clock()

    if lastActivatedSkillUntil > now and lastActivatedSkillKey then
        return lastActivatedSkillKey
    end

    if (m1ToolUntil > now and m1ToolRef ~= nil) or m1InputUntil > now or isM1Pressed then
        return "M1"
    end

    return activeSkillKey
end

function IsCurrentSlotAimbotAllowed(explicitSkillKey)
    local category = GetEquippedToolCategory()
    local key = explicitSkillKey or GetCurrentAimMoveKey()
    local now = os.clock()

    if key == nil or key == "" then

        key = nil
    end

    if key == "Z" or key == "X" or key == "C" or key == "V" or key == "F" or key == "ABILITY" then
        return not (_G["G_Blacklist_" .. category .. "_" .. key] == true)
    end

    if key == "M1" then
        local blocked = _G["G_Blacklist_" .. category .. "_M1"] == true
        return not blocked
    end

    return true
end

local MouseModuleInstance = ReplicatedStorage:FindFirstChild("Mouse")
local MouseModule = nil
if MouseModuleInstance then
    pcall(function() MouseModule = require(MouseModuleInstance) end)
end
if MouseModule and typeof(MouseModule) == "table" then
    pcall(function()
        local realStore = { Hit = rawget(MouseModule, "Hit"), Target = rawget(MouseModule, "Target") }
        local mmt = getrawmetatable(MouseModule)
        if mmt then setreadonly(mmt, false) else mmt = {}; setmetatable(MouseModule, mmt) end
        rawset(MouseModule, "Hit", nil); rawset(MouseModule, "Target", nil)
        mmt.__index = function(self, key)
            if key == "Hit" then
                if _G.G_SilentAimSkill and currentSilentAimTarget and IsCurrentToolAimbotAllowed() and IsCurrentSlotAimbotAllowed() then return CFrame.new(GetPredictedAimPosition(currentSilentAimTarget) or currentSilentAimTarget.Position) end
                return realStore.Hit
            elseif key == "Target" then
                if _G.G_SilentAimSkill and currentSilentAimTarget and IsCurrentToolAimbotAllowed() and IsCurrentSlotAimbotAllowed() then return currentSilentAimTarget end
                return realStore.Target
            end
        end
        mmt.__newindex = function(self, key, value)
            if key == "Hit" or key == "Target" then realStore[key] = value else rawset(self, key, value) end
        end
        setreadonly(mmt, true)
    end)
end


-- Strictly scoped combat hook:
-- 1) Gun M1 Silent Aim only redirects an existing ShootGunEvent call.
--    It never creates/fires a shot by itself.
-- 2) Buddy Sword X captures the game's real InvokeServer request and
--    redirects its target argument, preserving the game's argument shape.
pcall(function()
    if hookmetamethod and newcclosure and getnamecallmethod then
        local previousNamecall
        previousNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local args = {...}
            local method = tostring(getnamecallmethod() or ""):lower()

            if method == "invokeserver" and self and self:IsA("RemoteFunction") then
                local char = player.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                local toolName = tool and string.lower(tostring(tool.Name)) or ""
                if tool and toolName:find("buddy", 1, true) and toolName:find("sword", 1, true)
                    and type(args[1]) == "string" and string.upper(args[1]) == "X" then
                    BuddyXRemote = self
                    BuddyXTemplateArgs = table.clone(args)
                    local target = GetBuddyXTarget()
                    if target then
                        args[2] = GetPredictedAimPosition(target) or target.Position
                    end
                    return previousNamecall(self, unpack(args))
                end
            end

            if method == "fireserver" and _G.G_GunM1SilentAim
                and self and self:IsA("RemoteEvent")
                and tostring(self.Name):lower():find("shootgunevent", 1, true)
                and _G.G_SilentAimSkill
                and currentSilentAimTarget
                and GetEquippedToolCategory() == "Gun"
                and IsCurrentSlotAimbotAllowed("M1") then

                local activePos = GetPredictedAimPosition(currentSilentAimTarget) or currentSilentAimTarget.Position
                args[1] = activePos
                args[2] = {currentSilentAimTarget}
                return previousNamecall(self, unpack(args))
            end

            return previousNamecall(self, ...)
        end))
    end
end)


function GetRainbowTargetChar()
    local targetPart = currentSilentAimTarget or GetClosestTargetToCenter()
    if targetPart and targetPart:IsA("BasePart") and targetPart.Parent then
        local hum = targetPart.Parent:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return targetPart.Parent
        end
    end
    return nil
end

local activeTargetHighlight = nil

local function updateRainbowTargetHighlight(targetChar)
    if not targetChar or not targetChar:IsA("Model") then
        if activeTargetHighlight then
            activeTargetHighlight:Destroy()
            activeTargetHighlight = nil
        end
        return
    end

    if not activeTargetHighlight or activeTargetHighlight.Parent ~= targetChar then
        if activeTargetHighlight then activeTargetHighlight:Destroy() end
        activeTargetHighlight = Instance.new("Highlight")
        activeTargetHighlight.Name = "ProdigyRainbowTargetBody"
        activeTargetHighlight.Adornee = targetChar
        activeTargetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        activeTargetHighlight.FillTransparency = 0.2
        activeTargetHighlight.OutlineTransparency = 0
        activeTargetHighlight.Parent = targetChar
    end

    local hue = (tick() * 0.7) % 1
    local rainbowColor = Color3.fromHSV(hue, 1, 1)
    activeTargetHighlight.FillColor = rainbowColor
    activeTargetHighlight.OutlineColor = Color3.fromHSV((hue + 0.25) % 1, 1, 1)
end

local SilentGunLastFire = 0
local SilentGunCooldown = 0.1

-- Buddy Sword X 100% modes
-- Uses the game's own Buddy Sword X RemoteFunction when observed.
-- Manual mode redirects the real X request; Auto mode replays the same
-- request shape at the current Silent Aim target.
local BuddyXLastFire = 0
local BuddyXCooldown = 0.05
local BuddyXManualSeen = 0
local BuddyXBusy = false
local BuddyXRemote = nil
local BuddyXTemplateArgs = nil

local function GetBuddyXTarget()
    local targetPart = currentSilentAimTarget or GetClosestTargetToCenter()
    if not targetPart or not targetPart:IsA("BasePart") or not targetPart.Parent then return nil end
    local targetChar = targetPart.Parent
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not root or not myRoot or targetChar == myChar then return nil end
    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
    if targetPlayer then
        if not _G.G_SilentAimTargetPlayers then return nil end
        if targetPlayer == player or BlacklistedPlayers[targetPlayer.Name] then return nil end
        if _G.G_SilentAimTeamCheck and not IsSilentAimEnemy(targetPlayer) then return nil end
        if _G.G_AimbotPvPCheck and not AX_ReadPvPState(targetPlayer) then return nil end
        if _G.G_AimbotSafeZoneCheck and AX_InSafeZone(targetPlayer) then return nil end
    else
        if not _G.G_SilentAimTargetMobs then return nil end
    end
    if (root.Position - myRoot.Position).Magnitude > (maxRange or 4250) then return nil end
    return root
end

local function FireBuddyX100()
    if BuddyXBusy then return false end
    if GetEquippedToolCategory() ~= "Sword" then return false end
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    local name = tool and string.lower(tostring(tool.Name)) or ""
    if not (name:find("buddy", 1, true) and name:find("sword", 1, true)) then return false end
    local targetRoot = GetBuddyXTarget()
    if not targetRoot or not BuddyXRemote or not BuddyXTemplateArgs then return false end
    local now = os.clock()
    if now - BuddyXLastFire < BuddyXCooldown then return false end

    local args = table.clone(BuddyXTemplateArgs)
    args[2] = GetPredictedAimPosition(targetRoot) or targetRoot.Position
    BuddyXBusy = true
    BuddyXLastFire = now
    task.spawn(function()
        pcall(function()
            BuddyXRemote:InvokeServer(unpack(args))
        end)
        BuddyXBusy = false
    end)
    return true
end

local function BuddyXStep()
    local mode = _G.G_BuddyXMode
    if mode ~= "Auto" and mode ~= "Manual" then return end
    if GetEquippedToolCategory() ~= "Sword" then return end
    if mode == "Auto" then
        FireBuddyX100()
        return
    end
    local now = os.clock()
    if lastActivatedSkillKey == "X" and lastActivatedSkillUntil > now and BuddyXManualSeen ~= lastActivatedSkillUntil then
        BuddyXManualSeen = lastActivatedSkillUntil
        -- Manual X is already sent by the game; the hook below redirects it.
    end
end


-- ============================================================
-- GUN M1 SILENT AIM + DRAGON GUN M1
-- ============================================================

local DragonShootFunction = nil
local DragonValidatorIndexes = {v26=12,v22=13,v25=14,v21=15,v23=16,v24=17,v27=18}

local function InitDragonGun()
    local ok, controller = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CombatController"))
    end)
    if ok and type(controller) == "table" and type(controller.Attack) == "function" then
        local getup = debug.getupvalue or getupvalue
        if getup then
            pcall(function()
                DragonShootFunction = getup(controller.Attack, 9)
            end)
        end
    end
end

local function GetNextDragonValidator()
    if not DragonShootFunction then InitDragonGun() end
    if not DragonShootFunction then return 0, 0 end

    local getups = debug.getupvalues or getupvalues
    local setup = debug.setupvalue or setupvalue
    if not getups or not setup then return 0, 0 end

    local ok, values = pcall(getups, DragonShootFunction)
    if not ok or not values then return 0, 0 end

    local idx = DragonValidatorIndexes
    if values[idx.v21] ~= 727595 then
        for i, v in pairs(values) do
            if v == 727595 then
                local offset = i - 15
                idx.v21 = i
                idx.v22 = 13 + offset
                idx.v23 = 16 + offset
                idx.v24 = 17 + offset
                idx.v26 = 12 + offset
                idx.v25 = 14 + offset
                idx.v27 = 18 + offset
                break
            end
        end
    end

    local ok2, v1,v2,v3,v4,v5,v6,v7 = pcall(function()
        return getup(DragonShootFunction,idx.v21),
               getup(DragonShootFunction,idx.v22),
               getup(DragonShootFunction,idx.v23),
               getup(DragonShootFunction,idx.v24),
               getup(DragonShootFunction,idx.v25),
               getup(DragonShootFunction,idx.v26),
               getup(DragonShootFunction,idx.v27)
    end)
    if not ok2 or not (v1 and v2 and v3 and v4 and v5 and v6 and v7) then return 0,0 end

    local v8 = v6 * v2
    local v9 = (v5 * v2 + v6 * v1) % v3
    v9 = (v9 * v3 + v8) % v4
    v5 = math.floor(v9 / v3)
    v6 = v9 - v5 * v3
    v7 = v7 + 1

    pcall(function()
        setup(DragonShootFunction,idx.v25,v5)
        setup(DragonShootFunction,idx.v26,v6)
        setup(DragonShootFunction,idx.v27,v7)
    end)

    return math.floor(v9 / v4 * 16777215), v7
end

local function GetClosestDragonTarget()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local closest, dist = nil, math.huge
    local myPos = root.Position

    if _G.G_AttackMobs or _G.G_SilentAimTargetMobs then
        local enemies = workspace:FindFirstChild("Enemies")
        if enemies then
            for _, enemy in ipairs(enemies:GetChildren()) do
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                local r = enemy:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and r then
                    local d = (r.Position - myPos).Magnitude
                    if d < dist and d <= (maxRange or 4250) then dist = d; closest = r end
                end
            end
        end
    end

    if _G.G_AttackPlayers or _G.G_SilentAimTargetPlayers then
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= player and targetPlayer.Character then
                local hum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                local r = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and r and not BlacklistedPlayers[targetPlayer.Name] then
                    if not (_G.G_SilentAimTeamCheck and not IsSilentAimEnemy(targetPlayer)) then
                        local d = (r.Position - myPos).Magnitude
                        if d < dist and d <= (maxRange or 4250) then dist = d; closest = r end
                    end
                end
            end
        end
    end
    return closest
end

-- Sacred's Dragon M1 path is a real gun-shot path, not a generic gun autofire toggle.
-- Keep it isolated: it only runs while the dedicated Dragon M1 option is enabled.
task.spawn(function()
    while task.wait(0.085) do
        if _G.G_DragonGunM1 then
            pcall(function()
                local char = player.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if not tool or tool.ToolTip ~= "Gun" then return end

                local target = currentSilentAimTarget or GetClosestDragonTarget()
                if not target then return end

                local modules = ReplicatedStorage:FindFirstChild("Modules")
                local net = modules and modules:FindFirstChild("Net")
                local shootEvent = net and net:FindFirstChild("RE/ShootGunEvent")
                if not shootEvent then return end

                local code, count = GetNextDragonValidator()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local validator = remotes and remotes:FindFirstChild("Validator2")
                if code ~= 0 and validator then validator:FireServer(code, count) end

                tool:SetAttribute("LocalOverheat", 0)
                tool:SetAttribute("LocalTotalShots", (tool:GetAttribute("LocalTotalShots") or 0) + 1)
                shootEvent:FireServer(GetPredictedAimPosition(target) or target.Position, {target})
            end)
        end
    end
end)


local function GetCurrentSilentGunTarget()
    local targetPart = currentSilentAimTarget
    if not targetPart or not targetPart:IsA("BasePart") or not targetPart.Parent then
        return nil
    end

    local targetChar = targetPart.Parent
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        return nil
    end

    local myChar = player.Character
    if targetChar == myChar then
        return nil
    end

    -- GetClosestTargetToCenter already filters Player/NPC selection, team checks,
    -- safe zones, blacklists, and range. This extra check prevents stale targets.
    local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
    if targetPlayer then
        if not _G.G_SilentAimTargetPlayers then return nil end
        if targetPlayer == player or BlacklistedPlayers[targetPlayer.Name] then return nil end
        if _G.G_SilentAimTeamCheck and not IsSilentAimEnemy(targetPlayer) then return nil end
    else
        if not _G.G_SilentAimTargetMobs then return nil end
    end

    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myRoot and (targetPart.Position - myRoot.Position).Magnitude > (maxRange or 3500) then
        return nil
    end

    return targetPart
end

local function SilentGunAutoFire()
    if not _G.G_SilentAimGunAutoFire or not _G.G_SilentAimSkill then
        return
    end

    if GetEquippedToolCategory() ~= "Gun" then
        return
    end

    local now = os.clock()
    if now - SilentGunLastFire < SilentGunCooldown then
        return
    end

    local targetPart = GetCurrentSilentGunTarget()
    if not targetPart then
        return
    end

    local net = ReplicatedStorage:FindFirstChild("Modules")
    net = net and net:FindFirstChild("Net")
    local shootEvent = net and net:FindFirstChild("RE/ShootGunEvent")
    if not shootEvent then
        return
    end

    local targetPos = GetPredictedAimPosition(targetPart) or targetPart.Position

    pcall(function()
        shootEvent:FireServer(targetPos, {targetPart})
    end)

    SilentGunLastFire = now
end

RunService.RenderStepped:Connect(function()
    pcall(SilentGunAutoFire)
    pcall(BuddyXStep)
end)

RunService.RenderStepped:Connect(function()
    pcall(function()
        local cam = workspace.CurrentCamera
        local screenCenter = cam and Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) or Vector2.new(0, 0)

        currentSilentAimTarget = GetClosestTargetToCenter()

        if LockLine then
            if _G.G_SilentAimShowLine and currentSilentAimTarget and currentSilentAimTarget.Parent then
                local targetPos, onScreen = cam:WorldToViewportPoint(currentSilentAimTarget.Position)
                local target2D = Vector2.new(targetPos.X, targetPos.Y)
                local viewport = cam.ViewportSize
                local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
                local endpoint = target2D

                if targetPos.Z <= 0 then
                    
                    local worldDir = (currentSilentAimTarget.Position - cam.CFrame.Position)
                    local localDir = cam.CFrame:VectorToObjectSpace(worldDir.Unit)
                    local angle = math.atan2(localDir.X, -localDir.Z)
                    endpoint = center + Vector2.new(math.sin(angle), -math.cos(angle)) * (math.min(viewport.X, viewport.Y) * 0.44)
                    onScreen = false
                elseif not onScreen then
                    local dx, dy = target2D.X - center.X, target2D.Y - center.Y
                    local scaleX = math.abs(dx) > 0.001 and ((viewport.X * 0.47) / math.abs(dx)) or math.huge
                    local scaleY = math.abs(dy) > 0.001 and ((viewport.Y * 0.47) / math.abs(dy)) or math.huge
                    local scale = math.min(scaleX, scaleY)
                    endpoint = center + Vector2.new(dx, dy) * scale
                end

                LockLine.From = center
                LockLine.To = endpoint
                LockLine.Thickness = math.clamp(tonumber(_G.G_ESP_LineThickness) or 2, 1, 6)
                LockLine.Color = hexToColor3(_G.G_ESP_LineColor or "FF4B14")
                LockLine.Visible = true
            else
                LockLine.Visible = false
            end
        end

        if _G.G_TargetRainbowBodyESP then
            local targetChar = GetRainbowTargetChar()
            if targetChar then
                updateRainbowTargetHighlight(targetChar)
            else
                updateRainbowTargetHighlight(nil)
            end
        else
            updateRainbowTargetHighlight(nil)
        end
    end)
end)

RunService.Stepped:Connect(function()
    if WalkSpeedEnabled and player.Character then
        local hum = player.Character:FindFirstChildOfClass('Humanoid')
        local hrp = player.Character:FindFirstChild('HumanoidRootPart')
        if hum and hrp then
            hum.WalkSpeed = WalkSpeedValue
            if hum.MoveDirection.Magnitude > 0 and WalkSpeedValue > 20 then
                hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (WalkSpeedValue / 100))
            end
        end
    end
end)

function SetPlayerBlacklist(playerName,state)
    if type(playerName)~='string' or playerName=='' then return end
    BlacklistedPlayers[playerName]=state==true or nil
end
function TogglePlayerBlacklist(playerName)
    if type(playerName)~='string' or playerName=='' then return false end
    BlacklistedPlayers[playerName]=not BlacklistedPlayers[playerName]
    return BlacklistedPlayers[playerName]==true
end

function SetSilentAim(v) _G.G_SilentAimSkill=(v==true) end
function SetMaxAccuracyMode(v)
    _G.G_MaxAccuracyMode = (v == true)
end

function SetBuddyXMode(mode)
    mode = tostring(mode)
    if mode ~= "Auto" and mode ~= "Manual" and mode ~= "Off" then mode = "Off" end
    _G.G_BuddyXMode = mode
    BuddyXManualSeen = 0
    pcall(SaveConfig)
end
function SetSilentAimTargets(playersEnabled,mobsEnabled)
    if playersEnabled~=nil then _G.G_SilentAimTargetPlayers=playersEnabled==true end
    if mobsEnabled~=nil then _G.G_SilentAimTargetMobs=mobsEnabled==true end
end
function SetTeamCheck(v) _G.G_SilentAimTeamCheck=(v==true) end
function SetAimlockPlayers(v) AimlockPlayerEnabled=(v==true) end
function SetAimlockNPCs(v) AimlockNpcEnabled=(v==true) end
function SetSoruAimbot(v) SoruAimbotEnabled=(v==true) end
function SetAntiStunHitbox(v)
    if v then enableAntiStunHitbox() else disableAntiStunHitbox() end
end
function SetFastAttack(v)
    FastAttackEnabled=(v==true)
    if FastAttackEnabled then StartFastAttack() end
end
function SetWalkSpeed(v,speed)
    WalkSpeedEnabled=(v==true)
    if speed~=nil then WalkSpeedValue=math.clamp(tonumber(speed) or WalkSpeedValue, 16, 120) end
end
function SetDash(v,distance)
    DashEnabled=(v==true)
    if distance~=nil then DashLengthDist=tonumber(distance) or DashLengthDist end
    if DashEnabled then startDashLoop(); applyDashInstantly() else stopDashLoop() end
end
function SetWalkOnWater(v) WalkOnWaterEnabled=(v==true) end
function SetSmartAutoV4(v) SmartAutoV4Enabled=(v==true) end
function SetAutoV4(v)
    AutoV4Enabled=(v==true)
    if AutoV4Enabled then startAutoV4Loop() else stopAutoV4Loop() end
end
function SetSuperJump(v,power)
    SuperJumpEnabled=(v==true)
    if power~=nil then SuperJumpPower=tonumber(power) or SuperJumpPower end
end
function SetSoulGuitar(v,dashLength)
    SoulGuitarJumpEnabled=(v==true)
    if dashLength~=nil then SoulGuitarDashLength=tonumber(dashLength) or SoulGuitarDashLength end
    if SoulGuitarJumpEnabled then
        prevDashLength=DashLengthDist
        DashLengthDist=SoulGuitarDashLength
        DashEnabled=true
        applyDashInstantly()
    else
        DashLengthDist=prevDashLength or 1
        applyDashInstantly()
    end
end
function SetAntiLava(v)
    antiLavaActive=(v==true)
    if antiLavaActive then startAntiLava() else stopAntiLava() end
end
function SetDeleteShip(v)
    deleteShipActive=(v==true)
    if deleteShipActive then startDeleteShipLoop() end
end
function SetFakeKorblox(v)
    FakeKorbloxEnabled=(v==true)
    if FakeKorbloxEnabled then applyFakeKorblox(player.Character) else removeFakeKorblox(player.Character) end
end
function SetFakeHeadless(v)
    FakeHeadlessEnabled=(v==true)
    if FakeHeadlessEnabled then applyFakeHeadless(player.Character) else removeFakeHeadless(player.Character) end
end
function SetESP(v)
    local b = v == true
    _G.G_ESPEnabled = b
    
    _G.G_ESP_Name = b
    _G.G_ESP_Level = b
    _G.G_ESP_Bounty = b
    _G.G_ESP_Fruit = b
    _G.G_ESP_Distance = b
    _G.G_ESP_HP = b
    _G.G_ESP_Highlight = b
    if b then EnableESP() else DisableESP() end
end
function SetESPOption(option,v)
    local map={Name="G_ESP_Name",Level="G_ESP_Level",Bounty="G_ESP_Bounty",Fruit="G_ESP_Fruit",Distance="G_ESP_Distance",HP="G_ESP_HP",Highlight="G_ESP_Highlight"}
    local key=map[option]
    if not key then return end
    _G[key]=v==true
    local any=_G.G_ESP_Name or _G.G_ESP_Level or _G.G_ESP_Bounty or _G.G_ESP_Fruit or _G.G_ESP_Distance or _G.G_ESP_HP or _G.G_ESP_Highlight
    _G.G_ESPEnabled=any
    if any then EnableESP() else DisableESP() end
end
function SetAimbotTarget(name)
    if name==nil or name=="" or name=="Nearest" then
        _G.G_SilentAimSelectedPlayer=""
        SelectedSoruTarget="Nearest"
    else
        _G.G_SilentAimSelectedPlayer=tostring(name)
        SelectedSoruTarget=tostring(name)
    end
end
function SetAimbotMaxDistance(distance)
    local n = tonumber(distance)
    if n then maxRange = math.clamp(n, 0, 4250) end
end
function SetSilentAimTargetMode(mode)
    if mode == "Lowest Health" or mode == "Nearest" then
        SilentAimTargetMode = mode
        pcall(SaveConfig)
    end
end
function SetSoruTarget(name) SelectedSoruTarget=(name and name~="") and tostring(name) or "Nearest" end

SuperJumpWidgetVisible=false
_G.G_SilentAimShowLine=_G.G_SilentAimShowLine or false
_G.G_AimbotSafeZoneCheck=_G.G_AimbotSafeZoneCheck ~= false
_G.G_AimbotPvPCheck=_G.G_AimbotPvPCheck ~= false
pcall(LoadConfig)

local function destroyCamLockFloatingButton()
    if CamLockFloatingGui then
        CamLockFloatingGui:Destroy()
        CamLockFloatingGui = nil
        CamLockFloatingButton = nil
    end
end

local function createCamLockFloatingButton()
    destroyCamLockFloatingButton()
    if not CamLockFloatingEnabled or not playerGui then return end

    CamLockFloatingGui = Instance.new("ScreenGui")
    CamLockFloatingGui.Name = "Prodigy_CamLock_Floating"
    CamLockFloatingGui.ResetOnSpawn = false
    CamLockFloatingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    CamLockFloatingGui.Parent = playerGui

    local button = Instance.new("TextButton")
    button.Name = "CamLockButton"
    button.Size = UDim2.fromOffset(math.clamp(tonumber(CamLockButtonWidth) or 110, 60, 300), math.clamp(tonumber(CamLockButtonHeight) or 40, 28, 120))
    button.Position = UDim2.new(CamLockButtonX, 0, CamLockButtonY, 0)
    button.BackgroundColor3 = AimlockPlayerEnabled and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(55, 55, 65)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Text = AimlockPlayerEnabled and "CAM LOCK: ON" or "CAM LOCK: OFF"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.AutoButtonColor = false
    button.Active = true
    button.Parent = CamLockFloatingGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Transparency = .25
    stroke.Thickness = 1
    stroke.Parent = button
    CamLockFloatingButton = button

    local dragging, dragStart, startPos, moved = false, nil, nil, false
    local function updateDrag(input)
        local delta = input.Position - dragStart
        if delta.Magnitude > 6 then moved = true end
        button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, dragStart, startPos = not LockAllUIButtons, false, input.Position, button.Position
        end
    end)
    button.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateDrag(input) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateDrag(input) end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            if not moved and UIButtonMode == "Use" then
                AimlockPlayerEnabled = not AimlockPlayerEnabled
                PlayerWidgetActive = AimlockPlayerEnabled
                SetAimlockPlayers(AimlockPlayerEnabled)
                button.Text = AimlockPlayerEnabled and "CAM LOCK: ON" or "CAM LOCK: OFF"
                button.BackgroundColor3 = AimlockPlayerEnabled and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(55, 55, 65)
                pcall(SaveConfig)
                local refresh = ToggleRegistryMap and ToggleRegistryMap["Aimlock Players"]
                if refresh then refresh(AimlockPlayerEnabled) end
            elseif moved then
                CamLockButtonX = math.clamp(button.Position.X.Scale + button.Position.X.Offset / math.max(workspace.CurrentCamera.ViewportSize.X, 1), 0, 1)
                CamLockButtonY = math.clamp(button.Position.Y.Scale + button.Position.Y.Offset / math.max(workspace.CurrentCamera.ViewportSize.Y, 1), 0, 1)
                button.Position = UDim2.new(CamLockButtonX, 0, CamLockButtonY, 0)
                pcall(SaveConfig)
            end
        end
    end)
end

local function refreshCamLockFloatingButton()
    if CamLockFloatingEnabled then createCamLockFloatingButton() else destroyCamLockFloatingButton() end
end

local function BuildUI()

local PlayersUI = game:GetService("Players")
local TweenServiceUI = game:GetService("TweenService")
local UserInputServiceUI = game:GetService("UserInputService")
local CoreGuiUI = game:GetService("CoreGui")

local function uiParent()
    local ok, hui = pcall(function()
        if type(gethui) == "function" then return gethui() end
        return nil
    end)
    if ok and hui then return hui end
    return CoreGuiUI
end

pcall(function()
    local old = uiParent():FindFirstChild("Prodigy")
    if old then old:Destroy() end
end)

local function parseHexColor(hex)
    hex = tostring(hex or "00FFFF"):gsub("#", "")
    if #hex ~= 6 or not hex:match("^[%x]+$") then return Color3.fromRGB(0, 255, 255) end
    local n = tonumber(hex, 16)
    return Color3.fromRGB(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
end

local function colorToHex(c)
    local r = math.clamp(math.floor(c.R * 255 + .5), 0, 255)
    local g = math.clamp(math.floor(c.G * 255 + .5), 0, 255)
    local b = math.clamp(math.floor(c.B * 255 + .5), 0, 255)
    return string.format("%02X%02X%02X", r, g, b)
end

local accent = parseHexColor(_G.G_UIAccentColor)
local Screen 

local Theme = {
    bg = Color3.fromRGB(2, 2, 8),
    panel = Color3.fromRGB(5, 5, 16),
    panel2 = Color3.fromRGB(7, 7, 20),
    card = Color3.fromRGB(4, 12, 22),
    cardHover = Color3.fromRGB(8, 22, 34),
    cyan = accent,
    purple = accent,
    cyanDark = accent:Lerp(Color3.new(0,0,0), .78),
    text = Color3.fromRGB(230, 240, 255),
    muted = Color3.fromRGB(80, 120, 140),
    green = accent,
    line = accent:Lerp(Color3.new(0,0,0), .28)
}

local function ApplyUIAccent(newColor)
    if typeof(newColor) ~= "Color3" then return end
    local old = {cyan=Theme.cyan,purple=Theme.purple,line=Theme.line,cyanDark=Theme.cyanDark,green=Theme.green}
    Theme.cyan=newColor; Theme.purple=newColor; Theme.line=newColor:Lerp(Color3.new(0,0,0),.28); Theme.cyanDark=newColor:Lerp(Color3.new(0,0,0),.78); Theme.green=newColor
    _G.G_UIAccentColor=colorToHex(newColor)
    if not Screen or not Screen.Parent then return end
    for _,obj in ipairs(Screen:GetDescendants()) do pcall(function()
        if obj:IsA("UIStroke") then
            if obj.Color==old.cyan or obj.Color==old.purple or obj.Color==old.green then obj.Color=Theme.cyan elseif obj.Color==old.line then obj.Color=Theme.line end
        elseif obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if obj.TextColor3==old.cyan or obj.TextColor3==old.purple or obj.TextColor3==old.green then obj.TextColor3=Theme.cyan end
        elseif obj:IsA("GuiObject") then
            if obj.BackgroundColor3==old.cyan or obj.BackgroundColor3==old.purple or obj.BackgroundColor3==old.green then obj.BackgroundColor3=Theme.cyan elseif obj.BackgroundColor3==old.cyanDark then obj.BackgroundColor3=Theme.cyanDark end
        end
        if obj:IsA("ScrollingFrame") and obj.ScrollBarImageColor3==old.cyan then obj.ScrollBarImageColor3=Theme.cyan end
    end) end
    pcall(SaveConfig)
end

local function uiTween(obj, duration, props)
    return TweenServiceUI:Create(obj, TweenInfo.new(duration or .2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
end

local function uiCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = obj
    return c
end

local function uiOutline(obj, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.line
    s.Transparency = transparency == nil and .35 or transparency
    s.Thickness = thickness or 1
    s.Parent = obj
    return s
end

local function uiLabel(parent, value, size, bold)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = value or ""
    l.TextColor3 = Theme.text
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium
    l.TextSize = size or 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function applyUITextScaleToObject(obj)
    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
    local base = obj:GetAttribute("ProdigyBaseTextSize")
    if type(base) ~= "number" then
        base = obj.TextSize
        obj:SetAttribute("ProdigyBaseTextSize", base)
    end
    obj.TextSize = math.max(1, math.floor(base * (_G.G_UITextScale or 1) + 0.5))
end

local function ApplyUITextScale(scaleValue)
    local n = tonumber(scaleValue)
    if not n then return end
    _G.G_UITextScale = math.clamp(n, 0.8, 1.6)
    if not Screen or not Screen.Parent then return end
    for _, obj in ipairs(Screen:GetDescendants()) do
        pcall(applyUITextScaleToObject, obj)
    end
end

Screen = Instance.new("ScreenGui")
Screen.Name = "Prodigy"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent = uiParent()
Screen.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if obj.Parent then pcall(applyUITextScaleToObject, obj) end
    end)
end)

local ToastHolder = Instance.new("Frame")
ToastHolder.BackgroundTransparency = 1
ToastHolder.AnchorPoint = Vector2.new(1, 0)
ToastHolder.Position = UDim2.new(1, -18, 0, 72)
ToastHolder.Size = UDim2.new(0, 330, 0, 400)
ToastHolder.Parent = Screen
local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 8)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.Parent = ToastHolder

local function notifyUI(titleText, descText, duration)
    local toast = Instance.new("Frame")
    toast.BackgroundColor3 = Theme.panel2
    toast.BackgroundTransparency = 1
    toast.Size = UDim2.new(1, 0, 0, 58)
    toast.Parent = ToastHolder
    uiCorner(toast, 12)
    uiOutline(toast, Theme.cyan, .5, 1)

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Theme.cyan
    bar.Position = UDim2.new(0, 8, 0, 8)
    bar.Size = UDim2.new(0, 3, 1, -16)
    bar.Parent = toast
    uiCorner(bar, 3)

    local t = uiLabel(toast, titleText or "Prodigy", 12, true)
    t.Position = UDim2.new(0, 22, 0, 8)
    t.Size = UDim2.new(1, -32, 0, 18)

    local d = uiLabel(toast, descText or "", 10, false)
    d.TextColor3 = Theme.muted
    d.Position = UDim2.new(0, 22, 0, 28)
    d.Size = UDim2.new(1, -32, 0, 18)

    uiTween(toast, .2, {BackgroundTransparency = .03}):Play()
    task.delay(duration or 3, function()
        if toast.Parent then
            uiTween(toast, .2, {BackgroundTransparency = 1}):Play()
            task.wait(.22)
            toast:Destroy()
        end
    end)
end
local notify = notifyUI

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(.5, .5)
Main.Position = UDim2.new(.5, 0, .5, 0)
Main.Size = UDim2.new(0, 1000, 0, 650)
Main.BackgroundColor3 = Theme.bg
Main.ClipsDescendants = true
Main.Parent = Screen
uiCorner(Main, 20)
uiOutline(Main, Theme.cyan, .55, 1)

local scale = Instance.new("UIScale")
scale.Parent = Main
local function resizeUI()
    local cameraUI = workspace.CurrentCamera
    if not cameraUI then return end
    scale.Scale = math.clamp(math.min((cameraUI.ViewportSize.X - 20) / 980, (cameraUI.ViewportSize.Y - 35) / 600), .58, 1)
end
resizeUI()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeUI)
end

local background = Instance.new("Frame")
background.BackgroundColor3 = Theme.panel
background.BackgroundTransparency = 0.18
background.Size = UDim2.new(1, 0, 1, 0)
background.ClipsDescendants = true
background.Parent = Main
uiCorner(background, 20)

-- UI background image
local backgroundImage = Instance.new("ImageLabel")
backgroundImage.Name = "UIBackgroundImage"
backgroundImage.BackgroundTransparency = 1
backgroundImage.Size = UDim2.new(1, 0, 1, 0)
backgroundImage.Position = UDim2.new(0, 0, 0, 0)
backgroundImage.Image = "rbxassetid://125604291892229"
backgroundImage.ImageTransparency = 0
backgroundImage.ScaleType = Enum.ScaleType.Crop
backgroundImage.ZIndex = 0
backgroundImage.Parent = background
local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 24, 34)),
    ColorSequenceKeypoint.new(.55, Color3.fromRGB(3, 6, 18)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 4, 34))
})
bgGradient.Rotation = 25
bgGradient.Parent = background

local Header = Instance.new("Frame")
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 74)
Header.Parent = Main

local logo = Instance.new("Frame")
logo.BackgroundColor3 = Theme.cyanDark
logo.Position = UDim2.new(0, 18, 0, 12)
logo.Size = UDim2.new(0, 48, 0, 48)
logo.Parent = Header
uiCorner(logo, 14)
uiOutline(logo, Theme.cyan, .15, 1)
local logoText = uiLabel(logo, "X", 18, true)
logoText.TextXAlignment = Enum.TextXAlignment.Center
logoText.TextYAlignment = Enum.TextYAlignment.Center
logoText.Size = UDim2.new(1, 0, 1, 0)

local eyebrow = uiLabel(Header, "PRODIGY", 8, true)
eyebrow.TextColor3 = Theme.purple
eyebrow.Position = UDim2.new(0, 80, 0, 14)
eyebrow.Size = UDim2.new(0, 420, 0, 13)
local title = uiLabel(Header, "Prodigy", 26, true)
title.Position = UDim2.new(0, 80, 0, 25)
title.Size = UDim2.new(0, 300, 0, 25)
local subtitle = uiLabel(Header, "The Best", 8, false)
subtitle.TextColor3 = Theme.muted
subtitle.Position = UDim2.new(0, 80, 0, 48)
subtitle.Size = UDim2.new(0, 300, 0, 14)

local function headerControl(symbol, x)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Text = symbol
    b.TextColor3 = Theme.text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.BackgroundColor3 = Theme.card
    b.Position = UDim2.new(1, x, 0, 27)
    b.Size = UDim2.new(0, 30, 0, 30)
    b.Parent = Header
    uiCorner(b, 8)
    uiOutline(b, Theme.line, .6, 1)
    return b
end
local closeButton = headerControl("×", -42)
local minimizeButton = headerControl("—", -78)

local divider = Instance.new("Frame")
divider.BackgroundColor3 = Theme.line
divider.BackgroundTransparency = .35
divider.Position = UDim2.new(0, 18, 0, 73)
divider.Size = UDim2.new(1, -36, 0, 1)
divider.Parent = Header

local Content = Instance.new("Frame")
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 18, 0, 86)
Content.Size = UDim2.new(1, -36, 1, -104)
Content.Parent = Main

local function makeCard(parent, titleText, description, position, size)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = Theme.panel2
    card.Position = position
    card.Size = size
    card.Parent = parent
    uiCorner(card, 14)
    uiOutline(card, Theme.line, .4, 1)
    local head = uiLabel(card, titleText, 13, true)
    head.Position = UDim2.new(0, 16, 0, 14)
    head.Size = UDim2.new(1, -32, 0, 20)
    local desc = uiLabel(card, description, 9, false)
    desc.TextColor3 = Theme.muted
    desc.Position = UDim2.new(0, 16, 0, 33)
    desc.Size = UDim2.new(1, -32, 0, 15)
    local line = Instance.new("Frame")
    line.BackgroundColor3 = Theme.line
    line.BackgroundTransparency = .5
    line.Position = UDim2.new(0, 14, 0, 57)
    line.Size = UDim2.new(1, -28, 0, 1)
    line.Parent = card
    local body = Instance.new("ScrollingFrame")
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.Position = UDim2.new(0, 8, 0, 66)
    body.Size = UDim2.new(1, -16, 1, -74)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.CanvasSize = UDim2.new()
    body.ScrollBarThickness = 3
    body.ScrollBarImageColor3 = Theme.cyan
    body.Parent = card
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = body
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = body
    return card, body
end

local function makeRow(parent, height)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Theme.card
    row.Size = UDim2.new(1, 0, 0, height or 48)
    row.Parent = parent
    uiCorner(row, 6)
    uiOutline(row, Theme.line, .55, 1)
    return row
end

local function addToggle(parent, titleText, defaultValue, callback)
    local row = makeRow(parent, 48)
    local t = uiLabel(row, titleText, 11, true)
    t.Position = UDim2.new(0, 13, 0, 0)
    t.Size = UDim2.new(1, -82, 1, 0)
    local value = defaultValue == true
    local switch = Instance.new("TextButton")
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.BackgroundColor3 = Color3.fromRGB(2, 28, 38)
    switch.Position = UDim2.new(1, -60, .5, -12)
    switch.Size = UDim2.new(0, 47, 0, 24)
    switch.Parent = row
    uiCorner(switch, 15)
    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Theme.muted
    knob.Position = UDim2.new(0, 3, .5, -9)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Parent = switch
    uiCorner(knob, 20)
    local function render()
        switch.BackgroundColor3 = value and Theme.cyan or Color3.fromRGB(2, 28, 38)
        knob.Position = value and UDim2.new(1, -21, .5, -9) or UDim2.new(0, 3, .5, -9)
        knob.BackgroundColor3 = value and Color3.new(1, 1, 1) or Theme.muted
    end
    render()
    switch.MouseButton1Click:Connect(function()
        value = not value
        render()
        local ok, err = pcall(callback, value)
        if not ok then notifyUI("Prodigy", tostring(err), 3) end
    end)
    return function(newValue)
        if newValue ~= nil then value = newValue == true; render() end
        return value
    end
end

local function addInput(parent, titleText, defaultText, placeholder, callback)
    local row = makeRow(parent, 58)
    local t = uiLabel(row, titleText, 10, true)
    t.TextColor3 = Theme.muted
    t.Position = UDim2.new(0, 13, 0, 6)
    t.Size = UDim2.new(1, -26, 0, 16)
    local box = Instance.new("TextBox")
    box.ClearTextOnFocus = false
    box.Text = tostring(defaultText or "")
    box.PlaceholderText = placeholder or ""
    box.TextColor3 = Theme.text
    box.PlaceholderColor3 = Theme.muted
    box.Font = Enum.Font.GothamBold
    box.TextSize = 10
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.BackgroundColor3 = Color3.fromRGB(0, 10, 20)
    box.Position = UDim2.new(0, 12, 0, 27)
    box.Size = UDim2.new(1, -24, 0, 22)
    box.Parent = row
    uiCorner(box, 7)
    uiOutline(box, Theme.cyan, .78, 1)
    box.FocusLost:Connect(function()
        local ok, err = pcall(callback, box.Text)
        if not ok then notifyUI("Prodigy", tostring(err), 3) end
    end)
    return box
end

local function addDropdown(parent, titleText, options, default, callback)
    local row = makeRow(parent, 54)
    local t = uiLabel(row, titleText, 10, true)
    t.TextColor3 = Theme.muted
    t.Position = UDim2.new(0, 14, 0, 6)
    t.Size = UDim2.new(1, -28, 0, 16)
    local index = table.find(options, default) or 1
    local valueBox = Instance.new("Frame")
    valueBox.BackgroundColor3 = Color3.fromRGB(0, 10, 20)
    valueBox.Position = UDim2.new(0, 12, 0, 26)
    valueBox.Size = UDim2.new(1, -24, 0, 22)
    valueBox.Parent = row
    uiCorner(valueBox, 7)
    uiOutline(valueBox, Theme.cyan, .78, 1)
    local selectedLabel = uiLabel(valueBox, tostring(options[index]), 9, true)
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Center
    selectedLabel.Size = UDim2.new(1, -54, 1, 0)
    selectedLabel.Position = UDim2.new(0, 27, 0, 0)
    local function arrow(symbol, x)
        local b = Instance.new("TextButton")
        b.AutoButtonColor = false
        b.Text = symbol
        b.TextColor3 = Theme.purple
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.BackgroundTransparency = 1
        b.Position = UDim2.new(x, 0, 0, 0)
        b.Size = UDim2.new(0, 27, 1, 0)
        b.Parent = valueBox
        return b
    end
    local left = arrow("‹", 0)
    local right = arrow("›", 1)
    right.AnchorPoint = Vector2.new(1, 0)
    local function render()
        selectedLabel.Text = tostring(options[index])
        pcall(callback, options[index])
    end
    left.MouseButton1Click:Connect(function()
        index -= 1
        if index < 1 then index = #options end
        render()
    end)
    right.MouseButton1Click:Connect(function()
        index += 1
        if index > #options then index = 1 end
        render()
    end)
    return function() return options[index] end
end

local function addButton(parent, titleText, callback)
    local row = makeRow(parent, 48)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Text = ""
    b.Size = UDim2.new(1, 0, 1, 0)
    b.BackgroundTransparency = 1
    b.Parent = row
    local t = uiLabel(b, titleText, 11, true)
    t.Position = UDim2.new(0, 13, 0, 0)
    t.Size = UDim2.new(1, -62, 1, 0)
    local arrow = uiLabel(b, "→", 17, true)
    arrow.TextColor3 = Theme.purple
    arrow.TextXAlignment = Enum.TextXAlignment.Center
    arrow.Position = UDim2.new(1, -45, 0, 0)
    arrow.Size = UDim2.new(0, 30, 1, 0)
    b.MouseEnter:Connect(function() uiTween(row, .15, {BackgroundColor3 = Theme.cardHover}):Play() end)
    b.MouseLeave:Connect(function() uiTween(row, .15, {BackgroundColor3 = Theme.card}):Play() end)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then notifyUI("Prodigy", tostring(err), 3) end
    end)
end

local NavWidth = 174

local Main = Main 
Main.Size = UDim2.new(0, 980, 0, 600)
Main.Position = UDim2.new(.5, 0, .5, 18)
resizeUI()

Content:ClearAllChildren()
Content.Position = UDim2.new(0, 16, 0, 78)
Content.Size = UDim2.new(1, -32, 1, -92)

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.BackgroundColor3 = Color3.fromRGB(3, 8, 16)
Sidebar.Size = UDim2.new(0, NavWidth, 1, 0)
Sidebar.Parent = Content
uiCorner(Sidebar, 14)
uiOutline(Sidebar, Theme.line, .58, 1)

local sideTitle = uiLabel(Sidebar, "PRODIGY", 13, true)
sideTitle.TextColor3 = Theme.cyan
sideTitle.Position = UDim2.new(0, 16, 0, 15)
sideTitle.Size = UDim2.new(1, -32, 0, 18)

local sideSub = uiLabel(Sidebar, "FEATURE HUB", 7, true)
sideSub.TextColor3 = Theme.muted
sideSub.Position = UDim2.new(0, 16, 0, 34)
sideSub.Size = UDim2.new(1, -32, 0, 12)

local sideLine = Instance.new("Frame")
sideLine.BackgroundColor3 = Theme.line
sideLine.BackgroundTransparency = .75
sideLine.Position = UDim2.new(0, 14, 0, 54)
sideLine.Size = UDim2.new(1, -28, 0, 1)
sideLine.Parent = Sidebar

local NavList = Instance.new("ScrollingFrame")
NavList.Name = "Navigation"
NavList.BackgroundTransparency = 1
NavList.BorderSizePixel = 0
NavList.Position = UDim2.new(0, 9, 0, 64)
NavList.Size = UDim2.new(1, -18, 1, -73)
NavList.AutomaticCanvasSize = Enum.AutomaticSize.Y
NavList.CanvasSize = UDim2.new()
NavList.ScrollBarThickness = 0
NavList.Parent = Sidebar
local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 5)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = NavList

local Pages = Instance.new("Frame")
Pages.Name = "Pages"
Pages.BackgroundTransparency = 1
Pages.Position = UDim2.new(0, NavWidth + 12, 0, 0)
Pages.Size = UDim2.new(1, -(NavWidth + 12), 1, 0)
Pages.Parent = Content

local pageFrames = {}
local navButtons = {}
local currentPage

local function makePage(id, titleText)
    local page = Instance.new("ScrollingFrame")
    page.Name = id .. "Page"
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Size = UDim2.new(1, 0, 1, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new()
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.cyan
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.Visible = false
    page.Parent = Pages

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 3)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    pageFrames[id] = page
    return page
end

local function pageCard(parent, titleText, descText)
    local card = Instance.new("Frame")
    card.BackgroundColor3 = Theme.panel2
    card.Size = UDim2.new(1, -2, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Parent = parent
    uiCorner(card, 12)
    uiOutline(card, Theme.line, .55, 1)

    local header = Instance.new("Frame")
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 49)
    header.Parent = card

    local titleLabel = uiLabel(header, titleText, 11, true)
    titleLabel.Position = UDim2.new(0, 14, 0, 10)
    titleLabel.Size = UDim2.new(1, -28, 0, 17)

    local descLabel = uiLabel(header, descText or "", 7, false)
    descLabel.TextColor3 = Theme.muted
    descLabel.Position = UDim2.new(0, 14, 0, 28)
    descLabel.Size = UDim2.new(1, -28, 0, 12)

    local line = Instance.new("Frame")
    line.BackgroundColor3 = Theme.line
    line.BackgroundTransparency = .78
    line.Position = UDim2.new(0, 13, 1, -1)
    line.Size = UDim2.new(1, -26, 0, 1)
    line.Parent = header

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundTransparency = 1
    body.Position = UDim2.new(0, 9, 0, 49)
    body.Size = UDim2.new(1, -18, 0, 0)
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Parent = card

    local bodyPad = Instance.new("UIPadding")
    bodyPad.PaddingBottom = UDim.new(0, 9)
    bodyPad.Parent = body

    local bodyLayout = Instance.new("UIListLayout")
    bodyLayout.Padding = UDim.new(0, 5)
    bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bodyLayout.Parent = body

    return card, body
end

local function makeRow(parent, height)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = Theme.card
    row.Size = UDim2.new(1, 0, 0, height or 44)
    row.Parent = parent
    uiCorner(row, 8)
    uiOutline(row, Theme.line, .76, 1)
    return row
end

local function addToggle(parent, titleText, defaultValue, callback)
    local row = makeRow(parent, 44)
    local t = uiLabel(row, titleText, 10, true)
    t.Position = UDim2.new(0, 13, 0, 0)
    t.Size = UDim2.new(1, -82, 1, 0)

    local value = defaultValue == true
    local switch = Instance.new("TextButton")
    switch.Name = "Toggle"
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.BackgroundColor3 = Color3.fromRGB(4, 25, 36)
    switch.Position = UDim2.new(1, -57, .5, -11)
    switch.Size = UDim2.new(0, 44, 0, 22)
    switch.Parent = row
    uiCorner(switch, 14)
    uiOutline(switch, Theme.line, .78, 1)

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Theme.muted
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Parent = switch
    uiCorner(knob, 20)

    local function render()
        switch.BackgroundColor3 = value and Theme.cyan or Color3.fromRGB(4, 25, 36)
        knob.Position = value and UDim2.new(1, -19, .5, -8) or UDim2.new(0, 3, .5, -8)
        knob.BackgroundColor3 = value and Color3.new(1, 1, 1) or Theme.muted
    end
    render()

    switch.MouseButton1Click:Connect(function()
        value = not value
        render()
        local ok, err = pcall(callback, value)
        if not ok then notifyUI("Prodigy", tostring(err), 3) end
    end)
    return function(newValue)
        if newValue ~= nil then value = newValue == true; render() end
        return value
    end
end

local function addInput(parent, titleText, defaultText, placeholder, callback)
    local row = makeRow(parent, 56)
    local t = uiLabel(row, titleText, 9, true)
    t.TextColor3 = Theme.muted
    t.Position = UDim2.new(0, 13, 0, 5)
    t.Size = UDim2.new(1, -26, 0, 14)

    local box = Instance.new("TextBox")
    box.ClearTextOnFocus = false
    box.Text = tostring(defaultText or "")
    box.PlaceholderText = placeholder or ""
    box.TextColor3 = Theme.text
    box.PlaceholderColor3 = Theme.muted
    box.Font = Enum.Font.GothamBold
    box.TextSize = 9
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.BackgroundColor3 = Color3.fromRGB(1, 8, 15)
    box.Position = UDim2.new(0, 11, 0, 25)
    box.Size = UDim2.new(1, -22, 0, 23)
    box.Parent = row
    uiCorner(box, 7)
    uiOutline(box, Theme.line, .7, 1)
    box.FocusLost:Connect(function()
        local ok, err = pcall(callback, box.Text)
        if not ok then notifyUI("Prodigy", tostring(err), 3) end
    end)
    return box
end

local function addButton(parent, titleText, callback)
    local row = makeRow(parent, 44)
    local b = Instance.new("TextButton")
-- Draggable floating icon: supports mouse and mobile touch.
do
    local UIS = game:GetService("UserInputService")
    local dragging = false
    local dragStart
    local startPos
    local dragInput

    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = b.Position
            dragInput = input

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    b.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then return end
        local delta = input.Position - dragStart
        b.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
end

    b.AutoButtonColor = false
    b.Text = ""
    b.Size = UDim2.new(1, 0, 1, 0)
    b.BackgroundTransparency = 1
    b.Parent = row
    local t = uiLabel(b, titleText, 10, true)
    t.Position = UDim2.new(0, 13, 0, 0)
    t.Size = UDim2.new(1, -55, 1, 0)
    local arrow = uiLabel(b, "›", 18, true)
    arrow.TextColor3 = Theme.cyan
    arrow.TextXAlignment = Enum.TextXAlignment.Center
    arrow.Position = UDim2.new(1, -38, 0, 0)
    arrow.Size = UDim2.new(0, 28, 1, 0)
    b.MouseEnter:Connect(function() uiTween(row, .12, {BackgroundColor3 = Theme.cardHover}):Play() end)
    b.MouseLeave:Connect(function() uiTween(row, .12, {BackgroundColor3 = Theme.card}):Play() end)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then notifyUI("Prodigy", tostring(err), 3) end
    end)
end


-- ============================================================

local Home = makePage("Home", "Home")
local Aim = makePage("Aim", "Aim")
local BlacklistPage = makePage("Blacklist", "Blacklist")
local ESPPage = makePage("ESP", "ESP")
local Movement = makePage("Movement", "Movement")
local PlayersPage = makePage("Players", "Players")
local Misc = makePage("Misc", "Misc")
local ConfigPage = makePage("Config", "Config")

local function navItem(id, icon, text, order)
    local b = Instance.new("TextButton")
    b.Name = id .. "Nav"
    b.Text = ""
    b.AutoButtonColor = false
    b.BackgroundColor3 = Color3.fromRGB(4, 12, 22)
    b.Size = UDim2.new(1, 0, 0, 41)
    b.LayoutOrder = order or 1
    b.Parent = NavList
    uiCorner(b, 9)
    uiOutline(b, Theme.line, .88, 1)

    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = Theme.cyan
    accent.BackgroundTransparency = 1
    accent.Position = UDim2.new(0, 0, 0, 8)
    accent.Size = UDim2.new(0, 3, 1, -16)
    accent.Parent = b
    uiCorner(accent, 3)

    local iconLabel = uiLabel(b, icon, 13, true)
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.Size = UDim2.new(0, 32, 1, 0)
    iconLabel.Position = UDim2.new(0, 5, 0, 0)

    local textLabel = uiLabel(b, text, 9, true)
    textLabel.Position = UDim2.new(0, 40, 0, 0)
    textLabel.Size = UDim2.new(1, -47, 1, 0)

    navButtons[id] = b
    b:SetAttribute("AccentObject", true)
    return b, accent
end

local navAccents = {}
local function bindNav(id, icon, text, order)
    local b, accent = navItem(id, icon, text, order)
    navAccents[id] = accent
    b.MouseButton1Click:Connect(function()
        for pageId, page in pairs(pageFrames) do page.Visible = (pageId == id) end
        for pageId, button in pairs(navButtons) do
            local active = pageId == id
            button.BackgroundColor3 = active and Color3.fromRGB(0, 48, 82) or Color3.fromRGB(4, 12, 22)
            local stroke = button:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = active and Theme.cyan or Theme.line; stroke.Transparency = active and .25 or .88 end
            if navAccents[pageId] then navAccents[pageId].BackgroundTransparency = active and .05 or 1 end
            for _, child in ipairs(button:GetChildren()) do
                if child:IsA("TextLabel") then child.TextColor3 = active and Color3.fromRGB(245,250,255) or Theme.text end
            end
        end
        currentPage = id
    end)
end

bindNav("Home", "", "Home", 1)
bindNav("Aim", "", "Aim", 2)
bindNav("Blacklist", "", "Blacklist", 3)
bindNav("ESP", "", "ESP", 4)
bindNav("Movement", "", "Movement", 5)
bindNav("Players", "", "Players", 6)
bindNav("Misc", "", "Misc", 8)
bindNav("Config", "", "Settings", 9)

local function showPage(id)
    for pageId, page in pairs(pageFrames) do page.Visible = pageId == id end
    for pageId, button in pairs(navButtons) do
        local active = pageId == id
        button.BackgroundColor3 = active and Color3.fromRGB(0, 48, 82) or Color3.fromRGB(4, 12, 22)
        local stroke = button:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = active and Theme.cyan or Theme.line; stroke.Transparency = active and .25 or .88 end
        if navAccents[pageId] then navAccents[pageId].BackgroundTransparency = active and .05 or 1 end
        for _, child in ipairs(button:GetChildren()) do
            if child:IsA("TextLabel") then child.TextColor3 = active and Color3.fromRGB(245,250,255) or Theme.text end
        end
    end
    currentPage = id
end

local activeModules = {}
local activeCount
local function setModule(name, value)
    activeModules[name] = value == true
    if activeCount then
        local count = 0
        for _, v in pairs(activeModules) do if v then count += 1 end end
        activeCount.Text = string.format("%d active features", count)
    end
end

local function toggleIn(parent, name, default, fn, moduleName)
    local key = moduleName or name
    local refresh = addToggle(parent, name, default, function(v)
        fn(v)
        setModule(key, v)
        pcall(SaveConfig)
    end)
    ToggleRegistryMap[key] = refresh
    setModule(key, default == true)
    return refresh
end

local function refreshToggle(key, value)
    local refresh = ToggleRegistryMap[key]
    if refresh then refresh(value == true) end
    setModule(key, value == true)
end

local homeCard, homeBody = pageCard(Home, "HOME", "Live status")
local homeStatus = uiLabel(homeBody, "READY", 16, true)
homeStatus.TextColor3 = Theme.cyan
homeStatus.Size = UDim2.new(1, 0, 0, 23)
activeCount = uiLabel(homeBody, "0 active features", 10, true)
activeCount.TextColor3 = Theme.text
activeCount.Size = UDim2.new(1, 0, 0, 18)

local homeInfo = uiLabel(homeBody, "Use the sidebar to open one section at a time. Changes save automatically.", 8, false)
homeInfo.TextColor3 = Theme.muted
homeInfo.TextWrapped = true
homeInfo.Size = UDim2.new(1, 0, 0, 30)

local aimCard, aimBody = pageCard(Aim, "TARGETING", "Target selection and prediction")
toggleIn(aimBody, "Silent Aim", _G.G_SilentAimSkill, function(v)
    
    _G.G_SilentAim360 = true
    SetSilentAim(v)
end)
toggleIn(aimBody, "Target Players", _G.G_SilentAimTargetPlayers, function(v) SetSilentAimTargets(v, nil) end)
toggleIn(aimBody, "Target NPCs", _G.G_SilentAimTargetMobs, function(v) SetSilentAimTargets(nil, v) end)
toggleIn(aimBody, "Gun Auto Fire", _G.G_SilentAimGunAutoFire, function(v) _G.G_SilentAimGunAutoFire = v == true; pcall(SaveConfig) end)
toggleIn(aimBody, "Gun M1 Silent Aim", _G.G_GunM1SilentAim, function(v)
    _G.G_GunM1SilentAim = v == true
    pcall(SaveConfig)
end)
toggleIn(aimBody, "Dragon Gun M1", _G.G_DragonGunM1, function(v)
    _G.G_DragonGunM1 = v == true
    if _G.G_DragonGunM1 then
        task.spawn(InitDragonGun)
    end
    pcall(SaveConfig)
end)
toggleIn(aimBody, "Team Check", _G.G_SilentAimTeamCheck, function(v) SetTeamCheck(v) end)
toggleIn(aimBody, "Auto Prediction", _G.G_AutoPrediction, function(v) _G.G_AutoPrediction = v end)
toggleIn(aimBody, "Max Accuracy", _G.G_MaxAccuracyMode, function(v) SetMaxAccuracyMode(v) end)
toggleIn(aimBody, "Auto Buddy X 100% • Auto Fires", _G.G_BuddyXMode == "Auto", function(v)
    if v then SetBuddyXMode("Auto") else SetBuddyXMode("Off") end
end)
toggleIn(aimBody, "Manual Buddy X 100% • Use X Move", _G.G_BuddyXMode == "Manual", function(v)
    if v then SetBuddyXMode("Manual") else SetBuddyXMode("Off") end
end)
local warning = uiLabel(aimBody, "⚠ Max Accuracy is an experimental precision mode.", 8, true)
warning.TextColor3 = Color3.fromRGB(255, 150, 90)
warning.Size = UDim2.new(1, 0, 0, 17)
addInput(aimBody, "Max Distance", maxRange, "0-4250 studs", function(v)
    local n = tonumber(v); if n then SetAimbotMaxDistance(n) end
end)
local targetModeRow = Instance.new("Frame")
targetModeRow.BackgroundTransparency = 1
targetModeRow.Size = UDim2.new(1, 0, 0, 34)
targetModeRow.Parent = aimBody
local targetModeLabel = uiLabel(targetModeRow, "Target Mode", 9, true)
targetModeLabel.Size = UDim2.new(0, 90, 1, 0)
local targetModeButton = Instance.new("TextButton")
targetModeButton.AutoButtonColor = false
targetModeButton.Text = SilentAimTargetMode
targetModeButton.Font = Enum.Font.GothamBold
targetModeButton.TextSize = 9
targetModeButton.TextColor3 = Theme.text
targetModeButton.BackgroundColor3 = Color3.fromRGB(1, 8, 15)
targetModeButton.Size = UDim2.new(0, 150, 0, 26)
targetModeButton.Position = UDim2.new(1, -154, 0, 4)
targetModeButton.Parent = targetModeRow
uiCorner(targetModeButton, 7)
uiOutline(targetModeButton, Theme.line, .7, 1)
targetModeButton.MouseButton1Click:Connect(function()
    SilentAimTargetMode = (SilentAimTargetMode == "Nearest") and "Lowest Health" or "Nearest"
    targetModeButton.Text = SilentAimTargetMode
    pcall(SaveConfig)
end)
toggleIn(aimBody, "Show Aim Line", _G.G_SilentAimShowLine, function(v) _G.G_SilentAimShowLine = v end)

local blacklistIntroCard, blacklistIntroBody = pageCard(BlacklistPage, "BLACKLIST", "Attack filters")
local blacklistIntro = uiLabel(blacklistIntroBody, "Select the attack slots Silent Aim should ignore. Settings save automatically and work on PC + mobile.", 8, false)
blacklistIntro.TextColor3 = Theme.muted
blacklistIntro.TextWrapped = true
blacklistIntro.Size = UDim2.new(1, 0, 0, 30)

local blacklistCard, blacklistBody = pageCard(BlacklistPage, "MOVE BLACKLIST", "Choose exactly which attacks Silent Aim should ignore")
local blacklistHint = uiLabel(blacklistBody, "Works with PC + mobile. M1 uses the weapon's LeftClickRemote; shared FireServer(true) ability calls are never guessed as M1.", 8, false)
blacklistHint.TextColor3 = Theme.muted
blacklistHint.TextWrapped = true
blacklistHint.Size = UDim2.new(1, 0, 0, 32)

local function addMoveBlacklistSection(category)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 34)
    row.Parent = blacklistBody
    local label = uiLabel(row, category, 10, true)
    label.Position = UDim2.new(0, 4, 0, 0)
    label.Size = UDim2.new(0, 70, 1, 0)
    local moves = BLACKLIST_MOVES_BY_CATEGORY[category] or {}
    for i, move in ipairs(moves) do
        local b = Instance.new("TextButton")
        b.AutoButtonColor = false
        b.Text = move
        b.Font = Enum.Font.GothamBold
        b.TextSize = 8
        b.TextColor3 = Theme.text
        b.BackgroundColor3 = Color3.fromRGB(4, 12, 22)
        b.Size = UDim2.new(0, 34, 0, 26)
        b.Position = UDim2.new(0, 72 + (i - 1) * 38, 0, 4)
        b.Parent = row
        uiCorner(b, 7)
        uiOutline(b, Theme.line, .65, 1)
        local key = "G_Blacklist_" .. category .. "_" .. move
        local function render()
            local on = _G[key] == true
            b.BackgroundColor3 = on and Theme.cyan or Color3.fromRGB(4, 12, 22)
            b.TextColor3 = on and Color3.new(1,1,1) or Theme.text
            local stroke = b:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = on and Theme.cyan or Theme.line; stroke.Transparency = on and .15 or .65 end
        end
        render()
        b.MouseButton1Click:Connect(function()
            _G[key] = not (_G[key] == true)
            render()
            pcall(SaveConfig)
        end)
    end
end
for _, category in ipairs(BLACKLIST_CATEGORIES) do addMoveBlacklistSection(category) end

_G.G_DynamicSkillMap = _G.G_DynamicSkillMap or {}

pcall(function()
    local events = ReplicatedStorage:FindFirstChild("Events")
    local ev = events and events:FindFirstChild("ActivatedSkill")
    if ev and ev:IsA("BindableEvent") then
        ev.Event:Connect(function(skillName, skillKey)
            local k = normalizeSkillKey(skillKey)
            if k and typeof(skillName) == "string" and skillName ~= "" then
                _G.G_DynamicSkillMap[skillName] = {name = skillName, key = k}
            end
        end)
    end
end)

toggleIn(aimBody, "Safe Zone Check", _G.G_AimbotSafeZoneCheck, function(v) _G.G_AimbotSafeZoneCheck = v end)
toggleIn(aimBody, "PvP Check", _G.G_AimbotPvPCheck, function(v) _G.G_AimbotPvPCheck = v end)
local aimlockCard, aimlockBody = pageCard(Aim, "AIMLOCK", "Locking")
toggleIn(aimlockBody, "Aimlock Players", AimlockPlayerEnabled, function(v) PlayerWidgetActive = v; SetAimlockPlayers(v) end)
toggleIn(aimlockBody, "Cam Lock Enable", CamLockFloatingEnabled, function(v)
    CamLockFloatingEnabled = v == true
    refreshCamLockFloatingButton()
    pcall(SaveConfig)
end, "CamLockFloating")
addInput(aimlockBody, "Cam Lock Button Width", CamLockButtonWidth, "60-300", function(v)
    local n = tonumber(v); if n then CamLockButtonWidth = math.clamp(n, 60, 300); if CamLockFloatingEnabled then createCamLockFloatingButton() end; pcall(SaveConfig) end
end)
addInput(aimlockBody, "Cam Lock Button Height", CamLockButtonHeight, "28-120", function(v)
    local n = tonumber(v); if n then CamLockButtonHeight = math.clamp(n, 28, 120); if CamLockFloatingEnabled then createCamLockFloatingButton() end; pcall(SaveConfig) end
end)
toggleIn(aimlockBody, "Aimlock NPCs", AimlockNpcEnabled, function(v) NpcWidgetActive = v; SetAimlockNPCs(v) end)
toggleIn(aimlockBody, "Soru Aimbot", SoruAimbotEnabled, function(v) SetSoruAimbot(v) end)
toggleIn(aimlockBody, "PvP Check", _G.G_AimbotPvPCheck, function(v) _G.G_AimbotPvPCheck = v end)

local combatCard, combatBody = pageCard(Movement, "COMBAT", "Attack")
toggleIn(combatBody, "Fast Attack", FastAttackEnabled, function(v) SetFastAttack(v) end)
local movementCard, movementBody = pageCard(Movement, "MOVEMENT", "Character movement")
toggleIn(movementBody, "Walk Speed", WalkSpeedEnabled, function(v) SetWalkSpeed(v, WalkSpeedValue) end)
addInput(movementBody, "Walk Speed Value", WalkSpeedValue, "16-120", function(v)
    local n = tonumber(v); if n then SetWalkSpeed(WalkSpeedEnabled, n) end
end)
toggleIn(movementBody, "Noclip", NoclipEnabled, function(v) SetNoclip(v) end)
toggleIn(movementBody, "Walk On Water", WalkOnWaterEnabled, function(v) SetWalkOnWater(v) end)
toggleIn(movementBody, "Smart Auto V4", SmartAutoV4Enabled, function(v) SetSmartAutoV4(v) end)
toggleIn(movementBody, "Auto V4", AutoV4Enabled, function(v) SetAutoV4(v) end)

local espCard, espBody = pageCard(ESPPage, "ESP", "Single fixed format")
toggleIn(espBody, "ESP Enabled", _G.G_ESPEnabled, function(v) SetESP(v) end, "ESP")
local espFormat = uiLabel(espBody, "NAME  •  LEVEL\nFRUIT  •  DISTANCE  •  HP  •  PVP", 9, true)
espFormat.TextColor3 = Theme.cyan
espFormat.TextWrapped = true
espFormat.Size = UDim2.new(1, 0, 0, 32)
addInput(espBody, "Text Size", _G.G_ESP_TextSize, "8-24", function(v)
    local n = tonumber(v); if n then _G.G_ESP_TextSize = math.clamp(n, 8, 24); pcall(SaveConfig) end
end)

local filterCard = pageCard(PlayersPage, "PLAYERS", "Exclude or restore players")
local playerFilterList = Instance.new("Frame")
playerFilterList.BackgroundTransparency = 1
playerFilterList.Size = UDim2.new(1, 0, 0, 0)
playerFilterList.AutomaticSize = Enum.AutomaticSize.Y
playerFilterList.Parent = filterCard:FindFirstChild("Body")
local playerFilterLayout = Instance.new("UIListLayout")
playerFilterLayout.Padding = UDim.new(0, 5)
playerFilterLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerFilterLayout.Parent = playerFilterList

local function refreshPlayerFilterList()
    for _, child in ipairs(playerFilterList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local currentPlayers = Players:GetPlayers()
    table.sort(currentPlayers, function(a, b) return a.Name:lower() < b.Name:lower() end)
    for _, targetP in ipairs(currentPlayers) do
        if targetP ~= player then
            local row = makeRow(playerFilterList, 40)
            row.Name = "Player_" .. targetP.UserId
            local nameLabel = uiLabel(row, targetP.Name, 9, true)
            nameLabel.Position = UDim2.new(0, 11, 0, 0)
            nameLabel.Size = UDim2.new(1, -105, 1, 0)
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            local excluded = BlacklistedPlayers[targetP.Name] == true
            local excludeButton = Instance.new("TextButton")
            excludeButton.AutoButtonColor = false
            excludeButton.Text = excluded and "RESTORE" or "EXCLUDE"
            excludeButton.Font = Enum.Font.GothamBold
            excludeButton.TextSize = 8
            excludeButton.TextColor3 = excluded and Theme.cyan or Theme.text
            excludeButton.BackgroundColor3 = excluded and Color3.fromRGB(4, 32, 42) or Color3.fromRGB(0, 14, 24)
            excludeButton.Size = UDim2.new(0, 78, 0, 24)
            excludeButton.Position = UDim2.new(1, -88, .5, -12)
            excludeButton.Parent = row
            uiCorner(excludeButton, 7)
            uiOutline(excludeButton, excluded and Theme.cyan or Theme.line, .62, 1)
            excludeButton.MouseButton1Click:Connect(function()
                SetPlayerBlacklist(targetP.Name, not BlacklistedPlayers[targetP.Name])
                refreshPlayerFilterList()
            end)
        end
    end
end
refreshPlayerFilterList()
Players.PlayerAdded:Connect(refreshPlayerFilterList)
Players.PlayerRemoving:Connect(function(targetP)
    BlacklistedPlayers[targetP.Name] = nil
    refreshPlayerFilterList()
end)

local miscCard, miscBody = pageCard(Misc, "UTILITY", "Utilities")
toggleIn(miscBody, "Anti Lava", antiLavaActive, function(v) SetAntiLava(v) end)
toggleIn(miscBody, "FPS Boost Mode", FPSBoostEnabled, function(v) SetFPSBoost(v) end)
toggleIn(miscBody, "Soul Guitar Jump", SoulGuitarJumpEnabled, function(v) SetSoulGuitar(v, SoulGuitarDashLength) end)
addInput(miscBody, "Soul Guitar Dash", SoulGuitarDashLength, "distance", function(v)
    local n = tonumber(v); if n then SoulGuitarDashLength = n; SetSoulGuitar(SoulGuitarJumpEnabled, n); pcall(SaveConfig) end
end)



-- ============================================================
if CamLockFloatingEnabled then
    task.defer(createCamLockFloatingButton)
end

local uiButtonCard, uiButtonBody = pageCard(ConfigPage, "FLOATING UI BUTTONS", "Placement and interaction")
local uiModeRow = makeRow(uiButtonBody, 44)
local uiModeLabel = uiLabel(uiModeRow, "UI Button Mode", 9, true)
uiModeLabel.TextColor3 = Theme.muted
uiModeLabel.Position = UDim2.new(0, 13, 0, 0)
uiModeLabel.Size = UDim2.new(0.55, 0, 1, 0)
local uiModeButton = Instance.new("TextButton")
uiModeButton.Text = UIButtonMode
uiModeButton.Font = Enum.Font.GothamBold
uiModeButton.TextSize = 9
uiModeButton.TextColor3 = Theme.text
uiModeButton.BackgroundColor3 = Color3.fromRGB(1, 8, 15)
uiModeButton.Size = UDim2.new(0, 100, 0, 24)
uiModeButton.Position = UDim2.new(1, -112, .5, -12)
uiModeButton.Parent = uiModeRow
uiCorner(uiModeButton, 7)
uiOutline(uiModeButton, Theme.line, .7, 1)
uiModeButton.MouseButton1Click:Connect(function()
    UIButtonMode = (UIButtonMode == "Use") and "Move" or "Use"
    uiModeButton.Text = UIButtonMode
    pcall(SaveConfig)
end)

local lockAllRefresh = toggleIn(uiButtonBody, "Lock All UI Button Mode", LockAllUIButtons, function(v)
    LockAllUIButtons = v == true
    pcall(SaveConfig)
end, "LockAllUIButtons")

local camXBox = addInput(uiButtonBody, "Cam Lock Position X (0-1)", CamLockButtonX, "0.00-1.00", function(v)
    local n = tonumber(v); if n then CamLockButtonX = math.clamp(n, 0, 1); if CamLockFloatingEnabled and CamLockFloatingButton then CamLockFloatingButton.Position = UDim2.new(CamLockButtonX,0,CamLockButtonY,0) end; pcall(SaveConfig) end
end)
local camYBox = addInput(uiButtonBody, "Cam Lock Position Y (0-1)", CamLockButtonY, "0.00-1.00", function(v)
    local n = tonumber(v); if n then CamLockButtonY = math.clamp(n, 0, 1); if CamLockFloatingEnabled and CamLockFloatingButton then CamLockFloatingButton.Position = UDim2.new(CamLockButtonX,0,CamLockButtonY,0) end; pcall(SaveConfig) end
end)

local configCard, configBody = pageCard(ConfigPage, "SETTINGS", "Configuration")
addButton(configBody, "Save Configuration", function()
    SaveConfig()
    notifyUI("Configuration", "Saved", 2)
end)
addInput(configBody, "UI Colour", _G.G_UIAccentColor, "RRGGBB", function(v)
    local c = parseHexColor(v)
    if c then ApplyUIAccent(c) end
end)

local textSizeRow = makeRow(configBody, 54)
local textSizeTitle = uiLabel(textSizeRow, "UI Text Size", 10, true)
textSizeTitle.TextColor3 = Theme.muted
textSizeTitle.Position = UDim2.new(0, 13, 0, 6)
textSizeTitle.Size = UDim2.new(1, -26, 0, 16)

local textSizeValue = uiLabel(textSizeRow, "100%", 10, true)
textSizeValue.TextColor3 = Theme.cyan
textSizeValue.TextXAlignment = Enum.TextXAlignment.Center
textSizeValue.Position = UDim2.new(.5, -32, 0, 27)
textSizeValue.Size = UDim2.new(0, 64, 0, 22)

local function refreshUITextSizeValue()
    textSizeValue.Text = tostring(math.floor((_G.G_UITextScale or 1) * 100 + .5)) .. "%"
end
local function changeUITextSize(delta)
    ApplyUITextScale((_G.G_UITextScale or 1) + delta)
    refreshUITextSizeValue()
    pcall(SaveConfig)
end
local textSizeMinus = Instance.new("TextButton")
textSizeMinus.AutoButtonColor = false
textSizeMinus.Text = "-"
textSizeMinus.TextColor3 = Theme.text
textSizeMinus.Font = Enum.Font.GothamBold
textSizeMinus.TextSize = 14
textSizeMinus.BackgroundColor3 = Theme.card
textSizeMinus.Position = UDim2.new(1, -108, 0, 26)
textSizeMinus.Size = UDim2.new(0, 30, 0, 24)
textSizeMinus.Parent = textSizeRow
uiCorner(textSizeMinus, 7)
uiOutline(textSizeMinus, Theme.line, .55, 1)
textSizeMinus.MouseButton1Click:Connect(function() changeUITextSize(-0.1) end)

local textSizePlus = Instance.new("TextButton")
textSizePlus.AutoButtonColor = false
textSizePlus.Text = "+"
textSizePlus.TextColor3 = Theme.text
textSizePlus.Font = Enum.Font.GothamBold
textSizePlus.TextSize = 14
textSizePlus.BackgroundColor3 = Theme.card
textSizePlus.Position = UDim2.new(1, -42, 0, 26)
textSizePlus.Size = UDim2.new(0, 30, 0, 24)
textSizePlus.Parent = textSizeRow
uiCorner(textSizePlus, 7)
uiOutline(textSizePlus, Theme.line, .55, 1)
textSizePlus.MouseButton1Click:Connect(function() changeUITextSize(0.1) end)
refreshUITextSizeValue()

local configNote = uiLabel(configBody, "Your enabled options are stored using the script's existing configuration system.", 8, false)
configNote.TextColor3 = Theme.muted
configNote.TextWrapped = true
configNote.Size = UDim2.new(1, 0, 0, 30)

for key, refresh in pairs(ToggleRegistryMap) do
    local value = nil
    if key == "ESP" then value = _G.G_ESPEnabled
    elseif key == "Silent Aim" then value = _G.G_SilentAimSkill
    elseif key == "Blacklist Fruit M1" then value = _G.G_BlacklistFruitM1
    elseif key == "Target Players" then value = _G.G_SilentAimTargetPlayers
    elseif key == "Target NPCs" then value = _G.G_SilentAimTargetMobs
    elseif key == "Gun Auto Fire" then value = _G.G_SilentAimGunAutoFire
    elseif key == "Team Check" then value = _G.G_SilentAimTeamCheck
    elseif key == "Auto Prediction" then value = _G.G_AutoPrediction
    elseif key == "Max Accuracy" then value = _G.G_MaxAccuracyMode
    elseif key == "Auto Buddy X 100% • Auto Fires" then value = _G.G_BuddyXMode == "Auto"
    elseif key == "Manual Buddy X 100% • Use X Move" then value = _G.G_BuddyXMode == "Manual"
    elseif key == "Show Aim Line" then value = _G.G_SilentAimShowLine
    elseif key == "Safe Zone Check" then value = _G.G_AimbotSafeZoneCheck
    elseif key == "PvP Check" then value = _G.G_AimbotPvPCheck
    elseif key == "Aimlock Players" then value = AimlockPlayerEnabled
    elseif key == "Aimlock NPCs" then value = AimlockNpcEnabled
    elseif key == "Soru Aimbot" then value = SoruAimbotEnabled
    elseif key == "Fast Attack" then value = FastAttackEnabled
    elseif key == "Walk Speed" then value = WalkSpeedEnabled
    elseif key == "Dash Boost" then value = DashEnabled
    elseif key == "Super Jump" then value = SuperJumpEnabled
    elseif key == "Noclip" then value = NoclipEnabled
    elseif key == "Walk On Water" then value = WalkOnWaterEnabled
    elseif key == "Smart Auto V4" then value = SmartAutoV4Enabled
    elseif key == "Auto V4" then value = AutoV4Enabled
    elseif key == "Anti Lava" then value = antiLavaActive
    elseif key == "FPS Boost Mode" then value = FPSBoostEnabled
    elseif key == "Soul Guitar Jump" then value = SoulGuitarJumpEnabled
    end
    if value ~= nil then refresh(value == true) end
end

ApplyUITextScale(_G.G_UITextScale or 1)
refreshUITextSizeValue()
showPage("Home")

local minimized = false
local floating = Instance.new("TextButton")
floating.Name = "ProdigyLauncher"
floating.AnchorPoint = Vector2.new(.5, .5)
floating.Text = "X"
floating.TextColor3 = Theme.cyan
floating.Font = Enum.Font.GothamBold
floating.TextSize = 15
floating.BackgroundColor3 = Theme.bg
floating.Size = UDim2.new(0, 48, 0, 48)
floating.Position = UDim2.new(FloatingX, 0, FloatingY, 0)
floating.ZIndex = 20
floating.AutoButtonColor = false
floating.Parent = Screen
uiCorner(floating, 999)
local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Theme.cyan
floatStroke.Thickness = 2
floatStroke.Transparency = .15
floatStroke.Parent = floating

local glow = Instance.new("Frame")
glow.BackgroundColor3 = Theme.cyan
glow.BackgroundTransparency = .86
glow.Size = UDim2.new(0, 62, 0, 62)
glow.AnchorPoint = Vector2.new(.5, .5)
glow.Position = floating.Position
glow.ZIndex = 19
glow.Parent = Screen
uiCorner(glow, 999)
local glowStroke = Instance.new("UIStroke")
glowStroke.Color = Theme.cyan
glowStroke.Thickness = 1
glowStroke.Transparency = .75
glowStroke.Parent = glow

task.spawn(function()
    while floating.Parent do
        uiTween(glow, 1.1, {Size = UDim2.new(0, 70, 0, 70), BackgroundTransparency = .94}):Play()
        uiTween(glowStroke, 1.1, {Transparency = .9}):Play()
        task.wait(1.1)
        uiTween(glow, 1.1, {Size = UDim2.new(0, 58, 0, 58), BackgroundTransparency = .82}):Play()
        uiTween(glowStroke, 1.1, {Transparency = .75}):Play()
        task.wait(1.1)
    end
end)

do
    local xDragging = false
    local xMoved = false
    local xDragStart
    local xStartPos
    local xTapPending = false
    floating.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            xDragging, xMoved, xTapPending = true, false, true
            xDragStart, xStartPos = input.Position, floating.Position
        end
    end)
    UserInputServiceUI.InputChanged:Connect(function(input)
        if xDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - xDragStart
            if delta.Magnitude > 6 then xMoved, xTapPending = true, false end
            floating.Position = UDim2.new(xStartPos.X.Scale, xStartPos.X.Offset + delta.X, xStartPos.Y.Scale, xStartPos.Y.Offset + delta.Y)
            glow.Position = floating.Position
        end
    end)
    UserInputServiceUI.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if xDragging and xMoved then
                FloatingX = math.clamp(floating.Position.X.Scale + floating.Position.X.Offset / math.max(workspace.CurrentCamera.ViewportSize.X, 1), 0, 1)
                FloatingY = math.clamp(floating.Position.Y.Scale + floating.Position.Y.Offset / math.max(workspace.CurrentCamera.ViewportSize.Y, 1), 0, 1)
                floating.Position = UDim2.new(FloatingX, 0, FloatingY, 0)
                glow.Position = floating.Position
                pcall(SaveConfig)
            elseif xTapPending then
                minimized = not minimized
                Main.Visible = not minimized
            end
            xDragging, xTapPending = false, false
        end
    end)
end
minimizeButton.MouseButton1Click:Connect(function() minimized = true; Main.Visible = false end)
closeButton.MouseButton1Click:Connect(function()
    pcall(SaveConfig)
    minimized = true
    Main.Visible = false
end)

local dragging, dragStart, startPos = false, nil, nil
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
UserInputServiceUI.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputServiceUI.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local footer = uiLabel(Main, "X  •  X", 7, true)
footer.TextColor3 = Theme.muted
footer.Position = UDim2.new(0, 20, 1, -25)
footer.Size = UDim2.new(1, -40, 0, 13)
footer.TextXAlignment = Enum.TextXAlignment.Center

Main.Visible = true
floating.Visible = true
glow.Visible = true
notifyUI("Prodigy", "Interface loaded.", 3)


end

BuildUI()
