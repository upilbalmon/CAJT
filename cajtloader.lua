local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Fungsi untuk menghancurkan GUI lama
local function destroyExistingGUI()
    local existingGUI = playerGui:FindFirstChild("CustomScriptGUI")
    if existingGUI then
        existingGUI:Destroy()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Info",
            Text = "Reloading GUI...",
            Duration = 1.5
        })
        return true
    end
    return false
end

destroyExistingGUI()

-- Daftar URL skrip untuk dijalankan
local scriptURLs = {
    "https://raw.githubusercontent.com/upilbalmon/1/refs/heads/main/loader.lua",
    "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/GUi/GuiLoader.lua",
    "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/infinity.lua",
    "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/cajtv4.lua",
    "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/AutoFarm.lua",
    "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/AutoHatchEgg.lua",
    "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/locationmark.lua"
}

local buttonNames = {
    "Home",
    "GUi",
    "Infinity",
    "Auto Coin Win Token",
    "Auto Farm",
    "Auto Hatch",
    "Teleport to All World"
}

-- Konfigurasi UI Compact iOS Style
local guiSize = UDim2.new(0, 170, 0, 240)
local buttonHeight = 28
local buttonSpacing = 4

-- Tema warna iOS Compact
local theme = {
    background = Color3.fromRGB(242, 242, 247),
    cardBackground = Color3.fromRGB(255, 255, 255),
    primaryBlue = Color3.fromRGB(0, 122, 255),
    primaryRed = Color3.fromRGB(255, 59, 48),
    primaryYellow = Color3.fromRGB(255, 204, 0),
    textPrimary = Color3.fromRGB(0, 0, 0),
    textSecondary = Color3.fromRGB(142, 142, 147),
    textWhite = Color3.fromRGB(255, 255, 255),
    separator = Color3.fromRGB(229, 229, 234),
    buttonNormal = Color3.fromRGB(255, 255, 255),
    buttonHover = Color3.fromRGB(240, 240, 245),
    buttonActive = Color3.fromRGB(0, 122, 255),
}

-- Buat GUI baru
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomScriptGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Container
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = guiSize
mainFrame.Position = UDim2.new(0.5, -85, 0.5, -120)
mainFrame.BackgroundColor3 = theme.background
mainFrame.BackgroundTransparency = 0 -- Pastikan tidak transparan
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

-- Corner radius
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

-- HAPUS shadow effect yang menyebabkan bercak hitam
-- Shadow tidak diperlukan karena sudah ada corner radius yang bagus

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = theme.background
titleBar.BackgroundTransparency = 0 -- Pastikan tidak transparan
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

-- Corner hanya di bagian atas
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 25, 0, 0)
titleLabel.Text = "CAJT Auto"
titleLabel.TextColor3 = theme.textPrimary
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.BackgroundTransparency = 1
titleLabel.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -26, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 69, 58)
closeBtn.BackgroundTransparency = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = theme.textWhite
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 20, 0, 20)
minimizeBtn.Position = UDim2.new(1, -50, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 204, 0)
minimizeBtn.BackgroundTransparency = 0
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = theme.textWhite
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14
minimizeBtn.AutoButtonColor = false
minimizeBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 10)
minCorner.Parent = minimizeBtn

-- Scrolling Frame - PERBAIKAN UTAMA
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -12, 1, -42)
scrollingFrame.Position = UDim2.new(0, 6, 0, 36)
scrollingFrame.BackgroundColor3 = theme.background
scrollingFrame.BackgroundTransparency = 0 -- Set ke 0 agar tidak transparan
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200)
scrollingFrame.ScrollBarThickness = 3
scrollingFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
scrollingFrame.Parent = mainFrame
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Akan diupdate otomatis

-- Layout untuk tombol
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, buttonSpacing)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = scrollingFrame

-- Update CanvasSize saat ada perubahan
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-- Fungsi untuk membuat tombol
local function createButton(name, url)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, buttonHeight) -- Beri sedikit padding
    btn.BackgroundColor3 = theme.cardBackground
    btn.BackgroundTransparency = 0
    btn.Text = name
    btn.TextColor3 = theme.primaryBlue
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = scrollingFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    -- Tambahkan border tipis untuk efek card
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(230, 230, 235)
    border.Thickness = 0.5
    border.Parent = btn
    
    local chevron = Instance.new("TextLabel")
    chevron.Size = UDim2.new(0, 15, 1, 0)
    chevron.Position = UDim2.new(1, -18, 0, 0)
    chevron.Text = "›"
    chevron.TextColor3 = Color3.fromRGB(199, 199, 204)
    chevron.Font = Enum.Font.GothamMedium
    chevron.TextSize = 16
    chevron.BackgroundTransparency = 1
    chevron.Parent = btn
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = theme.buttonHover
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = theme.cardBackground
    end)
    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = theme.buttonActive
        btn.TextColor3 = theme.textWhite
        task.delay(0.15, function()
            btn.BackgroundColor3 = theme.cardBackground
            btn.TextColor3 = theme.primaryBlue
        end)
        pcall(function()
            loadstring(game:HttpGet(url))()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "✅ " .. name,
                Text = "Loaded!",
                Duration = 1.5
            })
        end)
    end)
end

-- Buat semua tombol
for i, url in ipairs(scriptURLs) do
    createButton(buttonNames[i] or "Tombol", url)
end

-- Mini button
local miniButton = Instance.new("TextButton")
miniButton.Name = "MiniButton"
miniButton.Size = UDim2.new(0, 36, 0, 36)
miniButton.Position = UDim2.new(1, -46, 1, -46)
miniButton.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
miniButton.BackgroundTransparency = 0
miniButton.Text = "⚡"
miniButton.TextColor3 = theme.textWhite
miniButton.Font = Enum.Font.GothamBold
miniButton.TextSize = 18
miniButton.AutoButtonColor = false
miniButton.Visible = false
miniButton.Parent = screenGui

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 18)
miniCorner.Parent = miniButton

-- HAPUS shadow pada mini button karena bisa menyebabkan masalah

-- Fungsi minimize
local function minimizeGUI()
    game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(1, 0, 1, 0)
    }):Play()
    task.delay(0.3, function()
        mainFrame.Visible = false
        miniButton.Visible = true
    end)
end

-- Fungsi restore
local function restoreGUI()
    miniButton.Visible = false
    mainFrame.Visible = true
    game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = guiSize,
        Position = UDim2.new(0.5, -85, 0.5, -120)
    }):Play()
end

-- Hubungkan tombol
minimizeBtn.MouseButton1Click:Connect(minimizeGUI)
miniButton.MouseButton1Click:Connect(restoreGUI)
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Hover effects
closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 70)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 69, 58)
end)

minimizeBtn.MouseEnter:Connect(function()
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
end)
minimizeBtn.MouseLeave:Connect(function()
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 204, 0)
end)

miniButton.MouseEnter:Connect(function()
    miniButton.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
end)
miniButton.MouseLeave:Connect(function()
    miniButton.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
end)

-- Dragging
local isDragging = false
local dragStartPos = nil
local frameStartPos = nil
local dragInput = nil

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = input.Position
        frameStartPos = mainFrame.Position
        dragInput = input
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        dragInput = nil
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if isDragging then
        local mousePos = game:GetService("UserInputService"):GetMouseLocation()
        if dragStartPos then
            local delta = mousePos - dragStartPos
            local newX = frameStartPos.X.Offset + delta.X
            local newY = frameStartPos.Y.Offset + delta.Y
            mainFrame.Position = UDim2.new(0, newX, 0, newY)
        end
    end
end)

-- Animasi masuk
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
task.delay(0.1, function()
    game:GetService("TweenService"):Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = guiSize,
        Position = UDim2.new(0.5, -85, 0.5, -120)
    }):Play()
end)
