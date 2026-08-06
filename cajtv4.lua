--[[
    AUTO COIN V4 - VANILLA UI WITH SIDEBAR (COMPACT + FONT+1)
    Dengan Integrasi Anti-AFK & Hidden Place
]]

------ SERVICES ------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

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
local CLAIM_RATIO = 7 / 8

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
    fullAuto = false,
    coinDelay = DEFAULT_DELAY,
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
    winClaimedThisLoop = false,
    tokenClaimedThisLoop = false,
    currentTab = "Main",
    -- Utility states
    antiAFKEnabled = false,
    antiAFKLastTrigger = 0,
    hiddenEnabled = false,
    isFlying = false,
    originalPosition = nil,
    bodyVelocity = nil,
    flyConnection = nil,
    keysPressed = {},
}

-- GUI Elements
local GUI = {}
local ScreenGui = nil
local MainFrame = nil
local ContentFrame = nil
local SidebarFrame = nil
local SidebarButtons = {}

------ UTILITY FUNCTIONS ------
local function CalculateFullAutoDelay(speed)
    if speed <= 0 then return DEFAULT_DELAY end
    return 14400 / (speed * 1.5)
end

local function CalculateHeight()
    local delay = State.coinDelay
    local calculatedHeight = math.floor((State.climbSpeed * HEIGHT_MULTIPLIER) * delay)
    return math.min(calculatedHeight, MAX_HEIGHT)
end

local function UpdateHeight()
    if State.climbSpeed > 0 and GUI.HeightLabel then
        GUI.HeightLabel.Text = string.format("Height: %d", CalculateHeight())
    end
end

local function UpdateDelays()
    if State.fullAuto then
        local speed = State.climbSpeed
        if speed > 0 then
            State.coinDelay = CalculateFullAutoDelay(speed)
            if GUI.DelayInput then
                GUI.DelayInput.Text = string.format("%.2f", State.coinDelay)
            end
        else
            State.coinDelay = DEFAULT_DELAY
            if GUI.DelayInput then
                GUI.DelayInput.Text = string.format("%.1f", DEFAULT_DELAY)
            end
        end
    else
        if GUI.DelayInput then
            local input = tonumber(GUI.DelayInput.Text)
            if input and input > 0 then
                State.coinDelay = input
            else
                State.coinDelay = DEFAULT_DELAY
                GUI.DelayInput.Text = string.format("%.1f", DEFAULT_DELAY)
            end
        end
    end

    if State.climbSpeed > 0 then
        UpdateHeight()
    end
end

------ STATUS FUNCTIONS ------
local function UpdateStatusBar()
    local coinReady = State.jumpID ~= nil and State.landingID ~= nil
    local coinLed = coinReady and "●" or "○"
    local coinColor = coinReady and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 59, 48)
    local coinTime = State.running and string.format("%.1fs", math.max(0, State.nextLoopTime - tick())) or "0.0s"

    local winReady = State.winID ~= nil
    local winLed = winReady and "●" or "○"
    local winColor = winReady and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 59, 48)
    local winTime = "0.0s"
    if State.autoWinEnabled and State.winID and State.running then
        if State.winClaimedThisLoop then
            winTime = "✅"
        else
            local claimTime = State.lastLoopTime + (State.coinDelay * CLAIM_RATIO)
            local remaining = claimTime - tick()
            winTime = string.format("%.1fs", math.max(0, remaining))
        end
    end

    local tokenReady = State.magicTokenID ~= nil
    local tokenLed = tokenReady and "●" or "○"
    local tokenColor = tokenReady and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 59, 48)
    local tokenTime = "0.0s"
    if State.autoTokenEnabled and State.magicTokenID and State.running then
        if State.tokenClaimedThisLoop then
            tokenTime = "✅"
        else
            local claimTime = State.lastLoopTime + (State.coinDelay * CLAIM_RATIO)
            local remaining = claimTime - tick()
            tokenTime = string.format("%.1fs", math.max(0, remaining))
        end
    end

    if GUI.CoinLabel then
        GUI.CoinLabel.Text = string.format("%s %s %s", coinLed, "Coin", coinTime)
        GUI.CoinLabel.TextColor3 = coinColor
    end
    if GUI.WinLabel then
        GUI.WinLabel.Text = string.format("%s %s %s", winLed, "Win", winTime)
        GUI.WinLabel.TextColor3 = winColor
    end
    if GUI.TokenLabel then
        GUI.TokenLabel.Text = string.format("%s %s %s", tokenLed, "Token", tokenTime)
        GUI.TokenLabel.TextColor3 = tokenColor
    end
    
    if GUI.SpeedLabel then
        if State.fullAuto then
            GUI.SpeedLabel.Text = string.format("Speed: %.2f 🔄", State.climbSpeed)
        else
            GUI.SpeedLabel.Text = string.format("Speed: %.2f", State.climbSpeed)
        end
    end
    
    -- Update Anti-AFK status di Utility tab
    if GUI.AntiAFKStatus then
        if State.antiAFKEnabled then
            local elapsed = tick() - State.antiAFKLastTrigger
            local minutes = math.floor(elapsed / 60)
            local secs = math.floor(elapsed % 60)
            GUI.AntiAFKStatus.Text = string.format("🟢 AFK: %02d:%02d", minutes, secs)
        else
            GUI.AntiAFKStatus.Text = "⏸ AFK: Off"
        end
    end
    
    if GUI.HiddenStatus then
        GUI.HiddenStatus.Text = State.hiddenEnabled and "🔴 Hidden: ON" or "🟢 Hidden: OFF"
        GUI.HiddenStatus.TextColor3 = State.hiddenEnabled and Color3.fromRGB(255, 59, 48) or Color3.fromRGB(52, 199, 89)
    end
end

local function UpdateStatusMessage()
    local isReady = State.jumpID ~= nil and State.landingID ~= nil

    if not isReady then
        if GUI.StatusLabel then
            GUI.StatusLabel.Text = "JUMP FIRST"
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 59, 48)
        end
    elseif State.running then
        local msg = "RUNNING..."
        if State.autoTokenEnabled then msg = msg .. " ⚡" end
        if State.autoWinEnabled then msg = msg .. " 🏆" end
        if State.fullAuto then msg = msg .. " 🔄" end
        if GUI.StatusLabel then
            GUI.StatusLabel.Text = msg
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(0, 122, 255)
        end
    else
        if GUI.StatusLabel then
            GUI.StatusLabel.Text = "READY!"
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(52, 199, 89)
        end
    end
end

local function UpdateStatus()
    local isReady = State.jumpID ~= nil and State.landingID ~= nil
    
    if isReady then
        State.isReady = true
        if State.running then
            if GUI.StartButton then
                GUI.StartButton.Text = "🛑 STOP"
                GUI.StartButton.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
            end
        else
            if GUI.StartButton then
                GUI.StartButton.Text = "▶ START"
                GUI.StartButton.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
            end
        end
    else
        State.isReady = false
        if GUI.StartButton then
            GUI.StartButton.Text = "⏸ START"
            GUI.StartButton.BackgroundColor3 = Color3.fromRGB(142, 142, 147)
        end
    end

    UpdateStatusMessage()
    UpdateStatusBar()
end

local function ShowTemporaryMessage(text, color, duration)
    if GUI.StatusLabel then
        local oldText = GUI.StatusLabel.Text
        local oldColor = GUI.StatusLabel.TextColor3
        GUI.StatusLabel.Text = text
        GUI.StatusLabel.TextColor3 = color
        task.delay(duration or 1.5, function()
            if State.hookEnabled and GUI.StatusLabel then
                GUI.StatusLabel.Text = oldText
                GUI.StatusLabel.TextColor3 = oldColor
            end
        end)
    end
end

------ REMOTE EVENT FUNCTIONS ------
local function SendRemoteEvent(eventName, ...)
    local args = {eventName, ...}
    ReplicatedStorage:WaitForChild("ProMgs"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end

local function SendJumpData()
    if State.jumpID then
        local height = CalculateHeight()
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
        local coinDelay = State.coinDelay

        State.winClaimedThisLoop = false
        State.tokenClaimedThisLoop = false
        State.lastLoopTime = tick()
        State.nextLoopTime = State.lastLoopTime + coinDelay

        SendJumpData()
        SendLandingData()

        if GUI.StatusLabel then
            GUI.StatusLabel.Text = "💰 COIN!"
            GUI.StatusLabel.TextColor3 = Color3.fromRGB(52, 199, 89)
            task.delay(0.3, function()
                if State.hookEnabled then UpdateStatusMessage() end
            end)
        end

        local winTokenClaimTime = State.lastLoopTime + (coinDelay * CLAIM_RATIO)

        while tick() < winTokenClaimTime and State.running and State.hookEnabled do
            UpdateStatusBar()
            task.wait(0.01)
        end

        if not State.running or not State.hookEnabled then break end

        if State.autoWinEnabled and State.winID then
            SendWinData()
            State.winClaimedThisLoop = true
            if GUI.StatusLabel then
                GUI.StatusLabel.Text = "🏆 WIN!"
                GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 204, 0)
                task.delay(0.3, function()
                    if State.hookEnabled then UpdateStatusMessage() end
                end)
            end
        end

        if State.autoTokenEnabled and State.magicTokenID then
            SendTokenData()
            State.tokenClaimedThisLoop = true
            if GUI.StatusLabel then
                GUI.StatusLabel.Text = "✨ TOKEN!"
                GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 204, 0)
                task.delay(0.3, function()
                    if State.hookEnabled then UpdateStatusMessage() end
                end)
            end
        end

        while tick() < State.nextLoopTime and State.running and State.hookEnabled do
            UpdateStatusBar()
            task.wait(0.01)
        end

        if not State.running or not State.hookEnabled then break end

        State.runTime = State.runTime + (tick() - State.lastLoopTime)
        if State.runTime >= PAUSE_INTERVAL then
            State.running = false
            if GUI.StatusLabel then
                GUI.StatusLabel.Text = "PAUSE 30s"
                GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 204, 0)
            end
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

------ CLIMB SPEED METER ------
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
                    if GUI.SpeedLabel then
                        GUI.SpeedLabel.Text = string.format("Speed: %.2f", State.climbSpeed)
                    end

                    if not State.lockSpeed then
                        UpdateHeight()
                        UpdateDelays()
                    end
                else
                    if totalTime > 0 and totalTime <= MIN_CLIMB_DURATION then
                        if GUI.StatusLabel then
                            GUI.StatusLabel.Text = "CLIMB >2s"
                            GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 204, 0)
                            task.delay(1.5, function()
                                if State.hookEnabled then UpdateStatusMessage() end
                            end)
                        end
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

------ ANTI-AFK LOGIC ------
local function InitAntiAFK()
    local player = Players.LocalPlayer
    
    State.antiAFKEnabled = true
    State.antiAFKLastTrigger = tick()
    
    -- Event ketika Anti-AFK dipicu
    player.Idled:Connect(function()
        if not State.antiAFKEnabled then return end
        
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        State.antiAFKLastTrigger = tick()
        
        -- Update status
        if GUI.AntiAFKStatus then
            GUI.AntiAFKStatus.TextColor3 = Color3.fromRGB(255, 200, 0)
            task.delay(0.8, function()
                if GUI.AntiAFKStatus and State.antiAFKEnabled then
                    GUI.AntiAFKStatus.TextColor3 = Color3.fromRGB(52, 199, 89)
                end
            end)
        end
        
        print("🔄 Anti-AFK triggered at " .. os.date("%X"))
    end)
    
    -- Update timer setiap 0.1 detik
    task.spawn(function()
        while State.antiAFKEnabled and State.hookEnabled do
            if GUI.AntiAFKStatus then
                local elapsed = tick() - State.antiAFKLastTrigger
                local minutes = math.floor(elapsed / 60)
                local secs = math.floor(elapsed % 60)
                GUI.AntiAFKStatus.Text = string.format("🟢 AFK: %02d:%02d", minutes, secs)
            end
            task.wait(0.1)
        end
    end)
    
    print("✅ Anti-AFK initialized!")
end

------ HIDDEN PLACE LOGIC ------
local function EnableFly(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    humanoid.PlatformStand = true
    State.isFlying = true

    State.bodyVelocity = Instance.new("BodyVelocity")
    State.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    State.bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
    State.bodyVelocity.Parent = character.HumanoidRootPart

    local function updateVelocity()
        if not State.bodyVelocity or not State.isFlying then return end

        local direction = Vector3.new(0, 0, 0)
        local rootPart = character.HumanoidRootPart

        if State.keysPressed[Enum.KeyCode.W] then
            direction = direction + rootPart.CFrame.LookVector
        end
        if State.keysPressed[Enum.KeyCode.S] then
            direction = direction - rootPart.CFrame.LookVector
        end
        if State.keysPressed[Enum.KeyCode.A] then
            direction = direction - rootPart.CFrame.RightVector
        end
        if State.keysPressed[Enum.KeyCode.D] then
            direction = direction + rootPart.CFrame.RightVector
        end
        if State.keysPressed[Enum.KeyCode.Space] then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if State.keysPressed[Enum.KeyCode.LeftControl] then
            direction = direction + Vector3.new(0, -1, 0)
        end

        if direction.Magnitude > 0 then
            State.bodyVelocity.Velocity = direction.Unit * 50
        else
            State.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
    end

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            State.keysPressed[input.KeyCode] = true
            updateVelocity()
        end
    end

    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            State.keysPressed[input.KeyCode] = nil
            updateVelocity()
        end
    end

    State.flyConnection = UserInputService.InputBegan:Connect(onInputBegan)
    UserInputService.InputEnded:Connect(onInputEnded)
end

local function DisableFly(character)
    State.isFlying = false
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end

    if State.bodyVelocity then
        State.bodyVelocity:Destroy()
        State.bodyVelocity = nil
    end

    if State.flyConnection then
        State.flyConnection:Disconnect()
        State.flyConnection = nil
    end

    State.keysPressed = {}
end

local function ToggleHiddenPlace()
    local player = Players.LocalPlayer
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        ShowTemporaryMessage("❌ No character!", Color3.fromRGB(255, 59, 48), 2)
        return
    end

    local rootPart = character.HumanoidRootPart

    if not State.hiddenEnabled then
        -- HIDE
        State.originalPosition = rootPart.CFrame
        rootPart.CFrame = CFrame.new(
            rootPart.Position.X,
            16000,
            rootPart.Position.Z
        )
        EnableFly(character)
        State.hiddenEnabled = true
        
        if GUI.HiddenButton then
            GUI.HiddenButton.Text = "🔴 RETURN"
            GUI.HiddenButton.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
        end
        if GUI.HiddenStatus then
            GUI.HiddenStatus.Text = "🔴 Hidden: ON"
            GUI.HiddenStatus.TextColor3 = Color3.fromRGB(255, 59, 48)
        end
        ShowTemporaryMessage("⬆️ Hidden Place Activated!", Color3.fromRGB(52, 199, 89), 2)
    else
        -- RETURN
        if State.originalPosition then
            rootPart.CFrame = State.originalPosition
        end
        DisableFly(character)
        State.hiddenEnabled = false
        
        if GUI.HiddenButton then
            GUI.HiddenButton.Text = "⬆️ HIDE"
            GUI.HiddenButton.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
        end
        if GUI.HiddenStatus then
            GUI.HiddenStatus.Text = "🟢 Hidden: OFF"
            GUI.HiddenStatus.TextColor3 = Color3.fromRGB(52, 199, 89)
        end
        ShowTemporaryMessage("⬇️ Returned to original position!", Color3.fromRGB(255, 204, 0), 2)
    end
end

------ SWITCH TAB FUNCTION ------
local function SwitchTab(tabName)
    State.currentTab = tabName
    
    for _, data in ipairs(SidebarButtons) do
        local btn = data.button
        local tab = data.tab
        if tab == tabName then
            btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
            btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end
    
    if GUI.MainContent then
        GUI.MainContent.Visible = (tabName == "Main")
    end
    if GUI.SettingsContent then
        GUI.SettingsContent.Visible = (tabName == "Settings")
    end
    if GUI.CreditsContent then
        GUI.CreditsContent.Visible = (tabName == "Credits")
    end
    if GUI.UtilityContent then
        GUI.UtilityContent.Visible = (tabName == "Utils")
    end
end

------ CREATE COMPACT GUI WITH SIDEBAR ------
local function CreateGUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    if playerGui:FindFirstChild("CAJT_UI") then
        playerGui:FindFirstChild("CAJT_UI"):Destroy()
    end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CAJT_UI"
    ScreenGui.Parent = playerGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = true

    -- Main Frame - UKURAN 50% LEBIH KECIL (250x240)
    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 250, 0, 240)
    MainFrame.Position = UDim2.new(0.5, -125, 0.5, -120)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BackgroundTransparency = 0.3
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    MainFrame.Draggable = true
    MainFrame.Active = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 20)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    TitleBar.BackgroundTransparency = 0.3
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8, 0, 0)
    TitleCorner.Parent = TitleBar

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0.7, 0, 1, 0)
    TitleText.Position = UDim2.new(0, 8, 0, 0)
    TitleText.Text = "⚡ CAJT"
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.BackgroundTransparency = 1
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 13
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 16, 0, 16)
    CloseBtn.Position = UDim2.new(1, -20, 0, 2)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 11
    CloseBtn.Parent = TitleBar
    CloseBtn.AutoButtonColor = false
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseBtn

    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 16, 0, 16)
    MinBtn.Position = UDim2.new(1, -38, 0, 2)
    MinBtn.Text = "−"
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 13
    MinBtn.Parent = TitleBar
    MinBtn.AutoButtonColor = false
    
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 4)
    MinCorner.Parent = MinBtn

    -- SIDEBAR (4 tabs: Main, Sets, Utils, Info)
    SidebarFrame = Instance.new("Frame")
    SidebarFrame.Size = UDim2.new(0, 60, 1, -20)
    SidebarFrame.Position = UDim2.new(0, 0, 0, 20)
    SidebarFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
    SidebarFrame.BackgroundTransparency = 0.3
    SidebarFrame.BorderSizePixel = 0
    SidebarFrame.Parent = MainFrame

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 0, 0, 8)
    SidebarCorner.Parent = SidebarFrame

    -- Sidebar Buttons (4 tabs)
    local tabs = {"Main", "Sets", "Utils", "Info"}
    local icons = {"🏠", "⚙️", "🛠️", "ℹ️"}
    
    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 22)
        btn.Position = UDim2.new(0, 3, 0, 3 + (i-1) * 25)
        btn.Text = icons[i] .. " " .. tab
        btn.TextColor3 = (i == 1) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
        btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(25, 25, 38)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 10
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = SidebarFrame
        btn.AutoButtonColor = false
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        table.insert(SidebarButtons, {
            button = btn,
            tab = tab
        })
        
        btn.MouseButton1Click:Connect(function()
            SwitchTab(tab)
        end)
        
        btn.MouseEnter:Connect(function()
            if State.currentTab ~= tab then
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
            end
        end)
        btn.MouseLeave:Connect(function()
            if State.currentTab ~= tab then
                btn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
            end
        end)
    end

    -- CONTENT FRAME
    ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -68, 1, -26)
    ContentFrame.Position = UDim2.new(0, 63, 0, 23)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    -- ===== MAIN TAB CONTENT =====
    GUI.MainContent = Instance.new("Frame")
    GUI.MainContent.Size = UDim2.new(1, 0, 1, 0)
    GUI.MainContent.Position = UDim2.new(0, 0, 0, 0)
    GUI.MainContent.BackgroundTransparency = 1
    GUI.MainContent.Parent = ContentFrame

    -- Status Labels
    GUI.CoinLabel = Instance.new("TextLabel")
    GUI.CoinLabel.Size = UDim2.new(1, 0, 0, 15)
    GUI.CoinLabel.Position = UDim2.new(0, 0, 0, 0)
    GUI.CoinLabel.Text = "Coin ○ 0.0s"
    GUI.CoinLabel.TextColor3 = Color3.fromRGB(255, 59, 48)
    GUI.CoinLabel.BackgroundTransparency = 1
    GUI.CoinLabel.Font = Enum.Font.GothamMedium
    GUI.CoinLabel.TextSize = 12
    GUI.CoinLabel.Parent = GUI.MainContent

    GUI.WinLabel = Instance.new("TextLabel")
    GUI.WinLabel.Size = UDim2.new(1, 0, 0, 15)
    GUI.WinLabel.Position = UDim2.new(0, 0, 0, 16)
    GUI.WinLabel.Text = "Win ○ 0.0s"
    GUI.WinLabel.TextColor3 = Color3.fromRGB(255, 59, 48)
    GUI.WinLabel.BackgroundTransparency = 1
    GUI.WinLabel.Font = Enum.Font.GothamMedium
    GUI.WinLabel.TextSize = 12
    GUI.WinLabel.Parent = GUI.MainContent

    GUI.TokenLabel = Instance.new("TextLabel")
    GUI.TokenLabel.Size = UDim2.new(1, 0, 0, 15)
    GUI.TokenLabel.Position = UDim2.new(0, 0, 0, 32)
    GUI.TokenLabel.Text = "Token ○ 0.0s"
    GUI.TokenLabel.TextColor3 = Color3.fromRGB(255, 59, 48)
    GUI.TokenLabel.BackgroundTransparency = 1
    GUI.TokenLabel.Font = Enum.Font.GothamMedium
    GUI.TokenLabel.TextSize = 12
    GUI.TokenLabel.Parent = GUI.MainContent

    GUI.SpeedLabel = Instance.new("TextLabel")
    GUI.SpeedLabel.Size = UDim2.new(1, 0, 0, 15)
    GUI.SpeedLabel.Position = UDim2.new(0, 0, 0, 48)
    GUI.SpeedLabel.Text = "Speed: 0"
    GUI.SpeedLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    GUI.SpeedLabel.BackgroundTransparency = 1
    GUI.SpeedLabel.Font = Enum.Font.GothamMedium
    GUI.SpeedLabel.TextSize = 12
    GUI.SpeedLabel.Parent = GUI.MainContent

    GUI.HeightLabel = Instance.new("TextLabel")
    GUI.HeightLabel.Size = UDim2.new(1, 0, 0, 15)
    GUI.HeightLabel.Position = UDim2.new(0, 0, 0, 64)
    GUI.HeightLabel.Text = "Height: 5000"
    GUI.HeightLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    GUI.HeightLabel.BackgroundTransparency = 1
    GUI.HeightLabel.Font = Enum.Font.GothamMedium
    GUI.HeightLabel.TextSize = 12
    GUI.HeightLabel.Parent = GUI.MainContent

    GUI.StatusLabel = Instance.new("TextLabel")
    GUI.StatusLabel.Size = UDim2.new(1, 0, 0, 15)
    GUI.StatusLabel.Position = UDim2.new(0, 0, 0, 80)
    GUI.StatusLabel.Text = "JUMP FIRST"
    GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 59, 48)
    GUI.StatusLabel.BackgroundTransparency = 1
    GUI.StatusLabel.Font = Enum.Font.GothamBold
    GUI.StatusLabel.TextSize = 12
    GUI.StatusLabel.Parent = GUI.MainContent

    -- Separator
    local Sep = Instance.new("Frame")
    Sep.Size = UDim2.new(1, 0, 0, 1)
    Sep.Position = UDim2.new(0, 0, 0, 98)
    Sep.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Sep.BackgroundTransparency = 0
    Sep.BorderSizePixel = 0
    Sep.Parent = GUI.MainContent

    -- Delay Input
    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(0.4, 0, 0, 18)
    DelayLabel.Position = UDim2.new(0, 0, 0, 103)
    DelayLabel.Text = "Delay:"
    DelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Font = Enum.Font.GothamMedium
    DelayLabel.TextSize = 11
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = GUI.MainContent

    GUI.DelayInput = Instance.new("TextBox")
    GUI.DelayInput.Size = UDim2.new(0.35, 0, 0, 18)
    GUI.DelayInput.Position = UDim2.new(0.5, 0, 0, 103)
    GUI.DelayInput.Text = tostring(DEFAULT_DELAY)
    GUI.DelayInput.PlaceholderText = "Sec"
    GUI.DelayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    GUI.DelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.DelayInput.Font = Enum.Font.GothamMedium
    GUI.DelayInput.TextSize = 11
    GUI.DelayInput.Parent = GUI.MainContent
    
    local DelayCorner = Instance.new("UICorner")
    DelayCorner.CornerRadius = UDim.new(0, 4)
    DelayCorner.Parent = GUI.DelayInput

    -- Toggle Buttons
    local toggleStates = {false, false, false, false}
    local toggleNames = {"Auto", "Lock", "Win", "Tkn"}
    local toggleButtons = {}

    for i = 1, 4 do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.43, 0, 0, 16)
        btn.Position = UDim2.new((i % 2 == 1) and 0 or 0.53, 0, 0, 126 + math.floor((i-1)/2) * 19)
        btn.Text = toggleNames[i] .. ": OFF"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 9
        btn.Parent = GUI.MainContent
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        toggleButtons[i] = btn
        
        btn.MouseButton1Click:Connect(function()
            toggleStates[i] = not toggleStates[i]
            btn.Text = toggleNames[i] .. ": " .. (toggleStates[i] and "ON" or "OFF")
            btn.BackgroundColor3 = toggleStates[i] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(50, 50, 60)
            
            if i == 1 then -- Full Auto
                State.fullAuto = toggleStates[i]
                if toggleStates[i] then
                    ShowTemporaryMessage("AUTO ON", Color3.fromRGB(52, 199, 89), 1.5)
                    UpdateDelays()
                else
                    ShowTemporaryMessage("AUTO OFF", Color3.fromRGB(255, 59, 48), 1.5)
                    local input = tonumber(GUI.DelayInput.Text)
                    if input and input > 0 then
                        State.coinDelay = input
                    else
                        State.coinDelay = DEFAULT_DELAY
                        GUI.DelayInput.Text = string.format("%.1f", DEFAULT_DELAY)
                    end
                    UpdateHeight()
                end
                UpdateStatusBar()
            elseif i == 2 then -- Lock Speed
                State.lockSpeed = toggleStates[i]
                if toggleStates[i] then
                    ShowTemporaryMessage("LOCKED", Color3.fromRGB(52, 199, 89), 1)
                else
                    ShowTemporaryMessage("UNLOCKED", Color3.fromRGB(142, 142, 147), 1)
                    if State.fullAuto then
                        UpdateDelays()
                    end
                end
            elseif i == 3 then -- Auto Win
                if State.winID then
                    State.autoWinEnabled = toggleStates[i]
                    if toggleStates[i] then
                        State.lastWinTime = tick()
                        UpdateDelays()
                    end
                    UpdateStatusBar()
                else
                    task.wait(0.1)
                    toggleStates[i] = false
                    btn.Text = "Win: OFF"
                    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                    State.autoWinEnabled = false
                end
            elseif i == 4 then -- Auto Token
                if State.magicTokenID then
                    State.autoTokenEnabled = toggleStates[i]
                    if toggleStates[i] then
                        UpdateDelays()
                    end
                    UpdateStatusBar()
                else
                    task.wait(0.1)
                    toggleStates[i] = false
                    btn.Text = "Tkn: OFF"
                    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                    State.autoTokenEnabled = false
                end
            end
        end)
    end

    -- Start Button
    GUI.StartButton = Instance.new("TextButton")
    GUI.StartButton.Size = UDim2.new(1, 0, 0, 20)
    GUI.StartButton.Position = UDim2.new(0, 0, 0, 170)
    GUI.StartButton.Text = "▶ START"
    GUI.StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.StartButton.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
    GUI.StartButton.Font = Enum.Font.GothamBold
    GUI.StartButton.TextSize = 12
    GUI.StartButton.Parent = GUI.MainContent
    
    local SBtnCorner = Instance.new("UICorner")
    SBtnCorner.CornerRadius = UDim.new(0, 6)
    SBtnCorner.Parent = GUI.StartButton

    -- ===== SETTINGS TAB CONTENT =====
    GUI.SettingsContent = Instance.new("Frame")
    GUI.SettingsContent.Size = UDim2.new(1, 0, 1, 0)
    GUI.SettingsContent.Position = UDim2.new(0, 0, 0, 0)
    GUI.SettingsContent.BackgroundTransparency = 1
    GUI.SettingsContent.Visible = false
    GUI.SettingsContent.Parent = ContentFrame

    local SettingsTitle = Instance.new("TextLabel")
    SettingsTitle.Size = UDim2.new(1, 0, 0, 25)
    SettingsTitle.Position = UDim2.new(0, 0, 0, 10)
    SettingsTitle.Text = "⚙️ Settings"
    SettingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    SettingsTitle.BackgroundTransparency = 1
    SettingsTitle.Font = Enum.Font.GothamBold
    SettingsTitle.TextSize = 15
    SettingsTitle.Parent = GUI.SettingsContent

    local SettingsDesc = Instance.new("TextLabel")
    SettingsDesc.Size = UDim2.new(1, 0, 0, 20)
    SettingsDesc.Position = UDim2.new(0, 0, 0, 40)
    SettingsDesc.Text = "Auto Coin Settings"
    SettingsDesc.TextColor3 = Color3.fromRGB(150, 150, 150)
    SettingsDesc.BackgroundTransparency = 1
    SettingsDesc.Font = Enum.Font.GothamMedium
    SettingsDesc.TextSize = 11
    SettingsDesc.Parent = GUI.SettingsContent

    local SDelayLabel = Instance.new("TextLabel")
    SDelayLabel.Size = UDim2.new(0.4, 0, 0, 18)
    SDelayLabel.Position = UDim2.new(0, 0, 0, 70)
    SDelayLabel.Text = "Coin Delay:"
    SDelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    SDelayLabel.BackgroundTransparency = 1
    SDelayLabel.Font = Enum.Font.GothamMedium
    SDelayLabel.TextSize = 11
    SDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    SDelayLabel.Parent = GUI.SettingsContent

    local SDelayInput = Instance.new("TextBox")
    SDelayInput.Size = UDim2.new(0.3, 0, 0, 18)
    SDelayInput.Position = UDim2.new(0.4, 0, 0, 70)
    SDelayInput.Text = tostring(DEFAULT_DELAY)
    SDelayInput.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    SDelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    SDelayInput.Font = Enum.Font.GothamMedium
    SDelayInput.TextSize = 11
    SDelayInput.Parent = GUI.SettingsContent
    
    local SDelayCorner = Instance.new("UICorner")
    SDelayCorner.CornerRadius = UDim.new(0, 4)
    SDelayCorner.Parent = SDelayInput

    -- ===== UTILITY TAB CONTENT =====
    GUI.UtilityContent = Instance.new("Frame")
    GUI.UtilityContent.Size = UDim2.new(1, 0, 1, 0)
    GUI.UtilityContent.Position = UDim2.new(0, 0, 0, 0)
    GUI.UtilityContent.BackgroundTransparency = 1
    GUI.UtilityContent.Visible = false
    GUI.UtilityContent.Parent = ContentFrame

    local UtilityTitle = Instance.new("TextLabel")
    UtilityTitle.Size = UDim2.new(1, 0, 0, 25)
    UtilityTitle.Position = UDim2.new(0, 0, 0, 5)
    UtilityTitle.Text = "🛠️ Utility"
    UtilityTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    UtilityTitle.BackgroundTransparency = 1
    UtilityTitle.Font = Enum.Font.GothamBold
    UtilityTitle.TextSize = 15
    UtilityTitle.Parent = GUI.UtilityContent

    -- Anti-AFK
    local AntiAFKLabel = Instance.new("TextLabel")
    AntiAFKLabel.Size = UDim2.new(0.6, 0, 0, 18)
    AntiAFKLabel.Position = UDim2.new(0, 0, 0, 35)
    AntiAFKLabel.Text = "Anti-AFK"
    AntiAFKLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    AntiAFKLabel.BackgroundTransparency = 1
    AntiAFKLabel.Font = Enum.Font.GothamMedium
    AntiAFKLabel.TextSize = 10
    AntiAFKLabel.TextXAlignment = Enum.TextXAlignment.Left
    AntiAFKLabel.Parent = GUI.UtilityContent

    GUI.AntiAFKButton = Instance.new("TextButton")
    GUI.AntiAFKButton.Size = UDim2.new(0.35, 0, 0, 18)
    GUI.AntiAFKButton.Position = UDim2.new(0.6, 0, 0, 35)
    GUI.AntiAFKButton.Text = "▶ ON"
    GUI.AntiAFKButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.AntiAFKButton.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
    GUI.AntiAFKButton.Font = Enum.Font.GothamMedium
    GUI.AntiAFKButton.TextSize = 10
    GUI.AntiAFKButton.Parent = GUI.UtilityContent
    GUI.AntiAFKButton.AutoButtonColor = false
    
    local AAFKCorner = Instance.new("UICorner")
    AAFKCorner.CornerRadius = UDim.new(0, 4)
    AAFKCorner.Parent = GUI.AntiAFKButton

    GUI.AntiAFKStatus = Instance.new("TextLabel")
    GUI.AntiAFKStatus.Size = UDim2.new(1, -10, 0, 16)
    GUI.AntiAFKStatus.Position = UDim2.new(0, 5, 0, 56)
    GUI.AntiAFKStatus.Text = "⏸ AFK: Off"
    GUI.AntiAFKStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    GUI.AntiAFKStatus.BackgroundTransparency = 1
    GUI.AntiAFKStatus.Font = Enum.Font.GothamMedium
    GUI.AntiAFKStatus.TextSize = 9
    GUI.AntiAFKStatus.TextXAlignment = Enum.TextXAlignment.Left
    GUI.AntiAFKStatus.Parent = GUI.UtilityContent

    -- Hidden Place
    local HiddenLabel = Instance.new("TextLabel")
    HiddenLabel.Size = UDim2.new(0.6, 0, 0, 18)
    HiddenLabel.Position = UDim2.new(0, 0, 0, 78)
    HiddenLabel.Text = "Hidden Place"
    HiddenLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    HiddenLabel.BackgroundTransparency = 1
    HiddenLabel.Font = Enum.Font.GothamMedium
    HiddenLabel.TextSize = 10
    HiddenLabel.TextXAlignment = Enum.TextXAlignment.Left
    HiddenLabel.Parent = GUI.UtilityContent

    GUI.HiddenButton = Instance.new("TextButton")
    GUI.HiddenButton.Size = UDim2.new(0.35, 0, 0, 18)
    GUI.HiddenButton.Position = UDim2.new(0.6, 0, 0, 78)
    GUI.HiddenButton.Text = "⬆️ HIDE"
    GUI.HiddenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.HiddenButton.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
    GUI.HiddenButton.Font = Enum.Font.GothamMedium
    GUI.HiddenButton.TextSize = 10
    GUI.HiddenButton.Parent = GUI.UtilityContent
    GUI.HiddenButton.AutoButtonColor = false
    
    local HCorner = Instance.new("UICorner")
    HCorner.CornerRadius = UDim.new(0, 4)
    HCorner.Parent = GUI.HiddenButton

    GUI.HiddenStatus = Instance.new("TextLabel")
    GUI.HiddenStatus.Size = UDim2.new(1, -10, 0, 16)
    GUI.HiddenStatus.Position = UDim2.new(0, 5, 0, 99)
    GUI.HiddenStatus.Text = "🟢 Hidden: OFF"
    GUI.HiddenStatus.TextColor3 = Color3.fromRGB(52, 199, 89)
    GUI.HiddenStatus.BackgroundTransparency = 1
    GUI.HiddenStatus.Font = Enum.Font.GothamMedium
    GUI.HiddenStatus.TextSize = 9
    GUI.HiddenStatus.TextXAlignment = Enum.TextXAlignment.Left
    GUI.HiddenStatus.Parent = GUI.UtilityContent

    -- ===== CREDITS TAB CONTENT =====
    GUI.CreditsContent = Instance.new("Frame")
    GUI.CreditsContent.Size = UDim2.new(1, 0, 1, 0)
    GUI.CreditsContent.Position = UDim2.new(0, 0, 0, 0)
    GUI.CreditsContent.BackgroundTransparency = 1
    GUI.CreditsContent.Visible = false
    GUI.CreditsContent.Parent = ContentFrame

    local CreditsTitle = Instance.new("TextLabel")
    CreditsTitle.Size = UDim2.new(1, 0, 0, 25)
    CreditsTitle.Position = UDim2.new(0, 0, 0, 10)
    CreditsTitle.Text = "ℹ️ Credits"
    CreditsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    CreditsTitle.BackgroundTransparency = 1
    CreditsTitle.Font = Enum.Font.GothamBold
    CreditsTitle.TextSize = 15
    CreditsTitle.Parent = GUI.CreditsContent

    local CreditsList = {
        "CAJT Auto Gacor",
        "Full Auto: 14400/(spd*1.5)",
        "Anti-AFK + Hidden Place",
        "Version 4.0 Compact",
        "✨ Enjoy!"
    }

    for i, text in ipairs(CreditsList) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, 40 + (i-1) * 22)
        label.Text = text
        label.TextColor3 = (i == #CreditsList) and Color3.fromRGB(255, 204, 0) or Color3.fromRGB(200, 200, 200)
        label.BackgroundTransparency = 1
        label.Font = (i == #CreditsList) and Enum.Font.GothamBold or Enum.Font.GothamMedium
        label.TextSize = (i == #CreditsList) and 13 or 11
        label.Parent = GUI.CreditsContent
    end

    -- ===== EVENT HANDLERS =====
    GUI.StartButton.MouseButton1Click:Connect(function()
        if State.isReady then
            State.running = not State.running
            if State.running then
                State.lastWinTime = tick()
                State.winClaimedThisLoop = false
                State.tokenClaimedThisLoop = false
                task.spawn(RunLoop)
            end
            UpdateStatus()
        end
    end)

    GUI.DelayInput:GetPropertyChangedSignal("Text"):Connect(function()
        if not State.fullAuto and not State.lockSpeed then
            UpdateDelays()
            if State.climbSpeed > 0 then
                UpdateHeight()
            end
        elseif State.fullAuto then
            local speed = State.climbSpeed
            if speed > 0 then
                local newDelay = CalculateFullAutoDelay(speed)
                State.coinDelay = newDelay
                GUI.DelayInput.Text = string.format("%.2f", newDelay)
            end
        end
    end)

    -- Anti-AFK Button
    GUI.AntiAFKButton.MouseButton1Click:Connect(function()
        State.antiAFKEnabled = not State.antiAFKEnabled
        if State.antiAFKEnabled then
            GUI.AntiAFKButton.Text = "⏹ OFF"
            GUI.AntiAFKButton.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
            State.antiAFKLastTrigger = tick()
            ShowTemporaryMessage("🟢 Anti-AFK ON", Color3.fromRGB(52, 199, 89), 1.5)
        else
            GUI.AntiAFKButton.Text = "▶ ON"
            GUI.AntiAFKButton.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
            GUI.AntiAFKStatus.Text = "⏸ AFK: Off"
            GUI.AntiAFKStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
            ShowTemporaryMessage("🔴 Anti-AFK OFF", Color3.fromRGB(255, 59, 48), 1.5)
        end
    end)

    -- Hidden Place Button
    GUI.HiddenButton.MouseButton1Click:Connect(ToggleHiddenPlace)

    CloseBtn.MouseButton1Click:Connect(function()
        State.hookEnabled = false
        -- Cleanup Hidden Place
        if State.hiddenEnabled then
            local character = Players.LocalPlayer.Character
            if character then
                DisableFly(character)
            end
        end
        ScreenGui:Destroy()
    end)

    CloseBtn.MouseEnter:Connect(function()
        CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    end)
    CloseBtn.MouseLeave:Connect(function()
        CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end)

    -- Minimize
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            MainFrame.Size = UDim2.new(0, 250, 0, 20)
            ContentFrame.Visible = false
            SidebarFrame.Visible = false
            MinBtn.Text = "+"
        else
            MainFrame.Size = UDim2.new(0, 250, 0, 240)
            ContentFrame.Visible = true
            SidebarFrame.Visible = true
            MinBtn.Text = "−"
        end
    end)

    MinBtn.MouseEnter:Connect(function()
        MinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    end)
    MinBtn.MouseLeave:Connect(function()
        MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    end)

    return ScreenGui
end

------ INITIALIZATION ------
print("=== AUTO COIN V4 COMPACT UI + UTILITY STARTING ===")

CreateGUI()
InitializeRemoteHook()
InitAntiAFK()  -- Start Anti-AFK (default: off)

local LocalPlayer = Players.LocalPlayer
if LocalPlayer.Character then
    SetupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(SetupCharacter)

UpdateDelays()
UpdateStatus()

print("=== AUTO COIN V4 COMPACT UI + UTILITY LOADED ===")
