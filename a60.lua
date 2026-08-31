local hints = {
    "Odd... I can't discover to who you died to..."
}

local rep = game.ReplicatedStorage
local G = getgenv()

-- Standalone functions for achievements
local function getDataModule()
    local function tryRequire(path)
        local success, mod = pcall(require, path)
        if success then return mod end
        return nil
    end

    if tostring(game.PlaceId) == "10549820578" then
        return tryRequire(game:GetService("ReplicatedStorage"):WaitForChild("Achievements"))
    else
        local shared = game.ReplicatedStorage:FindFirstChild("ModulesShared")
        if not shared then return nil end
        local achMod = shared:FindFirstChild("Achievements")
        if not achMod then return nil end
        return tryRequire(achMod)
    end
end

local function getUnlockUI()
    local gui = game.Players.LocalPlayer.PlayerGui
    local path = gui:FindFirstChild("MainUI")
    if path then path = path:FindFirstChild("Initiator") end
    if path then path = path:FindFirstChild("Main_Game") end
    if path then path = path:FindFirstChild("RemoteListener") end
    if path then path = path:FindFirstChild("Modules") end
    if path then path = path:FindFirstChild("AchievementUnlock") end
    if not path then return nil end
    local success, func = pcall(require, path)
    return success and func or nil
end

function AddAchievement(title, desc, reason, image, achname)
    local dataModule = getDataModule()
    if not dataModule then return end

    dataModule[achname] = {
        GetInfo = function()
            return {
                Title = title,
                Desc = desc,
                Reason = reason,
                Image = image
            }
        end
    }
end

function GiveAchievement(name)
    local dataModule = getDataModule()
    if not dataModule then
        warn("Data module not found")
        return
    end

    if not dataModule[name] then
        warn("Achievement key '"..name.."' does not exist.")
        return
    end

    local unlockUI = getUnlockUI()
    if not unlockUI then
        warn("UI unlock function not found")
        return
    end

    unlockUI(game.Players.LocalPlayer, name)
end

-- [[ FORCE LOAD: Retries 20 times to bypass Roblox asset loading lag ]]
local function loadModel(id)
    local obj = nil
    local attempts = 0
    local maxAttempts = 20

    while obj == nil and attempts < maxAttempts do
        attempts = attempts + 1
        local success, result = pcall(function()
            return game:GetObjects("rbxassetid://" .. id)
        end)

        if success and result and result[1] then
            obj = result[1]
            --print("✅ Depth Model Loaded successfully on attempt: " .. attempts)
        else
            --warn("⚠️ Attempt " .. attempts .. " failed to load model " .. id .. ". Retrying...")
            task.wait(0.5)
        end
    end

    if not obj then
        warn("❌ CRITICAL: Failed to load model after 20 attempts.")
    end
    
    return obj
end

G.LoadGithubAudio = function(url)
    if not (writefile and getcustomasset and request) then return nil end

    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "multimonster_" .. tostring(hash) .. ".mpeg"
    end
    
    local fileName = generateFileName(url)
    
    local success, exists = pcall(function()
        return isfile and isfile(fileName)
    end)
    
    if success and exists then
        local assetSuccess, assetId = pcall(function()
            return getcustomasset(fileName)
        end)
        
        if assetSuccess then
            return assetId
        end
    end

    local response = request({
        Url = url,
        Method = "GET",
        Headers = {
            ["Accept"] = "audio/mpeg, audio/ogg, application/octet-stream"
        }
    })

    if response.StatusCode ~= 200 then
        return nil
    end
    
    writefile(fileName, response.Body)
    
    local success, assetId = pcall(function()
        return getcustomasset(fileName)
    end)

    if success then
        return assetId
    end
    
    return nil
end

local function isBossActive()
    local gameData = game.ReplicatedStorage:FindFirstChild("GameData")
    if not gameData then return false end
    local latestRoom = gameData:FindFirstChild("LatestRoom")
    
    local room = latestRoom.Value
    if room == 48 or room == 99 then return true end
    
    for _, sound in pairs(game.ReplicatedStorage:GetDescendants()) do
        if sound:IsA("Sound") and sound.IsPlaying and (sound.Name:find("Music") or sound.Name == "Shade") then
            return true
        end
    end
    return false
end

task.spawn(function()
    local camera = workspace.CurrentCamera
    local shakerModule = game.ReplicatedStorage:FindFirstChild("CameraShaker")
    if not shakerModule then return end
    
    local cameraShaker = require(shakerModule)
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    camShake:Start()

    local gameData = game.ReplicatedStorage:WaitForChild("GameData")
    local latestRoom = gameData:WaitForChild("LatestRoom")
    local ambruhheight = Vector3.new(0, 3, 0)
    local ambruhspeed = 230          -- base speed (dynamic)
    local randomizedtimes = math.random(4, 9)
    local killed = false
    local PlayerGui = game.Players.LocalPlayer.PlayerGui

    local entity = loadModel(15972282065)
    if not entity then return end
    
    entity.Parent = workspace
    local pr = entity:FindFirstChildWhichIsA("BasePart") or entity:FindFirstChildWhichIsA("MeshPart")
    if not pr then return end

    -- ------------------------------------------------------------
    -- DYNAMIC SPEED FUNCTION (distance + room length)
    -- ------------------------------------------------------------
    local function getDynamicSpeed(entityPos, playerPos, nodeCount)
        local baseSpeed = 230
        local speed = baseSpeed

        -- If far from player (>225 studs), double speed
        if playerPos and (entityPos - playerPos).magnitude > 225 then
            speed = speed * 4
        end

        -- If room has many nodes, speed up progressively (cap at +50%)
        if nodeCount >= 6 then
            local extra = (nodeCount - 5) * 0.4  -- +10% per extra node beyond 5
            speed = speed * (1 + math.min(extra, 1))
        end

        return speed
    end
    -- ------------------------------------------------------------

    local function GetTime(dist, speed)
        return dist / speed
    end

    spawn(function()
        if not rep:FindFirstChild("ModulesClient") then return end
        local ROOT = "https://github.com/RegularVynixu/DOORS-Entity-Spawner-V2/raw/main"
        local Assets = {
            Repentance = LoadCustomInstance(ROOT.."/Assets/Repentance.rbxm"),
            Earthquake = LoadCustomInstance(ROOT.."/Assets/Earthquake.rbxm")
        }
        local Modules = {
            Module_Events = require(rep.ModulesClient.Module_Events),
            Main_Game = require(PlayerGui.MainUI.Initiator.Main_Game)
        }
        local Storage = {
            Ambient = {},
            DeathTypes = {
                ["Yellow"] = {"yellow", "curious"},
                ["Blue"] = {"blue", "guiding"}
            }
        }
        local function Earthquake()
            Modules.Main_Game.camShaker:ShakeOnce(4, 12, 1, 5)
            Modules.Main_Game.camShaker:ShakeOnce(10, 2, 3, 3)
            Assets.Earthquake.SoundEarthquake:Play()
            local v5 = CollectionService:GetTagged("PartCeiling")
            local v6 = {}
            for _, v7 in v5 do
                local v8 = v7.Size.Magnitude * 0.7
                local v9 = math.clamp(v8, 0, 150)
                for _, v10 in Assets.Earthquake.Particles:GetChildren() do
                    local v11 = v10:Clone()
                    v11.Parent = v7
                    v11:Emit(v9 / 10)
                    v11.Enabled = true
                    table.insert(v6, v11)
                end
            end
            task.wait(4)
            for _, v12 in v6 do
                v12.Enabled = false
            end
        end
        task.spawn(Earthquake)
    end)

    local function canSeeTarget(target, size)
        if killed then return end
        local origin = pr.Position
        local targetPos = target.HumanoidRootPart.Position
        local direction = (targetPos - pr.Position).unit * size
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRay(ray, pr)
        
        if hit and hit:IsDescendantOf(target) then
            return true
        end
        return false
    end

    task.wait(1)

    -- Kill/Shake Loop
    task.spawn(function()
        while entity and entity.Parent do 
            task.wait(0.1)
            local v = game.Players.LocalPlayer
            if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local root = v.Character.HumanoidRootPart
                
                if canSeeTarget(v.Character, 70) and not v.Character:GetAttribute("Hiding") then
                    killed = true
                    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/wow!.lua"))() end)
                    
                    task.delay(1.3, function()
                        v.Character.Humanoid.Health = 0
                        local stats = rep:FindFirstChild("GameStats")
                        if stats and stats:FindFirstChild("Player_".. v.Name) then
                            stats["Player_".. v.Name].Total.DeathCause.Value = "A-60"
                        end
                        
                        local remotes = rep:FindFirstChild("RemotesFolder") or rep:FindFirstChild("Bricks")
                        if remotes and remotes:FindFirstChild("DeathHint") then
                            if remotes.Name == "RemotesFolder" then
                                if type(firesignal) == "function" then
                                    pcall(firesignal, remotes.DeathHint.OnClientEvent, hints, "Blue")
                                end
                            else
                                if type(firesignal) == "function" then
                                    pcall(firesignal, remotes.DeathHint.OnClientEvent, hints)
                                end
                            end
                        end
                    end)
                end

                if (pr.Position - root.Position).magnitude <= 70 then
                    camShake:ShakeOnce(43, 20, 0.1, 2.3, 1, 6)
                end
            end
        end
    end)

    local gruh = workspace.CurrentRooms

    -- Forward pass with dynamic speed
    local function Forward()
        local limit = latestRoom.Value
        for i = 1, limit do
            local room = gruh:FindFirstChild(tostring(i))
            if room and room:FindFirstChild("Nodes") then
                local nodes = room.Nodes:GetChildren()
                table.sort(nodes, function(a,b) return tonumber(a.Name) < tonumber(b.Name) end)
                local nodeCount = #nodes
                for _, node in ipairs(nodes) do
                    local distance = (pr.Position - node.Position).magnitude
                    -- Compute dynamic speed
                    local playerPos = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character.HumanoidRootPart
                    local currentSpeed = getDynamicSpeed(pr.Position, playerPos and playerPos.Position, nodeCount)
                    local jerk = game.TweenService:Create(pr, TweenInfo.new(GetTime(distance, currentSpeed), Enum.EasingStyle.Linear), {CFrame = node.CFrame + ambruhheight})
                    jerk:Play()
                    jerk.Completed:Wait()
                end
            end
        end
    end

    -- Backward pass with dynamic speed
    local function Backward()
        local limit = latestRoom.Value
        for i = limit, 1, -1 do
            local room = gruh:FindFirstChild(tostring(i))
            if room and room:FindFirstChild("Nodes") then
                local nodes = room.Nodes:GetChildren()
                table.sort(nodes, function(a,b) return tonumber(a.Name) < tonumber(b.Name) end)
                local nodeCount = #nodes
                for n = #nodes, 1, -1 do
                    local node = nodes[n]
                    local distance = (pr.Position - node.Position).magnitude
                    local playerPos = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character.HumanoidRootPart
                    local currentSpeed = getDynamicSpeed(pr.Position, playerPos and playerPos.Position, nodeCount)
                    local jerk = game.TweenService:Create(pr, TweenInfo.new(GetTime(distance, currentSpeed), Enum.EasingStyle.Linear), {CFrame = node.CFrame + ambruhheight})
                    jerk:Play()
                    jerk.Completed:Wait()
                end
            end
        end
    end

    -- --- 🏃 THE REBOUNDS ---
    for i = 1, randomizedtimes do
        pcall(Forward)
        task.wait(1)
        pcall(Backward)
        task.wait(1)
    end

    entity:Destroy()

    local stingDissapear = G.LoadGithubAudio("https://raw.githubusercontent.com/Francisco1692qzd/RevivedOldHardcore/main/Multimonster_sting.mp3.mpeg")
    task.spawn(function()
        GiveAchievement("Multimonster")
    end)

    local light = Instance.new("ColorCorrectionEffect", game.Lighting)
    light.Brightness, light.Saturation, light.Contrast = -0.4, 0.4, -0.5
    light.TintColor = Color3.fromRGB(255, 0, 0)
    
    game.TweenService:Create(light, TweenInfo.new(20), {
        Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.fromRGB(255, 255, 255)
    }):Play()
    
    game.Debris:AddItem(light, 20)
    camShake:ShakeOnce(23, 45, 0, 16, 1, 6)
end)
