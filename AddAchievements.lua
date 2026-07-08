-- No early returns – let the functions handle missing modules gracefully

local FALLBACK_IMAGE = "rbxassetid://1234567890" -- Replace with a valid placeholder

local function ImageLoader(url)
    if not (writefile and getcustomasset and request) then
        return FALLBACK_IMAGE
    end

    local rawUrl = url:gsub("github.com", "raw.githubusercontent.com"):gsub("/blob/", "/")

    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        local short = url:match("[^/]+$") or ""
        short = short:gsub("%.?[^%w]", ""):sub(1, 10)
        return "LoadedImage_" .. short .. "_" .. tostring(hash) .. ".png"
    end

    local fileName = generateFileName(rawUrl)

    local fileExists = false
    local success, exists = pcall(function()
        return isfile and isfile(fileName)
    end)
    if success and exists then
        local asset = getcustomasset(fileName)
        if asset and asset ~= "" then
            return asset
        end
    end

    local response, err = pcall(function()
        return request({ Url = rawUrl, Method = "GET" })
    end)

    if not response or not response.StatusCode or response.StatusCode ~= 200 then
        return FALLBACK_IMAGE
    end

    local writeSuccess = pcall(function()
        writefile(fileName, response.Body)
    end)

    if not writeSuccess then
        return FALLBACK_IMAGE
    end

    local asset = getcustomasset(fileName)
    if asset and asset ~= "" then
        return asset
    else
        return FALLBACK_IMAGE
    end
end

-- Helper to get the achievement data module (supports both versions)
local function getDataModule()
    local function tryRequire(path)
        local success, mod = pcall(require, path)
        if success then return mod end
        return nil
    end

    if tostring(game.PlaceId) == "10549820578" then
        -- Old version
        return tryRequire(game:GetService("ReplicatedStorage"):WaitForChild("Achievements"))
    else
        -- New version
        local shared = game.ReplicatedStorage:FindFirstChild("ModulesShared")
        if not shared then return nil end
        local achMod = shared:FindFirstChild("Achievements")
        if not achMod then return nil end
        return tryRequire(achMod)
    end
end

-- Helper to get the UI unlock function (same path for both versions)
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
    if not dataModule then
        warn("Data module not found – cannot add achievement")
        return
    end

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

-- Load images from GitHub
local HardcoreSurvivorAchievement = "https://github.com/Francisco1692qzd/AchievementsImages/blob/main/Door100Achievement.png"
local SilenceAchievement = "https://github.com/Francisco1692qzd/AchievementsImages/blob/main/silenceachievement.png"
local MultimonsterAchievement = "https://github.com/Francisco1692qzd/AchievementsImages/blob/main/a60achievement.png"
local ReboundAchievement = "https://github.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/blob/main/achievementrebound.png"
local ShockerAchievement = "https://github.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/blob/main/AchievementShocker.png"
local DeerGod = "https://github.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/blob/main/DeerGod.png"

local Door100Image = ImageLoader(HardcoreSurvivorAchievement)
local silenceImage = ImageLoader(SilenceAchievement)
local MultimonsterImage = ImageLoader(MultimonsterAchievement)
local ReboundImage = ImageLoader(ReboundAchievement)
local ShockerImage = ImageLoader(ShockerAchievement)
local DeerGodImage = ImageLoader(DeerGod)

-- Add all custom achievements
AddAchievement("Am I... still alive?", "You're a game beater professional.", "Beat all 100 DOORS with suffer.", Door100Image, "HardcoreSurvivor")
AddAchievement("A Nostalgic Fright", "So many familiar faces!", "Encounter Multimonster (A-60)", MultimonsterImage, "Multimonster")
AddAchievement("Careful Listener", "Shhh.. do you hear that?", "Encounter Silence.", silenceImage, "Silence")
AddAchievement("Out of Many Rebounds", "Back for more!", "Encounter Rebound.", ReboundImage, "Rebound")
AddAchievement("Torn Apart", "Dont leave to early..", "Encounter Ripper.", "rbxassetid://12231244908", "Ripper")
AddAchievement("Last chance to look away", "Why are you running?", "Encounter Dear god.", DeerGodImage, "DeerGod")
AddAchievement("Shocking Experience", "Look at me.", "Encounter Shocker.", ShockerImage, "Shocker")
AddAchievement("You don't know how this means the world to me.", "Thank you SO badly much for playing!", "Made by Francisco.", "rbxassetid://249529865", "Thankyou")

-- Trigger the "Thankyou" popup
GiveAchievement("Thankyou")

print("Achievements Created Successfully")
