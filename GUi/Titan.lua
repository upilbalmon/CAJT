-- Script untuk membuka paksa GUI Titan Pet (Metode FusePet)
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- Cari semua kemungkinan lokasi Titan Pet
local function findTitanPet()
    -- Coba cari di ScreenGui
    local screenGui = pg:FindFirstChild("ScreenGui")
    if screenGui then
        local titanPet = screenGui:FindFirstChild("Titan Pet")
        if titanPet then return titanPet end
    end
    
    -- Coba cari langsung di PlayerGui
    local titanPet = pg:FindFirstChild("Titan Pet")
    if titanPet then return titanPet end
    
    -- Cari dengan nama alternatif
    local alternatif = {"TitanPet", "Titan_Pet", "Titan"}
    for _, name in ipairs(alternatif) do
        local found = pg:FindFirstChild(name)
        if found then return found end
        if screenGui then
            found = screenGui:FindFirstChild(name)
            if found then return found end
        end
    end
    
    -- Cari secara rekursif (mendalam)
    local function searchRecursive(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "Titan Pet" or child.Name == "TitanPet" or child.Name == "Titan_Pet" then
                return child
            end
            local found = searchRecursive(child)
            if found then return found end
        end
        return nil
    end
    
    return searchRecursive(pg)
end

local titanPet = findTitanPet()

if titanPet then
    print("[TitanPet] Ditemukan! Membuka GUI...")
    
    -- Buka GUI
    titanPet.Visible = true
    
    -- Cari UI_Control (controller)
    local uiControl = nil
    for _, child in ipairs(titanPet:GetDescendants()) do
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
                print("[TitanPet] openUi() berhasil dipanggil!")
            elseif controller and controller.updateUi then
                controller.updateUi()
                print("[TitanPet] updateUi() berhasil dipanggil!")
            else
                print("[TitanPet] UI_Control ditemukan tapi tidak ada fungsi openUi/updateUi")
                -- Tampilkan fungsi yang tersedia
                if controller then
                    print("[TitanPet] Fungsi yang tersedia:")
                    for key, _ in pairs(controller) do
                        print("  - " .. key)
                    end
                end
            end
        end)
        
        if not success then
            print("[TitanPet] Gagal memanggil UI_Control:", result)
        end
    else
        print("[TitanPet] UI_Control tidak ditemukan, menampilkan manual...")
        -- Tampilkan semua elemen manual
        local function showAll(obj)
            if obj:IsA("GuiObject") then
                obj.Visible = true
            end
            for _, child in ipairs(obj:GetChildren()) do
                showAll(child)
            end
        end
        showAll(titanPet)
    end
    
    -- Update UI jika ada fungsi di modules lain
    task.wait(0.5)
    
    -- Coba temukan dan panggil updateUi dari module lain
    local modules = {
        titanPet:FindFirstChild("UI_Control"),
        titanPet:FindFirstChild("TitanControl"),
        titanPet:FindFirstChild("MainControl"),
        titanPet:FindFirstChild("Controller"),
    }
    
    for _, module in ipairs(modules) do
        if module and module:IsA("ModuleScript") then
            pcall(function()
                local controller = require(module)
                if controller and controller.updateUi then
                    controller.updateUi()
                    print("[TitanPet] updateUi() dipanggil dari", module.Name)
                end
            end)
        end
    end
    
    print("[TitanPet] ✅ GUI Titan Pet berhasil dibuka!")
else
    warn("[TitanPet] ❌ Tidak menemukan GUI Titan Pet!")
    
    -- Tampilkan semua GUI yang ada untuk debugging
    print("[TitanPet] Daftar GUI di PlayerGui:")
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
