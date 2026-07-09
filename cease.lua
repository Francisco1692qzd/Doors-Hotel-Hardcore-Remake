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

    -- Try loading from cache first
    local cached = loadFromFile()
    if cached then return cached end

    -- Download new model
    local response = request({ Url = url, Method = "GET" })
    if response.StatusCode ~= 200 then return nil end

    writefile(fileName, response.Body)
    return loadFromFile() or nil
end

local function ceasetheroom()
    -- -------------------------------
    -- Configuration
    -- -------------------------------
    local AMBRUH_SPEED = 45
    local DEF_SPEED = 9999
    local AMBRUH_HEIGHT = Vector3.new(0, 3.4, 0)
    local KILL_DISTANCE = 60
    local ENTITY_MODEL_URL = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/main/ceaser.rbxm"

    -- -------------------------------
    -- Safe reference gathering
    -- -------------------------------
    local repStorage = game:GetService("ReplicatedStorage")
    local gameData = repStorage:FindFirstChild("GameData")
    if not gameData then
        warn("GameData not found – aborting")
        return
    end

    local latestRoom = gameData:FindFirstChild("LatestRoom")
    local currentRooms = workspace:FindFirstChild("CurrentRooms")
    if not latestRoom or not currentRooms then
        warn("LatestRoom or CurrentRooms missing – aborting")
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    -- -------------------------------
    -- Camera shake setup (safe)
    -- -------------------------------
    local CameraShaker = pcall(require, repStorage:FindFirstChild("CameraShaker")) and require(repStorage.CameraShaker) or nil
    local camShake
    if CameraShaker then
        camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
            camera.CFrame = camera.CFrame * cf
        end)
        camShake:Start()
        camShake:Shake(CameraShaker.Presets.Earthquake)
    end

    -- -------------------------------
    -- Load entity
    -- -------------------------------
    local entity = G.LoadGithubModel and G.LoadGithubModel(ENTITY_MODEL_URL)
    if not entity then
        warn("Failed to load Ceaser model")
        return
    end
    entity.Parent = workspace

    -- Find the main part
    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
    if not entityPart then
        warn("No BasePart in entity – aborting")
        entity:Destroy()
        return
    end

    -- Play sound if exists
    local sound = entity:FindFirstChild("Silence")
    if sound and sound:IsA("Sound") then
        sound:Play()
    end

    -- -------------------------------
    -- Lights effect
    -- -------------------------------
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

    -- -------------------------------
    -- Kill detection
    -- -------------------------------
    local killed = false
    local player = game.Players.LocalPlayer
    local character = player.Character

    local function canSeeTarget(target, size)
        if killed then return false end
        if not target or not target:FindFirstChild("HumanoidRootPart") then return false end

        -- Avoid bosses
        local room = latestRoom.Value
        if room == 50 or room == 100 then return false end

        -- Use modern raycast
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

    -- -------------------------------
    -- Helper to get movement time
    -- -------------------------------
    local function GetTime(dist, speed)
        return dist / speed
    end

    -- -------------------------------
    -- Spawn kill monitor (optimized with Heartbeat)
    -- -------------------------------
    local killConnection
    killConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if killed or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            return
        end

        if canSeeTarget(player.Character, KILL_DISTANCE) then
            -- Kill
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
            if remote then
                local hints = {
                    "You died to Cease...",
                    "Maybe trying to not move when he's nearby?"
                }
                -- Fire client event (exploit specific)
                if firesignal then
                    firesignal(remote.OnClientEvent, hints, "Blue")
                else
                    -- Fallback: print to console
                    print("[Cease] Death hint:", table.concat(hints, " "))
                end
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

    -- -------------------------------
    -- Movement system
    -- -------------------------------
    local function moveThroughRooms(forward, speedMod)
        local start, finish, step
        if forward then
            start = 1
            finish = latestRoom.Value
            step = 1
        else
            start = latestRoom.Value
            finish = 1
            step = -1
        end

        for i = start, finish, step do
            local room = currentRooms:FindFirstChild(tostring(i))
            if room then
                local nodes = room:FindFirstChild("Nodes")
                if nodes then
                    local children = nodes:GetChildren()
                    -- Sort nodes by name (assuming they are numbered)
                    table.sort(children, function(a, b)
                        return tonumber(a.Name) < tonumber(b.Name)
                    end)
                    if not forward then
                        -- Reverse order for backward
                        for idx = #children, 1, -1 do
                            local node = children[idx]
                            if node then
                                local dist = (entityPart.Position - node.Position).Magnitude
                                local speed = (ambruh_speed or AMBRUH_SPEED) + (speedMod or 0)
                                local tween = game.TweenService:Create(
                                    entityPart,
                                    TweenInfo.new(GetTime(dist, speed), Enum.EasingStyle.Linear),
                                    { CFrame = node.CFrame + AMBRUH_HEIGHT }
                                )
                                tween:Play()
                                tween.Completed:Wait()
                            end
                        end
                    else
                        for _, node in ipairs(children) do
                            if node then
                                local dist = (entityPart.Position - node.Position).Magnitude
                                local speed = (ambruh_speed or AMBRUH_SPEED) + (speedMod or 0)
                                local tween = game.TweenService:Create(
                                    entityPart,
                                    TweenInfo.new(GetTime(dist, speed), Enum.EasingStyle.Linear),
                                    { CFrame = node.CFrame + AMBRUH_HEIGHT }
                                )
                                tween:Play()
                                tween.Completed:Wait()
                            end
                        end
                    end
                end
            end
        end
    end

    -- Execute movement with speed adjustments
    local ambr uh_speed = AMBRUH_SPEED

    -- Pass 1: Forward (normal speed)
    moveThroughRooms(true, 0)

    -- Pass 2: Backward (normal speed)
    moveThroughRooms(false, 0)

    -- Pass 3: Forward (increasing speed each node)
    for i = 1, latestRoom.Value do
        local room = currentRooms:FindFirstChild(tostring(i))
        if room then
            local nodes = room:FindFirstChild("Nodes")
            if nodes then
                local children = nodes:GetChildren()
                table.sort(children, function(a, b)
                    return tonumber(a.Name) < tonumber(b.Name)
                end)
                for _, node in ipairs(children) do
                    if node then
                        local dist = (entityPart.Position - node.Position).Magnitude
                        local speed = AMBRUH_SPEED + 80   -- increasing speed
                        local tween = game.TweenService:Create(
                            entityPart,
                            TweenInfo.new(GetTime(dist, speed), Enum.EasingStyle.Linear),
                            { CFrame = node.CFrame + AMBRUH_HEIGHT }
                        )
                        tween:Play()
                        tween.Completed:Wait()
                    end
                end
            end
        end
    end

    -- Cleanup
    entityPart.Anchored = false
    entityPart.CanCollide = false
    game.Debris:AddItem(entity, 5)
    if killConnection then killConnection:Disconnect() end
    if camShake then camShake:Stop() end
end

-- Run with error protection
local success, err = pcall(ceasetheroom)
if not success then
    warn("Cease script error: " .. tostring(err))
end
