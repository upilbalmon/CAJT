-- Script Season - Dengan Info Lengkap
local function openSeasonWithInfo()
    local lp = game.Players.LocalPlayer
    local pg = lp:WaitForChild("PlayerGui")
    local rs = game:GetService("ReplicatedStorage")
    
    -- Cari Season
    local season = pg:FindFirstChild("Season") or 
                    (pg:FindFirstChild("ScreenGui") and pg.ScreenGui:FindFirstChild("Season"))
    
    if not season then
        local source = game:GetService("StarterGui"):FindFirstChild("ScreenGui")
        if source then
            local s = source:FindFirstChild("Season")
            if s then
                season = s:Clone()
                season.Parent = pg
                season.Enabled = true
                task.wait(0.1)
            end
        end
    end
    
    if season then
        print("[Season] ========================================")
        print("[Season] 🍀 ST. PATRICK'S SEASON")
        print("[Season] ========================================")
        
        -- Dapatkan info season
        local configModule = require(rs.GlobalConfig.ConfigModule)
        local seasonConfig = configModule.Season
        if seasonConfig then
            print("[Season] Season Config:")
            print("  - Hatch x1: " .. tostring(seasonConfig["Hatchx1"]))
            print("  - Hatch x3: " .. tostring(seasonConfig["Hatchx3"]))
            print("  - Hatch x10: " .. tostring(seasonConfig["Hatchx10"]))
        end
        
        -- Dapatkan level dan exp
        local bag = lp:FindFirstChild("Bag")
        if bag then
            local seasonLevel = bag:FindFirstChild("SeasonLevel")
            local seasonExp = bag:FindFirstChild("SeasonExp")
            if seasonLevel then
                print("[Season] Level: " .. tostring(seasonLevel.Value))
            end
            if seasonExp then
                print("[Season] Exp: " .. tostring(seasonExp.Value))
            end
        end
        
        -- Buka GUI
        season.Visible = true
        
        -- Panggil UI_Control
        local uiControl = season:FindFirstChild("UI_Control")
        if uiControl then
            pcall(function()
                local ctrl = require(uiControl)
                if ctrl then
                    if ctrl.openUi then
                        ctrl.openUi()
                    end
                    if ctrl.UpdateReward then
                        ctrl.UpdateReward()
                    end
                    if ctrl.updateBigShow then
                        ctrl.updateBigShow()
                    end
                    if ctrl.updateTask then
                        ctrl.updateTask()
                    end
                end
            end)
        end
        
        -- Set tab
        local curPanel = season:FindFirstChild("CurPanel")
        if curPanel then
            curPanel.Value = "Rewards"
        end
        
        local frame = season:FindFirstChild("Frame")
        if frame then
            local rewards = frame:FindFirstChild("Rewards")
            if rewards then rewards.Visible = true end
            local premium = frame:FindFirstChild("PremiumPass")
            if premium then premium.Visible = false end
            local task = frame:FindFirstChild("Task")
            if task then task.Visible = false end
            local luckHatch = frame:FindFirstChild("LuckHatch")
            if luckHatch then luckHatch.Visible = false end
        end
        
        print("[Season] ✅ Season GUI berhasil dibuka!")
        print("[Season] ========================================")
    else
        warn("[Season] ❌ Tidak ditemukan!")
    end
end

openSeasonWithInfo()
