--[[
    AUTO COIN V3 - Enhanced Version
    Features:
    1. Auto height calculation: (speed × 2.8) × delay
    2. Dynamic auto win delay: 10000 / speed
    3. Compact 200x200 GUI
    4. All original functionality preserved
    5. Auto token delay formula: (10000/speed) with 1 decimal place
    6. Max height limit: 14400
    7. Lock delay setting checkbox
    8. Speed validation: measurement minimum 3 seconds
    9. Speed detection stops after validation
    10. Optimized CPU usage (heartbeat interval)
    11. Hook stops after all IDs collected OR timeout (3 minutes)
    12. GUI validation - prevents duplicate GUI instances
    13. Safe GUI destruction - ensures all scripts stopped before destroying
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
local MIN_SPEED_MEASUREMENT = 3 -- Minimum seconds for speed measurement
local HEARTBEAT_INTERVAL = 5    -- Process every 5 frames to save CPU
local HOOK_TIMEOUT = 180        -- 3 minutes timeout for hook
local DESTROY_WAIT_TIME = 1     -- Wait time for cleanup before destroying GUI

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
    speedValidated = false,
    speedMeasurementTime = 0,
    speedDetectionActive = true,
    speedDetectionConnections = {},
    hookActive = true,
    hookCleanup = nil,
    hookStartTime = 0,
    hookTimedOut = false,
    guiInstance = nil,
    isDestroying = false, -- Flag untuk mencegah destroy berulang
    runLoopCoroutine = nil -- Referensi ke coroutine run loop
}

------ UTILITY FUNCTIONS ------
local function GetWinDelay()
    return State.climbSpeed > 0 and (WIN_DELAY_BASE / State.climbSpeed) or 20
end

local function CalculateHeight()
    local delay = tonumber(GUI.DelayTextBox.Text) or DEFAULT_DELAY
    local calculatedHeight = math.floor((State.climbSpeed * HEIGHT_MULTIPLIER) * delay)
    return math.min(calculatedHeight, MAX_HEIGHT)
end

local function UpdateHeight()
    if State.climbSpeed > 0 and State.speedValidated then
        GUI.HeightTextBox.Text = tostring(CalculateHeight())
    end
end

local function CheckAllIDsCollected()
    return State.jumpID ~= nil and 
           State.landingID ~= nil and 
           State.winID ~= nil and 
           State.magicTokenID ~= nil
end

local function GetCollectedIDsCount()
    local count = 0
    if State.jumpID then count = count + 1 end
    if State.landingID then count = count + 1 end
    if State.winID then count = count + 1 end
    if State.magicTokenID then count = count + 1 end
    return count
end

------ GUI VALIDATION ------
local function IsGUIExists()
    local player = Players.LocalPlayer
    if not player then return false end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local existingGUI = playerGui:FindFirstChild("CoinClaimerGUI")
    if existingGUI then
        return true
    end
    
    return false
end

local function DestroyExistingGUI()
    local player = Players.LocalPlayer
    if not player then return end
    
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    local existingGUI = playerGui:FindFirstChild("CoinClaimerGUI")
    if existingGUI then
        print("Destroying existing GUI instance...")
        existingGUI:Destroy()
        task.wait(0.5)
    end
end

------ SAFE GUI DESTRUCTION ------
local function StopAllProcesses()
    print("🛑 Stopping all processes...")
    
    -- 1. Stop running loop
    if State.running then
        State.running = false
        print("✓ Running loop stopped")
    end
    
    -- 2. Stop hook
    if State.hookActive then
        State.hookActive = false
        if State.hookCleanup then
            State.hookCleanup()
            State.hookCleanup = nil
        end
        print("✓ Hook stopped")
    end
    
    -- 3. Stop speed detection
    if State.speedDetectionActive then
        State.speedDetectionActive = false
        for _, connection in ipairs(State.speedDetectionConnections) do
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end
        State.speedDetectionConnections = {}
        print("✓ Speed detection stopped")
    end
    
    -- 4. Disable hookEnabled
    State.hookEnabled = false
    print("✓ All processes stopped")
end

local function ValidateAllStopped()
    -- Cek apakah semua proses sudah berhenti
    local allStopped = true
    local issues = {}
    
    if State.running then
        allStopped = false
        table.insert(issues, "Running loop masih aktif")
    end
    
    if State.hookActive then
        allStopped = false
        table.insert(issues, "Hook masih aktif")
    end
    
    if State.speedDetectionActive then
        allStopped = false
        table.insert(issues, "Speed detection masih aktif")
    end
    
    if State.hookEnabled then
        allStopped = false
        table.insert(issues, "Hook enabled masih true")
    end
    
    if #issues > 0 then
        print("⚠️ Proses masih berjalan:")
        for _, issue in ipairs(issues) do
            print("  - " .. issue)
        end
    else
        print("✓ Semua proses sudah berhenti")
    end
    
    return allStopped
end

local function SafeDestroyGUI()
    -- Cegah destroy berulang
    if State.isDestroying then
        print("⚠️ GUI already being destroyed, skipping...")
        return
    end
    
    if not State.guiInstance then
        print("⚠️ GUI instance not found, skipping...")
        return
    end
    
    State.isDestroying = true
    print("🔄 Starting safe GUI destruction...")
    
    -- Step 1: Stop semua proses
    StopAllProcesses()
    
    -- Step 2: Tunggu sebentar untuk memastikan semua proses berhenti
    print("⏳ Waiting for processes to fully stop...")
    task.wait(DESTROY_WAIT_TIME)
    
    -- Step 3: Validasi semua proses sudah berhenti
    local allStopped = ValidateAllStopped()
    
    if not allStopped then
        print("⚠️ Some processes still running! Force stopping...")
        -- Force stop dengan reset semua state
        State.running = false
        State.hookActive = false
        State.speedDetectionActive = false
        State.hookEnabled = false
        task.wait(0.5)
    end
    
    -- Step 4: Destroy GUI
    print("🗑️ Destroying GUI...")
    local success, err = pcall(function()
        if State.guiInstance and State.guiInstance.Parent then
            State.guiInstance:Destroy()
        end
    end)
    
    if not success then
        warn("Error destroying GUI: " .. tostring(err))
    end
    
    -- Step 5: Clear references
    State.guiInstance = nil
    State.runLoopCoroutine = nil
    
    -- Step 6: Final cleanup
    if State.hookCleanup then
        State.hookCleanup()
        State.hookCleanup = nil
    end
    
    for _, connection in ipairs(State.speedDetectionConnections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    State.speedDetectionConnections = {}
    
    State.isDestroying = false
    print("✅ GUI destroyed successfully!")
end

------ GUI CREATION ------
local function CreateGUI()
    -- VALIDASI: Cek dan destroy GUI existing dengan safe destroy
    if IsGUIExists() then
        print("⚠️ GUI already exists! Destroying old instance with safe method...")
        SafeDestroyGUI()
    end
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Main ScreenGui
    local MainFrame = Instance.new("ScreenGui")
    MainFrame.Name = "CoinClaimerGUI"
    MainFrame.Parent = playerGui
    MainFrame.ResetOnSpawn = false
    MainFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame (200x200)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 200, 0, 200)
    Frame.Position = UDim2.new(0.5, -100, 0.5, -100)
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
    InputFrame.Size = UDim2.new(1, 0, 0, 50)
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

    -- Lock Delay Checkbox
    local LockDelayFrame = Instance.new("Frame")
    LockDelayFrame.Size = UDim2.new(1, 0, 0, 15)
    LockDelayFrame.Position = UDim2.new(0, 0, 0, 50)
    LockDelayFrame.BackgroundTransparency = 1
    LockDelayFrame.Parent = InputFrame

    local LockDelayBox = Instance.new("TextButton")
    LockDelayBox.Size = UDim2.new(0, 15, 0, 15)
    LockDelayBox.Position = UDim2.new(0, 0, 0, 0)
    LockDelayBox.Text = ""
    LockDelayBox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    LockDelayBox.Parent = LockDelayFrame

    local LockDelayCorner = Instance.new("UICorner")
    LockDelayCorner.CornerRadius = UDim.new(0, 3)
    LockDelayCorner.Parent = LockDelayBox

    local LockDelayLabel = Instance.new("TextLabel")
    LockDelayLabel.Size = UDim2.new(1, -20, 1, 0)
    LockDelayLabel.Position = UDim2.new(0, 20, 0, 0)
    LockDelayLabel.Text = "Lock Delay Setting"
    LockDelayLabel.TextColor3 = Color3.new(1, 1, 1)
    LockDelayLabel.BackgroundTransparency = 1
    LockDelayLabel.Font = Enum.Font.Gotham
    LockDelayLabel.TextSize = 10
    LockDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    LockDelayLabel.Parent = LockDelayFrame

    -- Status Indicator
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 15)
    StatusLabel.Position = UDim2.new(0, 0, 0, 70)
    StatusLabel.Text = "Coin[○] Win[○] Token[○]"
    StatusLabel.TextColor3 = Color3.new(1, 1, 1)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 11
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Parent = Content

    -- Speed Indicator
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(1, 0, 0, 15)
    SpeedLabel.Position = UDim2.new(0, 0, 0, 85)
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
    MainButton.Position = UDim2.new(0, 0, 0, 105)
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
    ToggleFrame.Position = UDim2.new(0, 0, 0, 140)
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

    -- Status Message
    local StatusMessage = Instance.new("TextLabel")
    StatusMessage.Size = UDim2.new(1, 0, 0, 15)
    StatusMessage.Position = UDim2.new(0, 0, 0, 170)
    StatusMessage.Text = "JUMP FROM TOWER FIRST"
    StatusMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
    StatusMessage.BackgroundTransparency = 1
    StatusMessage.Font = Enum.Font.Gotham
    StatusMessage.TextSize = 11
    StatusMessage.TextXAlignment = Enum.TextXAlignment.Center
    StatusMessage.Parent = Content

    -- Store GUI instance untuk validasi
    State.guiInstance = MainFrame

    -- Return GUI elements
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
        LockDelayLabel = LockDelayLabel
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
    end
end

local function SendTokenData()
    if State.magicTokenID then
        SendRemoteEvent("ClaimRooftopMagicToken", State.magicTokenID)
    end
end

------ CORE LOGIC ------
local function UpdateStatus()
    if not GUI or not GUI.StatusLabel then return end
    
    local coinIcon = State.jumpID and State.landingID and "●" or "○"
    local winIcon = State.winID and "●" or "○"
    local tokenIcon = State.magicTokenID and "●" or "○"
    local idCount = GetCollectedIDsCount()

    GUI.StatusLabel.Text = string.format("Coin[%s] Win[%s] Token[%s] (%d/4)", coinIcon, winIcon, tokenIcon, idCount)

    local hookStatus = State.hookActive and "ACTIVE" or (State.hookTimedOut and "TIMEOUT" or "STOPPED")
    local timeElapsed = math.floor(os.time() - State.hookStartTime)
    local timeDisplay = State.hookActive and string.format(" (%ds/%ds)", timeElapsed, HOOK_TIMEOUT) or ""
    
    GUI.SpeedLabel.Text = string.format("Hook: %s%s | Speed: %.2f", hookStatus, timeDisplay, State.climbSpeed)

    if State.jumpID and State.landingID then
        State.isReady = true
        GUI.StartStopButton.BackgroundColor3 = State.running and Color3.fromRGB(0, 200, 50) or Color3.fromRGB(70, 140, 80)
        GUI.StatusMessage.Text = State.running and "RUNNING..." or "READY TO START!"
        GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        State.isReady = false
        GUI.StartStopButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        GUI.StatusMessage.Text = "JUMP FROM TOWER FIRST"
        GUI.StatusMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

local function RunLoop()
    -- Simpan referensi coroutine
    State.runLoopCoroutine = coroutine.running()
    
    while State.running and State.hookEnabled do
        -- Cek apakah GUI masih ada
        if not State.guiInstance or not State.guiInstance.Parent then
            print("⚠️ GUI destroyed, stopping run loop...")
            State.running = false
            break
        end
        
        local internalDelay = tonumber(GUI.DelayTextBox.Text) or DEFAULT_DELAY

        if State.autoTokenEnabled and State.climbSpeed > 0 and not State.lockDelay and State.speedValidated then
            internalDelay = math.floor((10000 / State.climbSpeed) * 10) / 10
            GUI.DelayTextBox.Text = string.format("%.1f", internalDelay)
        end

        State.lastLoopTime = os.time()
        State.nextLoopTime = State.lastLoopTime + internalDelay

        if State.autoTokenEnabled and State.magicTokenID then
            local tokenTime = State.lastLoopTime + (internalDelay / 2)
            while os.time() < tokenTime and State.running and State.hookEnabled do
                if not State.guiInstance or not State.guiInstance.Parent then
                    State.running = false
                    break
                end
                task.wait(0.1)
            end
            if State.running and State.hookEnabled then
                SendTokenData()
            end
        end

        local currentWinDelay = GetWinDelay()
        if State.autoWinEnabled and State.speedValidated and os.time() - State.lastWinTime >= currentWinDelay then
            SendWinData()
        end

        while os.time() < State.nextLoopTime and State.running and State.hookEnabled do
            if not State.guiInstance or not State.guiInstance.Parent then
                State.running = false
                break
            end
            
            local remaining = State.nextLoopTime - os.time()
            local winRemaining = currentWinDelay - (os.time() - State.lastWinTime)
            local statusText = string.format("RUNNING (%.1fs)", remaining)

            if State.autoWinEnabled and State.speedValidated then
                statusText = statusText..string.format(" | WIN (%.1fs)", winRemaining > 0 and winRemaining or 0)
            end

            GUI.StatusMessage.Text = statusText
            task.wait(0.1)
        end

        if not State.running or not State.hookEnabled then break end

        SendJumpData()
        SendLandingData()

        State.runTime = State.runTime + (os.time() - State.lastLoopTime)
        if State.runTime >= PAUSE_INTERVAL then
            State.running = false
            GUI.StatusMessage.Text = "PAUSING FOR 30 SECONDS..."
            task.wait(PAUSE_DURATION)
            State.runTime = 0
            State.running = true
        end
    end

    if State.hookEnabled and State.guiInstance and State.guiInstance.Parent then
        UpdateStatus()
    end
    
    State.runLoopCoroutine = nil
end

------ OPTIMIZED CLIMB SPEED METER ------
local function StopSpeedDetection()
    State.speedDetectionActive = false
    
    for _, connection in ipairs(State.speedDetectionConnections) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    State.speedDetectionConnections = {}
    
    print("Speed detection stopped - measurement complete")
end

local function SetupCharacter(char)
    if not State.speedDetectionActive then
        if GUI and GUI.SpeedLabel then
            GUI.SpeedLabel.Text = string.format("Speed: %.2f studs/s (Locked)", State.climbSpeed)
        end
        return
    end
    
    local humanoid = char:WaitForChild("Humanoid")
    local humanoidRootPart = char:WaitForChild("HumanoidRootPart")
    local connections = {}
    
    local isClimbing = false
    local maxY = 0
    local climbStartY = 0
    local climbStartTime = 0
    local frameCounter = 0

    local stateChangedConnection = humanoid.StateChanged:Connect(function(_, new)
        if not State.speedDetectionActive then
            return
        end
        
        if new == Enum.HumanoidStateType.Climbing then
            State.speedValidated = false
            State.speedMeasurementTime = 0
            isClimbing = true
            climbStartY = humanoidRootPart.Position.Y
            climbStartTime = tick()
            maxY = climbStartY
            State.climbing = true
            if GUI and GUI.SpeedLabel then
                GUI.SpeedLabel.Text = "Speed: Measuring..."
            end
        else
            if isClimbing then
                local climbEndY = maxY
                local climbEndTime = tick()
                local totalY = climbEndY - climbStartY
                local totalTime = climbEndTime - climbStartTime

                if totalY > 0 and totalTime > 0 then
                    if totalTime >= MIN_SPEED_MEASUREMENT then
                        State.climbSpeed = totalY / totalTime
                        State.speedValidated = true
                        State.speedMeasurementTime = totalTime
                        
                        if GUI and GUI.SpeedLabel then
                            GUI.SpeedLabel.Text = string.format("Speed: %.2f studs/s ✓ (Valid)", State.climbSpeed)
                        end
                        if GUI and GUI.StatusMessage then
                            GUI.StatusMessage.Text = string.format("✓ SPEED VALIDATED! (%.1fs) - DETECTION STOPPED", totalTime)
                            GUI.StatusMessage.TextColor3 = Color3.fromRGB(100, 255, 100)
                        end
                        task.wait(1.5)

                        StopSpeedDetection()

                        if not State.lockDelay then
                            UpdateHeight()
                            if State.autoTokenEnabled then
                                local newDelay = math.floor((10000 / State.climbSpeed) * 10) / 10
                                if GUI and GUI.DelayTextBox then
                                    GUI.DelayTextBox.Text = string.format("%.1f", newDelay)
                                end
                            end
                        end

                        if State.autoWinEnabled and GUI and GUI.StatusMessage then
                            GUI.StatusMessage.Text = string.format("WIN DELAY: %.1fs", GetWinDelay())
                            task.wait(2)
                            if State.running then
                                GUI.StatusMessage.Text = "RUNNING..."
                            end
                        end
                    else
                        State.climbSpeed = totalY / totalTime
                        State.speedValidated = false
                        
                        if GUI and GUI.SpeedLabel then
                            GUI.SpeedLabel.Text = string.format("Speed: %.2f studs/s ✗ (INVALID - %.1fs)", State.climbSpeed, totalTime)
                        end
                        if GUI and GUI.StatusMessage then
                            GUI.StatusMessage.Text = "✗ SPEED MEASUREMENT TOO SHORT! (>3s needed)"
                            GUI.StatusMessage.TextColor3 = Color3.fromRGB(255, 100, 100)
                        end
                        task.wait(2)
                        
                        if State.running and GUI and GUI.StatusMessage then
                            GUI.StatusMessage.Text = "RUNNING... (USE PREVIOUS SPEED)"
                        else
                            UpdateStatus()
                        end
                    end
                else
                    if GUI and GUI.SpeedLabel then
                        GUI.SpeedLabel.Text = "Speed: 0 studs/s"
                    end
                end
                isClimbing = false
                State.climbing = false
            end
        end
    end)
    table.insert(connections, stateChangedConnection)

    local heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not State.speedDetectionActive or not isClimbing then
            return
        end
        
        frameCounter = frameCounter + 1
        if frameCounter % HEARTBEAT_INTERVAL == 0 then
            local currentY = humanoidRootPart.Position.Y
            if currentY > maxY then
                maxY = currentY
            end
        end
    end)
    table.insert(connections, heartbeatConnection)

    State.speedDetectionConnections = connections
end

------ OPTIMIZED HOOK WITH TIMEOUT ------
local function StopHook(reason)
    if State.hookActive then
        State.hookActive = false
        
        if State.hookCleanup then
            State.hookCleanup()
            State.hookCleanup = nil
        end
        
        local message = ""
        if reason == "complete" then
            message = "✓ ALL IDs COLLECTED! HOOK STOPPED"
            print("Hook stopped - all IDs collected!")
        elseif reason == "timeout" then
            State.hookTimedOut = true
            local collected = GetCollectedIDsCount()
            message = string.format("⏰ HOOK TIMEOUT! (%d/4 IDs collected)", collected)
            print(string.format("Hook stopped - timeout! (%d/4 IDs collected)", collected))
        end
        
        if GUI and GUI.StatusMessage then
            GUI.StatusMessage.Text = message
            GUI.StatusMessage.TextColor3 = reason == "complete" and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 0)
        end
        task.wait(2)
        UpdateStatus()
    end
end

local function StartTimeoutTimer()
    coroutine.wrap(function()
        local startTime = os.time()
        State.hookStartTime = startTime
        
        while State.hookActive do
            -- Cek apakah GUI masih ada
            if not State.guiInstance or not State.guiInstance.Parent then
                print("⚠️ GUI destroyed, stopping timeout timer...")
                break
            end
            
            local elapsed = os.time() - startTime
            
            if elapsed % 5 == 0 then
                local remaining = HOOK_TIMEOUT - elapsed
                if remaining > 0 and GUI and GUI.StatusMessage then
                    GUI.StatusMessage.Text = string.format("⏳ Collecting IDs... (%ds remaining)", remaining)
                    GUI.StatusMessage.TextColor3 = Color3.fromRGB(255, 200, 100)
                end
            end
            
            if elapsed >= HOOK_TIMEOUT then
                if State.hookActive then
                    print("⚠️ HOOK TIMEOUT! Stopping hook...")
                    StopHook("timeout")
                end
                break
            end
            
            task.wait(1)
        end
    end)()
end

local function InitializeRemoteHook()
    local remoteEvent = ReplicatedStorage:WaitForChild("ProMgs"):WaitForChild("RemoteEvent")
    local oldNamecall
    local isHooked = false

    State.hookCleanup = function()
        if isHooked and oldNamecall then
            local success, err = pcall(function()
                hookmetamethod(game, "__namecall", oldNamecall)
            end)
            if not success then
                warn("Failed to unhook: " .. tostring(err))
            end
            isHooked = false
            print("Hook successfully removed")
        end
    end

    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not State.hookActive then
            return oldNamecall(self, ...)
        end

        if self == remoteEvent then
            local method = getnamecallmethod()
            if method == "FireServer" then
                local args = {...}
                local eventType = args[1]
                local eventID = args[2]

                if typeof(eventID) == "number" then
                    local idCollected = false
                    
                    if eventType == "JumpResults" then
                        if State.jumpID == nil then
                            State.jumpID = eventID
                            idCollected = true
                            print(string.format("✓ Jump ID collected: %d", eventID))
                        end
                    elseif eventType == "LandingResults" then
                        if State.landingID == nil then
                            State.landingID = eventID
                            idCollected = true
                            print(string.format("✓ Landing ID collected: %d", eventID))
                        end
                    elseif eventType == "ClaimRooftopWinsReward" then
                        if State.winID == nil then
                            State.winID = eventID
                            idCollected = true
                            print(string.format("✓ Win ID collected: %d", eventID))
                        end
                    elseif eventType == "ClaimRooftopMagicToken" then
                        if State.magicTokenID == nil then
                            State.magicTokenID = eventID
                            idCollected = true
                            print(string.format("✓ Token ID collected: %d", eventID))
                        end
                    end

                    if idCollected then
                        UpdateStatus()
                        print(string.format("Progress: %d/4 IDs collected", GetCollectedIDsCount()))
                    end

                    if CheckAllIDsCollected() then
                        print("🎯 All IDs collected! Stopping hook...")
                        StopHook("complete")
                    end
                end
            end
        end

        return oldNamecall(self, ...)
    end)

    isHooked = true
    State.hookStartTime = os.time()
    print(string.format("Hook initialized - waiting for IDs... (timeout: %d seconds)", HOOK_TIMEOUT))
    
    StartTimeoutTimer()
end

------ EVENT HANDLERS ------
local function InitializeEventHandlers()
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

    GUI.AutoWinToggle.MouseButton1Click:Connect(function()
        if State.winID then
            State.autoWinEnabled = not State.autoWinEnabled
            if State.autoWinEnabled then
                GUI.AutoWinToggle.Text = "WIN: ON"
                GUI.AutoWinToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                State.lastWinTime = os.time()
                if State.climbSpeed > 0 and State.speedValidated then
                    GUI.StatusMessage.Text = string.format("WIN DELAY: %.1fs", GetWinDelay())
                    task.wait(2)
                    if State.running then
                        GUI.StatusMessage.Text = "RUNNING..."
                    end
                end
            else
                GUI.AutoWinToggle.Text = "WIN: OFF"
                GUI.AutoWinToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            end
        end
    end)

    GUI.AutoTokenToggle.MouseButton1Click:Connect(function()
        if State.magicTokenID then
            State.autoTokenEnabled = not State.autoTokenEnabled
            if State.autoTokenEnabled then
                GUI.AutoTokenToggle.Text = "TOKEN: ON"
                GUI.AutoTokenToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                if State.climbSpeed > 0 and not State.lockDelay and State.speedValidated then
                    local newDelay = math.floor((10000 / State.climbSpeed) * 10) / 10
                    GUI.DelayTextBox.Text = string.format("%.1f", newDelay)
                end
            else
                GUI.AutoTokenToggle.Text = "TOKEN: OFF"
                GUI.AutoTokenToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            end
        end
    end)

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
                GUI.StatusMessage.Text = "RUNNING..."
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
                GUI.StatusMessage.Text = "RUNNING..."
            else
                UpdateStatus()
            end
        end
    end)

    GUI.DelayTextBox:GetPropertyChangedSignal("Text"):Connect(function()
        if State.climbSpeed > 0 and not State.lockDelay and State.speedValidated then
            UpdateHeight()
        end
    end)

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
            GUI.Frame.Size = UDim2.new(0, 200, 0, 200)
            GUI.MinimizeButton.Text = "-"
            GUI.Content.Visible = true
            GUI.StatusMessage.Visible = true
            GUI.TitleText.Position = UDim2.new(0.15, 0, 0, 0)
            GUI.TitleText.TextXAlignment = Enum.TextXAlignment.Left
        end
    end)

    -- Close Button dengan safe destroy
    GUI.CloseButton.MouseButton1Click:Connect(function()
        SafeDestroyGUI()
    end)
end

------ VALIDATION FUNCTIONS ------
local function IsGUIActive()
    return State.guiInstance ~= nil and State.guiInstance.Parent ~= nil
end

local function IsAllProcessesStopped()
    return not State.running and 
           not State.hookActive and 
           not State.speedDetectionActive and 
           not State.hookEnabled
end

------ INITIALIZATION ------
print("=========================================")
print("AUTO COIN V3 - Initializing...")

-- Cek dan destroy existing GUI dengan safe method
if IsGUIExists() then
    print("⚠️ Existing GUI detected! Removing with safe method...")
    SafeDestroyGUI()
end

-- Create GUI
GUI = CreateGUI()
print("✓ GUI Created Successfully")

-- Initialize components
InitializeEventHandlers()
print("✓ Event Handlers Initialized")

InitializeRemoteHook()
print("✓ Remote Hook Initialized")

-- Setup character
local LocalPlayer = Players.LocalPlayer
if LocalPlayer.Character then
    SetupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(char)
    State.speedDetectionActive = true
    State.speedValidated = false
    SetupCharacter(char)
end)

print("=========================================")
print("AUTO COIN V3 - Enhanced Version Loaded!")
print(string.format("✓ Speed validation: %d seconds minimum", MIN_SPEED_MEASUREMENT))
print(string.format("✓ CPU Optimization: Heartbeat interval = %d frames", HEARTBEAT_INTERVAL))
print(string.format("✓ Hook timeout: %d seconds (%d minutes)", HOOK_TIMEOUT, HOOK_TIMEOUT/60))
print("✓ Hook stops when: All 4 IDs collected OR Timeout")
print("✓ GUI Validation: Active - prevents duplicate GUI")
print("✓ Safe Destruction: All scripts stopped before GUI destroy")
print("=========================================")
