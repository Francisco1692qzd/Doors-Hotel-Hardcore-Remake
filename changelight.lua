-- placeid :6839171747
local function LoadGithubModel(url, AssetName)
    print("[Debug] LoadGithubModel called with URL:", url)
    
    if not (writefile and getcustomasset and request) then
        warn("[Debug] Missing required functions (writefile, getcustomasset, request).")
        return nil
    end
    
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        return "LoadedModel_" .. AssetName .. "_" .. tostring(hash) .. ".rbxm"
    end
    
    local fileName = generateFileName(url)
    print("[Debug] Generated filename:", fileName)
    
    -- Check if file exists
    local success, exists = pcall(function()
        return isfile and isfile(fileName)
    end)
    
    if success and exists then
        print("[Debug] File exists, attempting to load from cache.")
        local assetId = getcustomasset(fileName)
        local loadSuccess, result = pcall(function()
            return game:GetObjects(assetId)[1]
        end)
        
        if loadSuccess and result then
            print("[Debug] Loaded model from cache successfully.")
            return result
        else
            warn("[Debug] Failed to load from cache, will re-download.")
        end
    else
        print("[Debug] File not found, downloading.")
    end
    
    -- Download
    local response = request({Url = url, Method = "GET"})
    if response.StatusCode ~= 200 then
        warn("[Debug] Download failed with status:", response.StatusCode)
        return nil
    end
    print("[Debug] Download successful, size:", #response.Body)
    
    writefile(fileName, response.Body)
    local assetId = getcustomasset(fileName)
    local loadSuccess, result = pcall(function()
        return game:GetObjects(assetId)[1]
    end)
    
    if loadSuccess and result then
        print("[Debug] Loaded model from download successfully.")
        return result
    else
        warn("[Debug] Failed to load model from downloaded file.")
        return nil
    end
end

local function ProcessRoom(room)
    print("[Debug] Processing room:", room.Name)
    
    if not room:IsA("Model") then
        print("[Debug] Room is not a Model, skipping.")
        return
    end
    
    local assets = room:FindFirstChild("Assets")
    if not assets then
        print("[Debug] Room has no 'Assets' folder, skipping.")
        return
    end
    print("[Debug] Found Assets folder.")
    
    local lightFixtures = assets:FindFirstChild("Light_Fixtures")
    if not lightFixtures then
        print("[Debug] Assets has no 'Light_Fixtures' folder, skipping.")
        return
    end
    print("[Debug] Found Light_Fixtures folder.")
    
    local foundAny = false
    for _, light in pairs(lightFixtures:GetChildren()) do
        if light:IsA("Model") and light.Name:find("LightStand") then
            foundAny = true
            print("[Debug] Found LightStand model:", light.Name)
            
            local lightFixture = light:FindFirstChild("LightFixture")
            if not lightFixture then
                print("[Debug] LightFixture model has no child 'LightFixture', skipping.")
                continue
            end
            print("[Debug] Found LightFixture child.")
            
            local neon = lightFixture:FindFirstChild("Neon")
            if not neon then
                print("[Debug] LightFixture has no 'Neon', skipping.")
                continue
            end
            print("[Debug] Found Neon part.")
            
            -- Load the model
            print("[Debug] Loading model from GitHub...")
            local lightModel = LoadGithubModel("https://github.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/raw/refs/heads/main/fuck.rbxm", "LightAsset")
            if not lightModel then
                warn("[Debug] Failed to load light model.")
                continue
            end
            print("[Debug] Light model loaded successfully.")
            
            lightModel.Parent = workspace
            
            -- Copy attachments
            local attachmentCount = 0
            for _, attachment in pairs(lightModel:GetChildren()) do
                if attachment:IsA("Attachment") then
                    local newAttachment = attachment:Clone()
                    newAttachment.Parent = neon
                    attachmentCount = attachmentCount + 1
                end
            end
            print("[Debug] Copied", attachmentCount, "attachments to Neon.")
            
            -- Destroy the model
            lightModel:Destroy()
            print("[Debug] Light model destroyed.")
        end
    end
    
    if not foundAny then
        print("[Debug] No LightFixture models found in Light_Fixtures.")
    end
end

-- Wait for CurrentRooms to exist
local gruh = workspace:FindFirstChild("CurrentRooms")
if not gruh then
    print("[Debug] CurrentRooms not found, waiting for it...")
    gruh = workspace:WaitForChild("CurrentRooms", 10)
    if not gruh then
        warn("[Debug] CurrentRooms not found after waiting. Aborting.")
        return
    end
end
print("[Debug] CurrentRooms found, processing existing rooms...")

-- Process existing rooms
local roomsProcessed = 0
for _, room in pairs(gruh:GetChildren()) do
    if room:IsA("Model") then
        ProcessRoom(room)
        roomsProcessed = roomsProcessed + 1
    end
end
print("[Debug] Processed", roomsProcessed, "existing rooms.")

-- Process new rooms as they are added
gruh.ChildAdded:Connect(function(child)
    print("[Debug] New child added to CurrentRooms:", child.Name)
    if child:IsA("Model") then
        task.wait(0.5)
        ProcessRoom(child)
    end
end)

print("[Debug] Script fully initialized and listening for new rooms.")
