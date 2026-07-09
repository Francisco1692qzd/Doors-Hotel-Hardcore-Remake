-- XENO GITHUB MODEL LOADER (.rbxm / .rbxmx)
local G = getgenv()
local ReplicatedStorage = game.ReplicatedStorage
local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder") or ReplicatedStorage:FindFirstChild("Bricks")

G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then return nil end

    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "ceaser_" .. tostring(hash) .. ".rbxm"
    end

    local fileName = generateFileName(url)

    local function loadFromFile()
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
        return nil
    end

    local cached = loadFromFile()
    if cached then return cached end

    local response = request({ Url = url, Method = "GET" })
    if response.StatusCode ~= 200 then return nil end

    writefile(fileName, response.Body)
    return loadFromFile() or nil
end

local function ceasetheroom()
    -- =============================================
    -- CONFIGURATION
    -- =============================================
    local KILL_DISTANCE = 60               -- how far Cease can see
    local TELEPORT_ROOM_OFFSET = 5         -- rooms ahead of current (e.g., latestRoom - 5)
    local ENTITY_MODEL_URL = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/main/ceaser.rbxm"
    local HEIGHT_OFFSET = Vector3.new(0, 3.4, 0)  -- float height

    -- =============================================
    -- SAFE REFERENCE GATHERING
    -- =============================================
    local repStorage = game:GetService("ReplicatedStorage")
    local gameData = repStorage:FindFirstChild("GameData")
    if not gameData then warn("GameData not found") return end

    local latestRoom = gameData:FindFirstChild("LatestRoom")
    local currentRooms = workspace:FindFirstChild("CurrentRooms")
    if not latestRoom or not currentRooms then
        warn("LatestRoom or CurrentRooms missing")
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    -- =============================================
    -- CAMERA SHAKE
    -- =============================================
    local CameraShaker = pcall(require, repStorage:FindFirstChild("CameraShaker")) and require(repStorage.CameraShaker) or nil
    local camShake
    if CameraShaker then
        camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
            camera.CFrame = camera.CFrame * cf
        end)
        camShake:Start()
        camShake:Shake(CameraShaker.Presets.Earthquake)
    end

    -- =============================================
    -- LOAD ENTITY
    -- =============================================
    local entity = G.LoadGithubModel and G.LoadGithubModel(ENTITY_MODEL_URL)
    if not entity then
        warn("Failed to load Ceaser model")
        return
    end
    entity.Parent = workspace

    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
    if not entityPart then
        warn("No BasePart in entity")
        entity:Destroy()
        return
    end

    -- Play sound
    local sound = entity:FindFirstChild("Silence")
    if sound and sound:IsA("Sound") then
        sound:Play()
    end

    -- =============================================
    -- LIGHTS EFFECT (BLUE FLICKER)
    -- =============================================
    local tweenLights = TweenInfo.new(1)
    local color = { Color = Color3.fromRGB(0, 0, 255) }
    local secondColor = { Color = Color3.fromRGB(0, 0, 155) }

    for _, light in ipairs(currentRooms:GetDescendants()) do
        if light:IsA("Light") then
            game.TweenService:Create(light, tweenLights, color):Play()
            if light.Parent and light.Parent.Name == "LightFixture" then
                game.TweenService:Create(light.Parent, tweenLights, color):Play()
            end
        end
    end

    delay(3, function()
        for _, light in ipairs(currentRooms:GetDescendants()) do
            if light:IsA("Light") then
                game.TweenService:Create(light, tweenLights, secondColor):Play()
                if light.Parent and light.Parent.Name == "LightFixture" then
                    game.TweenService:Create(light.Parent, tweenLights, secondColor):Play()
                end
            end
        end
    end)

    wait(2)  -- let lights flicker

    -- =============================================
    -- TELEPORT TO TARGET ROOM
    -- =============================================
    local targetRoomNumber = math.max(1, latestRoom.Value - TELEPORT_ROOM_OFFSET)
    local targetRoom = currentRooms:FindFirstChild(tostring(targetRoomNumber))
    if targetRoom then
        -- Find an entrance part (RoomEntrance, Entrance, or any part with "entrance" in name)
        local entrancePart = targetRoom:FindFirstChild("RoomEntrance") or targetRoom:FindFirstChild("Entrance")
        if not entrancePart then
            for _, part in ipairs(targetRoom:GetDescendants()) do
                if part:IsA("BasePart") and (part.Name:lower():find("entrance") or part.Name:lower():find("door")) then
                    entrancePart = part
                    break
                end
            end
        end
        if entrancePart then
            entityPart.CFrame = entrancePart.CFrame + HEIGHT_OFFSET
        else
            -- fallback to primary part or any base part
            local primary = targetRoom:FindFirstChild("PrimaryPart") or targetRoom:FindFirstChildWhichIsA("BasePart")
            if primary then
                entityPart.CFrame = primary.CFrame + HEIGHT_OFFSET
            end
        end
    else
        warn("Target room " .. targetRoomNumber .. " not found – teleporting to current room")
        -- fallback to current room (player's location)
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            entityPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 0, 20) + HEIGHT_OFFSET
        end
    end

    -- =============================================
    -- KILL DETECTION (MOVEMENT INDEPENDENT)
    -- =============================================
    local killed = false
    local player = game.Players.LocalPlayer

    local function canSeeTarget(target, size)
        if killed then return false end
        if not target or not target:FindFirstChild("HumanoidRootPart") then return false end

        -- Skip boss rooms (safe)
        local room = latestRoom.Value
        if room == 50 or room == 100 then return false end

        -- Raycast from entity to target
        local origin = entityPart.Position
        local direction = (target.HumanoidRootPart.Position - origin).unit * size
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = { entityPart }

        local result = workspace:Raycast(origin, direction, raycastParams)
        if result and result.Instance and result.Instance:IsDescendantOf(target) then
            killed = true
            return true
        end
        return false
    end

    local killConnection
    killConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if killed or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            return
        end

        -- Check if player is in line‑of‑sight (regardless of movement)
        if canSeeTarget(player.Character, KILL_DISTANCE) then
            local hum = player.Character:FindFirstChild("Humanoid")
            if hum then
                hum:TakeDamage(100)
            end

            -- Update death cause
            local stats = repStorage:FindFirstChild("GameStats")
            if stats then
                local playerFolder = stats:FindFirstChild("Player_" .. player.Name)
                if playerFolder and playerFolder:FindFirstChild("Total") then
                    local deathCause = playerFolder.Total:FindFirstChild("DeathCause")
                    if deathCause then
                        deathCause.Value = "Cease"
                    end
                end
            end

            -- Send death hint (if remote exists)
            local remote = remotesFolder and remotesFolder:FindFirstChild("DeathHint")
            if remote and firesignal then
                local hints = {
                    "You died to Cease...",
                    "Maybe trying to not move when he's nearby?"
                }
                firesignal(remote.OnClientEvent, hints, "Blue")
            end

            killed = true
        end

        -- Camera shake when near
        if not killed and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (entityPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if dist <= KILL_DISTANCE and camShake then
                camShake:ShakeOnce(2.4, 25, 0.5, 2, 1, 6)
            end
        end
    end)

    -- =============================================
    -- CLEANUP AFTER A FEW SECONDS
    -- =============================================
    delay(10, function()
        if entity and entity.Parent then
            entityPart.Anchored = false
            entityPart.CanCollide = false
            game.Debris:AddItem(entity, 5)
        end
        if killConnection then killConnection:Disconnect() end
        if camShake then camShake:Stop() end
    end)
end

-- Run safely
pcall(ceasetheroom)
