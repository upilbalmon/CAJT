--[[
    AUTO COIN V4 - Compact Version with Real-time Cooldown Status
    Fitur: Height (auto), Delay (manual), Speed | Lock Speed | Sync Delay | Mode Farming
    Sync Delay: Menyamakan delay dan membuat loop berjalan bareng
    MODIFIKASI: Progress bar dihapus total, Tab Stat & Log dikosongkan
]]

local Infinity = loadstring(game:HttpGet("https://raw.githubusercontent.com/upilbalmon/CAJT/refs/heads/main/compactlibraryui.lua"))()

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- CONSTANTS
local PAUSE_INTERVAL, PAUSE_DURATION, WIN_DELAY_BASE = 3600, 30, 10000
local DEFAULT_HEIGHT, DEFAULT_DELAY, HEIGHT_MULTIPLIER, MAX_HEIGHT = 5000, 5, 2.8, 14400

-- STATE
local S = {
    jumpID = nil, landingID = nil, winID = nil, magicTokenID = nil,
    isReady = false, running = false, hookEnabled = true,
    runTime = 0, lastLoopTime = 0, nextLoopTime = 0, lastWinTime = 0,
    climbSpeed = 0, climbing = false, climbStartY = 0, climbStartTime = 0, maxY = 0,
    lockSpeed = false, lockedSpeed = 0, syncEnabled = false,
    modeCoin = true, modeWin = true, modeToken = true,
    manualDelay = DEFAULT_DELAY,
    syncedDelay = DEFAULT_DELAY,
    syncStartTime = 0, syncLoopCount = 0,
    -- GUI refs
    app = nil, gui = nil, heightBox = nil, delayBox = nil, speedBox = nil,
    coinLight = nil, winLight = nil, tokenLight = nil,
    coinCheck = nil, winCheck = nil, tokenCheck = nil,
    coinCooldown = nil, winCooldown = nil, tokenCooldown = nil,
    statusLabel = nil, lockSpeedCheckbox = nil, syncToggle = nil,
    startStopButton = nil, clearLogButton = nil,
    resultList = nil, scrollFrame = nil,
    -- PROGRESS BAR DIHAPUS
    resultCount = 0
}

-- GET CURRENT SPEED
local function GetCurrentSpeed()
    if S.lockSpeed and S.lockedSpeed > 0 then return S.lockedSpeed end
    return S.climbSpeed
end

-- GET DELAY
local function GetDelay()
    if S.syncEnabled then return S.syncedDelay end
    local delay = tonumber(S.delayBox and S.delayBox.Text)
    if delay and delay > 0 then
        S.manualDelay = delay
        return delay
    end
    return S.manualDelay or DEFAULT_DELAY
end

local function GetCoinDelay() return GetDelay() end

local function GetWinDelay()
    if S.syncEnabled then return GetDelay() end
    local speed = GetCurrentSpeed()
    return speed > 0 and (WIN_DELAY_BASE / speed) or 20
end

local function GetTokenDelay()
    if S.syncEnabled then return GetDelay() end
    local speed = GetCurrentSpeed()
    if speed > 0 then return math.floor((10000/speed)*10)/10 end
    return GetDelay()
end

local function CalculateHeight()
    local delay = GetDelay()
    local speed = GetCurrentSpeed()
    return math.min(math.floor((speed * HEIGHT_MULTIPLIER) * delay), MAX_HEIGHT)
end

local function UpdateHeight()
    local speed = GetCurrentSpeed()
    if speed > 0 and S.heightBox then
        S.heightBox.Text = tostring(CalculateHeight())
    end
end

local function UpdateSpeedBox()
    if not S.speedBox then return end
    local speed = GetCurrentSpeed()
    if S.lockSpeed and S.lockedSpeed > 0 then
        S.speedBox.Text = string.format("%.2f [LOCKED]", S.lockedSpeed)
        S.speedBox.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        S.speedBox.Text = string.format("%.2f", S.climbSpeed)
        S.speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

local function UpdateDelayBox()
    if not S.delayBox then return end
    local delay = GetDelay()
    S.delayBox.Text = string.format("%.1f", delay)
    S.delayBox.TextColor3 = S.syncEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,255,255)
end

local function GetModeDesc()
    local parts = {}
    if S.modeCoin then table.insert(parts, "🪙") end
    if S.modeWin then table.insert(parts, "🏆") end
    if S.modeToken then table.insert(parts, "✨") end
    local modeStr = #parts > 0 and table.concat(parts, " ") or "❌ None"
    return S.syncEnabled and modeStr .. " [SYNC]" or modeStr
end

-- SYNC DELAY
local function SyncDelay()
    local speed = GetCurrentSpeed()
    if speed > 0 then
        local newDelay = math.floor((WIN_DELAY_BASE / speed) * 10) / 10
        if newDelay < 0.5 then newDelay = 0.5 end
        S.syncedDelay = newDelay
        S.manualDelay = newDelay
        S.lastLoopTime = os.time()
        S.lastWinTime = os.time()
        S.syncStartTime = os.time()
        S.syncLoopCount = 0
        UpdateDelayBox()
        UpdateHeight()
        return true
    end
    return false
end

-- REMOTE
local function SendRemote(event, ...)
    local ev = RS:FindFirstChild("ProMgs") and RS.ProMgs:FindFirstChild("RemoteEvent")
    if ev then ev:FireServer(event, ...) end
end

local function SendJump()
    if S.jumpID then 
        local height = tonumber(S.heightBox and S.heightBox.Text) or CalculateHeight()
        SendRemote("JumpResults", S.jumpID, height)
    end
end

local function SendLanding()
    if S.landingID then SendRemote("LandingResults", S.landingID) end
end

local function SendWin()
    if S.winID then SendRemote("ClaimRooftopWinsReward", S.winID); S.lastWinTime = os.time() end
end

local function SendToken()
    if S.magicTokenID then SendRemote("ClaimRooftopMagicToken", S.magicTokenID) end
end

-- ADD RESULT
local function AddResult(text, color)
    if not S.resultList then return end
    S.resultCount = S.resultCount + 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-4,0,16)
    lbl.Position = UDim2.new(0,2,0,(S.resultCount-1)*17)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = color or Color3.fromRGB(200,200,200)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 11
    lbl.Text = text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = S.resultList
    if S.scrollFrame then
        S.scrollFrame.CanvasSize = UDim2.new(0,0,0,S.resultCount*17+6)
        S.scrollFrame.CanvasPosition = Vector2.new(0,S.scrollFrame.CanvasSize.Y.Offset)
    end
end

-- CLEAR LOG
local function ClearLog()
    if S.running then return end
    for _, child in pairs(S.resultList:GetChildren()) do
        child:Destroy()
    end
    S.resultCount = 0
    if S.scrollFrame then
        S.scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
    end
    AddResult("🗑️ Log cleared", Color3.fromRGB(255,200,0))
end

-- UPDATE COOLDOWN
local function UpdateCooldowns()
    if not S.coinCooldown then return end
    local now = os.time()
    local delay = GetDelay()
    
    if S.syncEnabled then
        local elapsed = now - S.lastLoopTime
        local remaining = math.max(0, delay - elapsed)
        local color = remaining > 2 and Color3.fromRGB(255,200,100) or Color3.fromRGB(100,255,100)
        
        S.coinCooldown.Text = S.running and S.modeCoin and string.format("%.1fs", remaining) or "⏸️"
        S.coinCooldown.TextColor3 = S.running and S.modeCoin and color or Color3.fromRGB(150,150,150)
        
        S.winCooldown.Text = (S.running and S.modeWin and S.winID) and string.format("%.1fs", remaining) or (not S.winID and "❌" or "⏸️")
        S.winCooldown.TextColor3 = (S.running and S.modeWin and S.winID) and color or (not S.winID and Color3.fromRGB(255,50,50) or Color3.fromRGB(150,150,150))
        
        S.tokenCooldown.Text = (S.running and S.modeToken and S.magicTokenID) and string.format("%.1fs", remaining) or (not S.magicTokenID and "❌" or "⏸️")
        S.tokenCooldown.TextColor3 = (S.running and S.modeToken and S.magicTokenID) and color or (not S.magicTokenID and Color3.fromRGB(255,50,50) or Color3.fromRGB(150,150,150))
    else
        -- Coin
        if S.running and S.modeCoin then
            local remaining = math.max(0, delay - (now - S.lastLoopTime))
            S.coinCooldown.Text = string.format("%.1fs", remaining)
            S.coinCooldown.TextColor3 = remaining > 2 and Color3.fromRGB(255,200,100) or Color3.fromRGB(100,255,100)
        else
            S.coinCooldown.Text = "⏸️"
            S.coinCooldown.TextColor3 = Color3.fromRGB(150,150,150)
        end
        
        -- Win
        if S.running and S.modeWin and S.winID then
            local remaining = math.max(0, GetWinDelay() - (now - S.lastWinTime))
            S.winCooldown.Text = string.format("%.1fs", remaining)
            S.winCooldown.TextColor3 = remaining > 2 and Color3.fromRGB(255,200,100) or Color3.fromRGB(100,255,100)
        else
            S.winCooldown.Text = not S.winID and "❌" or "⏸️"
            S.winCooldown.TextColor3 = not S.winID and Color3.fromRGB(255,50,50) or Color3.fromRGB(150,150,150)
        end
        
        -- Token
        if S.running and S.modeToken and S.magicTokenID then
            local tokenDelay = GetTokenDelay()
            local remaining = math.max(0, (tokenDelay/2) - (now - S.lastLoopTime))
            S.tokenCooldown.Text = string.format("%.1fs", remaining)
            S.tokenCooldown.TextColor3 = remaining > 2 and Color3.fromRGB(255,200,100) or Color3.fromRGB(100,255,100)
        else
            S.tokenCooldown.Text = not S.magicTokenID and "❌" or "⏸️"
            S.tokenCooldown.TextColor3 = not S.magicTokenID and Color3.fromRGB(255,50,50) or Color3.fromRGB(150,150,150)
        end
    end
end

-- UPDATE STATUS (PROGRESS BAR DIHAPUS)
local function UpdateStatus()
    if S.coinLight then
        S.coinLight.BackgroundColor3 = (S.jumpID and S.landingID) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
        S.winLight.BackgroundColor3 = S.winID and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
        S.tokenLight.BackgroundColor3 = S.magicTokenID and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
    end
    
    local ready = S.jumpID and S.landingID
    S.isReady = ready
    if S.startStopButton then
        S.startStopButton.Text = S.running and "⏹ STOP" or "▶ START"
        S.startStopButton.BackgroundColor3 = S.running and Color3.fromRGB(200,50,50) or Color3.fromRGB(40,160,40)
    end
    if S.statusLabel then
        S.statusLabel.Text = ready and (S.running and "RUNNING" or "READY! Mode: "..GetModeDesc()) or "JUMP FROM TOWER FIRST"
        S.statusLabel.TextColor3 = ready and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    end
    UpdateSpeedBox()
    UpdateDelayBox()
    if not S.running then UpdateHeight() end
    UpdateCooldowns()
end

local function UpdateStatusMsg(c, w, t)
    if not S.statusLabel then return end
    local txt = ""
    txt = txt .. (c == "claimed" and "C:✓ " or c == "waiting" and "C:⏳ " or c == "ready" and "C:▶ " or "C:○ ")
    txt = txt .. (w == "claimed" and "W:✓ " or w == "waiting" and "W:⏳ " or w == "ready" and "W:▶ " or "W:○ ")
    txt = txt .. (t == "claimed" and "T:✓" or t == "waiting" and "T:⏳" or t == "ready" and "T:▶" or "T:○")
    S.statusLabel.Text = txt .. " | " .. GetModeDesc()
    S.statusLabel.TextColor3 = Color3.fromRGB(100,255,100)
    UpdateSpeedBox()
    UpdateDelayBox()
    UpdateCooldowns()
end

-- MAIN LOOP
local function RunLoop()
    AddResult("===== MULAI LOOP =====", Color3.fromRGB(100,200,255))
    AddResult("Mode: "..GetModeDesc(), Color3.fromRGB(255,200,0))
    
    while S.running and S.hookEnabled do
        local delay = GetDelay()
        S.lastLoopTime = os.time()
        S.nextLoopTime = S.lastLoopTime + delay
        UpdateStatusMsg("ready","ready","ready")
        
        if S.syncEnabled then
            while os.time() < S.nextLoopTime and S.running and S.hookEnabled do
                task.wait(0.1)
            end
            if not S.running or not S.hookEnabled then break end
            
            local claims = {}
            if S.modeCoin then SendJump(); SendLanding(); table.insert(claims, "🪙") end
            if S.modeWin and S.winID then SendWin(); table.insert(claims, "🏆") end
            if S.modeToken and S.magicTokenID then SendToken(); table.insert(claims, "✨") end
            if #claims > 0 then
                AddResult("✅ "..table.concat(claims, " + "), Color3.fromRGB(0,255,0))
                S.syncLoopCount = S.syncLoopCount + 1
            end
            UpdateStatusMsg("claimed","claimed","claimed")
            task.wait(0.3)
        else
            -- Token midpoint
            if S.modeToken and S.magicTokenID then
                local tokenTime = S.lastLoopTime + (GetTokenDelay() / 2)
                while os.time() < tokenTime and S.running and S.hookEnabled do
                    task.wait(0.1)
                end
                if S.running and S.hookEnabled then
                    SendToken(); AddResult("✅ ✨ Token", Color3.fromRGB(0,255,0)); UpdateStatusMsg("claimed","ready","claimed"); task.wait(0.3)
                end
            end
            
            -- Win
            local winDelay = GetWinDelay()
            if S.modeWin and os.time() - S.lastWinTime >= winDelay then
                SendWin(); AddResult("✅ 🏆 Win ("..string.format("%.1fs",winDelay)..")", Color3.fromRGB(0,255,0)); UpdateStatusMsg("ready","claimed","ready"); task.wait(0.3)
            end
            
            while os.time() < S.nextLoopTime and S.running and S.hookEnabled do
                task.wait(0.1)
            end
            if not S.running or not S.hookEnabled then break end
            
            SendJump(); SendLanding(); AddResult("✅ 🪙 Coin", Color3.fromRGB(0,255,0)); UpdateStatusMsg("claimed","ready","ready"); task.wait(0.3)
        end
        
        -- Pause
        S.runTime = S.runTime + (os.time() - S.lastLoopTime)
        if S.runTime >= PAUSE_INTERVAL then
            AddResult("⏸️ PAUSED 30s", Color3.fromRGB(255,200,0))
            S.running = false
            if S.statusLabel then S.statusLabel.Text = "PAUSED 30s"; S.statusLabel.TextColor3 = Color3.fromRGB(255,100,100) end
            if S.startStopButton then S.startStopButton.Text = "▶ START"; S.startStopButton.BackgroundColor3 = Color3.fromRGB(40,160,40) end
            task.wait(PAUSE_DURATION)
            S.runTime = 0; S.running = true
            if S.startStopButton then S.startStopButton.Text = "⏹ STOP"; S.startStopButton.BackgroundColor3 = Color3.fromRGB(200,50,50) end
            if S.syncEnabled then S.lastLoopTime = os.time(); S.lastWinTime = os.time() end
            AddResult("▶️ Resume", Color3.fromRGB(0,255,0))
        end
    end
    if S.hookEnabled then
        AddResult("⏹️ LOOP BERHENTI", Color3.fromRGB(255,200,0))
        UpdateStatus()
    end
end

-- CLIMB DETECTION
local function SetupCharacter(char)
    local hum = char:WaitForChild("Humanoid")
    hum.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Climbing then
            S.climbStartY = char:WaitForChild("HumanoidRootPart").Position.Y
            S.climbStartTime = tick(); S.maxY = S.climbStartY; S.climbing = true
            if S.statusLabel then S.statusLabel.Text = "CLIMBING..."; S.statusLabel.TextColor3 = Color3.fromRGB(255,200,100) end
            AddResult("🧗 Climbing...", Color3.fromRGB(255,200,100))
        elseif S.climbing then
            local totalY = S.maxY - S.climbStartY
            local totalT = tick() - S.climbStartTime
            if totalY > 0 and totalT > 0 then
                S.climbSpeed = totalY / totalT
                UpdateSpeedBox()
                AddResult(string.format("📊 Speed: %.2f | H: %d", S.climbSpeed, totalY), Color3.fromRGB(100,200,255))
                
                if S.lockSpeed and S.lockedSpeed == 0 then
                    S.lockedSpeed = S.climbSpeed
                    if S.statusLabel then S.statusLabel.Text = "SPEED LOCKED: "..string.format("%.2f",S.lockedSpeed); S.statusLabel.TextColor3 = Color3.fromRGB(100,255,100) end
                    AddResult("🔒 Speed Locked: "..string.format("%.2f",S.lockedSpeed), Color3.fromRGB(100,255,100))
                    UpdateSpeedBox(); task.wait(1.5)
                    if S.running then UpdateStatusMsg("ready","ready","ready") else UpdateStatus() end
                end
                
                if S.syncEnabled then SyncDelay() end
                UpdateHeight()
                AddResult(string.format("📏 Height: %d (Delay: %.1fs)", CalculateHeight(), GetDelay()), Color3.fromRGB(100,200,255))
                
                if S.modeWin then
                    if S.statusLabel then S.statusLabel.Text = "WIN DELAY: "..string.format("%.1fs", GetWinDelay()); S.statusLabel.TextColor3 = Color3.fromRGB(100,255,100) end
                    task.wait(2)
                    if S.running then UpdateStatusMsg("ready","ready","ready") else UpdateStatus() end
                else
                    if S.running then UpdateStatusMsg("ready","ready","ready") else UpdateStatus() end
                end
            end
            S.climbing = false
        end
    end)
    RunService.Heartbeat:Connect(function()
        if S.climbing and char:FindFirstChild("HumanoidRootPart") then
            local y = char.HumanoidRootPart.Position.Y
            if y > S.maxY then S.maxY = y end
        end
        UpdateCooldowns()
    end)
end

-- BUILD GUI (PROGRESS BAR DIHAPUS TOTAL)
local function BuildGUI()
    local app = Infinity.new({
        title = "AUTO COIN V4",
        delay = 5, heroId = 7000001, mode = "farming", compact = true,
        tabs = {{name="MAIN",active=true},{name="STATS",active=false},{name="LOGS",active=false}}
    })
    
    -- NONAKTIFKAN SEMUA ELEMEN YANG TIDAK DIPAKAI
    -- 1. Nonaktifkan notifikasi
    app.notify = function() end
    
    -- 2. Hapus status label bawaan library & Buat ulang tab MAIN
    app.buildMainTab = function(self, parent, fLabel, fInput, fInfo, fResult, fProgress, fButton)
        -- HAPUS STATUS LABEL BAWAAN LIBRARY
        if self.statusLabel then
            self.statusLabel:Destroy()
            self.statusLabel = nil
        end
        
        -- HAPUS PROGRESS BAR BAWAAN LIBRARY jika ada
        if self.progressBar then
            self.progressBar:Destroy()
            self.progressBar = nil
        end
        if self.progressText then
            self.progressText:Destroy()
            self.progressText = nil
        end
        
        -- BUTTONS
        local btns = Instance.new("Frame")
        btns.Size = UDim2.new(1, 0, 0, 24)
        btns.Position = UDim2.new(0, 0, 1, -24)
        btns.BackgroundTransparency = 1
        btns.Parent = parent
        
        -- START/STOP Button
        self.testButton = Instance.new("TextButton")
        self.testButton.Size = UDim2.new(0.68, -3, 1, 0)
        self.testButton.Position = UDim2.new(0, 0, 0, 0)
        self.testButton.Text = "▶ START"
        self.testButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
        self.testButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        self.testButton.Font = Enum.Font.SourceSansBold
        self.testButton.TextSize = 11
        self.testButton.Parent = btns
        Instance.new("UICorner").CornerRadius = UDim.new(0, 3); Instance.new("UICorner").Parent = self.testButton
        S.startStopButton = self.testButton
        
        -- CLEAR LOG Button
        self.clearButton = Instance.new("TextButton")
        self.clearButton.Size = UDim2.new(0.30, -3, 1, 0)
        self.clearButton.Position = UDim2.new(0.70, 0, 0, 0)
        self.clearButton.Text = "🗑️ CLEAR"
        self.clearButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        self.clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        self.clearButton.Font = Enum.Font.SourceSansBold
        self.clearButton.TextSize = 9
        self.clearButton.Parent = btns
        Instance.new("UICorner").CornerRadius = UDim.new(0, 3); Instance.new("UICorner").Parent = self.clearButton
        S.clearLogButton = self.clearButton
        
        self.clearButton.MouseButton1Click:Connect(ClearLog)
        self.clearButton.MouseEnter:Connect(function()
            self.clearButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        end)
        self.clearButton.MouseLeave:Connect(function()
            self.clearButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        end)
        
        -- CONTENT FRAME
        local cf = Instance.new("Frame")
        cf.Size = UDim2.new(1, 0, 1, -24)
        cf.Position = UDim2.new(0, 0, 0, 0)
        cf.BackgroundColor3 = Color3.fromRGB(30,30,35)
        cf.BackgroundTransparency = 0.3
        cf.BorderSizePixel = 0
        cf.ClipsDescendants = false
        cf.Parent = parent
        Instance.new("UICorner").CornerRadius = UDim.new(0,3); Instance.new("UICorner").Parent = cf
        
        -- STATUS LABEL (kita buat sendiri)
        self.statusLabel = Instance.new("TextLabel")
        self.statusLabel.Size = UDim2.new(1, -8, 0, 16)
        self.statusLabel.Position = UDim2.new(0, 4, 0, 2)
        self.statusLabel.BackgroundTransparency = 1
        self.statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        self.statusLabel.Font = Enum.Font.SourceSans
        self.statusLabel.TextSize = 10
        self.statusLabel.Text = "Status: Siap..."
        self.statusLabel.TextXAlignment = Enum.TextXAlignment.Center
        self.statusLabel.Visible = true
        self.statusLabel.Parent = cf
        S.statusLabel = self.statusLabel
        
        -- Input Row
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,0,0,42)
        row.Position = UDim2.new(0,0,0,20)
        row.BackgroundTransparency = 1
        row.Parent = cf
        
        local function makeInput(col, label, default)
            local c = Instance.new("Frame")
            c.Size = UDim2.new(0.33,-2,1,0)
            c.Position = UDim2.new(col,0,0,0)
            c.BackgroundTransparency = 1
            c.Parent = row
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,0,12)
            lbl.Position = UDim2.new(0,0,0,0)
            lbl.Text = label
            lbl.TextColor3 = Color3.fromRGB(180,180,180)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 8
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.Parent = c
            
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1,0,0,18)
            box.Position = UDim2.new(0,0,0,12)
            box.Text = default
            box.BackgroundColor3 = Color3.fromRGB(45,45,50)
            box.TextColor3 = Color3.new(1,1,1)
            box.Font = Enum.Font.Gotham
            box.TextSize = 10
            box.TextXAlignment = Enum.TextXAlignment.Center
            box.Parent = c
            Instance.new("UICorner").CornerRadius = UDim.new(0,3); Instance.new("UICorner").Parent = box
            return box
        end
        
        S.heightBox = makeInput(0, "Height (Auto)", tostring(DEFAULT_HEIGHT))
        S.delayBox = makeInput(0.34, "Delay", tostring(DEFAULT_DELAY))
        S.speedBox = makeInput(0.67, "Speed", "0")
        
        -- Lock Section
        local lock = Instance.new("Frame")
        lock.Size = UDim2.new(1,0,0,24)
        lock.Position = UDim2.new(0,0,0,64)
        lock.BackgroundTransparency = 1
        lock.Parent = cf
        
        local function makeToggle(x, label)
            local r = Instance.new("Frame")
            r.Size = UDim2.new(0.48,0,0,16)
            r.Position = UDim2.new(x,0,0,0)
            r.BackgroundTransparency = 1
            r.Parent = lock
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0,12,0,12)
            btn.Position = UDim2.new(0,2,0,2)
            btn.Text = ""
            btn.BackgroundColor3 = Color3.fromRGB(60,60,70)
            btn.Parent = r
            Instance.new("UICorner").CornerRadius = UDim.new(0,3); Instance.new("UICorner").Parent = btn
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,-18,1,0)
            lbl.Position = UDim2.new(0,18,0,0)
            lbl.Text = label
            lbl.TextColor3 = Color3.new(1,1,1)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 9
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = r
            return btn
        end
        
        S.lockSpeedCheckbox = makeToggle(0.02, "Lock Speed")
        S.syncToggle = makeToggle(0.52, "Sync Delay")
        
        -- CWT Indicators
        local cwt = Instance.new("Frame")
        cwt.Size = UDim2.new(1,0,0,36)
        cwt.Position = UDim2.new(0,0,0,90)
        cwt.BackgroundTransparency = 1
        cwt.Parent = cf
        
        local function makeIndicator(col, label)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(0.33,-2,1,0)
            f.Position = UDim2.new(col,0,0,0)
            f.BackgroundTransparency = 1
            f.Parent = cwt
            
            local check = Instance.new("TextButton")
            check.Size = UDim2.new(0,10,0,10)
            check.Position = UDim2.new(0,2,0.15,-5)
            check.Text = "✓"
            check.TextColor3 = Color3.fromRGB(0,255,0)
            check.Font = Enum.Font.GothamBold
            check.TextSize = 8
            check.BackgroundColor3 = Color3.fromRGB(40,180,40)
            check.BackgroundTransparency = 0.3
            check.Parent = f
            Instance.new("UICorner").CornerRadius = UDim.new(0,2); Instance.new("UICorner").Parent = check
            
            local light = Instance.new("Frame")
            light.Size = UDim2.new(0,5,0,5)
            light.Position = UDim2.new(0,16,0.15,-2)
            light.BackgroundColor3 = Color3.fromRGB(255,0,0)
            light.Parent = f
            Instance.new("UICorner").CornerRadius = UDim.new(0,3); Instance.new("UICorner").Parent = light
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,-28,0,10)
            lbl.Position = UDim2.new(0,25,0,0)
            lbl.Text = label
            lbl.TextColor3 = Color3.fromRGB(180,180,180)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 8
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = f
            
            local cooldown = Instance.new("TextLabel")
            cooldown.Size = UDim2.new(1,-28,0,13)
            cooldown.Position = UDim2.new(0,25,0,10)
            cooldown.Text = "⏸️"
            cooldown.TextColor3 = Color3.fromRGB(150,150,150)
            cooldown.BackgroundTransparency = 1
            cooldown.Font = Enum.Font.GothamBold
            cooldown.TextSize = 9
            cooldown.TextXAlignment = Enum.TextXAlignment.Left
            cooldown.Parent = f
            
            if label == "Coin" then S.coinCooldown = cooldown
            elseif label == "Win" then S.winCooldown = cooldown
            else S.tokenCooldown = cooldown end
            
            local isActive = (label == "Win" and S.modeWin) or (label == "Token" and S.modeToken) or (label == "Coin" and S.modeCoin)
            if not isActive then check.Text = ""; check.BackgroundColor3 = Color3.fromRGB(60,60,70) end
            
            check.MouseButton1Click:Connect(function()
                if label == "Coin" then
                    S.modeCoin = not S.modeCoin
                    check.Text = S.modeCoin and "✓" or ""; check.BackgroundColor3 = S.modeCoin and Color3.fromRGB(40,180,40) or Color3.fromRGB(60,60,70)
                    AddResult(S.modeCoin and "🪙 Coin: ON" or "🪙 Coin: OFF", S.modeCoin and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,100,100))
                elseif label == "Win" then
                    if not S.winID then AddResult("⚠️ Belum ada Win ID!", Color3.fromRGB(255,100,0)); return end
                    S.modeWin = not S.modeWin
                    check.Text = S.modeWin and "✓" or ""; check.BackgroundColor3 = S.modeWin and Color3.fromRGB(40,180,40) or Color3.fromRGB(60,60,70)
                    if S.modeWin then S.lastWinTime = os.time() end
                    AddResult(S.modeWin and "🏆 Win: ON" or "🏆 Win: OFF", S.modeWin and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,100,100))
                elseif label == "Token" then
                    if not S.magicTokenID then AddResult("⚠️ Belum ada Token ID!", Color3.fromRGB(255,100,0)); return end
                    S.modeToken = not S.modeToken
                    check.Text = S.modeToken and "✓" or ""; check.BackgroundColor3 = S.modeToken and Color3.fromRGB(40,180,40) or Color3.fromRGB(60,60,70)
                    AddResult(S.modeToken and "✨ Token: ON" or "✨ Token: OFF", S.modeToken and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,100,100))
                end
                UpdateStatus()
            end)
            
            if label == "Coin" then S.coinLight = light; S.coinCheck = check
            elseif label == "Win" then S.winLight = light; S.winCheck = check
            else S.tokenLight = light; S.tokenCheck = check end
            
            return light, check, cooldown
        end
        
        makeIndicator(0, "Coin")
        makeIndicator(0.34, "Win")
        makeIndicator(0.67, "Token")
        
        -- Results (ScrollingFrame untuk log)
        self.scrollFrame = Instance.new("ScrollingFrame")
        self.scrollFrame.Size = UDim2.new(1, 0, 1, -148)
        self.scrollFrame.Position = UDim2.new(0, 0, 0, 128)
        self.scrollFrame.BackgroundColor3 = Color3.fromRGB(25,25,30)
        self.scrollFrame.BackgroundTransparency = 0.3
        self.scrollFrame.BorderSizePixel = 0
        self.scrollFrame.Parent = cf
        Instance.new("UICorner").CornerRadius = UDim.new(0,3); Instance.new("UICorner").Parent = self.scrollFrame
        S.scrollFrame = self.scrollFrame
        
        self.resultList = Instance.new("Frame")
        self.resultList.Size = UDim2.new(1,0,0,0)
        self.resultList.BackgroundTransparency = 1
        self.resultList.Parent = self.scrollFrame
        S.resultList = self.resultList
        self.scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
        self.resultCount = 0
        
        -- PROGRESS BAR DIHAPUS TOTAL - Tidak ada kode pembuatan progress bar di sini
        
        return cf
    end
    
    -- KOSONGKAN TAB STATS & LOGS (Nonaktifkan)
    app.buildStatsTab = function(self, parent)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,1,0)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.Text = "Tab Stat dinonaktifkan"
        label.TextColor3 = Color3.fromRGB(100,100,100)
        label.Font = Enum.Font.SourceSans
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.Parent = frame
        return frame
    end
    
    app.buildLogsTab = function(self, parent)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,1,0)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.Text = "Tab Log dinonaktifkan"
        label.TextColor3 = Color3.fromRGB(100,100,100)
        label.Font = Enum.Font.SourceSans
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.Parent = frame
        return frame
    end
    
    app:buildGUI()
    S.app = app; S.gui = app.gui; S.mainFrame = app.mainFrame
    return app
end

-- EVENT HANDLERS
local function SetupEvents()
    if S.startStopButton then
        S.startStopButton.MouseButton1Click:Connect(function()
            if S.isReady then
                S.running = not S.running
                if S.running then
                    S.startStopButton.Text = "⏹ STOP"
                    S.startStopButton.BackgroundColor3 = Color3.fromRGB(200,50,50)
                    S.lastWinTime = os.time(); S.runTime = 0; S.syncLoopCount = 0
                    if S.syncEnabled then S.lastLoopTime = os.time() end
                    AddResult("▶️ STARTED - Mode: "..GetModeDesc(), Color3.fromRGB(0,255,0))
                    coroutine.wrap(RunLoop)()
                else
                    S.startStopButton.Text = "▶ START"
                    S.startStopButton.BackgroundColor3 = Color3.fromRGB(40,160,40)
                    AddResult("⏹️ STOPPED", Color3.fromRGB(255,200,0))
                    UpdateStatus()
                end
            else
                AddResult("⚠️ Lompat dari tower dulu!", Color3.fromRGB(255,100,0))
            end
        end)
    end
    
    if S.lockSpeedCheckbox then
        S.lockSpeedCheckbox.MouseButton1Click:Connect(function()
            S.lockSpeed = not S.lockSpeed
            if S.lockSpeed then
                S.lockSpeedCheckbox.BackgroundColor3 = Color3.fromRGB(100,200,100)
                if S.climbSpeed > 0 then
                    S.lockedSpeed = S.climbSpeed
                    if S.statusLabel then S.statusLabel.Text = "SPEED LOCKED: "..string.format("%.2f",S.lockedSpeed); S.statusLabel.TextColor3 = Color3.fromRGB(100,255,100) end
                    AddResult("🔒 Speed Locked: "..string.format("%.2f",S.lockedSpeed), Color3.fromRGB(100,255,100))
                    UpdateSpeedBox(); UpdateHeight()
                    if S.syncEnabled then SyncDelay() end
                    task.wait(1.5)
                    if S.running then UpdateStatusMsg("ready","ready","ready") else UpdateStatus() end
                else
                    if S.statusLabel then S.statusLabel.Text = "WAITING FOR SPEED..."; S.statusLabel.TextColor3 = Color3.fromRGB(255,200,100) end
                    AddResult("⏳ Menunggu speed...", Color3.fromRGB(255,200,100))
                end
            else
                S.lockSpeedCheckbox.BackgroundColor3 = Color3.fromRGB(60,60,70)
                S.lockedSpeed = 0
                if S.statusLabel then S.statusLabel.Text = "SPEED UNLOCKED"; S.statusLabel.TextColor3 = Color3.fromRGB(100,255,100) end
                AddResult("🔓 Speed Unlocked", Color3.fromRGB(100,255,100))
                UpdateSpeedBox(); UpdateHeight()
                if S.syncEnabled then SyncDelay() end
                task.wait(1.5)
                if S.running then UpdateStatusMsg("ready","ready","ready") else UpdateStatus() end
            end
        end)
    end
    
    if S.syncToggle then
        S.syncToggle.MouseButton1Click:Connect(function()
            S.syncEnabled = not S.syncEnabled
            if S.syncEnabled then
                S.syncToggle.BackgroundColor3 = Color3.fromRGB(100,200,100)
                if S.statusLabel then S.statusLabel.Text = "SYNC ENABLED"; S.statusLabel.TextColor3 = Color3.fromRGB(100,255,100) end
                AddResult("🔄 SYNC ON - Loop bareng", Color3.fromRGB(100,255,100))
                if S.climbSpeed > 0 then SyncDelay() else S.syncedDelay = GetDelay(); S.lastLoopTime = os.time(); S.lastWinTime = os.time(); UpdateDelayBox() end
                task.wait(1.5)
                if S.running then UpdateStatusMsg("ready","ready","ready") else UpdateStatus() end
            else
                S.syncToggle.BackgroundColor3 = Color3.fromRGB(60,60,70)
                if S.statusLabel then S.statusLabel.Text = "SYNC DISABLED"; S.statusLabel.TextColor3 = Color3.fromRGB(255,100,100) end
                AddResult("🔄 SYNC OFF - Terpisah", Color3.fromRGB(255,100,100))
                S.syncedDelay = S.manualDelay; UpdateDelayBox()
                task.wait(1.5)
                if S.running then UpdateStatusMsg("ready","ready","ready") else UpdateStatus() end
            end
        end)
    end
    
    if S.delayBox then
        S.delayBox:GetPropertyChangedSignal("Text"):Connect(function()
            local val = tonumber(S.delayBox.Text)
            if val and val > 0 then S.manualDelay = val; if S.syncEnabled then S.syncedDelay = val end; UpdateHeight() end
        end)
    end
end

-- REMOTE HOOK
local function InitRemoteHook()
    local ev = RS:FindFirstChild("ProMgs") and RS.ProMgs:FindFirstChild("RemoteEvent")
    if not ev then return end
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        if not S.hookEnabled then return old(self, ...) end
        local args = {...}
        local method = getnamecallmethod()
        if self == ev and method == "FireServer" then
            local eType, eID = args[1], args[2]
            if typeof(eID) == "number" then
                if eType == "JumpResults" then S.jumpID = eID
                elseif eType == "LandingResults" then S.landingID = eID
                elseif eType == "ClaimRooftopWinsReward" then S.winID = eID
                elseif eType == "ClaimRooftopMagicToken" then S.magicTokenID = eID end
                UpdateStatus()
            end
        end
        return old(self, ...)
    end)
end

-- COOLDOWN UPDATER
local function StartCooldownUpdater()
    coroutine.wrap(function()
        while S.hookEnabled do
            UpdateCooldowns()
            task.wait(0.1)
        end
    end)()
end

-- INIT
local app = BuildGUI()
SetupEvents()
InitRemoteHook()
StartCooldownUpdater()

local lp = Players.LocalPlayer
if lp.Character then SetupCharacter(lp.Character) end
lp.CharacterAdded:Connect(SetupCharacter)

task.wait(0.5)
UpdateStatus()

AddResult("✅ AUTO COIN V4 - Siap!", Color3.fromRGB(0,255,0))
AddResult("📌 Mode: "..GetModeDesc(), Color3.fromRGB(255,200,0))
AddResult("📌 START/STOP 1 tombol | CLEAR LOG", Color3.fromRGB(100,200,255))
AddResult("📌 Lompat dari tower untuk memulai", Color3.fromRGB(255,200,100))

print("AUTO COIN V4 - Progress bar dihapus total!")
