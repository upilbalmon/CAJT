-- Auto Collect Button (Style Loader)
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus GUI lama
local existingGUI = playerGui:FindFirstChild("AutoCollectGUI")
if existingGUI then existingGUI:Destroy() end

-- ============================================
-- FUNGSI GET AUTO COLLECT
-- ============================================
local function getAutoCollect()
    local setting = player:FindFirstChild("Setting")
    if setting then
        return setting:FindFirstChild("isAutoCllect")
    end
    return nil
end

-- ============================================
-- FUNGSI TOGGLE
-- ============================================
local function toggle()
    local ac = getAutoCollect()
    if ac then
        ac.Value = ac.Value == 1 and 0 or 1
        print("🔄 Auto Collect: " .. (ac.Value == 1 and "ON" or "OFF"))
        updateLED()
    else
        print("❌ isAutoCllect tidak ditemukan!")
    end
end

-- ============================================
-- UPDATE LED
-- ============================================
local function updateLED()
    local ac = getAutoCollect()
    if ac then
        local isOn = ac.Value == 1
        led.Text = isOn and "🟢" or "🔴"
        led.TextColor3 = isOn and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
        btn.Text = isOn and "▶ ACTIVE" or "⏸ INACTIVE"
        btn.BackgroundColor3 = isOn and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
    else
        led.Text = "⚪"
        led.TextColor3 = Color3.fromRGB(150, 150, 150)
        btn.Text = "❌ ERROR"
        btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end

-- ============================================
-- KONFIGURASI UI (Style Loader)
-- ============================================
local guiSize = UDim2.new(0, 200, 0, 60)
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

-- ============================================
-- BUAT GUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoCollectGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = guiSize
mainFrame.Position = UDim2.new(1, -210, 0, 50)
mainFrame.BackgroundColor3 = theme.background
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

-- Corner radius
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

-- ============================================
-- TITLE BAR
-- ============================================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = theme.background
titleBar.BackgroundTransparency = 0
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14, 0, 0)
titleCorner.Parent = titleBar

-- Title Label
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.Text = "⚡ Auto Collect"
titleLabel.TextColor3 = theme.textPrimary
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 12
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.BackgroundTransparency = 1
titleLabel.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 18, 0, 18)
closeBtn.Position = UDim2.new(1, -24, 0.5, -9)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 69, 58)
closeBtn.BackgroundTransparency = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = theme.textWhite
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 10
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    print("🔒 Auto Collect GUI ditutup!")
end)

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 70)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 69, 58)
end)

-- ============================================
-- CONTENT
-- ============================================
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -8, 1, -36)
content.Position = UDim2.new(0, 4, 0, 32)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- ============================================
-- TOMBOL UTAMA (Dengan LED)
-- ============================================
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 1, 0)
btn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
btn.BackgroundTransparency = 0
btn.Text = "▶ ACTIVE"
btn.TextColor3 = theme.textWhite
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.AutoButtonColor = false
btn.Parent = content

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = btn

btn.MouseEnter:Connect(function()
    btn.BackgroundTransparency = 0.1
end)
btn.MouseLeave:Connect(function()
    btn.BackgroundTransparency = 0
end)

btn.MouseButton1Click:Connect(function()
    toggle()
end)

-- ============================================
-- LED (di dalam tombol - sebelah kanan)
-- ============================================
local led = Instance.new("TextLabel")
led.Size = UDim2.new(0, 22, 0, 22)
led.Position = UDim2.new(1, -28, 0.5, -11)
led.BackgroundTransparency = 1
led.Text = "🟢"
led.TextColor3 = Color3.fromRGB(0, 255, 100)
led.TextScaled = true
led.Font = Enum.Font.Gotham
led.TextXAlignment = Enum.TextXAlignment.Center
led.Parent = btn

-- ============================================
-- UPDATE AWAL
-- ============================================
updateLED()

-- ============================================
-- DRAGGING (Style Loader)
-- ============================================
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

-- ============================================
-- SHORTCUT KEY (A)
-- ============================================
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.A then
        toggle()
    end
end)

-- ============================================
-- EXPORT
-- ============================================
_G.AutoCollect = {
    start = function()
        local ac = getAutoCollect()
        if ac then ac.Value = 1; updateLED(); print("✅ Auto Collect STARTED!") end
    end,
    stop = function()
        local ac = getAutoCollect()
        if ac then ac.Value = 0; updateLED(); print("❌ Auto Collect STOPPED!") end
    end,
    toggle = toggle,
    getStatus = function()
        local ac = getAutoCollect()
        return ac and ac.Value or -1
    end,
    close = function()
        screenGui:Destroy()
        print("🔒 GUI ditutup!")
    end
}

-- ============================================
-- PRINT INFO
-- ============================================
print("======================================")
print("⚡ AUTO COLLECT CONTROLLER")
print("======================================")

local ac = getAutoCollect()
if ac then
    print("✅ isAutoCllect ditemukan!")
    print("📊 Status: " .. (ac.Value == 1 and "ON" or "OFF"))
else
    print("❌ isAutoCllect tidak ditemukan!")
end

print("\n💡 Klik tombol untuk toggle")
print("⌨️  Tekan 'A' untuk toggle")
print("\n💡 Perintah console:")
print("   _G.AutoCollect.start()  - Start")
print("   _G.AutoCollect.stop()   - Stop")
print("   _G.AutoCollect.toggle() - Toggle")
print("   _G.AutoCollect.close()  - Tutup GUI")
print("======================================")
