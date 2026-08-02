--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- HAPUS GUI LAMA JIKA ADA
-- ============================================
local function destroyExistingGUI()
    local existingGUI = playerGui:FindFirstChild("WingPurchaseGUI")
    if existingGUI then
        existingGUI:Destroy()
        return true
    end
    return false
end

destroyExistingGUI()

--// Variables
local baseWingID = 13000001  -- ID dasar dari textbox
local currentWingID = 13000001 -- ID yang akan dikirim (base + iterasi)
local purchaseCount = 10
local delayTime = 0.5
local autoDetect = true
local hookEnabled = true
local isMinimized = false
local running = false
local coroutineLoop = nil
local oldNamecall = nil
local remoteEvent = nil
local iterationCount = 0 -- Menghitung pengiriman ke berapa

--// GUI Creation
local MainFrame = Instance.new("ScreenGui")
MainFrame.Name = "WingPurchaseGUI"
MainFrame.Parent = playerGui
MainFrame.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 380, 0, 180)
Frame.Position = UDim2.new(0.5, -190, 0.5, -90)
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
Title.Text = "WING PURCHASE (SEQUENTIAL ID)"
Title.TextColor3 = Color3.fromRGB(220, 220, 220)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.SourceSans
Title.TextSize = 13
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
StatusLabel.Position = UDim2.new(0, 5, 1, -160)
StatusLabel.Text = "Status: Siap..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = ContentFrame

-- Purchase Count Label
local CountLabel = Instance.new("TextLabel")
CountLabel.Size = UDim2.new(0.12, -5, 0, 18)
CountLabel.Position = UDim2.new(0, 5, 1, -138)
CountLabel.Text = "Jumlah:"
CountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CountLabel.BackgroundTransparency = 1
CountLabel.Font = Enum.Font.SourceSans
CountLabel.TextSize = 11
CountLabel.TextXAlignment = Enum.TextXAlignment.Right
CountLabel.Parent = ContentFrame

-- Purchase Count Buttons
local CountButtonFrame = Instance.new("Frame")
CountButtonFrame.Size = UDim2.new(0.5, -10, 0, 18)
CountButtonFrame.Position = UDim2.new(0.15, 0, 1, -138)
CountButtonFrame.BackgroundTransparency = 1
CountButtonFrame.Parent = ContentFrame

local Count1Button = Instance.new("TextButton")
Count1Button.Size = UDim2.new(0.3, -3, 1, 0)
Count1Button.Position = UDim2.new(0, 0, 0, 0)
Count1Button.Text = "10"
Count1Button.Font = Enum.Font.SourceSans
Count1Button.TextSize = 11
Count1Button.TextColor3 = Color3.fromRGB(220, 220, 220)
Count1Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Count1Button.BackgroundTransparency = 0.3
Count1Button.BorderSizePixel = 0
Count1Button.Parent = CountButtonFrame

local Count1Corner = Instance.new("UICorner")
Count1Corner.CornerRadius = UDim.new(0, 4)
Count1Corner.Parent = Count1Button

local Count2Button = Instance.new("TextButton")
Count2Button.Size = UDim2.new(0.3, -3, 1, 0)
Count2Button.Position = UDim2.new(0.35, 0, 0, 0)
Count2Button.Text = "50"
Count2Button.Font = Enum.Font.SourceSans
Count2Button.TextSize = 11
Count2Button.TextColor3 = Color3.fromRGB(220, 220, 220)
Count2Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Count2Button.BackgroundTransparency = 0.3
Count2Button.BorderSizePixel = 0
Count2Button.Parent = CountButtonFrame

local Count2Corner = Instance.new("UICorner")
Count2Corner.CornerRadius = UDim.new(0, 4)
Count2Corner.Parent = Count2Button

local Count3Button = Instance.new("TextButton")
Count3Button.Size = UDim2.new(0.3, -3, 1, 0)
Count3Button.Position = UDim2.new(0.7, 0, 0, 0)
Count3Button.Text = "100"
Count3Button.Font = Enum.Font.SourceSans
Count3Button.TextSize = 11
Count3Button.TextColor3 = Color3.fromRGB(220, 220, 220)
Count3Button.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
Count3Button.BackgroundTransparency = 0.3
Count3Button.BorderSizePixel = 0
Count3Button.Parent = CountButtonFrame

local Count3Corner = Instance.new("UICorner")
Count3Corner.CornerRadius = UDim.new(0, 4)
Count3Corner.Parent = Count3Button

-- Custom Count Box
local CustomCountBox = Instance.new("TextBox")
CustomCountBox.Size = UDim2.new(0.15, -5, 0, 18)
CustomCountBox.Position = UDim2.new(0.68, 0, 1, -138)
CustomCountBox.Text = ""
CustomCountBox.PlaceholderText = "Custom"
CustomCountBox.TextColor3 = Color3.fromRGB(220, 220, 220)
CustomCountBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CustomCountBox.BackgroundTransparency = 0.3
CustomCountBox.Font = Enum.Font.SourceSans
CustomCountBox.TextSize = 11
CustomCountBox.ClearTextOnFocus = false
CustomCountBox.Parent = ContentFrame

local CustomCountCorner = Instance.new("UICorner")
CustomCountCorner.CornerRadius = UDim.new(0, 4)
CustomCountCorner.Parent = CustomCountBox

-- Auto Detect Toggle
local AutoDetectButton = Instance.new("TextButton")
AutoDetectButton.Size = UDim2.new(0.18, -5, 0, 18)
AutoDetectButton.Position = UDim2.new(0, 5, 1, -116)
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

-- Wing ID Label
local IdLabel = Instance.new("TextLabel")
IdLabel.Size = UDim2.new(0.12, -5, 0, 18)
IdLabel.Position = UDim2.new(0.2, 0, 1, -116)
IdLabel.Text = "Base ID:"
IdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
IdLabel.BackgroundTransparency = 1
IdLabel.Font = Enum.Font.SourceSans
IdLabel.TextSize = 11
IdLabel.TextXAlignment = Enum.TextXAlignment.Right
IdLabel.Parent = ContentFrame

-- Wing ID Box
local IdBox = Instance.new("TextBox")
IdBox.Size = UDim2.new(0.35, -10, 0, 18)
IdBox.Position = UDim2.new(0.35, 0, 1, -116)
IdBox.Text = tostring(baseWingID)
IdBox.PlaceholderText = "Base Wing ID"
IdBox.TextColor3 = Color3.fromRGB(220, 220, 220)
IdBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
IdBox.BackgroundTransparency = 0.3
IdBox.Font = Enum.Font.SourceSans
IdBox.TextSize = 11
IdBox.ClearTextOnFocus = false
IdBox.Parent = ContentFrame

local IdBoxCorner = Instance.new("UICorner")
IdBoxCorner.CornerRadius = UDim.new(0, 4)
IdBoxCorner.Parent = IdBox

-- Detect Now Button
local DetectNowButton = Instance.new("TextButton")
DetectNowButton.Size = UDim2.new(0.12, -5, 0, 18)
DetectNowButton.Position = UDim2.new(0.72, 0, 1, -116)
DetectNowButton.Text = "Detect!"
DetectNowButton.Font = Enum.Font.SourceSans
DetectNowButton.TextSize = 10
DetectNowButton.TextColor3 = Color3.fromRGB(220, 220, 220)
DetectNowButton.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
DetectNowButton.BackgroundTransparency = 0.3
DetectNowButton.BorderSizePixel = 0
DetectNowButton.Parent = ContentFrame

local DetectNowCorner = Instance.new("UICorner")
DetectNowCorner.CornerRadius = UDim.new(0, 4)
DetectNowCorner.Parent = DetectNowButton

-- Info ID Awal
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(0.3, -5, 0, 18)
InfoLabel.Position = UDim2.new(0.85, 0, 1, -116)
InfoLabel.Text = "➜ ID+1"
InfoLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.SourceSans
InfoLabel.TextSize = 10
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.Parent = ContentFrame

-- Delay
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0.12, -5, 0, 18)
DelayLabel.Position = UDim2.new(0, 5, 1, -94)
DelayLabel.Text = "Delay:"
DelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextSize = 11
DelayLabel.TextXAlignment = Enum.TextXAlignment.Right
DelayLabel.Parent = ContentFrame

local DelayBox = Instance.new("TextBox")
DelayBox.Size = UDim2.new(0.15, -10, 0, 18)
DelayBox.Position = UDim2.new(0.15, 0, 1, -94)
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

-- Start/Stop Button
local StartStopButton = Instance.new("TextButton")
StartStopButton.Size = UDim2.new(0.45, -10, 0, 18)
StartStopButton.Position = UDim2.new(0.32, 0, 1, -94)
StartStopButton.Text = "Start"
StartStopButton.Font = Enum.Font.SourceSans
StartStopButton.TextSize = 11
StartStopButton.TextColor3 = Color3.fromRGB(220, 220, 220)
StartStopButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
StartStopButton.BackgroundTransparency = 0.3
StartStopButton.BorderSizePixel = 0
StartStopButton.Parent = ContentFrame

local StartStopCorner = Instance.new("UICorner")
StartStopCorner.CornerRadius = UDim.new(0, 4)
StartStopCorner.Parent = StartStopButton

-- Info ID Sekarang
local CurrentIdLabel = Instance.new("TextLabel")
CurrentIdLabel.Size = UDim2.new(0.5, -5, 0, 18)
CurrentIdLabel.Position = UDim2.new(0.25, 0, 1, -72)
CurrentIdLabel.Text = "ID Sekarang: -"
CurrentIdLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
CurrentIdLabel.BackgroundTransparency = 1
CurrentIdLabel.Font = Enum.Font.SourceSans
CurrentIdLabel.TextSize = 11
CurrentIdLabel.TextXAlignment = Enum.TextXAlignment.Center
CurrentIdLabel.Parent = ContentFrame

-- Progress Label
local ProgressLabel = Instance.new("TextLabel")
ProgressLabel.Size = UDim2.new(1, -10, 0, 15)
ProgressLabel.Position = UDim2.new(0, 5, 1, -54)
ProgressLabel.Text = "Progress: 0/0"
ProgressLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
ProgressLabel.BackgroundTransparency = 1
ProgressLabel.Font = Enum.Font.SourceSans
ProgressLabel.TextSize = 11
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
ProgressLabel.Parent = ContentFrame

-- Detail Label
local DetailLabel = Instance.new("TextLabel")
DetailLabel.Size = UDim2.new(1, -10, 0, 15)
DetailLabel.Position = UDim2.new(0, 5, 1, -36)
DetailLabel.Text = "Base: " .. baseWingID .. " | Mulai dari: " .. (baseWingID + 1) .. " | Delay: " .. delayTime .. "s"
DetailLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
DetailLabel.BackgroundTransparency = 1
DetailLabel.Font = Enum.Font.SourceSans
DetailLabel.TextSize = 10
DetailLabel.TextXAlignment = Enum.TextXAlignment.Left
DetailLabel.Parent = ContentFrame

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

--// Function to update count buttons
local function UpdateCountButtons(selected)
    Count1Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Count2Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Count3Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    
    if selected == 10 then
        Count1Button.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        purchaseCount = 10
        CustomCountBox.Text = ""
    elseif selected == 50 then
        Count2Button.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        purchaseCount = 50
        CustomCountBox.Text = ""
    elseif selected == 100 then
        Count3Button.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        purchaseCount = 100
        CustomCountBox.Text = ""
    end
    DetailLabel.Text = "Base: " .. baseWingID .. " | Mulai dari: " .. (baseWingID + 1) .. " | Delay: " .. delayTime .. "s"
end

--// Count button events
Count1Button.MouseButton1Click:Connect(function()
    UpdateCountButtons(10)
end)

Count2Button.MouseButton1Click:Connect(function()
    UpdateCountButtons(50)
end)

Count3Button.MouseButton1Click:Connect(function()
    UpdateCountButtons(100)
end)

-- Custom count input
CustomCountBox.FocusLost:Connect(function(enterPressed)
    local newCount = tonumber(CustomCountBox.Text)
    if newCount and newCount > 0 then
        purchaseCount = newCount
        Count1Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Count2Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Count3Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        DetailLabel.Text = "Base: " .. baseWingID .. " | Mulai dari: " .. (baseWingID + 1) .. " | Delay: " .. delayTime .. "s"
        StatusLabel.Text = "✅ Jumlah diatur ke: " .. purchaseCount
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        CustomCountBox.Text = ""
        StatusLabel.Text = "⚠️ Jumlah tidak valid"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
    end
end)

-- Button hover effects
local function SetupButtonHover(button, hoverColor, normalColor)
    button.MouseEnter:Connect(function()
        if button.BackgroundColor3 ~= hoverColor then
            button.BackgroundColor3 = normalColor
        end
    end)
    button.MouseLeave:Connect(function()
        if button.BackgroundColor3 ~= hoverColor then
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end)
end

SetupButtonHover(Count1Button, Color3.fromRGB(40, 180, 40), Color3.fromRGB(60, 60, 60))
SetupButtonHover(Count2Button, Color3.fromRGB(40, 180, 40), Color3.fromRGB(60, 60, 60))
SetupButtonHover(Count3Button, Color3.fromRGB(40, 180, 40), Color3.fromRGB(60, 60, 60))

--// Get Remote Event
local function GetRemoteEvent()
    local success, event = pcall(function()
        return ReplicatedStorage:WaitForChild("Msg"):WaitForChild("RemoteEvent")
    end)
    if success and event then
        return event
    end
    return nil
end

--// HOOK METAMETHOD untuk FireServer - INTERCEPT DAN GANTI ID
local function InitializeRemoteHook()
    remoteEvent = GetRemoteEvent()
    
    if not remoteEvent then
        StatusLabel.Text = "❌ RemoteEvent tidak ditemukan!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        return false
    end
    
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not hookEnabled then
            return oldNamecall(self, ...)
        end
        
        local args = {...}
        local method = getnamecallmethod()
        
        -- Intercept FireServer calls
        if self == remoteEvent and method == "FireServer" then
            if #args >= 2 then
                local action = args[1]
                local id = args[2]
                
                -- Jika action adalah "BuyWing" dan id adalah angka
                if action == "BuyWing" and type(id) == "number" and id > 0 then
                    -- AUTO-DETECT: Jika ID berbeda dari baseWingID, update base
                    if autoDetect and id ~= baseWingID then
                        baseWingID = id
                        IdBox.Text = tostring(baseWingID)
                        currentWingID = baseWingID + 1 -- Reset current ke base+1
                        DetailLabel.Text = "Base: " .. baseWingID .. " | Mulai dari: " .. (baseWingID + 1) .. " | Delay: " .. delayTime .. "s"
                        CurrentIdLabel.Text = "ID Sekarang: " .. currentWingID
                        StatusLabel.Text = "🎯 Base ID terdeteksi: " .. baseWingID .. " ➜ Mulai dari: " .. (baseWingID + 1)
                        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    end
                    
                    -- Ganti dengan currentWingID (base + iterasi)
                    -- currentWingID sudah di-update di loop
                    local newArgs = {"BuyWing", currentWingID}
                    return oldNamecall(self, unpack(newArgs))
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
    
    StatusLabel.Text = "✅ Hook aktif. Menunggu FireServer..."
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
        StatusLabel.Text = "✅ Auto detect aktif"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        AutoDetectButton.Text = "Auto: OFF"
        AutoDetectButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        UnhookRemote()
        StatusLabel.Text = "⛔ Auto detect nonaktif"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
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
    StatusLabel.Text = "⏳ Mencoba mendeteksi base wing ID..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
    
    local tempEvent = GetRemoteEvent()
    if tempEvent then
        pcall(function()
            -- Coba beberapa ID umum
            local testIDs = {13000001, 13000002, 13000003, 13000004, 13000005, 13000006, 13000007, 13000008}
            for _, id in ipairs(testIDs) do
                if not running then
                    tempEvent:FireServer("BuyWing", id)
                    task.wait(0.15)
                end
            end
        end)
    end
    
    if baseWingID == 13000001 then
        StatusLabel.Text = "❌ Tidak ada ID terdeteksi. Masukkan manual."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    else
        currentWingID = baseWingID + 1
        CurrentIdLabel.Text = "ID Sekarang: " .. currentWingID
        DetailLabel.Text = "Base: " .. baseWingID .. " | Mulai dari: " .. (baseWingID + 1) .. " | Delay: " .. delayTime .. "s"
    end
end)

DetectNowButton.MouseEnter:Connect(function()
    DetectNowButton.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
end)

DetectNowButton.MouseLeave:Connect(function()
    DetectNowButton.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
end)

--// Function to send purchase dengan ID berurutan
local function SendPurchase(step)
    remoteEvent = GetRemoteEvent()
    if not remoteEvent then
        UpdateStatus("❌ RemoteEvent tidak ditemukan!", Color3.fromRGB(255, 0, 0))
        return false
    end
    
    -- Hitung ID untuk step ini: baseWingID + step
    local sendID = baseWingID + step
    currentWingID = sendID
    
    local success, result = pcall(function()
        return remoteEvent:FireServer("BuyWing", sendID)
    end)
    
    if not success then
        UpdateStatus("❌ Error pada ID " .. sendID .. ": " .. tostring(result), Color3.fromRGB(255, 0, 0))
        return false
    end
    return true
end

--// Main loop
local function RunLoop()
    local totalCount = purchaseCount
    local successCount = 0
    local failCount = 0
    
    -- Reset current ID ke base+1
    currentWingID = baseWingID + 1
    
    ProgressLabel.Text = "Progress: 0/" .. totalCount
    DetailLabel.Text = "Base: " .. baseWingID .. " | Mulai dari: " .. (baseWingID + 1) .. " | Delay: " .. delayTime .. "s"
    CurrentIdLabel.Text = "ID Sekarang: " .. currentWingID
    CurrentIdLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
    
    UpdateStatus(string.format("▶️ Memulai dari ID: %d", baseWingID + 1), Color3.fromRGB(255, 255, 0))
    
    for step = 1, totalCount do
        if not running then
            break
        end
        
        -- Kirim dengan ID = baseWingID + step
        local success = SendPurchase(step)
        
        if success then
            successCount = successCount + 1
            local sentID = baseWingID + step
            CurrentIdLabel.Text = "ID Terkirim: " .. sentID
            CurrentIdLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            ProgressLabel.Text = string.format("Progress: %d/%d (✓ %d | ✗ %d) - ID: %d", 
                step, totalCount, successCount, failCount, sentID)
            ProgressLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            failCount = failCount + 1
            ProgressLabel.Text = string.format("Progress: %d/%d (✓ %d | ✗ %d)", 
                step, totalCount, successCount, failCount)
            ProgressLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
        
        -- Update status
        local nextID = baseWingID + step + 1
        if step < totalCount then
            UpdateStatus(string.format("▶️ %d/%d - ID: %d ➜ Selanjutnya: %d", 
                step, totalCount, baseWingID + step, nextID), Color3.fromRGB(255, 255, 0))
        else
            UpdateStatus(string.format("▶️ %d/%d - ID: %d (Terakhir)", 
                step, totalCount, baseWingID + step), Color3.fromRGB(255, 255, 0))
        end
        
        -- Delay sebelum next
        if step < totalCount and running then
            task.wait(delayTime)
        end
    end
    
    -- Jika loop selesai dan masih running
    if running then
        UpdateStatus("✅ Selesai! " .. successCount .. " berhasil dari " .. totalCount .. 
            " | ID Terakhir: " .. (baseWingID + totalCount), Color3.fromRGB(0, 255, 0))
        ProgressLabel.Text = string.format("Selesai: %d/%d (✓ %d | ✗ %d) | ID Terakhir: %d", 
            totalCount, totalCount, successCount, failCount, baseWingID + totalCount)
        running = false
        StartStopButton.Text = "Start"
        StartStopButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    end
end

--// Start/Stop button
StartStopButton.MouseButton1Click:Connect(function()
    running = not running
    
    if running then
        -- Validasi count
        if purchaseCount <= 0 then
            StatusLabel.Text = "⚠️ Jumlah pembelian harus > 0!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
            running = false
            return
        end
        
        -- Validasi base wing ID
        if baseWingID <= 0 then
            StatusLabel.Text = "⚠️ Base Wing ID tidak valid!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
            running = false
            return
        end
        
        StartStopButton.Text = "Stop"
        StartStopButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        
        local startID = baseWingID + 1
        local endID = baseWingID + purchaseCount
        UpdateStatus(string.format("▶️ Running: %d ➜ %d (%d ID)", startID, endID, purchaseCount), 
            Color3.fromRGB(0, 255, 0))
        
        -- Jalankan loop di coroutine
        coroutineLoop = coroutine.wrap(RunLoop)
        coroutineLoop()
    else
        StartStopButton.Text = "Start"
        StartStopButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        UpdateStatus("⏹️ Stopped", Color3.fromRGB(255, 255, 0))
    end
end)

-- Button hover effects
StartStopButton.MouseEnter:Connect(function()
    if running then
        StartStopButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    else
        StartStopButton.BackgroundColor3 = Color3.fromRGB(60, 220, 60)
    end
end)

StartStopButton.MouseLeave:Connect(function()
    if running then
        StartStopButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    else
        StartStopButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
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
        Size = UDim2.new(0, 380, 0, 180),
        Position = UDim2.new(0.5, -190, 0.5, -90)
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

--// Wing ID Box Input
IdBox.FocusLost:Connect(function(enterPressed)
    local newId = tonumber(IdBox.Text)
    if newId and newId > 0 then
        baseWingID = newId
        currentWingID = baseWingID + 1
        IdBox.Text = tostring(baseWingID)
        DetailLabel.Text = "Base: " .. baseWingID .. " | Mulai dari: " .. (baseWingID + 1) .. " | Delay: " .. delayTime .. "s"
        CurrentIdLabel.Text = "ID Sekarang: " .. currentWingID
        UpdateStatus(string.format("✅ Base ID: %d ➜ Mulai dari: %d", baseWingID, baseWingID + 1), 
            Color3.fromRGB(0, 255, 0))
    else
        IdBox.Text = tostring(baseWingID)
        UpdateStatus("⚠️ ID tidak valid, dikembalikan ke: " .. baseWingID, Color3.fromRGB(255, 165, 0))
    end
end)

-- Delay Box Input
DelayBox.FocusLost:Connect(function(enterPressed)
    local newDelay = tonumber(DelayBox.Text)
    if newDelay and newDelay > 0 then
        delayTime = newDelay
        DetailLabel.Text = "Base: " .. baseWingID .. " | Mulai dari: " .. (baseWingID + 1) .. " | Delay: " .. delayTime .. "s"
        UpdateStatus("✅ Delay diatur ke: " .. delayTime .. "s", Color3.fromRGB(0, 255, 0))
    else
        DelayBox.Text = tostring(delayTime)
        UpdateStatus("⚠️ Delay tidak valid, dikembalikan ke: " .. delayTime, Color3.fromRGB(255, 165, 0))
    end
end)

--// Initialize
UpdateCountButtons(100) -- Default 100
currentWingID = baseWingID + 1
CurrentIdLabel.Text = "ID Sekarang: " .. currentWingID
DetailLabel.Text = "Base: " .. baseWingID .. " | Mulai dari: " .. (baseWingID + 1) .. " | Delay: " .. delayTime .. "s"

local initSuccess = InitializeRemoteHook()

if initSuccess then
    UpdateStatus("✅ Script siap. Auto detect aktif.", Color3.fromRGB(0, 255, 0))
else
    UpdateStatus("⚠️ Auto detect gagal. Gunakan ID manual.", Color3.fromRGB(255, 165, 0))
end

print("🚀 Wing Purchase Script Loaded (Sequential ID)")
print("📌 Base Wing ID: " .. baseWingID)
print("📌 Mulai dari ID: " .. (baseWingID + 1))
print("📌 Default Count: " .. purchaseCount .. "x")
print("📌 Default Delay: " .. delayTime .. "s")
