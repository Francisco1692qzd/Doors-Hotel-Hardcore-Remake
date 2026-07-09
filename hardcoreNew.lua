-- [[ HARDCORE WITH SyncWait (FIXED) ]]
repeat task.wait() until game:IsLoaded()

-- Run improvements from Achievements and stuff. (DOES NOT REQUIRE TO RUN ANYMORE)
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/AchievementsModule.lua"))()

local Player = game.Players.LocalPlayer
local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom
local TS = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local opened = false

-- ============================================
-- SIMPLE CONFIG
-- ============================================
local CONFIG = {
    RIPPER_DELAY = {80, 110},
    REBOUND_DELAY = {230, 540},
    FROSTBITE_DELAY = {630, 830},
    FROSTBITE_MIN_ROOM = 20,
    CEASE_DELAY = {60, 80},
    A60_DELAY = {1750, 2400},
    SILENCE_DELAY = {600, 900},
    DEERGOD_DELAY = {900, 1200},
    SHOCKER_DELAY = {25, 50},
}

-- ============================================
-- MULTIPLAYER SYNC VIA SyncWait
-- ============================================
local syncFolder = ReplicatedStorage:FindFirstChild("HardcoreSync") or Instance.new("Folder", ReplicatedStorage)
syncFolder.Name = "HardcoreSync"

-- Shared start time (set when room == 1)
local startTimeValue = syncFolder:FindFirstChild("StartTime") or Instance.new("NumberValue", syncFolder)
startTimeValue.Name = "StartTime"
startTimeValue.Value = 0

-- All players use this to wait for the same absolute time
local function SyncWait(seconds)
    if startTimeValue.Value == 0 then return end
    local targetTime = startTimeValue.Value + seconds
    while workspace:GetServerTimeNow() < targetTime do
        task.wait(0.1)
    end
end

-- ============================================
-- ENTITY SPAWNING FUNCTIONS
-- ============================================
local entityURLs = {
    Ripper = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/ripper.lua",
    Rebound = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/rebound.lua",
    DeerGod = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/deergod.lua",
    --Cease = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/cease.lua",
    Shocker = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/shocker.lua",
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

-- Function that spawns entity (PCALL added)
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
-- DETERMINISTIC DELAYS (same for all players)
-- ============================================
local spawnDelays = {
    Ripper = 0, Rebound = 0, Frostbite = 0,
    Cease = 0, Shocker = 0, A60 = 0, Silence = 0, DeerGod = 0
}

local JobId = game.JobId
local function getDeterministicSeed(jobId)
    local seed = 0
    for i = 1, #jobId do
        seed = (seed * 31 + string.byte(jobId, i)) % 2^32
    end
    return seed
end

local function initSharedRandom()
    math.randomseed(getDeterministicSeed(JobId))
end

local function CalculateSpawnDelays()
    spawnDelays.Ripper = math.random(CONFIG.RIPPER_DELAY[1], CONFIG.RIPPER_DELAY[2])
    spawnDelays.Rebound = math.random(CONFIG.REBOUND_DELAY[1], CONFIG.REBOUND_DELAY[2])
    spawnDelays.Frostbite = math.random(CONFIG.FROSTBITE_DELAY[1], CONFIG.FROSTBITE_DELAY[2])
    --spawnDelays.Cease = math.random(CONFIG.CEASE_DELAY[1], CONFIG.CEASE_DELAY[2])
    spawnDelays.Shocker = math.random(CONFIG.SHOCKER_DELAY[1], CONFIG.SHOCKER_DELAY[2])
    spawnDelays.A60 = math.random(CONFIG.A60_DELAY[1], CONFIG.A60_DELAY[2])
    spawnDelays.Silence = math.random(CONFIG.SILENCE_DELAY[1], CONFIG.SILENCE_DELAY[2])
    spawnDelays.DeerGod = math.random(CONFIG.DEERGOD_DELAY[1], CONFIG.DEERGOD_DELAY[2])
    print("📊 Spawn delays calculated")
end

-- ============================================
-- LOCAL SPAWNER (Shocker only)
-- ============================================
local lastLocalSpawnTimes = { Shocker = 0 }
local function SetupLocalSpawners()
    task.spawn(function()
        while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
            local now = workspace:GetServerTimeNow()
            if now - lastLocalSpawnTimes.Shocker >= spawnDelays.Shocker then
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
-- STAMINA BAR (clean version – unchanged)
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
staminaContainer.Position = UDim2.new(0.5, 0, 0.92, -30)  -- centered bottom
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
-- UI, CAPTIONS, CREDITS (unchanged)
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
    creditLabel.Text = "Original Hardcore By Noonie and Ping."
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
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/changelight.lua"))()
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
        ShowCaption("Error. Please go to Door 0 to begin.", 6)
        if Player.Character then Player.Character.Humanoid:TakeDamage(100) end
        return
    else
        local modeInit = Instance.new("BoolValue", workspace)
        modeInit.Name = "ExecutedHard"
        ShowCaption("Script Loaded.", 6)
    end
else
    ShowCaption("Already Running.", 3)
    return
end

-- ============================================
-- INITIALIZATION (SyncWait)
-- ============================================
initSharedRandom()
CalculateSpawnDelays()

local rammessages = {
    "Hardcore V5 by Noonie and Ping for who does not know.",
    "Have fun? (you wont!)",
    "Who took all time just to play?",
    "Fun have? (Won't you!)",
    "Hold Q or tap sprint button to run!"
}

-- Start the schedule when room becomes 1
LatestRoom.Changed:Connect(function()
    if not opened and LatestRoom.Value == 1 then
        opened = true
        startTimeValue.Value = workspace:GetServerTimeNow()  -- all players sync to this
        print("⏱️ Sync start time set to: " .. startTimeValue.Value)

        task.spawn(ShowSmoothCredits)
        ShowCaption("Hardcore Initiated. | True MP Sync: ON", 5)
        task.wait(3)
        ShowCaption("Have fun " .. Player.Name .. ".", 4)
        task.wait(7)
        ShowCaption(rammessages[math.random(1, #rammessages)], 5)
        CreateSprintButton()
        SetupLocalSpawners()

        -- ============================================
        -- SPAWN LOOPS (using SyncWait)
        -- ============================================

        -- Ripper (door‑required)
        task.spawn(function()
            local nextSpawnTime = 0
            while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
                nextSpawnTime = nextSpawnTime + spawnDelays.Ripper
                SyncWait(nextSpawnTime)
                if isPlayerAlive and LatestRoom.Value < 100 then
                    LatestRoom.Changed:Wait()  -- wait for door to open
                    SpawnEntity("Ripper")
                end
            end
        end)

        -- Rebound (door‑required)
        task.spawn(function()
            local nextSpawnTime = 0
            while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
                nextSpawnTime = nextSpawnTime + spawnDelays.Rebound
                SyncWait(nextSpawnTime)
                if isPlayerAlive and LatestRoom.Value < 100 then
                    LatestRoom.Changed:Wait()
                    SpawnEntity("Rebound")
                end
            end
        end)

        -- Frostbite (door‑required, only after room 20)
        task.spawn(function()
            local nextSpawnTime = 0
            while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
                if LatestRoom.Value >= CONFIG.FROSTBITE_MIN_ROOM then
                    nextSpawnTime = nextSpawnTime + spawnDelays.Frostbite
                    SyncWait(nextSpawnTime)
                    if isPlayerAlive and LatestRoom.Value < 100 then
                        LatestRoom.Changed:Wait()
                        SpawnEntity("Frostbite")
                    end
                else
                    task.wait(5)
                end
            end
        end)

        -- Cease (immediate)
        --[[task.spawn(function()
            local nextSpawnTime = 0
            while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
                nextSpawnTime = nextSpawnTime + spawnDelays.Cease
                SyncWait(nextSpawnTime)
                if isPlayerAlive and LatestRoom.Value < 100 then
                    SpawnEntity("Cease")
                end
            end
        end)--]]

        -- A60 (immediate)
        task.spawn(function()
            local nextSpawnTime = 0
            while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
                nextSpawnTime = nextSpawnTime + spawnDelays.A60
                SyncWait(nextSpawnTime)
                if isPlayerAlive and LatestRoom.Value < 100 then
                    SpawnEntity("A60")
                end
            end
        end)

        -- Silence (immediate)
        task.spawn(function()
            local nextSpawnTime = 0
            while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
                nextSpawnTime = nextSpawnTime + spawnDelays.Silence
                SyncWait(nextSpawnTime)
                if isPlayerAlive and LatestRoom.Value < 100 then
                    SpawnEntity("Silence")
                end
            end
        end)

        -- DeerGod (immediate)
        task.spawn(function()
            local nextSpawnTime = 0
            while isPlayerAlive and LatestRoom.Value >= 1 and LatestRoom.Value < 100 do
                nextSpawnTime = nextSpawnTime + spawnDelays.DeerGod
                SyncWait(nextSpawnTime)
                if isPlayerAlive and LatestRoom.Value < 100 then
                    SpawnEntity("DeerGod")
                end
            end
        end)

        print("✅ Hardcore Mode Loaded! (SyncWait active)")
    end
end)

-- Achievement for room 100
LatestRoom.Changed:Connect(function()
    if opened and LatestRoom.Value == 100 and not GaveAchievement then
        GaveAchievement = true
        pcall(function()
            --[[local AchievementModule = Player.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
            if AchievementModule then
                local unlockFunc = require(AchievementModule)
                unlockFunc(nil, "HardcoreSurvivor")
            end--]]
            GiveAchievement("HardcoreSurvivor")
        end)
    end
end)
