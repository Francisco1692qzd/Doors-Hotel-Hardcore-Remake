local hints = {
    "The cold is creeping in... Keep moving and find a light source to stay warm!",
    "You are freezing out! Seek out a candle or lighter immediately before your health drops.",
    "A sinister chill is nearby. Make sure your lighter is equipped!"
}

local rep = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local G = getgenv()

-- [[ MODEL DOWNLOADER SYSTEM ]]
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then return nil end
    
    local function generateFileName(targetUrl)
        local hash = 0
        for i = 1, #targetUrl do
            hash = (hash * 31 + string.byte(targetUrl, i)) % 2^32
        end
        return "frost_" .. tostring(hash) .. ".rbxm"
    end
    
    local fileName = generateFileName(url)
    
    local success, exists = pcall(function()
        return isfile and isfile(fileName)
    end)
    
    if success and exists then
        local assetId = getcustomasset(fileName)
        local loadSuccess, result = pcall(function()
            return game:GetObjects(assetId)[1]
        end)
        
        if loadSuccess and result then
            return result
        end
    end
    
    local response = request({Url = url, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    
    writefile(fileName, response.Body)
    local assetId = getcustomasset(fileName)
    local loadSuccess, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    
    if loadSuccess and result then return result end
    return nil
end

-- [[ EXECUTOR GITHUB AUDIO LOADER SYSTEM ]]
local SoundService = game:GetService("SoundService")

local function GetGitAudio(AssetName, GithubUrl)
    local existingSound = SoundService:FindFirstChild(AssetName)
    if existingSound and existingSound:IsA("Sound") then
        return existingSound
    end

    local fileName = "FractureMode_Audio_" .. AssetName .. ".mp3"
    local customAssetId

    if isfile and isfile(fileName) then
        customAssetId = getcustomasset(fileName)
    else
        local success, audioData = pcall(function()
            return game:HttpGet(GithubUrl)
        end)

        if success and audioData then
            if writefile then writefile(fileName, audioData) end
            if getcustomasset then customAssetId = getcustomasset(fileName) end
        else
            warn("❌ Failed to download audio from GitHub: " .. tostring(GithubUrl))
            return nil
        end
    end

    if customAssetId then
        local newSound = Instance.new("Sound")
        newSound.Name = AssetName
        newSound.SoundId = customAssetId
        newSound.Parent = SoundService
        return newSound
    end

    return nil
end

local frostURL = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore/main/newFrostbite.rbxm"
local AmbienceFrostbiteraw = "https://raw.githubusercontent.com/Francisco1692qzd/Fracture-Mode/main/AmbienceFrostbite.mp3"

task.spawn(function()
    local camera = workspace.CurrentCamera
    local cameraShaker = require(rep:WaitForChild("CameraShaker"))
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    camShake:Start()
    
    local gameData = rep:WaitForChild("GameData")
    local latestRoom = gameData:WaitForChild("LatestRoom")
    local room = workspace.CurrentRooms:FindFirstChild(tostring(latestRoom.Value))
    
    local player = Players.LocalPlayer
    local entity = nil
    local active = false
    local turn1 = true
    
    -- Load Custom Audio Asset
    local ambienceFrost = GetGitAudio("AmbienceFroster", AmbienceFrostbiteraw)

    -- Load Custom Entity Model
    if G.LoadGithubModel then
        entity = G.LoadGithubModel(frostURL)
        if entity then entity.Parent = workspace end
    end

    if not entity then return end

    local part = entity:FindFirstChild("Part")
    if not part then return end

    local static = part:FindFirstChild("Static Effect")
    if static then static:Play() end

    -- Apply Sound ID safely directly from object
    if ambienceFrost and ambienceFrost.SoundId ~= "" then
        part.Ambience.SoundId = ambienceFrost.SoundId
        part.AmbienceFar.SoundId = ambienceFrost.SoundId
    end
    part.Ambience:Stop()
    part.AmbienceFar:Stop()

    -- Node Placement
    if room then
        local nodes = room:FindFirstChild("Nodes")
        if nodes then
            local childrenNodes = nodes:GetChildren()
            if #childrenNodes > 0 then
                local randomNode = childrenNodes[math.random(1, #childrenNodes)]
                part.CFrame = randomNode.CFrame * CFrame.new(math.random(5, 10), 6, math.random(5, 10))
            end
        end
    end

    -- Initial Shake Loop
    task.spawn(function()
        while entity and entity.Parent and turn1 do
            camShake:ShakeOnce(14, 30, 0, 4)
            task.wait(0.5)
        end
    end)

    task.wait(5.33)
    turn1 = false
    if static then
        TweenService:Create(static, TweenInfo.new(1.4), {PlaybackSpeed = 0}):Play()
    end
    task.wait(2.3)

    -- Enable active state BEFORE spawning thread so the while-loop checks true instantly
    active = true

    -- Active Shake Loop
    task.spawn(function()
        while entity and entity.Parent and active do
            camShake:ShakeOnce(20, 30, 0, 3)
            task.wait(0.5)
        end
    end)

    part.Ambience:Play()
    part.AmbienceFar:Play()
    if part:FindFirstChild("Attachment") then
        if part.Attachment:FindFirstChild("Heylois") then part.Attachment.Heylois.Enabled = true end
        if part.Attachment:FindFirstChild("face") then part.Attachment.face.Enabled = true end
    end

    -- Frostbite Screen Filter
    local lightFilter = Instance.new("ColorCorrectionEffect")
    lightFilter.Name = "FrostbiteFilter"
    lightFilter.Parent = Lighting
    
    local currentLightTween = TweenService:Create(lightFilter, TweenInfo.new(13), {
        Brightness = -0.2,
        Contrast = 0.9,
        Saturation = -0.7,
        TintColor = Color3.fromRGB(23, 66, 255)
    })
    currentLightTween:Play()

    -- [[ HEAT DETECTION & FREEZING DAMAGE LOOP ]]
    task.delay(1.3, function()
        task.spawn(function()
            while active and entity and entity.Parent do
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then
                    local hasHeat = false
                    
                    -- Check held/equipped Lighter or Candle tool
                    local tool = char:FindFirstChild("Lighter") or char:FindFirstChild("Candle")
                    if tool then
                        for _, obj in ipairs(tool:GetDescendants()) do
                            if obj:IsA("PointLight") and obj.Enabled then
                                hasHeat = true
                                break
                            end
                        end
                    end

                    -- Apply freezing damage if no heat source is equipped
                    if not hasHeat and char.Humanoid.Health > 0 then
                        char.Humanoid:TakeDamage(10)
                        
                        -- Handle Custom Death Screen Details
                        if char.Humanoid.Health <= 0 then
                            pcall(function()
                                rep.GameStats["Player_".. char.Name].Total.DeathCause.Value = "Frostbite"
                                local remote = rep:FindFirstChild("Bricks") or rep:FindFirstChild("RemotesFolder")
                                if remote and remote:FindFirstChild("DeathHint") and firesignal then 
                                    firesignal(remote.DeathHint.OnClientEvent, hints) 
                                end
                            end)
                            break
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end)

    -- Wait for player to move to next room to despawn
    latestRoom.Changed:Wait()
    
    if currentLightTween.PlaybackState == Enum.PlaybackState.Playing then
        currentLightTween:Cancel()
    end
    
    local restoreLightTween = TweenService:Create(lightFilter, TweenInfo.new(18), {
        Brightness = 0,
        Saturation = 0,
        Contrast = 0,
        TintColor = Color3.fromRGB(255, 255, 255)
    })
    restoreLightTween:Play()
    restoreLightTween.Completed:Connect(function()
        lightFilter:Destroy()
    end)
    
    active = false
    part.Ambience:Stop()
    part.AmbienceFar:Stop()
    
    if part:FindFirstChild("Attachment") then
        if part.Attachment:FindFirstChild("Heylois") then part.Attachment.Heylois.Enabled = false end
        if part.Attachment:FindFirstChild("face") then part.Attachment.face.Enabled = false end
    end
    
    -- Play despawn sound effect
    local ahhh_despawn = Instance.new("Sound")
    ahhh_despawn.Parent = part
    ahhh_despawn.SoundId = "rbxassetid://6305809364"
    ahhh_despawn.Volume = 1.2
    ahhh_despawn.RollOffMaxDistance = 300
    ahhh_despawn.RollOffMinDistance = 5
    ahhh_despawn.PlaybackSpeed = 0.24
    ahhh_despawn.RollOffMode = Enum.RollOffMode.LinearSquare
    ahhh_despawn:Play()
    
    local dist = Instance.new("DistortionSoundEffect", ahhh_despawn)
    local flange = Instance.new("FlangeSoundEffect", ahhh_despawn)
    local flange2 = Instance.new("FlangeSoundEffect", ahhh_despawn)
    
    dist.Level = 0.98
    flange.Depth = 1
    flange.Mix = 1
    flange.Priority = 0
    flange.Rate = 0.25
    flange2.Depth = 1
    flange2.Mix = 0.73
    flange2.Priority = 0
    flange2.Rate = 0.75
    
    ahhh_despawn.Ended:Wait()
    task.wait(0.4)
    entity:Destroy()
end)
