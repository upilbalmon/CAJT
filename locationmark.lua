--[[ 
GUI Location Mark + Import + Waypoint (Roblox Lua)
Dengan penyimpanan di folder Delta
]]

-- ==== Helper: Dapatkan Player & Services ====
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")

-- ==== KONFIGURASI PENYIMPANAN DELTA ====
local STORAGE_FOLDER = "locationmark/"
local STORAGE_PATH = STORAGE_FOLDER .. "locations.json"

-- ==== Data ====
local locations = {}  -- { [name] = Vector3, ... }
local savedLocations = {}

-- ==== Fungsi Penyimpanan Delta ====
local function ensureFolder()
    if not makefolder then
        warn("⚠️ Fungsi makefolder tidak tersedia")
        return false
    end

    local success, err = pcall(function()
        makefolder(STORAGE_FOLDER)
    end)

    if success then
        print("✅ Folder berhasil dibuat: " .. STORAGE_FOLDER)
        return true
    else
        warn("❌ Gagal membuat folder: " .. tostring(err))
        return false
    end
end

local function saveData()
    if not next(locations) then
        print("⚠️ Tidak ada data untuk disimpan")
        return false
    end

    local dataToSave = {}
    for name, pos in pairs(locations) do
        dataToSave[name] = {X = pos.X, Y = pos.Y, Z = pos.Z}
    end

    local json
    local success, err = pcall(function()
        json = HttpService:JSONEncode(dataToSave)
    end)

    if not success then
        warn("❌ Gagal encode JSON: " .. tostring(err))
        return false
    end

    if writefile then
        success, err = pcall(function()
            ensureFolder()
            writefile(STORAGE_PATH, json)
        end)

        if success then
            print("✅ Data berhasil disimpan ke: " .. STORAGE_PATH)
            return true
        else
            warn("❌ Gagal menyimpan ke file: " .. tostring(err))
        end
    end

    -- Fallback ke atribut player
    success, err = pcall(function()
        player:SetAttribute("LocationData", json)
    end)

    if success then
        print("✅ Data berhasil disimpan ke atribut player")
        return true
    end

    return false
end

local function loadData()
    local dataLoaded = false

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
                    return HttpService:JSONDecode(content)
                end)

                if success and type(decoded) == "table" then
                    local count = 0
                    for name, posData in pairs(decoded) do
                        if type(posData) == "table" and posData.X and posData.Y and posData.Z then
                            locations[name] = Vector3.new(posData.X, posData.Y, posData.Z)
                            count = count + 1
                        end
                    end
                    if count > 0 then
                        print(string.format("✅ Berhasil memuat %d location mark", count))
                        dataLoaded = true
                    end
                end
            end
        end
    end

    if not dataLoaded then
        local attrData = player:GetAttribute("LocationData")
        if attrData and attrData ~= "" then
            local decoded
            local success, err = pcall(function()
                decoded = HttpService:JSONDecode(attrData)
            end)

            if success and type(decoded) == "table" then
                local count = 0
                for name, posData in pairs(decoded) do
                    if type(posData) == "table" and posData.X and posData.Y and posData.Z then
                        locations[name] = Vector3.new(posData.X, posData.Y, posData.Z)
                        count = count + 1
                    end
                end
                if count > 0 then
                    print(string.format("✅ Berhasil memuat %d location mark dari atribut", count))
                    dataLoaded = true
                end
            end
        end
    end

    if not dataLoaded then
        print("ℹ️ Tidak ada data ditemukan. Membuat data contoh.")
        locations["Rumah"] = Vector3.new(0, 10, 0)
        locations["Toko"] = Vector3.new(100, 5, 200)
        saveData()
    end

    return dataLoaded
end

-- Load data
loadData()

-- ============================================
-- UI CREATION
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LocationMarkGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Container utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(280, 380)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -190)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BackgroundTransparency = 0.4
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 8)

local uiPadding = Instance.new("UIPadding", mainFrame)
uiPadding.PaddingTop = UDim.new(0, 8)
uiPadding.PaddingBottom = UDim.new(0, 8)
uiPadding.PaddingLeft = UDim.new(0, 8)
uiPadding.PaddingRight = UDim.new(0, 8)

-- Header
local headerFrame = Instance.new("Frame")
headerFrame.Name = "HeaderFrame"
headerFrame.Size = UDim2.new(1, -16, 0, 19)
headerFrame.Position = UDim2.fromOffset(8, 5)
headerFrame.BackgroundTransparency = 1
headerFrame.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.fromOffset(0, 0)
title.BackgroundTransparency = 1
title.Text = "📍 Location Mark"
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = headerFrame

-- Tombol Minimize
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.fromOffset(16, 16)
minimizeBtn.Position = UDim2.new(1, -36, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
minimizeBtn.TextColor3 = Color3.new(250, 250, 250)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 12
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = headerFrame
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 4)

-- Tombol Close
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.fromOffset(16, 16)
closeBtn.Position = UDim2.new(1, -18, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.AutoButtonColor = false
closeBtn.Parent = headerFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

-- Tombol Minimized
local minimizedBtn = Instance.new("TextButton")
minimizedBtn.Name = "MinimizedBtn"
minimizedBtn.Size = UDim2.fromOffset(40, 40)
minimizedBtn.Position = UDim2.new(0, 20, 1, -60)
minimizedBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
minimizedBtn.TextColor3 = Color3.new(1, 1, 1)
minimizedBtn.Text = "📍"
minimizedBtn.Font = Enum.Font.GothamBold
minimizedBtn.TextSize = 16
minimizedBtn.AutoButtonColor = true
minimizedBtn.Visible = false
minimizedBtn.Parent = screenGui
Instance.new("UICorner", minimizedBtn).CornerRadius = UDim.new(0, 8)

-- Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, -16, 0, 24)
tabContainer.Position = UDim2.fromOffset(8, 29)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local function createTab(name, text, position, size)
	local tab = Instance.new("TextButton")
	tab.Name = "Tab" .. name
	tab.Size = size
	tab.Position = position
	tab.BackgroundColor3 = name == "Location" and Color3.fromRGB(60, 120, 255) or Color3.fromRGB(40, 40, 40)
	tab.Text = text
	tab.TextColor3 = name == "Location" and Color3.new(1, 1, 1) or Color3.fromRGB(180, 180, 180)
	tab.Font = Enum.Font.GothamBold
	tab.TextSize = 10
	tab.AutoButtonColor = false
	tab.Parent = tabContainer
	Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 4)
	return tab
end

local tabLocation = createTab("Location", "Location", UDim2.fromOffset(0, 0), UDim2.new(0.333, -2, 1, 0))
local tabImport = createTab("Import", "Import", UDim2.new(0.333, 2, 0, 0), UDim2.new(0.333, -2, 1, 0))
local tabSaver = createTab("Saver", "Saver", UDim2.new(0.666, 2, 0, 0), UDim2.new(0.333, 0, 1, 0))

-- Container untuk konten tab
local tabContent = Instance.new("Frame")
tabContent.Name = "TabContent"
tabContent.Size = UDim2.new(1, -16, 1, -65)
tabContent.Position = UDim2.fromOffset(8, 58)
tabContent.BackgroundTransparency = 1
tabContent.ClipsDescendants = true
tabContent.Parent = mainFrame

-- ===== TAB LOCATION =====
local locationTab = Instance.new("ScrollingFrame")
locationTab.Name = "LocationTab"
locationTab.Size = UDim2.new(1, 0, 1, 0)
locationTab.Position = UDim2.fromOffset(0, 0)
locationTab.CanvasSize = UDim2.new(0, 0, 0, 0)
locationTab.ScrollBarThickness = 4
locationTab.BackgroundTransparency = 1
locationTab.BorderSizePixel = 0
locationTab.Visible = true
locationTab.Parent = tabContent

local uiList = Instance.new("UIListLayout", locationTab)
uiList.Padding = UDim.new(0, 5)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Left
uiList.SortOrder = Enum.SortOrder.LayoutOrder

local listPadding = Instance.new("UIPadding", locationTab)
listPadding.PaddingTop = UDim.new(0, 5)
listPadding.PaddingLeft = UDim.new(0, 5)
listPadding.PaddingRight = UDim.new(0, 5)
listPadding.PaddingBottom = UDim.new(0, 5)

local function updateCanvasSize()
	task.defer(function()
		local contentSize = uiList.AbsoluteContentSize
		locationTab.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 10)
	end)
end
uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)

-- ===== TAB IMPORT =====
local importTab = Instance.new("Frame")
importTab.Name = "ImportTab"
importTab.Size = UDim2.new(1, 0, 1, 0)
importTab.Position = UDim2.fromOffset(0, 0)
importTab.BackgroundTransparency = 1
importTab.Visible = false
importTab.Parent = tabContent

local importBox = Instance.new("TextBox")
importBox.Name = "ImportBox"
importBox.Size = UDim2.new(1, 0, 0, 100)
importBox.Position = UDim2.fromOffset(0, 0)
importBox.TextWrapped = true
importBox.ClearTextOnFocus = false
importBox.MultiLine = true
importBox.PlaceholderText = 'Tempel data di sini...\nContoh:\n["CP3"] = Vector3.new(-1636.47, 992.97, 284.60),'
importBox.TextXAlignment = Enum.TextXAlignment.Left
importBox.TextYAlignment = Enum.TextYAlignment.Top
importBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
importBox.TextColor3 = Color3.fromRGB(230, 230, 230)
importBox.Font = Enum.Font.Code
importBox.TextSize = 9
importBox.Parent = importTab
Instance.new("UICorner", importBox).CornerRadius = UDim.new(0, 5)

local importBtn = Instance.new("TextButton")
importBtn.Name = "ImportBtn"
importBtn.Size = UDim2.fromOffset(67, 21)
importBtn.Position = UDim2.fromOffset(0, 108)
importBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
importBtn.Text = "Import"
importBtn.TextColor3 = Color3.new(1,1,1)
importBtn.Font = Enum.Font.GothamBold
importBtn.TextSize = 9
importBtn.AutoButtonColor = true
importBtn.Parent = importTab
Instance.new("UICorner", importBtn).CornerRadius = UDim.new(0, 5)

local statusLbl = Instance.new("TextLabel")
statusLbl.Name = "StatusLabel"
statusLbl.Size = UDim2.new(1, -75, 0, 21)
statusLbl.Position = UDim2.fromOffset(72, 108)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = ""
statusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 9
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = importTab

-- ===== TAB SAVER =====
local saverTab = Instance.new("Frame")
saverTab.Name = "SaverTab"
saverTab.Size = UDim2.new(1, 0, 1, 0)
saverTab.Position = UDim2.fromOffset(0, 0)
saverTab.BackgroundTransparency = 1
saverTab.Visible = false
saverTab.Parent = tabContent

local function applyCorner(guiObject, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = guiObject
end

local saverTextBox = Instance.new("TextBox")
saverTextBox.Size = UDim2.new(1, -10, 0, 30)
saverTextBox.Position = UDim2.new(0, 5, 0, 5)
saverTextBox.PlaceholderText = "Masukkan nama lokasi"
saverTextBox.Text = ""
saverTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
saverTextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
saverTextBox.BackgroundTransparency = 0.7
saverTextBox.Parent = saverTab
applyCorner(saverTextBox, 6)

local function styleBlueButton(btn)
	btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

local saveButton = Instance.new("TextButton")
saveButton.Size = UDim2.new(0.5, -7, 0, 45)
saveButton.Position = UDim2.new(0, 5, 0, 45)
saveButton.Text = "Simpan Lokasi"
saveButton.Parent = saverTab
styleBlueButton(saveButton)
applyCorner(saveButton, 6)

local printButton = Instance.new("TextButton")
printButton.Size = UDim2.new(0.5, -7, 0, 45)
printButton.Position = UDim2.new(0.5, 2, 0, 45)
printButton.Text = "Print & Copy"
printButton.Parent = saverTab
styleBlueButton(printButton)
applyCorner(printButton, 6)

local saverStatusLabel = Instance.new("TextLabel")
saverStatusLabel.Name = "StatusLabel"
saverStatusLabel.Size = UDim2.new(1, -10, 0, 20)
saverStatusLabel.Position = UDim2.new(0, 5, 1, -25)
saverStatusLabel.BackgroundTransparency = 1
saverStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 50)
saverStatusLabel.Text = "🔔 Siap digunakan"
saverStatusLabel.TextSize = 8
saverStatusLabel.Parent = saverTab

-- ===== Fungsi GUI =====
local function setStatus(text, isError)
	statusLbl.Text = text or ""
	if isError then
		statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
	else
		statusLbl.TextColor3 = Color3.fromRGB(180, 220, 160)
	end
end

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

local function switchTab(selectedTab)
	tabLocation.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	tabLocation.TextColor3 = Color3.fromRGB(180, 180, 180)
	tabImport.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	tabImport.TextColor3 = Color3.fromRGB(180, 180, 180)
	tabSaver.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	tabSaver.TextColor3 = Color3.fromRGB(180, 180, 180)

	locationTab.Visible = false
	importTab.Visible = false
	saverTab.Visible = false

	if selectedTab == "location" then
		tabLocation.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
		tabLocation.TextColor3 = Color3.new(1, 1, 1)
		locationTab.Visible = true
	elseif selectedTab == "import" then
		tabImport.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
		tabImport.TextColor3 = Color3.new(1, 1, 1)
		importTab.Visible = true
	elseif selectedTab == "saver" then
		tabSaver.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
		tabSaver.TextColor3 = Color3.new(1, 1, 1)
		saverTab.Visible = true
	end
end

tabLocation.MouseButton1Click:Connect(function() switchTab("location") end)
tabImport.MouseButton1Click:Connect(function() switchTab("import") end)
tabSaver.MouseButton1Click:Connect(function() switchTab("saver") end)

-- ==== Buat item location mark DENGAN TOMBOL RENAME ====
local function makeListItem(name, v3)
	local item = Instance.new("Frame")
	item.Name = "Item_" .. name
	item.Size = UDim2.new(1, -10, 0, 32)
	item.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	item.BorderSizePixel = 0
	item.Parent = locationTab
	Instance.new("UICorner", item).CornerRadius = UDim.new(0, 5)

	-- Label nama
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "NameLabel"
	nameLbl.Size = UDim2.new(1, -115, 1, -0)  -- Dikurangi untuk tombol rename
	nameLbl.Position = UDim2.fromOffset(8, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Text = name
	nameLbl.TextColor3 = Color3.fromRGB(235, 235, 235)
	nameLbl.Font = Enum.Font.Gotham
	nameLbl.TextSize = 11
	nameLbl.Parent = item

	-- Tombol Rename
	local renameBtn = Instance.new("TextButton")
	renameBtn.Name = "RenameBtn"
	renameBtn.Size = UDim2.fromOffset(28, 24)
	renameBtn.Position = UDim2.new(1, -108, 0.5, -12)
	renameBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 50)
	renameBtn.Text = "✎"
	renameBtn.TextColor3 = Color3.new(1,1,1)
	renameBtn.Font = Enum.Font.GothamBold
	renameBtn.TextSize = 12
	renameBtn.AutoButtonColor = true
	renameBtn.Parent = item
	Instance.new("UICorner", renameBtn).CornerRadius = UDim.new(0, 5)

	-- Tombol Teleport
	local tpBtn = Instance.new("TextButton")
	tpBtn.Name = "TpBtn"
	tpBtn.Size = UDim2.fromOffset(45, 24)
	tpBtn.Position = UDim2.new(1, -78, 0.5, -12)
	tpBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 90)
	tpBtn.Text = "TP"
	tpBtn.TextColor3 = Color3.new(1,1,1)
	tpBtn.Font = Enum.Font.GothamBold
	tpBtn.TextSize = 10
	tpBtn.AutoButtonColor = true
	tpBtn.Parent = item
	Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 5)

	-- Tombol Hapus
	local delBtn = Instance.new("TextButton")
	delBtn.Name = "DelBtn"
	delBtn.Size = UDim2.fromOffset(24, 24)
	delBtn.Position = UDim2.new(1, -30, 0.5, -12)
	delBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
	delBtn.Text = "X"
	delBtn.TextColor3 = Color3.new(1,1,1)
	delBtn.Font = Enum.Font.GothamBold
	delBtn.TextSize = 12
	delBtn.AutoButtonColor = true
	delBtn.Parent = item
	Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 5)

	-- ===== FUNGSI RENAME =====
	renameBtn.MouseButton1Click:Connect(function()
		-- Buat popup input untuk rename
		local popup = Instance.new("Frame")
		popup.Name = "RenamePopup"
		popup.Size = UDim2.fromOffset(200, 80)
		popup.Position = UDim2.new(0.5, -100, 0.5, -40)
		popup.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		popup.BackgroundTransparency = 0.1
		popup.BorderSizePixel = 0
		popup.Parent = screenGui
		Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 8)

		-- Efek blur background
		local blur = Instance.new("BlurEffect", game:GetService("Lighting"))
		blur.Size = 8

		-- Label
		local popupLabel = Instance.new("TextLabel")
		popupLabel.Size = UDim2.new(1, -20, 0, 20)
		popupLabel.Position = UDim2.new(0, 10, 0, 5)
		popupLabel.BackgroundTransparency = 1
		popupLabel.Text = "Masukkan nama baru:"
		popupLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		popupLabel.Font = Enum.Font.Gotham
		popupLabel.TextSize = 11
		popupLabel.TextXAlignment = Enum.TextXAlignment.Left
		popupLabel.Parent = popup

		-- Input Box
		local renameInput = Instance.new("TextBox")
		renameInput.Size = UDim2.new(1, -20, 0, 25)
		renameInput.Position = UDim2.new(0, 10, 0, 30)
		renameInput.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		renameInput.Text = name
		renameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
		renameInput.Font = Enum.Font.Gotham
		renameInput.TextSize = 11
		renameInput.Parent = popup
		Instance.new("UICorner", renameInput).CornerRadius = UDim.new(0, 4)

		-- Tombol Rename
		local confirmBtn = Instance.new("TextButton")
		confirmBtn.Size = UDim2.fromOffset(60, 25)
		confirmBtn.Position = UDim2.new(1, -70, 1, -30)
		confirmBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
		confirmBtn.Text = "Rename"
		confirmBtn.TextColor3 = Color3.new(1,1,1)
		confirmBtn.Font = Enum.Font.GothamBold
		confirmBtn.TextSize = 10
		confirmBtn.AutoButtonColor = true
		confirmBtn.Parent = popup
		Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 4)

		-- Tombol Batal
		local cancelBtn = Instance.new("TextButton")
		cancelBtn.Size = UDim2.fromOffset(50, 25)
		cancelBtn.Position = UDim2.new(1, -125, 1, -30)
		cancelBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
		cancelBtn.Text = "Batal"
		cancelBtn.TextColor3 = Color3.new(1,1,1)
		cancelBtn.Font = Enum.Font.GothamBold
		cancelBtn.TextSize = 10
		cancelBtn.AutoButtonColor = true
		cancelBtn.Parent = popup
		Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 4)

		-- Fungsi rename
		local function doRename()
			local newName = renameInput.Text
			if newName == "" then
				setStatus("❌ Nama tidak boleh kosong!", true)
				return
			end

			if locations[newName] then
				setStatus("❌ Nama '" .. newName .. "' sudah digunakan!", true)
				return
			end

			-- Pindahkan data ke nama baru
			locations[newName] = locations[name]
			locations[name] = nil

			-- Update UI
			nameLbl.Text = newName
			item.Name = "Item_" .. newName
			
			-- Update nama di tabel data
			saveData()
			setStatus("✅ Berhasil rename '" .. name .. "' → '" .. newName .. "'", false)
			
			-- Tutup popup
			popup:Destroy()
			blur:Destroy()
		end

		confirmBtn.MouseButton1Click:Connect(doRename)
		cancelBtn.MouseButton1Click:Connect(function()
			popup:Destroy()
			blur:Destroy()
		end)
		
		-- Enter key untuk rename
		renameInput.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				doRename()
			end
		end)

		-- Fokus ke input
		renameInput:CaptureFocus()
	end)

	-- ===== TELEPORT =====
	tpBtn.MouseButton1Click:Connect(function()
		local char = player.Character or player.CharacterAdded:Wait()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(v3)
			setStatus("Teleport ke " .. name .. " ✓", false)
		else
			setStatus("Gagal teleport: HRP tidak ditemukan.", true)
		end
	end)

	-- ===== DELETE =====
	delBtn.MouseButton1Click:Connect(function()
		locations[name] = nil
		item:Destroy()
		updateCanvasSize()
		saveData()
		setStatus("Hapus location mark: " .. name, false)
	end)

	return item
end

local function renderList()
	for _, child in ipairs(locationTab:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^Item_") then
			child:Destroy()
		end
	end
	
	local names = {}
	for name in pairs(locations) do
		table.insert(names, name)
	end
	table.sort(names, function(a, b) return a:lower() < b:lower() end)

	for _, name in ipairs(names) do
		makeListItem(name, locations[name])
	end

	updateCanvasSize()
end

-- ==== Parser Import ====
local function parseAndImport(text)
	if not text or text == "" then
		return false, "Input kosong."
	end

	local count = 0
	for name, x, y, z in text:gmatch("%[\"(.-)\"%]%s*=%s*Vector3%.new%s*%(%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*%)") do
		local vx = tonumber(x)
		local vy = tonumber(y)
		local vz = tonumber(z)
		if name ~= "" and vx and vy and vz then
			locations[name] = Vector3.new(vx, vy, vz)
			count = count + 1
		end
	end

	if count == 0 then
		return false, "Tidak ada baris valid yang ditemukan."
	end

	renderList()
	saveData()
	switchTab("location")
	return true, ("Berhasil import %d location mark."):format(count)
end

importBtn.MouseButton1Click:Connect(function()
	local ok, msg = parseAndImport(importBox.Text)
	setStatus(msg, not ok)
end)

-- ==== Generate nama otomatis ====
local function generateAutoName()
	local maxNum = 0
	for name in pairs(locations) do
		local num = name:match("Lokasi (%d+)")
		if num then
			num = tonumber(num)
			if num and num > maxNum then
				maxNum = num
			end
		end
	end
	return "Lokasi " .. (maxNum + 1)
end

-- ==== Fungsi Save ====
saveButton.MouseButton1Click:Connect(function()
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then 
		saverStatusLabel.Text = "❌ Character belum siap!"
		return 
	end

	local pos = player.Character.HumanoidRootPart.Position
	local name = saverTextBox.Text

	if name == "" then
		name = generateAutoName()
		saverStatusLabel.Text = "✅ Lokasi '" .. name .. "' tersimpan otomatis."
	else
		saverStatusLabel.Text = "✅ Lokasi '"..name.."' tersimpan."
	end

	locations[name] = pos
	savedLocations[name] = pos

	makeListItem(name, pos)
	updateCanvasSize()
	saveData()

	saverTextBox.Text = ""
	switchTab("location")
end)

-- ==== Print & Copy ====
printButton.MouseButton1Click:Connect(function()
	if next(locations) == nil then
		saverStatusLabel.Text = "⚠️ Tidak ada location mark."
		return
	end

	local result = "local Locations = {\n"
	for name, pos in pairs(locations) do
		result = result .. string.format('    ["%s"] = Vector3.new(%.2f, %.2f, %.2f),\n', name, pos.X, pos.Y, pos.Z)
	end
	result = result .. "}"

	print("Hasil Lokasi:\n"..result)

	if setclipboard then
		setclipboard(result)
		saverStatusLabel.Text = "✅ Location mark dicopy ke clipboard."
	else
		saverStatusLabel.Text = "❌ setclipboard tidak tersedia."
	end
end)

-- ==== Data contoh ====
local contoh = [[
["Rumah"] = Vector3.new(0, 10, 0)
["Toko"] = Vector3.new(100, 5, 200)
["Gunung"] = Vector3.new(-50, 100, 300)
]]
importBox.Text = contoh

-- ==== Render awal ====
renderList()
switchTab("location")
print("✅ Location Mark GUI telah dimuat!")
print("📁 Lokasi penyimpanan: " .. STORAGE_PATH)
