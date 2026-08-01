--[[
    AUTO COIN V4
--]]

------ SERVICES ------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

------ THEME (iOS Compact Style) ------
local THEME = {
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
    ledGreen = Color3.fromRGB(52, 199, 89),
    ledRed = Color3.fromRGB(255, 59, 48),
}

------ CONSTANTS ------
local PAUSE_INTERVAL = 60 * 60
local PAUSE_DURATION = 30
local WIN_DELAY_BASE = 10000
local TOKEN_DELAY_BASE = 10000
local DEFAULT_HEIGHT = 5000
local DEFAULT_DELAY = 5
local HEIGHT_MULTIPLIER = 2.8
local MAX_HEIGHT = 14400
local MIN_CLIMB_DURATION = 2

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
    lockSpeed = false,
    tokenClaimed = false,
    tokenClaimTime = 0,
    coinDelay = DEFAULT_DELAY,      -- ABSOLUT dari user input
    currentTokenDelay = 0,          -- Untuk display cooldown token
    currentWinDelay = 0,            -- Untuk display cooldown win
    runTime = 0,
    lastLoopTime = 0,
    nextLoopTime = 0,
    lastWinTime = 0,
    hookEnabled = true,
    minimized = false,
    climbSpeed = 0,
    climbing = false,
    climbStartY = 0,
    climbStartTime = 0,
    maxY = 0,
}

------ UTILITY FUNCTIONS ------
local function GetWinDelay()
    if State.autoWinEnabled and State.climbSpeed > 0 then
        return math.floor((WIN_DELAY_BASE / State.climbSpeed) * 10) / 10
    end
    return 0
end

local function GetTokenDelay()
    if State.autoTokenEnabled and State.climbSpeed > 0 then
        return math.floor((TOKEN_DELAY_BASE / State.climbSpeed) * 10) / 10
    end
    return 0
end

-- Height = f(Speed, Delay) - SATU ARAH
local function CalculateHeight()
    local delay = State.coinDelay  -- ← HANYA BACA
    local calculatedHeight = math.floor((State.climbSpeed * HEIGHT_MULTIPLIER) * delay)
    return math.min(calculatedHeight, MAX_HEIGHT)
end

local function UpdateHeight()
    if State.climbSpeed > 0 then
        GUI.HeightLabel.Text = string.format("Height: %d", CalculateHeight())
    end
end

------ UPDATE DELAYS (HANYA BACA DARI INPUT) ------
local function UpdateDelays()
    -- HANYA baca dari input, tidak ada yang mengubah selain user
    local input = tonumber(GUI.DelayTextBox.Text)
    if input and input > 0 then
        State.coinDelay = input
    else
        State.coinDelay = DEFAULT_DELAY
        GUI.DelayTextBox.Text = string.format("%.1f", DEFAULT_DELAY)
    end
    
    -- Hitung delay untuk display cooldown saja (TIDAK mempengaruhi coinDelay)
    State.currentTokenDelay = GetTokenDelay()
    State.currentWinDelay = GetWinDelay()
    
    -- Update display height
    if State.climbSpeed > 0 then
        UpdateHeight()
    end
end

------ IOS SWITCH COMPONENT ------
local function CreateiOSSwitch(parent, position, initialState, labelText)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 10)
    container.Position = position
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = labelText
    label.TextColor3 = THEME.textPrimary
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, 18, 0, 10)
    track.Position = UDim2.new(1, -18, 0.5, -5)
    track.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    track.BackgroundTransparency = 0
    track.BorderSizePixel = 0
    track.AutoButtonColor = false
    track.Text = ""
    track.Parent = container
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 5)
    trackCorner.Parent = track
    
    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 9, 0, 9)
    knob.Position = UDim2.new(0, 0.5, 0.5, -4.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BackgroundTransparency = 0
    knob.BorderSizePixel = 0
    knob.AutoButtonColor = false
    knob.Text = ""
    knob.Parent = track
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 4.5)
    knobCorner.Parent = knob
    
    local knobShadow = Instance.new("UIShadow")
    knobShadow.Color = Color3.fromRGB(0, 0, 0)
    knobShadow.Transparency = 0.2
    knobShadow.Offset = UDim2.new(0, 0, 0, 0.5)
    knobShadow.Parent = knob
    
    local isOn = initialState or false
    local onToggle = nil
    
    local function updateSwitch()
        local targetPosition = isOn and UDim2.new(0, 8.5, 0.5, -4.5) or UDim2.new(0, 0.5, 0.5, -4.5)
        local targetColor = isOn and THEME.primaryBlue or Color3.fromRGB(200, 200, 200)
        
        TweenService:Create(track, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = targetColor
        }):Play()
        
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = targetPosition
        }):Play()
    end
    
    updateSwitch()
    
    local function toggle()
        isOn = not isOn
        updateSwitch()
        if onToggle then
            onToggle(isOn)
        end
    end
    
    track.MouseButton1Click:Connect(toggle)
    knob.MouseButton1Click:Connect(toggle)
    
    track.MouseEnter:Connect(function()
        track.BackgroundColor3 = isOn and Color3.fromRGB(0, 112, 235) or Color3.fromRGB(180, 180, 180)
    end)
    track.MouseLeave:Connect(function()
        track.BackgroundColor3 = isOn and THEME.primaryBlue or Color3.fromRGB(200, 200, 200)
    end)
    
    return {
        setOn = function(value)
            isOn = value
            updateSwitch()
        end,
        isOn = function()
            return isOn
        end,
        toggle = toggle,
        onChange = function(callback)
            onToggle = callback
        end,
    }
end

------ STATUS FUNCTIONS ------
local function UpdateStatusBar()
    -- COIN: Hijau jika jumpID dan landingID ada
    local coinReady = State.jumpID ~= nil and State.landingID ~= nil
    local coinLed = coinReady and "●" or "○"
    local coinColor = coinReady and THEME.ledGreen or THEME.ledRed
    local coinTime = State.running and string.format("%.1fs", math.max(0, State.nextLoopTime - tick())) or "0.0s"
    
    -- WIN: Hijau jika winID ada
    local winReady = State.winID ~= nil
    local winLed = winReady and "●" or "○"
    local winColor = winReady and THEME.ledGreen or THEME.ledRed
    local winTime = "0.0s"
    if State.autoWinEnabled and State.winID and State.running then
        local currentWinDelay = State.currentWinDelay
        winTime = string.format("%.1fs", math.max(0, currentWinDelay - (tick() - State.lastWinTime)))
    end
    
    -- TOKEN: Hijau jika magicTokenID ada (tidak peduli switch ON/OFF)
    local tokenReady = State.magicTokenID ~= nil
    local tokenLed = tokenReady and "●" or "○"
    local tokenColor = tokenReady and THEME.ledGreen or THEME.ledRed
    
    -- Cooldown token: HANYA BACA delay, tidak mengubahnya
    local tokenTime = "0.0s"
    if State.autoTokenEnabled and State.magicTokenID and State.running then
        local halfDelay = State.coinDelay / 2  -- ← HANYA BACA
        
        if State.tokenClaimed then
            local remainingToNext = State.nextLoopTime - tick()
            tokenTime = string.format("%.1fs", math.max(0, remainingToNext))
        else
            local remainingToMidpoint = (State.lastLoopTime + halfDelay) - tick()
            tokenTime = string.format("%.1fs", math.max(0, remainingToMidpoint))
        end
    end
    
    GUI.CoinLabel.Text = string.format("Coin %s %s", coinLed, coinTime)
    GUI.CoinLabel.TextColor3 = coinColor
    
    GUI.WinLabel.Text = string.format("Win %s %s", winLed, winTime)
    GUI.WinLabel.TextColor3 = winColor
    
    GUI.TokenLabel.Text = string.format("Token %s %s", tokenLed, tokenTime)
    GUI.TokenLabel.TextColor3 = tokenColor
end

local function UpdateStatusMessage()
    local isReady = State.jumpID ~= nil and State.landingID ~= nil
    
    if not isReady then
        GUI.StatusMessage.Text = "JUMP FROM TOWER FIRST"
        GUI.StatusMessage.TextColor3 = THEME.primaryRed
    elseif State.running then
        local msg = "RUNNING..."
        if State.autoTokenEnabled then
            msg = msg .. " ⚡"
        end
        if State.autoWinEnabled then
            msg = msg .. " 🏆"
        end
        GUI.StatusMessage.Text = msg
        GUI.StatusMessage.TextColor3 = THEME.primaryBlue
    else
        GUI.StatusMessage.Text = "READY TO START!"
        GUI.StatusMessage.TextColor3 = THEME.ledGreen
    end
end

local function ShowTemporaryMessage(text, color, duration)
    local oldText = GUI.StatusMessage.Text
    local oldColor = GUI.StatusMessage.TextColor3
    
    GUI.StatusMessage.Text = text
    GUI.StatusMessage.TextColor3 = color
    
    task.delay(duration or 1.5, function()
        if State.hookEnabled then
            GUI.StatusMessage.Text = oldText
            GUI.StatusMessage.TextColor3 = oldColor
        end
    end)
end

local function UpdateStatus()
    local isReady = State.jumpID ~= nil and State.landingID ~= nil
    
    if isReady then
        State.isReady = true
        if State.running then
            GUI.StartStopButton.BackgroundColor3 = THEME.primaryBlue
            GUI.StartStopButton.TextColor3 = THEME.textWhite
            GUI.StartStopButton.Text = "AUTO COIN ON"
        else
            GUI.StartStopButton.BackgroundColor3 = THEME.cardBackground
            GUI.StartStopButton.TextColor3 = THEME.primaryBlue
            GUI.StartStopButton.Text = "START AUTO COIN"
        end
    else
        State.isReady = false
        GUI.StartStopButton.BackgroundColor3 = THEME.cardBackground
        GUI.StartStopButton.TextColor3 = THEME.textSecondary
        GUI.StartStopButton.Text = "START AUTO COIN"
    end
    
    UpdateStatusMessage()
    UpdateStatusBar()
end

------ GUI CREATION ------
local function CreateGUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    if playerGui:FindFirstChild("CoinClaimerGUI") then
        playerGui:FindFirstChild("CoinClaimerGUI"):Destroy()
    end

    local MainFrame = Instance.new("ScreenGui")
    MainFrame.Name = "CoinClaimerGUI"
    MainFrame.Parent = playerGui
    MainFrame.ResetOnSpawn = false
    MainFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 200, 0, 245)
    Frame.Position = UDim2.new(0.5, -100, 0.5, -122.5)
    Frame.BackgroundColor3 = THEME.background
    Frame.BackgroundTransparency = 0
    Frame.BorderSizePixel = 0
    Frame.Parent = MainFrame
    Frame.Draggable = true
    Frame.Active = true
    Frame.ClipsDescendants = true

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 14)
    UICorner.Parent = Frame

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 32)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = THEME.background
    TitleBar.BackgroundTransparency = 0
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Frame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 14, 0, 0)
    TitleCorner.Parent = TitleBar

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0.7, 0, 1, 0)
    TitleText.Position = UDim2.new(0.15, 0, 0, 0)
    TitleText.Text = "CAJT AUTO GACOR"
    TitleText.TextColor3 = THEME.textPrimary
    TitleText.BackgroundTransparency = 1
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 14
    TitleText.Parent = TitleBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 20, 0, 20)
    CloseButton.Position = UDim2.new(1, -26, 0, 6)
    CloseButton.Text = "X"
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 12
    CloseButton.TextColor3 = THEME.textWhite
    CloseButton.BackgroundColor3 = THEME.primaryRed
    CloseButton.AutoButtonColor = false
    CloseButton.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 10)
    CloseCorner.Parent = CloseButton

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Size = UDim2.new(0, 20, 0, 20)
    MinimizeButton.Position = UDim2.new(1, -50, 0, 6)
    MinimizeButton.Text = "−"
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.TextSize = 14
    MinimizeButton.TextColor3 = THEME.textWhite
    MinimizeButton.BackgroundColor3 = THEME.primaryYellow
    MinimizeButton.AutoButtonColor = false
    MinimizeButton.Parent = TitleBar

    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 10)
    MinimizeCorner.Parent = MinimizeButton

    -- Content
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -12, 1, -42)
    Content.Position = UDim2.new(0, 6, 0, 36)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    -- ===== STATUS GROUP =====
    local StatusGroup = Instance.new("Frame")
    StatusGroup.Size = UDim2.new(1, 0, 0, 75)
    StatusGroup.Position = UDim2.new(0, 0, 0, 0)
    StatusGroup.BackgroundColor3 = THEME.cardBackground
    StatusGroup.BackgroundTransparency = 0
    StatusGroup.BorderSizePixel = 0
    StatusGroup.Parent = Content

    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 8)
    StatusCorner.Parent = StatusGroup

    local StatusBorder = Instance.new("UIStroke")
    StatusBorder.Color = THEME.separator
    StatusBorder.Thickness = 0.5
    StatusBorder.Parent = StatusGroup

    -- Status Bar Container (3 labels terpisah untuk warna LED)
    local StatusBarContainer = Instance.new("Frame")
    StatusBarContainer.Size = UDim2.new(1, -10, 0, 15)
    StatusBarContainer.Position = UDim2.new(0, 5, 0, 2)
    StatusBarContainer.BackgroundTransparency = 1
    StatusBarContainer.Parent = StatusGroup

    -- Coin Label
    local CoinLabel = Instance.new("TextLabel")
    CoinLabel.Size = UDim2.new(0.33, 0, 1, 0)
    CoinLabel.Position = UDim2.new(0, 0, 0, 0)
    CoinLabel.Text = "Coin ○ 0.0s"
    CoinLabel.TextColor3 = THEME.ledRed
    CoinLabel.BackgroundTransparency = 1
    CoinLabel.Font = Enum.Font.GothamMedium
    CoinLabel.TextSize = 11
    CoinLabel.TextXAlignment = Enum.TextXAlignment.Center
    CoinLabel.Parent = StatusBarContainer

    -- Win Label
    local WinLabel = Instance.new("TextLabel")
    WinLabel.Size = UDim2.new(0.33, 0, 1, 0)
    WinLabel.Position = UDim2.new(0.33, 0, 0, 0)
    WinLabel.Text = "Win ○ 0.0s"
    WinLabel.TextColor3 = THEME.ledRed
    WinLabel.BackgroundTransparency = 1
    WinLabel.Font = Enum.Font.GothamMedium
    WinLabel.TextSize = 11
    WinLabel.TextXAlignment = Enum.TextXAlignment.Center
    WinLabel.Parent = StatusBarContainer

    -- Token Label
    local TokenLabel = Instance.new("TextLabel")
    TokenLabel.Size = UDim2.new(0.33, 0, 1, 0)
    TokenLabel.Position = UDim2.new(0.66, 0, 0, 0)
    TokenLabel.Text = "Token ○ 0.0s"
    TokenLabel.TextColor3 = THEME.ledRed
    TokenLabel.BackgroundTransparency = 1
    TokenLabel.Font = Enum.Font.GothamMedium
    TokenLabel.TextSize = 11
    TokenLabel.TextXAlignment = Enum.TextXAlignment.Center
    TokenLabel.Parent = StatusBarContainer

    -- Speed Label
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(1, -10, 0, 15)
    SpeedLabel.Position = UDim2.new(0, 5, 0, 19)
    SpeedLabel.Text = "Speed: 0 studs/s"
    SpeedLabel.TextColor3 = THEME.primaryBlue
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Font = Enum.Font.GothamMedium
    SpeedLabel.TextSize = 11
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Center
    SpeedLabel.Parent = StatusGroup

    -- Height Label
    local HeightLabel = Instance.new("TextLabel")
    HeightLabel.Size = UDim2.new(1, -10, 0, 15)
    HeightLabel.Position = UDim2.new(0, 5, 0, 36)
    HeightLabel.Text = "Height: 5000"
    HeightLabel.TextColor3 = THEME.primaryBlue
    HeightLabel.BackgroundTransparency = 1
    HeightLabel.Font = Enum.Font.GothamMedium
    HeightLabel.TextSize = 11
    HeightLabel.TextXAlignment = Enum.TextXAlignment.Center
    HeightLabel.Parent = StatusGroup

    -- Separator
    local Separator = Instance.new("Frame")
    Separator.Size = UDim2.new(1, -10, 0, 1)
    Separator.Position = UDim2.new(0, 5, 0, 53)
    Separator.BackgroundColor3 = THEME.separator
    Separator.BackgroundTransparency = 0
    Separator.BorderSizePixel = 0
    Separator.Parent = StatusGroup

    -- Status Message
    local StatusMessage = Instance.new("TextLabel")
    StatusMessage.Size = UDim2.new(1, -10, 0, 15)
    StatusMessage.Position = UDim2.new(0, 5, 0, 57)
    StatusMessage.Text = "JUMP FROM TOWER FIRST"
    StatusMessage.TextColor3 = THEME.primaryRed
    StatusMessage.BackgroundTransparency = 1
    StatusMessage.Font = Enum.Font.GothamMedium
    StatusMessage.TextSize = 11
    StatusMessage.TextXAlignment = Enum.TextXAlignment.Center
    StatusMessage.Parent = StatusGroup

    -- ===== CONTROL GROUP =====
    local ControlGroup = Instance.new("Frame")
    ControlGroup.Size = UDim2.new(1, 0, 0, 85)
    ControlGroup.Position = UDim2.new(0, 0, 0, 80)
    ControlGroup.BackgroundColor3 = THEME.cardBackground
    ControlGroup.BackgroundTransparency = 0
    ControlGroup.BorderSizePixel = 0
    ControlGroup.Parent = Content

    local ControlCorner = Instance.new("UICorner")
    ControlCorner.CornerRadius = UDim.new(0, 8)
    ControlCorner.Parent = ControlGroup

    local ControlBorder = Instance.new("UIStroke")
    ControlBorder.Color = THEME.separator
    ControlBorder.Thickness = 0.5
    ControlBorder.Parent = ControlGroup

    -- Delay Input
    local DelayContainer = Instance.new("Frame")
    DelayContainer.Size = UDim2.new(1, -10, 0, 25)
    DelayContainer.Position = UDim2.new(0, 5, 0, 2)
    DelayContainer.BackgroundTransparency = 1
    DelayContainer.Parent = ControlGroup

    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(0.5, 0, 1, 0)
    DelayLabel.Position = UDim2.new(0, 0, 0, 0)
    DelayLabel.Text = "Coin Delay"
    DelayLabel.TextColor3 = THEME.textPrimary
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Font = Enum.Font.GothamMedium
    DelayLabel.TextSize = 13
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = DelayContainer

    local DelayBox = Instance.new("TextBox")
    DelayBox.Size = UDim2.new(0.4, 0, 1, 0)
    DelayBox.Position = UDim2.new(0.6, 0, 0, 0)
    DelayBox.Text = tostring(DEFAULT_DELAY)
    DelayBox.PlaceholderText = "Sec"
    DelayBox.BackgroundColor3 = THEME.cardBackground
    DelayBox.TextColor3 = THEME.textPrimary
    DelayBox.Font = Enum.Font.GothamMedium
    DelayBox.TextSize = 12
    DelayBox.TextXAlignment = Enum.TextXAlignment.Center
    DelayBox.Parent = DelayContainer

    local DelayCorner = Instance.new("UICorner")
    DelayCorner.CornerRadius = UDim.new(0, 6)
    DelayCorner.Parent = DelayBox

    local DelayBorder = Instance.new("UIStroke")
    DelayBorder.Color = THEME.separator
    DelayBorder.Thickness = 0.5
    DelayBorder.Parent = DelayBox

    -- Separator
    local ControlSeparator = Instance.new("Frame")
    ControlSeparator.Size = UDim2.new(1, -10, 0, 1)
    ControlSeparator.Position = UDim2.new(0, 5, 0, 29)
    ControlSeparator.BackgroundColor3 = THEME.separator
    ControlSeparator.BackgroundTransparency = 0
    ControlSeparator.BorderSizePixel = 0
    ControlSeparator.Parent = ControlGroup

    -- Switches Frame
    local SwitchFrame = Instance.new("Frame")
    SwitchFrame.Size = UDim2.new(1, -10, 0, 55)
    SwitchFrame.Position = UDim2.new(0, 5, 0, 32)
    SwitchFrame.BackgroundTransparency = 1
    SwitchFrame.Parent = ControlGroup

    local lockSpeedSwitch = CreateiOSSwitch(
        SwitchFrame,
        UDim2.new(0, 0, 0, 0),
        false,
        "Lock Speed"
    )
    
    local winSwitch = CreateiOSSwitch(
        SwitchFrame,
        UDim2.new(0, 0, 0, 15),
        false,
        "Auto Win"
    )
    
    local tokenSwitch = CreateiOSSwitch(
        SwitchFrame,
        UDim2.new(0, 0, 0, 30),
        false,
        "Auto Token"
    )

    -- ===== MAIN BUTTON =====
    local MainButton = Instance.new("TextButton")
    MainButton.Size = UDim2.new(1, 0, 0, 30)
    MainButton.Position = UDim2.new(0, 0, 0, 173)
    MainButton.Text = "START AUTO COIN"
    MainButton.Font = Enum.Font.GothamBold
    MainButton.TextSize = 12
    MainButton.TextColor3 = THEME.primaryBlue
    MainButton.BackgroundColor3 = THEME.cardBackground
    MainButton.AutoButtonColor = false
    MainButton.Parent = Content

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainButton

    local MainBorder = Instance.new("UIStroke")
    MainBorder.Color = THEME.separator
    MainBorder.Thickness = 0.5
    MainBorder.Parent = MainButton

    local GUI = {
        MainFrame = MainFrame,
        Frame = Frame,
        Content = Content,
        CoinLabel = CoinLabel,
        WinLabel = WinLabel,
        TokenLabel = TokenLabel,
        StatusMessage = StatusMessage,
        SpeedLabel = SpeedLabel,
        HeightLabel = HeightLabel,
        DelayTextBox = DelayBox,
        StartStopButton = MainButton,
        MinimizeButton = MinimizeButton,
        CloseButton = CloseButton,
        TitleText = TitleText,
        lockSpeedSwitch = lockSpeedSwitch,
        winSwitch = winSwitch,
        tokenSwitch = tokenSwitch,
    }
    
    return GUI
end

------ REMOTE EVENT FUNCTIONS ------
local function SendRemoteEvent(eventName, ...)
    local args = {eventName, ...}
    ReplicatedStorage:WaitForChild("ProMgs"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end

local function SendJumpData()
    if State.jumpID then
        local height = CalculateHeight()  -- ← HANYA BACA delay
        SendRemoteEvent("JumpResults", State.jumpID, height)
    end
end

local function SendLandingData()
    if State.landingID then
        SendRemoteEvent("LandingResults", State.landingID)
    end
end

local function SendWinData()
    if State.winID then
        SendRemoteEvent("ClaimRooftopWinsReward", State.winID)
        State.lastWinTime = tick()
    end
end

local function SendTokenData()
    if State.magicTokenID then
        SendRemoteEvent("ClaimRooftopMagicToken", State.magicTokenID)
    end
end

------ CORE LOGIC ------
local function RunLoop()
    while State.running and State.hookEnabled do
        -- HANYA BACA delay dari user (TIDAK diubah)
        local coinDelay = State.coinDelay  -- ← ABSOLUT dari user
        
        State.lastLoopTime = tick()
        State.nextLoopTime = State.lastLoopTime + coinDelay
        State.tokenClaimed = false

        -- === HANDLE TOKEN (MIDPOINT) ===
        -- Token di-claim di MIDPOINT dari delay user
        if State.autoTokenEnabled and State.magicTokenID then
            local tokenTime = State.lastLoopTime + (coinDelay / 2)  -- ← HANYA BACA
            while tick() < tokenTime and State.running and State.hookEnabled do
                UpdateStatusBar()
                task.wait(0.1)
            end
            if State.running and State.hookEnabled then
                SendTokenData()
                State.tokenClaimed = true
                State.tokenClaimTime = tick()
                
                GUI.StatusMessage.Text = "✨ TOKEN CLAIMED!"
                GUI.StatusMessage.TextColor3 = THEME.primaryYellow
                task.delay(0.5, function()
                    if State.hookEnabled then
                        UpdateStatusMessage()
                    end
                end)
            end
        end

        -- === HANDLE WIN ===
        if State.autoWinEnabled and State.winID then
            local winDelay = State.currentWinDelay
            if winDelay > 0 and (tick() - State.lastWinTime) >= winDelay then
                SendWinData()
                
                GUI.StatusMessage.Text = "🏆 WIN CLAIMED!"
                GUI.StatusMessage.TextColor3 = THEME.primaryYellow
                task.delay(0.5, function()
                    if State.hookEnabled then
                        UpdateStatusMessage()
                    end
                end)
            end
        end

        -- === WAIT REMAINING TIME ===
        while tick() < State.nextLoopTime and State.running and State.hookEnabled do
            UpdateStatusBar()
            task.wait(0.1)
        end

        if not State.running or not State.hookEnabled then break end

        -- === CLAIM COIN ===
        SendJumpData()
        SendLandingData()

        -- === AUTO-PAUSE ===
        State.runTime = State.runTime + (tick() - State.lastLoopTime)
        if State.runTime >= PAUSE_INTERVAL then
            State.running = false
            GUI.StatusMessage.Text = "PAUSING FOR 30 SECONDS..."
            GUI.StatusMessage.TextColor3 = THEME.primaryYellow
            task.wait(PAUSE_DURATION)
            State.runTime = 0
            State.running = true
            UpdateStatusMessage()
        end
    end

    if State.hookEnabled then
        UpdateStatus()
    end
end

------ CLIMB SPEED METER LOGIC ------
local function SetupCharacter(char)
    local humanoid = char:WaitForChild("Humanoid")
    
    local climbStartTime = 0
    local climbStartY = 0
    local maxY = 0
    local isClimbing = false

    humanoid.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Climbing then
            climbStartTime = tick()
            climbStartY = char:WaitForChild("HumanoidRootPart").Position.Y
            maxY = climbStartY
            isClimbing = true
            State.climbing = true
            State.climbStartY = climbStartY
            State.climbStartTime = climbStartTime
            State.maxY = maxY
        else
            if isClimbing then
                local climbEndY = maxY
                local climbEndTime = tick()
                local totalY = climbEndY - climbStartY
                local totalTime = climbEndTime - climbStartTime
                
                if totalY > 0 and totalTime > MIN_CLIMB_DURATION then
                    State.climbSpeed = totalY / totalTime
                    GUI.SpeedLabel.Text = string.format("Speed: %.2f studs/s", State.climbSpeed)
                    
                    if not State.lockSpeed then
                        -- Height diupdate otomatis dari delay (SATU ARAH)
                        UpdateHeight()
                        -- Update delays untuk display cooldown saja (TIDAK mengubah coinDelay)
                        UpdateDelays()
                    end
                else
                    if totalTime > 0 and totalTime <= MIN_CLIMB_DURATION then
                        GUI.StatusMessage.Text = "CLIMB LONGER (>2s)"
                        GUI.StatusMessage.TextColor3 = THEME.primaryYellow
                        task.delay(1.5, function()
                            if State.hookEnabled then
                                UpdateStatusMessage()
                            end
                        end)
                    end
                end
                
                isClimbing = false
                State.climbing = false
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if isClimbing and char:FindFirstChild("HumanoidRootPart") then
            local y = char.HumanoidRootPart.Position.Y
            if y > maxY then
                maxY = y
                State.maxY = maxY
            end
        end
    end)
end

------ EVENT HANDLERS ------
local function InitializeEventHandlers()
    GUI.StartStopButton.MouseButton1Click:Connect(function()
        if State.isReady then
            State.running = not State.running
            if State.running then
                State.lastWinTime = tick()
                coroutine.wrap(RunLoop)()
            end
            UpdateStatus()
        end
    end)

    GUI.StartStopButton.MouseEnter:Connect(function()
        if not State.running then            GUI.StartStopButton.BackgroundColor3 = THEME.buttonHover
        end
    end)
    GUI.StartStopButton.MouseLeave:Connect(function()
        if not State.running then
            GUI.StartStopButton.BackgroundColor3 = THEME.cardBackground
        end
    end)

    GUI.lockSpeedSwitch.onChange(function(isOn)
        State.lockSpeed = isOn
        if isOn then
            ShowTemporaryMessage("SPEED LOCKED", THEME.ledGreen, 1.5)
        else
            ShowTemporaryMessage("SPEED UNLOCKED", THEME.textSecondary, 1.5)
        end
    end)

    -- Auto Win Switch
    GUI.winSwitch.onChange(function(isOn)
        State.autoWinEnabled = isOn
        if State.winID then
            if isOn then
                State.lastWinTime = tick()
                UpdateDelays()
            end
            UpdateStatusBar()
        else
            task.wait(0.1)
            GUI.winSwitch.setOn(false)
            State.autoWinEnabled = false
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "⚠️ Auto Win",
                Text = "Claim win reward first!",
                Duration = 2
            })
        end
    end)

    -- Auto Token Switch
    GUI.tokenSwitch.onChange(function(isOn)
        if State.magicTokenID then
            State.autoTokenEnabled = isOn
            if isOn then
                UpdateDelays()
            end
            UpdateStatusBar()
        else
            task.wait(0.1)
            GUI.tokenSwitch.setOn(false)
            State.autoTokenEnabled = false
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "⚠️ Auto Token",
                Text = "Claim magic token first!",
                Duration = 2
            })
        end
    end)

    -- Delay Box: HANYA baca input user, tidak ada yang mengubah selain user
    GUI.DelayTextBox:GetPropertyChangedSignal("Text"):Connect(function()
        if not State.lockSpeed then
            UpdateDelays()
            if State.climbSpeed > 0 then
                UpdateHeight()  -- Height otomatis dari delay
            end
        end
    end)

    GUI.MinimizeButton.MouseButton1Click:Connect(function()
        State.minimized = not State.minimized
        if State.minimized then
            GUI.Frame.Size = UDim2.new(0, 100, 0, 32)
            GUI.MinimizeButton.Text = "+"
            GUI.Content.Visible = false
            GUI.TitleText.Position = UDim2.new(0.5, -25, 0, 0)
            GUI.TitleText.TextXAlignment = Enum.TextXAlignment.Center
        else
            GUI.Frame.Size = UDim2.new(0, 200, 0, 245)
            GUI.MinimizeButton.Text = "−"
            GUI.Content.Visible = true
            GUI.TitleText.Position = UDim2.new(0.15, 0, 0, 0)
            GUI.TitleText.TextXAlignment = Enum.TextXAlignment.Left
        end
    end)

    GUI.CloseButton.MouseButton1Click:Connect(function()
        State.hookEnabled = false
        GUI.MainFrame:Destroy()
    end)

    GUI.CloseButton.MouseEnter:Connect(function()
        GUI.CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 70)
    end)
    GUI.CloseButton.MouseLeave:Connect(function()
        GUI.CloseButton.BackgroundColor3 = THEME.primaryRed
    end)

    GUI.MinimizeButton.MouseEnter:Connect(function()
        GUI.MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    end)
    GUI.MinimizeButton.MouseLeave:Connect(function()
        GUI.MinimizeButton.BackgroundColor3 = THEME.primaryYellow
    end)
end

------ REMOTE EVENT HOOK ------
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
                    UpdateStatus()
                elseif eventType == "LandingResults" then
                    State.landingID = eventID
                    UpdateStatus()
                elseif eventType == "ClaimRooftopWinsReward" then
                    State.winID = eventID
                    UpdateStatus()
                elseif eventType == "ClaimRooftopMagicToken" then
                    State.magicTokenID = eventID
                    UpdateStatus()
                end
            end
        end

        return oldNamecall(self, ...)
    end)
end

------ DRAGGING SYSTEM ------
local function SetupDragging()
    local frame = GUI.Frame
    local isDragging = false
    local dragStartPos = nil
    local frameStartPos = nil
    local dragInput = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartPos = input.Position
            frameStartPos = frame.Position
            dragInput = input
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
            dragInput = nil
        end
    end)

    RunService.Heartbeat:Connect(function()
        if isDragging then
            local mousePos = UserInputService:GetMouseLocation()
            if dragStartPos then
                local delta = mousePos - dragStartPos
                local newX = frameStartPos.X.Offset + delta.X
                local newY = frameStartPos.Y.Offset + delta.Y
                frame.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)
end

------ ANIMATION ------
local function SetupAnimation()
    local frame = GUI.Frame
    frame.Size = UDim2.new(0, 0, 0, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    task.delay(0.1, function()
        TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 200, 0, 245),
            Position = UDim2.new(0.5, -100, 0.5, -122.5)
        }):Play()
    end)
end

------ INITIALIZATION ------
print("=== AUTO COIN V4 STARTING ===")

GUI = CreateGUI()

InitializeEventHandlers()
InitializeRemoteHook()
SetupDragging()
SetupAnimation()

local LocalPlayer = Players.LocalPlayer
if LocalPlayer.Character then
    SetupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(SetupCharacter)

UpdateDelays()
UpdateStatus()

print("=== AUTO COIN V4 LOADED SUCCESSFULLY ===")
