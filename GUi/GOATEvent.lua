-- Script untuk membuka paksa GUI EventPass
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- Cari semua kemungkinan lokasi EventPass
local function findEventPass()
    -- Coba cari di ScreenGui
    local screenGui = pg:FindFirstChild("ScreenGui")
    if screenGui then
        local eventPass = screenGui:FindFirstChild("EventPass")
        if eventPass then return eventPass end
    end
    
    -- Coba cari langsung di PlayerGui
    local eventPass = pg:FindFirstChild("EventPass")
    if eventPass then return eventPass end
    
    -- Cari dengan nama alternatif
    local alternatif = {"Event", "EventPassUI", "GOATEvent", "GOAT"}
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
            if child.Name == "EventPass" or child.Name == "Event" or child.Name == "GOATEvent" then
                return child
            end
            local found = searchRecursive(child)
            if found then return found end
        end
        return nil
    end
    
    return searchRecursive(pg)
end

local eventPass = findEventPass()

if eventPass then
    print("[EventPass] Ditemukan! Membuka GUI...")
    
    -- Buka GUI
    eventPass.Visible = true
    
    -- Cari UI_Control (controller)
    local uiControl = nil
    for _, child in ipairs(eventPass:GetDescendants()) do
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
                print("[EventPass] Fungsi yang tersedia:")
                for key, _ in pairs(controller) do
                    print("  - " .. key)
                end
                
                if controller.openUi then
                    controller.openUi()
                    print("[EventPass] openUi() berhasil dipanggil!")
                elseif controller.updateUi then
                    controller.updateUi()
                    print("[EventPass] updateUi() berhasil dipanggil!")
                else
                    print("[EventPass] Tidak ada fungsi openUi/updateUi")
                    -- Manual show
                    local function showAll(obj)
                        if obj:IsA("GuiObject") then
                            obj.Visible = true
                        end
                        for _, child in ipairs(obj:GetChildren()) do
                            showAll(child)
                        end
                    end
                    showAll(eventPass)
                    print("[EventPass] GUI dibuka manual")
                end
            end
        end)
        
        if not success then
            print("[EventPass] Gagal memanggil UI_Control:", result)
            -- Fallback manual
            local function showAll(obj)
                if obj:IsA("GuiObject") then
                    obj.Visible = true
                end
                for _, child in ipairs(obj:GetChildren()) do
                    showAll(child)
                end
            end
            showAll(eventPass)
            print("[EventPass] GUI dibuka manual (fallback)")
        end
    else
        print("[EventPass] UI_Control tidak ditemukan, menampilkan manual...")
        -- Tampilkan semua elemen manual
        local function showAll(obj)
            if obj:IsA("GuiObject") then
                obj.Visible = true
            end
            for _, child in ipairs(obj:GetChildren()) do
                showAll(child)
            end
        end
        showAll(eventPass)
        print("[EventPass] GUI dibuka manual")
    end
    
    -- Update UI jika ada fungsi di modules lain
    task.wait(0.5)
    
    -- Coba temukan dan panggil updateUi dari module lain
    local modules = {
        eventPass:FindFirstChild("UI_Control"),
        eventPass:FindFirstChild("EventControl"),
        eventPass:FindFirstChild("MainControl"),
        eventPass:FindFirstChild("Controller"),
    }
    
    for _, module in ipairs(modules) do
        if module and module:IsA("ModuleScript") then
            pcall(function()
                local controller = require(module)
                if controller and controller.updateUi then
                    controller.updateUi()
                    print("[EventPass] updateUi() dipanggil dari", module.Name)
                end
            end)
        end
    end
    
    -- Set tab ke Rewards (default)
    local curPanel = eventPass:FindFirstChild("CurPanel")
    if curPanel then
        curPanel.Value = "Rewards"
        print("[EventPass] CurPanel set ke Rewards")
    end
    
    -- Aktifkan tab Rewards
    local frame = eventPass:FindFirstChild("Frame")
    if frame then
        local rewards = frame:FindFirstChild("Rewards")
        if rewards then
            rewards.Visible = true
            print("[EventPass] Tab Rewards diaktifkan")
        end
        local premiumPass = frame:FindFirstChild("PremiumPass")
        if premiumPass then
            premiumPass.Visible = false
        end
        local task = frame:FindFirstChild("Task")
        if task then
            task.Visible = false
        end
    end
    
    -- Update reward display
    if uiControl then
        pcall(function()
            local controller = require(uiControl)
            if controller and controller.UpdateReward then
                controller.UpdateReward()
                print("[EventPass] UpdateReward() dipanggil")
            end
            if controller and controller.updateBigShow then
                controller.updateBigShow()
                print("[EventPass] updateBigShow() dipanggil")
            end
        end)
    end
    
    print("[EventPass] ✅ GUI EventPass berhasil dibuka!")
else
    warn("[EventPass] ❌ Tidak menemukan GUI EventPass!")
    
    -- Tampilkan semua GUI yang ada untuk debugging
    print("[EventPass] Daftar GUI di PlayerGui:")
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
