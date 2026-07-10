--[[
    HARDCORE MODE – OLD‑SCHOOL SYNC (FIXED INTERVALS, NO MASTER)
    All players use the same start time and hardcoded offsets.
    Robust error handling via pcalls.
]]

repeat task.wait() until game:IsLoaded()

local Player = game.Players.LocalPlayer
local LatestRoom = game.ReplicatedStorage.GameData.LatestRoom
local TS = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================
-- SHARED START TIME (SYNC ANCHOR)
-- ============================================
local startTimeValue = workspace:FindFirstChild("HardcoreStartTime") or Instance.new("NumberValue", workspace)
startTimeValue.Name = "HardcoreStartTime"

local function SyncWait(seconds)
    if startTimeValue.Value == 0 then return end
    local targetTime = startTimeValue.Value + seconds
    while workspace:GetServerTimeNow() < targetTime do
        task.wait(0.5)
    end
end

-- ============================================
-- ENTITY URLs (CEASE REMOVED)
-- ============================================
local entityURLs = {
    Ripper = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/ripper.lua",
    Rebound = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/rebound.lua",
    DeerGod = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/deergod.lua",
    Shocker = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/shocker.lua",
    Silence = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/silence.lua",
    A60 = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/a60.lua",
    Frostbite = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/frostbite.lua"
}

local function LoadEntity(name)
    if workspace:FindFirstChild("SeekMoving") then return end
    local url = entityURLs[name]
    if url then
        task.spawn(function()
            pcall(function()
                local script = game:HttpGet(url)
                loadstring(script)()
            end)
        end)
    end
end

-- ============================================
-- CAPTIONS & CREDITS
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
    creditLabel.Text = "Original Hardcore By Noonie and Ping. | True MP Sync (Old School)"
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

-- ============================================
-- DOOR 0 CHECK
-- ============================================
local alreadyExecuted = workspace:FindFirstChild("ExecutedHard")
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
-- LOAD EXTERNAL MODULES (WITH PCALL)
-- ============================================
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/OverridenEntitiesMode/refs/heads/main/nodes.lua"))()
end)
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/AddAchievements.lua"))()
end)
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/changelight.lua"))()
end)

-- Change music speed (optional)
pcall(function()
    Player.PlayerGui.MainUI.Initiator.Main_Game.Health.Music.Blue.PlaybackSpeed = 0.55
    Player.PlayerGui.MainUI.Initiator.Main_Game.Health.Music.Blue.SoundId = "rbxassetid://10472612727"
end)

-- ============================================
-- STAMINA SYSTEM (same as before)
-- ============================================
local UIS = game:GetService("UserInputService")
local stamina = 100
local maxStamina = 100
local isExhausted = false
local sprinting = false
local crouching = false
local isPlayerAlive = true

-- GUI
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

UIS.InputBegan:Connect(function(i, gpe)
    if not gpe and i.KeyCode == Enum.KeyCode.Q then sprinting = true end
end)
UIS.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Q then sprinting = false end
end)

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
-- SPAWN INTERVALS (no randomness)
-- ============================================
local INTERVALS = {
    RIPPER = 140,
    REBOUND = 550,
    FROSTBITE = 700,
    A60 = 910,
    SILENCE = 600,
    DEERGOD = 2100,
    SHOCKER_MIN = 30,
    SHOCKER_MAX = 70,
}

-- ============================================
-- MAIN INIT – Door 1 triggers everything
-- ============================================
local opened = false
local GaveAchievement = false

-- Wrap the whole door handler in a pcall to prevent crashes
pcall(function()
    LatestRoom.Changed:Connect(function()
        if not opened and LatestRoom.Value == 1 then
            opened = true
            startTimeValue.Value = workspace:GetServerTimeNow()

            task.spawn(ShowSmoothCredits)
            ShowCaption("Hardcore Initiated. | True MP Sync: ON", 5)
            task.wait(3)
            ShowCaption("Have fun " .. Player.Name .. ".", 4)
            task.wait(4)
            ShowCaption("Stamina: Hold Q (or tap button) to sprint.", 5)
            task.wait(4)
            ShowCaption("If you can't sprint, crouch in a closet then leave.", 6)
            task.wait(4)
            ShowCaption("Big Thanks to Ostah for the A-60 and Frostbite models.", 6)
            task.wait(3)

            CreateSprintButton()

            -- ============================================
            -- SPAWN LOOPS (all players run these)
            -- ============================================
            -- Ripper (door wait)
            task.spawn(function()
                local c = 0
                while true do
                    SyncWait(c + 80); LatestRoom.Changed:Wait(); LoadEntity("Ripper")
                    SyncWait(c + 167); LatestRoom.Changed:Wait(); LoadEntity("Ripper")
                    c = c + 300
                    task.wait(INTERVALS.RIPPER)
                end
            end)

            -- Rebound (door wait)
            task.spawn(function()
                local c = 0
                while true do
                    SyncWait(c + 670); LatestRoom.Changed:Wait(); LoadEntity("Rebound")
                    SyncWait(c + 1100); LatestRoom.Changed:Wait(); LoadEntity("Rebound")
                    c = c + 930
                    task.wait(INTERVALS.REBOUND)
                end
            end)

            -- Frostbite (door wait, only after room 20)
            task.spawn(function()
                local c = 0
                while true do
                    SyncWait(c + 270); 
                    if LatestRoom.Value >= 20 then
                        LatestRoom.Changed:Wait()
                        LoadEntity("Frostbite")
                    end
                    SyncWait(c + 645);
                    if LatestRoom.Value >= 20 then
                        LatestRoom.Changed:Wait()
                        LoadEntity("Frostbite")
                    end
                    c = c + 900
                    task.wait(INTERVALS.FROSTBITE)
                end
            end)

            -- A60 (immediate, no door wait)
            task.spawn(function()
                local c = 0
                while true do
                    SyncWait(c + 730); LoadEntity("A60")
                    SyncWait(c + 1200); LoadEntity("A60")
                    c = c + 910
                    task.wait(INTERVALS.A60)
                end
            end)

            -- Silence (immediate)
            task.spawn(function()
                local c = 0
                while true do
                    SyncWait(c + 850); LoadEntity("Silence")
                    SyncWait(c + 1530); LoadEntity("Silence")
                    c = c + 600
                    task.wait(INTERVALS.SILENCE)
                end
            end)

            -- DeerGod (immediate)
            task.spawn(function()
                local c = 0
                while true do
                    SyncWait(c + 1500); LoadEntity("DeerGod")
                    c = c + 2100
                    task.wait(INTERVALS.DEERGOD)
                end
            end)

            -- Shocker (local random, independent)
            task.spawn(function()
                while true do
                    task.wait(math.random(INTERVALS.SHOCKER_MIN, INTERVALS.SHOCKER_MAX))
                    LoadEntity("Shocker")
                end
            end)

            print("✅ Hardcore Mode Loaded! (Sync via HardcoreStartTime)")
        end

        -- Achievement at room 100
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
end)
