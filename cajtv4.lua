--[[
    AUTO COIN V4 - VANILLA UI WITH SIDEBAR (COMPACT + FONT+1)
    Main Frame Height: 285 (konten tetap seperti sebelumnya)
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
local MAX_EXPONENT = 300

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
    antiAFKEnabled = true,
    antiAFKLastTrigger = 0,
    hiddenEnabled = false,
    isFlying = false,
    originalPosition = nil,
    bodyVelocity = nil,
    flyConnection = nil,
    keysPressed = {},
    -- Auto Collect states
    autoCollectEnabled = false,
    autoCollectSetting = nil,
    -- Hatch states
    hatchRunning = false,
    hatchDelay = 1,
    hatchHeroId = 7000001,
    hatchDrawCount = 10,
    hatchAutoDetect = false,
    hatchHookEnabled = false,
    hatchCoroutine = nil,
    hatchDrawEvent = nil,
    hatchOldNamecall = nil,
    -- Infinity Test states
    infinityRunning = false,
    infinityStopped = false,
    infinityHeroId = 7000001,
    infinityDelay = 5,
    infinityStartExp = 10,
    infinityCount = 15,
    infinityStep = 3,
    infinityIsOffMode = false,
    infinityLoopCount = 0,
    infinityResultCount = 0,
    infinityTotalTests = 0,
}

-- GUI Elements
local GUI = {}
local ScreenGui = nil
local MainFrame = nil
local ContentFrame = nil
local SidebarFrame = nil
local SidebarButtons = {}

------ TOGGLE SWITCH CREATOR ------
local function CreateToggleSwitch(parent, position, labelText, initialState, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 20)
    container.Position = position
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, 30, 0, 16)
    track.Position = UDim2.new(1, -30, 0.5, -8)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    track.BackgroundTransparency = 0
    track.BorderSizePixel = 0
    track.AutoButtonColor = false
    track.Text = ""
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 8)
    trackCorner.Parent = track

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BackgroundTransparency = 0
    knob.BorderSizePixel = 0
    knob.AutoButtonColor = false
    knob.Text = ""
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 6)
    knobCorner.Parent = knob

    local isOn = initialState or false
    local onToggle = callback or function() end

    local function updateSwitch()
        local targetPosition = isOn and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        local targetColor = isOn and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(60, 60, 70)

        TweenService:Create(track, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = targetColor
        }):Play()

        TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = targetPosition
        }):Play()
    end

    updateSwitch()

    local function toggle()
        isOn = not isOn
        updateSwitch()
        onToggle(isOn)
    end

    track.MouseButton1Click:Connect(toggle)
    knob.MouseButton1Click:Connect(toggle)

    return {
        setOn = function(value)
            isOn = value
            updateSwitch()
        end,
        isOn = function()
            return isOn
        end,
        toggle = toggle,
        getContainer = function()
            return container
        end
    }
end

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

    if GUI.AntiAFKStatus then
        if State.antiAFKEnabled then
            local elapsed = tick() - State.antiAFKLastTrigger
            local minutes = math.floor(elapsed / 60)
            local secs = math.floor(elapsed % 60)
            GUI.AntiAFKStatus.Text = string.format("🟢 AFK: %02d:%02d", minutes, secs)
            GUI.AntiAFKStatus.TextColor3 = Color3.fromRGB(52, 199, 89)
        else
            GUI.AntiAFKStatus.Text = "⏸ AFK: Off"
            GUI.AntiAFKStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end

    if GUI.HatchStatus then
        if State.hatchRunning then
            GUI.HatchStatus.Text = "🟢 Running | ID: " .. State.hatchHeroId .. " | " .. State.hatchDrawCount .. "x"
            GUI.HatchStatus.TextColor3 = Color3.fromRGB(52, 199, 89)
        else
            GUI.HatchStatus.Text = "⏸ Stopped"
            GUI.HatchStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end

    if GUI.InfinityStatus then
        if State.infinityRunning then
            if State.infinityIsOffMode then
                GUI.InfinityStatus.Text = "♾️ Loop #" .. State.infinityLoopCount
            else
                local percent = 0
                if State.infinityTotalTests > 0 then
                    percent = math.floor((State.infinityResultCount / State.infinityTotalTests) * 100)
                end
                GUI.InfinityStatus.Text = "⏳ " .. percent .. "% | e+" .. State.infinityStartExp
            end
            GUI.InfinityStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            GUI.InfinityStatus.Text = "⏸ Ready"
            GUI.InfinityStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
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
    State.antiAFKEnabled = false
    State.antiAFKLastTrigger = tick()

    player.Idled:Connect(function()
        if not State.antiAFKEnabled then return end
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        State.antiAFKLastTrigger = tick()
        if GUI.AntiAFKStatus then
            GUI.AntiAFKStatus.TextColor3 = Color3.fromRGB(255, 200, 0)
            task.delay(0.8, function()
                if GUI.AntiAFKStatus and State.antiAFKEnabled then
                    GUI.AntiAFKStatus.TextColor3 = Color3.fromRGB(52, 199, 89)
                end
            end)
        end
    end)

    task.spawn(function()
        while State.hookEnabled do
            if State.antiAFKEnabled and GUI.AntiAFKStatus then
                local elapsed = tick() - State.antiAFKLastTrigger
                local minutes = math.floor(elapsed / 60)
                local secs = math.floor(elapsed % 60)
                GUI.AntiAFKStatus.Text = string.format("🟢 AFK: %02d:%02d", minutes, secs)
            end
            task.wait(0.1)
        end
    end)
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
        if State.keysPressed[Enum.KeyCode.W] then direction = direction + rootPart.CFrame.LookVector end
        if State.keysPressed[Enum.KeyCode.S] then direction = direction - rootPart.CFrame.LookVector end
        if State.keysPressed[Enum.KeyCode.A] then direction = direction - rootPart.CFrame.RightVector end
        if State.keysPressed[Enum.KeyCode.D] then direction = direction + rootPart.CFrame.RightVector end
        if State.keysPressed[Enum.KeyCode.Space] then direction = direction + Vector3.new(0, 1, 0) end
        if State.keysPressed[Enum.KeyCode.LeftControl] then direction = direction + Vector3.new(0, -1, 0) end
        if direction.Magnitude > 0 then State.bodyVelocity.Velocity = direction.Unit * 50 else State.bodyVelocity.Velocity = Vector3.new(0, 0, 0) end
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
    if humanoid then humanoid.PlatformStand = false end
    if State.bodyVelocity then State.bodyVelocity:Destroy(); State.bodyVelocity = nil end
    if State.flyConnection then State.flyConnection:Disconnect(); State.flyConnection = nil end
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
        State.originalPosition = rootPart.CFrame
        rootPart.CFrame = CFrame.new(rootPart.Position.X, 16000, rootPart.Position.Z)
        EnableFly(character)
        State.hiddenEnabled = true
        ShowTemporaryMessage("⬆️ Hidden Place Activated!", Color3.fromRGB(52, 199, 89), 2)
    else
        if State.originalPosition then rootPart.CFrame = State.originalPosition end
        DisableFly(character)
        State.hiddenEnabled = false
        ShowTemporaryMessage("⬇️ Returned!", Color3.fromRGB(255, 204, 0), 2)
    end
end

------ AUTO COLLECT LOGIC ------
local function InitAutoCollect()
    local player = Players.LocalPlayer
    local setting = player:FindFirstChild("Setting")
    if setting then State.autoCollectSetting = setting:FindFirstChild("isAutoCllect") end
    if not State.autoCollectSetting then
        if not setting then setting = Instance.new("Folder"); setting.Name = "Setting"; setting.Parent = player end
        State.autoCollectSetting = Instance.new("IntValue")
        State.autoCollectSetting.Name = "isAutoCllect"
        State.autoCollectSetting.Value = 0
        State.autoCollectSetting.Parent = setting
    end
    State.autoCollectEnabled = true
end

local function ToggleAutoCollect()
    if not State.autoCollectEnabled then InitAutoCollect(); return end
    if not State.autoCollectSetting then
        ShowTemporaryMessage("❌ Setting not found!", Color3.fromRGB(255, 59, 48), 2)
        return
    end
    State.autoCollectSetting.Value = State.autoCollectSetting.Value == 1 and 0 or 1
    local isOn = State.autoCollectSetting.Value == 1
    ShowTemporaryMessage(isOn and "🟢 AutoCollect ON" or "🔴 AutoCollect OFF", isOn and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 59, 48), 1.5)
end

------ HATCH LOGIC ------
local function GetDrawHeroEvent()
    local success, event = pcall(function()
        return ReplicatedStorage:WaitForChild("Tool"):WaitForChild("DrawUp"):WaitForChild("Msg"):WaitForChild("DrawHero")
    end)
    if success and event then
        return event
    end
    return nil
end

local function InitHatchHook()
    State.hatchDrawEvent = GetDrawHeroEvent()

    if not State.hatchDrawEvent then
        if GUI.HatchStatus then
            GUI.HatchStatus.Text = "❌ Event DrawHero tidak ditemukan!"
            GUI.HatchStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
        return false
    end

    State.hatchOldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not State.hatchHookEnabled then
            return State.hatchOldNamecall(self, ...)
        end

        local args = {...}
        local method = getnamecallmethod()

        if self == State.hatchDrawEvent and method == "InvokeServer" then
            if #args >= 1 then
                local id = args[1]
                if type(id) == "number" and id > 0 then
                    if id ~= State.hatchHeroId then
                        State.hatchHeroId = id
                        if GUI.HatchIdBox then
                            GUI.HatchIdBox.Text = tostring(State.hatchHeroId)
                        end
                        if GUI.HatchDetectedLabel then
                            GUI.HatchDetectedLabel.Text = "✅ ID Terdeteksi: " .. State.hatchHeroId
                            GUI.HatchDetectedLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        end
                        if GUI.HatchStatus then
                            GUI.HatchStatus.Text = "🎯 ID: " .. State.hatchHeroId
                            GUI.HatchStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
                        end
                    end
                end
            end
        end

        return State.hatchOldNamecall(self, ...)
    end)

    if GUI.HatchStatus then
        GUI.HatchStatus.Text = "✅ Hook aktif. Menunggu InvokeServer..."
        GUI.HatchStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
    end
    return true
end

local function UnhookHatch()
    State.hatchHookEnabled = false
    State.hatchOldNamecall = nil
end

local function DrawHeroFunction()
    State.hatchDrawEvent = GetDrawHeroEvent()
    if not State.hatchDrawEvent then
        if GUI.HatchStatus then
            GUI.HatchStatus.Text = "❌ Event tidak ditemukan!"
            GUI.HatchStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
        return
    end

    local success, result = pcall(function()
        return State.hatchDrawEvent:InvokeServer(State.hatchHeroId, State.hatchDrawCount)
    end)

    if not success and GUI.HatchStatus then
        GUI.HatchStatus.Text = "❌ Error: " .. tostring(result)
        GUI.HatchStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end

local function HatchRunLoop()
    while State.hatchRunning do
        DrawHeroFunction()
        task.wait(State.hatchDelay)
    end
end

local function ToggleHatch()
    State.hatchRunning = not State.hatchRunning
    
    if State.hatchRunning then
        if GUI.HatchStartButton then
            GUI.HatchStartButton.Text = "⏹ STOP"
            GUI.HatchStartButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
        State.hatchCoroutine = coroutine.wrap(HatchRunLoop)
        State.hatchCoroutine()
        if GUI.HatchStatus then
            GUI.HatchStatus.Text = "▶️ Running | ID: " .. State.hatchHeroId .. " | " .. State.hatchDrawCount .. "x"
            GUI.HatchStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
        end
    else
        if GUI.HatchStartButton then
            GUI.HatchStartButton.Text = "▶ START"
            GUI.HatchStartButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        end
        if GUI.HatchStatus then
            GUI.HatchStatus.Text = "⏹️ Stopped"
            GUI.HatchStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    end
    UpdateStatusBar()
end

local function ToggleHatchAutoDetect()
    State.hatchAutoDetect = not State.hatchAutoDetect
    if State.hatchAutoDetect then
        if GUI.HatchAutoDetectButton then
            GUI.HatchAutoDetectButton.Text = "Auto: ON"
            GUI.HatchAutoDetectButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        end
        State.hatchHookEnabled = true
        InitHatchHook()
    else
        if GUI.HatchAutoDetectButton then
            GUI.HatchAutoDetectButton.Text = "Auto: OFF"
            GUI.HatchAutoDetectButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
        UnhookHatch()
    end
end

local function DetectHatchNow()
    if GUI.HatchStatus then
        GUI.HatchStatus.Text = "⏳ Mencoba mendeteksi ID..."
        GUI.HatchStatus.TextColor3 = Color3.fromRGB(255, 165, 0)
    end

    local tempEvent = GetDrawHeroEvent()
    if tempEvent then
        pcall(function()
            tempEvent:InvokeServer(1, State.hatchDrawCount)
            task.wait(0.3)
            tempEvent:InvokeServer(2, State.hatchDrawCount)
            task.wait(0.3)
        end)
    end

    if State.hatchHeroId == 7000117 then
        if GUI.HatchStatus then
            GUI.HatchStatus.Text = "❌ Tidak ada ID terdeteksi. Coba jalankan game."
            GUI.HatchStatus.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end

------ INFINITY TEST LOGIC ------
local function GetDrawHeroEventForInfinity()
    local success, event = pcall(function()
        return ReplicatedStorage:WaitForChild("Tool"):WaitForChild("DrawUp"):WaitForChild("Msg"):WaitForChild("DrawHero")
    end)
    if success and event then
        return event
    end
    return nil
end

local function InfinityAddResult(text, color)
    State.infinityResultCount = State.infinityResultCount + 1
    
    local resultLabel = Instance.new("TextLabel")
    resultLabel.Size = UDim2.new(1, -4, 0, 18)
    resultLabel.Position = UDim2.new(0, 2, 0, (State.infinityResultCount - 1) * 19)
    resultLabel.BackgroundTransparency = 1
    resultLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    resultLabel.Font = Enum.Font.GothamMedium
    resultLabel.TextSize = 11
    resultLabel.Text = text
    resultLabel.TextXAlignment = Enum.TextXAlignment.Left
    resultLabel.Parent = GUI.InfinityResultList
    
    local scrollFrame = GUI.InfinityScrollFrame
    if scrollFrame then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, State.infinityResultCount * 19 + 6)
        scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
    end
end

local function InfinityUpdateProgress(current, total)
    local percent = 0
    if total > 0 then
        percent = math.floor((current / total) * 100)
    end
    
    if GUI.InfinityProgressBar then
        GUI.InfinityProgressBar.Size = UDim2.new(percent / 100, 0, 1, 0)
    end
    if GUI.InfinityProgressText then
        GUI.InfinityProgressText.Text = percent .. "%"
    end
    
    local progressBar = GUI.InfinityProgressBar
    if progressBar then
        if percent < 30 then
            progressBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        elseif percent < 70 then
            progressBar.BackgroundColor3 = Color3.fromRGB(200, 200, 50)
        else
            progressBar.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        end
    end
end

local function InfinityRunTest()
    if State.infinityRunning then return end

    local drawEvent = GetDrawHeroEventForInfinity()
    if not drawEvent then
        ShowTemporaryMessage("❌ DrawHero event not found!", Color3.fromRGB(255, 59, 48), 2)
        return
    end

    local delay = tonumber(GUI.InfinityDelayBox and GUI.InfinityDelayBox.Text) or 5
    if delay < 0.1 then delay = 5 end

    local startExp = tonumber(GUI.InfinityStartBox and GUI.InfinityStartBox.Text) or 10
    if startExp < 1 then startExp = 10 end
    if startExp > MAX_EXPONENT then startExp = MAX_EXPONENT - 10 end

    local testCount = tonumber(GUI.InfinityCountBox and GUI.InfinityCountBox.Text) or 15
    if testCount < 1 then testCount = 15 end
    if testCount > 30 then testCount = 30 end

    local step = tonumber(GUI.InfinityStepButton and GUI.InfinityStepButton.Text) or 3
    State.infinityIsOffMode = (GUI.InfinityStepButton and GUI.InfinityStepButton.Text == "OFF") or false

    local heroId = tonumber(GUI.InfinityIdBox and GUI.InfinityIdBox.Text) or 7000001
    if GUI.InfinityIdBox then GUI.InfinityIdBox.Text = tostring(heroId) end

    State.infinityRunning = true
    State.infinityStopped = false
    State.infinityLoopCount = 0
    State.infinityHeroId = heroId
    State.infinityDelay = delay
    State.infinityStartExp = startExp
    State.infinityCount = testCount
    State.infinityStep = step

    if GUI.InfinityResultList then
        for _, child in pairs(GUI.InfinityResultList:GetChildren()) do child:Destroy() end
    end
    State.infinityResultCount = 0
    if GUI.InfinityScrollFrame then
        GUI.InfinityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    end

    if GUI.InfinityStartButton then
        GUI.InfinityStartButton.Visible = false
    end
    if GUI.InfinityStopButton then
        GUI.InfinityStopButton.Visible = true
    end
    
    if GUI.InfinityStatus then
        GUI.InfinityStatus.Text = "⏳ Running..."
        GUI.InfinityStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
    end

    InfinityAddResult("===== MULAI =====", Color3.fromRGB(100, 200, 255))
    InfinityAddResult(string.format("ID:%d | Dly:%.1fs", heroId, delay), Color3.fromRGB(200, 200, 200))

    if State.infinityIsOffMode then
        InfinityAddResult("♾️ MODE OFF: LOOP TANPA HENTI", Color3.fromRGB(255, 200, 0))
        InfinityAddResult("📌 Tekan STOP untuk berhenti", Color3.fromRGB(255, 200, 0))
        InfinityAddResult("", Color3.fromRGB(200, 200, 200))
        State.infinityTotalTests = 0
        
        if GUI.InfinityProgressText then
            GUI.InfinityProgressText.Text = "∞"
        end
        if GUI.InfinityProgressBar then
            GUI.InfinityProgressBar.Size = UDim2.new(1, 0, 1, 0)
            GUI.InfinityProgressBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        end

        while State.infinityRunning and not State.infinityStopped do
            State.infinityLoopCount = State.infinityLoopCount + 1
            local exp = startExp
            local value = 10 ^ exp

            if exp > MAX_EXPONENT then
                InfinityAddResult("⚠️ MELEWATI BATAS 300!", Color3.fromRGB(255, 200, 0))
                InfinityAddResult("⏹️ TEST DICANCEL OTOMATIS", Color3.fromRGB(255, 100, 0))
                break
            end

            local success, err = pcall(function()
                return drawEvent:InvokeServer(heroId, -value)
            end)

            local statusText = success and "✅" or "❌"
            local color = success and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

            if not success then
                InfinityAddResult(string.format("%s [%d] e+%d", statusText, State.infinityLoopCount, exp), color)
                InfinityAddResult("⏹️ GAGAL! STOP OTOMATIS", Color3.fromRGB(255, 100, 0))
                break
            end

            if State.infinityLoopCount % 5 == 0 then
                InfinityAddResult(string.format("%s [%d] e+%d", statusText, State.infinityLoopCount, exp), color)
            end

            if GUI.InfinityStatus then
                GUI.InfinityStatus.Text = string.format("♾️ Loop #%d | e+%d", State.infinityLoopCount, exp)
            end

            task.wait(delay)
        end

        if State.infinityStopped then
            InfinityAddResult("", Color3.fromRGB(200, 200, 200))
            InfinityAddResult("⏹️ DIHENTIKAN USER - Loop #" .. State.infinityLoopCount, Color3.fromRGB(255, 200, 0))
            if GUI.InfinityStatus then
                GUI.InfinityStatus.Text = "⏹️ Stopped - " .. State.infinityLoopCount .. " loops"
                GUI.InfinityStatus.TextColor3 = Color3.fromRGB(255, 200, 0)
            end
        else
            InfinityAddResult("", Color3.fromRGB(200, 200, 200))
            InfinityAddResult("⏹️ BERHENTI - Loop #" .. State.infinityLoopCount, Color3.fromRGB(255, 200, 0))
            if GUI.InfinityStatus then
                GUI.InfinityStatus.Text = "⏹️ Berhenti - " .. State.infinityLoopCount .. " loops"
                GUI.InfinityStatus.TextColor3 = Color3.fromRGB(255, 200, 0)
            end
        end

    else
        local maxPossibleExp = startExp + ((testCount - 1) * step)
        if maxPossibleExp > MAX_EXPONENT then
            local maxAllowed = math.floor((MAX_EXPONENT - startExp) / step) + 1
            if maxAllowed < 1 then
                InfinityAddResult("❌ Mulai terlalu tinggi!", Color3.fromRGB(255, 0, 0))
                InfinityAddResult("📊 Mulai max: " .. (MAX_EXPONENT - step), Color3.fromRGB(255, 200, 0))
                State.infinityRunning = false
                if GUI.InfinityStartButton then
                    GUI.InfinityStartButton.Visible = true
                end
                if GUI.InfinityStopButton then
                    GUI.InfinityStopButton.Visible = false
                end
                return
            end
            testCount = maxAllowed
            if GUI.InfinityCountBox then
                GUI.InfinityCountBox.Text = tostring(testCount)
            end
            InfinityAddResult("⚠️ Disesuaikan ke " .. testCount .. " test (max 300)", Color3.fromRGB(255, 200, 0))
        end

        State.infinityTotalTests = testCount
        InfinityAddResult(string.format("📊 1e+%d x%d | Step:%d", startExp, testCount, step), Color3.fromRGB(200, 200, 200))

        local testValues = {}
        for i = 0, testCount - 1 do
            local exp = startExp + (i * step)
            if exp > MAX_EXPONENT then break end
            table.insert(testValues, {value = 10 ^ exp, label = string.format("e+%d", exp)})
        end

        local lastSuccess = 0
        local firstFail = nil
        local currentTest = 0
        local stoppedByLimit = false

        for _, test in ipairs(testValues) do
            if State.infinityStopped then
                InfinityAddResult("⏹️ DIHENTIKAN", Color3.fromRGB(255, 200, 0))
                break
            end

            currentTest = currentTest + 1
            State.infinityResultCount = currentTest
            InfinityUpdateProgress(currentTest, State.infinityTotalTests)

            local exponent = math.floor(math.log10(test.value))
            if exponent > MAX_EXPONENT then
                InfinityAddResult("⚠️ MELEWATI BATAS 300!", Color3.fromRGB(255, 200, 0))
                stoppedByLimit = true
                break
            end

            local success, err = pcall(function()
                return drawEvent:InvokeServer(heroId, -test.value)
            end)

            local statusText = success and "✅" or "❌"
            local color = success and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            InfinityAddResult(string.format("%s %s", statusText, test.label), color)

            if success then
                lastSuccess = test.value
            else
                if not firstFail then
                    firstFail = test.value
                end
            end

            task.wait(delay)
        end

        InfinityAddResult("===== HASIL =====", Color3.fromRGB(100, 200, 255))

        if stoppedByLimit then
            InfinityAddResult("⛔ TEST DICANCEL (BATAS 300)", Color3.fromRGB(255, 100, 0))
            if GUI.InfinityStatus then
                GUI.InfinityStatus.Text = "⛔ Dicancel (Batas 300)"
                GUI.InfinityStatus.TextColor3 = Color3.fromRGB(255, 100, 0)
            end
        elseif firstFail then
            local maxExp = math.floor(math.log10(lastSuccess))
            local failExp = math.floor(math.log10(firstFail))
            InfinityAddResult(string.format("✅ Max: 1e+%d", maxExp), Color3.fromRGB(0, 255, 0))
            InfinityAddResult(string.format("❌ Fail: 1e+%d", failExp), Color3.fromRGB(255, 0, 0))
            local safeMin = math.max(1, maxExp - (step * 2))
            InfinityAddResult(string.format("📊 Aman: 1e+%d-1e+%d", safeMin, maxExp), Color3.fromRGB(255, 200, 0))
            if GUI.InfinityStatus then
                GUI.InfinityStatus.Text = string.format("✅ Selesai! Aman: 1e+%d", maxExp)
                GUI.InfinityStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
            end
        else
            if not State.infinityStopped then
                InfinityAddResult("✅ SEMUA BERHASIL!", Color3.fromRGB(0, 255, 0))
                if GUI.InfinityStatus then
                    GUI.InfinityStatus.Text = "✅ Semua berhasil!"
                    GUI.InfinityStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
                end
            end
        end
        InfinityUpdateProgress(State.infinityTotalTests, State.infinityTotalTests)
    end

    State.infinityRunning = false
    if GUI.InfinityStartButton then
        GUI.InfinityStartButton.Visible = true
        GUI.InfinityStartButton.Text = "▶ START"
        GUI.InfinityStartButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
    end
    if GUI.InfinityStopButton then
        GUI.InfinityStopButton.Visible = false
    end
    if not State.infinityIsOffMode then
        InfinityUpdateProgress(State.infinityTotalTests, State.infinityTotalTests)
    end
    UpdateStatusBar()
end

local function InfinityStopTest()
    if State.infinityRunning then
        State.infinityStopped = true
        if GUI.InfinityStatus then
            GUI.InfinityStatus.Text = "⏹️ Menghentikan..."
            GUI.InfinityStatus.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end
end

local function InfinityResetResults()
    if State.infinityRunning then return end
    if GUI.InfinityResultList then
        for _, child in pairs(GUI.InfinityResultList:GetChildren()) do child:Destroy() end
    end
    State.infinityResultCount = 0
    if GUI.InfinityScrollFrame then
        GUI.InfinityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    end
    if GUI.InfinityProgressBar then
        GUI.InfinityProgressBar.Size = UDim2.new(0, 0, 1, 0)
    end
    if GUI.InfinityProgressText then
        GUI.InfinityProgressText.Text = "0%"
    end
    if GUI.InfinityStatus then
        GUI.InfinityStatus.Text = "⏸ Ready"
        GUI.InfinityStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    InfinityAddResult("✅ Hasil dibersihkan", Color3.fromRGB(255, 200, 0))
end

------ LOADSTRING FUNCTIONS ------
local function LoadGUI(url, button, originalText)
    if button then
        button.Text = "⏳ Loading..."
        button.BackgroundColor3 = Color3.fromRGB(255, 204, 0)
    end
    
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        local func, err = loadstring(result)
        if func then
            pcall(func)
            ShowTemporaryMessage("✅ Loaded!", Color3.fromRGB(52, 199, 89), 1.5)
            print("✅ GUI loaded from: " .. url)
            if button then
                button.Text = "✅ Loaded"
                button.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
                task.delay(1.5, function()
                    if button then
                        button.Text = originalText or "Load"
                        button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                    end
                end)
            end
        else
            ShowTemporaryMessage("❌ Error: " .. tostring(err), Color3.fromRGB(255, 59, 48), 2)
            print("❌ Loadstring error:", err)
            if button then
                button.Text = "❌ Error"
                button.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                task.delay(1.5, function()
                    if button then
                        button.Text = originalText or "Load"
                        button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                    end
                end)
            end
        end
    else
        ShowTemporaryMessage("❌ Failed to load URL", Color3.fromRGB(255, 59, 48), 2)
        print("❌ Failed to load URL:", result)
        if button then
            button.Text = "❌ Failed"
            button.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            task.delay(1.5, function()
                if button then
                    button.Text = originalText or "Load"
                    button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                end
            end)
        end
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
    if GUI.MainContent then GUI.MainContent.Visible = (tabName == "Main") end
    if GUI.CoinContent then GUI.CoinContent.Visible = (tabName == "Coin+") end
    if GUI.CreditsContent then GUI.CreditsContent.Visible = (tabName == "Credits") end
    if GUI.UtilityContent then GUI.UtilityContent.Visible = (tabName == "Utils") end
    if GUI.HatchContent then GUI.HatchContent.Visible = (tabName == "Hatch") end
    if GUI.GoToContent then GUI.GoToContent.Visible = (tabName == "GoTo") end
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

    -- Main Frame - HEIGHT 285 (hanya ini yang diubah)
    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 250, 0, 285)
    MainFrame.Position = UDim2.new(0.5, -125, 0.5, -142.5)
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

    -- SIDEBAR (6 tabs)
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

    -- Sidebar Buttons (6 tabs)
    local tabs = {"Main", "Utils", "Hatch", "Coin+", "GoTo", "Info"}
    local icons = {"🏠", "🛠️", "🥚", "💎", "🚀", "ℹ️"}

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

    -- ===== MAIN TAB CONTENT (UKURAN NORMAL) =====
    GUI.MainContent = Instance.new("Frame")
    GUI.MainContent.Size = UDim2.new(1, 0, 1, 0)
    GUI.MainContent.Position = UDim2.new(0, 0, 0, 0)
    GUI.MainContent.BackgroundTransparency = 1
    GUI.MainContent.Parent = ContentFrame

    -- Status Labels (ukuran normal)
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

            if i == 1 then
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
            elseif i == 2 then
                State.lockSpeed = toggleStates[i]
                if toggleStates[i] then
                    ShowTemporaryMessage("LOCKED", Color3.fromRGB(52, 199, 89), 1)
                else
                    ShowTemporaryMessage("UNLOCKED", Color3.fromRGB(142, 142, 147), 1)
                    if State.fullAuto then
                        UpdateDelays()
                    end
                end
            elseif i == 3 then
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
            elseif i == 4 then
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

    -- ===== UTILITY TAB CONTENT (UKURAN NORMAL) =====
    GUI.UtilityContent = Instance.new("Frame")
    GUI.UtilityContent.Size = UDim2.new(1, 0, 1, 0)
    GUI.UtilityContent.Position = UDim2.new(0, 0, 0, 0)
    GUI.UtilityContent.BackgroundTransparency = 1
    GUI.UtilityContent.Visible = false
    GUI.UtilityContent.Parent = ContentFrame

    local UtilityTitle = Instance.new("TextLabel")
    UtilityTitle.Size = UDim2.new(1, 0, 0, 22)
    UtilityTitle.Position = UDim2.new(0, 0, 0, 3)
    UtilityTitle.Text = "🛠️ Utility"
    UtilityTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    UtilityTitle.BackgroundTransparency = 1
    UtilityTitle.Font = Enum.Font.GothamBold
    UtilityTitle.TextSize = 13
    UtilityTitle.Parent = GUI.UtilityContent

    -- Anti-AFK Toggle
    local antiAFKSwitch = CreateToggleSwitch(
        GUI.UtilityContent,
        UDim2.new(0, 0, 0, 28),
        "Anti-AFK",
        false,
        function(value)
            State.antiAFKEnabled = value
            if value then
                State.antiAFKLastTrigger = tick()
                ShowTemporaryMessage("🟢 Anti-AFK ON", Color3.fromRGB(52, 199, 89), 1.5)
            else
                ShowTemporaryMessage("🔴 Anti-AFK OFF", Color3.fromRGB(255, 59, 48), 1.5)
            end
            UpdateStatusBar()
        end
    )

    GUI.AntiAFKStatus = Instance.new("TextLabel")
    GUI.AntiAFKStatus.Size = UDim2.new(1, -10, 0, 14)
    GUI.AntiAFKStatus.Position = UDim2.new(0, 5, 0, 50)
    GUI.AntiAFKStatus.Text = "⏸ AFK: Off"
    GUI.AntiAFKStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    GUI.AntiAFKStatus.BackgroundTransparency = 1
    GUI.AntiAFKStatus.Font = Enum.Font.GothamMedium
    GUI.AntiAFKStatus.TextSize = 9
    GUI.AntiAFKStatus.TextXAlignment = Enum.TextXAlignment.Left
    GUI.AntiAFKStatus.Parent = GUI.UtilityContent

    -- Hidden Place Toggle
    local hiddenSwitch = CreateToggleSwitch(
        GUI.UtilityContent,
        UDim2.new(0, 0, 0, 70),
        "Hidden Place",
        false,
        function(value)
            if value then
                ToggleHiddenPlace()
            else
                if State.hiddenEnabled then
                    ToggleHiddenPlace()
                end
            end
        end
    )

    -- Auto Collect Toggle
    local autoCollectSwitch = CreateToggleSwitch(
        GUI.UtilityContent,
        UDim2.new(0, 0, 0, 94),
        "Auto Collect",
        false,
        function(value)
            if not State.autoCollectEnabled then
                InitAutoCollect()
            end
            if State.autoCollectSetting then
                State.autoCollectSetting.Value = value and 1 or 0
                ShowTemporaryMessage(
                    value and "🟢 AutoCollect ON" or "🔴 AutoCollect OFF",
                    value and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 59, 48),
                    1.5
                )
            end
        end
    )

    -- Shortcut info
    local ShortcutLabel = Instance.new("TextLabel")
    ShortcutLabel.Size = UDim2.new(1, -10, 0, 14)
    ShortcutLabel.Position = UDim2.new(0, 5, 0, 118)
    ShortcutLabel.Text = "⌨️ Press 'A' to toggle Auto Collect"
    ShortcutLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
    ShortcutLabel.BackgroundTransparency = 1
    ShortcutLabel.Font = Enum.Font.GothamMedium
    ShortcutLabel.TextSize = 8
    ShortcutLabel.TextXAlignment = Enum.TextXAlignment.Left
    ShortcutLabel.Parent = GUI.UtilityContent

    -- ===== HATCH TAB CONTENT (UKURAN NORMAL) =====
    GUI.HatchContent = Instance.new("Frame")
    GUI.HatchContent.Size = UDim2.new(1, 0, 1, 0)
    GUI.HatchContent.Position = UDim2.new(0, 0, 0, 0)
    GUI.HatchContent.BackgroundTransparency = 1
    GUI.HatchContent.Visible = false
    GUI.HatchContent.Parent = ContentFrame

    local HatchTitle = Instance.new("TextLabel")
    HatchTitle.Size = UDim2.new(1, 0, 0, 22)
    HatchTitle.Position = UDim2.new(0, 0, 0, 3)
    HatchTitle.Text = "🥚 Auto Hatch"
    HatchTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    HatchTitle.BackgroundTransparency = 1
    HatchTitle.Font = Enum.Font.GothamBold
    HatchTitle.TextSize = 13
    HatchTitle.Parent = GUI.HatchContent

    -- Status
    GUI.HatchStatus = Instance.new("TextLabel")
    GUI.HatchStatus.Size = UDim2.new(1, -10, 0, 14)
    GUI.HatchStatus.Position = UDim2.new(0, 5, 0, 28)
    GUI.HatchStatus.Text = "⏸ Stopped"
    GUI.HatchStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    GUI.HatchStatus.BackgroundTransparency = 1
    GUI.HatchStatus.Font = Enum.Font.GothamMedium
    GUI.HatchStatus.TextSize = 9
    GUI.HatchStatus.TextXAlignment = Enum.TextXAlignment.Left
    GUI.HatchStatus.Parent = GUI.HatchContent

    -- Draw Count
    local DrawLabel = Instance.new("TextLabel")
    DrawLabel.Size = UDim2.new(0.25, 0, 0, 16)
    DrawLabel.Position = UDim2.new(0, 5, 0, 46)
    DrawLabel.Text = "Draw:"
    DrawLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    DrawLabel.BackgroundTransparency = 1
    DrawLabel.Font = Enum.Font.GothamMedium
    DrawLabel.TextSize = 9
    DrawLabel.TextXAlignment = Enum.TextXAlignment.Right
    DrawLabel.Parent = GUI.HatchContent

    local DrawBtnFrame = Instance.new("Frame")
    DrawBtnFrame.Size = UDim2.new(0.6, 0, 0, 16)
    DrawBtnFrame.Position = UDim2.new(0.28, 0, 0, 46)
    DrawBtnFrame.BackgroundTransparency = 1
    DrawBtnFrame.Parent = GUI.HatchContent

    local Draw1Btn = Instance.new("TextButton")
    Draw1Btn.Size = UDim2.new(0.3, -3, 1, 0)
    Draw1Btn.Position = UDim2.new(0, 0, 0, 0)
    Draw1Btn.Text = "1x"
    Draw1Btn.Font = Enum.Font.GothamMedium
    Draw1Btn.TextSize = 9
    Draw1Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Draw1Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Draw1Btn.BackgroundTransparency = 0.3
    Draw1Btn.BorderSizePixel = 0
    Draw1Btn.Parent = DrawBtnFrame
    Draw1Btn.AutoButtonColor = false

    local Draw1Corner = Instance.new("UICorner")
    Draw1Corner.CornerRadius = UDim.new(0, 4)
    Draw1Corner.Parent = Draw1Btn

    local Draw3Btn = Instance.new("TextButton")
    Draw3Btn.Size = UDim2.new(0.3, -3, 1, 0)
    Draw3Btn.Position = UDim2.new(0.35, 0, 0, 0)
    Draw3Btn.Text = "3x"
    Draw3Btn.Font = Enum.Font.GothamMedium
    Draw3Btn.TextSize = 9
    Draw3Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Draw3Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Draw3Btn.BackgroundTransparency = 0.3
    Draw3Btn.BorderSizePixel = 0
    Draw3Btn.Parent = DrawBtnFrame
    Draw3Btn.AutoButtonColor = false

    local Draw3Corner = Instance.new("UICorner")
    Draw3Corner.CornerRadius = UDim.new(0, 4)
    Draw3Corner.Parent = Draw3Btn

    local Draw10Btn = Instance.new("TextButton")
    Draw10Btn.Size = UDim2.new(0.3, -3, 1, 0)
    Draw10Btn.Position = UDim2.new(0.7, 0, 0, 0)
    Draw10Btn.Text = "10x"
    Draw10Btn.Font = Enum.Font.GothamMedium
    Draw10Btn.TextSize = 9
    Draw10Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Draw10Btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    Draw10Btn.BackgroundTransparency = 0.3
    Draw10Btn.BorderSizePixel = 0
    Draw10Btn.Parent = DrawBtnFrame
    Draw10Btn.AutoButtonColor = false

    local Draw10Corner = Instance.new("UICorner")
    Draw10Corner.CornerRadius = UDim.new(0, 4)
    Draw10Corner.Parent = Draw10Btn

    -- Auto Detect Toggle
    GUI.HatchAutoDetectButton = Instance.new("TextButton")
    GUI.HatchAutoDetectButton.Size = UDim2.new(0.2, -5, 0, 16)
    GUI.HatchAutoDetectButton.Position = UDim2.new(0.7, 0, 0, 66)
    GUI.HatchAutoDetectButton.Text = "Auto: ON"
    GUI.HatchAutoDetectButton.Font = Enum.Font.GothamMedium
    GUI.HatchAutoDetectButton.TextSize = 8
    GUI.HatchAutoDetectButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    GUI.HatchAutoDetectButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    GUI.HatchAutoDetectButton.BackgroundTransparency = 0.3
    GUI.HatchAutoDetectButton.BorderSizePixel = 0
    GUI.HatchAutoDetectButton.Parent = GUI.HatchContent
    GUI.HatchAutoDetectButton.AutoButtonColor = false

    local HatchAutoDetectCorner = Instance.new("UICorner")
    HatchAutoDetectCorner.CornerRadius = UDim.new(0, 4)
    HatchAutoDetectCorner.Parent = GUI.HatchAutoDetectButton

    -- ID Input
    local IdLabel = Instance.new("TextLabel")
    IdLabel.Size = UDim2.new(0.15, 0, 0, 16)
    IdLabel.Position = UDim2.new(0, 5, 0, 66)
    IdLabel.Text = "ID:"
    IdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    IdLabel.BackgroundTransparency = 1
    IdLabel.Font = Enum.Font.GothamMedium
    IdLabel.TextSize = 9
    IdLabel.TextXAlignment = Enum.TextXAlignment.Right
    IdLabel.Parent = GUI.HatchContent

    GUI.HatchIdBox = Instance.new("TextBox")
    GUI.HatchIdBox.Size = UDim2.new(0.35, 0, 0, 16)
    GUI.HatchIdBox.Position = UDim2.new(0.18, 0, 0, 66)
    GUI.HatchIdBox.Text = tostring(State.hatchHeroId)
    GUI.HatchIdBox.PlaceholderText = "Hero ID"
    GUI.HatchIdBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    GUI.HatchIdBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    GUI.HatchIdBox.BackgroundTransparency = 0.3
    GUI.HatchIdBox.Font = Enum.Font.GothamMedium
    GUI.HatchIdBox.TextSize = 9
    GUI.HatchIdBox.Parent = GUI.HatchContent

    local HatchIdBoxCorner = Instance.new("UICorner")
    HatchIdBoxCorner.CornerRadius = UDim.new(0, 4)
    HatchIdBoxCorner.Parent = GUI.HatchIdBox

    -- Detect Now Button
    local DetectNowBtn = Instance.new("TextButton")
    DetectNowBtn.Size = UDim2.new(0.2, -5, 0, 16)
    DetectNowBtn.Position = UDim2.new(0.55, 0, 0, 66)
    DetectNowBtn.Text = "Detect!"
    DetectNowBtn.Font = Enum.Font.GothamMedium
    DetectNowBtn.TextSize = 9
    DetectNowBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    DetectNowBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
    DetectNowBtn.BackgroundTransparency = 0.3
    DetectNowBtn.BorderSizePixel = 0
    DetectNowBtn.Parent = GUI.HatchContent
    DetectNowBtn.AutoButtonColor = false

    local DetectNowCorner = Instance.new("UICorner")
    DetectNowCorner.CornerRadius = UDim.new(0, 4)
    DetectNowCorner.Parent = DetectNowBtn

    -- Delay Input
    local DelayLabel2 = Instance.new("TextLabel")
    DelayLabel2.Size = UDim2.new(0.15, 0, 0, 16)
    DelayLabel2.Position = UDim2.new(0, 5, 0, 86)
    DelayLabel2.Text = "Delay:"
    DelayLabel2.TextColor3 = Color3.fromRGB(200, 200, 200)
    DelayLabel2.BackgroundTransparency = 1
    DelayLabel2.Font = Enum.Font.GothamMedium
    DelayLabel2.TextSize = 9
    DelayLabel2.TextXAlignment = Enum.TextXAlignment.Right
    DelayLabel2.Parent = GUI.HatchContent

    GUI.HatchDelayBox = Instance.new("TextBox")
    GUI.HatchDelayBox.Size = UDim2.new(0.2, 0, 0, 16)
    GUI.HatchDelayBox.Position = UDim2.new(0.18, 0, 0, 86)
    GUI.HatchDelayBox.Text = tostring(State.hatchDelay)
    GUI.HatchDelayBox.PlaceholderText = "Delay"
    GUI.HatchDelayBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    GUI.HatchDelayBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    GUI.HatchDelayBox.BackgroundTransparency = 0.3
    GUI.HatchDelayBox.Font = Enum.Font.GothamMedium
    GUI.HatchDelayBox.TextSize = 9
    GUI.HatchDelayBox.Parent = GUI.HatchContent

    local HatchDelayBoxCorner = Instance.new("UICorner")
    HatchDelayBoxCorner.CornerRadius = UDim.new(0, 4)
    HatchDelayBoxCorner.Parent = GUI.HatchDelayBox

    -- Start/Stop Button
    GUI.HatchStartButton = Instance.new("TextButton")
    GUI.HatchStartButton.Size = UDim2.new(0.45, -10, 0, 16)
    GUI.HatchStartButton.Position = UDim2.new(0.38, 0, 0, 86)
    GUI.HatchStartButton.Text = "▶ START"
    GUI.HatchStartButton.Font = Enum.Font.GothamMedium
    GUI.HatchStartButton.TextSize = 9
    GUI.HatchStartButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    GUI.HatchStartButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    GUI.HatchStartButton.BackgroundTransparency = 0.3
    GUI.HatchStartButton.BorderSizePixel = 0
    GUI.HatchStartButton.Parent = GUI.HatchContent
    GUI.HatchStartButton.AutoButtonColor = false

    local HatchStartCorner = Instance.new("UICorner")
    HatchStartCorner.CornerRadius = UDim.new(0, 4)
    HatchStartCorner.Parent = GUI.HatchStartButton

    -- Detected ID Label
    GUI.HatchDetectedLabel = Instance.new("TextLabel")
    GUI.HatchDetectedLabel.Size = UDim2.new(1, -10, 0, 14)
    GUI.HatchDetectedLabel.Position = UDim2.new(0, 5, 0, 106)
    GUI.HatchDetectedLabel.Text = "ID Terdeteksi: -"
    GUI.HatchDetectedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    GUI.HatchDetectedLabel.BackgroundTransparency = 1
    GUI.HatchDetectedLabel.Font = Enum.Font.GothamMedium
    GUI.HatchDetectedLabel.TextSize = 8
    GUI.HatchDetectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    GUI.HatchDetectedLabel.Parent = GUI.HatchContent

    -- Draw Count Display
    local HatchDrawDisplay = Instance.new("TextLabel")
    HatchDrawDisplay.Size = UDim2.new(1, -10, 0, 14)
    HatchDrawDisplay.Position = UDim2.new(0, 5, 0, 122)
    HatchDrawDisplay.Text = "Draw: 10x"
    HatchDrawDisplay.TextColor3 = Color3.fromRGB(100, 200, 100)
    HatchDrawDisplay.BackgroundTransparency = 1
    HatchDrawDisplay.Font = Enum.Font.GothamMedium
    HatchDrawDisplay.TextSize = 8
    HatchDrawDisplay.TextXAlignment = Enum.TextXAlignment.Center
    HatchDrawDisplay.Parent = GUI.HatchContent

    -- Hatch Event Handlers
    local function UpdateDrawButtons(selected)
        Draw1Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Draw3Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Draw10Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

        if selected == 1 then
            Draw1Btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
            HatchDrawDisplay.Text = "Draw: 1x"
        elseif selected == 3 then
            Draw3Btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
            HatchDrawDisplay.Text = "Draw: 3x"
        elseif selected == 10 then
            Draw10Btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
            HatchDrawDisplay.Text = "Draw: 10x"
        end
        State.hatchDrawCount = selected
    end

    Draw1Btn.MouseButton1Click:Connect(function() UpdateDrawButtons(1) end)
    Draw3Btn.MouseButton1Click:Connect(function() UpdateDrawButtons(3) end)
    Draw10Btn.MouseButton1Click:Connect(function() UpdateDrawButtons(10) end)

    -- Hover effects for draw buttons
    local function SetupDrawHover(btn)
        btn.MouseEnter:Connect(function()
            if btn.BackgroundColor3 ~= Color3.fromRGB(40, 180, 40) then
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end)
        btn.MouseLeave:Connect(function()
            if btn.BackgroundColor3 ~= Color3.fromRGB(40, 180, 40) then
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            end
        end)
    end
    SetupDrawHover(Draw1Btn)
    SetupDrawHover(Draw3Btn)
    SetupDrawHover(Draw10Btn)

    -- Hatch button events
    GUI.HatchStartButton.MouseButton1Click:Connect(ToggleHatch)

    GUI.HatchAutoDetectButton.MouseButton1Click:Connect(ToggleHatchAutoDetect)

    DetectNowBtn.MouseButton1Click:Connect(DetectHatchNow)

    GUI.HatchIdBox.FocusLost:Connect(function()
        local newId = tonumber(GUI.HatchIdBox.Text)
        if newId and newId > 0 then
            State.hatchHeroId = newId
            if GUI.HatchStatus then
                GUI.HatchStatus.Text = "ID manual: " .. State.hatchHeroId
                GUI.HatchStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
            end
            if GUI.HatchDetectedLabel then
                GUI.HatchDetectedLabel.Text = "📌 ID Manual: " .. State.hatchHeroId
                GUI.HatchDetectedLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            end
        else
            GUI.HatchIdBox.Text = tostring(State.hatchHeroId)
        end
    end)

    GUI.HatchDelayBox.FocusLost:Connect(function()
        local newDelay = tonumber(GUI.HatchDelayBox.Text)
        if newDelay and newDelay > 0 then
            State.hatchDelay = newDelay
            if GUI.HatchStatus then
                GUI.HatchStatus.Text = "Delay: " .. State.hatchDelay .. "s"
                GUI.HatchStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
            end
        else
            GUI.HatchDelayBox.Text = tostring(State.hatchDelay)
        end
    end)

    -- Hover effects
    GUI.HatchStartButton.MouseEnter:Connect(function()
        if State.hatchRunning then
            GUI.HatchStartButton.BackgroundColor3 = Color3.fromRGB(140, 50, 50)
        else
            GUI.HatchStartButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end)
    GUI.HatchStartButton.MouseLeave:Connect(function()
        if State.hatchRunning then
            GUI.HatchStartButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        else
            GUI.HatchStartButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        end
    end)

    GUI.HatchAutoDetectButton.MouseEnter:Connect(function()
        if State.hatchAutoDetect then
            GUI.HatchAutoDetectButton.BackgroundColor3 = Color3.fromRGB(60, 220, 60)
        else
            GUI.HatchAutoDetectButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        end
    end)
    GUI.HatchAutoDetectButton.MouseLeave:Connect(function()
        if State.hatchAutoDetect then
            GUI.HatchAutoDetectButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        else
            GUI.HatchAutoDetectButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
    end)

    DetectNowBtn.MouseEnter:Connect(function()
        DetectNowBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 220)
    end)
    DetectNowBtn.MouseLeave:Connect(function()
        DetectNowBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
    end)

    -- ===== COIN+ TAB CONTENT =====
    GUI.CoinContent = Instance.new("Frame")
    GUI.CoinContent.Size = UDim2.new(1, 0, 1, 0)
    GUI.CoinContent.Position = UDim2.new(0, 0, 0, 0)
    GUI.CoinContent.BackgroundTransparency = 1
    GUI.CoinContent.Visible = false
    GUI.CoinContent.Parent = ContentFrame

    -- Status
    GUI.InfinityStatus = Instance.new("TextLabel")
    GUI.InfinityStatus.Size = UDim2.new(1, -10, 0, 14)
    GUI.InfinityStatus.Position = UDim2.new(0, 5, 0, 2)
    GUI.InfinityStatus.Text = "⏸ Ready"
    GUI.InfinityStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    GUI.InfinityStatus.BackgroundTransparency = 1
    GUI.InfinityStatus.Font = Enum.Font.GothamMedium
    GUI.InfinityStatus.TextSize = 9
    GUI.InfinityStatus.TextXAlignment = Enum.TextXAlignment.Left
    GUI.InfinityStatus.Parent = GUI.CoinContent

    -- Control Grid
    local ControlGrid = Instance.new("Frame")
    ControlGrid.Size = UDim2.new(1, -10, 0, 90)
    ControlGrid.Position = UDim2.new(0, 5, 0, 18)
    ControlGrid.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    ControlGrid.BackgroundTransparency = 0.3
    ControlGrid.BorderSizePixel = 0
    ControlGrid.Parent = GUI.CoinContent

    local ControlCorner = Instance.new("UICorner")
    ControlCorner.CornerRadius = UDim.new(0, 4)
    ControlCorner.Parent = ControlGrid

    -- Row 1: Delay & ID
    local DelayLbl = Instance.new("TextLabel")
    DelayLbl.Size = UDim2.new(0.15, 0, 0, 14)
    DelayLbl.Position = UDim2.new(0.02, 0, 0, 2)
    DelayLbl.BackgroundTransparency = 1
    DelayLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    DelayLbl.Font = Enum.Font.GothamMedium
    DelayLbl.TextSize = 9
    DelayLbl.Text = "Dly:"
    DelayLbl.TextXAlignment = Enum.TextXAlignment.Right
    DelayLbl.Parent = ControlGrid

    GUI.InfinityDelayBox = Instance.new("TextBox")
    GUI.InfinityDelayBox.Size = UDim2.new(0.15, 0, 0, 16)
    GUI.InfinityDelayBox.Position = UDim2.new(0.18, 0, 0, 1)
    GUI.InfinityDelayBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    GUI.InfinityDelayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.InfinityDelayBox.Font = Enum.Font.GothamMedium
    GUI.InfinityDelayBox.TextSize = 9
    GUI.InfinityDelayBox.Text = "5"
    GUI.InfinityDelayBox.ClearTextOnFocus = false
    GUI.InfinityDelayBox.Parent = ControlGrid

    local DBoxCorner = Instance.new("UICorner")
    DBoxCorner.CornerRadius = UDim.new(0, 2)
    DBoxCorner.Parent = GUI.InfinityDelayBox

    local IDLbl = Instance.new("TextLabel")
    IDLbl.Size = UDim2.new(0.12, 0, 0, 14)
    IDLbl.Position = UDim2.new(0.38, 0, 0, 2)
    IDLbl.BackgroundTransparency = 1
    IDLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    IDLbl.Font = Enum.Font.GothamMedium
    IDLbl.TextSize = 9
    IDLbl.Text = "ID:"
    IDLbl.TextXAlignment = Enum.TextXAlignment.Right
    IDLbl.Parent = ControlGrid

    GUI.InfinityIdBox = Instance.new("TextBox")
    GUI.InfinityIdBox.Size = UDim2.new(0.2, 0, 0, 16)
    GUI.InfinityIdBox.Position = UDim2.new(0.5, 0, 0, 1)
    GUI.InfinityIdBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    GUI.InfinityIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.InfinityIdBox.Font = Enum.Font.GothamMedium
    GUI.InfinityIdBox.TextSize = 9
    GUI.InfinityIdBox.Text = "7000001"
    GUI.InfinityIdBox.ClearTextOnFocus = false
    GUI.InfinityIdBox.Parent = ControlGrid

    local IDBoxCorner = Instance.new("UICorner")
    IDBoxCorner.CornerRadius = UDim.new(0, 2)
    IDBoxCorner.Parent = GUI.InfinityIdBox

    -- Row 2: Count & Start
    local CountLbl = Instance.new("TextLabel")
    CountLbl.Size = UDim2.new(0.15, 0, 0, 14)
    CountLbl.Position = UDim2.new(0.02, 0, 0, 20)
    CountLbl.BackgroundTransparency = 1
    CountLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    CountLbl.Font = Enum.Font.GothamMedium
    CountLbl.TextSize = 9
    CountLbl.Text = "Jml:"
    CountLbl.TextXAlignment = Enum.TextXAlignment.Right
    CountLbl.Parent = ControlGrid

    GUI.InfinityCountBox = Instance.new("TextBox")
    GUI.InfinityCountBox.Size = UDim2.new(0.15, 0, 0, 16)
    GUI.InfinityCountBox.Position = UDim2.new(0.18, 0, 0, 19)
    GUI.InfinityCountBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    GUI.InfinityCountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.InfinityCountBox.Font = Enum.Font.GothamMedium
    GUI.InfinityCountBox.TextSize = 9
    GUI.InfinityCountBox.Text = "15"
    GUI.InfinityCountBox.ClearTextOnFocus = false
    GUI.InfinityCountBox.Parent = ControlGrid

    local CBoxCorner = Instance.new("UICorner")
    CBoxCorner.CornerRadius = UDim.new(0, 2)
    CBoxCorner.Parent = GUI.InfinityCountBox

    local StartLbl = Instance.new("TextLabel")
    StartLbl.Size = UDim2.new(0.12, 0, 0, 14)
    StartLbl.Position = UDim2.new(0.38, 0, 0, 20)
    StartLbl.BackgroundTransparency = 1
    StartLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    StartLbl.Font = Enum.Font.GothamMedium
    StartLbl.TextSize = 9
    StartLbl.Text = "Mul:"
    StartLbl.TextXAlignment = Enum.TextXAlignment.Right
    StartLbl.Parent = ControlGrid

    GUI.InfinityStartBox = Instance.new("TextBox")
    GUI.InfinityStartBox.Size = UDim2.new(0.2, 0, 0, 16)
    GUI.InfinityStartBox.Position = UDim2.new(0.5, 0, 0, 19)
    GUI.InfinityStartBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    GUI.InfinityStartBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.InfinityStartBox.Font = Enum.Font.GothamMedium
    GUI.InfinityStartBox.TextSize = 9
    GUI.InfinityStartBox.Text = "10"
    GUI.InfinityStartBox.ClearTextOnFocus = false
    GUI.InfinityStartBox.Parent = ControlGrid

    local SBoxCorner = Instance.new("UICorner")
    SBoxCorner.CornerRadius = UDim.new(0, 2)
    SBoxCorner.Parent = GUI.InfinityStartBox

    -- Row 3: Step & Limit
    local StepLbl = Instance.new("TextLabel")
    StepLbl.Size = UDim2.new(0.15, 0, 0, 14)
    StepLbl.Position = UDim2.new(0.02, 0, 0, 38)
    StepLbl.BackgroundTransparency = 1
    StepLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    StepLbl.Font = Enum.Font.GothamMedium
    StepLbl.TextSize = 9
    StepLbl.Text = "Step:"
    StepLbl.TextXAlignment = Enum.TextXAlignment.Right
    StepLbl.Parent = ControlGrid

    GUI.InfinityStepButton = Instance.new("TextButton")
    GUI.InfinityStepButton.Size = UDim2.new(0.15, 0, 0, 16)
    GUI.InfinityStepButton.Position = UDim2.new(0.18, 0, 0, 37)
    GUI.InfinityStepButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    GUI.InfinityStepButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.InfinityStepButton.Font = Enum.Font.GothamMedium
    GUI.InfinityStepButton.TextSize = 9
    GUI.InfinityStepButton.Text = "3"
    GUI.InfinityStepButton.BorderSizePixel = 0
    GUI.InfinityStepButton.Parent = ControlGrid

    local StepBtnCorner = Instance.new("UICorner")
    StepBtnCorner.CornerRadius = UDim.new(0, 2)
    StepBtnCorner.Parent = GUI.InfinityStepButton

    local LimitLbl = Instance.new("TextLabel")
    LimitLbl.Size = UDim2.new(0.25, 0, 0, 14)
    LimitLbl.Position = UDim2.new(0.38, 0, 0, 38)
    LimitLbl.BackgroundTransparency = 1
    LimitLbl.TextColor3 = Color3.fromRGB(255, 200, 0)
    LimitLbl.Font = Enum.Font.GothamBold
    LimitLbl.TextSize = 9
    LimitLbl.Text = "MAX 300!"
    LimitLbl.TextXAlignment = Enum.TextXAlignment.Left
    LimitLbl.Parent = ControlGrid

    -- Row 4: Info
    local InfoLbl = Instance.new("TextLabel")
    InfoLbl.Size = UDim2.new(0.9, 0, 0, 12)
    InfoLbl.Position = UDim2.new(0.05, 0, 0, 56)
    InfoLbl.BackgroundTransparency = 1
    InfoLbl.TextColor3 = Color3.fromRGB(120, 120, 140)
    InfoLbl.Font = Enum.Font.GothamMedium
    InfoLbl.TextSize = 7
    InfoLbl.Text = "OFF = loop terus | max 300 auto-cancel"
    InfoLbl.TextXAlignment = Enum.TextXAlignment.Center
    InfoLbl.Parent = ControlGrid

    -- Step Dropdown
    local stepOptions = {"OFF", 1, 2, 3, 6, 9, 12, 15}
    local stepButtons = {}
    local currentStep = "3"
    local dropdownOpen = false

    GUI.InfinityStepButton.MouseButton1Click:Connect(function()
        dropdownOpen = not dropdownOpen
        if GUI.InfinityDropdown then
            GUI.InfinityDropdown.Visible = dropdownOpen
        end
        if dropdownOpen then
            local stepPos = GUI.InfinityStepButton.AbsolutePosition
            local stepSize = GUI.InfinityStepButton.AbsoluteSize
            if GUI.InfinityDropdown then
                GUI.InfinityDropdown.Position = UDim2.new(0, stepPos.X, 0, stepPos.Y + stepSize.Y)
                GUI.InfinityDropdown.Size = UDim2.new(0, 50, 0, 120)
            end
        end
    end)

    GUI.InfinityDropdown = Instance.new("Frame")
    GUI.InfinityDropdown.Size = UDim2.new(0, 50, 0, 120)
    GUI.InfinityDropdown.Position = UDim2.new(0, 0, 0, 0)
    GUI.InfinityDropdown.BackgroundTransparency = 1
    GUI.InfinityDropdown.Visible = false
    GUI.InfinityDropdown.ZIndex = 9999
    GUI.InfinityDropdown.Parent = ScreenGui

    local DropList = Instance.new("Frame")
    DropList.Size = UDim2.new(1, 0, 1, 0)
    DropList.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    DropList.BackgroundTransparency = 0.1
    DropList.BorderSizePixel = 1
    DropList.BorderColor3 = Color3.fromRGB(80, 80, 90)
    DropList.ZIndex = 9999
    DropList.ClipsDescendants = true
    DropList.Parent = GUI.InfinityDropdown

    local DropCorner = Instance.new("UICorner")
    DropCorner.CornerRadius = UDim.new(0, 3)
    DropCorner.Parent = DropList

    for i, step in ipairs(stepOptions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 15)
        btn.Position = UDim2.new(0, 0, 0, (i-1) * 15)
        btn.Text = tostring(step)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 9
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.ZIndex = 10000
        btn.Parent = DropList

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 2)
        btnCorner.Parent = btn

        stepButtons[step] = btn

        btn.MouseButton1Down:Connect(function()
            currentStep = step
            GUI.InfinityStepButton.Text = tostring(step)
            if step == "OFF" then
                GUI.InfinityStepButton.Text = "OFF"
            end

            for s, b in pairs(stepButtons) do
                b.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                b.BackgroundTransparency = 0.3
            end
            btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
            btn.BackgroundTransparency = 0.3

            dropdownOpen = false
            if GUI.InfinityDropdown then
                GUI.InfinityDropdown.Visible = false
            end
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

    for s, btn in pairs(stepButtons) do
        if s == currentStep then
            btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
            btn.BackgroundTransparency = 0.3
        end
    end

    -- Tutup dropdown
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not dropdownOpen then return end
            task.wait(0.05)
            local mousePos = UserInputService:GetMouseLocation()
            local dropPos = DropList.AbsolutePosition
            local dropSize = DropList.AbsoluteSize
            
            local inDropdown = (mousePos.X >= dropPos.X and mousePos.X <= dropPos.X + dropSize.X and
                               mousePos.Y >= dropPos.Y and mousePos.Y <= dropPos.Y + dropSize.Y)
            
            local stepPos = GUI.InfinityStepButton.AbsolutePosition
            local stepSize = GUI.InfinityStepButton.AbsoluteSize
            local inStep = (mousePos.X >= stepPos.X and mousePos.X <= stepPos.X + stepSize.X and
                           mousePos.Y >= stepPos.Y and mousePos.Y <= stepPos.Y + stepSize.Y)
            
            if not inDropdown and not inStep then
                dropdownOpen = false
                if GUI.InfinityDropdown then
                    GUI.InfinityDropdown.Visible = false
                end
            end
        end
    end)

    -- Result Scrolling Frame
    GUI.InfinityScrollFrame = Instance.new("ScrollingFrame")
    GUI.InfinityScrollFrame.Size = UDim2.new(1, -10, 0, 65)
    GUI.InfinityScrollFrame.Position = UDim2.new(0, 5, 0, 112)
    GUI.InfinityScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    GUI.InfinityScrollFrame.BackgroundTransparency = 0.3
    GUI.InfinityScrollFrame.BorderSizePixel = 0
    GUI.InfinityScrollFrame.Parent = GUI.CoinContent

    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 3)
    ScrollCorner.Parent = GUI.InfinityScrollFrame

    GUI.InfinityResultList = Instance.new("Frame")
    GUI.InfinityResultList.Size = UDim2.new(1, 0, 0, 0)
    GUI.InfinityResultList.BackgroundTransparency = 1
    GUI.InfinityResultList.Parent = GUI.InfinityScrollFrame
    GUI.InfinityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

    -- Progress Bar
    local ProgressFrame = Instance.new("Frame")
    ProgressFrame.Size = UDim2.new(1, -10, 0, 10)
    ProgressFrame.Position = UDim2.new(0, 5, 0, 180)
    ProgressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    ProgressFrame.BackgroundTransparency = 0.3
    ProgressFrame.BorderSizePixel = 0
    ProgressFrame.Parent = GUI.CoinContent

    local ProgCorner = Instance.new("UICorner")
    ProgCorner.CornerRadius = UDim.new(0, 2)
    ProgCorner.Parent = ProgressFrame

    GUI.InfinityProgressBar = Instance.new("Frame")
    GUI.InfinityProgressBar.Size = UDim2.new(0, 0, 1, 0)
    GUI.InfinityProgressBar.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    GUI.InfinityProgressBar.BackgroundTransparency = 0.5
    GUI.InfinityProgressBar.BorderSizePixel = 0
    GUI.InfinityProgressBar.Parent = ProgressFrame

    local ProgCorner2 = Instance.new("UICorner")
    ProgCorner2.CornerRadius = UDim.new(0, 2)
    ProgCorner2.Parent = GUI.InfinityProgressBar

    GUI.InfinityProgressText = Instance.new("TextLabel")
    GUI.InfinityProgressText.Size = UDim2.new(1, 0, 1, 0)
    GUI.InfinityProgressText.BackgroundTransparency = 1
    GUI.InfinityProgressText.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.InfinityProgressText.Font = Enum.Font.GothamBold
    GUI.InfinityProgressText.TextSize = 8
    GUI.InfinityProgressText.Text = "0%"
    GUI.InfinityProgressText.Parent = ProgressFrame

    -- Buttons Row
    local ButtonRow = Instance.new("Frame")
    ButtonRow.Size = UDim2.new(1, -10, 0, 20)
    ButtonRow.Position = UDim2.new(0, 5, 0, 194)
    ButtonRow.BackgroundTransparency = 1
    ButtonRow.Parent = GUI.CoinContent

    GUI.InfinityStartButton = Instance.new("TextButton")
    GUI.InfinityStartButton.Size = UDim2.new(0.32, -2, 1, 0)
    GUI.InfinityStartButton.Position = UDim2.new(0, 0, 0, 0)
    GUI.InfinityStartButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
    GUI.InfinityStartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.InfinityStartButton.Font = Enum.Font.GothamBold
    GUI.InfinityStartButton.TextSize = 10
    GUI.InfinityStartButton.Text = "▶ START"
    GUI.InfinityStartButton.Parent = ButtonRow

    local StartCorner = Instance.new("UICorner")
    StartCorner.CornerRadius = UDim.new(0, 3)
    StartCorner.Parent = GUI.InfinityStartButton

    GUI.InfinityStopButton = Instance.new("TextButton")
    GUI.InfinityStopButton.Size = UDim2.new(0.32, -2, 1, 0)
    GUI.InfinityStopButton.Position = UDim2.new(0.34, 0, 0, 0)
    GUI.InfinityStopButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    GUI.InfinityStopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    GUI.InfinityStopButton.Font = Enum.Font.GothamBold
    GUI.InfinityStopButton.TextSize = 10
    GUI.InfinityStopButton.Text = "⏹ STOP"
    GUI.InfinityStopButton.Visible = false
    GUI.InfinityStopButton.Parent = ButtonRow

    local StopCorner = Instance.new("UICorner")
    StopCorner.CornerRadius = UDim.new(0, 3)
    StopCorner.Parent = GUI.InfinityStopButton

    local ResetBtn = Instance.new("TextButton")
    ResetBtn.Size = UDim2.new(0.32, -2, 1, 0)
    ResetBtn.Position = UDim2.new(0.68, 0, 0, 0)
    ResetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ResetBtn.Font = Enum.Font.GothamBold
    ResetBtn.TextSize = 10
    ResetBtn.Text = "✕ CLR"
    ResetBtn.Parent = ButtonRow

    local ResetCorner = Instance.new("UICorner")
    ResetCorner.CornerRadius = UDim.new(0, 3)
    ResetCorner.Parent = ResetBtn

    -- Infinity button events
    GUI.InfinityStartButton.MouseButton1Click:Connect(InfinityRunTest)
    GUI.InfinityStopButton.MouseButton1Click:Connect(InfinityStopTest)
    ResetBtn.MouseButton1Click:Connect(InfinityResetResults)

    -- Hover effects
    GUI.InfinityStartButton.MouseEnter:Connect(function()
        if not State.infinityRunning then
            GUI.InfinityStartButton.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        end
    end)
    GUI.InfinityStartButton.MouseLeave:Connect(function()
        if not State.infinityRunning then
            GUI.InfinityStartButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
        end
    end)

    GUI.InfinityStopButton.MouseEnter:Connect(function()
        GUI.InfinityStopButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end)
    GUI.InfinityStopButton.MouseLeave:Connect(function()
        GUI.InfinityStopButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end)

    ResetBtn.MouseEnter:Connect(function()
        ResetBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    end)
    ResetBtn.MouseLeave:Connect(function()
        ResetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    end)

    -- Validasi input infinity
    GUI.InfinityDelayBox.FocusLost:Connect(function()
        local val = tonumber(GUI.InfinityDelayBox.Text)
        if not val or val < 0.1 then GUI.InfinityDelayBox.Text = "5" end
    end)

    GUI.InfinityStartBox.FocusLost:Connect(function()
        local val = tonumber(GUI.InfinityStartBox.Text)
        if not val or val < 1 then GUI.InfinityStartBox.Text = "10" end
        if val > MAX_EXPONENT then
            GUI.InfinityStartBox.Text = tostring(MAX_EXPONENT - 10)
        end
    end)

    GUI.InfinityCountBox.FocusLost:Connect(function()
        local val = tonumber(GUI.InfinityCountBox.Text)
        if not val or val < 1 then GUI.InfinityCountBox.Text = "15" end
        if val > 30 then GUI.InfinityCountBox.Text = "30" end
    end)

    -- ===== GOTO TAB CONTENT =====
    GUI.GoToContent = Instance.new("Frame")
    GUI.GoToContent.Size = UDim2.new(1, 0, 1, 0)
    GUI.GoToContent.Position = UDim2.new(0, 0, 0, 0)
    GUI.GoToContent.BackgroundTransparency = 1
    GUI.GoToContent.Visible = false
    GUI.GoToContent.Parent = ContentFrame

    local GoToScroll = Instance.new("ScrollingFrame")
    GoToScroll.Size = UDim2.new(1, 0, 1, 0)
    GoToScroll.Position = UDim2.new(0, 0, 0, 0)
    GoToScroll.BackgroundTransparency = 1
    GoToScroll.BorderSizePixel = 0
    GoToScroll.ScrollBarThickness = 4
    GoToScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
    GoToScroll.Parent = GUI.GoToContent

    local Canvas = Instance.new("Frame")
    Canvas.Size = UDim2.new(1, 0, 0, 0)
    Canvas.BackgroundTransparency = 1
    Canvas.Parent = GoToScroll

    local goToButtons = {
        {name = "FusePet", icon = "🔮", url = "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/GUi/FusePet.lua"},
        {name = "EnchantPet", icon = "✨", url = "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/GUi/EnchantPet.lua"},
        {name = "Titan", icon = "🗿", url = "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/GUi/Titan.lua"},
        {name = "WingShop", icon = "🪶", url = "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/GUi/WingShop.lua"},
        {name = "UnlockWorld", icon = "🌍", url = "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/GUi/UnlockWorldGUi.lua"},
        {name = "GOATEvent", icon = "🐐", url = "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/GUi/GOATEvent.lua"},
        {name = "StPatrick", icon = "🍀", url = "https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/GUi/GuiStPatrickSeason.lua"},
    }

    local gBtnHeight = 22
    local gSpacing = 24
    local gStartY = 3
    local totalHeight = gStartY + (#goToButtons * gSpacing) + 3

    Canvas.Size = UDim2.new(1, 0, 0, totalHeight)
    GoToScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

    for i, data in ipairs(goToButtons) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.95, 0, 0, gBtnHeight)
        btn.Position = UDim2.new(0.025, 0, 0, gStartY + (i-1) * gSpacing)
        local originalText = data.icon .. " " .. data.name
        btn.Text = originalText
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 10
        btn.Parent = Canvas
        btn.AutoButtonColor = false

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn

        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        end)
        btn.MouseLeave:Connect(function()
            if btn.Text ~= "⏳ Loading..." and not string.find(btn.Text, "✅") and not string.find(btn.Text, "❌") then
                btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            end
        end)

        btn.MouseButton1Click:Connect(function()
            LoadGUI(data.url, btn, originalText)
        end)
    end

    -- ===== CREDITS TAB CONTENT =====
    GUI.CreditsContent = Instance.new("Frame")
    GUI.CreditsContent.Size = UDim2.new(1, 0, 1, 0)
    GUI.CreditsContent.Position = UDim2.new(0, 0, 0, 0)
    GUI.CreditsContent.BackgroundTransparency = 1
    GUI.CreditsContent.Visible = false
    GUI.CreditsContent.Parent = ContentFrame

    local CreditsTitle = Instance.new("TextLabel")
    CreditsTitle.Size = UDim2.new(1, 0, 0, 22)
    CreditsTitle.Position = UDim2.new(0, 0, 0, 3)
    CreditsTitle.Text = "ℹ️ Credits"
    CreditsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    CreditsTitle.BackgroundTransparency = 1
    CreditsTitle.Font = Enum.Font.GothamBold
    CreditsTitle.TextSize = 13
    CreditsTitle.Parent = GUI.CreditsContent

    local CreditsList = {
        "CAJT Auto Gacor",
        "Full Auto: 14400/(spd*1.5)",
        "Anti-AFK + Hidden Place",
        "Auto Collect Integrated",
        "Auto Hatch - Draw Hero",
        "Coin+ - Infinity Test",
        "GoTo GUI - Loadstring",
        "Version 4.0 Compact",
        "✨ Enjoy!"
    }

    for i, text in ipairs(CreditsList) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 18)
        label.Position = UDim2.new(0, 0, 0, 28 + (i-1) * 20)
        label.Text = text
        label.TextColor3 = (i == #CreditsList) and Color3.fromRGB(255, 204, 0) or Color3.fromRGB(200, 200, 200)
        label.BackgroundTransparency = 1
        label.Font = (i == #CreditsList) and Enum.Font.GothamBold or Enum.Font.GothamMedium
        label.TextSize = (i == #CreditsList) and 12 or 10
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

    -- Shortcut Key untuk Auto Collect (A)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.A then
            if autoCollectSwitch then
                autoCollectSwitch:toggle()
            end
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        State.hookEnabled = false
        State.hatchRunning = false
        State.hatchHookEnabled = false
        State.infinityRunning = false
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
            MainFrame.Size = UDim2.new(0, 250, 0, 285)
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
print("=== AUTO COIN V4 COMPACT UI (285px) STARTING ===")

CreateGUI()
InitializeRemoteHook()
InitAntiAFK()
InitHatchHook()

local LocalPlayer = Players.LocalPlayer
if LocalPlayer.Character then
    SetupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(SetupCharacter)

UpdateDelays()
UpdateStatus()

print("=== AUTO COIN V4 COMPACT UI (285px) LOADED ===")
print("📌 Tekan 'A' untuk toggle Auto Collect")
print("📌 Buka tab Coin+ untuk Infinity Test")
