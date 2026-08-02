-- Script untuk GUI Controller dengan nama GUI yang bisa diedit
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Membuat ScreenGui utama
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GUIController"
screenGui.Parent = playerGui

-- Membuat Frame utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 200)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Corner untuk Frame
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
titleLabel.BackgroundTransparency = 0.3
titleLabel.Text = "GUI Controller"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Label untuk Input Nama GUI
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(0.9, 0, 0, 25)
nameLabel.Position = UDim2.new(0.05, 0, 0, 45)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Nama GUI:"
nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
nameLabel.TextSize = 14
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Font = Enum.Font.Gotham
nameLabel.Parent = mainFrame

-- TextBox untuk mengedit nama GUI
local nameTextBox = Instance.new("TextBox")
nameTextBox.Name = "NameTextBox"
nameTextBox.Size = UDim2.new(0.9, 0, 0, 30)
nameTextBox.Position = UDim2.new(0.05, 0, 0, 70)
nameTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
nameTextBox.BackgroundTransparency = 0.2
nameTextBox.Text = "FusePet"
nameTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameTextBox.TextSize = 14
nameTextBox.Font = Enum.Font.Gotham
nameTextBox.ClearTextOnFocus = false
nameTextBox.PlaceholderText = "Masukkan nama GUI..."
nameTextBox.Parent = mainFrame

-- Corner untuk TextBox
local textBoxCorner = Instance.new("UICorner")
textBoxCorner.CornerRadius = UDim.new(0, 4)
textBoxCorner.Parent = nameTextBox

-- Tombol Execute
local executeButton = Instance.new("TextButton")
executeButton.Name = "ExecuteButton"
executeButton.Size = UDim2.new(0.4, 0, 0, 35)
executeButton.Position = UDim2.new(0.05, 0, 0, 115)
executeButton.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
executeButton.Text = "▶ Execute"
executeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
executeButton.TextSize = 16
executeButton.Font = Enum.Font.GothamBold
executeButton.Parent = mainFrame

-- Corner untuk tombol Execute
local executeCorner = Instance.new("UICorner")
executeCorner.CornerRadius = UDim.new(0, 4)
executeCorner.Parent = executeButton

-- Tombol Close/Exit
local exitButton = Instance.new("TextButton")
exitButton.Name = "ExitButton"
exitButton.Size = UDim2.new(0.4, 0, 0, 35)
exitButton.Position = UDim2.new(0.55, 0, 0, 115)
exitButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
exitButton.Text = "✕ Close"
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.TextSize = 16
exitButton.Font = Enum.Font.GothamBold
exitButton.Parent = mainFrame

-- Corner untuk tombol Close
local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 4)
exitCorner.Parent = exitButton

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0.9, 0, 0, 25)
statusLabel.Position = UDim2.new(0.05, 0, 0, 160)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Siap"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

-- Fungsi untuk menjalankan script utama
local function executeScript()
    local guiName = nameTextBox.Text
    if guiName == "" then
        statusLabel.Text = "Status: Nama GUI tidak boleh kosong!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    statusLabel.Text = "Status: Mencari " .. guiName .. "..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    -- Script utama yang akan dijalankan
    local success, err = pcall(function()
        -- Mencari dan membuka GUI secara otomatis
        local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        local targetGUI = pg:FindFirstChild(guiName)
        
        if targetGUI then
            targetGUI.Visible = true
            targetGUI.Enabled = true
            
            -- Panggil controller jika ada
            local controller = targetGUI:FindFirstChild("UI_Control")
            if controller then
                local controllerModule = require(controller)
                if controllerModule.updateUi then 
                    controllerModule.updateUi() 
                end
                if controllerModule.openUi then 
                    controllerModule.openUi() 
                end
            end
            
            statusLabel.Text = "Status: ✓ " .. guiName .. " berhasil dibuka!"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            statusLabel.Text = "Status: ✗ " .. guiName .. " tidak ditemukan!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
    
    if not success then
        statusLabel.Text = "Status: Error - " .. err
        statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end

-- Event untuk tombol Execute
executeButton.MouseButton1Click:Connect(executeScript)

-- Event untuk tombol Close
exitButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Event untuk Enter key pada TextBox
nameTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        executeScript()
    end
end)

-- Menampilkan status awal
statusLabel.Text = "Status: Siap - Default: FusePet"
