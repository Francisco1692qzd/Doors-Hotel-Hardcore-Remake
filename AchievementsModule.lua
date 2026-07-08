local module = {}

function module.AddAchievement(title, desc, reason, image, achname)
    if game.PlaceId == "10549820578" then
        local Achievements = require(game:GetService("ReplicatedStorage"):WaitForChild("Achievements"))
        -- Create a custom achievement (use the same structure)
        local myAchievement = {
            Title = title,
            Desc = desc,
            Reason = reason,
            Image = image -- optional
        }
        -- Add it to the table (only affects your client)
        Achievements[achname] = { GetInfo = function() return myAchievement end }
    else
        local AchievementModule = game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
        if AchievementModule == nil then return end
        if not game.ReplicatedStorage:FindFirstChild("ModulesShared") then return end
        local dataModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ModulesShared"):WaitForChild("Achievements"))
        local unlockFunc = require(AchievementModule)
        dataModule[achname] = {
            GetInfo = function()
                return {
                    Title = title,
                    Desc = desc,
                    Reason = reason,
                    Image = image -- Custom Icon ID
                    --[[Prize = {
                        Knobs = 50,
                        Stardust = 1
                    }--]]
                }
            end
        }
    end
end

function module.GiveAchievement(name)
    if game.PlaceId == "10549820578" then
        local unlockUI = require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock)
        unlockUI(game.Players.LocalPlayer, name)
    else
        local AchievementModule = game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules.AchievementUnlock
        if AchievementModule == nil then return end
        if not game.ReplicatedStorage:FindFirstChild("ModulesShared") then return end
        local dataModule = require(game:GetService("ReplicatedStorage"):WaitForChild("ModulesShared"):WaitForChild("Achievements"))
        local unlockFunc = require(AchievementModule)
        unlockFunc(nil, name)
    end
end

return module
