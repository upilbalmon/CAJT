-- Script untuk membuka paksa GUI WingShop
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- Cari semua kemungkinan lokasi WingShop
local function findWingShop()
    -- Coba cari di ScreenGui
    local screenGui = pg:FindFirstChild("ScreenGui")
    if screenGui then
        local wingShop = screenGui:FindFirstChild("WingShop")
        if wingShop then return wingShop end
    end
    
    -- Coba cari langsung di PlayerGui
    local wingShop = pg:FindFirstChild("WingShop")
    if wingShop then return wingShop end
    
    -- Cari dengan nama alternatif
    local alternatif = {"Wing", "Wings", "WingShopUI", "ShopWing"}
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
            if child.Name == "WingShop" or child.Name == "Wing" or child.Name == "Wings" then
                return child
            end
            local found = searchRecursive(child)
            if found then return found end
        end
        return nil
    end
    
    return searchRecursive(pg)
end

local wingShop = findWingShop()

if wingShop then
    print("[WingShop] Ditemukan! Membuka GUI...")
    
    -- Buka GUI
    wingShop.Visible = true
    
    -- Cari UI_Control (controller)
    local uiControl = nil
    for _, child in ipairs(wingShop:GetDescendants()) do
        if child.Name == "UI_Control" and child:IsA("ModuleScript") then
            uiControl = child
            break
        end
    end
    
    -- Jika ada UI_Control, panggil fungsi openUi
    if uiControl then
        local success, result = pcall(function()
            local controller = require(uiControl)
            if controller then
                print("[WingShop] Fungsi yang tersedia:")
                for key, _ in pairs(controller) do
                    print("  - " .. key)
                end
                
                if controller.openUi then
                    controller.openUi()
                    print("[WingShop] openUi() berhasil dipanggil!")
                elseif controller.updateUi then
                    controller.updateUi()
                    print("[WingShop] updateUi() berhasil dipanggil!")
                else
                    print("[WingShop] Tidak ada fungsi openUi/updateUi")
                    -- Manual show
                    local function showAll(obj)
                        if obj:IsA("GuiObject") then
                            obj.Visible = true
                        end
                        for _, child in ipairs(obj:GetChildren()) do
                            showAll(child)
                        end
                    end
                    showAll(wingShop)
                    print("[WingShop] GUI dibuka manual")
                end
            end
        end)
        
        if not success then
            print("[WingShop] Gagal memanggil UI_Control:", result)
            -- Fallback manual
            local function showAll(obj)
                if obj:IsA("GuiObject") then
                    obj.Visible = true
                end
                for _, child in ipairs(obj:GetChildren()) do
                    showAll(child)
                end
            end
            showAll(wingShop)
            print("[WingShop] GUI dibuka manual (fallback)")
        end
    else
        print("[WingShop] UI_Control tidak ditemukan, menampilkan manual...")
        -- Tampilkan semua elemen manual
        local function showAll(obj)
            if obj:IsA("GuiObject") then
                obj.Visible = true
            end
            for _, child in ipairs(obj:GetChildren()) do
                showAll(child)
            end
        end
        showAll(wingShop)
        print("[WingShop] GUI dibuka manual")
    end
    
    -- Update UI jika ada fungsi di modules lain
    task.wait(0.5)
    
    -- Coba temukan dan panggil updateUi dari module lain
    local modules = {
        wingShop:FindFirstChild("UI_Control"),
        wingShop:FindFirstChild("WingControl"),
        wingShop:FindFirstChild("ShopControl"),
        wingShop:FindFirstChild("MainControl"),
        wingShop:FindFirstChild("Controller"),
    }
    
    for _, module in ipairs(modules) do
        if module and module:IsA("ModuleScript") then
            pcall(function()
                local controller = require(module)
                if controller and controller.updateUi then
                    controller.updateUi()
                    print("[WingShop] updateUi() dipanggil dari", module.Name)
                end
            end)
        end
    end
    
    -- Tampilkan tab pertama (All Wings)
    local tabAll = wingShop:FindFirstChild("AllTab")
    if tabAll then
        tabAll.Visible = true
        print("[WingShop] Tab All Wings diaktifkan")
    end
    
    -- Pastikan nowFood (selected wing) di-update
    local nowFood = wingShop:FindFirstChild("nowFood")
    if nowFood then
        print("[WingShop] nowFood ditemukan, value:", nowFood.Value)
    end
    
    print("[WingShop] ✅ GUI WingShop berhasil dibuka!")
else
    warn("[WingShop] ❌ Tidak menemukan GUI WingShop!")
    
    -- Tampilkan semua GUI yang ada untuk debugging
    print("[WingShop] Daftar GUI di PlayerGui:")
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
