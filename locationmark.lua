--[[ 
GUI Bookmark Lokasi + Import + Waypoint (Roblox Lua)
Dengan penyimpanan di folder Delta: localstorage:delta/locationmark
- Membuat folder secara otomatis jika belum ada
- Menggunakan multiple metode penyimpanan sebagai fallback
- Auto-load dan auto-save
]]

-- ==== Helper: Dapatkan Player & Services ====
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==== Konfigurasi Penyimpanan Delta ====
local STORAGE_FOLDER = "localstorage:delta/locationmark/"
local STORAGE_PATH = STORAGE_FOLDER .. "bookmarks.json"

-- Fungsi untuk membuat folder jika belum ada
local function ensureFolder()
    if not makefolder then
        warn("Fungsi makefolder tidak tersedia")
        return false
    end
    
    local success, err = pcall(function()
        makefolder(STORAGE_FOLDER)
    end)
    
    if success then
        print("Folder berhasil dibuat/divalidasi: " .. STORAGE_FOLDER)
        return true
    else
        warn("Gagal membuat folder: " .. tostring(err))
        return false
    end
end

-- Fungsi untuk menyimpan data dengan multiple metode
local function saveData()
    if not next(bookmarks) then
        print("Tidak ada data untuk disimpan")
        return false
    end
    
    local dataToSave = {}
    for name, pos in pairs(bookmarks) do
        dataToSave[name] = {X = pos.X, Y = pos.Y, Z = pos.Z}
    end
    
    local json
    local success, err = pcall(function()
        json = game:GetService("HttpService"):JSONEncode(dataToSave)
    end)
    
    if not success then
        warn("Gagal encode JSON: " .. tostring(err))
        return false
    end
    
    -- Metode 1: Simpan ke file Delta
    if writefile then
        success, err = pcall(function()
            -- Pastikan folder ada sebelum menulis
            ensureFolder()
            writefile(STORAGE_PATH, json)
        end)
        
        if success then
            print("Data berhasil disimpan ke: " .. STORAGE_PATH)
            return true
        else
            warn("Gagal menyimpan ke file: " .. tostring(err))
        end
    end
    
    -- Metode 2: Simpan ke atribut player (fallback)
    success, err = pcall(function()
        player:SetAttribute("BookmarkData", json)
    end)
    
    if success then
        print("Data berhasil disimpan ke atribut player (fallback)")
        return true
    else
        warn("Gagal menyimpan ke atribut: " .. tostring(err))
    end
    
    -- Metode 3: Simpan ke clipboard (last resort)
    if setclipboard then
        success, err = pcall(function()
            setclipboard("-- BOOKMARK DATA --\n" .. json)
        end)
        if success then
            print("Data disimpan ke clipboard (last resort)")
            return true
        end
    end
    
    return false
end

-- Fungsi untuk memuat data dari multiple sumber
local function loadData()
    local dataLoaded = false
    
    -- Metode 1: Load dari file Delta
    if readfile and isfile then
        local fileExists
        local success, err = pcall(function()
            fileExists = isfile(STORAGE_PATH)
        end)
        
        if success and fileExists then
            local content
            success, content = pcall(function()
                return readfile(STORAGE_PATH)
            end)
            
            if success and content and content ~= "" then
                local decoded
                success, decoded = pcall(function()
                    return game:GetService("HttpService"):JSONDecode(content)
                end)
                
                if success and type(decoded) == "table" then
                    local count = 0
                    for name, posData in pairs(decoded) do
                        if type(posData) == "table" and posData.X and posData.Y and posData.Z then
                            bookmarks[name] = Vector3.new(posData.X, posData.Y, posData.Z)
                            count = count + 1
                        end
                    end
                    if count > 0 then
                        print(string.format("Berhasil memuat %d bookmark dari file Delta", count))
                        dataLoaded = true
                    end
                end
            end
        else
            print("File bookmark belum ada di: " .. STORAGE_PATH)
        end
    end
    
    -- Metode 2: Load dari atribut player (fallback)
    if not dataLoaded then
        local attrData = player:GetAttribute("BookmarkData")
        if attrData and attrData ~= "" then
            local decoded
            local success, err = pcall(function()
                decoded = game:GetService("HttpService"):JSONDecode(attrData)
            end)
            
            if success and type(decoded) == "table" then
                local count = 0
                for name, posData in pairs(decoded) do
                    if type(posData) == "table" and posData.X and posData.Y and posData.Z then
                        bookmarks[name] = Vector3.new(posData.X, posData.Y, posData.Z)
                        count = count + 1
                    end
                end
                if count > 0 then
                    print(string.format("Berhasil memuat %d bookmark dari atribut player", count))
                    dataLoaded = true
                end
            end
        end
    end
    
    -- Metode 3: Cek clipboard (jika ada data darurat)
    if not dataLoaded and getclipboard then
        local clipboardContent = getclipboard()
        if clipboardContent and clipboardContent:match("-- BOOKMARK DATA --") then
            local json = clipboardContent:gsub("-- BOOKMARK DATA --\n", "")
            local decoded
            local success, err = pcall(function()
                decoded = game:GetService("HttpService"):JSONDecode(json)
            end)
            
            if success and type(decoded) == "table" then
                local count = 0
                for name, posData in pairs(decoded) do
                    if type(posData) == "table" and posData.X and posData.Y and posData.Z then
                        bookmarks[name] = Vector3.new(posData.X, posData.Y, posData.Z)
                        count = count + 1
                    end
                end
                if count > 0 then
                    print(string.format("Berhasil memuat %d bookmark dari clipboard", count))
                    dataLoaded = true
                end
            end
        end
    end
    
    if not dataLoaded then
        print("Tidak ada data yang ditemukan. Memulai dengan bookmark kosong.")
    end
    
    return dataLoaded
end

-- ==== Data ====
local bookmarks = {}  -- { [name] = Vector3, ... }

-- Load data saat script dimulai
loadData()

-- ==== UI Creation (sama seperti sebelumnya, potong untuk menghemat ruang) ====
-- [KODE UI SAMA PERSIS SEPERTI SEBELUMNYA]
-- (Saya akan singkatkan di sini karena sudah sama)

-- ... (semua kode UI yang sama seperti sebelumnya) ...

-- ==== Fungsi untuk status dan error handling ====
local function showStatus(message, isError)
    if saverStatusLabel then
        saverStatusLabel.Text = message or ""
        if isError then
            saverStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            saverStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end
    print(message)
end

-- ==== MODIFIKASI: Tombol Save dengan error handling lebih baik ====
saveButton.MouseButton1Click:Connect(function()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then 
        showStatus("❌ Character belum siap!", true)
        return 
    end

    local pos = player.Character.HumanoidRootPart.Position
    local name = saverTextBox.Text

    if name == "" then
        name = generateAutoName()
        showStatus("✅ Lokasi '" .. name .. "' tersimpan otomatis")
    else
        showStatus("✅ Lokasi '" .. name .. "' tersimpan")
    end

    bookmarks[name] = pos
    savedLocations[name] = pos
    makeListItem(name, pos)
    updateCanvasSize()
    
    -- Coba simpan dengan multiple metode
    local saved = saveData()
    if saved then
        showStatus("✅ Data berhasil disimpan ke folder Delta")
    else
        showStatus("⚠️ Data tersimpan di memori, tapi gagal simpan ke file", true)
    end

    saverTextBox.Text = ""
    switchTab("bookmark")
end)

-- ==== MODIFIKASI: Tombol Delete dengan error handling ====
delBtn.MouseButton1Click:Connect(function()
    bookmarks[name] = nil
    item:Destroy()
    updateCanvasSize()
    local saved = saveData()
    if saved then
        showStatus("🗑️ Hapus bookmark: " .. name .. " (tersimpan)")
    else
        showStatus("⚠️ Bookmark dihapus tapi gagal simpan ke file", true)
    end
end)

-- ==== MODIFIKASI: Fungsi Import dengan error handling ====
importBtn.MouseButton1Click:Connect(function()
    local ok, msg = parseAndImport(importBox.Text)
    if ok then
        local saved = saveData()
        if saved then
            setStatus(msg .. " (tersimpan ke file)", false)
        else
            setStatus(msg .. " (tapi gagal simpan ke file)", true)
        end
    else
        setStatus(msg, true)
    end
end)

-- ==== Tombol untuk test penyimpanan ====
local testSaveBtn = Instance.new("TextButton")
testSaveBtn.Name = "TestSaveBtn"
testSaveBtn.Size = UDim2.fromOffset(80, 25)
testSaveBtn.Position = UDim2.new(0.5, -40, 1, -35)
testSaveBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
testSaveBtn.Text = "Test Save"
testSaveBtn.TextColor3 = Color3.new(0, 0, 0)
testSaveBtn.Font = Enum.Font.GothamBold
testSaveBtn.TextSize = 10
testSaveBtn.AutoButtonColor = true
testSaveBtn.Parent = saverTab
applyCorner(testSaveBtn, 5)

testSaveBtn.MouseButton1Click:Connect(function()
    showStatus("🔍 Mencoba menyimpan data test...")
    local testData = {
        ["Test Location"] = {X = 0, Y = 0, Z = 0},
        ["Test Location 2"] = {X = 100, Y = 50, Z = 200}
    }
    
    local json = game:GetService("HttpService"):JSONEncode(testData)
    
    -- Test writefile
    if writefile then
        ensureFolder()
        local success, err = pcall(function()
            writefile(STORAGE_PATH, json)
        end)
        if success then
            showStatus("✅ Test berhasil! File tersimpan di: " .. STORAGE_PATH)
            -- Coba baca kembali
            if readfile and isfile then
                local exists = isfile(STORAGE_PATH)
                if exists then
                    local content = readfile(STORAGE_PATH)
                    showStatus("✅ File terbaca! Size: " .. #content .. " bytes")
                end
            end
        else
            showStatus("❌ Test gagal: " .. tostring(err), true)
        end
    else
        showStatus("❌ writefile tidak tersedia (bukan eksekutor Delta?)", true)
    end
end)

-- ===== Informasi di GUI =====
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(1, -10, 0, 15)
infoLabel.Position = UDim2.new(0, 5, 1, -10)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "📁 " .. STORAGE_PATH
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 7
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = mainFrame

-- ==== Render awal ====
renderList()
print("Bookmark GUI dengan penyimpanan Delta telah dimuat!")
print("Lokasi penyimpanan: " .. STORAGE_PATH)
print("Gunakan tombol 'Test Save' untuk mengecek penyimpanan")
