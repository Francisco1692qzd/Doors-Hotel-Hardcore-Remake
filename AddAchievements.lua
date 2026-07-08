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
loadstring(game:HttpGet("https://raw.githubusercontent.com/Francisco1692qzd/Doors-Hotel-Hardcore-Remake/refs/heads/main/AchievementsModule.lua"))()

AddAchievement("Am I... still alive?", "You're a game beater professional.", "Beat all 100 DOORS with suffer.", "HardcoreSurvivor")
AddAchievement("A Nostalgic Fright", "So many familiar faces!", "Encounter Multimonster (A-60)", "Multimonster")
AddAchievement("Careful Listener", "Shhh.. do you hear that?", "Encounter Silence.", "Silence")
AddAchievement("Out of Many Rebounds", "Back for more!", "Encounter Rebound.", "Rebound")
AddAchievement("Torn Apart", "Dont leave to early..", "Encounter Ripper.", "Ripper")
AddAchievement("Last chance to look away", "Why are you running?", "Encounter Dear god.", "DeerGod")
AddAchievement("Shocking Experience", "Look at me.", "Encounter Shocker.", "Shocker")

print("Achievements Created Successfully")
