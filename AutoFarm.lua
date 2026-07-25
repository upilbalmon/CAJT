--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local delayTime = 1
local heroId = 7000117
local drawCount = 10
local autoDetect = true
local hookEnabled = true
local isMinimized = false
local customAmount = 0
local currentStep = 15
local currentPangkat = 0

--// Debounce variables
local buttonCooldown = false
local holdDelay = 0.3
local holdInterval = 0.15

-- ============================================
-- PATTERN CALCULATOR
-- ============================================
local function hitungPattern(word)
    word = string.lower(word)
    local len = #word
    if len < 2 then
        return nil, "Minimal 2 huruf"
    end

    local firstChar = string.sub(word, 1, 1)
    if not firstChar:match("%a") then
        return nil, "Harus huruf a-z"
    end

    for c in word:gmatch(".") do
        if c ~= firstChar or not c:match("%a") then
            return nil, "Huruf harus sama semua (contoh: aaaaa)"
        end
    end

    local i = string.byte(firstChar) - 97
    local k = len
    local n = 26 * (k - 2) + 1 + i
    local exponent = 18 + 3 * n
    return exponent, n
end

local function exponentToNumber(exponent)
    return 10 ^ exponent
end

--// Fungsi untuk mengubah angka ke notasi ilmiah
local function toScientificNotation(num)
    if num == 0 then return "0" end
    
    local sign = ""
    if num < 0 then
        sign = "-"
        num = math.abs(num)
    end
    
    local exponent = math.floor(math.log10(num))
    local mantissa = num / (10 ^ exponent)
    
    mantissa = math.floor(mantissa * 100 + 0.5) / 100
    
    if mantissa == 0 then
        return "0"
    elseif exponent == 0 then
        return sign .. tostring(mantissa)
    else
        return sign .. string.format("%.2f", mantissa) .. "e+" .. tostring(exponent)
    end
end

--// Fungsi untuk mendapatkan pattern dari exponent
local function getPatternFromExponent(exponent)
    if exponent < 21 then
        return nil
    end
    
    local n = (exponent - 18) / 3
    if n < 1 then return nil end
    
    local k = math.floor((n - 1) / 26) + 2
    local i = (n - 1) % 26
    local char = string.char(97 + i)
    
    return string.rep(char, k)
end

--// Fungsi untuk display pattern dengan mantissa
local function getPatternDisplay(num)
    if num == 0 then return "0" end
    
    local sign = ""
    local absNum = num
    if num < 0 then
        sign = "-"
        absNum = math.abs(num)
    end
    
    local exponent = math.floor(math.log10(absNum))
    local mantissa = absNum / (10 ^ exponent)
    mantissa = math.floor(mantissa * 100 + 0.5) / 100
    
    local pattern = getPatternFromExponent(exponent)
    
    if pattern then
        if mantissa == 1 then
            return sign .. pattern
        else
            return sign .. string.format("%.2f", mantissa) .. pattern
        end
    else
        return toScientificNotation(num)
    end
end

--// GUI
local MainFrame = Instance.new("ScreenGui")
MainFrame.Name = "DrawHeroLoopGUI"
MainFrame.Parent = playerGui
MainFrame.ResetOnSpawn = false

-- MAIN FRAME
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 420, 0, 350)
Frame.Position = UDim2.new(0.5, -210, 0.5, -175)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BackgroundTransparency = 0.2
Frame.Parent = MainFrame
Frame.Draggable = true
Frame.Active = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = Frame

-- TITLE BAR
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 25)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BackgroundTransparency = 0.3
TitleBar.Parent = Frame

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 6)
TitleBarCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 5, 0, 0)
Title.Text = "🧮 AUTO HATCH + PATTERN"
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.SourceSans
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- MINIMIZE BUTTON
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 25, 0, 25)
MinimizeButton.Position = UDim2.new(1, -50, 0, 0)
MinimizeButton.Text = "−"
MinimizeButton.Font = Enum.Font.SourceSans
MinimizeButton.TextSize = 16
MinimizeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinimizeButton.BackgroundTransparency = 0.3
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Parent = TitleBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 4)
MinimizeCorner.Parent = MinimizeButton

-- CLOSE BUTTON
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -25, 0, 0)
CloseButton.Text = "✕"
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 14
CloseButton.TextColor3 = Color3.fromRGB(220, 220, 220)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseButton.BackgroundTransparency = 0.3
CloseButton.BorderSizePixel = 0
CloseButton.Parent = TitleBar

local CloseButtonCorner = Instance.new("UICorner")
CloseButtonCorner.CornerRadius = UDim.new(0, 4)
CloseButtonCorner.Parent = CloseButton

-- CONTENT FRAME
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -25)
ContentFrame.Position = UDim2.new(0, 0, 0, 25)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = Frame

-- ============================================
-- SECTION 1: PATTERN CALCULATOR
-- ============================================
local PatternFrame = Instance.new("Frame")
PatternFrame.Size = UDim2.new(1, -10, 0, 85)
PatternFrame.Position = UDim2.new(0, 5, 0, 5)
PatternFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
PatternFrame.BackgroundTransparency = 0.3
PatternFrame.BorderSizePixel = 0
PatternFrame.Parent = ContentFrame

local PatternCorner = Instance.new("UICorner")
PatternCorner.CornerRadius = UDim.new(0, 4)
PatternCorner.Parent = PatternFrame

local PatternTitle = Instance.new("TextLabel")
PatternTitle.Size = UDim2.new(1, 0, 0, 15)
PatternTitle.Position = UDim2.new(0, 0, 0, 2)
PatternTitle.BackgroundTransparency = 1
PatternTitle.TextColor3 = Color3.fromRGB(180, 180, 200)
PatternTitle.Font = Enum.Font.SourceSans
PatternTitle.TextSize = 10
PatternTitle.Text = "📐 PATTERN CALCULATOR → otomatis ke -Hero"
PatternTitle.TextXAlignment = Enum.TextXAlignment.Center
PatternTitle.Parent = PatternFrame

local PatternInput = Instance.new("TextBox")
PatternInput.Size = UDim2.new(0.7, -10, 0, 28)
PatternInput.Position = UDim2.new(0, 5, 0, 20)
PatternInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
PatternInput.TextColor3 = Color3.fromRGB(255, 255, 255)
PatternInput.Font = Enum.Font.SourceSans
PatternInput.TextSize = 14
PatternInput.PlaceholderText = "contoh: aaaaa"
PatternInput.Text = ""
PatternInput.ClearTextOnFocus = false
PatternInput.Parent = PatternFrame

local PatternInputCorner = Instance.new("UICorner")
PatternInputCorner.CornerRadius = UDim.new(0, 4)
PatternInputCorner.Parent = PatternInput

local PatternButton = Instance.new("TextButton")
PatternButton.Size = UDim2.new(0.25, -5, 0, 28)
PatternButton.Position = UDim2.new(0.72, 0, 0, 20)
PatternButton.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
PatternButton.TextColor3 = Color3.fromRGB(255, 255, 255)
PatternButton.Font = Enum.Font.SourceSansBold
PatternButton.TextSize = 12
PatternButton.Text = "HITUNG → -Hero"
PatternButton.Parent = PatternFrame

local PatternButtonCorner = Instance.new("UICorner")
PatternButtonCorner.CornerRadius = UDim.new(0, 4)
PatternButtonCorner.Parent = PatternButton

local PatternResult = Instance.new("TextLabel")
PatternResult.Size = UDim2.new(1, -10, 0, 18)
PatternResult.Position = UDim2.new(0, 5, 0, 55)
PatternResult.BackgroundTransparency = 1
PatternResult.TextColor3 = Color3.fromRGB(100, 255, 150)
PatternResult.Font = Enum.Font.SourceSans
PatternResult.TextSize = 12
PatternResult.Text = ""
PatternResult.TextXAlignment = Enum.TextXAlignment.Left
PatternResult.Parent = PatternFrame

local PatternStatus = Instance.new("TextLabel")
PatternStatus.Size = UDim2.new(1, -10, 0, 14)
PatternStatus.Position = UDim2.new(0, 5, 0, 73)
PatternStatus.BackgroundTransparency = 1
PatternStatus.TextColor3 = Color3.fromRGB(150, 150, 170)
PatternStatus.Font = Enum.Font.SourceSans
PatternStatus.TextSize = 9
PatternStatus.Text = "Enter = Hitung & Masukkan ke -Hero"
PatternStatus.TextXAlignment = Enum.TextXAlignment.Right
PatternStatus.Parent = PatternFrame

-- ============================================
-- SECTION 2: AUTO FARM
-- ============================================
local AutoFarmFrame = Instance.new("Frame")
AutoFarmFrame.Size = UDim2.new(1, -10, 0, 220)
AutoFarmFrame.Position = UDim2.new(0, 5, 0, 100)
AutoFarmFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
AutoFarmFrame.BackgroundTransparency = 0.3
AutoFarmFrame.BorderSizePixel = 0
AutoFarmFrame.Parent = ContentFrame

local AutoFarmCorner = Instance.new("UICorner")
AutoFarmCorner.CornerRadius = UDim.new(0, 4)
AutoFarmCorner.Parent = AutoFarmFrame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 15)
StatusLabel.Position = UDim2.new(0, 5, 0, 5)
StatusLabel.Text = "Status: Siap..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = AutoFarmFrame

-- Draw Count Label
local DrawLabel = Instance.new("TextLabel")
DrawLabel.Size = UDim2.new(0.12, -5, 0, 18)
DrawLabel.Position = UDim2.new(0, 5, 0, 23)
DrawLabel.Text = "Draw:"
DrawLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DrawLabel.BackgroundTransparency = 1
DrawLabel.Font = Enum.Font.SourceSans
DrawLabel.TextSize = 11
DrawLabel.TextXAlignment = Enum.TextXAlignment.Right
DrawLabel.Parent = AutoFarmFrame

local DrawButtonFrame = Instance.new("Frame")
DrawButtonFrame.Size = UDim2.new(0.6, -10, 0, 18)
DrawButtonFrame.Position = UDim2.new(0.15, 0, 0, 23)
DrawButtonFrame.BackgroundTransparency = 1
DrawButtonFrame.Parent = AutoFarmFrame

local Draw1Button = Instance.new("TextButton")
Draw1Button.Size = UDim2.new(0.3, -3, 1, 0)
Draw1Button.Position = UDim2.new(0, 0, 0, 0)
Draw1Button.Text = "1x"
Draw1Button.Font = Enum.Font.SourceSans
Draw1Button.TextSize = 11
Draw1Button.TextColor3 = Color3.fromRGB(220, 220, 220)
Draw1Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Draw1Button.BackgroundTransparency = 0.3
Draw1Button.BorderSizePixel = 0
Draw1Button.Parent = DrawButtonFrame

local Draw1Corner = Instance.new("UICorner")
Draw1Corner.CornerRadius = UDim.new(0, 4)
Draw1Corner.Parent = Draw1Button

local Draw3Button = Instance.new("TextButton")
Draw3Button.Size = UDim2.new(0.3, -3, 1, 0)
Draw3Button.Position = UDim2.new(0.35, 0, 0, 0)
Draw3Button.Text = "3x"
Draw3Button.Font = Enum.Font.SourceSans
Draw3Button.TextSize = 11
Draw3Button.TextColor3 = Color3.fromRGB(220, 220, 220)
Draw3Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Draw3Button.BackgroundTransparency = 0.3
Draw3Button.BorderSizePixel = 0
Draw3Button.Parent = DrawButtonFrame

local Draw3Corner = Instance.new("UICorner")
Draw3Corner.CornerRadius = UDim.new(0, 4)
Draw3Corner.Parent = Draw3Button

local Draw10Button = Instance.new("TextButton")
Draw10Button.Size = UDim2.new(0.3, -3, 1, 0)
Draw10Button.Position = UDim2.new(0.7, 0, 0, 0)
Draw10Button.Text = "10x"
Draw10Button.Font = Enum.Font.SourceSans
Draw10Button.TextSize = 11
Draw10Button.TextColor3 = Color3.fromRGB(220, 220, 220)
Draw10Button.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
Draw10Button.BackgroundTransparency = 0.3
Draw10Button.BorderSizePixel = 0
Draw10Button.Parent = DrawButtonFrame

local Draw10Corner = Instance.new("UICorner")
Draw10Corner.CornerRadius = UDim.new(0, 4)
Draw10Corner.Parent = Draw10Button

local AutoDetectButton = Instance.new("TextButton")
AutoDetectButton.Size = UDim2.new(0.18, -5, 0, 18)
AutoDetectButton.Position = UDim2.new(0.78, 0, 0, 23)
AutoDetectButton.Text = "Auto: ON"
AutoDetectButton.Font = Enum.Font.SourceSans
AutoDetectButton.TextSize = 10
AutoDetectButton.TextColor3 = Color3.fromRGB(220, 220, 220)
AutoDetectButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
AutoDetectButton.BackgroundTransparency = 0.3
AutoDetectButton.BorderSizePixel = 0
AutoDetectButton.Parent = AutoFarmFrame

local AutoDetectCorner = Instance.new("UICorner")
AutoDetectCorner.CornerRadius = UDim.new(0, 4)
AutoDetectCorner.Parent = AutoDetectButton

-- ID
local IdLabel = Instance.new("TextLabel")
IdLabel.Size = UDim2.new(0.1, -5, 0, 18)
IdLabel.Position = UDim2.new(0, 5, 0, 44)
IdLabel.Text = "ID:"
IdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
IdLabel.BackgroundTransparency = 1
IdLabel.Font = Enum.Font.SourceSans
IdLabel.TextSize = 11
IdLabel.TextXAlignment = Enum.TextXAlignment.Right
IdLabel.Parent = AutoFarmFrame

local IdBox = Instance.new("TextBox")
IdBox.Size = UDim2.new(0.25, -10, 0, 18)
IdBox.Position = UDim2.new(0.13, 0, 0, 44)
IdBox.Text = tostring(heroId)
IdBox.PlaceholderText = "Hero ID"
IdBox.TextColor3 = Color3.fromRGB(220, 220, 220)
IdBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
IdBox.BackgroundTransparency = 0.3
IdBox.Font = Enum.Font.SourceSans
IdBox.TextSize = 11
IdBox.Parent = AutoFarmFrame

local IdBoxCorner = Instance.new("UICorner")
IdBoxCorner.CornerRadius = UDim.new(0, 4)
IdBoxCorner.Parent = IdBox

local DetectNowButton = Instance.new("TextButton")
DetectNowButton.Size = UDim2.new(0.15, -5, 0, 18)
DetectNowButton.Position = UDim2.new(0.4, 0, 0, 44)
DetectNowButton.Text = "Detect!"
DetectNowButton.Font = Enum.Font.SourceSans
DetectNowButton.TextSize = 11
DetectNowButton.TextColor3 = Color3.fromRGB(220, 220, 220)
DetectNowButton.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
DetectNowButton.BackgroundTransparency = 0.3
DetectNowButton.BorderSizePixel = 0
DetectNowButton.Parent = AutoFarmFrame

local DetectNowCorner = Instance.new("UICorner")
DetectNowCorner.CornerRadius = UDim.new(0, 4)
DetectNowCorner.Parent = DetectNowButton

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.1, -5, 0, 18)
DelayLabel.Position = UDim2.new(0.57, 0, 0, 44)
DelayLabel.Text = "Delay:"
DelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextSize = 11
DelayLabel.TextXAlignment = Enum.TextXAlignment.Right
DelayLabel.Parent = AutoFarmFrame

local DelayBox = Instance.new("TextBox")
DelayBox.Size = UDim2.new(0.12, -5, 0, 18)
DelayBox.Position = UDim2.new(0.67, 0, 0, 44)
DelayBox.Text = tostring(delayTime)
DelayBox.PlaceholderText = "Delay"
DelayBox.TextColor3 = Color3.fromRGB(220, 220, 220)
DelayBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
DelayBox.BackgroundTransparency = 0.3
DelayBox.Font = Enum.Font.SourceSans
DelayBox.TextSize = 11
DelayBox.Parent = AutoFarmFrame

local DelayBoxCorner = Instance.new("UICorner")
DelayBoxCorner.CornerRadius = UDim.new(0, 4)
DelayBoxCorner.Parent = DelayBox

local StartStopButton = Instance.new("TextButton")
StartStopButton.Size = UDim2.new(0.2, -5, 0, 18)
StartStopButton.Position = UDim2.new(0.8, 0, 0, 44)
StartStopButton.Text = "Start"
StartStopButton.Font = Enum.Font.SourceSans
StartStopButton.TextSize = 11
StartStopButton.TextColor3 = Color3.fromRGB(220, 220, 220)
StartStopButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
StartStopButton.BackgroundTransparency = 0.3
StartStopButton.BorderSizePixel = 0
StartStopButton.Parent = AutoFarmFrame

local StartStopCorner = Instance.new("UICorner")
StartStopCorner.CornerRadius = UDim.new(0, 4)
StartStopCorner.Parent = StartStopButton

local IdDetectedLabel = Instance.new("TextLabel")
IdDetectedLabel.Size = UDim2.new(1, -10, 0, 15)
IdDetectedLabel.Position = UDim2.new(0, 5, 0, 65)
IdDetectedLabel.Text = "ID Terdeteksi: -"
IdDetectedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
IdDetectedLabel.BackgroundTransparency = 1
IdDetectedLabel.Font = Enum.Font.SourceSans
IdDetectedLabel.TextSize = 11
IdDetectedLabel.TextXAlignment = Enum.TextXAlignment.Left
IdDetectedLabel.Parent = AutoFarmFrame

local DrawCountDisplay = Instance.new("TextLabel")
DrawCountDisplay.Size = UDim2.new(1, -10, 0, 15)
DrawCountDisplay.Position = UDim2.new(0, 5, 0, 82)
DrawCountDisplay.Text = "Draw: 10x"
DrawCountDisplay.TextColor3 = Color3.fromRGB(100, 200, 100)
DrawCountDisplay.BackgroundTransparency = 1
DrawCountDisplay.Font = Enum.Font.SourceSans
DrawCountDisplay.TextSize = 11
DrawCountDisplay.TextXAlignment = Enum.TextXAlignment.Center
DrawCountDisplay.Parent = AutoFarmFrame

-- ============================================
-- CUSTOM HERO dengan Step Control
-- ============================================
local CustomLabel = Instance.new("TextLabel")
CustomLabel.Size = UDim2.new(0.12, -5, 0, 18)
CustomLabel.Position = UDim2.new(0, 5, 0, 100)
CustomLabel.Text = "-Hero:"
CustomLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
CustomLabel.BackgroundTransparency = 1
CustomLabel.Font = Enum.Font.SourceSans
CustomLabel.TextSize = 11
CustomLabel.TextXAlignment = Enum.TextXAlignment.Right
CustomLabel.Parent = AutoFarmFrame

local CustomFrame = Instance.new("Frame")
CustomFrame.Size = UDim2.new(0.82, -10, 0, 28)
CustomFrame.Position = UDim2.new(0.15, 0, 0, 98)
CustomFrame.BackgroundTransparency = 1
CustomFrame.Parent = AutoFarmFrame

-- CustomBox utama
local CustomBox = Instance.new("TextBox")
CustomBox.Size = UDim2.new(0.55, -5, 1, 0)
CustomBox.Position = UDim2.new(0, 0, 0, 0)
CustomBox.Text = "0"
CustomBox.PlaceholderText = "Jumlah Hero (+/-)"
CustomBox.TextColor3 = Color3.fromRGB(255, 150, 150)
CustomBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CustomBox.BackgroundTransparency = 0.3
CustomBox.Font = Enum.Font.SourceSans
CustomBox.TextSize = 11
CustomBox.Parent = CustomFrame

local CustomBoxCorner = Instance.new("UICorner")
CustomBoxCorner.CornerRadius = UDim.new(0, 4)
CustomBoxCorner.Parent = CustomBox

-- Tombol ▼ (Down)
local DownButton = Instance.new("TextButton")
DownButton.Size = UDim2.new(0.07, 0, 1, 0)
DownButton.Position = UDim2.new(0.57, 0, 0, 0)
DownButton.Text = "▼"
DownButton.Font = Enum.Font.SourceSans
DownButton.TextSize = 14
DownButton.TextColor3 = Color3.fromRGB(220, 220, 220)
DownButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
DownButton.BackgroundTransparency = 0.3
DownButton.BorderSizePixel = 0
DownButton.Parent = CustomFrame

local DownCorner = Instance.new("UICorner")
DownCorner.CornerRadius = UDim.new(0, 4)
DownCorner.Parent = DownButton

-- Tombol ▲ (Up)
local UpButton = Instance.new("TextButton")
UpButton.Size = UDim2.new(0.07, 0, 1, 0)
UpButton.Position = UDim2.new(0.65, 0, 0, 0)
UpButton.Text = "▲"
UpButton.Font = Enum.Font.SourceSans
UpButton.TextSize = 14
UpButton.TextColor3 = Color3.fromRGB(220, 220, 220)
UpButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
UpButton.BackgroundTransparency = 0.3
UpButton.BorderSizePixel = 0
UpButton.Parent = CustomFrame

local UpCorner = Instance.new("UICorner")
UpCorner.CornerRadius = UDim.new(0, 4)
UpCorner.Parent = UpButton

-- Dropdown Step
local StepLabel = Instance.new("TextLabel")
StepLabel.Size = UDim2.new(0.12, -5, 1, 0)
StepLabel.Position = UDim2.new(0.74, 0, 0, 0)
StepLabel.Text = "Step:"
StepLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
StepLabel.BackgroundTransparency = 1
StepLabel.Font = Enum.Font.SourceSans
StepLabel.TextSize = 10
StepLabel.TextXAlignment = Enum.TextXAlignment.Right
StepLabel.Parent = CustomFrame

local StepDropdown = Instance.new("TextButton")
StepDropdown.Size = UDim2.new(0.12, -5, 1, 0)
StepDropdown.Position = UDim2.new(0.88, 0, 0, 0)
StepDropdown.Text = "15"
StepDropdown.Font = Enum.Font.SourceSans
StepDropdown.TextSize = 11
StepDropdown.TextColor3 = Color3.fromRGB(220, 220, 220)
StepDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
StepDropdown.BackgroundTransparency = 0.3
StepDropdown.BorderSizePixel = 0
StepDropdown.Parent = CustomFrame

local StepCorner = Instance.new("UICorner")
StepCorner.CornerRadius = UDim.new(0, 4)
StepCorner.Parent = StepDropdown

-- Dropdown List (popup) - DIPERLAMBAR untuk step 1,2,3
local DropdownList = Instance.new("Frame")
DropdownList.Size = UDim2.new(0.12, -5, 0, 180) -- Diperbesar untuk 12 item
DropdownList.Position = UDim2.new(0.88, 0, 1, 0)
DropdownList.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
DropdownList.BackgroundTransparency = 0.3
DropdownList.BorderSizePixel = 1
DropdownList.BorderColor3 = Color3.fromRGB(60, 60, 70)
DropdownList.Visible = false
DropdownList.Parent = CustomFrame

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 4)
DropdownCorner.Parent = DropdownList

-- Isi dropdown dengan step 1,2,3 dan kelipatan 3
local stepOptions = {1, 2, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30}
local stepButtons = {}

for i, step in ipairs(stepOptions) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 15)
    btn.Position = UDim2.new(0, 0, 0, (i-1) * 15)
    btn.Text = tostring(step)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Parent = DropdownList
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn
    
    stepButtons[step] = btn
end

-- Display Notasi Ilmiah + Pattern
local DisplayLabel = Instance.new("TextLabel")
DisplayLabel.Size = UDim2.new(1, -10, 0, 18)
DisplayLabel.Position = UDim2.new(0, 5, 0, 130)
DisplayLabel.Text = "Display: 0"
DisplayLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
DisplayLabel.BackgroundTransparency = 1
DisplayLabel.Font = Enum.Font.SourceSans
DisplayLabel.TextSize = 11
DisplayLabel.TextXAlignment = Enum.TextXAlignment.Left
DisplayLabel.Parent = AutoFarmFrame

-- MINI BUTTON
local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(0, 40, 0, 40)
MiniButton.Position = UDim2.new(1, -50, 1, -50)
MiniButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
MiniButton.Text = "⤴"
MiniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniButton.Font = Enum.Font.SourceSans
MiniButton.TextSize = 20
MiniButton.Visible = false
MiniButton.Parent = MainFrame

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(0, 20)
MiniCorner.Parent = MiniButton

--// Variables
local running = false
local coroutineLoop = nil
local DrawHeroEvent = nil
local oldNamecall = nil

--// Fungsi untuk format angka
local function FormatNumber(num)
    local absNum = math.abs(num)
    local sign = num < 0 and "-" or ""

    if absNum >= 1000000000000 then
        return sign .. string.format("%.2fB", absNum/1000000000000)
    elseif absNum >= 1000000000 then
        return sign .. string.format("%.2fT", absNum/1000000000)
    elseif absNum >= 1000000 then
        return sign .. string.format("%.2fM", absNum/1000000)
    elseif absNum >= 1000 then
        return sign .. string.format("%.2fK", absNum/1000)
    else
        return sign .. tostring(absNum)
    end
end

--// Fungsi untuk mendapatkan mantissa dan exponent dari angka
local function getMantissaAndExponent(num)
    if num == 0 then return 0, 0 end
    
    local absNum = math.abs(num)
    local exponent = math.floor(math.log10(absNum))
    local mantissa = absNum / (10 ^ exponent)
    mantissa = math.floor(mantissa * 100 + 0.5) / 100
    
    return mantissa, exponent
end

--// Fungsi untuk update custom amount
local function UpdateCustomAmount(value)
    customAmount = value
    CustomBox.Text = tostring(customAmount)
    
    if customAmount ~= 0 then
        local _, exp = getMantissaAndExponent(customAmount)
        currentPangkat = exp
    else
        currentPangkat = 0
    end
    
    if customAmount == 0 then
        DisplayLabel.Text = "Display: 0"
        DisplayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    elseif customAmount < 0 then
        local displayText = getPatternDisplay(customAmount)
        DisplayLabel.Text = "Display: " .. displayText .. "  (" .. toScientificNotation(customAmount) .. ")"
        DisplayLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        customAmount = 0
        CustomBox.Text = "0"
        DisplayLabel.Text = "Display: 0 (hanya negatif/0)"
        DisplayLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
    
    if customAmount < 0 then
        StatusLabel.Text = "📊 Custom: " .. FormatNumber(customAmount)
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    elseif customAmount == 0 then
        StatusLabel.Text = "📊 Custom: 0 (menggunakan Draw)"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

--// Fungsi untuk mengubah pangkat dengan step (dengan debounce)
local function ChangePangkat(direction)
    if buttonCooldown then return end
    buttonCooldown = true
    
    if customAmount == 0 then
        if direction == 1 then
            UpdateCustomAmount(- (10 ^ currentStep))
            currentPangkat = currentStep
        end
        buttonCooldown = false
        return
    end
    
    if customAmount >= 0 then
        UpdateCustomAmount(0)
        buttonCooldown = false        return
    end
    
    local mantissa, exponent = getMantissaAndExponent(customAmount)
    local newExponent = exponent + (direction * currentStep)
    
    if newExponent < 6 then
        newExponent = 6
    end
    
    local newValue = - (mantissa * (10 ^ newExponent))
    UpdateCustomAmount(newValue)
    
    task.wait(0.1)
    buttonCooldown = false
end

--// Event untuk Up Button (▲)
local upHold = false
local upCoroutine = nil
local upHoldStarted = false

UpButton.MouseButton1Down:Connect(function()
    if upHold then return end
    upHold = true
    upHoldStarted = false
    
    ChangePangkat(1)
    
    upCoroutine = coroutine.wrap(function()
        task.wait(holdDelay)
        upHoldStarted = true
        
        while upHold do
            ChangePangkat(1)
            task.wait(holdInterval)
        end
    end)
    upCoroutine()
end)

UpButton.MouseButton1Up:Connect(function()
    upHold = false
    upHoldStarted = false
end)

UpButton.MouseLeave:Connect(function()
    upHold = false
    upHoldStarted = false
end)

UpButton.MouseEnter:Connect(function()
    UpButton.BackgroundColor3 = Color3.fromRGB(60, 220, 60)
end)

UpButton.MouseLeave:Connect(function()
    UpButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
end)

--// Event untuk Down Button (▼)
local downHold = false
local downCoroutine = nil
local downHoldStarted = false

DownButton.MouseButton1Down:Connect(function()
    if downHold then return end
    downHold = true
    downHoldStarted = false
    
    ChangePangkat(-1)
    
    downCoroutine = coroutine.wrap(function()
        task.wait(holdDelay)
        downHoldStarted = true
        
        while downHold do
            ChangePangkat(-1)
            task.wait(holdInterval)
        end
    end)
    downCoroutine()
end)

DownButton.MouseButton1Up:Connect(function()
    downHold = false
    downHoldStarted = false
end)

DownButton.MouseLeave:Connect(function()
    downHold = false
    downHoldStarted = false
end)

DownButton.MouseEnter:Connect(function()
    DownButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
end)

DownButton.MouseLeave:Connect(function()
    DownButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
end)

--// Event untuk Dropdown
StepDropdown.MouseButton1Click:Connect(function()
    DropdownList.Visible = not DropdownList.Visible
end)

for step, btn in pairs(stepButtons) do
    btn.MouseButton1Click:Connect(function()
        currentStep = step
        StepDropdown.Text = tostring(step)
        DropdownList.Visible = false
        
        for s, b in pairs(stepButtons) do
            b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
        btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        
        if customAmount ~= 0 then
            local mantissa, exponent = getMantissaAndExponent(customAmount)
            local newExponent = math.floor(exponent / step) * step
            if newExponent < 6 then newExponent = step end
            local newValue = - (mantissa * (10 ^ newExponent))
            UpdateCustomAmount(newValue)
        end
    end)
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    
    btn.MouseLeave:Connect(function()
        if tonumber(btn.Text) ~= currentStep then
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end)
end

-- Sembunyikan dropdown saat klik di luar
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = game:GetService("UserInputService"):GetMouseLocation()
        local dropdownPos = DropdownList.AbsolutePosition
        local dropdownSize = DropdownList.AbsoluteSize
        
        if not (mousePos.X >= dropdownPos.X and mousePos.X <= dropdownPos.X + dropdownSize.X and
                mousePos.Y >= dropdownPos.Y and mousePos.Y <= dropdownPos.Y + dropdownSize.Y) then
            DropdownList.Visible = false
        end
    end
end)

--// Fungsi Pattern Calculator
local function updatePatternResult(text, isSuccess, exponentValue)
    if isSuccess then
        PatternResult.Text = text
        PatternResult.TextColor3 = Color3.fromRGB(100, 255, 100)
        PatternStatus.Text = "✅ " .. text .. " → dimasukkan ke -Hero"
        PatternStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        if exponentValue then
            local adjustedExponent = math.floor(exponentValue / currentStep) * currentStep
            if adjustedExponent < 6 then adjustedExponent = currentStep end
            
            local negativeValue = -exponentToNumber(adjustedExponent)
            UpdateCustomAmount(negativeValue)
            StatusLabel.Text = "📊 Pattern → -Hero: " .. FormatNumber(negativeValue) .. " (step " .. currentStep .. ")"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    else
        PatternResult.Text = "⚠️ " .. text
        PatternResult.TextColor3 = Color3.fromRGB(255, 100, 100)
        PatternStatus.Text = "❌ " .. text
        PatternStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

local function clearPattern()
    PatternInput.Text = ""
    PatternResult.Text = ""
    PatternResult.TextColor3 = Color3.fromRGB(100, 255, 150)
    PatternStatus.Text = "Enter = Hitung & Masukkan ke -Hero"
    PatternStatus.TextColor3 = Color3.fromRGB(150, 150, 170)
end

local function hitungPatternFromInput()
    local text = PatternInput.Text
    if text == "" then
        updatePatternResult("Masukkan huruf!", false)
        return
    end

    local exponent, nOrErr = hitungPattern(text)
    if exponent then
        updatePatternResult(string.format("1e+%d  (n=%d)", exponent, nOrErr), true, exponent)
    else
        updatePatternResult(nOrErr, false)
    end
end

--// Event Pattern Calculator
PatternButton.MouseButton1Click:Connect(hitungPatternFromInput)

PatternInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        hitungPatternFromInput()
    end
end)

PatternInput.Focused:Connect(function()
    if PatternInput.Text == "" then
        PatternInput.PlaceholderText = "contoh: aaaaa"
    end
end)

PatternInput.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        clearPattern()
    end
end)

--// Event untuk Custom Box
CustomBox.FocusLost:Connect(function(enterPressed)
    local value = tonumber(CustomBox.Text)
    if value ~= nil then
        if value > 0 then
            value = 0
        end
        UpdateCustomAmount(value)
    else
        CustomBox.Text = tostring(customAmount)
    end
end)

--// Function to update draw button states
local function UpdateDrawButtons(selected)
    Draw1Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Draw3Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Draw10Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

    if selected == 1 then
        Draw1Button.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        DrawCountDisplay.Text = "Draw: 1x"
        drawCount = 1
    elseif selected == 3 then
        Draw3Button.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        DrawCountDisplay.Text = "Draw: 3x"
        drawCount = 3
    elseif selected == 10 then
        Draw10Button.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        DrawCountDisplay.Text = "Draw: 10x"
        drawCount = 10
    end
end

--// Draw button events
Draw1Button.MouseButton1Click:Connect(function()
    UpdateDrawButtons(1)
end)

Draw3Button.MouseButton1Click:Connect(function()
    UpdateDrawButtons(3)
end)

Draw10Button.MouseButton1Click:Connect(function()
    UpdateDrawButtons(10)
end)

-- Button hover effects
local function SetupDrawButtonHover(button)
    button.MouseEnter:Connect(function()
        if button.BackgroundColor3 ~= Color3.fromRGB(40, 180, 40) then
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end)
    button.MouseLeave:Connect(function()
        if button.BackgroundColor3 ~= Color3.fromRGB(40, 180, 40) then
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end)
end

SetupDrawButtonHover(Draw1Button)
SetupDrawButtonHover(Draw3Button)
SetupDrawButtonHover(Draw10Button)

--// Get DrawHero Event
local function GetDrawHeroEvent()
    local success, event = pcall(function()
        return ReplicatedStorage:WaitForChild("Tool"):WaitForChild("DrawUp"):WaitForChild("Msg"):WaitForChild("DrawHero")
    end)
    if success and event then
        return event
    end
    return nil
end

--// HOOK METAMETHOD
local function InitializeRemoteHook()
    DrawHeroEvent = GetDrawHeroEvent()

    if not DrawHeroEvent then
        StatusLabel.Text = "❌ Event DrawHero tidak ditemukan!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
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
                        IdBox.Text = tostring(heroId)
                        IdDetectedLabel.Text = "✅ ID Terdeteksi: " .. heroId
                        IdDetectedLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        StatusLabel.Text = "🎯 ID terdeteksi: " .. heroId
                        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    end
                end
            end
        end

        return oldNamecall(self, ...)
    end)

    StatusLabel.Text = "✅ Hook aktif. Menunggu InvokeServer..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    return true
end

--// Unhook
local function UnhookRemote()
    hookEnabled = false
    oldNamecall = nil
end

--// Function to update status
local function UpdateStatus(text, color)
    StatusLabel.Text = text
    StatusLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
end

--// Toggle auto detect
AutoDetectButton.MouseButton1Click:Connect(function()
    autoDetect = not autoDetect
    if autoDetect then
        AutoDetectButton.Text = "Auto: ON"
        AutoDetectButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        hookEnabled = true
        InitializeRemoteHook()
    else
        AutoDetectButton.Text = "Auto: OFF"
        AutoDetectButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        UnhookRemote()
    end
end)

AutoDetectButton.MouseEnter:Connect(function()
    if autoDetect then
        AutoDetectButton.BackgroundColor3 = Color3.fromRGB(60, 220, 60)
    else
        AutoDetectButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end)

AutoDetectButton.MouseLeave:Connect(function()
    if autoDetect then
        AutoDetectButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    else
        AutoDetectButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
end)

-- Detect Now
DetectNowButton.MouseButton1Click:Connect(function()
    StatusLabel.Text = "⏳ Mencoba mendeteksi ID..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)

    local tempEvent = GetDrawHeroEvent()
    if tempEvent then
        pcall(function()
            tempEvent:InvokeServer(1, drawCount)
            task.wait(0.3)
            tempEvent:InvokeServer(2, drawCount)
            task.wait(0.3)
        end)
    end

    if heroId == 7000117 then
        StatusLabel.Text = "❌ Tidak ada ID terdeteksi. Coba jalankan game."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end)

DetectNowButton.MouseEnter:Connect(function()
    DetectNowButton.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
end)

DetectNowButton.MouseLeave:Connect(function()
    DetectNowButton.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
end)

--// Function to run the loop
local function DrawHeroFunction()
    DrawHeroEvent = GetDrawHeroEvent()
    if not DrawHeroEvent then
        UpdateStatus("❌ Event tidak ditemukan!", Color3.fromRGB(255, 0, 0))
        return
    end

    local amountToDraw = drawCount
    if customAmount ~= 0 then
        amountToDraw = customAmount
    end

    local success, result = pcall(function()
        return DrawHeroEvent:InvokeServer(heroId, amountToDraw)
    end)

    if not success then
        UpdateStatus("❌ Error: " .. tostring(result), Color3.fromRGB(255, 0, 0))
    else
        if customAmount ~= 0 then
            UpdateStatus("✅ Draw " .. FormatNumber(customAmount) .. " hero berhasil!", Color3.fromRGB(255, 100, 100))
        end
    end
end

local function RunLoop()
    while running do
        DrawHeroFunction()
        wait(delayTime)
    end
end

--// Start/Stop button
StartStopButton.MouseButton1Click:Connect(function()
    running = not running
    if running then
        StartStopButton.Text = "Stop"
        StartStopButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        coroutineLoop = coroutine.wrap(RunLoop)
        coroutineLoop()

        local amountDisplay = drawCount .. "x"
        if customAmount ~= 0 then
            amountDisplay = FormatNumber(customAmount)
        end
        UpdateStatus("▶️ Running... ID: " .. heroId .. " | " .. amountDisplay, Color3.fromRGB(0, 255, 0))
    else
        StartStopButton.Text = "Start"
        StartStopButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        UpdateStatus("⏹️ Stopped", Color3.fromRGB(255, 255, 0))
    end
end)

--// MINIMIZE FUNCTION
local function MinimizeGUI()
    isMinimized = true
    TweenService:Create(Frame, TweenInfo.new(0.3), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(1, 0, 1, 0)
    }):Play()
    task.wait(0.3)
    Frame.Visible = false
    MiniButton.Visible = true
end

local function RestoreGUI()
    isMinimized = false
    MiniButton.Visible = false
    Frame.Visible = true
    TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 420, 0, 350),
        Position = UDim2.new(0.5, -210, 0.5, -175)
    }):Play()
end

-- EVENT MINIMIZE
MinimizeButton.MouseButton1Click:Connect(function()
    MinimizeGUI()
end)

-- EVENT MINI BUTTON
MiniButton.MouseButton1Click:Connect(function()
    RestoreGUI()
end)

MiniButton.MouseEnter:Connect(function()
    MiniButton.BackgroundColor3 = Color3.fromRGB(60, 220, 60)
end)

MiniButton.MouseLeave:Connect(function()
    MiniButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
end)

--// CLOSE BUTTON
CloseButton.MouseButton1Click:Connect(function()
    hookEnabled = false
    running = false
    coroutineLoop = nil
    MainFrame:Destroy()
end)

-- HOVER EFFECTS
CloseButton.MouseEnter:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
end)

CloseButton.MouseLeave:Connect(function()
    CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
end)

MinimizeButton.MouseEnter:Connect(function()
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
end)

MinimizeButton.MouseLeave:Connect(function()
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
end)

StartStopButton.MouseEnter:Connect(function()
    if running then
        StartStopButton.BackgroundColor3 = Color3.fromRGB(140, 50, 50)
    else
        StartStopButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
end)

StartStopButton.MouseLeave:Connect(function()
    if running then
        StartStopButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    else
        StartStopButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)

-- ID Box input
IdBox.FocusLost:Connect(function(enterPressed)
    local newId = tonumber(IdBox.Text)
    if newId and newId > 0 then
        heroId = newId
        UpdateStatus("ID manual: " .. heroId, Color3.fromRGB(0, 255, 0))
        IdDetectedLabel.Text = "📌 ID Manual: " .. heroId
        IdDetectedLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    else
        IdBox.Text = tostring(heroId)
    end
end)

-- Delay Box input
DelayBox.FocusLost:Connect(function(enterPressed)
    local newDelay = tonumber(DelayBox.Text)
    if newDelay and newDelay > 0 then
        delayTime = newDelay
        UpdateStatus("Delay: " .. delayTime .. "s", Color3.fromRGB(0, 255, 0))
    else
        DelayBox.Text = tostring(delayTime)
    end
end)

--// Initialize
UpdateDrawButtons(10)
local initSuccess = InitializeRemoteHook()
if initSuccess then
    UpdateStatus("✅ Script siap. Auto detect aktif.", Color3.fromRGB(0, 255, 0))
else
    UpdateStatus("⚠️ Auto detect gagal. Gunakan ID manual.", Color3.fromRGB(255, 165, 0))
end

-- Set default step highlight
for s, btn in pairs(stepButtons) do
    if s == currentStep then
        btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    end
end

print("🚀 Auto Hatch + Pattern Script Loaded")
print("📌 Default ID: " .. heroId)
print("📌 Default Draw: " .. drawCount .. "x")
print("📌 Default Step: " .. currentStep)
