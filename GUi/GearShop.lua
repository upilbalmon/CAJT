-- Versi sederhana
local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local gearShop = pg.ScreenGui:WaitForChild("GearShop")

gearShop.Visible = true
gearShop.Enabled = true

local uiControl = gearShop:FindFirstChild("UI_Control")
if uiControl then
    local controller = require(uiControl)
    if controller.updateUi then
        controller.updateUi()
    end
end

print("✅ GearShop dibuka!")