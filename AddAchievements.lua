local AchievementModule = game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
if AchievementModule == nil then return end
if not game.ReplicatedStorage:FindFirstChild("ModulesShared") then return end
local dataModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ModulesShared"):WaitForChild("Achievements"))
local unlockFunc = require(AchievementModule)

-- Fallback image to use if loading fails (change to a valid placeholder if needed)
local FALLBACK_IMAGE = "rbxassetid://1234567890" -- Replace with your own placeholder ID

local function ImageLoader(url)
    if not (writefile and getcustomasset and request) then
        return FALLBACK_IMAGE
    end

    local rawUrl = url:gsub("github.com", "raw.githubusercontent.com"):gsub("/blob/", "/")

    -- Generate a unique filename using a better hash (avoids collisions)
    local function generateFileName(url)
        local hash = 0
        for i = 1, #url do
            hash = (hash * 31 + string.byte(url, i)) % 2^32
        end
        -- Add a portion of the URL to make it even more unique (just in case)
        local short = url:match("[^/]+$") or ""
        short = short:gsub("%.?[^%w]", ""):sub(1, 10)
        return "LoadedImage_" .. short .. "_" .. tostring(hash) .. ".png"
    end

    local fileName = generateFileName(rawUrl)

    -- Check if file exists and return the asset
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

    -- Download image
    local response, err = pcall(function()
        return request({ Url = rawUrl, Method = "GET" })
    end)

    if not response or not response.StatusCode or response.StatusCode ~= 200 then
        return FALLBACK_IMAGE
    end

    -- Write file and verify it was written
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

-- Now you can call them directly:
--[[AddAchievement("My Meme", "I am a legend", "Because I can", "rbxassetid://123456789", "MemeMaster")
GiveAchievement("MemeMaster")--]]

-- URLs remain unchanged
local HardcoreSurvivorAchievement = "https://github.com/Francisco1692qzd/AchievementsImages/blob/main/Door100Achievement.png"
local SilenceAchievement = "https://github.com/Francisco1692qzd/AchievementsImages/blob/main/silenceachievement.png"
local MultimonsterAchievement = "https://github.com/Francisco1692qzd/AchievementsImages/blob/main/a60achievement.png"
local ReboundAchievement = "https://github.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/blob/main/achievementrebound.png"
local ShockerAchievement = "https://github.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/blob/main/AchievementShocker.png"
local DeerGod = "https://github.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/blob/main/DeerGod.png"

-- Load images (they will return fallback if needed)
local Door100Image = ImageLoader(HardcoreSurvivorAchievement)
local silenceImage = ImageLoader(SilenceAchievement)
local MultimonsterImage = ImageLoader(MultimonsterAchievement)
local ReboundImage = ImageLoader(ReboundAchievement)
local ShockerImage = ImageLoader(ShockerAchievement)
local DeerGodImage = ImageLoader(DeerGod)

-- Achievement definitions (unchanged except they now always have an image)
--[[dataModule["HardcoreSurvivor"] = {
	GetInfo = function()
		return {
			Title = "HARDCORE SURVIVOR",
			Desc = "You survived the 100 rooms of Hardcore!",
			Reason = "Survive until Room 100. Congrats!",
			Image = Door100Image,
            Prize = {
                Knobs = 50,
                Stardust = 1
            }
		}
	end
}

dataModule["Shocker"] = {
	GetInfo = function()
		return {
			Title = "Shocking Experience",
			Desc = "Look at me.",
			Reason = "Encounter Shocker.",
			Image = ShockerImage
		}
	end
}

dataModule["Rebound"] = {
	GetInfo = function()
		return {
			Title = "Out of Many Rebounds",
			Desc = "Back for more!",
			Reason = "Encounter Rebound.",
			Image = ReboundImage
		}
	end
}

dataModule["Ripper"] = {
	GetInfo = function()
		return {
			Title = "Torn Apart",
			Desc = "Don't Leave Too Early.",
			Reason = "Encounter Ripper.",
			Image = "rbxassetid://12231244908"
		}
	end
}

dataModule["DeerGod"] = {
	GetInfo = function()
		return {
			Title = "Running for my life",
			Desc = "Why are you running?",
			Reason = "Encounter Dear God.",
			Image = DeerGodImage
		}
	end
}

dataModule["Silence"] = {
	GetInfo = function()
		return {
			Title = "Careful Listener",
			Desc = "Shhh.. do you hear that?",
			Reason = "Successfully encounter Silence",
			Image = silenceImage
		}
	end
}

dataModule["Multimonster"] = {
	GetInfo = function()
		return {
			Title = "A Nostalgic Fright",
			Desc = "So many familiar faces!",
			Reason = "Encounter Multimonster (known as A-60).",
			Image = MultimonsterImage
		}
	end
}
--]]
--loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/AchievementsModule.lua"))()

AddAchievement("Am I... still alive?", "You're a game beater professional.", "Beat all 100 DOORS with suffer.", Door100Image, "HardcoreSurvivor")
AddAchievement("A Nostalgic Fright", "So many familiar faces!", "Encounter Multimonster (A-60)", MultimonsterImage, "Multimonster")
AddAchievement("Careful Listener", "Shhh.. do you hear that?", "Encounter Silence.", silenceImage, "Silence")
AddAchievement("Out of Many Rebounds", "Back for more!", "Encounter Rebound.", ReboundImage, "Rebound")
AddAchievement("Torn Apart", "Dont leave to early..", "Encounter Ripper.", "rbxassetid://12231244908", "Ripper")
AddAchievement("Last chance to look away", "Why are you running?", "Encounter Dear god.", DeerGodImage, "DeerGod")
AddAchievement("Shocking Experience", "Look at me.", "Encounter Shocker.", ShockerImage, "Shocker")
AddAchievement("You don't know how this means the world to me.", "Thank you SO badly much for playing!", "Made by Francisco.", "rbxassetid://249529865", "Thankyou")
GiveAchievement("Thankyou")

print("Achievements Created Successfully")
