--[[
    AUTO COIN V3 - Separate Controls & Monitor
    Tombol dan Monitor terpisah untuk kontrol yang lebih baik
--]]

------ SERVICES ------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

------ KONSTANTA ------
local PAUSE_INTERVAL = 60 * 60
local PAUSE_DURATION = 30
local WIN_DELAY_BASE = 10000
local DEFAULT_HEIGHT = 5000
local DEFAULT_DELAY = 5
local HEIGHT_MULTIPLIER = 2.8
local MAX_HEIGHT = 14400

------ STATE MANAGEMENT ------
local State = {
    jumpID = nil,
    landingID = nil,
    winID = nil,
    magicTokenID = nil,
    isReady = false,
    running = false,
    autoWinEnabled = false,
    autoTokenEnabled = false,
    runTime = 0,
    lastLoopTime = 0,
    nextLoopTime = 0,
    lastWinTime = 0,
    hookEnabled = true,
    climbSpeed = 0,
    climbing = false,
    climbStartY = 0,
    climbStartTime = 0,
    maxY = 0,
    lockDelay = false,
    currentDelay = DEFAULT_DELAY,
    currentHeight = DEFAULT_HEIGHT
}

------ FUNGSI UTILITY ------
local function GetWinDelay()
    return State.climbSpeed > 0 and (WIN_DELAY_BASE / State.climbSpeed) or 20
end

local function CalculateHeight(speed, delay)
    local calculatedHeight = math.floor((speed * HEIGHT_MULTIPLIER) * delay)
    return math.min(calculatedHeight, MAX_HEIGHT)
end

local function GetAutoTokenDelay(speed)
    if speed > 0 then
        return math.floor((10000 / speed) * 10) / 10
    end
    return DEFAULT_DELAY
end

------ FUNGSI REMOTE EVENT ------
local function SendRemoteEvent(eventName, ...)
    local args = {eventName, ...}
    ReplicatedStorage:WaitForChild("ProMgs"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end

local function SendJumpData(jumpID, height)
    if jumpID then
        SendRemoteEvent("JumpResults", jumpID, height)
    end
end

local function SendLandingData(landingID)
    if landingID then
        SendRemoteEvent("LandingResults", landingID)
    end
end

local function SendWinData(winID)
    if winID then
        SendRemoteEvent("ClaimRooftopWinsReward", winID)
        State.lastWinTime = os.time()
    end
end

local function SendTokenData(magicTokenID)
    if magicTokenID then
        SendRemoteEvent("ClaimRooftopMagicToken", magicTokenID)
    end
end

------ FUNGSI CORE LOGIC ------
local function ProcessCoinActions()
    local height = CalculateHeight(State.climbSpeed, State.currentDelay)
    SendJumpData(State.jumpID, height)
    SendLandingData(State.landingID)
end

local function ProcessAutoToken()
    if State.autoTokenEnabled and State.magicTokenID then
        local tokenTime = State.lastLoopTime + (State.currentDelay / 2)
        while os.time() < tokenTime and State.running and State.hookEnabled do
            task.wait(0.1)
        end
        if State.running and State.hookEnabled then
            SendTokenData(State.magicTokenID)
        end
    end
end

local function ProcessAutoWin()
    local currentWinDelay = GetWinDelay()
    if State.autoWinEnabled and os.time() - State.lastWinTime >= currentWinDelay then
        SendWinData(State.winID)
    end
end

local function HandleAutoPause()
    State.runTime = State.runTime + (os.time() - State.lastLoopTime)
    if State.runTime >= PAUSE_INTERVAL then
        State.running = false
        task.wait(PAUSE_DURATION)
        State.runTime = 0
        State.running = true
        return true
    end
    return false
end

local function RunLoop()
    while State.running and State.hookEnabled do
        if State.autoTokenEnabled and State.climbSpeed > 0 and not State.lockDelay then
            State.currentDelay = GetAutoTokenDelay(State.climbSpeed)
            UpdateMonitor()
        end
        
        State.lastLoopTime = os.time()
        State.nextLoopTime = State.lastLoopTime + State.currentDelay
        
        ProcessAutoToken()
        ProcessAutoWin()
        
        while os.time() < State.nextLoopTime and State.running and State.hookEnabled do
            local remaining = State.nextLoopTime - os.time()
            UpdateMonitor()
            task.wait(0.1)
        end
        
        if not State.running or not State.hookEnabled then break end
        
        ProcessCoinActions()
        
        if HandleAutoPause() then
            break
        end
    end
    
    if State.hookEnabled then
        UpdateMonitor()
    end
end

------ FUNGSI CLIMB SPEED ------
local function TrackClimbingState(char)
    local humanoid = char:WaitForChild("Humanoid")
    
    humanoid.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Climbing then
            State.climbStartY = char:WaitForChild("HumanoidRootPart").Position.Y
            State.climbStartTime = tick()
            State.maxY = State.climbStartY
            State.climbing = true
        else
            if State.climbing then
                local climbEndY = State.maxY
                local climbEndTime = tick()
                local totalY = climbEndY - State.climbStartY
                local totalTime = climbEndTime - State.climbStartTime
                
                if totalY > 0 and totalTime > 0 then
                    State.climbSpeed = totalY / totalTime
                    if not State.lockDelay then
                        State.currentHeight = CalculateHeight(State.climbSpeed, State.currentDelay)
                        if State.autoTokenEnabled then
                            State.currentDelay = GetAutoTokenDelay(State.climbSpeed)
                        end
                        UpdateMonitor()
                    end
                end
                State.climbing = false
            end
        end
    end)
    
    RunService.Heartbeat:Connect(function()
        if State.climbing and char:FindFirstChild("HumanoidRootPart") then
            local y = char.HumanoidRootPart.Position.Y
            if y > State.maxY then
                State.maxY = y
            end
        end
    end)
end

------ FUNGSI REMOTE HOOK ------
local function InitializeRemoteHook()
    local remoteEvent = ReplicatedStorage:WaitForChild("ProMgs"):WaitForChild("RemoteEvent")
    local oldNamecall
    
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not State.hookEnabled then
            return oldNamecall(self, ...)
        end
        
        local args = {...}
        local method = getnamecallmethod()

        if self == remoteEvent and method == "FireServer" then
            local eventType = args[1]
            local eventID = args[2]
            
            if typeof(eventID) == "number" then
                if eventType == "JumpResults" then
                    State.jumpID = eventID
                elseif eventType == "LandingResults" then
                    State.landingID = eventID
                elseif eventType == "ClaimRooftopWinsReward" then
                    State.winID = eventID
                elseif eventType == "ClaimRooftopMagicToken" then
                    State.magicTokenID = eventID
                end
                UpdateMonitor()
            end
        end

        return oldNamecall(self, ...)
    end)
end

------ FUNGSI GUI - MONITOR ------
local function CreateMonitor()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    if playerGui:FindFirstChild("CoinMonitor") then
        playerGui:FindFirstChild("CoinMonitor"):Destroy()
    end

    local MonitorGui = Instance.new("ScreenGui")
    MonitorGui.Name = "CoinMonitor"
    MonitorGui.Parent = playerGui
    MonitorGui.ResetOnSpawn = false
    MonitorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MonitorFrame = Instance.new("Frame")
    MonitorFrame.Size = UDim2.new(0, 250, 0, 180)
    MonitorFrame.Position = UDim2.new(0, 10, 0, 10)
    MonitorFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MonitorFrame.BackgroundTransparency = 0.15
    MonitorFrame.BorderSizePixel = 0
    MonitorFrame.Parent = MonitorGui
    MonitorFrame.Draggable = true
    MonitorFrame.Active = true

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = MonitorFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MonitorFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10, 0, 0)
    TitleCorner.Parent = TitleBar

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0.7, 0, 1, 0)
    TitleText.Position = UDim2.new(0.15, 0, 0, 0)
    TitleText.Text = "📊 COIN MONITOR"
    TitleText.TextColor3 = Color3.new(1, 1, 1)
    TitleText.BackgroundTransparency = 1
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 14
    TitleText.Parent = TitleBar

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 1, -40)
    Content.Position = UDim2.new(0, 10, 0, 35)
    Content.BackgroundTransparency = 1
    Content.Parent = MonitorFrame

    -- Status Bar
    local StatusBar = Instance.new("Frame")
    StatusBar.Size = UDim2.new(1, 0, 0, 25)
    StatusBar.Position = UDim2.new(0, 0, 0, 0)
    StatusBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    StatusBar.BorderSizePixel = 0
    StatusBar.Parent = Content

    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 6)
    StatusCorner.Parent = StatusBar

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 1, 0)
    StatusLabel.Text = "Coin[○] Win[○] Token[○]"
    StatusLabel.TextColor3 = Color3.new(1, 1, 1)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 12
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Parent = StatusBar

    -- Speed & Info
    local InfoFrame = Instance.new("Frame")
    InfoFrame.Size = UDim2.new(1, 0, 0, 50)
    InfoFrame.Position = UDim2.new(0, 0, 0, 30)
    InfoFrame.BackgroundTransparency = 1
    InfoFrame.Parent = Content

    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(0.5, 0, 0, 20)
    SpeedLabel.Position = UDim2.new(0, 0, 0, 0)
    SpeedLabel.Text = "Speed: 0.0"
    SpeedLabel.TextColor3 = Color3.new(1, 1, 1)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Font = Enum.Font.Gotham
    SpeedLabel.TextSize = 12
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = InfoFrame

    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(0.5, 0, 0, 20)
    DelayLabel.Position = UDim2.new(0.5, 0, 0, 0)
    DelayLabel.Text = "Delay: 5.0s"
    DelayLabel.TextColor3 = Color3.new(1, 1, 1)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Font = Enum.Font.Gotham
    DelayLabel.TextSize = 12
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = InfoFrame

    local HeightLabel = Instance.new("TextLabel")
    HeightLabel.Size = UDim2.new(0.5, 0, 0, 20)
    HeightLabel.Position = UDim2.new(0, 0, 0, 22)
    HeightLabel.Text = "Height: 5000"
    HeightLabel.TextColor3 = Color3.new(1, 1, 1)
    HeightLabel.BackgroundTransparency = 1
    HeightLabel.Font = Enum.Font.Gotham
    HeightLabel.TextSize = 12
    HeightLabel.TextXAlignment = Enum.TextXAlignment.Left
    HeightLabel.Parent = InfoFrame

    local WinDelayLabel = Instance.new("TextLabel")
    WinDelayLabel.Size = UDim2.new(0.5, 0, 0, 20)
    WinDelayLabel.Position = UDim2.new(0.5, 0, 0, 22)
    WinDelayLabel.Text = "Win Delay: 20.0s"
    WinDelayLabel.TextColor3 = Color3.new(1, 1, 1)
    WinDelayLabel.BackgroundTransparency = 1
    WinDelayLabel.Font = Enum.Font.Gotham
    WinDelayLabel.TextSize = 12
    WinDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    WinDelayLabel.Parent = InfoFrame

    -- Running Status
    local RunStatus = Instance.new("TextLabel")
    RunStatus.Size = UDim2.new(1, 0, 0, 20)
    RunStatus.Position = UDim2.new(0, 0, 0, 85)
    RunStatus.Text = "⏸️ STOPPED"
    RunStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
    RunStatus.BackgroundTransparency = 1
    RunStatus.Font = Enum.Font.GothamBold
    RunStatus.TextSize = 13
    RunStatus.TextXAlignment = Enum.TextXAlignment.Center
    RunStatus.Parent = Content

    -- Progress Bar
    local ProgressFrame = Instance.new("Frame")
    ProgressFrame.Size = UDim2.new(1, 0, 0, 10)
    ProgressFrame.Position = UDim2.new(0, 0, 0, 110)
    ProgressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    ProgressFrame.BorderSizePixel = 0
    ProgressFrame.Parent = Content

    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(0, 5)
    ProgressCorner.Parent = ProgressFrame

    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = ProgressFrame

    local ProgressCorner2 = Instance.new("UICorner")
    ProgressCorner2.CornerRadius = UDim.new(0, 5)
    ProgressCorner2.Parent = ProgressBar

    return {
        MonitorGui = MonitorGui,
        StatusLabel = StatusLabel,
        SpeedLabel = SpeedLabel,
        DelayLabel = DelayLabel,
        HeightLabel = HeightLabel,
        WinDelayLabel = WinDelayLabel,
        RunStatus = RunStatus,
        ProgressBar = ProgressBar
    }
end

------ FUNGSI GUI - KONTROL ------
local function CreateControls()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    if playerGui:FindFirstChild("CoinControls") then
        playerGui:FindFirstChild("CoinControls"):Destroy()
    end

    local ControlGui = Instance.new("ScreenGui")
    ControlGui.Name = "CoinControls"
    ControlGui.Parent = playerGui
    ControlGui.ResetOnSpawn = false
    ControlGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local ControlFrame = Instance.new("Frame")
    ControlFrame.Size = UDim2.new(0, 220, 0, 280)
    ControlFrame.Position = UDim2.new(1, -230, 0, 10)
    ControlFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    ControlFrame.BackgroundTransparency = 0.1
    ControlFrame.BorderSizePixel = 0
    ControlFrame.Parent = ControlGui
    ControlFrame.Draggable = true
    ControlFrame.Active = true

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = ControlFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = ControlFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10, 0, 0)
    TitleCorner.Parent = TitleBar

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0.7, 0, 1, 0)
    TitleText.Position = UDim2.new(0.15, 0, 0, 0)
    TitleText.Text = "🎮 COIN CONTROLS"
    TitleText.TextColor3 = Color3.new(1, 1, 1)
    TitleText.BackgroundTransparency = 1
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 13
    TitleText.Parent = TitleBar

    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 25, 0, 25)
    CloseButton.Position = UDim2.new(1, -25, 0, 0)
    CloseButton.Text = "×"
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 16
    CloseButton.TextColor3 = Color3.new(1, 1, 1)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseButton

    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 1, -40)
    Content.Position = UDim2.new(0, 10, 0, 35)
    Content.BackgroundTransparency = 1
    Content.Parent = ControlFrame

    -- Start/Stop Button
    local MainButton = Instance.new("TextButton")
    MainButton.Size = UDim2.new(1, 0, 0, 35)
    MainButton.Position = UDim2.new(0, 0, 0, 0)
    MainButton.Text = "▶ START"
    MainButton.Font = Enum.Font.GothamBold
    MainButton.TextSize = 14
    MainButton.TextColor3 = Color3.new(1, 1, 1)
    MainButton.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
    MainButton.Parent = Content

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainButton

    -- Toggle Buttons Frame
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 70)
    ToggleFrame.Position = UDim2.new(0, 0, 0, 45)
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Parent = Content

    -- Auto Win Toggle
    local WinButton = Instance.new("TextButton")
    WinButton.Size = UDim2.new(0.48, 0, 0, 30)
    WinButton.Position = UDim2.new(0, 0, 0, 0)
    WinButton.Text = "🏆 WIN OFF"
    WinButton.Font = Enum.Font.Gotham
    WinButton.TextSize = 11
    WinButton.TextColor3 = Color3.new(1, 1, 1)
    WinButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    WinButton.Parent = ToggleFrame

    local WinCorner = Instance.new("UICorner")
    WinCorner.CornerRadius = UDim.new(0, 6)
    WinCorner.Parent = WinButton

    -- Auto Token Toggle
    local TokenButton = Instance.new("TextButton")
    TokenButton.Size = UDim2.new(0.48, 0, 0, 30)
    TokenButton.Position = UDim2.new(0.52, 0, 0, 0)
    TokenButton.Text = "🔮 TOKEN OFF"
    TokenButton.Font = Enum.Font.Gotham
    TokenButton.TextSize = 11
    TokenButton.TextColor3 = Color3.new(1, 1, 1)
    TokenButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    TokenButton.Parent = ToggleFrame

    local TokenCorner = Instance.new("UICorner")
    TokenCorner.CornerRadius = UDim.new(0, 6)
    TokenCorner.Parent = TokenButton

    -- Lock Delay Toggle
    local LockButton = Instance.new("TextButton")
    LockButton.Size = UDim2.new(0.48, 0, 0, 30)
    LockButton.Position = UDim2.new(0, 0, 0, 35)
    LockButton.Text = "🔒 DELAY UNLOCKED"
    LockButton.Font = Enum.Font.Gotham
    LockButton.TextSize = 11
    LockButton.TextColor3 = Color3.new(1, 1, 1)
    LockButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    LockButton.Parent = ToggleFrame

    local LockCorner = Instance.new("UICorner")
    LockCorner.CornerRadius = UDim.new(0, 6)
    LockCorner.Parent = LockButton

    -- Input Frame
    local InputFrame = Instance.new("Frame")
    InputFrame.Size = UDim2.new(1, 0, 0, 75)
    InputFrame.Position = UDim2.new(0, 0, 0, 120)
    InputFrame.BackgroundTransparency = 1
    InputFrame.Parent = Content

    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(0.35, 0, 0, 20)
    DelayLabel.Position = UDim2.new(0, 0, 0, 0)
    DelayLabel.Text = "Delay (s):"
    DelayLabel.TextColor3 = Color3.new(1, 1, 1)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Font = Enum.Font.Gotham
    DelayLabel.TextSize = 11
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = InputFrame

    local DelayBox = Instance.new("TextBox")
    DelayBox.Size = UDim2.new(0.6, 0, 0, 20)
    DelayBox.Position = UDim2.new(0.4, 0, 0, 0)
    DelayBox.Text = tostring(DEFAULT_DELAY)
    DelayBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    DelayBox.TextColor3 = Color3.new(1, 1, 1)
    DelayBox.Font = Enum.Font.Gotham
    DelayBox.TextSize = 11
    DelayBox.Parent = InputFrame

    local DelayCorner = Instance.new("UICorner")
    DelayCorner.CornerRadius = UDim.new(0, 4)
    DelayCorner.Parent = DelayBox

    local HeightLabel = Instance.new("TextLabel")
    HeightLabel.Size = UDim2.new(0.35, 0, 0, 20)
    HeightLabel.Position = UDim2.new(0, 0, 0, 25)
    HeightLabel.Text = "Height:"
    HeightLabel.TextColor3 = Color3.new(1, 1, 1)
    HeightLabel.BackgroundTransparency = 1
    HeightLabel.Font = Enum.Font.Gotham
    HeightLabel.TextSize = 11
    HeightLabel.TextXAlignment = Enum.TextXAlignment.Left
    HeightLabel.Parent = InputFrame

    local HeightBox = Instance.new("TextBox")
    HeightBox.Size = UDim2.new(0.6, 0, 0, 20)
    HeightBox.Position = UDim2.new(0.4, 0, 0, 25)
    HeightBox.Text = tostring(DEFAULT_HEIGHT)
    HeightBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    HeightBox.TextColor3 = Color3.new(1, 1, 1)
    HeightBox.Font = Enum.Font.Gotham
    HeightBox.TextSize = 11
    HeightBox.Parent = InputFrame

    local HeightCorner = Instance.new("UICorner")
    HeightCorner.CornerRadius = UDim.new(0, 4)
    HeightCorner.Parent = HeightBox

    -- Speed Button (Reset)
    local SpeedButton = Instance.new("TextButton")
    SpeedButton.Size = UDim2.new(1, 0, 0, 20)
    SpeedButton.Position = UDim2.new(0, 0, 0, 50)
    SpeedButton.Text = "🔄 Reset Speed"
    SpeedButton.Font = Enum.Font.Gotham
    SpeedButton.TextSize = 11
    SpeedButton.TextColor3 = Color3.new(1, 1, 1)
    SpeedButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    SpeedButton.Parent = InputFrame

    local SpeedCorner = Instance.new("UICorner")
    SpeedCorner.CornerRadius = UDim.new(0, 4)
    SpeedCorner.Parent = SpeedButton

    return {
        ControlGui = ControlGui,
        MainButton = MainButton,
        WinButton = WinButton,
        TokenButton = TokenButton,
        LockButton = LockButton,
        DelayBox = DelayBox,
        HeightBox = HeightBox,
        SpeedButton = SpeedButton,
        CloseButton = CloseButton
    }
end

------ FUNGSI UPDATE MONITOR ------
local Monitor = nil
local Controls = nil

function UpdateMonitor()
    if not Monitor then return end
    
    local coinIcon = State.jumpID and State.landingID and "●" or "○"
    local winIcon = State.winID and "●" or "○"
    local tokenIcon = State.magicTokenID and "●" or "○"
    
    Monitor.StatusLabel.Text = string.format("Coin[%s] Win[%s] Token[%s]", coinIcon, winIcon, tokenIcon)
    Monitor.SpeedLabel.Text = string.format("Speed: %.1f", State.climbSpeed)
    Monitor.DelayLabel.Text = string.format("Delay: %.1fs", State.currentDelay)
    Monitor.HeightLabel.Text = string.format("Height: %d", State.currentHeight)
    Monitor.WinDelayLabel.Text = string.format("Win Delay: %.1fs", GetWinDelay())
    
    if State.running then
        Monitor.RunStatus.Text = "▶ RUNNING"
        Monitor.RunStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
        local progress = (State.lastLoopTime > 0) and ((os.time() - State.lastLoopTime) / State.currentDelay) or 0
        Monitor.ProgressBar.Size = UDim2.new(math.min(progress, 1), 0, 1, 0)
    else
        Monitor.RunStatus.Text = "⏸️ STOPPED"
        Monitor.RunStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
        Monitor.ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    end
    
    if State.isReady then
        Controls.MainButton.BackgroundColor3 = State.running and Color3.fromRGB(0, 200, 50) or Color3.fromRGB(0, 150, 50)
    else
        Controls.MainButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end
end

------ FUNGSI EVENT HANDLER ------
function SetupEventHandlers()
    -- Start/Stop Button
    Controls.MainButton.MouseButton1Click:Connect(function()
        if State.isReady then
            State.running = not State.running
            Controls.MainButton.Text = State.running and "⏹ STOP" or "▶ START"
            if State.running then
                State.lastWinTime = os.time()
                coroutine.wrap(RunLoop)()
            end
            UpdateMonitor()
        end
    end)

    -- Auto Win Toggle
    Controls.WinButton.MouseButton1Click:Connect(function()
        if State.winID then
            State.autoWinEnabled = not State.autoWinEnabled
            Controls.WinButton.Text = State.autoWinEnabled and "🏆 WIN ON" or "🏆 WIN OFF"
            Controls.WinButton.BackgroundColor3 = State.autoWinEnabled and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(60, 60, 70)
            if State.autoWinEnabled then
                State.lastWinTime = os.time()
            end
            UpdateMonitor()
        end
    end)

    -- Auto Token Toggle
    Controls.TokenButton.MouseButton1Click:Connect(function()
        if State.magicTokenID then
            State.autoTokenEnabled = not State.autoTokenEnabled
            Controls.TokenButton.Text = State.autoTokenEnabled and "🔮 TOKEN ON" or "🔮 TOKEN OFF"
            Controls.TokenButton.BackgroundColor3 = State.autoTokenEnabled and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(60, 60, 70)
            if State.autoTokenEnabled and State.climbSpeed > 0 and not State.lockDelay then
                State.currentDelay = GetAutoTokenDelay(State.climbSpeed)
                Controls.DelayBox.Text = string.format("%.1f", State.currentDelay)
                UpdateMonitor()
            end
        end
    end)

    -- Lock Delay Toggle
    Controls.LockButton.MouseButton1Click:Connect(function()
        State.lockDelay = not State.lockDelay
        Controls.LockButton.Text = State.lockDelay and "🔒 DELAY LOCKED" or "🔒 DELAY UNLOCKED"
        Controls.LockButton.BackgroundColor3 = State.lockDelay and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(60, 60, 70)
        Controls.DelayBox.TextEditable = not State.lockDelay
        Controls.DelayBox.BackgroundColor3 = State.lockDelay and Color3.fromRGB(60, 60, 70) or Color3.fromRGB(40, 40, 45)
        UpdateMonitor()
    end)

    -- Delay Box Change
    Controls.DelayBox:GetPropertyChangedSignal("Text"):Connect(function()
        if not State.lockDelay then
            local newDelay = tonumber(Controls.DelayBox.Text) or DEFAULT_DELAY
            State.currentDelay = newDelay
            if State.climbSpeed > 0 then
                State.currentHeight = CalculateHeight(State.climbSpeed, newDelay)
                Controls.HeightBox.Text = tostring(State.currentHeight)
            end
            UpdateMonitor()
        end
    end)

    -- Height Box Change
    Controls.HeightBox:GetPropertyChangedSignal("Text"):Connect(function()
        local newHeight = tonumber(Controls.HeightBox.Text) or DEFAULT_HEIGHT
        State.currentHeight = math.min(newHeight, MAX_HEIGHT)
        UpdateMonitor()
    end)

    -- Reset Speed Button
    Controls.SpeedButton.MouseButton1Click:Connect(function()
        State.climbSpeed = 0
        State.climbing = false
        UpdateMonitor()
    end)

    -- Close Button
    Controls.CloseButton.MouseButton1Click:Connect(function()
        State.hookEnabled = false
        Controls.ControlGui:Destroy()
        if Monitor and Monitor.MonitorGui then
            Monitor.MonitorGui:Destroy()
        end
    end)

    -- Keyboard Shortcut: Space to Start/Stop
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Space then
            Controls.MainButton:Click()
        end
    end)
end

------ FUNGSI INISIALISASI ------
function InitializeAll()
    -- Buat GUI
    Monitor = CreateMonitor()
    Controls = CreateControls()
    
    -- Setup event handlers
    SetupEventHandlers()
    
    -- Initialize remote hook
    InitializeRemoteHook()
    
    -- Setup character detection
    local LocalPlayer = Players.LocalPlayer
    if LocalPlayer.Character then
        TrackClimbingState(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(TrackClimbingState)
    
    -- Update monitor pertama
    UpdateMonitor()
    
    print("Auto Coin V3 - Separate Controls & Monitor Loaded!")
    print("Shortcut: Space to Start/Stop")
end

-- Jalankan
InitializeAll()
