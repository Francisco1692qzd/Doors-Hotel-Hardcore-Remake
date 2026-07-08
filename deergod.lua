-- XENO GITHUB MODEL LOADER (.rbxm / .rbxmx)
local G = getgenv()
local ReplicatedStorage = game.ReplicatedStorage

-- Garantindo que a função exista no ambiente Global
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then
        return nil
    end
    
    -- Generate consistent filename from URL
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "deer_god_" .. tostring(hash) .. ".rbxm"
    end
    
    local fileName = generateFileName(url)
    
    -- Check if file exists and try to load it
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
    
    -- Download new model if not exists or failed to load
    local response = request({Url = url, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    
    writefile(fileName, response.Body)
    local assetId = getcustomasset(fileName)
    local success, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    
    if success and result then return result end
    return nil
end

G.LoadGithubAudio = function(url)
    if not (writefile and getcustomasset and request) then
        warn("Xeno: Missing required functions (writefile, getcustomasset, request)")
        return nil
    end

    -- Extract the base URL without query parameters (for consistent filename)
    local baseUrl = url:match("^([^%?]+)") or url

    -- Generate a deterministic filename from the base URL
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "audiodeer_" .. tostring(hash) .. ".mp3"
    end
    local fileName = generateFileName(baseUrl)

    -- Check if the file already exists locally
    local fileExists = pcall(isfile, fileName) and isfile(fileName)
    if fileExists then
        -- Try to load the existing file
        local success, assetId = pcall(getcustomasset, fileName)
        if success then
            --print("✅ Áudio carregado do cache: " .. fileName)
            return assetId
        else
            warn("Xeno: Falha ao carregar arquivo existente – " .. tostring(assetId))
            -- Fall through to re-download (optional: you could also delete the corrupt file here)
        end
    else
        print("Xeno: Áudio não encontrado no cache, baixando...")
    end

    -- Download with cache-busting (only affects the request, not the stored filename)
    local cacheBuster = "t=" .. math.random(1, 100000)
    local downloadUrl = baseUrl .. (baseUrl:find("%?") and "&" or "?") .. cacheBuster

    local response = request({
        Url = downloadUrl,
        Method = "GET",
        Headers = {
            ["Accept"] = "audio/mpeg, audio/ogg, application/octet-stream"
        }
    })

    if response.StatusCode ~= 200 then
        warn("Xeno: Falha no download. Status: " .. response.StatusCode)
        return nil
    end

    -- Save the file
    local writeSuccess, writeErr = pcall(function()
        writefile(fileName, response.Body)
    end)
    if not writeSuccess then
        warn("Xeno: Falha ao escrever arquivo: " .. tostring(writeErr))
        return nil
    end

    -- Load the newly downloaded asset
    local loadSuccess, assetId = pcall(getcustomasset, fileName)
    if loadSuccess then
        --print("✅ Áudio baixado e carregado: " .. fileName)
        return assetId
    else
        warn("Xeno: Falha no getcustomasset após download: " .. tostring(assetId))
        return nil
    end
end

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

-- Global function to add custom achievement
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

-- Global function to trigger popup
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

local function DeerGod()
    local ambruhspeed = 15
    local DEF_SPEED = 99999
    local storer = ambruhspeed
    local ambruhheight = Vector3.new(0, 3.4, 0)
    local repStorage = game.ReplicatedStorage
    local gameData = repStorage.GameData
    local latestRoom = gameData.LatestRoom
    local currentRooms = workspace.CurrentRooms
    local entity = nil
    local killed = false
    local deergodId = "rbxassetid://12262883448"
    local entity = game:GetObjects(deergodId)[1]
    entity.Parent = workspace
    local chaseTheme = G.LoadGithubAudio("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/main/DeerGodChaseTheme.mp3")
    local chaseMusic = Instance.new("Sound")
    chaseMusic.Parent = workspace
    chaseMusic.SoundId = chaseTheme
    chaseMusic.Volume = 3
    chaseMusic.Looped = true
    chaseMusic:Play()
	local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
	local camera = workspace.CurrentCamera
	local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
		camera.CFrame = camera.CFrame * cf
	end)
	camShake:Start()

    if not entity then return end

    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
    local function canSeeTarget(target, size)
        if killed == true then
            return
        end
local function isBossActive()
    local room = latestRoom.Value
    if room == 50 or room == 100 then return true end
    
    -- Check for any playing music in ReplicatedStorage that might indicate a cutscene
    for _, sound in pairs(game.ReplicatedStorage:GetDescendants()) do
        if sound:IsA("Sound") and sound.IsPlaying and (sound.Name:find("Music") or sound.Name == "Shade") then
            return true
        end
    end
    return false
end

if isBossActive() then return end

        local origin = entityPart.Position
        local direction = (target.HumanoidRootPart.Position - origin).unit * size
        local ray = Ray.new(origin, direction)

        local hit, pos = workspace:FindPartOnRay(ray, entityPart)

        if hit then
            if hit:IsDescendantOf(target) then
                killed = true
                return true
            end
        else
            return false
        end
    end
    local function GetTime(dist, speed)
        return dist / speed
    end
    wait(1)
    spawn(function()
        while entity ~= nil and entityPart ~= nil do wait(0.01)
            local v = game.Players.LocalPlayer
            if v.Character ~= nil and v.Character.HumanoidRootPart then
                if canSeeTarget(v.Character, 50) and not v.Character:GetAttribute("Hiding") then
                    v.Character.Humanoid:TakeDamage(100)
                    game.ReplicatedStorage.GameStats["Player_".. v.Character.Name].Total.DeathCause.Value = "Deer God"
                            local hints = {
                                "You died to Dear god...",
                                "Hide wont work, so try running",
                                "Avoid eye contact!"
                            }
							if ReplicatedStorage:FindFirstChild("RemotesFolder") then
								local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
			                    firesignal(remotesFolder.DeathHint.OnClientEvent, hints, "Blue")
							elseif ReplicatedStorage:FindFirstChild("Bricks") then
								local remotesFolder = ReplicatedStorage:FindFirstChild("Bricks")
			                    firesignal(remotesFolder.DeathHint.OnClientEvent, hints, "Blue")
							end
                end
            end
        end
    end)
	spawn(function()
        while entity ~= nil and entityPart ~= nil do wait(1.6)
			if entity.Parent ~= nil and entityPart.Parent ~= nil then
				camShake:Shake(cameraShaker.Presets.Earthquake)
			end
		end
	end)

    ambruhspeed = DEF_SPEED
    for i = 1, latestRoom.Value + 1 do
        if currentRooms:FindFirstChild(i) then
            local room = currentRooms[i]
            if room and room:FindFirstChild("Nodes") then
                local nodes = room:FindFirstChild("Nodes")
                for v = 1, #nodes:GetChildren() do
                    if nodes:FindFirstChild(v) then
                        local node = nodes[v]
                        local dist = (entityPart.Position - node.Position).magnitude
                        local jerk = game.TweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0,false,0), {CFrame = node.CFrame + ambruhheight})
                        jerk:Play()
                        jerk.Completed:Wait()
                        ambruhspeed = storer
                    end
                end
            end
        end
    end
    game.TweenService:Create(entityPart, TweenInfo.new(0.5), {CFrame = entityPart.CFrame * CFrame.new(0,-80,0)}):Play()
    game.Debris:AddItem(entity, 0.5)
    wait(0.5)
    chaseMusic:Destroy()
	wait(1)
	--[[local AchievementModule = game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
	if AchievementModule == nil then return end
	if workspace:FindFirstChild("DeerGodAchievement") then return end
	if not game.ReplicatedStorage:FindFirstChild("ModulesShared") then return end
	local dataModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ModulesShared"):WaitForChild("Achievements"))
	local unlockFunc = require(AchievementModule)--]]
	if not workspace:FindFirstChild("DeerGodAchievement") then
		GiveAchievement("DeerGod")
	end
	local ObtainedBadge = Instance.new("BoolValue")
	ObtainedBadge.Name = "DeerGodAchievement"
	ObtainedBadge.Value = true
	ObtainedBadge.Parent = workspace
end
pcall(DeerGod)
