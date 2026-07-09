-- [[ HARDCORE WITH PERFECT MULTIPLAYER SYNC (FIXED INTERVALS) ]]
repeat task.wait() until game:IsLoaded()

local Player = game.Players.LocalPlayer
local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom
local TS = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local opened = false

-- ============================================
-- CONFIG (FIXED INTERVALS – NO RANDOM)
-- ============================================
local CONFIG = {
    RIPPER_INTERVAL = 90,          -- seconds between Ripper spawns
    REBOUND_INTERVAL = 250,
    FROSTBITE_INTERVAL = 700,
    FROSTBITE_MIN_ROOM = 20,
    CEASE_INTERVAL = 70,
    A60_INTERVAL = 2000,
    SILENCE_INTERVAL = 750,
    DEERGOD_INTERVAL = 1000,
    SHOCKER_INTERVAL = 35,         -- local spawner (Shocker)
    MASTER_HEARTBEAT_INTERVAL = 5,
    MASTER_TIMEOUT = 15,
}

-- ============================================
-- MULTIPLAYER SYNC SYSTEM
-- ============================================
local syncFolder = ReplicatedStorage:FindFirstChild("HardcoreSync") or Instance.new("Folder", ReplicatedStorage)
syncFolder.Name = "HardcoreSync"

local masterStart = syncFolder:FindFirstChild("MasterStart") or Instance.new("NumberValue", syncFolder)
masterStart.Name = "MasterStart"

local nextSpawn = syncFolder:FindFirstChild("NextSpawn") or Instance.new("StringValue", syncFolder)
nextSpawn.Name = "NextSpawn"

local spawnLock = syncFolder:FindFirstChild("SpawnLock") or Instance.new("BoolValue", syncFolder)
spawnLock.Name = "SpawnLock"
spawnLock.Value = false

-- Master heartbeat
local masterHeartbeat = syncFolder:FindFirstChild("MasterHeartbeat") or Instance.new("NumberValue", syncFolder)
masterHeartbeat.Name = "MasterHeartbeat"
masterHeartbeat.Value = 0

-- Persistent last spawn times for room-wait entities
local lastSpawnTimes = {
    Ripper = syncFolder:FindFirstChild("LastRipper") or Instance.new("NumberValue", syncFolder),
    Rebound = syncFolder:FindFirstChild("LastRebound") or Instance.new("NumberValue", syncFolder),
    Frostbite = syncFolder:FindFirstChild("LastFrostbite") or Instance.new("NumberValue", syncFolder),
}
for name, val in pairs(lastSpawnTimes) do
    val.Name = "Last" .. name
    val.Value = masterStart.Value
end

local isMaster = false
local masterElected = false

-- ============================================
-- MASTER ELECTION & HEARTBEAT
-- ============================================
local function TryBecomeMaster(force)
    if masterElected and not force then return end
    local now = workspace:GetServerTimeNow()
    if masterStart.Value == 0 or (now - masterHeartbeat.Value > CONFIG.MASTER_TIMEOUT) or force then
        masterStart.Value = now
        masterHeartbeat.Value = now
        isMaster = true
        masterElected = true
        print("🎮 Master player: " .. Player.Name .. " (elected)")
        return true
    end
    return false
end

local function ScheduleSpawn(entityName, absoluteTime)
    if not isMaster then return false end
    if spawnLock.Value then return false end
    spawnLock.Value = true
    nextSpawn.Value = entityName .. ":" .. tostring(absoluteTime)
    spawnLock.Value = false
    return true
end

-- Master heartbeat updater
local function StartHeartbeat()
    if not isMaster then return end
    task.spawn(function()
        while isMaster and isPlayerAlive do
            masterHeartbeat.Value = workspace:GetServerTimeNow()
            task.wait(CONFIG.MASTER_HEARTBEAT_INTERVAL)
        end
    end)
end

-- Monitor heartbeat and re-elect if master dies
local function MonitorHeartbeat()
    task.spawn(function()
        while isPlayerAlive do
            task.wait(CONFIG.MASTER_TIMEOUT)
            local now = workspace:GetServerTimeNow()
            if masterStart.Value ~= 0 and (now - masterHeartbeat.Value > CONFIG.MASTER_TIMEOUT) then
                print("⚠️ Master heartbeat lost. Re-electing...")
                TryBecomeMaster(true)
                if isMaster then
                    SetupMasterScheduler()
                    StartHeartbeat()
                end
            end
        end
    end)
end

-- ============================================
-- ENTITY SPAWNING FUNCTIONS
-- ============================================
local entityURLs = {
    Ripper = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/ripper.lua",
    Rebound = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/rebound.lua",
    DeerGod = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/deergod.lua",
    Cease = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/cease.lua",
    Shocker = "https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/refs/heads/main/oldShocker.lua",
    Silence = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/silence.lua",
    A60 = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/a60.lua",
    Frostbite = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/frostbite.lua"
}

local lastEntitySpawnTime = 0
local ENTITY_SPAWN_COOLDOWN = 3
local isPlayerAlive = true

local function CanSpawnEntity(entityName)
    if not isPlayerAlive then return false end
    if workspace:FindFirstChild("SeekMovingNewClone") or workspace:FindFirstChild("SeekMoving") then
        return false
    end
    local latestRoom = LatestRoom.Value
    if latestRoom == 100 then return false end
    if latestRoom == 50 and entityName ~= "A60" then return false end
    if latestRoom == 51 or (latestRoom > 52 and latestRoom < 59) then return false end
    if workspace:GetServerTimeNow() - lastEntitySpawnTime < ENTITY_SPAWN_COOLDOWN then
        return false
    end
    local activeEntity = workspace:FindFirstChild("asdasdasdd") or
        workspace:FindFirstChild("asdasdas") or
        workspace:FindFirstChild("asdasda") or
        workspace:FindFirstChild("asdasd") or
        workspace:FindFirstChild("asdas") or
        workspace:FindFirstChild("asda") or
        workspace:FindFirstChild("a") or
        workspace:FindFirstChild("as") or
        workspace:FindFirstChild("asd") or
        workspace:FindFirstChild("asdasdasd")
    return activeEntity == nil
end

local function SpawnEntity(entityName)
    if not isPlayerAlive then return false end
    if not entityURLs[entityName] then return false end
    if not CanSpawnEntity(entityName) then return false end
    lastEntitySpawnTime = workspace:GetServerTimeNow()
    local success, err = pcall(function()
        loadstring(game:HttpGet(entityURLs[entityName]))()
        print("🎮 Spawning: " .. entityName)
    end)
    if not success then
        warn("Failed to spawn " .. entityName .. ": " .. tostring(err))
        return false
    end
    return true
end

-- ============================================
-- SYNC LISTENER
-- ============================================
nextSpawn.Changed:Connect(function()
    if nextSpawn.Value == "" then return end
    local parts = {}
    for part in string.gmatch(nextSpawn.Value, "[^:]+") do
        table.insert(parts, part)
    end
    if #parts >= 2 then
        local entityName = parts[1]
        local spawnTime = tonumber(parts[2])
        while workspace:GetServerTimeNow() < spawnTime do
            task.wait(0.05)
        end
        if CanSpawnEntity(entityName) then
            SpawnEntity(entityName)
            print("🎮 SYNC SPAWN: " .. entityName .. " at room " .. LatestRoom.Value)
        end
        task.wait(0.5)
        nextSpawn.Value = ""
    end
end)

-- ============================================
-- MASTER SCHEDULER (USES FIXED INTERVALS)
-- ============================================
local function SetupMasterScheduler()
    if not isMaster then return end

    -- Load last spawn times from persistent storage
    local lastSpawnAbsolute = {
        Ripper = lastSpawnTimes.Ripper.Value,
        Rebound = lastSpawnTimes.Rebound.Value,
        Frostbite = lastSpawnTimes.Frostbite.Value,
        Cease = 0,
        A60 = 0,
        Silence = 0,
        DeerGod = 0,
    }

    local pendingDoorWait = {}

    task.spawn(function()
        while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
            local now = workspace:GetServerTimeNow()

            -- Ripper (door wait)
            if now - lastSpawnAbsolute.Ripper >= CONFIG.RIPPER_INTERVAL then
                pendingDoorWait.Ripper = true
                lastSpawnAbsolute.Ripper = now
                lastSpawnTimes.Ripper.Value = now
            end

            -- Rebound (door wait)
            if now - lastSpawnAbsolute.Rebound >= CONFIG.REBOUND_INTERVAL then
                pendingDoorWait.Rebound = true
                lastSpawnAbsolute.Rebound = now
                lastSpawnTimes.Rebound.Value = now
            end

            -- Frostbite (door wait, min room)
            if LatestRoom.Value >= CONFIG.FROSTBITE_MIN_ROOM and 
               now - lastSpawnAbsolute.Frostbite >= CONFIG.FROSTBITE_INTERVAL then
                pendingDoorWait.Frostbite = true
                lastSpawnAbsolute.Frostbite = now
                lastSpawnTimes.Frostbite.Value = now
            end

            -- Immediate entities (no door wait)
            if now - lastSpawnAbsolute.Cease >= CONFIG.CEASE_INTERVAL then
                ScheduleSpawn("Cease", now + 0.5)
                lastSpawnAbsolute.Cease = now
            end

            if now - lastSpawnAbsolute.A60 >= CONFIG.A60_INTERVAL then
                ScheduleSpawn("A60", now + 0.5)
                lastSpawnAbsolute.A60 = now
            end

            if now - lastSpawnAbsolute.Silence >= CONFIG.SILENCE_INTERVAL then
                ScheduleSpawn("Silence", now + 0.5)
                lastSpawnAbsolute.Silence = now
            end

            if now - lastSpawnAbsolute.DeerGod >= CONFIG.DEERGOD_INTERVAL then
                ScheduleSpawn("DeerGod", now + 0.5)
                lastSpawnAbsolute.DeerGod = now
            end

            task.wait(0.5)
        end
    end)

    -- Door listener
    local lastRoom = LatestRoom.Value
    LatestRoom.Changed:Connect(function()
        local newRoom = LatestRoom.Value
        if newRoom > lastRoom then
            for entity, _ in pairs(pendingDoorWait) do
                if CanSpawnEntity(entity) then
                    ScheduleSpawn(entity, workspace:GetServerTimeNow() + 0.5)
                    print("🚪 DOOR SPAWN: " .. entity)
                else
                    print("⏳ " .. entity .. " still pending (blocked)")
                end
            end
            pendingDoorWait = {}
        end
        lastRoom = newRoom
    end)
end

-- ============================================
-- LOCAL SPAWNER (Shocker only – uses fixed interval)
-- ============================================
local lastLocalSpawnTimes = { Shocker = 0 }
local function SetupLocalSpawners()
    task.spawn(function()
        while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
            local now = workspace:GetServerTimeNow()
            if now - lastLocalSpawnTimes.Shocker >= CONFIG.SHOCKER_INTERVAL then
                if CanSpawnEntity("Shocker") then
                    SpawnEntity("Shocker")
                    lastLocalSpawnTimes.Shocker = now
                    print("⚡ Shocker (local)")
                end
            end
            task.wait(1)
        end
    end)
end

-- ============================================
-- STAMINA BAR (clean version)
-- ============================================
local UIS = game:GetService("UserInputService")
local stamina = 100
local maxStamina = 100
local isExhausted = false
local sprinting = false
local crouching = false

-- Create GUI
local staminaGui = Instance.new("ScreenGui")
staminaGui.Name = "StaminaGui"
staminaGui.ResetOnSpawn = false
staminaGui.IgnoreGuiInset = true
staminaGui.Parent = Player.PlayerGui

local staminaContainer = Instance.new("Frame")
staminaContainer.Size = UDim2.new(0, 280, 0, 12)
staminaContainer.Position = UDim2.new(0.5, 0, 0.92, -30)
staminaContainer.AnchorPoint = Vector2.new(0.5, 0.5)
staminaContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
staminaContainer.BackgroundTransparency = 0.4
staminaContainer.BorderSizePixel = 0
staminaContainer.ClipsDescendants = true
staminaContainer.Parent = staminaGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 6)
containerCorner.Parent = staminaContainer

local staminaFill = Instance.new("Frame")
staminaFill.Size = UDim2.new(1, 0, 1, 0)
staminaFill.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaContainer

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = staminaFill

local staminaText = Instance.new("TextLabel")
staminaText.Size = UDim2.new(1, 0, 1, 0)
staminaText.BackgroundTransparency = 1
staminaText.Text = "100%"
staminaText.TextColor3 = Color3.fromRGB(255, 255, 255)
staminaText.TextSize = 11
staminaText.Font = Enum.Font.GothamBold
staminaText.Parent = staminaContainer

-- Sprint input
UIS.InputBegan:Connect(function(i, gpe)
    if not gpe and i.KeyCode == Enum.KeyCode.Q then sprinting = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Q then sprinting = false end
end)

-- Mobile sprint button
local function CreateSprintButton()
    if not UIS.TouchEnabled then return end
    local btnGui = Instance.new("ScreenGui")
    btnGui.Name = "SprintButtonGui"
    btnGui.ResetOnSpawn = false
    btnGui.IgnoreGuiInset = true
    btnGui.DisplayOrder = 999
    btnGui.Parent = Player.PlayerGui

    local button = Instance.new("ImageButton")
    button.Size = UDim2.new(0, 75, 0, 75)
    button.Position = UDim2.new(1, -90, 0.5, -30)
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    button.BackgroundTransparency = 0.3
    button.BorderSizePixel = 0
    button.Image = "rbxassetid://6031094773"
    button.ScaleType = Enum.ScaleType.Fit
    button.Parent = btnGui

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = button

    button.MouseButton1Down:Connect(function()
        if isPlayerAlive and stamina > 5 then
            sprinting = true
            button.ImageColor3 = Color3.fromRGB(255, 222, 189)
        end
    end)
    button.MouseButton1Up:Connect(function()
        sprinting = false
        button.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end)
    button.MouseLeave:Connect(function()
        sprinting = false
        button.ImageColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

-- Breath sound
local breathSound
local function SetupCharacter(char)
    local head = char:FindFirstChild("Head")
    if head then
        if breathSound then breathSound:Destroy() end
        breathSound = Instance.new("Sound", head)
        breathSound.SoundId = "rbxassetid://8258601891"
        breathSound.Volume = 2
        breathSound.Looped = true
    end
end

Player.CharacterAdded:Connect(function(char)
    isPlayerAlive = true
    stamina = 100
    isExhausted = false
    sprinting = false
    SetupCharacter(char)
end)

Player.CharacterRemoving:Connect(function()
    isPlayerAlive = false
    sprinting = false
end)

if Player.Character then SetupCharacter(Player.Character) end

-- Stamina update loop
task.spawn(function()
    while task.wait(0.05) do
        local char = Player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if not hum then continue end

        local isMoving = hum.MoveDirection.Magnitude > 0
        local seekActive = workspace:FindFirstChild("SeekMovingNewClone") or workspace:FindFirstChild("SeekMoving")
        crouching = char:GetAttribute("Crouching")

        local percent = stamina / maxStamina
        staminaFill.Size = UDim2.new(percent, 0, 1, 0)
        staminaText.Text = math.floor(stamina) .. "%"

        if stamina <= 20 then
            staminaFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        elseif stamina <= 50 then
            staminaFill.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
        else
            staminaFill.BackgroundColor3 = Color3.fromRGB(255, 222, 189)
        end

        if seekActive then
            staminaContainer.Visible = false
            stamina = math.min(maxStamina, stamina + 0.8)
            sprinting = false
        else
            staminaContainer.Visible = true
            if isExhausted then
                char:SetAttribute("SpeedBoost", 0)
                hum.WalkSpeed = 11
                stamina = math.min(maxStamina, stamina + 0.6)
                if breathSound and not breathSound.IsPlaying then breathSound:Play() end
                if stamina >= maxStamina then isExhausted = false end
            elseif crouching then
                char:SetAttribute("SpeedBoost", 0)
                hum.WalkSpeed = 7
                stamina = math.min(maxStamina, stamina + 0.9)
                if breathSound then breathSound:Stop() end
            elseif sprinting and isMoving and stamina > 5 then
                char:SetAttribute("SpeedBoost", 4.5)
                hum.WalkSpeed = 20
                stamina = math.max(0, stamina - 1.4)
                if stamina <= 0 then isExhausted = true end
                if breathSound then breathSound:Stop() end
            else
                char:SetAttribute("SpeedBoost", 0)
                hum.WalkSpeed = 14
                stamina = math.min(maxStamina, stamina + 0.7)
                if breathSound then breathSound:Stop() end
            end
        end
    end
end)

-- ============================================
-- UI, CAPTIONS, CREDITS
-- ============================================
local function ShowCaption(text, duration)
    local pGui = Player:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("HardcoreCaption") then pGui.HardcoreCaption:Destroy() end
    local screenGui = Instance.new("ScreenGui", pGui)
    screenGui.Name = "HardcoreCaption"
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999
    local captionLabel = Instance.new("TextLabel", screenGui)
    captionLabel.Size = UDim2.new(0.6, 0, 0.05, 10)
    captionLabel.Position = UDim2.new(0.5, 0, 0.92, -60)
    captionLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    captionLabel.BackgroundTransparency = 1
    captionLabel.Text = text
    captionLabel.TextColor3 = Color3.fromRGB(255, 222, 189)
    captionLabel.TextSize = 30
    captionLabel.Font = Enum.Font.Oswald
    captionLabel.TextStrokeTransparency = 0
    local alertSound = Instance.new("Sound", game.SoundService)
    alertSound.SoundId = "rbxassetid://3848738542"
    alertSound:Play()
    game.Debris:AddItem(alertSound, 2)
    task.delay(duration or 4, function()
        if captionLabel then
            TS:Create(captionLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
            task.wait(0.5)
            pcall(function() screenGui:Destroy() end)
        end
    end)
end

local function ShowSmoothCredits()
    task.wait(3)
    local creditGui = Instance.new("ScreenGui", Player.PlayerGui)
    creditGui.Name = "HardcoreCredits"
    local creditLabel = Instance.new("TextLabel", creditGui)
    creditLabel.Text = "Original Hardcore By Noonie and Ping. | True Multiplayer Sync"
    creditLabel.Font = Enum.Font.Oswald
    creditLabel.TextSize = 22
    creditLabel.TextColor3 = Color3.fromRGB(255,255,255)
    creditLabel.TextStrokeTransparency = 0.5
    creditLabel.BackgroundTransparency = 1
    creditLabel.TextXAlignment = Enum.TextXAlignment.Left
    creditLabel.Position = UDim2.new(-0.6,0,0.05,0)
    creditLabel.Size = UDim2.new(0.5,0,0.05,0)
    TS:Create(creditLabel, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.02,0,0.05,0)}):Play()
    task.wait(5)
    local b = TS:Create(creditLabel, TweenInfo.new(1.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(-0.6,0,0.05,0)})
    b:Play()
    b.Completed:Connect(function() pcall(function() creditGui:Destroy() end) end)
end

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/OverridenEntitiesMode/refs/heads/main/nodes.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/AddAchievements.lua"))()
end)

-- Door 0 check
local alreadyExecuted = workspace:FindFirstChild("ExecutedHard")
pcall(function()
    Player.PlayerGui.MainUI.Initiator.Main_Game.Health.Music.Blue.PlaybackSpeed = 0.55
    Player.PlayerGui.MainUI.Initiator.Main_Game.Health.Music.Blue.SoundId = "rbxassetid://10472612727"
end)
local GaveAchievement = false

if not alreadyExecuted then
    if LatestRoom.Value ~= 0 then
        ShowCaption("EXECUTOR: Error. Please go to Door 0 to begin.", 6)
        if Player.Character then Player.Character.Humanoid:TakeDamage(100) end
        return
    else
        local modeInit = Instance.new("BoolValue", workspace)
        modeInit.Name = "ExecutedHard"
        ShowCaption("EXECUTOR: Script Loaded. | True MP Sync: ON", 6)
    end
else
    ShowCaption("EXECUTOR: Already Running.", 3)
    return
end

-- ============================================
-- INITIALIZATION (UPGRADED)
-- ============================================
TryBecomeMaster(false)

if isMaster then
    StartHeartbeat()
end

MonitorHeartbeat()

local rammessages = {
    "Hardcore V5 by Noonie and Ping if you don't know.",
    "Whose mode is this?",
    "Five nights at freddy's, how could it be?",
    "Linxy C: Please play this",
    "Who's A-60?",
    "Hold Q or tap sprint button to run!",
    "Took 8 F###ING days to finish this off, I can't dude."
}

LatestRoom.Changed:Connect(function()
    if not opened and LatestRoom.Value == 1 then
        opened = true
        task.spawn(ShowSmoothCredits)
        ShowCaption("Hardcore Initiated. | True MP Sync: ON", 5)
        task.wait(3)
        ShowCaption("Have fun " .. Player.Name .. ".", 4)
        task.wait(7)
        ShowCaption(rammessages[math.random(1, #rammessages)], 5)
        CreateSprintButton()
        if isMaster then
            SetupMasterScheduler()
        end
        SetupLocalSpawners()
        print("✅ Hardcore Mode Loaded! (Master: " .. (isMaster and "YES" or "NO") .. ")")
    end
end)

LatestRoom.Changed:Connect(function()
    if opened and LatestRoom.Value == 100 and not GaveAchievement then
        GaveAchievement = true
        pcall(function()
            local AchievementModule = Player.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
            if AchievementModule then
                local unlockFunc = require(AchievementModule)
                unlockFunc(nil, "HardcoreSurvivor")
            end
        end)
    end
end)
