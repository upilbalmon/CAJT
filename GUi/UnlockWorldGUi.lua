-- Script Teleport - Versi Ringkas
local lp = game.Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- Cari Teleport
local teleport = pg:FindFirstChild("Teleport") or 
                  (pg:FindFirstChild("ScreenGui") and pg.ScreenGui:FindFirstChild("Teleport"))

if teleport then
    print("[Teleport] Ditemukan!")
    teleport.Visible = true
    
    -- Cari UI_Control
    local uiControl = teleport:FindFirstChild("UI_Control")
    
    if uiControl then
        local success, err = pcall(function()
            local ctrl = require(uiControl)
            if ctrl then
                if ctrl.openUi then
                    ctrl.openUi()
                    print("[Teleport] ✅ openUi() berhasil")
                elseif ctrl.updateUi then
                    ctrl.updateUi()
                    print("[Teleport] ✅ updateUi() berhasil")
                else
                    -- Manual show
                    for _, child in ipairs(teleport:GetDescendants()) do
                        if child:IsA("GuiObject") then
                            child.Visible = true
                        end
                    end
                    print("[Teleport] ✅ GUI dibuka manual")
                end
            end
        end)
        if not success then
            print("[Teleport] Error:", err)
            -- Fallback manual
            for _, child in ipairs(teleport:GetDescendants()) do
                if child:IsA("GuiObject") then
                    child.Visible = true
                end
            end
            print("[Teleport] ✅ GUI dibuka manual (fallback)")
        end
    else
        -- Manual show semua
        for _, child in ipairs(teleport:GetDescendants()) do
            if child:IsA("GuiObject") then
                child.Visible = true
            end
        end
        print("[Teleport] ✅ GUI dibuka secara manual")
    end
    
    -- Aktifkan komponen utama
    local frame = teleport:FindFirstChild("Frame")
    if frame then
        frame.Visible = true
        local scrollFrame = frame:FindFirstChild("ScrollingFrame")
        if scrollFrame then
            scrollFrame.Visible = true
        end
    end
    
    local bg = teleport:FindFirstChild("BG")
    if bg then
        bg.Visible = true
        local exitBtn = bg:FindFirstChild("Exit")
        if exitBtn then exitBtn.Visible = true end
    end
    
    print("[Teleport] 🎉 Teleport GUI berhasil dibuka!")
else
    warn("[Teleport] ❌ Tidak ditemukan!")
end
