-- XENO GITHUB MODEL LOADER (.rbxm / .rbxmx)
local G = getgenv()
local ReplicatedStorage = game.ReplicatedStorage
local remotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder")

G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then return nil end
    
    -- Generate consistent filename from URL
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "cease_" .. tostring(hash) .. ".rbxm"
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

-- ============================================
-- DYNAMIC CEASE WITH CLEANUP
-- ============================================
local function ceasetheroom()
    local ambruhspeed = 45
    local DEF_SPEED = 9999
    local storer = ambruhspeed
    local ambruhheight = Vector3.new(0, 3.4, 0)
    local repStorage = game.ReplicatedStorage
    local gameData = repStorage.GameData
    local latestRoom = gameData.LatestRoom
    local currentRooms = workspace.CurrentRooms
    local entity = nil
    local killed = false
    local rawUrl = "https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/main/cease.rbxm"
    local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
    local camera = workspace.CurrentCamera
    local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
        camera.CFrame = camera.CFrame * cf
    end)
    camShake:Start()
    camShake:Shake(cameraShaker.Presets.Earthquake)

    if G.LoadGithubModel then
        entity = G.LoadGithubModel(rawUrl)
        if entity then
            entity.Parent = workspace
        end
    end

    if not entity then return end
    entity.Silence:Play()

    local entityPart = entity:FindFirstChildWhichIsA("BasePart")
    if not entityPart then return end
    entityPart.Anchored = true

    -- Light effects (unchanged)
    local tweenLights = TweenInfo.new(1)
    local color = {Color = Color3.fromRGB(0, 0, 255)}
    for i, v in pairs(currentRooms:GetDescendants()) do
        if v:IsA("Light") then
            game.TweenService:Create(v, tweenLights, color):Play()
            if v.Parent and v.Parent.Name == "LightFixture" then
                game.TweenService:Create(v.Parent, tweenLights, color):Play()
            end
        end
    end
    local secondColor = {Color = Color3.fromRGB(0, 0, 155)}
    delay(3, function()
        for i, v in pairs(currentRooms:GetDescendants()) do
            if v:IsA("Light") then
                game.TweenService:Create(v, tweenLights, secondColor):Play()
                if v.Parent and v.Parent.Name == "LightFixture" then
                    game.TweenService:Create(v.Parent, tweenLights, secondColor):Play()
                end
            end
        end
    end)

    -- Death detection
    local function canSeeTarget(target, size)
        if killed then return false end
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
        if isBossActive() then return false end
        local origin = entityPart.Position
        local direction = (target.HumanoidRootPart.Position - origin).unit * size
        local ray = Ray.new(origin, direction)
        local hit, pos = workspace:FindPartOnRay(ray, entityPart)
        if hit and hit:IsDescendantOf(target) then
            killed = true
            return true
        end
        return false
    end

    -- Helper: get all nodes of a room in order
    local function getRoomNodes(roomNumber)
        local room = currentRooms:FindFirstChild(tostring(roomNumber))
        if not room then return {} end
        local nodes = room:FindFirstChild("Nodes")
        if not nodes then return {} end
        local nodeList = {}
        for _, child in pairs(nodes:GetChildren()) do
            local num = tonumber(child.Name)
            if num then
                table.insert(nodeList, {num = num, node = child})
            end
        end
        table.sort(nodeList, function(a, b) return a.num < b.num end)
        local sorted = {}
        for _, item in ipairs(nodeList) do
            table.insert(sorted, item.node)
        end
        return sorted
    end

    -- Find the best target room (player's current room - 2, but at least 1)
    local function getTargetRoomNumber()
        local playerRoom = latestRoom.Value
        local target = math.max(1, playerRoom - 2)
        while target > 1 do
            if currentRooms:FindFirstChild(tostring(target)) then
                break
            end
            target = target - 1
        end
        return target
    end

    -- Determine the path of rooms from currentRoom to targetRoom
    local function getRoomPath(currentRoomNum, targetRoomNum)
        local path = {}
        local step = (currentRoomNum < targetRoomNum) and 1 or -1
        local room = currentRoomNum
        while true do
            if currentRooms:FindFirstChild(tostring(room)) then
                table.insert(path, room)
            end
            if room == targetRoomNum then break end
            room = room + step
            if room < 1 or room > 100 then break end
        end
        return path
    end

    -- Movement system
    local moveCoroutine = nil
    local stopMoving = false

    local function startMoving()
        if moveCoroutine then
            stopMoving = true
            task.wait(0.1)
            stopMoving = false
        end
        moveCoroutine = task.spawn(function()
            local currentRoomNumber = getTargetRoomNumber()
            local currentNodes = getRoomNodes(currentRoomNumber)
            local nodeIndex = 1
            if #currentNodes == 0 then
                while not stopMoving do
                    task.wait(0.5)
                end
                return
            end

            local function moveToNode(node)
                local dist = (entityPart.Position - node.Position).magnitude
                local speed = (currentRoomNumber == latestRoom.Value) and 45 or 9999
                local duration = dist / speed
                if duration < 0.01 then duration = 0.01 end
                local tween = game.TweenService:Create(entityPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = node.CFrame + ambruhheight})
                tween:Play()
                tween.Completed:Wait()
            end

            while not stopMoving do
                local targetRoom = getTargetRoomNumber()
                if currentRoomNumber ~= targetRoom then
                    local roomPath = getRoomPath(currentRoomNumber, targetRoom)
                    for _, roomNum in ipairs(roomPath) do
                        if stopMoving then break end
                        local nodes = getRoomNodes(roomNum)
                        for _, node in ipairs(nodes) do
                            if stopMoving then break end
                            moveToNode(node)
                        end
                        currentRoomNumber = roomNum
                        task.wait(0.05)
                    end
                else
                    local nodes = getRoomNodes(currentRoomNumber)
                    if #nodes > 0 then
                        for _, node in ipairs(nodes) do
                            if stopMoving then break end
                            moveToNode(node)
                        end
                        for i = #nodes, 1, -1 do
                            if stopMoving then break end
                            moveToNode(nodes[i])
                        end
                    else
                        task.wait(0.5)
                    end
                end
                task.wait(0.1)
            end
        end)
    end

    startMoving()

    -- ============================================
    -- DESPAWN FUNCTION (cleanup)
    -- ============================================
    local function despawnCease()
        if not entity or not entity.Parent then return end
        if moveCoroutine then
            stopMoving = true
            task.wait(0.1)
            task.cancel(moveCoroutine)
            moveCoroutine = nil
        end
        if entityPart then
            entityPart.Anchored = false
            entityPart.CanCollide = false
        end
        game.Debris:AddItem(entity, 5)
        print("💀 Cease despawned (cleanup)")
    end

    -- Despawn when player reaches Door 100
    local roomListener
    roomListener = latestRoom.Changed:Connect(function()
        if latestRoom.Value >= 100 then
            roomListener:Disconnect()
            despawnCease()
        end
    end)

    -- Safety timer: despawn after 5 minutes (in case player never reaches 100)
    task.delay(300, function()
        if entity and entity.Parent then
            if roomListener then roomListener:Disconnect() end
            despawnCease()
        end
    end)

    -- Death detection loop (unchanged)
    spawn(function()
        while entity and entity.Parent and entityPart do
            task.wait(0.01)
            local player = game.Players.LocalPlayer
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if canSeeTarget(player.Character, 60) and player.Character.Humanoid.MoveDirection.Magnitude > 0 then
                    player.Character.Humanoid:TakeDamage(100)
                    game.ReplicatedStorage.GameStats["Player_".. player.Character.Name].Total.DeathCause.Value = "Cease"
                    local hints = {
                        "You died to Cease...",
                        "Maybe trying to not move when he's nearby?"
                    }
                    if ReplicatedStorage:FindFirstChild("RemotesFolder") then
                        firesignal(ReplicatedStorage.RemotesFolder.DeathHint.OnClientEvent, hints, "Blue")
                    elseif ReplicatedStorage:FindFirstChild("Bricks") then
                        firesignal(ReplicatedStorage.Bricks.DeathHint.OnClientEvent, hints, "Blue")
                    end
                    -- also despawn after death? (optional)
                    despawnCease()
                end
            end
            if player.Character and (entityPart.Position - player.Character.HumanoidRootPart.Position).magnitude <= 60 then
                camShake:ShakeOnce(2.4, 25, 0.5, 2, 1, 6)
            end
        end
    end)

    -- If entity is manually removed, clean up listeners
    entity.AncestryChanged:Connect(function()
        if not entity.Parent then
            if roomListener then roomListener:Disconnect() end
            stopMoving = true
            if moveCoroutine then
                task.cancel(moveCoroutine)
                moveCoroutine = nil
            end
        end
    end)
end

pcall(ceasetheroom)
