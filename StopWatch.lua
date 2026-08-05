-- Stopwatch (GUI Transparan + Kontrol)
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus GUI lama
local oldGui = playerGui:FindFirstChild("Stopwatch")
if oldGui then oldGui:Destroy() end

-- ============================================
-- VARIABEL STOPWATCH
-- ============================================
local running = false
local startTime = 0
local elapsedTime = 0
local lastUpdate = 0

-- ============================================
-- BUAT GUI
-- ============================================
local gui = Instance.new("ScreenGui")
gui.Name = "Stopwatch"
gui.Parent = playerGui
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 130)
frame.Position = UDim2.new(1, -230, 0, 50)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.35
frame.BorderSizePixel = 0
frame.Parent = gui
frame.Draggable = true
frame.Active = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- ============================================
-- TITLE BAR
-- ============================================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 24)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
titleBar.BackgroundTransparency = 0.3
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8, 0, 0)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -45, 1, 0)
titleText.Position = UDim2.new(0, 8, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "⏱ STOPWATCH"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 10
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- ============================================
-- CLOSE BUTTON
-- ============================================
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 18, 0, 18)
closeBtn.Position = UDim2.new(1, -22, 0.5, -9)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BackgroundTransparency = 0.2
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 10
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    print("🔒 Stopwatch ditutup!")
end)

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundTransparency = 0
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundTransparency = 0.2
end)

-- ============================================
-- CONTENT
-- ============================================
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -12, 1, -30)
content.Position = UDim2.new(0, 6, 0, 28)
content.BackgroundTransparency = 1
content.Parent = frame

-- WAKTU (besar)
local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, 0, 0, 45)
timeLabel.Position = UDim2.new(0, 0, 0, 0)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "00:00:00"
timeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
timeLabel.TextScaled = true
timeLabel.Font = Enum.Font.GothamBold
timeLabel.TextXAlignment = Enum.TextXAlignment.Center
timeLabel.Parent = content

-- STATUS (Running/Stopped)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.Position = UDim2.new(0, 0, 0, 48)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⏹ Stopped"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = content

-- ============================================
-- TOMBOL KONTROL
-- ============================================
local btnFrame = Instance.new("Frame")
btnFrame.Size = UDim2.new(1, 0, 0, 30)
btnFrame.Position = UDim2.new(0, 0, 0, 68)
btnFrame.BackgroundTransparency = 1
btnFrame.Parent = content

-- Tombol Start/Pause
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 70, 0, 26)
startBtn.Position = UDim2.new(0.15, -35, 0, 0)
startBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
startBtn.BackgroundTransparency = 0.2
startBtn.BorderSizePixel = 0
startBtn.Text = "▶ Start"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 12
startBtn.AutoButtonColor = false
startBtn.Parent = btnFrame

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 6)
startCorner.Parent = startBtn

startBtn.MouseEnter:Connect(function()
    startBtn.BackgroundTransparency = 0
end)
startBtn.MouseLeave:Connect(function()
    startBtn.BackgroundTransparency = 0.2
end)

-- Tombol Reset
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 60, 0, 26)
resetBtn.Position = UDim2.new(0.7, -30, 0, 0)
resetBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
resetBtn.BackgroundTransparency = 0.2
resetBtn.BorderSizePixel = 0
resetBtn.Text = "↺ Reset"
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 12
resetBtn.AutoButtonColor = false
resetBtn.Parent = btnFrame

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 6)
resetCorner.Parent = resetBtn

resetBtn.MouseEnter:Connect(function()
    resetBtn.BackgroundTransparency = 0
end)
resetBtn.MouseLeave:Connect(function()
    resetBtn.BackgroundTransparency = 0.2
end)

-- ============================================
-- FUNGSI FORMAT WAKTU
-- ============================================
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local millis = math.floor((seconds % 1) * 100)
    
    if hours > 0 then
        return string.format("%02d:%02d:%02d.%02d", hours, minutes, secs, millis)
    else
        return string.format("%02d:%02d.%02d", minutes, secs, millis)
    end
end

-- ============================================
-- UPDATE STOPWATCH
-- ============================================
local function updateStopwatch()
    if running then
        local currentTime = tick()
        elapsedTime = elapsedTime + (currentTime - lastUpdate)
        lastUpdate = currentTime
        
        timeLabel.Text = formatTime(elapsedTime)
    end
end

-- ============================================
-- TOMBOL START/PAUSE
-- ============================================
startBtn.MouseButton1Click:Connect(function()
    if running then
        -- PAUSE
        running = false
        startBtn.Text = "▶ Start"
        startBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        statusLabel.Text = "⏹ Stopped"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        print("⏸ Stopwatch Paused at " .. formatTime(elapsedTime))
    else
        -- START / RESUME
        if elapsedTime == 0 then
            -- Start baru
            startTime = tick()
            lastUpdate = startTime
            print("▶ Stopwatch Started!")
        else
            -- Resume
            lastUpdate = tick()
            print("▶ Stopwatch Resumed!")
        end
        running = true
        startBtn.Text = "⏸ Pause"
        startBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
        statusLabel.Text = "▶ Running"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    end
end)

-- ============================================
-- TOMBOL RESET
-- ============================================
resetBtn.MouseButton1Click:Connect(function()
    running = false
    elapsedTime = 0
    startTime = 0
    lastUpdate = 0
    timeLabel.Text = "00:00:00"
    startBtn.Text = "▶ Start"
    startBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    statusLabel.Text = "⏹ Stopped"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    print("🔄 Stopwatch Reset!")
end)

-- ============================================
-- HEARTBEAT UPDATE (Setiap 0.05 detik)
-- ============================================
game:GetService("RunService").Heartbeat:Connect(function()
    updateStopwatch()
end)

-- ============================================
-- EXPORT
-- ============================================
_G.Stopwatch = {
    start = function()
        if not running then
            if elapsedTime == 0 then
                startTime = tick()
                lastUpdate = startTime
            else
                lastUpdate = tick()
            end
            running = true
            startBtn.Text = "⏸ Pause"
            startBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
            statusLabel.Text = "▶ Running"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            print("▶ Stopwatch Started!")
        end
    end,
    pause = function()
        if running then
            running = false
            startBtn.Text = "▶ Start"
            startBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            statusLabel.Text = "⏹ Stopped"
            statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            print("⏸ Stopwatch Paused at " .. formatTime(elapsedTime))
        end
    end,
    reset = function()
        running = false
        elapsedTime = 0
        startTime = 0
        lastUpdate = 0
        timeLabel.Text = "00:00:00"
        startBtn.Text = "▶ Start"
        startBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        statusLabel.Text = "⏹ Stopped"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        print("🔄 Stopwatch Reset!")
    end,
    getTime = function()
        return elapsedTime
    end,
    getFormattedTime = function()
        return formatTime(elapsedTime)
    end,
    isRunning = function()
        return running
    end,
    close = function()
        gui:Destroy()
        print("🔒 Stopwatch ditutup!")
    end
}

print("======================================")
print("⏱ STOPWATCH AKTIF!")
print("======================================")
print("Tombol: Start/Pause | Reset")
print("\nPerintah console:")
print("  _G.Stopwatch.start()   - Mulai")
print("  _G.Stopwatch.pause()   - Pause")
print("  _G.Stopwatch.reset()   - Reset")
print("  _G.Stopwatch.getTime() - Lihat waktu (detik)")
print("  _G.Stopwatch.close()   - Tutup GUI")
print("======================================")
