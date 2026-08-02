-- GUI Controller untuk membuka UI_Control dari StarterGui
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Membuat ScreenGui utama
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GUIController"
screenGui.Parent = playerGui

-- Frame utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 380, 0, 180)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -90)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
titleLabel.BackgroundTransparency = 0.2
titleLabel.Text = "🚀 UI_Control Opener"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Label Nama GUI
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(0.9, 0, 0, 25)
nameLabel.Position = UDim2.new(0.05, 0, 0, 45)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "📁 Nama GUI:"
nameLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
nameLabel.TextSize = 14
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Font = Enum.Font.Gotham
nameLabel.Parent = mainFrame

-- TextBox
local nameTextBox = Instance.new("TextBox")
nameTextBox.Name = "NameTextBox"
nameTextBox.Size = UDim2.new(0.9, 0, 0, 32)
nameTextBox.Position = UDim2.new(0.05, 0, 0, 70)
nameTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
nameTextBox.BackgroundTransparency = 0.3
nameTextBox.Text = "FusePet"
nameTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameTextBox.TextSize = 14
nameTextBox.Font = Enum.Font.Gotham
nameTextBox.ClearTextOnFocus = false
nameTextBox.PlaceholderText = "Masukkan nama GUI..."
nameTextBox.Parent = mainFrame

local textBoxCorner = Instance.new("UICorner")
textBoxCorner.CornerRadius = UDim.new(0, 6)
textBoxCorner.Parent = nameTextBox

-- Tombol Execute
local executeButton = Instance.new("TextButton")
executeButton.Name = "ExecuteButton"
executeButton.Size = UDim2.new(0.42, 0, 0, 35)
executeButton.Position = UDim2.new(0.05, 0, 0, 115)
executeButton.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
executeButton.Text = "▶ OPEN"
executeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
executeButton.TextSize = 14
executeButton.TextScaled = true
executeButton.Font = Enum.Font.GothamBold
executeButton.Parent = mainFrame

local executeCorner = Instance.new("UICorner")
executeCorner.CornerRadius = UDim.new(0, 6)
executeCorner.Parent = executeButton

-- Tombol Close
local exitButton = Instance.new("TextButton")
exitButton.Name = "ExitButton"
exitButton.Size = UDim2.new(0.42, 0, 0, 35)
exitButton.Position = UDim2.new(0.53, 0, 0, 115)
exitButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
exitButton.Text = "✕ CLOSE"
exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
exitButton.TextSize = 14
exitButton.TextScaled = true
exitButton.Font = Enum.Font.GothamBold
exitButton.Parent = mainFrame

local exitCorner = Instance.new("UICorner")
exitCorner.CornerRadius = UDim.new(0, 6)
exitCorner.Parent = exitButton

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0.9, 0, 0, 30)
statusLabel.Position = UDim2.new(0.05, 0, 0, 155)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "💡 Status: Siap - Default: FusePet"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.Gotham
statusLabel.Parent = mainFrame

-- Fungsi untuk membuka UI_Control
local function openUI()
    local guiName = nameTextBox.Text
    if guiName == "" then
        statusLabel.Text = "⚠️ Status: Nama GUI tidak boleh kosong!"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    statusLabel.Text = "⏳ Status: Mencari " .. guiName .. "..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    -- Script utama dengan path yang sudah dikonfirmasi
    local success, result = pcall(function()
        -- Path: StarterGui → ScreenGui → [NamaGUI] → UI_Control
        local m = require(game:GetService("StarterGui"):WaitForChild("ScreenGui"):WaitForChild(guiName):WaitForChild("UI_Control"))
        if m.openUi then 
            m.openUi() 
            return "✅ UI_Control opened successfully!"
        else
            return "⚠️ UI_Control found but no openUi function!"
        end
    end)
    
    if success then
        statusLabel.Text = result
        statusLabel.TextColor3 = result:match("✅") and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 100)
    else
        statusLabel.Text = "❌ Error: " .. tostring(result)
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- Event tombol Execute
executeButton.MouseButton1Click:Connect(openUI)

-- Hover effects
executeButton.MouseEnter:Connect(function()
    executeButton.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
end)
executeButton.MouseLeave:Connect(function()
    executeButton.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
end)

exitButton.MouseEnter:Connect(function()
    exitButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
end)
exitButton.MouseLeave:Connect(function()
    exitButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

-- Event tombol Close
exitButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Event Enter key
nameTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        openUI()
    end
end)

-- Status awal
statusLabel.Text = "💡 Status: Siap - Default: FusePet"
