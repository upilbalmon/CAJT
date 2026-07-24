--[[
    AUTO COIN V3 - Enhanced Version with Lock Speed & Fixed GUI
    Features:
    1. Auto height calculation: (speed × 2.8) × delay
    2. Dynamic auto win delay: 10000 / speed
    3. Compact 200x200 GUI
    4. All original functionality preserved
    5. Auto token delay formula: (10000/speed) with 1 decimal place
    6. Max height limit: 14400
    7. Lock delay setting checkbox
    8. Lock speed setting checkbox
    9. Fixed GUI with proper sizing
    10. Compact status display (C, W, T)
    11. Sync Delay toggle button in 3-row layout
    12. Fixed CWT position (NEW)
--]]

------ SERVICES ------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

------ CONSTANTS ------
local PAUSE_INTERVAL = 60 * 60  -- 1 hour
local PAUSE_DURATION = 30       -- 30 seconds
local WIN_DELAY_BASE = 10000    -- Base for auto win delay calculation
local DEFAULT_HEIGHT = 5000
local DEFAULT_DELAY = 5
local HEIGHT_MULTIPLIER = 2.8   -- Height calculation multiplier
local MAX_HEIGHT = 14400        -- Maximum height limit

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
    minimized = false,
    climbSpeed = 0,
    climbing = false,
    climbStartY = 0,
    climbStartTime = 0,
    maxY = 0,
    lockDelay = false,
    lockSpeed = false,
    lockedSpeed = 0,
    syncEnabled = false,
    -- Status tracking
    lastCoinClaim = 0,
    lastWinClaim = 0,
    lastTokenClaim = 0
}

------ UTILITY FUNCTIONS ------
local function GetWinDelay()
    local currentSpeed = State.lockSpeed and State.lockedSpeed or State.climbSpeed
    return currentSpeed > 0 and (WIN_DELAY_BASE / currentSpeed) or 20
end

local function CalculateHeight()
    local delay = tonumber(GUI.DelayTextBox.Text) or DEFAULT_DELAY
    local currentSpeed = State.lockSpeed and State.lockedSpeed or State.climbSpeed
    local calculatedHeight = math.floor((currentSpeed * HEIGHT_MULTIPLIER) * delay)
    return math.min(calculatedHeight, MAX_HEIGHT)
end

local function UpdateHeight()
    local currentSpeed = State.lockSpeed and State.lockedSpeed or State.climbSpeed
    if currentSpeed > 0 then
        GUI.HeightTextBox.Text = tostring(CalculateHeight())
    end
end

local function SyncDelayWithWin()
    local winDelay = GetWinDelay()
    if winDelay > 0 then
        GUI.DelayTextBox.Text = string.format("%.1f", winDelay)
        UpdateHeight()
        GUI.StatusMessage.Text = string.format("SYNCED: %.1fs", winDelay)
        GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
        task.wait(1.5)
        if State.running then
            UpdateStatusMessage("ready", "ready", "ready")
        else
            UpdateStatus()
        end
        return true
    end
    return false
end

------ GUI CREATION ------
local function CreateGUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Clean up previous GUI
    if playerGui:FindFirstChild("CoinClaimerGUI") then
        playerGui:FindFirstChild("CoinClaimerGUI"):Destroy()
    end

    -- Main ScreenGui
    local MainFrame = Instance.new("ScreenGui")
    MainFrame.Name = "CoinClaimerGUI"
    MainFrame.Parent = playerGui
    MainFrame.ResetOnSpawn = false
    MainFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 200, 0, 275)  -- Increased height for better spacing
    Frame.Position = UDim2.new(0.5, -100, 0.5, -137)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Frame.BackgroundTransparency = 0.1
    Frame.BorderSizePixel = 0
    Frame.Parent = MainFrame
    Frame.Draggable = true
    Frame.Active = true

    -- Rounded Corners
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Frame

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 25)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Frame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8, 0, 0)
    TitleCorner.Parent = TitleBar

    -- Title Text
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0.7, 0, 1, 0)
    TitleText.Position = UDim2.new(0.15, 0, 0, 0)
    TitleText.Text = "CAJT AUTO GACOR"
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
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseButton

    -- Minimize Button
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Size = UDim2.new(0, 25, 0, 25)
    MinimizeButton.Position = UDim2.new(1, -50, 0, 0)
    MinimizeButton.Text = "-"
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.TextSize = 16
    MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    MinimizeButton.Parent = TitleBar

    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 4)
    MinimizeCorner.Parent = MinimizeButton

    -- Content Frame
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -10, 1, -35)
    Content.Position = UDim2.new(0, 5, 0, 30)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    -- Input Frame
    local InputFrame = Instance.new("Frame")
    InputFrame.Size = UDim2.new(1, 0, 0, 80)
    InputFrame.Position = UDim2.new(0, 0, 0, 0)
    InputFrame.BackgroundTransparency = 1
    InputFrame.Parent = Content

    -- Height Input
    local HeightLabel = Instance.new("TextLabel")
    HeightLabel.Size = UDim2.new(0.4, 0, 0, 20)
    HeightLabel.Position = UDim2.new(0, 0, 0, 0)
    HeightLabel.Text = "Height:"
    HeightLabel.TextColor3 = Color3.new(1, 1, 1)
    HeightLabel.BackgroundTransparency = 1
    HeightLabel.Font = Enum.Font.Gotham
    HeightLabel.TextSize = 11
    HeightLabel.TextXAlignment = Enum.TextXAlignment.Left
    HeightLabel.Parent = InputFrame

    local HeightBox = Instance.new("TextBox")
    HeightBox.Size = UDim2.new(0.6, 0, 0, 20)
    HeightBox.Position = UDim2.new(0.4, 0, 0, 0)
    HeightBox.Text = tostring(DEFAULT_HEIGHT)
    HeightBox.PlaceholderText = "Auto"
    HeightBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    HeightBox.TextColor3 = Color3.new(1, 1, 1)
    HeightBox.Font = Enum.Font.Gotham
    HeightBox.TextSize = 11
    HeightBox.Parent = InputFrame

    local HeightCorner = Instance.new("UICorner")
    HeightCorner.CornerRadius = UDim.new(0, 4)
    HeightCorner.Parent = HeightBox

    -- Delay Input
    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(0.4, 0, 0, 20)
    DelayLabel.Position = UDim2.new(0, 0, 0, 25)
    DelayLabel.Text = "Delay:"
    DelayLabel.TextColor3 = Color3.new(1, 1, 1)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Font = Enum.Font.Gotham
    DelayLabel.TextSize = 11
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = InputFrame

    local DelayBox = Instance.new("TextBox")
    DelayBox.Size = UDim2.new(0.6, 0, 0, 20)
    DelayBox.Position = UDim2.new(0.4, 0, 0, 25)
    DelayBox.Text = tostring(DEFAULT_DELAY)
    DelayBox.PlaceholderText = "Sec"
    DelayBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    DelayBox.TextColor3 = Color3.new(1, 1, 1)
    DelayBox.Font = Enum.Font.Gotham
    DelayBox.TextSize = 11
    DelayBox.Parent = InputFrame

    local DelayCorner = Instance.new("UICorner")
    DelayCorner.CornerRadius = UDim.new(0, 4)
    DelayCorner.Parent = DelayBox

    -- LOCK SECTION: 3-row layout
    local LockSection = Instance.new("Frame")
    LockSection.Size = UDim2.new(1, 0, 0, 75)
    LockSection.Position = UDim2.new(0, 0, 0, 50)
    LockSection.BackgroundTransparency = 1
    LockSection.Parent = InputFrame

    -- ROW 1: Lock Delay
    local Row1 = Instance.new("Frame")
    Row1.Size = UDim2.new(1, 0, 0, 20)
    Row1.Position = UDim2.new(0, 0, 0, 0)
    Row1.BackgroundTransparency = 1
    Row1.Parent = LockSection

    local LockDelayBox = Instance.new("TextButton")
    LockDelayBox.Size = UDim2.new(0, 15, 0, 15)
    LockDelayBox.Position = UDim2.new(0, 5, 0, 2)
    LockDelayBox.Text = ""
    LockDelayBox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    LockDelayBox.Parent = Row1

    local LockDelayCorner = Instance.new("UICorner")
    LockDelayCorner.CornerRadius = UDim.new(0, 3)
    LockDelayCorner.Parent = LockDelayBox

    local LockDelayLabel = Instance.new("TextLabel")
    LockDelayLabel.Size = UDim2.new(1, -25, 1, 0)
    LockDelayLabel.Position = UDim2.new(0, 25, 0, 0)
    LockDelayLabel.Text = "Lock Delay"
    LockDelayLabel.TextColor3 = Color3.new(1, 1, 1)
    LockDelayLabel.BackgroundTransparency = 1
    LockDelayLabel.Font = Enum.Font.Gotham
    LockDelayLabel.TextSize = 10
    LockDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    LockDelayLabel.Parent = Row1

    -- ROW 2: Lock Speed
    local Row2 = Instance.new("Frame")
    Row2.Size = UDim2.new(1, 0, 0, 20)
    Row2.Position = UDim2.new(0, 0, 0, 25)
    Row2.BackgroundTransparency = 1
    Row2.Parent = LockSection

    local LockSpeedBox = Instance.new("TextButton")
    LockSpeedBox.Size = UDim2.new(0, 15, 0, 15)
    LockSpeedBox.Position = UDim2.new(0, 5, 0, 2)
    LockSpeedBox.Text = ""
    LockSpeedBox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    LockSpeedBox.Parent = Row2

    local LockSpeedCorner = Instance.new("UICorner")
    LockSpeedCorner.CornerRadius = UDim.new(0, 3)
    LockSpeedCorner.Parent = LockSpeedBox

    local LockSpeedLabel = Instance.new("TextLabel")
    LockSpeedLabel.Size = UDim2.new(1, -25, 1, 0)
    LockSpeedLabel.Position = UDim2.new(0, 25, 0, 0)
    LockSpeedLabel.Text = "Lock Speed"
    LockSpeedLabel.TextColor3 = Color3.new(1, 1, 1)
    LockSpeedLabel.BackgroundTransparency = 1
    LockSpeedLabel.Font = Enum.Font.Gotham
    LockSpeedLabel.TextSize = 10
    LockSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    LockSpeedLabel.Parent = Row2

    -- ROW 3: Sync Delay = Win
    local Row3 = Instance.new("Frame")
    Row3.Size = UDim2.new(1, 0, 0, 20)
    Row3.Position = UDim2.new(0, 0, 0, 50)
    Row3.BackgroundTransparency = 1
    Row3.Parent = LockSection

    local SyncToggle = Instance.new("TextButton")
    SyncToggle.Size = UDim2.new(0, 15, 0, 15)
    SyncToggle.Position = UDim2.new(0, 5, 0, 2)
    SyncToggle.Text = ""
    SyncToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    SyncToggle.Parent = Row3

    local SyncCorner = Instance.new("UICorner")
    SyncCorner.CornerRadius = UDim.new(0, 3)
    SyncCorner.Parent = SyncToggle

    local SyncLabel = Instance.new("TextLabel")
    SyncLabel.Size = UDim2.new(1, -25, 1, 0)
    SyncLabel.Position = UDim2.new(0, 25, 0, 0)
    SyncLabel.Text = "Sync Delay = Win"
    SyncLabel.TextColor3 = Color3.new(1, 1, 1)
    SyncLabel.BackgroundTransparency = 1
    SyncLabel.Font = Enum.Font.Gotham
    SyncLabel.TextSize = 10
    SyncLabel.TextXAlignment = Enum.TextXAlignment.Left
    SyncLabel.Parent = Row3

    -- CWT Status Indicator (moved down to avoid overlap)
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 15)
    StatusLabel.Position = UDim2.new(0, 0, 0, 130)  -- Moved from 85 to 130
    StatusLabel.Text = "C[○] W[○] T[○]"
    StatusLabel.TextColor3 = Color3.new(1, 1, 1)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 11
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Parent = Content

    -- Speed Indicator
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(1, 0, 0, 15)
    SpeedLabel.Position = UDim2.new(0, 0, 0, 145)  -- Moved from 100 to 145
    SpeedLabel.Text = "Speed: 0 studs/s"
    SpeedLabel.TextColor3 = Color3.new(1, 1, 1)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Font = Enum.Font.Gotham
    SpeedLabel.TextSize = 11
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Center
    SpeedLabel.Parent = Content

    -- Main Button
    local MainButton = Instance.new("TextButton")
    MainButton.Size = UDim2.new(1, 0, 0, 30)
    MainButton.Position = UDim2.new(0, 0, 0, 165)  -- Moved from 120 to 165
    MainButton.Text = "START AUTO COIN"
    MainButton.Font = Enum.Font.GothamBold
    MainButton.TextSize = 12
    MainButton.TextColor3 = Color3.new(1, 1, 1)
    MainButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainButton.Parent = Content

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Parent = MainButton

    -- Toggle Buttons Frame
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 25)
    ToggleFrame.Position = UDim2.new(0, 0, 0, 200)  -- Moved from 155 to 200
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Parent = Content

    -- Auto Win Toggle
    local WinButton = Instance.new("TextButton")
    WinButton.Size = UDim2.new(0.48, 0, 1, 0)
    WinButton.Position = UDim2.new(0, 0, 0, 0)
    WinButton.Text = "WIN: OFF"
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
    TokenButton.Size = UDim2.new(0.48, 0, 1, 0)
    TokenButton.Position = UDim2.new(0.52, 0, 0, 0)
    TokenButton.Text = "TOKEN: OFF"
    TokenButton.Font = Enum.Font.Gotham
    TokenButton.TextSize = 11
    TokenButton.TextColor3 = Color3.new(1, 1, 1)
    TokenButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    TokenButton.Parent = ToggleFrame

    local TokenCorner = Instance.new("UICorner")
    TokenCorner.CornerRadius = UDim.new(0, 6)
    TokenCorner.Parent = TokenButton

    -- Status Message (Loop Status with C, W, T)
    local StatusMessage = Instance.new("TextLabel")
    StatusMessage.Size = UDim2.new(1, 0, 0, 20)
    StatusMessage.Position = UDim2.new(0, 0, 0, 230)  -- Moved from 185 to 230
    StatusMessage.Text = "JUMP FROM TOWER FIRST"
    StatusMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
    StatusMessage.BackgroundTransparency = 1
    StatusMessage.Font = Enum.Font.GothamBold
    StatusMessage.TextSize = 11
    StatusMessage.TextXAlignment = Enum.TextXAlignment.Center
    StatusMessage.Parent = Content

    -- Store references
    return {
        MainFrame = MainFrame,
        Frame = Frame,
        Content = Content,
        HeightTextBox = HeightBox,
        DelayTextBox = DelayBox,
        StatusLabel = StatusLabel,
        SpeedLabel = SpeedLabel,
        StartStopButton = MainButton,
        AutoWinToggle = WinButton,
        AutoTokenToggle = TokenButton,
        StatusMessage = StatusMessage,
        MinimizeButton = MinimizeButton,
        CloseButton = CloseButton,
        LockDelayCheckbox = LockDelayBox,
        LockDelayLabel = LockDelayLabel,
        LockSpeedCheckbox = LockSpeedBox,
        LockSpeedLabel = LockSpeedLabel,
        SyncToggle = SyncToggle,
        SyncLabel = SyncLabel
    }
end

------ REMOTE EVENT FUNCTIONS ------
local function SendRemoteEvent(eventName, ...)
    local args = {eventName, ...}
    ReplicatedStorage:WaitForChild("ProMgs"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end

local function SendJumpData()
    if State.jumpID then
        local height = tonumber(GUI.HeightTextBox.Text) or CalculateHeight()
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
        State.lastWinTime = os.time()
        State.lastWinClaim = os.time()
    end
end

local function SendTokenData()
    if State.magicTokenID then
        SendRemoteEvent("ClaimRooftopMagicToken", State.magicTokenID)
        State.lastTokenClaim = os.time()
    end
end

------ CORE LOGIC ------
local function UpdateStatus()
    local coinIcon = State.jumpID and State.landingID and "●" or "○"
    local winIcon = State.winID and "●" or "○"
    local tokenIcon = State.magicTokenID and "●" or "○"

    GUI.StatusLabel.Text = string.format("C[%s] W[%s] T[%s]", coinIcon, winIcon, tokenIcon)

    if State.jumpID and State.landingID then
        State.isReady = true
        GUI.StartStopButton.BackgroundColor3 = State.running and Color3.fromRGB(0, 200, 50) or Color3.fromRGB(70, 140, 80)
        if not State.running then
            GUI.StatusMessage.Text = "READY TO START!"
            GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    else
        State.isReady = false
        GUI.StartStopButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        GUI.StatusMessage.Text = "JUMP FROM TOWER FIRST"
        GUI.StatusMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

local function UpdateStatusMessage(coinStatus, winStatus, tokenStatus)
    local statusText = ""
    
    if coinStatus == "claimed" then
        statusText = statusText .. "C:✓ "
    elseif coinStatus == "waiting" then
        statusText = statusText .. "C:⏳ "
    elseif coinStatus == "ready" then
        statusText = statusText .. "C:▶ "
    else
        statusText = statusText .. "C:○ "
    end
    
    if winStatus == "claimed" then
        statusText = statusText .. "W:✓ "
    elseif winStatus == "waiting" then
        statusText = statusText .. "W:⏳ "
    elseif winStatus == "ready" then
        statusText = statusText .. "W:▶ "
    else
        statusText = statusText .. "W:○ "
    end
    
    if tokenStatus == "claimed" then
        statusText = statusText .. "T:✓"
    elseif tokenStatus == "waiting" then
        statusText = statusText .. "T:⏳"
    elseif tokenStatus == "ready" then
        statusText = statusText .. "T:▶"
    else
        statusText = statusText .. "T:○"
    end
    
    GUI.StatusMessage.Text = statusText
    GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
end

local function RunLoop()
    while State.running and State.hookEnabled do
        local internalDelay = tonumber(GUI.DelayTextBox.Text) or DEFAULT_DELAY

        -- Apply auto token delay formula when enabled (only if delay is not locked)
        if State.autoTokenEnabled and not State.lockDelay then
            local currentSpeed = State.lockSpeed and State.lockedSpeed or State.climbSpeed
            if currentSpeed > 0 then
                internalDelay = math.floor((10000 / currentSpeed) * 10) / 10
                GUI.DelayTextBox.Text = string.format("%.1f", internalDelay)
            end
        end

        State.lastLoopTime = os.time()
        State.nextLoopTime = State.lastLoopTime + internalDelay
        
        UpdateStatusMessage("ready", "ready", "ready")

        -- Handle auto token at midpoint
        if State.autoTokenEnabled and State.magicTokenID then
            local tokenTime = State.lastLoopTime + (internalDelay / 2)
            while os.time() < tokenTime and State.running and State.hookEnabled do
                local remaining = tokenTime - os.time()
                local winRemaining = GetWinDelay() - (os.time() - State.lastWinTime)
                
                local coinStatus = string.format("%.1fs", remaining)
                local winStatus = State.autoWinEnabled and string.format("%.1fs", winRemaining > 0 and winRemaining or 0) or "off"
                local tokenStatus = string.format("%.1fs", remaining)
                
                GUI.StatusMessage.Text = string.format("C:%s W:%s T:%s", coinStatus, winStatus, tokenStatus)
                GUI.StatusMessage.TextColor3 = Color3.fromRGB(255, 200, 100)
                task.wait(0.1)
            end
            if State.running and State.hookEnabled then
                SendTokenData()
                State.lastTokenClaim = os.time()
                UpdateStatusMessage("claimed", "ready", "claimed")
                task.wait(0.3)
            end
        end

        -- Handle auto win with dynamic delay
        local currentWinDelay = GetWinDelay()
        if State.autoWinEnabled and os.time() - State.lastWinTime >= currentWinDelay then
            SendWinData()
            State.lastWinClaim = os.time()
            UpdateStatusMessage("ready", "claimed", "ready")
            task.wait(0.3)
        end

        -- Wait remaining time with status updates
        local loopStartTime = os.time()
        while os.time() < State.nextLoopTime and State.running and State.hookEnabled do
            local remaining = State.nextLoopTime - os.time()
            local winRemaining = currentWinDelay - (os.time() - State.lastWinTime)
            
            local coinStatus = string.format("%.1fs", remaining)
            local winStatus = State.autoWinEnabled and string.format("%.1fs", winRemaining > 0 and winRemaining or 0) or "off"
            local tokenStatus = State.autoTokenEnabled and string.format("%.1fs", remaining) or "off"
            
            GUI.StatusMessage.Text = string.format("C:%s W:%s T:%s", coinStatus, winStatus, tokenStatus)
            GUI.StatusMessage.TextColor3 = Color3.fromRGB(255, 200, 100)
            task.wait(0.1)
        end

        if not State.running or not State.hookEnabled then break end

        -- Execute coin actions
        SendJumpData()
        SendLandingData()
        State.lastCoinClaim = os.time()
        UpdateStatusMessage("claimed", "ready", "ready")
        task.wait(0.3)

        -- Auto-pause system
        State.runTime = State.runTime + (os.time() - State.lastLoopTime)
        if State.runTime >= PAUSE_INTERVAL then
            State.running = false
            GUI.StatusMessage.Text = "PAUSED 30s"
            GUI.StatusMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
            task.wait(PAUSE_DURATION)
            State.runTime = 0
            State.running = true
        end
    end

    if State.hookEnabled then
        UpdateStatus()
    end
end

------ CLIMB SPEED METER LOGIC ------
local function SetupCharacter(char)
    local humanoid = char:WaitForChild("Humanoid")

    humanoid.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Climbing then
            State.climbStartY = char:WaitForChild("HumanoidRootPart").Position.Y
            State.climbStartTime = tick()
            State.maxY = State.climbStartY
            State.climbing = true
            GUI.StatusMessage.Text = "CLIMBING..."
            GUI.StatusMessage.TextColor3 = Color3.fromRGB(255, 200, 100)
        else
            if State.climbing then
                local climbEndY = State.maxY
                local climbEndTime = tick()
                local totalY = climbEndY - State.climbStartY
                local totalTime = climbEndTime - State.climbStartTime

                if totalY > 0 and totalTime > 0 then
                    State.climbSpeed = totalY / totalTime
                    GUI.SpeedLabel.Text = string.format("Speed: %.2f studs/s", State.climbSpeed)

                    if State.lockSpeed and State.lockedSpeed == 0 then
                        State.lockedSpeed = State.climbSpeed
                        GUI.StatusMessage.Text = "SPEED LOCKED: " .. string.format("%.2f", State.lockedSpeed)
                        GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
                        task.wait(1.5)
                        if State.running then
                            UpdateStatusMessage("ready", "ready", "ready")
                        else
                            UpdateStatus()
                        end
                    end

                    if not State.lockDelay then
                        UpdateHeight()

                        if State.autoTokenEnabled then
                            local currentSpeed = State.lockSpeed and State.lockedSpeed or State.climbSpeed
                            if currentSpeed > 0 then
                                local newDelay = math.floor((10000 / currentSpeed) * 10) / 10
                                GUI.DelayTextBox.Text = string.format("%.1f", newDelay)
                            end
                        end
                    end

                    -- Auto sync if sync toggle is enabled
                    if State.syncEnabled then
                        SyncDelayWithWin()
                    end

                    if State.autoWinEnabled then
                        GUI.StatusMessage.Text = string.format("WIN DELAY: %.1fs", GetWinDelay())
                        GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
                        task.wait(2)
                        if State.running then
                            UpdateStatusMessage("ready", "ready", "ready")
                        else
                            UpdateStatus()
                        end
                    else
                        if State.running then
                            UpdateStatusMessage("ready", "ready", "ready")
                        else
                            UpdateStatus()
                        end
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

------ EVENT HANDLERS ------
local function InitializeEventHandlers()
    -- Start/Stop button
    GUI.StartStopButton.MouseButton1Click:Connect(function()
        if State.isReady then
            State.running = not State.running
            if State.running then
                GUI.StartStopButton.Text = "AUTO COIN ON"
                GUI.StartStopButton.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
                State.lastWinTime = os.time()
                coroutine.wrap(RunLoop)()
            else
                GUI.StartStopButton.Text = "START AUTO COIN"
                GUI.StartStopButton.BackgroundColor3 = Color3.fromRGB(70, 140, 80)
                UpdateStatus()
            end
        end
    end)

    -- Auto Win toggle
    GUI.AutoWinToggle.MouseButton1Click:Connect(function()
        if State.winID then
            State.autoWinEnabled = not State.autoWinEnabled
            if State.autoWinEnabled then
                GUI.AutoWinToggle.Text = "WIN: ON"
                GUI.AutoWinToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                State.lastWinTime = os.time()
                if State.climbSpeed > 0 then
                    GUI.StatusMessage.Text = string.format("WIN DELAY: %.1fs", GetWinDelay())
                    GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
                    task.wait(2)
                    if State.running then
                        UpdateStatusMessage("ready", "ready", "ready")
                    else
                        UpdateStatus()
                    end
                end
            else
                GUI.AutoWinToggle.Text = "WIN: OFF"
                GUI.AutoWinToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                UpdateStatus()
            end
        end
    end)

    -- Auto Token toggle
    GUI.AutoTokenToggle.MouseButton1Click:Connect(function()
        if State.magicTokenID then
            State.autoTokenEnabled = not State.autoTokenEnabled
            if State.autoTokenEnabled then
                GUI.AutoTokenToggle.Text = "TOKEN: ON"
                GUI.AutoTokenToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                if not State.lockDelay then
                    local currentSpeed = State.lockSpeed and State.lockedSpeed or State.climbSpeed
                    if currentSpeed > 0 then
                        local newDelay = math.floor((10000 / currentSpeed) * 10) / 10
                        GUI.DelayTextBox.Text = string.format("%.1f", newDelay)
                    end
                end
            else
                GUI.AutoTokenToggle.Text = "TOKEN: OFF"
                GUI.AutoTokenToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                UpdateStatus()
            end
        end
    end)

    -- Sync Toggle
    GUI.SyncToggle.MouseButton1Click:Connect(function()
        State.syncEnabled = not State.syncEnabled
        if State.syncEnabled then
            GUI.SyncToggle.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            GUI.StatusMessage.Text = "SYNC ENABLED"
            GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
            if State.climbSpeed > 0 then
                SyncDelayWithWin()
            end
            task.wait(1.5)
            if State.running then
                UpdateStatusMessage("ready", "ready", "ready")
            else
                UpdateStatus()
            end
        else
            GUI.SyncToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            GUI.StatusMessage.Text = "SYNC DISABLED"
            GUI.StatusMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
            task.wait(1.5)
            if State.running then
                UpdateStatusMessage("ready", "ready", "ready")
            else
                UpdateStatus()
            end
        end
    end)

    -- Lock Delay Checkbox
    GUI.LockDelayCheckbox.MouseButton1Click:Connect(function()
        State.lockDelay = not State.lockDelay
        if State.lockDelay then
            GUI.LockDelayCheckbox.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            GUI.DelayTextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            GUI.DelayTextBox.TextEditable = false
            GUI.StatusMessage.Text = "DELAY LOCKED"
            GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
            task.wait(1.5)
            if State.running then
                UpdateStatusMessage("ready", "ready", "ready")
            else
                UpdateStatus()
            end
        else
            GUI.LockDelayCheckbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            GUI.DelayTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            GUI.DelayTextBox.TextEditable = true
            GUI.StatusMessage.Text = "DELAY UNLOCKED"
            GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
            task.wait(1.5)
            if State.running then
                UpdateStatusMessage("ready", "ready", "ready")
            else
                UpdateStatus()
            end
        end
    end)

    -- Lock Speed Checkbox
    GUI.LockSpeedCheckbox.MouseButton1Click:Connect(function()
        State.lockSpeed = not State.lockSpeed
        if State.lockSpeed then
            GUI.LockSpeedCheckbox.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            if State.climbSpeed > 0 then
                State.lockedSpeed = State.climbSpeed
                GUI.StatusMessage.Text = "SPEED LOCKED: " .. string.format("%.2f", State.lockedSpeed)
                GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
                task.wait(1.5)
                if State.running then
                    UpdateStatusMessage("ready", "ready", "ready")
                else
                    UpdateStatus()
                end
            else
                GUI.StatusMessage.Text = "WAITING FOR SPEED..."
                GUI.StatusMessage.TextColor3 = Color3.fromRGB(255, 200, 100)
            end
        else
            GUI.LockSpeedCheckbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            State.lockedSpeed = 0
            GUI.StatusMessage.Text = "SPEED UNLOCKED"
            GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
            task.wait(1.5)
            if State.running then
                UpdateStatusMessage("ready", "ready", "ready")
            else
                UpdateStatus()
            end
        end
    end)

    -- Delay box change handler (only if not locked)
    GUI.DelayTextBox:GetPropertyChangedSignal("Text"):Connect(function()
        if State.climbSpeed > 0 and not State.lockDelay then
            UpdateHeight()
        end
    end)

    -- Minimize button
    GUI.MinimizeButton.MouseButton1Click:Connect(function()
        State.minimized = not State.minimized
        if State.minimized then
            GUI.Frame.Size = UDim2.new(0, 100, 0, 25)
            GUI.MinimizeButton.Text = "+"
            GUI.Content.Visible = false
            GUI.StatusMessage.Visible = false
            GUI.TitleText.Position = UDim2.new(0.5, -25, 0, 0)
            GUI.TitleText.TextXAlignment = Enum.TextXAlignment.Center
        else
            GUI.Frame.Size = UDim2.new(0, 200, 0, 275)
            GUI.MinimizeButton.Text = "-"
            GUI.Content.Visible = true
            GUI.StatusMessage.Visible = true
            GUI.TitleText.Position = UDim2.new(0.15, 0, 0, 0)
            GUI.TitleText.TextXAlignment = Enum.TextXAlignment.Left
        end
    end)

    -- Close button
    GUI.CloseButton.MouseButton1Click:Connect(function()
        State.hookEnabled = false
        GUI.MainFrame:Destroy()
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
                elseif eventType == "LandingResults" then
                    State.landingID = eventID
                elseif eventType == "ClaimRooftopWinsReward" then
                    State.winID = eventID
                elseif eventType == "ClaimRooftopMagicToken" then
                    State.magicTokenID = eventID
                end

                UpdateStatus()
            end
        end

        return oldNamecall(self, ...)
    end)
end

------ INITIALIZATION ------
-- Create GUI
GUI = CreateGUI()

-- Set up event handlers
InitializeEventHandlers()
InitializeRemoteHook()

-- Set up character climbing detection
local LocalPlayer = Players.LocalPlayer
if LocalPlayer.Character then
    SetupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(SetupCharacter)

print("Auto Coin V3 - Enhanced Version with Fixed CWT Position Loaded Successfully!")
