local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Daftar URL skrip untuk dijalankan
local scriptURLs = {
    "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/cajtv4.lua",
    "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/AutoFarm.lua",
    "https://raw.githubusercontent.com/upilbalmon/goblox/refs/heads/main/autohatchx10.lua",
    "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/infinity.lua",
    "https://raw.githubusercontent.com/upilbalmon/Gunung/refs/heads/main/UiGunung.lua",
    "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/locationmark.lua",
    "https://raw.githubusercontent.com/upilbalmon/goblox/refs/heads/main/tele.lua",
    "https://raw.githubusercontent.com/upilbalmon/Gunung/refs/heads/main/speed.lua",
    "https://raw.githubusercontent.com/upilbalmon/Gunung/refs/heads/main/koordinatsaver.lua",
    "https://raw.githubusercontent.com/upilbalmon/Gunung/refs/heads/main/size.lua",
    "https://raw.githubusercontent.com/upilbalmon/Gunung/refs/heads/main/weaterControll.lua",
    "https://raw.githubusercontent.com/upilbalmon/Gunung/refs/heads/main/teleporttoplayer.lua",
    "https://raw.githubusercontent.com/upilbalmon/Fish/refs/heads/main/Loader.lua",
}

local buttonNames = {
    "AutoCWT", 
    "AutoCoinFarm", 
    "Autohatch", 
    "infinity", 
    "GUNUNG", 
    "locations", 
    "TELE", 
    "SPEED", 
    "LOC", 
    "SIZE", 
    "Weater", 
    "TPT", 
    "FISH",
}

-- Konfigurasi UI
local guiSize = UDim2.new(0, 150, 0, 210)
local buttonHeight = 25
local buttonSpacing = 5

-- Tema warna
local theme = {
    background = Color3.fromRGB(40, 40, 50),
    buttonNormal = Color3.fromRGB(60, 60, 70),
    buttonHover = Color3.fromRGB(80, 80, 90),
    buttonActive = Color3.fromRGB(100, 150, 255),
    textColor = Color3.fromRGB(255, 255, 255),
    closeButton = Color3.fromRGB(255, 80, 80),
    closeButtonHover = Color3.fromRGB(255, 120, 120),
    accentColor = Color3.fromRGB(100, 150, 255)
}

-- Buat GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomScriptGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = guiSize
mainFrame.Position = UDim2.new(0.5, -75, 0.5, -105)
mainFrame.BackgroundColor3 = theme.background
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 25)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text = "Menu Skrip"
titleLabel.TextColor3 = theme.textColor
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleLabel.BorderSizePixel = 0
titleLabel.Parent = mainFrame

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -10, 1, -35)
scrollingFrame.Position = UDim2.new(0.5, -70, 0, 30)
scrollingFrame.BackgroundColor3 = theme.background
scrollingFrame.BackgroundTransparency = 0.5
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarImageColor3 = theme.accentColor
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, buttonSpacing)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = scrollingFrame

-- Fungsi untuk membuat tombol
local function createButton(name, url)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, buttonHeight)
    btn.BackgroundColor3 = theme.buttonNormal
    btn.Text = name
    btn.TextColor3 = theme.textColor
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.Parent = scrollingFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = theme.buttonHover
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = theme.buttonNormal
    end)
    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = theme.buttonActive
        task.delay(0.2, function()
            btn.BackgroundColor3 = theme.buttonNormal
        end)
        pcall(function()
            loadstring(game:HttpGet(url))()
        end)
    end)
end

-- Buat semua tombol
for i, url in ipairs(scriptURLs) do
    createButton(buttonNames[i] or "Tombol", url)
end

-- Tombol Minimize/Close
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 20, 0, 20)
minimizeBtn.Position = UDim2.new(1, -25, 0, 5)
minimizeBtn.BackgroundColor3 = theme.closeButton
minimizeBtn.Text = "–"
minimizeBtn.TextColor3 = theme.textColor
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = mainFrame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minimizeBtn

-- Tombol mini (saat diminimalkan)
local miniButton = Instance.new("TextButton")
miniButton.Size = UDim2.new(0, 30, 0, 30)
miniButton.Position = UDim2.new(1, -40, 1, -40)
miniButton.BackgroundColor3 = theme.accentColor
miniButton.Text = "▲"
miniButton.TextColor3 = theme.textColor
miniButton.Font = Enum.Font.GothamBold
miniButton.TextSize = 20
miniButton.AutoButtonColor = false
miniButton.Visible = false
miniButton.Parent = screenGui

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 15)
miniCorner.Parent = miniButton

-- Fungsi untuk meminimalkan GUI
local function minimizeGUI()
    game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(1, 0, 1, 0)}):Play()
    task.delay(0.3, function()
        mainFrame.Visible = false
        miniButton.Visible = true
    end)
end

-- Fungsi untuk mengembalikan GUI
local function restoreGUI()
    miniButton.Visible = false
    mainFrame.Visible = true
    game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = guiSize, Position = UDim2.new(0.5, -75, 0.5, -105)}):Play()
end

-- Hubungkan tombol dengan fungsinya
minimizeBtn.MouseButton1Click:Connect(minimizeGUI)
miniButton.MouseButton1Click:Connect(restoreGUI)

-- Jadikan frame dapat diseret
local isDragging = false
local dragStartPos = nil
local frameStartPos = nil

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = true
        dragStartPos = input.Position
        frameStartPos = mainFrame.Position
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if isDragging then
        local delta = game:GetService("UserInputService"):GetMouseLocation() - dragStartPos
        local newX = frameStartPos.X.Offset + delta.X
        local newY = frameStartPos.Y.Offset + delta.Y
        mainFrame.Position = UDim2.new(0, newX, 0, newY)
    end
end)
