--// TEST BATAS MAKSIMUM DRAW HERO (DEFAULT BARU)
--// Copy paste script ini di executor Anda

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

--// Cari Event DrawHero
local function GetDrawHeroEvent()
    local success, event = pcall(function()
        return ReplicatedStorage:WaitForChild("Tool"):WaitForChild("DrawUp"):WaitForChild("Msg"):WaitForChild("DrawHero")
    end)
    if success and event then
        return event
    end
    return nil
end

local DrawHeroEvent = GetDrawHeroEvent()

if not DrawHeroEvent then
    print("❌ Event DrawHero tidak ditemukan!")
    return
end

--// Buat GUI (Ukuran 220x300)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TestMaxGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 300)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 4)
corner.Parent = mainFrame

-- ============================================
-- TITLE BAR (HEADER: INFINITY)
-- ============================================
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 26)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
titleBar.BackgroundTransparency = 0.3
titleBar.Parent = mainFrame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 4)
titleBarCorner.Parent = titleBar

-- DRAG MANUAL
local dragData = {dragging = false, startPos = nil, startMouse = nil}

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragData.dragging = true
        dragData.startPos = mainFrame.Position
        dragData.startMouse = input.Position
        if dropdownOpen then
            dropdownContainer.Visible = false
            dropdownOpen = false
        end
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragData.dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragData.dragging then
        local delta = input.Position - dragData.startMouse
        local newPos = UDim2.new(
            dragData.startPos.X.Scale, dragData.startPos.X.Offset + delta.X,
            dragData.startPos.Y.Scale, dragData.startPos.Y.Offset + delta.Y
        )
        mainFrame.Position = newPos
        if dropdownOpen then
            UpdateDropdownPosition()
        end
    end
end)

-- Title (HEADER: INFINITY) (FONT 14)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 4, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 200, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.Text = "♾️ INFINITY"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Min Button
local minButton = Instance.new("TextButton")
minButton.Size = UDim2.new(0, 18, 0, 16)
minButton.Position = UDim2.new(1, -38, 0, 5)
minButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
minButton.TextColor3 = Color3.fromRGB(220, 220, 220)
minButton.Font = Enum.Font.SourceSans
minButton.TextSize = 12
minButton.Text = "−"
minButton.BorderSizePixel = 0
minButton.ZIndex = 10
minButton.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 2)
minCorner.Parent = minButton

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 18, 0, 16)
closeButton.Position = UDim2.new(1, -18, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.SourceSans
closeButton.TextSize = 12
closeButton.Text = "✕"
closeButton.BorderSizePixel = 0
closeButton.ZIndex = 10
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 2)
closeCorner.Parent = closeButton

-- Status Label (FONT 14)
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -8, 0, 20)
statusLabel.Position = UDim2.new(0, 4, 0, 28)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
statusLabel.BackgroundTransparency = 0.3
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 14
statusLabel.Text = "Status: Siap..."
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 2)
statusCorner.Parent = statusLabel

-- ============================================
-- KONTROL
-- ============================================
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(1, -8, 0, 115)
controlFrame.Position = UDim2.new(0, 4, 0, 50)
controlFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
controlFrame.BackgroundTransparency = 0.3
controlFrame.BorderSizePixel = 0
controlFrame.ClipsDescendants = false
controlFrame.Parent = mainFrame

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 3)
controlCorner.Parent = controlFrame

-- BARIS 1
-- Delay (FONT 14) - DEFAULT 5
local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(0.18, 0, 0, 18)
delayLabel.Position = UDim2.new(0.02, 0, 0, 2)
delayLabel.BackgroundTransparency = 1
delayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
delayLabel.Font = Enum.Font.SourceSans
delayLabel.TextSize = 14
delayLabel.Text = "Dly:"
delayLabel.TextXAlignment = Enum.TextXAlignment.Right
delayLabel.Parent = controlFrame

local delayBox = Instance.new("TextBox")
delayBox.Size = UDim2.new(0.18, 0, 0, 22)
delayBox.Position = UDim2.new(0.22, 0, 0, 0)
delayBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
delayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
delayBox.Font = Enum.Font.SourceSans
delayBox.TextSize = 14
delayBox.Text = "5"
delayBox.ClearTextOnFocus = false
delayBox.Parent = controlFrame

local delayBoxCorner = Instance.new("UICorner")
delayBoxCorner.CornerRadius = UDim.new(0, 2)
delayBoxCorner.Parent = delayBox

-- ID (RATA KANAN) (FONT 14) - DEFAULT 7000001
local idLabel = Instance.new("TextLabel")
idLabel.Size = UDim2.new(0.12, 0, 0, 18)
idLabel.Position = UDim2.new(0.44, 0, 0, 2)
idLabel.BackgroundTransparency = 1
idLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
idLabel.Font = Enum.Font.SourceSans
idLabel.TextSize = 14
idLabel.Text = "ID:"
idLabel.TextXAlignment = Enum.TextXAlignment.Right
idLabel.Parent = controlFrame

local idBox = Instance.new("TextBox")
idBox.Size = UDim2.new(0.22, 0, 0, 22)
idBox.Position = UDim2.new(0.57, 0, 0, 0)
idBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
idBox.TextColor3 = Color3.fromRGB(255, 255, 255)
idBox.Font = Enum.Font.SourceSans
idBox.TextSize = 14
idBox.Text = "7000001"
idBox.ClearTextOnFocus = false
idBox.Parent = controlFrame

local idBoxCorner = Instance.new("UICorner")
idBoxCorner.CornerRadius = UDim.new(0, 2)
idBoxCorner.Parent = idBox

-- BARIS 2
-- Jumlah Test (FONT 14)
local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(0.18, 0, 0, 18)
countLabel.Position = UDim2.new(0.02, 0, 0, 28)
countLabel.BackgroundTransparency = 1
countLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
countLabel.Font = Enum.Font.SourceSans
countLabel.TextSize = 14
countLabel.Text = "Jml:"
countLabel.TextXAlignment = Enum.TextXAlignment.Right
countLabel.Parent = controlFrame

local countBox = Instance.new("TextBox")
countBox.Size = UDim2.new(0.18, 0, 0, 22)
countBox.Position = UDim2.new(0.22, 0, 0, 26)
countBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
countBox.TextColor3 = Color3.fromRGB(255, 255, 255)
countBox.Font = Enum.Font.SourceSans
countBox.TextSize = 14
countBox.Text = "15"
countBox.ClearTextOnFocus = false
countBox.Parent = controlFrame

local countBoxCorner = Instance.new("UICorner")
countBoxCorner.CornerRadius = UDim.new(0, 2)
countBoxCorner.Parent = countBox

-- Mulai Dari (RATA KANAN) (FONT 14)
local startLabel = Instance.new("TextLabel")
startLabel.Size = UDim2.new(0.12, 0, 0, 18)
startLabel.Position = UDim2.new(0.44, 0, 0, 28)
startLabel.BackgroundTransparency = 1
startLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
startLabel.Font = Enum.Font.SourceSans
startLabel.TextSize = 14
startLabel.Text = "Mul:"
startLabel.TextXAlignment = Enum.TextXAlignment.Right
startLabel.Parent = controlFrame

local startBox = Instance.new("TextBox")
startBox.Size = UDim2.new(0.22, 0, 0, 22)
startBox.Position = UDim2.new(0.57, 0, 0, 26)
startBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
startBox.TextColor3 = Color3.fromRGB(255, 255, 255)
startBox.Font = Enum.Font.SourceSans
startBox.TextSize = 14
startBox.Text = "10"
startBox.ClearTextOnFocus = false
startBox.Parent = controlFrame

local startBoxCorner = Instance.new("UICorner")
startBoxCorner.CornerRadius = UDim.new(0, 2)
startBoxCorner.Parent = startBox

-- BARIS 3: STEP DROPDOWN (FONT 14)
local stepLabel = Instance.new("TextLabel")
stepLabel.Size = UDim2.new(0.18, 0, 0, 18)
stepLabel.Position = UDim2.new(0.02, 0, 0, 54)
stepLabel.BackgroundTransparency = 1
stepLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
stepLabel.Font = Enum.Font.SourceSans
stepLabel.TextSize = 14
stepLabel.Text = "Step:"
stepLabel.TextXAlignment = Enum.TextXAlignment.Right
stepLabel.Parent = controlFrame

-- Tombol Dropdown (FONT 14)
local stepButton = Instance.new("TextButton")
stepButton.Size = UDim2.new(0.18, 0, 0, 22)
stepButton.Position = UDim2.new(0.22, 0, 0, 52)
stepButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
stepButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stepButton.Font = Enum.Font.SourceSans
stepButton.TextSize = 14
stepButton.Text = "3"
stepButton.BorderSizePixel = 0
stepButton.ZIndex = 100
stepButton.Parent = controlFrame

local stepButtonCorner = Instance.new("UICorner")
stepButtonCorner.CornerRadius = UDim.new(0, 2)
stepButtonCorner.Parent = stepButton

-- Limit Label (FONT 14)
local limitLabel = Instance.new("TextLabel")
limitLabel.Size = UDim2.new(0.2, 0, 0, 18)
limitLabel.Position = UDim2.new(0.44, 0, 0, 54)
limitLabel.BackgroundTransparency = 1
limitLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
limitLabel.Font = Enum.Font.SourceSansBold
limitLabel.TextSize = 14
limitLabel.Text = "MAX 300!"
limitLabel.TextXAlignment = Enum.TextXAlignment.Left
limitLabel.Parent = controlFrame

-- BARIS 4: Info kecil (FONT 12)
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(0.8, 0, 0, 16)
infoLabel.Position = UDim2.new(0.02, 0, 0, 80)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
infoLabel.Font = Enum.Font.SourceSans
infoLabel.TextSize = 12
infoLabel.Text = "OFF = loop terus | max 300 auto-cancel"
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.Parent = controlFrame

-- ============================================
-- DROPDOWN CONTAINER (DENGAN OPSI OFF)
-- ============================================
local dropdownContainer = Instance.new("Frame")
dropdownContainer.Size = UDim2.new(0, 50, 0, 120)
dropdownContainer.Position = UDim2.new(0, 0, 0, 0)
dropdownContainer.BackgroundTransparency = 1
dropdownContainer.ZIndex = 9999
dropdownContainer.Visible = false
dropdownContainer.Parent = screenGui

local dropdownList = Instance.new("Frame")
dropdownList.Size = UDim2.new(1, 0, 1, 0)
dropdownList.Position = UDim2.new(0, 0, 0, 0)
dropdownList.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
dropdownList.BackgroundTransparency = 0.1
dropdownList.BorderSizePixel = 1
dropdownList.BorderColor3 = Color3.fromRGB(80, 80, 90)
dropdownList.ZIndex = 9999
dropdownList.ClipsDescendants = true
dropdownList.Parent = dropdownContainer

local dropdownCorner = Instance.new("UICorner")
dropdownCorner.CornerRadius = UDim.new(0, 3)
dropdownCorner.Parent = dropdownList

local dropdownScroll = Instance.new("ScrollingFrame")
dropdownScroll.Size = UDim2.new(1, 0, 1, 0)
dropdownScroll.Position = UDim2.new(0, 0, 0, 0)
dropdownScroll.BackgroundTransparency = 1
dropdownScroll.BorderSizePixel = 0
dropdownScroll.ZIndex = 9999
dropdownScroll.Parent = dropdownList

local dropdownContent = Instance.new("Frame")
dropdownContent.Size = UDim2.new(1, 0, 0, 120)
dropdownContent.BackgroundTransparency = 1
dropdownContent.Parent = dropdownScroll
dropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 120)

-- Step options (TAMBAH OPSI "OFF")
local stepOptions = {"OFF", 1, 2, 3, 6, 9, 12, 15}
local stepButtons = {}
local currentStep = "3"
local isClickingStep = false

for i, step in ipairs(stepOptions) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 15)
    btn.Position = UDim2.new(0, 0, 0, (i-1) * 15)
    btn.Text = tostring(step)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.ZIndex = 10000
    btn.Parent = dropdownContent
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 2)
    btnCorner.Parent = btn
    
    stepButtons[step] = btn
end

-- Highlight default
for s, btn in pairs(stepButtons) do
    if s == currentStep then
        btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        btn.BackgroundTransparency = 0.3
    end
end

-- ============================================
-- SCROLLING FRAME UNTUK HASIL
-- ============================================
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -8, 0, 72)
scrollFrame.Position = UDim2.new(0, 4, 0, 169)
scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
scrollFrame.BackgroundTransparency = 0.3
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = mainFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 3)
scrollCorner.Parent = scrollFrame

local resultList = Instance.new("Frame")
resultList.Size = UDim2.new(1, 0, 0, 0)
resultList.BackgroundTransparency = 1
resultList.Parent = scrollFrame
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

-- ============================================
-- PROGRESS BAR (FONT 14)
-- ============================================
local progressFrame = Instance.new("Frame")
progressFrame.Size = UDim2.new(1, -8, 0, 14)
progressFrame.Position = UDim2.new(0, 4, 0, 244)
progressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
progressFrame.BackgroundTransparency = 0.3
progressFrame.BorderSizePixel = 0
progressFrame.Parent = mainFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 2)
progressCorner.Parent = progressFrame

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
progressBar.BackgroundTransparency = 0.5
progressBar.BorderSizePixel = 0
progressBar.Parent = progressFrame

local progressCorner2 = Instance.new("UICorner")
progressCorner2.CornerRadius = UDim.new(0, 2)
progressCorner2.Parent = progressBar

local progressText = Instance.new("TextLabel")
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.Font = Enum.Font.SourceSansBold
progressText.TextSize = 14
progressText.Text = "0%"
progressText.Parent = progressFrame

-- ============================================
-- TOMBOL (FONT 16) - TEXT "START"
-- ============================================
local buttonFrame = Instance.new("Frame")
buttonFrame.Size = UDim2.new(1, -8, 0, 26)
buttonFrame.Position = UDim2.new(0, 4, 0, 260)
buttonFrame.BackgroundTransparency = 1
buttonFrame.Parent = mainFrame

local testButton = Instance.new("TextButton")
testButton.Size = UDim2.new(0.32, -2, 1, 0)
testButton.Position = UDim2.new(0, 0, 0, 0)
testButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
testButton.TextColor3 = Color3.fromRGB(255, 255, 255)
testButton.Font = Enum.Font.SourceSansBold
testButton.TextSize = 16
testButton.Text = "▶ START"
testButton.Parent = buttonFrame

local testCorner = Instance.new("UICorner")
testCorner.CornerRadius = UDim.new(0, 3)
testCorner.Parent = testButton

local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(0.32, -2, 1, 0)
stopButton.Position = UDim2.new(0.34, 0, 0, 0)
stopButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.Font = Enum.Font.SourceSansBold
stopButton.TextSize = 16
stopButton.Text = "⏹ STOP"
stopButton.Visible = false
stopButton.Parent = buttonFrame

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 3)
stopCorner.Parent = stopButton

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0.32, -2, 1, 0)
resetButton.Position = UDim2.new(0.68, 0, 0, 0)
resetButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.Font = Enum.Font.SourceSansBold
resetButton.TextSize = 16
resetButton.Text = "✕ CLR"
resetButton.Parent = buttonFrame

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 3)
resetCorner.Parent = resetButton

-- ============================================
-- MINI BUTTON (FONT 16)
-- ============================================
local miniButton = Instance.new("TextButton")
miniButton.Size = UDim2.new(0, 32, 0, 32)
miniButton.Position = UDim2.new(1, -36, 1, -36)
miniButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
miniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
miniButton.Font = Enum.Font.SourceSans
miniButton.TextSize = 16
miniButton.Text = "♾️"
miniButton.Visible = false
miniButton.Parent = screenGui

local miniCorner = Instance.new("UICorner")
miniCorner.CornerRadius = UDim.new(0, 16)
miniCorner.Parent = miniButton

-- ============================================
-- VARIABEL
-- ============================================
local testRunning = false
local testStopped = false
local heroId = 7000001
local resultCount = 0
local totalTests = 0
local isMinimized = false
local dropdownOpen = false
local isClickingStep = false
local MAX_EXPONENT = 300
local isOffMode = false
local loopCount = 0

-- ============================================
-- FUNGSI
-- ============================================

-- Fungsi untuk menambah hasil (FONT 14)
local function AddResult(text, color)
    resultCount = resultCount + 1
    
    local resultLabel = Instance.new("TextLabel")
    resultLabel.Size = UDim2.new(1, -4, 0, 18)
    resultLabel.Position = UDim2.new(0, 2, 0, (resultCount - 1) * 19)
    resultLabel.BackgroundTransparency = 1
    resultLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    resultLabel.Font = Enum.Font.SourceSans
    resultLabel.TextSize = 14
    resultLabel.Text = text
    resultLabel.TextXAlignment = Enum.TextXAlignment.Left
    resultLabel.Parent = resultList
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, resultCount * 19 + 6)
    scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
end

-- Fungsi untuk update progress
local function UpdateProgress(current, total)
    local percent
    if total > 0 then
        percent = math.floor((current / total) * 100)
    else
        percent = 0
    end
    progressBar.Size = UDim2.new(percent / 100, 0, 1, 0)
    progressText.Text = percent .. "%"
    
    if percent < 30 then
        progressBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    elseif percent < 70 then
        progressBar.BackgroundColor3 = Color3.fromRGB(200, 200, 50)
    else
        progressBar.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    end
end

-- Fungsi untuk test nilai (DENGAN LIMIT 300)
local function TestValue(value, label)
    local exponent = math.floor(math.log10(value))
    
    if exponent > MAX_EXPONENT then
        AddResult("⚠️ MELEWATI BATAS 300!", Color3.fromRGB(255, 200, 0))
        return false, "limit_exceeded"
    end
    
    local success, result = pcall(function()
        return DrawHeroEvent:InvokeServer(heroId, -value)
    end)
    
    local statusText = ""
    local color = Color3.fromRGB(200, 200, 200)
    
    if success then
        statusText = "✅"
        color = Color3.fromRGB(0, 255, 0)
    else
        statusText = "❌"
        color = Color3.fromRGB(255, 0, 0)
    end
    
    local displayText = string.format("%s e+%d", statusText, exponent)
    AddResult(displayText, color)
    
    return success, nil
end

-- Fungsi test utama (DENGAN MODE OFF = LOOP)
local function RunTest()
    if testRunning then return end
    
    local delay = tonumber(delayBox.Text) or 5
    if delay < 0.1 then delay = 5 delayBox.Text = "5" end
    
    local startExp = tonumber(startBox.Text) or 10
    if startExp < 1 then startExp = 10 startBox.Text = "10" end
    if startExp > MAX_EXPONENT then 
        startExp = MAX_EXPONENT - 10
        startBox.Text = tostring(startExp)
    end
    
    local testCount = tonumber(countBox.Text) or 15
    if testCount < 1 then testCount = 15 countBox.Text = "15" end
    if testCount > 30 then testCount = 30 countBox.Text = "30" end
    
    local step = tonumber(stepButton.Text) or 3
    isOffMode = (stepButton.Text == "OFF")
    
    heroId = tonumber(idBox.Text) or 7000001
    idBox.Text = tostring(heroId)
    
    testRunning = true
    testStopped = false
    loopCount = 0
    
    testButton.Visible = false
    stopButton.Visible = true
    statusLabel.Text = "⏳ Running..."
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    
    AddResult("===== MULAI =====", Color3.fromRGB(100, 200, 255))
    AddResult(string.format("ID:%d | Dly:%.1fs", heroId, delay), Color3.fromRGB(200, 200, 200))
    
    if isOffMode then
        AddResult("♾️ MODE OFF: LOOP TANPA HENTI", Color3.fromRGB(255, 200, 0))
        AddResult("📌 Tekan STOP untuk berhenti", Color3.fromRGB(255, 200, 0))
        AddResult("", Color3.fromRGB(200, 200, 200))
        totalTests = 0
        progressText.Text = "∞"
        progressBar.Size = UDim2.new(1, 0, 1, 0)
        progressBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        
        -- LOOP TANPA HENTI
        while testRunning and not testStopped do
            loopCount = loopCount + 1
            
            local exp = startExp
            local value = 10 ^ exp
            
            -- Cek limit 300
            if exp > MAX_EXPONENT then
                AddResult("⚠️ MELEWATI BATAS 300!", Color3.fromRGB(255, 200, 0))
                AddResult("⏹️ TEST DICANCEL OTOMATIS", Color3.fromRGB(255, 100, 0))
                break
            end
            
            local success, limitFlag = pcall(function()
                return DrawHeroEvent:InvokeServer(heroId, -value)
            end)
            
            local statusText = ""
            local color = Color3.fromRGB(200, 200, 200)
            
            if success then
                statusText = "✅"
                color = Color3.fromRGB(0, 255, 0)
            else
                statusText = "❌"
                color = Color3.fromRGB(255, 0, 0)
                AddResult(string.format("%s [%d] e+%d", statusText, loopCount, exp), color)
                AddResult("⏹️ GAGAL! STOP OTOMATIS", Color3.fromRGB(255, 100, 0))
                break
            end
            
            -- Tampilkan setiap 5 loop atau jika gagal
            if loopCount % 5 == 0 or not success then
                AddResult(string.format("%s [%d] e+%d", statusText, loopCount, exp), color)
            end
            
            statusLabel.Text = string.format("♾️ Loop #%d | e+%d", loopCount, exp)
            
            task.wait(delay)
        end
        
        if testStopped then
            AddResult("", Color3.fromRGB(200, 200, 200))
            AddResult("⏹️ DIHENTIKAN USER - Loop #" .. loopCount, Color3.fromRGB(255, 200, 0))
            statusLabel.Text = "⏹️ Stopped - " .. loopCount .. " loops"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        else
            AddResult("", Color3.fromRGB(200, 200, 200))
            AddResult("⏹️ BERHENTI - Loop #" .. loopCount, Color3.fromRGB(255, 200, 0))
            statusLabel.Text = "⏹️ Berhenti - " .. loopCount .. " loops"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
        
    else
        -- MODE STEP NORMAL
        -- Cek batas 300
        local maxPossibleExp = startExp + ((testCount - 1) * step)
        if maxPossibleExp > MAX_EXPONENT then
            local maxAllowed = math.floor((MAX_EXPONENT - startExp) / step) + 1
            if maxAllowed < 1 then
                AddResult("❌ Mulai terlalu tinggi!", Color3.fromRGB(255, 0, 0))
                AddResult("📊 Mulai max: " .. (MAX_EXPONENT - step), Color3.fromRGB(255, 200, 0))
                testRunning = false
                testButton.Visible = true
                stopButton.Visible = false
                return
            end
            testCount = maxAllowed
            countBox.Text = tostring(testCount)
            AddResult("⚠️ Disesuaikan ke " .. testCount .. " test (max 300)", Color3.fromRGB(255, 200, 0))
        end
        
        totalTests = testCount
        AddResult(string.format("📊 1e+%d x%d | Step:%d", startExp, testCount, step), Color3.fromRGB(200, 200, 200))
        
        -- Generate nilai test
        local testValues = {}
        for i = 0, testCount - 1 do
            local exp = startExp + (i * step)
            if exp > MAX_EXPONENT then break end
            table.insert(testValues, {
                value = 10 ^ exp,
                label = string.format("e+%d", exp)
            })
        end
        
        local lastSuccess = 0
        local firstFail = nil
        local currentTest = 0
        local stoppedByLimit = false
        
        for _, test in ipairs(testValues) do
            if testStopped then
                AddResult("⏹️ DIHENTIKAN", Color3.fromRGB(255, 200, 0))
                break
            end
            
            currentTest = currentTest + 1
            UpdateProgress(currentTest, totalTests)
            
            local success, limitFlag = TestValue(test.value, test.label)
            
            if limitFlag == "limit_exceeded" then
                stoppedByLimit = true
                break
            end
            
            if success then
                lastSuccess = test.value
            else
                if not firstFail then
                    firstFail = test.value
                end
            end
            
            task.wait(delay)
        end
        
        AddResult("===== HASIL =====", Color3.fromRGB(100, 200, 255))
        
        if stoppedByLimit then
            AddResult("⛔ TEST DICANCEL (BATAS 300)", Color3.fromRGB(255, 100, 0))
            statusLabel.Text = "⛔ Dicancel (Batas 300)"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 0)
        elseif firstFail then
            local maxExp = math.floor(math.log10(lastSuccess))
            local failExp = math.floor(math.log10(firstFail))
            AddResult(string.format("✅ Max: 1e+%d", maxExp), Color3.fromRGB(0, 255, 0))
            AddResult(string.format("❌ Fail: 1e+%d", failExp), Color3.fromRGB(255, 0, 0))
            local safeMin = math.max(1, maxExp - (step * 2))
            AddResult(string.format("📊 Aman: 1e+%d-1e+%d", safeMin, maxExp), Color3.fromRGB(255, 200, 0))
            statusLabel.Text = string.format("✅ Selesai! Aman: 1e+%d", maxExp)
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            if not testStopped then
                AddResult("✅ SEMUA BERHASIL!", Color3.fromRGB(0, 255, 0))
                statusLabel.Text = "✅ Semua berhasil!"
                statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            end
        end
        UpdateProgress(totalTests, totalTests)
    end
    
    testRunning = false
    testButton.Visible = true
    stopButton.Visible = false
    testButton.Text = "▶ START"
    testButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
    if not isOffMode then
        UpdateProgress(totalTests, totalTests)
    end
end

-- Fungsi Stop
local function StopTest()
    if testRunning then
        testStopped = true
        statusLabel.Text = "⏹️ Menghentikan..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end

-- Fungsi Reset
local function ResetResults()
    if testRunning then return end
    for _, child in pairs(resultList:GetChildren()) do child:Destroy() end
    resultCount = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressText.Text = "0%"
    statusLabel.Text = "Status: Siap..."
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    AddResult("✅ Hasil dibersihkan", Color3.fromRGB(255, 200, 0))
end

-- Fungsi Close
local function CloseGUI()
    if testRunning then
        testRunning = false
        testStopped = true
    end
    screenGui:Destroy()
end

-- Fungsi Minimize
local function MinimizeGUI()
    isMinimized = true
    mainFrame.Visible = false
    miniButton.Visible = true
    dropdownContainer.Visible = false
    dropdownOpen = false
end

local function RestoreGUI()
    isMinimized = false
    miniButton.Visible = false
    mainFrame.Visible = true
end

-- ============================================
-- FUNGSI DROPDOWN
-- ============================================
local function UpdateDropdownPosition()
    local stepPos = stepButton.AbsolutePosition
    local stepSize = stepButton.AbsoluteSize
    
    dropdownContainer.Position = UDim2.new(0, stepPos.X, 0, stepPos.Y + stepSize.Y + 1)
    dropdownContainer.Size = UDim2.new(0, 50, 0, 120)
end

local function ToggleDropdown()
    if dropdownOpen then
        dropdownContainer.Visible = false
        dropdownOpen = false
        return
    end
    
    UpdateDropdownPosition()
    dropdownContainer.Visible = true
    dropdownOpen = true
end

local function CloseDropdown()
    if dropdownOpen then
        dropdownContainer.Visible = false
        dropdownOpen = false
    end
end

-- ============================================
-- EVENT TOMBOL UTAMA
-- ============================================
testButton.MouseButton1Click:Connect(RunTest)
stopButton.MouseButton1Click:Connect(StopTest)
resetButton.MouseButton1Click:Connect(ResetResults)
minButton.MouseButton1Click:Connect(MinimizeGUI)
miniButton.MouseButton1Click:Connect(RestoreGUI)
closeButton.MouseButton1Click:Connect(CloseGUI)
stepButton.MouseButton1Click:Connect(ToggleDropdown)

-- ============================================
-- EVENT TOMBOL STEP (DENGAN OPSI OFF)
-- ============================================
for step, btn in pairs(stepButtons) do
    btn.MouseButton1Down:Connect(function()
        isClickingStep = true
        
        currentStep = step
        stepButton.Text = tostring(step)
        
        -- Jika OFF, ubah label menjadi "OFF"
        if step == "OFF" then
            stepButton.Text = "OFF"
        end
        
        for s, b in pairs(stepButtons) do
            b.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            b.BackgroundTransparency = 0.3
        end
        btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        btn.BackgroundTransparency = 0.3
        
        CloseDropdown()
        
        task.wait(0.05)
        isClickingStep = false
    end)
    
    btn.MouseEnter:Connect(function()
        if btn.Text ~= currentStep then
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            btn.BackgroundTransparency = 0.2
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if btn.Text ~= currentStep then
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.BackgroundTransparency = 0.3
        end
    end)
end

-- ============================================
-- SISTEM TUTUP DROPDOWN
-- ============================================
scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    CloseDropdown()
end)

mainFrame:GetPropertyChangedSignal("Position"):Connect(function()
    if dropdownOpen then
        UpdateDropdownPosition()
    end
end)

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isClickingStep then return end
        if not dropdownOpen then return end
        
        task.wait(0.05)
        
        local mousePos = game:GetService("UserInputService"):GetMouseLocation()
        
        local dropPos = dropdownList.AbsolutePosition
        local dropSize = dropdownList.AbsoluteSize
        
        local inDropdown = (mousePos.X >= dropPos.X and mousePos.X <= dropPos.X + dropSize.X and
                           mousePos.Y >= dropPos.Y and mousePos.Y <= dropPos.Y + dropSize.Y)
        
        local stepPos = stepButton.AbsolutePosition
        local stepSize = stepButton.AbsoluteSize
        local inStep = (mousePos.X >= stepPos.X and mousePos.X <= stepPos.X + stepSize.X and
                       mousePos.Y >= stepPos.Y and mousePos.Y <= stepPos.Y + stepSize.Y)
        
        local inStepButton = false
        for _, btn in pairs(stepButtons) do
            local btnPos = btn.AbsolutePosition
            local btnSize = btn.AbsoluteSize
            if mousePos.X >= btnPos.X and mousePos.X <= btnPos.X + btnSize.X and
               mousePos.Y >= btnPos.Y and mousePos.Y <= btnPos.Y + btnSize.Y then
                inStepButton = true
                break
            end
        end
        
        if not inDropdown and not inStep and not inStepButton then
            CloseDropdown()
        end
    end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    if dropdownOpen then
        UpdateDropdownPosition()
    end
end)

-- Hover effects
testButton.MouseEnter:Connect(function()
    if not testRunning then testButton.BackgroundColor3 = Color3.fromRGB(60, 200, 60) end
end)
testButton.MouseLeave:Connect(function()
    if not testRunning then testButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40) end
end)

stopButton.MouseEnter:Connect(function()
    stopButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
end)
stopButton.MouseLeave:Connect(function()
    stopButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
end)

resetButton.MouseEnter:Connect(function()
    resetButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
end)
resetButton.MouseLeave:Connect(function()
    resetButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

closeButton.MouseEnter:Connect(function()
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
end)
closeButton.MouseLeave:Connect(function()
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
end)

minButton.MouseEnter:Connect(function()
    minButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
end)
minButton.MouseLeave:Connect(function()
    minButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
end)

miniButton.MouseEnter:Connect(function()
    miniButton.BackgroundColor3 = Color3.fromRGB(60, 220, 60)
end)
miniButton.MouseLeave:Connect(function()
    miniButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
end)

stepButton.MouseEnter:Connect(function()
    stepButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
end)
stepButton.MouseLeave:Connect(function()
    stepButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
end)

-- Validasi input
delayBox.FocusLost:Connect(function()
    local val = tonumber(delayBox.Text)
    if not val or val < 0.1 then delayBox.Text = "5" end
end)

startBox.FocusLost:Connect(function()
    local val = tonumber(startBox.Text)
    if not val or val < 1 then startBox.Text = "10" end
    if val > MAX_EXPONENT then 
        startBox.Text = tostring(MAX_EXPONENT - 10)
    end
end)

countBox.FocusLost:Connect(function()
    local val = tonumber(countBox.Text)
    if not val or val < 1 then countBox.Text = "15" end
    if val > 30 then countBox.Text = "30" end
end)

-- ============================================
-- INISIALISASI
-- ============================================
AddResult("✅ Script siap!", Color3.fromRGB(0, 255, 0))
AddResult("♾️ INFINITY - Klik START untuk mulai", Color3.fromRGB(255, 200, 0))
AddResult("📊 Step: " .. currentStep .. " | Max: 300", Color3.fromRGB(150, 150, 170))
AddResult("⏱️ Delay default: 5s | ID: 7000001", Color3.fromRGB(150, 150, 170))

print("♾️ INFINITY - Script test batas maksimum siap!")
print("📌 Delay default: 5")
print("📌 ID default: 7000001")
print("📌 Tombol: START / STOP")
print("📌 Step: " .. currentStep)
print("📌 OFF = loop tanpa henti (farming)")
