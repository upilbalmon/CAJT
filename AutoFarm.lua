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
local customAmount = 0 -- Nilai custom untuk jumlah hero (bisa negatif)

--// GUI
local MainFrame = Instance.new("ScreenGui")
MainFrame.Name = "DrawHeroLoopGUI"
MainFrame.Parent = playerGui
MainFrame.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 380, 0, 200)
Frame.Position = UDim2.new(0.5, -190, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BackgroundTransparency = 0.2
Frame.Parent = MainFrame
Frame.Draggable = true
Frame.Active = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = Frame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 20)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BackgroundTransparency = 0.3
TitleBar.Parent = Frame

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, 6)
TitleBarCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 5, 0, 0)
Title.Text = "AUTO HATCH"
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.SourceSans
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 20, 0, 20)
MinimizeButton.Position = UDim2.new(1, -45, 0, 0)
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

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(1, -22, 0, 0)
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

-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -20)
ContentFrame.Position = UDim2.new(0, 0, 0, 20)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = Frame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 15)
StatusLabel.Position = UDim2.new(0, 5, 1, -180)
StatusLabel.Text = "Status: Siap..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = ContentFrame

-- Draw Count Label
local DrawLabel = Instance.new("TextLabel")
DrawLabel.Size = UDim2.new(0.15, -5, 0, 18)
DrawLabel.Position = UDim2.new(0, 5, 1, -160)
DrawLabel.Text = "Draw:"
DrawLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DrawLabel.BackgroundTransparency = 1
DrawLabel.Font = Enum.Font.SourceSans
DrawLabel.TextSize = 11
DrawLabel.TextXAlignment = Enum.TextXAlignment.Right
DrawLabel.Parent = ContentFrame

-- Draw Count Buttons
local DrawButtonFrame = Instance.new("Frame")
DrawButtonFrame.Size = UDim2.new(0.5, -10, 0, 18)
DrawButtonFrame.Position = UDim2.new(0.18, 0, 1, -160)
DrawButtonFrame.BackgroundTransparency = 1
DrawButtonFrame.Parent = ContentFrame

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

-- Auto Detect Toggle
local AutoDetectButton = Instance.new("TextButton")
AutoDetectButton.Size = UDim2.new(0.18, -5, 0, 18)
AutoDetectButton.Position = UDim2.new(0.7, 0, 1, -160)
AutoDetectButton.Text = "Auto: ON"
AutoDetectButton.Font = Enum.Font.SourceSans
AutoDetectButton.TextSize = 10
AutoDetectButton.TextColor3 = Color3.fromRGB(220, 220, 220)
AutoDetectButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
AutoDetectButton.BackgroundTransparency = 0.3
AutoDetectButton.BorderSizePixel = 0
AutoDetectButton.Parent = ContentFrame

local AutoDetectCorner = Instance.new("UICorner")
AutoDetectCorner.CornerRadius = UDim.new(0, 4)
AutoDetectCorner.Parent = AutoDetectButton

-- ID
local IdLabel = Instance.new("TextLabel")
IdLabel.Size = UDim2.new(0.12, -5, 0, 18)
IdLabel.Position = UDim2.new(0, 5, 1, -138)
IdLabel.Text = "ID:"
IdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
IdLabel.BackgroundTransparency = 1
IdLabel.Font = Enum.Font.SourceSans
IdLabel.TextSize = 11
IdLabel.TextXAlignment = Enum.TextXAlignment.Right
IdLabel.Parent = ContentFrame

local IdBox = Instance.new("TextBox")
IdBox.Size = UDim2.new(0.35, -10, 0, 18)
IdBox.Position = UDim2.new(0.15, 0, 1, -138)
IdBox.Text = tostring(heroId)
IdBox.PlaceholderText = "Hero ID"
IdBox.TextColor3 = Color3.fromRGB(220, 220, 220)
IdBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
IdBox.BackgroundTransparency = 0.3
IdBox.Font = Enum.Font.SourceSans
IdBox.TextSize = 11
IdBox.Parent = ContentFrame

local IdBoxCorner = Instance.new("UICorner")
IdBoxCorner.CornerRadius = UDim.new(0, 4)
IdBoxCorner.Parent = IdBox

local DetectNowButton = Instance.new("TextButton")
DetectNowButton.Size = UDim2.new(0.2, -5, 0, 18)
DetectNowButton.Position = UDim2.new(0.53, 0, 1, -138)
DetectNowButton.Text = "Detect!"
DetectNowButton.Font = Enum.Font.SourceSans
DetectNowButton.TextSize = 11
DetectNowButton.TextColor3 = Color3.fromRGB(220, 220, 220)
DetectNowButton.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
DetectNowButton.BackgroundTransparency = 0.3
DetectNowButton.BorderSizePixel = 0
DetectNowButton.Parent = ContentFrame

local DetectNowCorner = Instance.new("UICorner")
DetectNowCorner.CornerRadius = UDim.new(0, 4)
DetectNowCorner.Parent = DetectNowButton

-- Delay
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.12, -5, 0, 18)
DelayLabel.Position = UDim2.new(0, 5, 1, -116)
DelayLabel.Text = "Delay:"
DelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextSize = 11
DelayLabel.TextXAlignment = Enum.TextXAlignment.Right
DelayLabel.Parent = ContentFrame

local DelayBox = Instance.new("TextBox")
DelayBox.Size = UDim2.new(0.2, -10, 0, 18)
DelayBox.Position = UDim2.new(0.15, 0, 1, -116)
DelayBox.Text = tostring(delayTime)
DelayBox.PlaceholderText = "Delay"
DelayBox.TextColor3 = Color3.fromRGB(220, 220, 220)
DelayBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
DelayBox.BackgroundTransparency = 0.3
DelayBox.Font = Enum.Font.SourceSans
DelayBox.TextSize = 11
DelayBox.Parent = ContentFrame

local DelayBoxCorner = Instance.new("UICorner")
DelayBoxCorner.CornerRadius = UDim.new(0, 4)
DelayBoxCorner.Parent = DelayBox

local StartStopButton = Instance.new("TextButton")
StartStopButton.Size = UDim2.new(0.45, -10, 0, 18)
StartStopButton.Position = UDim2.new(0.38, 0, 1, -116)
StartStopButton.Text = "Start"
StartStopButton.Font = Enum.Font.SourceSans
StartStopButton.TextSize = 11
StartStopButton.TextColor3 = Color3.fromRGB(220, 220, 220)
StartStopButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
StartStopButton.BackgroundTransparency = 0.3
StartStopButton.BorderSizePixel = 0
StartStopButton.Parent = ContentFrame

local StartStopCorner = Instance.new("UICorner")
StartStopCorner.CornerRadius = UDim.new(0, 4)
StartStopCorner.Parent = StartStopButton

-- ID Detected Label
local IdDetectedLabel = Instance.new("TextLabel")
IdDetectedLabel.Size = UDim2.new(1, -10, 0, 15)
IdDetectedLabel.Position = UDim2.new(0, 5, 1, -96)
IdDetectedLabel.Text = "ID Terdeteksi: -"
IdDetectedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
IdDetectedLabel.BackgroundTransparency = 1
IdDetectedLabel.Font = Enum.Font.SourceSans
IdDetectedLabel.TextSize = 11
IdDetectedLabel.TextXAlignment = Enum.TextXAlignment.Left
IdDetectedLabel.Parent = ContentFrame

-- Draw Count Display
local DrawCountDisplay = Instance.new("TextLabel")
DrawCountDisplay.Size = UDim2.new(1, -10, 0, 15)
DrawCountDisplay.Position = UDim2.new(0, 5, 1, -78)
DrawCountDisplay.Text = "Draw: 10x"
DrawCountDisplay.TextColor3 = Color3.fromRGB(100, 200, 100)
DrawCountDisplay.BackgroundTransparency = 1
DrawCountDisplay.Font = Enum.Font.SourceSans
DrawCountDisplay.TextSize = 11
DrawCountDisplay.TextXAlignment = Enum.TextXAlignment.Center
DrawCountDisplay.Parent = ContentFrame

-- === FITUR CUSTOM JUMLAH HERO (NEGATIF) ===
local CustomLabel = Instance.new("TextLabel")
CustomLabel.Size = UDim2.new(0.15, -5, 0, 18)
CustomLabel.Position = UDim2.new(0, 5, 1, -56)
CustomLabel.Text = "-Hero:"
CustomLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Warna merah untuk negatif
CustomLabel.BackgroundTransparency = 1
CustomLabel.Font = Enum.Font.SourceSans
CustomLabel.TextSize = 11
CustomLabel.TextXAlignment = Enum.TextXAlignment.Right
CustomLabel.Parent = ContentFrame

-- Frame untuk custom amount
local CustomFrame = Instance.new("Frame")
CustomFrame.Size = UDim2.new(0.65, -10, 0, 24)
CustomFrame.Position = UDim2.new(0.18, 0, 1, -58)
CustomFrame.BackgroundTransparency = 1
CustomFrame.Parent = ContentFrame

-- TextBox untuk input custom (otomatis negatif)
local CustomBox = Instance.new("TextBox")
CustomBox.Size = UDim2.new(0.55, -5, 1, 0)
CustomBox.Position = UDim2.new(0, 0, 0, 0)
CustomBox.Text = "0"
CustomBox.PlaceholderText = "Jumlah Hero (-)"
CustomBox.TextColor3 = Color3.fromRGB(255, 150, 150) -- Warna merah
CustomBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CustomBox.BackgroundTransparency = 0.3
CustomBox.Font = Enum.Font.SourceSans
CustomBox.TextSize = 11
CustomBox.Parent = CustomFrame

local CustomBoxCorner = Instance.new("UICorner")
CustomBoxCorner.CornerRadius = UDim.new(0, 4)
CustomBoxCorner.Parent = CustomBox

-- Tombol Up (menambah nilai negatif, contoh: -1 -> -2)
local UpButton = Instance.new("TextButton")
UpButton.Size = UDim2.new(0.07, 0, 0.5, 0)
UpButton.Position = UDim2.new(0.57, 0, 0, 0)
UpButton.Text = "▲"
UpButton.Font = Enum.Font.SourceSans
UpButton.TextSize = 10
UpButton.TextColor3 = Color3.fromRGB(220, 220, 220)
UpButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
UpButton.BackgroundTransparency = 0.3
UpButton.BorderSizePixel = 0
UpButton.Parent = CustomFrame

local UpCorner = Instance.new("UICorner")
UpCorner.CornerRadius = UDim.new(0, 3)
UpCorner.Parent = UpButton

-- Tombol Down (mengurangi nilai negatif, contoh: -1 -> 0)
local DownButton = Instance.new("TextButton")
DownButton.Size = UDim2.new(0.07, 0, 0.5, 0)
DownButton.Position = UDim2.new(0.57, 0, 0.5, 0)
DownButton.Text = "▼"
DownButton.Font = Enum.Font.SourceSans
DownButton.TextSize = 10
DownButton.TextColor3 = Color3.fromRGB(220, 220, 220)
DownButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
DownButton.BackgroundTransparency = 0.3
DownButton.BorderSizePixel = 0
DownButton.Parent = CustomFrame

local DownCorner = Instance.new("UICorner")
DownCorner.CornerRadius = UDim.new(0, 3)
DownCorner.Parent = DownButton

-- Tombol Kelipatan NEGATIF (1K-, 1M-, 1T-, 1B-)
local MultiplierFrame = Instance.new("Frame")
MultiplierFrame.Size = UDim2.new(0.3, -5, 0.8, 0)
MultiplierFrame.Position = UDim2.new(0.66, 0, 0.1, 0)
MultiplierFrame.BackgroundTransparency = 1
MultiplierFrame.Parent = CustomFrame

local MultiplierButtons = {}
local multipliers = {
    {name = "1K-", value = -1000},
    {name = "1M-", value = -1000000},
    {name = "1T-", value = -1000000000},
    {name = "1B-", value = -1000000000000}
}

for i, mult in ipairs(multipliers) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.23, -2, 1, 0)
    btn.Position = UDim2.new((i-1) * 0.25, 0, 0, 0)
    btn.Text = mult.name
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 9
    btn.TextColor3 = Color3.fromRGB(255, 150, 150) -- Warna merah
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Parent = MultiplierFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn
    
    MultiplierButtons[mult.name] = btn
end

-- Mini Button
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

--// Fungsi untuk update custom amount (selalu negatif)
local function UpdateCustomAmount(value)
    -- Pastikan nilai selalu negatif atau 0
    local newValue = math.min(0, value) -- Hanya 0 atau negatif
    newValue = math.max(-999999999999, newValue) -- Batas minimum
    customAmount = newValue
    CustomBox.Text = tostring(customAmount)
    
    -- Update status
    if customAmount < 0 then
        StatusLabel.Text = "📊 Custom: " .. FormatNumber(customAmount)
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Warna merah
    elseif customAmount == 0 then
        StatusLabel.Text = "📊 Custom: 0 (menggunakan Draw)"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

--// Event untuk Custom Box
CustomBox.FocusLost:Connect(function(enterPressed)
    local value = tonumber(CustomBox.Text)
    if value ~= nil then
        -- Pastikan negatif
        UpdateCustomAmount(value)
    else
        CustomBox.Text = tostring(customAmount)
    end
end)

--// Event untuk Up Button (nilai semakin negatif)
local upHold = false
local upCoroutine = nil

UpButton.MouseButton1Down:Connect(function()
    upHold = true
    UpdateCustomAmount(customAmount - 1) -- Kurangi 1 (lebih negatif)
    
    upCoroutine = coroutine.wrap(function()
        while upHold do
            task.wait(0.1)
            if upHold then
                UpdateCustomAmount(customAmount - 1)
            end
        end
    end)
    upCoroutine()
end)

UpButton.MouseButton1Up:Connect(function()
    upHold = false
end)

UpButton.MouseLeave:Connect(function()
    upHold = false
end)

--// Event untuk Down Button (nilai mendekati 0)
local downHold = false
local downCoroutine = nil

DownButton.MouseButton1Down:Connect(function()
    downHold = true
    UpdateCustomAmount(customAmount + 1) -- Tambah 1 (mendekati 0)
    
    downCoroutine = coroutine.wrap(function()
        while downHold do
            task.wait(0.1)
            if downHold then
                UpdateCustomAmount(customAmount + 1)
            end
        end
    end)
    downCoroutine()
end)

DownButton.MouseButton1Up:Connect(function()
    downHold = false
end)

DownButton.MouseLeave:Connect(function()
    downHold = false
end)

--// Event untuk Multiplier Buttons (semua negatif)
for name, btn in pairs(MultiplierButtons) do
    btn.MouseButton1Click:Connect(function()
        local multValue = 0
        if name == "1K-" then multValue = -1000
        elseif name == "1M-" then multValue = -1000000
        elseif name == "1T-" then multValue = -1000000000
        elseif name == "1B-" then multValue = -1000000000000
        end
        
        UpdateCustomAmount(customAmount + multValue) -- Tambahkan nilai negatif
    end)
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
end

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

    -- Gunakan customAmount jika tidak 0 (negatif), selain itu gunakan drawCount
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

--// Minimize function
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
        Size = UDim2.new(0, 380, 0, 200),
        Position = UDim2.new(0.5, -190, 0.5, -100)
    }):Play()
end

MinimizeButton.MouseButton1Click:Connect(function()
    MinimizeGUI()
end)

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

-- Close button hover
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

print("🚀 Auto Hatch Script Loaded")
print("📌 Default ID: " .. heroId)
print("📌 Default Draw: " .. drawCount .. "x")
