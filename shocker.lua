local G = getgenv()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [1] MODEL LOADER
G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then return nil end
    
    local rawUrl = url:gsub("github.com", "raw.githubusercontent.com"):gsub("/blob/", "/")
    
    -- Generate consistent filename from URL
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "shocker_final_fix_" .. tostring(hash) .. ".rbxm"
    end
    
    local fileName = generateFileName(rawUrl)
    
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
    local response = request({Url = rawUrl, Method = "GET"})
    if response.StatusCode ~= 200 then return nil end
    
    writefile(fileName, response.Body)
    local assetId = getcustomasset(fileName)
    
    local success, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    return success and result or nil
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

-- [2] ENTITY: SHOCKER
local function SpawnShocker()
    local LP = game.Players.LocalPlayer
    local Char = LP.Character or LP.CharacterAdded:Wait()
    local Hum = Char:WaitForChild("Humanoid")
    local Root = Char:WaitForChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        cam.CFrame = cam.CFrame * cf
    end)
    camShake:Start()
    
    local modelUrl = "https://github.com/Francisco1692qzd/RevivedOldHardcore/blob/main/oldShocker.rbxm"
    local entity = G.LoadGithubModel(modelUrl)

    if not entity then return end

    local mainPart = entity:FindFirstChild("OOGA BOOGAAAA")
    if not mainPart then return end

    -- Configuração Vital
    entity.PrimaryPart = mainPart
    mainPart.Anchored = true
    mainPart.CanCollide = true
    
    entity:PivotTo(Root.CFrame * CFrame.new(0, 0, -12))
    entity.Parent = workspace

    local spawnSound = entity:FindFirstChild("PlaySound")
    local attackSound = mainPart:FindFirstChild("HORROR SCREAM 15")
    
    if spawnSound then spawnSound:Play() end

    local lookingTime = 0
    local hasAttacked = false
    local isLookingAtSpawn = false -- Track initial look state

    -- IMPROVED: Better line-of-sight and angle detection
    local function isPlayerLooking()
        -- Check if entity is on screen
        local entityPos = mainPart.Position
        local vector, onScreen = cam:WorldToViewportPoint(entityPos)
        
        if not onScreen then return false end
        
        -- Calculate angle between camera look vector and direction to entity
        local cameraToEntity = (entityPos - cam.CFrame.Position).Unit
        local dotProduct = cameraToEntity:Dot(cam.CFrame.LookVector)
        
        -- More forgiving angle threshold (0.7 = ~45 degrees)
        return dotProduct > 0.7
    end

    -- Fix sound properties
    for i, v in pairs(entity:GetChildren()) do
        if (v:IsA("Sound") and v.Name == "PlaySound") then
            if v.PlayOnRemove == true then v.PlayOnRemove = false end
        end
    end

    -- CHECK INITIAL LOOK STATE BEFORE MAIN LOOP
    task.wait(0.1) -- Small delay to ensure everything is loaded
    if not isPlayerLooking() then
        -- Player is NOT looking at spawn - entity should ignore and disappear
        mainPart.Anchored = false
        mainPart.CanCollide = false
        --[[local AchievementModule = game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
  	    if AchievementModule == nil then return end
  	    if workspace:FindFirstChild("ShockerAchievement") then return end
  	    if not game.ReplicatedStorage:FindFirstChild("ModulesShared") then return end
  	    local dataModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ModulesShared"):WaitForChild("Achievements"))
  	    local unlockFunc = require(AchievementModule)--]]
  	    if not workspace:FindFirstChild("ShockerAchievement") then
  		      GiveAchievement("Shocker")
  	    end
  	    local ObtainedBadge = Instance.new("BoolValue")
  	    ObtainedBadge.Name = "ShockerAchievement"
  	    ObtainedBadge.Value = true
  	    ObtainedBadge.Parent = workspace
        task.wait(6)
        if entity then entity:Destroy() end
        --camShake:Stop()
        return
    end

    task.spawn(function()
        local lastLookState = isPlayerLooking()
        local timeSinceLastLook = 0
        
        while entity and entity.Parent and not hasAttacked do
            task.wait(0.05)
            
            local currentLookState = isPlayerLooking()
            
            -- FIXED: Proper look tracking logic
            if currentLookState then
                -- Player is looking at entity
                if not lastLookState then
                    -- Just started looking
                    lookingTime = 0
                end
                lookingTime = lookingTime + 0.05
                timeSinceLastLook = 0
            else
                -- Player is NOT looking at entity
                timeSinceLastLook = timeSinceLastLook + 0.05
                
                -- If player looked away and look time was between threshold
                if lookingTime > 0.1 and lookingTime < 1.9 and timeSinceLastLook > 0.1 then
                    -- Entity ignores player and disappears
                    mainPart.Anchored = false
                    mainPart.CanCollide = false
                    --[[local AchievementModule = game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
	                if AchievementModule == nil then return end
	                if workspace:FindFirstChild("ShockerAchievement") then return end
	                if not game.ReplicatedStorage:FindFirstChild("ModulesShared") then return end
	                local dataModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ModulesShared"):WaitForChild("Achievements"))
	                local unlockFunc = require(AchievementModule)]]
	                if not workspace:FindFirstChild("ShockerAchievement") then
			  		      GiveAchievement("Shocker")
			  	    end
			  	    local ObtainedBadge = Instance.new("BoolValue")
			  	    ObtainedBadge.Name = "ShockerAchievement"
			  	    ObtainedBadge.Value = true
			  	    ObtainedBadge.Parent = workspace
                    task.wait(6)
                    if entity then entity:Destroy() end
                    break
                end
                
                -- Reset looking time if player isn't looking
                if timeSinceLastLook > 0.5 then
                    lookingTime = 0
                end
            end
            
            lastLookState = currentLookState

            -- [ATTACK LOGIC]
            if lookingTime >= 1.9 and not hasAttacked then
                hasAttacked = true
                
                -- Play attack sound
                if attackSound then attackSound:Play() end
                
                -- Prepare tween for attack movement
                mainPart.Anchored = true
                mainPart.CanCollide = true
                
                local attackTween = game:GetService("TweenService"):Create(mainPart, 
                    TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), 
                    {CFrame = Root.CFrame}
                )
                
                attackTween:Play()
                
                -- Deal damage after visual impact
                task.delay(0.37, function()
                    if Hum and Hum.Health > 0 then
                        Hum:TakeDamage(25)
                        camShake:Shake(cameraShaker.Presets.Explosion)
                        
                        -- Set death cause
                        local statsFolder = game.ReplicatedStorage:FindFirstChild("GameStats")
                        if statsFolder then
                            local playerStat = statsFolder:FindFirstChild("Player_" .. Char.Name)
                            if playerStat and playerStat:FindFirstChild("Total") then
                                local total = playerStat.Total
                                if total:FindFirstChild("DeathCause") then
                                    total.DeathCause.Value = "Shocker"
                                end
                            end
                        end
                        
                        -- Show death hints
                        local hints = {
                            "You died to who you call Shocker...",
                            "Don't look at it or it stuns you!"
                        }
                        
                        if ReplicatedStorage:FindFirstChild("RemotesFolder") then
                            local remotesFolder = ReplicatedStorage:FindFirstChild("RemotesFolder")
                            if remotesFolder:FindFirstChild("DeathHint") then
                                firesignal(remotesFolder.DeathHint.OnClientEvent, hints, "Blue")
                            end
                        elseif ReplicatedStorage:FindFirstChild("Bricks") then
                            local remotesFolder = ReplicatedStorage:FindFirstChild("Bricks")
                            if remotesFolder:FindFirstChild("DeathHint") then
                                firesignal(remotesFolder.DeathHint.OnClientEvent, hints)
                            end
                        end
                    end
                end)

                -- Cleanup after attack
                attackTween.Completed:Wait()
                task.wait(0.75)
                if entity then entity:Destroy() end
                --camShake:Stop()
                break
            end
        end
    end)
end

task.spawn(SpawnShocker)
