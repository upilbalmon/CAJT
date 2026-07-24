--[[
    Hero ID Scanner & CSV Saver
    Menggabungkan fungsi AutoFarm.lua + locationmark.lua
    Fitur:
    1. Deteksi ID hero otomatis (hook __namecall)
    2. Scan ID hero dari file
    3. Simpan ke tabel dengan data manual (nilai, world, name)
    4. Export ke CSV (menggunakan writefile)
    5. Load CSV
]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

--// Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local heroId = 7000117
local drawCount = 10
local autoDetect = true
local hookEnabled = true
local isMinimized = false

-- Data tabel untuk hero
local heroData = {} -- { [id] = {value, world, name} }
local detectedIds = {} -- Untuk menyimpan ID yang terdeteksi

-- Konfigurasi penyimpanan
local STORAGE_FOLDER = "herodata/"
local CSV_PATH = STORAGE_FOLDER .. "hero_data.csv"
local JSON_PATH = STORAGE_FOLDER .. "hero_data.json"

--// ========== FUNGSI PENYIMPANAN ==========

local function ensureFolder()
    if not makefolder then
        warn("⚠️ Fungsi makefolder tidak tersedia")
        return false
    end
    
    local success, err = pcall(function()
        makefolder(STORAGE_FOLDER)
    end)
    
    if success then
        print("✅ Folder dibuat: " .. STORAGE_FOLDER)
        return true
    else
        warn("❌ Gagal membuat folder: " .. tostring(err))
        return false
    end
end

-- Simpan ke CSV (menggunakan writefile)
local function saveToCSV()
    if not next(heroData) then
        print("⚠️ Tidak ada data untuk disimpan")
        return false
    end
    
    if not writefile then
        warn("⚠️ writefile tidak didukung")
        return false
    end
    
    ensureFolder()
    
    local csvContent = "id,value,world,name\n"
    for id, data in pairs(heroData) do
        csvContent = csvContent .. string.format("%s,%s,%s,%s\n", 
            id, 
            data.value or "", 
            data.world or "", 
            data.name or ""
        )
    end
    
    local success, err = pcall(function()
        writefile(CSV_PATH, csvContent)
    end)
    
    if success then
        print("✅ Data disimpan ke: " .. CSV_PATH)
        return true
    else
        warn("❌ Gagal menyimpan CSV: " .. tostring(err))
        return false
    end
end

-- Load dari CSV
local function loadFromCSV()
    if not readfile or not isfile then
        return false
    end
    
    local fileExists
    local success, err = pcall(function()
        fileExists = isfile(CSV_PATH)
    end)
    
    if not success or not fileExists then
        return false
    end
    
    local content
    success, content = pcall(function()
        return readfile(CSV_PATH)
    end)
    
    if not success or not content or content == "" then
        return false
    end
    
    -- Parse CSV
    local lines = {}
    for line in content:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    if #lines < 2 then
        return false
    end
    
    -- Header: id,value,world,name
    local count = 0
    for i = 2, #lines do
        local parts = {}
        for part in lines[i]:gmatch("([^,]*),?") do
            table.insert(parts, part)
        end
        
        if #parts >= 4 then
            local id = parts[1]
            if id and id ~= "" then
                heroData[id] = {
                    value = parts[2] or "",
                    world = parts[3] or "",
                    name = parts[4] or ""
                }
                count = count + 1
            end
        end
    end
    
    if count > 0 then
        print(string.format("✅ Load %d hero dari CSV", count))
        return true
    end
    
    return false
end

-- Simpan ke JSON (alternatif)
local function saveToJSON()
    if not next(heroData) then
        return false
    end
    
    if not writefile then
        return false
    end
    
    ensureFolder()
    
    local dataToSave = {}
    for id, data in pairs(heroData) do
        dataToSave[id] = {
            value = data.value or "",
            world = data.world or "",
            name = data.name or ""
        }
    end
    
    local json
    local success, err = pcall(function()
        json = HttpService:JSONEncode(dataToSave)
    end)
    
    if not success then
        warn("❌ Gagal encode JSON: " .. tostring(err))
        return false
    end
    
    success, err = pcall(function()
        writefile(JSON_PATH, json)
    end)
    
    if success then
        print("✅ Data disimpan ke JSON: " .. JSON_PATH)
        return true
    else
        warn("❌ Gagal menyimpan JSON: " .. tostring(err))
        return false
    end
end

-- Load dari JSON
local function loadFromJSON()
    if not readfile or not isfile then
        return false
    end
    
    local fileExists
    local success, err = pcall(function()
        fileExists = isfile(JSON_PATH)
    end)
    
    if not success or not fileExists then
        return false
    end
    
    local content
    success, content = pcall(function()
        return readfile(JSON_PATH)
    end)
    
    if not success or not content or content == "" then
        return false
    end
    
    local decoded
    success, decoded = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if not success or type(decoded) ~= "table" then
        return false
    end
    
    local count = 0
    for id, data in pairs(decoded) do
        if type(data) == "table" then
            heroData[id] = {
                value = data.value or "",
                world = data.world or "",
                name = data.name or ""
            }
            count = count + 1
        end
    end
    
    if count > 0 then
        print(string.format("✅ Load %d hero dari JSON", count))
        return true
    end
    
    return false
end

-- Load data saat startup
local function loadAllData()
    -- Coba load dari CSV dulu
    if loadFromCSV() then
        return true
    end
    
    -- Jika gagal, coba dari JSON
    if loadFromJSON() then
        return true
    end
    
    -- Jika tidak ada data, buat contoh
    print("ℹ️ Tidak ada data ditemukan. Membuat data contoh.")
    heroData["7000117"] = {value = "1000", world = "World_1", name = "Hero_Contoh"}
    heroData["7000118"] = {value = "2000", world = "World_2", name = "Hero_Kedua"}
    saveToCSV()
    return true
end

-- Panggil load data
loadAllData()

--// ========== GUI CREATION ==========

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeroScannerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromOffset(400, 500)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 8)

-- Header
local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, -16, 0, 24)
headerFrame.Position = UDim2.fromOffset(8, 6)
headerFrame.BackgroundTransparency = 1
headerFrame.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.fromOffset(0, 0)
title.BackgroundTransparency = 1
title.Text = "🎯 Hero Scanner & CSV Saver"
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = headerFrame

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.fromOffset(20, 20)
minimizeBtn.Position = UDim2.new(1, -48, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = headerFrame
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 4)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(20, 20)
closeBtn.Position = UDim2.new(1, -24, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.Parent = headerFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

-- Minimized Button
local minimizedBtn = Instance.new("TextButton")
minimizedBtn.Size = UDim2.fromOffset(40, 40)
minimizedBtn.Position = UDim2.new(0, 20, 1, -60)
minimizedBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
minimizedBtn.Text = "🎯"
minimizedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizedBtn.Font = Enum.Font.GothamBold
minimizedBtn.TextSize = 18
minimizedBtn.AutoButtonColor = true
minimizedBtn.Visible = false
minimizedBtn.Parent = screenGui
Instance.new("UICorner", minimizedBtn).CornerRadius = UDim.new(0, 10)

-- Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -16, 0, 28)
tabContainer.Position = UDim2.fromOffset(8, 35)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local function createTab(name, text, position)
    local tab = Instance.new("TextButton")
    tab.Name = "Tab" .. name
    tab.Size = UDim2.new(0.25, -2, 1, 0)
    tab.Position = position
    tab.BackgroundColor3 = name == "Scan" and Color3.fromRGB(60, 120, 255) or Color3.fromRGB(40, 40, 45)
    tab.Text = text
    tab.TextColor3 = name == "Scan" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
    tab.Font = Enum.Font.GothamBold
    tab.TextSize = 11
    tab.AutoButtonColor = false
    tab.Parent = tabContainer
    Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 4)
    return tab
end

local tabScan = createTab("Scan", "🔍 Scan", UDim2.fromOffset(0, 0))
local tabData = createTab("Data", "📊 Data", UDim2.new(0.25, 4, 0, 0))
local tabCSV = createTab("CSV", "💾 CSV", UDim2.new(0.5, 4, 0, 0))
local tabAdd = createTab("Add", "➕ Add", UDim2.new(0.75, 4, 0, 0))

-- Tab Content Container
local tabContent = Instance.new("Frame")
tabContent.Size = UDim2.new(1, -16, 1, -80)
tabContent.Position = UDim2.fromOffset(8, 68)
tabContent.BackgroundTransparency = 1
tabContent.ClipsDescendants = true
tabContent.Parent = mainFrame

-- ========== TAB 1: SCAN ==========
local scanTab = Instance.new("ScrollingFrame")
scanTab.Size = UDim2.new(1, 0, 1, 0)
scanTab.Position = UDim2.fromOffset(0, 0)
scanTab.CanvasSize = UDim2.new(0, 0, 0, 0)
scanTab.ScrollBarThickness = 4
scanTab.BackgroundTransparency = 1
scanTab.BorderSizePixel = 0
scanTab.Visible = true
scanTab.Parent = tabContent

local scanLayout = Instance.new("UIListLayout", scanTab)
scanLayout.Padding = UDim.new(0, 8)
scanLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local scanPadding = Instance.new("UIPadding", scanTab)
scanPadding.PaddingTop = UDim.new(0, 5)
scanPadding.PaddingLeft = UDim.new(0, 5)
scanPadding.PaddingRight = UDim.new(0, 5)

-- ID Display
local idFrame = Instance.new("Frame")
idFrame.Size = UDim2.new(1, -10, 0, 40)
idFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
idFrame.BorderSizePixel = 0
idFrame.Parent = scanTab
Instance.new("UICorner", idFrame).CornerRadius = UDim.new(0, 6)

local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(0.3, -5, 1, 0)
idLabel.Position = UDim2.fromOffset(8, 0)
idLabel.BackgroundTransparency = 1
idLabel.Text = "Hero ID:"
idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
idLabel.Font = Enum.Font.Gotham
idLabel.TextSize = 12
idLabel.TextXAlignment = Enum.TextXAlignment.Left
idLabel.Parent = idFrame

local idValue = Instance.new("TextLabel")
idValue.Size = UDim2.new(0.65, -10, 1, 0)
idValue.Position = UDim2.new(0.32, 0, 0, 0)
idValue.BackgroundTransparency = 1
idValue.Text = tostring(heroId)
idValue.TextColor3 = Color3.fromRGB(0, 255, 200)
idValue.Font = Enum.Font.GothamBold
idValue.TextSize = 14
idValue.TextXAlignment = Enum.TextXAlignment.Left
idValue.Parent = idFrame

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.fromOffset(10, 50)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "✅ Siap... Auto Detect: ON"
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = scanTab

-- Auto Detect Toggle
local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0.45, -5, 0, 28)
autoBtn.Position = UDim2.fromOffset(10, 75)
autoBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
autoBtn.Text = "🔄 Auto Detect: ON"
autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBtn.Font = Enum.Font.GothamBold
autoBtn.TextSize = 11
autoBtn.Parent = scanTab
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 6)

-- Detect Now Button
local detectBtn = Instance.new("TextButton")
detectBtn.Size = UDim2.new(0.45, -5, 0, 28)
detectBtn.Position = UDim2.new(0.55, 0, 0, 75)
detectBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 200)
detectBtn.Text = "🔍 Detect Now"
detectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
detectBtn.Font = Enum.Font.GothamBold
detectBtn.TextSize = 11
detectBtn.Parent = scanTab
Instance.new("UICorner", detectBtn).CornerRadius = UDim.new(0, 6)

-- Detected IDs List
local detectedLabel = Instance.new("TextLabel")
detectedLabel.Size = UDim2.new(1, -20, 0, 20)
detectedLabel.Position = UDim2.fromOffset(10, 108)
detectedLabel.BackgroundTransparency = 1
detectedLabel.Text = "📋 Detected IDs:"
detectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
detectedLabel.Font = Enum.Font.GothamBold
detectedLabel.TextSize = 11
detectedLabel.TextXAlignment = Enum.TextXAlignment.Left
detectedLabel.Parent = scanTab

local detectedBox = Instance.new("ScrollingFrame")
detectedBox.Size = UDim2.new(1, -20, 0, 80)
detectedBox.Position = UDim2.fromOffset(10, 130)
detectedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
detectedBox.BorderSizePixel = 0
detectedBox.Parent = scanTab
Instance.new("UICorner", detectedBox).CornerRadius = UDim.new(0, 6)

local detectedList = Instance.new("UIListLayout", detectedBox)
detectedList.Padding = UDim.new(0, 2)

-- ========== TAB 2: DATA ==========
local dataTab = Instance.new("ScrollingFrame")
dataTab.Size = UDim2.new(1, 0, 1, 0)
dataTab.Position = UDim2.fromOffset(0, 0)
dataTab.CanvasSize = UDim2.new(0, 0, 0, 0)
dataTab.ScrollBarThickness = 4
dataTab.BackgroundTransparency = 1
dataTab.BorderSizePixel = 0
dataTab.Visible = false
dataTab.Parent = tabContent

local dataLayout = Instance.new("UIListLayout", dataTab)
dataLayout.Padding = UDim.new(0, 4)
dataLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local dataPadding = Instance.new("UIPadding", dataTab)
dataPadding.PaddingTop = UDim.new(0, 5)
dataPadding.PaddingLeft = UDim.new(0, 5)
dataPadding.PaddingRight = UDim.new(0, 5)

-- Refresh button untuk data
local refreshDataBtn = Instance.new("TextButton")
refreshDataBtn.Size = UDim2.new(1, -20, 0, 28)
refreshDataBtn.Position = UDim2.fromOffset(10, 0)
refreshDataBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
refreshDataBtn.Text = "🔄 Refresh Data"
refreshDataBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshDataBtn.Font = Enum.Font.GothamBold
refreshDataBtn.TextSize = 11
refreshDataBtn.Parent = dataTab
Instance.new("UICorner", refreshDataBtn).CornerRadius = UDim.new(0, 6)

local dataCountLabel = Instance.new("TextLabel")
dataCountLabel.Size = UDim2.new(1, -20, 0, 20)
dataCountLabel.Position = UDim2.fromOffset(10, 32)
dataCountLabel.BackgroundTransparency = 1
dataCountLabel.Text = "Total Heroes: 0"
dataCountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
dataCountLabel.Font = Enum.Font.Gotham
dataCountLabel.TextSize = 11
dataCountLabel.TextXAlignment = Enum.TextXAlignment.Left
dataCountLabel.Parent = dataTab

-- Container untuk list data
local dataListFrame = Instance.new("Frame")
dataListFrame.Size = UDim2.new(1, -20, 0, 0)
dataListFrame.Position = UDim2.fromOffset(10, 55)
dataListFrame.BackgroundTransparency = 1
dataListFrame.Parent = dataTab

local dataListLayout = Instance.new("UIListLayout", dataListFrame)
dataListLayout.Padding = UDim.new(0, 3)

-- ========== TAB 3: CSV ==========
local csvTab = Instance.new("Frame")
csvTab.Size = UDim2.new(1, 0, 1, 0)
csvTab.Position = UDim2.fromOffset(0, 0)
csvTab.BackgroundTransparency = 1
csvTab.Visible = false
csvTab.Parent = tabContent

-- Save CSV Button
local saveCSVBtn = Instance.new("TextButton")
saveCSVBtn.Size = UDim2.new(0.45, -5, 0, 35)
saveCSVBtn.Position = UDim2.fromOffset(10, 10)
saveCSVBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
saveCSVBtn.Text = "💾 Save CSV"
saveCSVBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveCSVBtn.Font = Enum.Font.GothamBold
saveCSVBtn.TextSize = 12
saveCSVBtn.Parent = csvTab
Instance.new("UICorner", saveCSVBtn).CornerRadius = UDim.new(0, 6)

-- Load CSV Button
local loadCSVBtn = Instance.new("TextButton")
loadCSVBtn.Size = UDim2.new(0.45, -5, 0, 35)
loadCSVBtn.Position = UDim2.new(0.55, 0, 0, 10)
loadCSVBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 200)
loadCSVBtn.Text = "📂 Load CSV"
loadCSVBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadCSVBtn.Font = Enum.Font.GothamBold
loadCSVBtn.TextSize = 12
loadCSVBtn.Parent = csvTab
Instance.new("UICorner", loadCSVBtn).CornerRadius = UDim.new(0, 6)

-- CSV Status
local csvStatus = Instance.new("TextLabel")
csvStatus.Size = UDim2.new(1, -20, 0, 20)
csvStatus.Position = UDim2.fromOffset(10, 50)
csvStatus.BackgroundTransparency = 1
csvStatus.Text = "📁 Lokasi: " .. CSV_PATH
csvStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
csvStatus.Font = Enum.Font.Gotham
csvStatus.TextSize = 10
csvStatus.TextXAlignment = Enum.TextXAlignment.Left
csvStatus.Parent = csvTab

-- CSV Content Preview
local csvPreview = Instance.new("ScrollingFrame")
csvPreview.Size = UDim2.new(1, -20, 0, 250)
csvPreview.Position = UDim2.fromOffset(10, 75)
csvPreview.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
csvPreview.BorderSizePixel = 0
csvPreview.Parent = csvTab
Instance.new("UICorner", csvPreview).CornerRadius = UDim.new(0, 6)

local csvPreviewLabel = Instance.new("TextLabel")
csvPreviewLabel.Size = UDim2.new(1, -10, 0, 0)
csvPreviewLabel.Position = UDim2.fromOffset(5, 5)
csvPreviewLabel.BackgroundTransparency = 1
csvPreviewLabel.Text = ""
csvPreviewLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
csvPreviewLabel.Font = Enum.Font.Code
csvPreviewLabel.TextSize = 10
csvPreviewLabel.TextXAlignment = Enum.TextXAlignment.Left
csvPreviewLabel.TextYAlignment = Enum.TextYAlignment.Top
csvPreviewLabel.TextWrapped = false
csvPreviewLabel.Parent = csvPreview

-- ========== TAB 4: ADD HERO ==========
local addTab = Instance.new("Frame")
addTab.Size = UDim2.new(1, 0, 1, 0)
addTab.Position = UDim2.fromOffset(0, 0)
addTab.BackgroundTransparency = 1
addTab.Visible = false
addTab.Parent = tabContent

local function createInput(parent, labelText, yPos, isId)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.25, -5, 0, 25)
    label.Position = UDim2.fromOffset(10, yPos)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Right
    label.Parent = parent
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.65, -10, 0, 25)
    box.Position = UDim2.new(0.28, 0, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    
    if isId then
        box.Text = tostring(heroId)
        box.PlaceholderText = "Hero ID"
    else
        box.Text = ""
        box.PlaceholderText = labelText
    end
    
    return box
end

local addIdBox = createInput(addTab, "Hero ID:", 10, true)
local addValueBox = createInput(addTab, "Nilai:", 45, false)
local addWorldBox = createInput(addTab, "World:", 80, false)
local addNameBox = createInput(addTab, "Name:", 115, false)

-- Add Button
local addHeroBtn = Instance.new("TextButton")
addHeroBtn.Size = UDim2.new(0.45, -5, 0, 35)
addHeroBtn.Position = UDim2.fromOffset(10, 155)
addHeroBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
addHeroBtn.Text = "➕ Add Hero"
addHeroBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addHeroBtn.Font = Enum.Font.GothamBold
addHeroBtn.TextSize = 12
addHeroBtn.Parent = addTab
Instance.new("UICorner", addHeroBtn).CornerRadius = UDim.new(0, 6)

-- Add Status
local addStatus = Instance.new("TextLabel")
addStatus.Size = UDim2.new(1, -20, 0, 20)
addStatus.Position = UDim2.fromOffset(10, 195)
addStatus.BackgroundTransparency = 1
addStatus.Text = "🔔 Masukkan data hero"
addStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
addStatus.Font = Enum.Font.Gotham
addStatus.TextSize = 10
addStatus.TextXAlignment = Enum.TextXAlignment.Left
addStatus.Parent = addTab

-- ========== FUNGSI UI ==========

-- Fungsi untuk mengupdate status
local function updateStatus(text, color)
    statusLabel.Text = text
    if color then
        statusLabel.TextColor3 = color
    end
end

-- Fungsi untuk toggle minimize
local function toggleMinimize()
    if mainFrame.Visible then
        mainFrame.Visible = false
        minimizedBtn.Visible = true
    else
        mainFrame.Visible = true
        minimizedBtn.Visible = false
    end
end

minimizeBtn.MouseButton1Click:Connect(toggleMinimize)
minimizedBtn.MouseButton1Click:Connect(toggleMinimize)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Fungsi switch tab
local function switchTab(tabName)
    tabScan.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    tabScan.TextColor3 = Color3.fromRGB(180, 180, 180)
    tabData.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    tabData.TextColor3 = Color3.fromRGB(180, 180, 180)
    tabCSV.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    tabCSV.TextColor3 = Color3.fromRGB(180, 180, 180)
    tabAdd.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    tabAdd.TextColor3 = Color3.fromRGB(180, 180, 180)
    
    scanTab.Visible = false
    dataTab.Visible = false
    csvTab.Visible = false
    addTab.Visible = false
    
    if tabName == "Scan" then
        tabScan.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
        tabScan.TextColor3 = Color3.fromRGB(255, 255, 255)
        scanTab.Visible = true
    elseif tabName == "Data" then
        tabData.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
        tabData.TextColor3 = Color3.fromRGB(255, 255, 255)
        dataTab.Visible = true
        refreshDataList()
    elseif tabName == "CSV" then
        tabCSV.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
        tabCSV.TextColor3 = Color3.fromRGB(255, 255, 255)
        csvTab.Visible = true
        updateCSVPreview()
    elseif tabName == "Add" then
        tabAdd.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
        tabAdd.TextColor3 = Color3.fromRGB(255, 255, 255)
        addTab.Visible = true
    end
end

tabScan.MouseButton1Click:Connect(function() switchTab("Scan") end)
tabData.MouseButton1Click:Connect(function() switchTab("Data") end)
tabCSV.MouseButton1Click:Connect(function() switchTab("CSV") end)
tabAdd.MouseButton1Click:Connect(function() switchTab("Add") end)

-- ========== TAB 1: SCAN FUNCTIONS ==========

-- Update detected IDs list
local function updateDetectedList()
    for _, child in ipairs(detectedBox:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    if not next(detectedIds) then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 20)
        empty.BackgroundTransparency = 1
        empty.Text = "Belum ada ID terdeteksi"
        empty.TextColor3 = Color3.fromRGB(150, 150, 150)
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 11
        empty.Parent = detectedBox
        return
    end
    
    for _, id in ipairs(detectedIds) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = "• " .. id
        label.TextColor3 = Color3.fromRGB(200, 255, 200)
        label.Font = Enum.Font.Gotham
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = detectedBox
    end
end

-- Get DrawHero Event
local function getDrawHeroEvent()
    local success, event = pcall(function()
        return ReplicatedStorage:WaitForChild("Tool"):WaitForChild("DrawUp"):WaitForChild("Msg"):WaitForChild("DrawHero")
    end)
    if success and event then
        return event
    end
    return nil
end

-- Hook untuk deteksi otomatis
local DrawHeroEvent = nil
local oldNamecall = nil

local function initializeRemoteHook()
    DrawHeroEvent = getDrawHeroEvent()
    
    if not DrawHeroEvent then
        updateStatus("❌ Event DrawHero tidak ditemukan!", Color3.fromRGB(255, 0, 0))
        return false
    end
    
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not hookEnabled then
            return oldNamecall(self, ...)
        end
        
        local args = {...}
        local method = getnamecallmethod()
        
        if self == DrawHeroEvent and method == "InvokeServer" then
            if #args >= 1 then
                local id = args[1]
                if type(id) == "number" and id > 0 then
                    if id ~= heroId then
                        heroId = id
                        idValue.Text = tostring(heroId)
                        addIdBox.Text = tostring(heroId)
                        updateStatus("🎯 ID terdeteksi: " .. heroId, Color3.fromRGB(0, 255, 0))
                        
                        -- Tambahkan ke detected IDs
                        local idStr = tostring(id)
                        if not table.find(detectedIds, idStr) then
                            table.insert(detectedIds, idStr)
                            updateDetectedList()
                        end
                    end
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
    
    updateStatus("✅ Hook aktif. Menunggu InvokeServer...", Color3.fromRGB(255, 255, 0))
    return true
end

-- Auto Detect toggle
autoBtn.MouseButton1Click:Connect(function()
    autoDetect = not autoDetect
    hookEnabled = autoDetect
    
    if autoDetect then
        autoBtn.Text = "🔄 Auto Detect: ON"
        autoBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        initializeRemoteHook()
    else
        autoBtn.Text = "🔄 Auto Detect: OFF"
        autoBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        hookEnabled = false
    end
end)

-- Detect Now
detectBtn.MouseButton1Click:Connect(function()
    updateStatus("⏳ Mencoba mendeteksi ID...", Color3.fromRGB(255, 165, 0))
    
    local tempEvent = getDrawHeroEvent()
    if tempEvent then
        pcall(function()
            tempEvent:InvokeServer(1, 1)
            task.wait(0.2)
            tempEvent:InvokeServer(2, 1)
        end)
    end
    
    if heroId == 7000117 and not next(detectedIds) then
        updateStatus("❌ Tidak ada ID terdeteksi. Coba jalankan game.", Color3.fromRGB(255, 0, 0))
    else
        updateStatus("✅ Scan selesai!", Color3.fromRGB(0, 255, 0))
    end
end)

-- ========== TAB 2: DATA FUNCTIONS ==========

-- Format data untuk display
local function formatHeroDisplay(id, data)
    return string.format("%s | %s | %s | %s", id, data.value or "-", data.world or "-", data.name or "-")
end

-- Refresh data list
local function refreshDataList()
    for _, child in ipairs(dataListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local count = 0
    for id, data in pairs(heroData) do
        count = count + 1
        
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, 0, 0, 28)
        item.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        item.BorderSizePixel = 0
        item.Parent = dataListFrame
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, -10, 1, 0)
        label.Position = UDim2.fromOffset(8, 0)
        label.BackgroundTransparency = 1
        label.Text = formatHeroDisplay(id, data)
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Font = Enum.Font.Gotham
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = item
        
        -- Delete button
        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.fromOffset(24, 20)
        delBtn.Position = UDim2.new(1, -28, 0.5, -10)
        delBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        delBtn.Text = "X"
        delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 10
        delBtn.Parent = item
        Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
        
        delBtn.MouseButton1Click:Connect(function()
            heroData[id] = nil
            item:Destroy()
            saveToCSV()
            refreshDataList()
            updateDataCount()
        end)
    end
    
    updateDataCount()
end

local function updateDataCount()
    local count = 0
    for _ in pairs(heroData) do
        count = count + 1
    end
    dataCountLabel.Text = "Total Heroes: " .. count
end

refreshDataBtn.MouseButton1Click:Connect(refreshDataList)

-- ========== TAB 3: CSV FUNCTIONS ==========

local function updateCSVPreview()
    if not readfile or not isfile then
        csvPreviewLabel.Text = "⚠️ writefile/readfile tidak tersedia"
        return
    end
    
    local fileExists
    local success, err = pcall(function()
        fileExists = isfile(CSV_PATH)
    end)
    
    if not success or not fileExists then
        csvPreviewLabel.Text = "📁 File CSV belum dibuat"
        return
    end
    
    local content
    success, content = pcall(function()
        return readfile(CSV_PATH)
    end)
    
    if success and content then
        csvPreviewLabel.Text = content
        csvPreviewLabel.Size = UDim2.new(1, -10, 0, #content * 0.7 + 10)
    else
        csvPreviewLabel.Text = "❌ Gagal membaca file"
    end
end

saveCSVBtn.MouseButton1Click:Connect(function()
    if saveToCSV() then
        csvStatus.Text = "✅ CSV saved: " .. CSV_PATH
        csvStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
        updateCSVPreview()
    else
        csvStatus.Text = "❌ Gagal menyimpan CSV"
        csvStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

loadCSVBtn.MouseButton1Click:Connect(function()
    if loadFromCSV() then
        csvStatus.Text = "✅ CSV loaded: " .. CSV_PATH
        csvStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
        updateCSVPreview()
        refreshDataList()
    else
        csvStatus.Text = "❌ Gagal load CSV"
        csvStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

-- ========== TAB 4: ADD HERO FUNCTIONS ==========

addHeroBtn.MouseButton1Click:Connect(function()
    local id = addIdBox.Text:gsub("%s+", "")
    local value = addValueBox.Text
    local world = addWorldBox.Text
    local name = addNameBox.Text
    
    if id == "" then
        addStatus.Text = "❌ Hero ID harus diisi!"
        addStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end
    
    if heroData[id] then
        addStatus.Text = "⚠️ ID " .. id .. " sudah ada!"
        addStatus.TextColor3 = Color3.fromRGB(255, 165, 0)
        return
    end
    
    heroData[id] = {
        value = value,
        world = world,
        name = name
    }
    
    addStatus.Text = "✅ Hero " .. id .. " berhasil ditambahkan!"
    addStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
    
    -- Reset inputs
    addValueBox.Text = ""
    addWorldBox.Text = ""
    addNameBox.Text = ""
    
    saveToCSV()
    refreshDataList()
end)

-- ========== INITIALIZATION ==========

-- Inisialisasi hook
local initSuccess = initializeRemoteHook()
if initSuccess then
    updateStatus("✅ Script siap. Auto Detect aktif.", Color3.fromRGB(0, 255, 0))
else
    updateStatus("⚠️ Auto Detect gagal. Gunakan Detect Now.", Color3.fromRGB(255, 165, 0))
end

-- Refresh data
refreshDataList()
updateCSVPreview()

-- Update status akhir
print("🎯 Hero Scanner & CSV Saver Loaded!")
print("📊 Total heroes: " .. table.count(heroData))
print("📁 Lokasi: " .. CSV_PATH)
