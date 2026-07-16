pcall(function()
local G = getgenv()
local ReplicatedStorage = game.ReplicatedStorage

G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then
        return nil
    end
    
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "ripperplus_" .. tostring(hash) .. ".rbxm"
    end
    
    local fileName = generateFileName(url)
    
    local fileExists = false
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
    local success, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    
    if success and result then return result end
    return nil
end

G.LoadGithubAudio = function(url)
    if not (writefile and getcustomasset and request) then return nil end

    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "ripper_" .. tostring(hash) .. ".mp3"
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

    local cleanUrl = url .. "?t=" .. math.random(1, 100000)

    local response = request({
        Url = cleanUrl,
        Method = "GET",
        Headers = {
            ["Accept"] = "audio/mpeg, audio/ogg, application/octet-stream"
        }
    })

    if response.StatusCode ~= 200 then
        warn("Xeno: Falha no download. Status: " .. response.StatusCode)
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

local function SPAWNHORROR()
    local breakMove = false
    local killed = false
    local repStorage = game.ReplicatedStorage
    local gameData = repStorage.GameData
    local latestRoom = gameData.LatestRoom
    local currentRooms = workspace.CurrentRooms
    local entity = nil
    local ambruhspeed = 150
    local val = 60
    local DEF_SPEED = 99999
    local storer = ambruhspeed
    local ambruhheight = Vector3.new(0,8,0)
    
	local success, result = pcall(function() return require(repStorage.CameraShaker) end)
	if not success then warn("Module failed to load, but script is still running!") end
    local camera = workspace.CurrentCamera
    local camShake = result.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
	pcall(function()
    camShake:Start()
    camShake:Shake(result.Presets.Earthquake)
	camShake:Shake(result.Presets.Earthquake)
	camShake:Shake(result.Presets.Bump)
	end)
	
	local rawURL = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/main/ripperr.rbxm"
	local gameCrashURL = "https://raw.githubusercontent.com/DripCapybara/Doors-Modes/main/HardcoreMode/game%20crash%20sound.mp3"
	
	if G.LoadGithubModel then
        entity = G.LoadGithubModel(rawURL)
        if entity then
            entity.Parent = workspace
        end
    end

    if not entity then return end 
    
	local tweenLights = TweenInfo.new(1)
    local color = {Color = Color3.fromRGB(255, 0, 0)}
    for i, v in pairs(currentRooms[latestRoom.Value]:GetDescendants()) do
        if v:IsA("Light") then
            game.TweenService:Create(v, tweenLights, color):Play()
            if v.Parent.Name == "LightFixture" then
                game.TweenService:Create(v.Parent, tweenLights, color):Play()
            end
        end
    end
    for i, v in pairs(currentRooms[latestRoom.Value - 1]:GetDescendants()) do
        if v:IsA("Light") then
            game.TweenService:Create(v, tweenLights, color):Play()
            if v.Parent.Name == "LightFixture" then
                game.TweenService:Create(v.Parent, tweenLights, color):Play()
            end
        end
    end
	for i, v in pairs(currentRooms[latestRoom.Value - 1]:GetDescendants()) do
        if v:IsA("Light") then
            game.TweenService:Create(v, tweenLights, color):Play()
            if v.Parent.Name == "LightFixture" then
                game.TweenService:Create(v.Parent, tweenLights, color):Play()
            end
        end
    end	
    local spawnSound = entity.Ripe.Spawn:Clone()
    entity.Ripe.Spawn:Destroy()
    spawnSound.Parent = workspace
    spawnSound.TimePosition = 0
    spawnSound.Looped = false
	spawnSound.Volume = 10
    spawnSound:Play()
    
    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
	local slam = Instance.new("Sound", entityPart)
    slam.Volume = 10
    slam.SoundId = "rbxassetid://1837829565"

    for _, sound in pairs(entityPart:GetChildren()) do
        if (sound:IsA("Sound") and sound.Name == "Screams of dah damneddd") then
			local soundClone = sound:Clone()
            local dist = Instance.new("DistortionSoundEffect", soundClone)
            dist.Level = 0.32
            dist.Parent = soundClone
			local dist2 = Instance.new("DistortionSoundEffect", sound)
			dist.Level = 0.32
			dist.Parent = sound
            print("added")
        end
    end

    local function canSeeTarget(target, size)
        if killed == true then return end
local function isBossActive()
    local room = latestRoom.Value
    if room == 50 or room == 100 then return true end
    
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
        local hit = workspace:FindPartOnRay(ray, entityPart)
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

	pcall(function()
    	task.spawn(function()
        	while entityPart ~= nil and entity ~= nil do wait(0.2)
            	local v = game.Players.LocalPlayer
            	if v.Character ~= nil and v.Character.HumanoidRootPart then
                	if canSeeTarget(v.Character, 50) and not v.Character:GetAttribute("Hiding") then
                    	breakMove = true
                    	local gui = Instance.new("ScreenGui", v:WaitForChild("PlayerGui"))
                    	gui.Name = "Noise"
                    	gui.IgnoreGuiInset = true
                    	local img = Instance.new("ImageLabel", gui)
                    	img.Size = UDim2.new(1, 0, 1, 0)
                    	img.BackgroundTransparency = 1
                    	img.Image = "rbxassetid://236542974"
                    	img.ImageTransparency = 1

                    	coroutine.wrap(function()
                        	local char = v.Character
                        	local ripper = entityPart
                        	local clone = ripper and ripper:Clone()
                        	if not clone then return end
                        	clone.Parent = workspace
                        	clone.Position = ripper.Position
                        	for _, x in ipairs(clone:GetDescendants()) do
                            	if x:IsA("ParticleEmitter") then
                                	spawn(function() x.Rate = 9999; wait(0.25); x.TimeScale = 0.0 end)
                            	elseif x:IsA("Sound") then x.Volume = 0 end
                        	end
                        	entity:Destroy()
							local crash = Instance.new("Sound", workspace)
							crash.SoundId = G.LoadGithubAudio(gameCrashURL)
							crash.Volume = 4
							crash:Play()
                        	local static = Instance.new("Sound", workspace)
                        	static.SoundId = "rbxassetid://372770465"
                        	static.Volume = 10
                        	static.Pitch = 0.7
                        	local anchor = Instance.new("Part", workspace)
                        	anchor.Name = "ripperAnchor"
                        	anchor.Anchored = true
                        	anchor.CanCollide = false
                        	anchor.Transparency = 1
                        	anchor.CFrame = workspace.CurrentCamera.CFrame
                        	char:FindFirstChild("HumanoidRootPart").Anchored = true
                        	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                        	local viewLoop = true
                        	spawn(function()
                            	while viewLoop do
                                	workspace.CurrentCamera.CFrame = anchor.CFrame
                                	img.Image = "rbxassetid://"..({8482795900,236542974,184251462,236777652})[math.random(1,4)]
                                	game["Run Service"].RenderStepped:Wait()
                            	end
                        	end)
                        	game.TweenService:Create(anchor, TweenInfo.new(0.3), {CFrame = CFrame.lookAt(anchor.Position, clone.Position)}):Play()
                        	wait(1)
                        	game.TweenService:Create(img, TweenInfo.new(2), {ImageTransparency = 0}):Play()
                        	static:Play()
                        	wait(2)
                        	viewLoop = false
                        	game.TweenService:Create(img, TweenInfo.new(1), {ImageTransparency = 1}):Play()
                        	static:Destroy()
                        	char:FindFirstChild("HumanoidRootPart").Anchored = false
                        	game.ReplicatedStorage.GameStats["Player_" .. v.Character.Name].Total.DeathCause.Value = "Ripper"
                        	char:FindFirstChildWhichIsA("Humanoid"):TakeDamage(100)
                        	local hints = {
                            	"The lights turn red. Hide, now.",
                            	"It will come back. Stay hidden until you're sure it's safe.",
                            	"Silence doesn't mean it's gone. Wait for the door to return to normal."
                        	}
                        		if ReplicatedStorage:FindFirstChild("RemotesFolder") then
									local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
			                    	firesignal(remotesFolder.DeathHint.OnClientEvent, hints, "Blue")
								elseif ReplicatedStorage:FindFirstChild("Bricks") then
									local remotesFolder = ReplicatedStorage:FindFirstChild("Bricks")
			                    	firesignal(remotesFolder.DeathHint.OnClientEvent, hints)
								end
                    	end)()
                	end
            	end
            	if v.Character ~= nil and v.Character.HumanoidRootPart and (entityPart.Position - v.Character.HumanoidRootPart.Position).magnitude <= 60 then
                	camShake:ShakeOnce(15, 25, 0, 2, 1, 6)
            	end
            	if breakMove then break end
        	end
    	end)
	end)

    entityPart.Rushing:Stop()
    entityPart.RushingFar:Stop()
    wait(8)
    entityPart.Rushing:Play()
    entityPart.RushingFar:Play()
    game.TweenService:Create(entityPart.Rushing, TweenInfo.new(6), {Volume = 0.8}):Play()
    game.TweenService:Create(entityPart.RushingFar, TweenInfo.new(6), {Volume = 0.8}):Play()
    ambruhspeed = DEF_SPEED

	pcall(function()
        -- Go through ALL rooms from 1 to latestRoom
        for i = 1, latestRoom.Value do
            local room = currentRooms:FindFirstChild(tostring(i))
            if room and room:FindFirstChild("Nodes") then
                local nodes = room:WaitForChild("Nodes", 5)
                for v_idx = 1, #nodes:GetChildren() do
                    local node = nodes:FindFirstChild(tostring(v_idx))
                    if node then
                        if breakMove then break end
                        local dist = (entityPart.Position - node.Position).magnitude
                        local bruh = game.TweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0,false,0), {CFrame = node.CFrame + ambruhheight})
                        bruh:Play()
                        bruh.Completed:Wait()
                        ambruhspeed = storer
                        if room.Name == nodes.Parent.Name then
                            pcall(function() room.Door.ClientOpen:FireServer() end)
                        end
                    end
                end
            end
            local soundHit = Instance.new("Sound") game.Debris:AddItem(soundHit, 3)
            soundHit.SoundId = "rbxassetid://5188314808"
            soundHit.Volume = 10
            soundHit:Play()
            camShake:ShakeOnce(10, 8, 0, 4, 1, 6)
            if breakMove then break end
        end
        
        -- Now REBOUND within the CURRENT ROOM only
        if not breakMove then
            local currentRoom = latestRoom.Value
            local room = currentRooms:FindFirstChild(tostring(currentRoom))
            
            if room and room:FindFirstChild("Nodes") then
                local nodes = room:WaitForChild("Nodes", 5)
                
                -- Go backwards through the current room
                for v_idx = #nodes:GetChildren(), 1, -1 do
                    local node = nodes:FindFirstChild(tostring(v_idx))
                    if node then
                        if breakMove then break end
                        local dist = (entityPart.Position - node.Position).magnitude
                        local bruh = game.TweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0,false,0), {CFrame = node.CFrame + ambruhheight})
                        bruh:Play()
                        bruh.Completed:Wait()
                        ambruhspeed = storer
                    end
                end
                
                -- Then go forward through the current room again
                if not breakMove then
                    for v_idx = 1, #nodes:GetChildren() do
                        local node = nodes:FindFirstChild(tostring(v_idx))
                        if node then
                            if breakMove then break end
                            local dist = (entityPart.Position - node.Position).magnitude
                            local bruh = game.TweenService:Create(entityPart, TweenInfo.new(GetTime(dist, ambruhspeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0,false,0), {CFrame = node.CFrame + ambruhheight})
                            bruh:Play()
                            bruh.Completed:Wait()
                            ambruhspeed = storer
                        end
                    end
                end
            end
        end
	end)

	local soundHit = Instance.new("Sound") game.Debris:AddItem(soundHit, 3)
	soundHit.SoundId = "rbxassetid://5188314808"
	soundHit.Volume = 10
	soundHit:Play()
	camShake:ShakeOnce(10, 8, 0, 4, 2, 6)
	task.wait(soundHit.TimeLength + 0.35)
    camShake:Shake(result.Presets.Explosion)
    camShake:Shake(result.Presets.Explosion)
    pcall(function() workspace.CurrentRooms[latestRoom.Value].Door.ClientOpen:FireServer() end)
    slam:Play()
    slam.Volume = 10500
    local dist = Instance.new("DistortionSoundEffect", slam)
    dist.Level = 0.6
    wait(1)
    entityPart.Anchored = false
    entityPart.CanCollide = false
	--[[local AchievementModule = game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
	if AchievementModule == nil then return end
	if workspace:FindFirstChild("RipperAchievement") then return end
	if not game.ReplicatedStorage:FindFirstChild("ModulesShared") then return end
	local dataModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ModulesShared"):WaitForChild("Achievements"))
	local unlockFunc = require(AchievementModule)--]]
	if not workspace:FindFirstChild("RipperAchievement") then
		GiveAchievement("Ripper")
	end
	local ObtainedBadge = Instance.new("BoolValue")
	ObtainedBadge.Name = "RipperAchievement"
	ObtainedBadge.Value = true
	ObtainedBadge.Parent = workspace
    game.Debris:AddItem(entity, 5)
end
task.spawn(function() pcall(SPAWNHORROR) end)
end)
