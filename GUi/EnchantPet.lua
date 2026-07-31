-- Script MagicPet - Versi Ringkas
local lp = game.Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- Cari MagicPet
local magicPet = pg:FindFirstChild("MagicPet") or 
                  (pg:FindFirstChild("ScreenGui") and pg.ScreenGui:FindFirstChild("MagicPet"))

if magicPet then
    print("[MagicPet] Ditemukan!")
    magicPet.Visible = true
    
    -- Cari UI_Control
    local uiControl = magicPet:FindFirstChild("UI_Control")
    
    if uiControl then
        local success, err = pcall(function()
            local ctrl = require(uiControl)
            if ctrl then
                if ctrl.openUi then
                    ctrl.openUi()
                    print("[MagicPet] ✅ openUi() berhasil")
                elseif ctrl.updateUi then
                    ctrl.updateUi()
                    print("[MagicPet] ✅ updateUi() berhasil")
                else
                    -- Manual show
                    for _, child in ipairs(magicPet:GetDescendants()) do
                        if child:IsA("GuiObject") then
                            child.Visible = true
                        end
                    end
                    print("[MagicPet] ✅ GUI dibuka manual")
                end
            end
        end)
        if not success then
            print("[MagicPet] Error:", err)
            -- Fallback manual
            for _, child in ipairs(magicPet:GetDescendants()) do
                if child:IsA("GuiObject") then
                    child.Visible = true
                end
            end
            print("[MagicPet] ✅ GUI dibuka manual (fallback)")
        end
    else
        -- Manual show semua
        for _, child in ipairs(magicPet:GetDescendants()) do
            if child:IsA("GuiObject") then
                child.Visible = true
            end
        end
        print("[MagicPet] ✅ GUI dibuka secara manual")
    end
    
    -- Aktifkan komponen utama
    local frame = magicPet:FindFirstChild("Frame")
    if frame then
        frame.Visible = true
        local main = frame:FindFirstChild("Main")
        if main then main.Visible = true end
    end
    
    local bg = magicPet:FindFirstChild("BG")
    if bg then
        bg.Visible = true
        local exitBtn = bg:FindFirstChild("Exit")
        if exitBtn then exitBtn.Visible = true end
    end
    
    print("[MagicPet] 🎉 MagicPet GUI berhasil dibuka!")
else
    warn("[MagicPet] ❌ Tidak ditemukan!")
end
