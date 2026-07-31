-- Script untuk membuka paksa GUI FusePet
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- Cari semua kemungkinan lokasi FusePet
local function findFusePet()
    -- Coba cari di ScreenGui
    local screenGui = pg:FindFirstChild("ScreenGui")
    if screenGui then
        local fusePet = screenGui:FindFirstChild("FusePet")
        if fusePet then return fusePet end
    end
    
    -- Coba cari langsung di PlayerGui
    local fusePet = pg:FindFirstChild("FusePet")
    if fusePet then return fusePet end
    
    -- Cari secara rekursif (mendalam)
    local function searchRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "FusePet" then
                return child
            end
            local found = searchRecursive(child)
            if found then return found end
        end
        return nil
    end
    
    return searchRecursive(pg)
end

local fusePet = findFusePet()

if fusePet then
    print("[FusePet] Ditemukan! Membuka GUI...")
    
    -- Buka GUI
    fusePet.Visible = true
    
    -- Cari UI_Control (controller)
    local uiControl = nil
    for _, child in ipairs(fusePet:GetDescendants()) do
        if child.Name == "UI_Control" and child:IsA("ModuleScript") then
            uiControl = child
            break
        end
    end
    
    -- Jika ada UI_Control, panggil fungsi openUi
    if uiControl then
        local success, result = pcall(function()
            local controller = require(uiControl)
            if controller and controller.openUi then
                controller.openUi()
                print("[FusePet] openUi() berhasil dipanggil!")
            elseif controller and controller.updateUi then
                controller.updateUi()
                print("[FusePet] updateUi() berhasil dipanggil!")
            else
                print("[FusePet] UI_Control ditemukan tapi tidak ada fungsi openUi/updateUi")
            end
        end)
        
        if not success then
            print("[FusePet] Gagal memanggil UI_Control:", result)
        end
    else
        print("[FusePet] UI_Control tidak ditemukan, menampilkan manual...")
        -- Tampilkan semua elemen manual
        local function showAll(obj)
            if obj:IsA("GuiObject") then
                obj.Visible = true
            end
            for _, child in ipairs(obj:GetChildren()) do
                showAll(child)
            end
        end
        showAll(fusePet)
    end
    
    -- Update UI jika ada fungsi di modules lain
    task.wait(0.5)
    
    -- Coba temukan dan panggil updateUi dari module lain
    local modules = {
        fusePet:FindFirstChild("UI_Control"),
        fusePet:FindFirstChild("FuseControl"),
        fusePet:FindFirstChild("MainControl"),
    }
    
    for _, module in ipairs(modules) do
        if module and module:IsA("ModuleScript") then
            pcall(function()
                local controller = require(module)
                if controller and controller.updateUi then
                    controller.updateUi()
                    print("[FusePet] updateUi() dipanggil dari", module.Name)
                end
            end)
        end
    end
    
    print("[FusePet] ✅ GUI FusePet berhasil dibuka!")
else
    warn("[FusePet] ❌ Tidak menemukan GUI FusePet!")
    
    -- Tampilkan semua GUI yang ada untuk debugging
    print("[FusePet] Daftar GUI di PlayerGui:")
    local function listGUI(parent, indent)
        indent = indent or ""
        for _, child in ipairs(parent:GetChildren()) do
            print(indent .. "- " .. child.Name .. " (" .. child.ClassName .. ")")
            if child:IsA("ScreenGui") or child:IsA("Frame") then
                listGUI(child, indent .. "  ")
            end
        end
    end
    listGUI(pg)
end
