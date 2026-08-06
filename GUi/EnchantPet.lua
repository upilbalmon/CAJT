-- Script perbaikan untuk MagicPet - Memastikan semua tombol berfungsi
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

-- Cari MagicPet di PlayerGui
local magicPet = nil
local pg = lp.PlayerGui

for _, gui in ipairs(pg:GetChildren()) do
    if gui:IsA("ScreenGui") then
        local found = gui:FindFirstChild("MagicPet")
        if found then
            magicPet = found
            print("[MagicPet] ✅ Ditemukan di:", gui.Name)
            break
        end
    end
end

if not magicPet then
    warn("[MagicPet] ❌ GUI tidak ditemukan!")
    return
end

-- 1. TAMPILKAN GUI
magicPet.Visible = true

-- 2. FUNGSI UNTUK MENAMPILKAN SEMUA ELEMEN
local function showAll(obj)
    if obj:IsA("GuiObject") then
        obj.Visible = true
        -- Aktifkan interaksi
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            obj.Active = true
            obj.Interactable = true
            obj.Selectable = true
        end
    end
    for _, child in ipairs(obj:GetChildren()) do
        showAll(child)
    end
end

-- 3. TAMPILKAN SEMUA ELEMEN TERLEBIH DAHULU
showAll(magicPet)
print("[MagicPet] ✅ Semua elemen ditampilkan")

-- 4. PANGGIL CONTROLLER
local uiControl = magicPet:FindFirstChild("UI_Control")
local controller = nil

if uiControl and uiControl:IsA("ModuleScript") then
    local success, result = pcall(require, uiControl)
    if success then
        controller = result
        print("[MagicPet] ✅ Controller berhasil dimuat!")
    else
        print("[MagicPet] ❌ Gagal memuat controller:", result)
    end
end

-- 5. PANGGIL SEMUA FUNGSI YANG DIPERLUKAN
if controller then
    -- Daftar fungsi yang harus dipanggil untuk inisialisasi
    local initFunctions = {
        "updateUi", "Init", "Initialize", "Setup", 
        "openUi", "Show", "Refresh", "Reload"
    }
    
    local called = {}
    for _, funcName in ipairs(initFunctions) do
        if controller[funcName] then
            local success, err = pcall(controller[funcName], controller)
            if success then
                print("[MagicPet] ✅ " .. funcName .. "() berhasil dipanggil")
                table.insert(called, funcName)
            else
                print("[MagicPet] ⚠️ " .. funcName .. "() gagal:", err)
            end
        end
    end
    
    -- Jika tidak ada fungsi yang dipanggil, coba panggil semua fungsi
    if #called == 0 then
        print("[MagicPet] ⚠️ Tidak ada fungsi inisialisasi yang ditemukan!")
        print("[MagicPet] Mencoba memanggil semua fungsi...")
        
        for key, value in pairs(controller) do
            if type(value) == "function" then
                local success, err = pcall(value, controller)
                if success then
                    print("[MagicPet] ✅ " .. key .. "() dipanggil")
                end
            end
        end
    end
end

-- 6. AKTIFKAN SEMUA TOMBOL SECARA MANUAL
local function activateAllButtons(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("ImageButton") then
            child.Visible = true
            child.Active = true
            child.Interactable = true
            child.Selectable = true
            child.AutoButtonColor = true
            
            -- Set background transparansi jika ada
            if child:IsA("ImageButton") then
                child.ImageTransparency = 0
            end
        end
        
        -- Rekursif ke child
        if child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("ScreenGui") then
            activateAllButtons(child)
        end
    end
end

activateAllButtons(magicPet)
print("[MagicPet] ✅ Semua tombol diaktifkan")

-- 7. TUNGGU SEBENTAR DAN REFRESH
task.wait(0.5)

-- 8. COBA PANGGIL UPDATE UI LAGI
if controller and controller.updateUi then
    pcall(controller.updateUi, controller)
    print("[MagicPet] ✅ updateUi() dipanggil ulang")
end

print("[MagicPet] 🎉 GUI siap digunakan! Tombol seharusnya berfungsi.")
