--[[
    INFINITY LIB - Single File Library
    Versi: 2.0.0
    Fitur: Tab System + Notification
    
    Cara Penggunaan:
    local Infinity = loadstring(game:HttpGet("https://raw.githubusercontent.com/.../InfinityLib.lua"))()
    
    local app = Infinity.new({
        tabs = {
            {name = "MAIN", active = true},
            {name = "STATS", active = false},
            {name = "LOGS", active = false}
        }
    })
    app:buildGUI()
    app:start()
    
    -- Notifikasi
    app:notify("Pesan", "info")  -- info | success | warning | error
]]

local InfinityLib = {}
InfinityLib.__index = InfinityLib

-- ============================================
-- DEFAULT CONFIG
-- ============================================
InfinityLib.defaultConfig = {
    title = "♾️ INFINITY",
    delay = 5,
    heroId = 7000001,
    mode = "farming",
    startExp = 10,
    step = 3,
    testCount = 15,
    maxExponent = 300,
    showProgress = true,
    autoStart = false,
    compact = true,
    fontScale = 1,
    tabs = {
        {name = "MAIN", active = true},
        {name = "STATS", active = false},
        {name = "LOGS", active = false}
    },
    onDraw = nil,
    onStop = nil,
    onComplete = nil,
    onError = nil
}

-- ============================================
-- CONSTRUCTOR
-- ============================================
function InfinityLib.new(config)
    local self = setmetatable({}, InfinityLib)
    self.config = self:mergeConfig(config or {})
    self.running = false
    self.loopCount = 0
    self.events = {}
    self.gui = nil
    self.mainFrame = nil
    self.tabs = {}
    self.activeTab = nil
    self.notificationQueue = {}
    self.isNotifying = false
    self.totalDraws = 0
    self.successDraws = 0
    self.failDraws = 0
    self.startTime = 0
    self.dropdownOpen = false
    self.isClickingStep = false
    
    self:findEvent()
    return self
end

-- ============================================
-- MERGE CONFIG
-- ============================================
function InfinityLib:mergeConfig(custom)
    local result = {}
    for k, v in pairs(self.defaultConfig) do
        result[k] = custom[k] ~= nil and custom[k] or v
    end
    return result
end

-- ============================================
-- FIND EVENT
-- ============================================
function InfinityLib:findEvent()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local success, event = pcall(function()
        return ReplicatedStorage:WaitForChild("Tool"):WaitForChild("DrawUp"):WaitForChild("Msg"):WaitForChild("DrawHero")
    end)
    if success and event then
        self.DrawHeroEvent = event
        return true
    end
    return false
end

-- ============================================
-- NOTIFICATION SYSTEM
-- ============================================
function InfinityLib:notify(message, type, duration)
    type = type or "info"
    duration = duration or 3
    
    table.insert(self.notificationQueue, {
        message = message,
        type = type,
        duration = duration
    })
    
    if not self.isNotifying then
        self:showNextNotification()
    end
end

function InfinityLib:showNextNotification()
    if #self.notificationQueue == 0 then
        self.isNotifying = false
        return
    end
    
    self.isNotifying = true
    local data = table.remove(self.notificationQueue, 1)
    
    -- Colors
    local colors = {
        info = Color3.fromRGB(100, 150, 255),
        success = Color3.fromRGB(0, 255, 100),
        warning = Color3.fromRGB(255, 200, 0),
        error = Color3.fromRGB(255, 50, 50)
    }
    
    local bgColors = {
        info = Color3.fromRGB(30, 40, 80),
        success = Color3.fromRGB(20, 60, 30),
        warning = Color3.fromRGB(60, 50, 20),
        error = Color3.fromRGB(80, 30, 30)
    }
    
    local icons = {
        info = "ℹ️",
        success = "✅",
        warning = "⚠️",
        error = "❌"
    }
    
    -- Create notification frame
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 280, 0, 40)
    notifFrame.Position = UDim2.new(0.5, -140, 0, -50)
    notifFrame.BackgroundColor3 = bgColors[data.type] or Color3.fromRGB(30, 30, 40)
    notifFrame.BackgroundTransparency = 0.2
    notifFrame.BorderSizePixel = 1
    notifFrame.BorderColor3 = colors[data.type] or Color3.fromRGB(100, 150, 255)
    notifFrame.ZIndex = 99999
    notifFrame.Parent = self.gui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notifFrame
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 1, 0)
    iconLabel.Position = UDim2.new(0, 5, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.Font = Enum.Font.SourceSans
    iconLabel.TextSize = 18
    iconLabel.Text = icons[data.type] or "📢"
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.Parent = notifFrame
    
    -- Message
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -40, 1, 0)
    msgLabel.Position = UDim2.new(0, 35, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.TextColor3 = colors[data.type] or Color3.fromRGB(255, 255, 255)
    msgLabel.Font = Enum.Font.SourceSansBold
    msgLabel.TextSize = 13
    msgLabel.Text = data.message
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Parent = notifFrame
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 1, 0)
    closeBtn.Position = UDim2.new(1, -22, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.Font = Enum.Font.SourceSans
    closeBtn.TextSize = 12
    closeBtn.Text = "✕"
    closeBtn.Parent = notifFrame
    closeBtn.MouseButton1Click:Connect(function()
        notifFrame:Destroy()
        self.isNotifying = false
        self:showNextNotification()
    end)
    
    -- Animate in
    notifFrame.Position = UDim2.new(0.5, -140, 0, -50)
    local tween = game:GetService("TweenService")
    tween:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -140, 0, 20)
    }):Play()
    
    -- Auto dismiss
    task.wait(data.duration)
    
    -- Animate out
    tween:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -140, 0, -50)
    }):Play()
    task.wait(0.3)
    
    notifFrame:Destroy()
    self.isNotifying = false
    self:showNextNotification()
end

-- ============================================
-- GUI BUILDER
-- ============================================
function InfinityLib:buildGUI()
    if self.gui then return end
    
    local config = self.config
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InfinityGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.gui = screenGui
    
    -- Ukuran frame (lebih tinggi untuk tabs)
    local w, h = 240, 340
    if not config.compact then
        w, h = 340, 420
    end
    
    local fs = config.fontScale or 1
    local fTitle = 14 * fs
    local fTab = 12 * fs
    local fStatus = 13 * fs
    local fLabel = 13 * fs
    local fInput = 13 * fs
    local fButton = 15 * fs
    local fResult = 13 * fs
    local fProgress = 13 * fs
    local fInfo = 11 * fs
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, w, 0, h)
    mainFrame.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    self.mainFrame = mainFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = mainFrame
    
    -- Title Bar
    self:buildTitleBar(mainFrame, config.title, fTitle)
    
    -- Tab Bar
    self:buildTabBar(mainFrame, fTab)
    
    -- Status Label
    self.statusLabel = self:buildStatusLabel(mainFrame, fStatus)
    
    -- Tab Contents
    self:buildTabContents(mainFrame, fLabel, fInput, fInfo, fResult, fProgress, fButton)
    
    -- Mini Button
    self:buildMiniButton(screenGui, fButton)
    
    -- Dropdown Container
    self:buildDropdown(screenGui, fInput)
    
    -- Event Connections
    self:setupEvents()
    
    -- Initial results
    self:addResult("✅ Script siap!", Color3.fromRGB(0, 255, 0))
    self:addResult("♾️ " .. config.title .. " - Klik START untuk mulai", Color3.fromRGB(255, 200, 0))
    self:addResult("📊 Mode: " .. config.mode:upper() .. " | Max: " .. config.maxExponent, Color3.fromRGB(150, 150, 170))
    self:addResult("⏱️ Delay: " .. config.delay .. "s | ID: " .. config.heroId, Color3.fromRGB(150, 150, 170))
    
    -- Notifikasi awal
    self:notify("♾️ INFINITY siap digunakan!", "success", 2)
    
    if config.autoStart then
        task.wait(1)
        self:start()
    end
end

-- ============================================
-- BUILD TITLE BAR
-- ============================================
function InfinityLib:buildTitleBar(parent, title, fSize)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 26)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    titleBar.BackgroundTransparency = 0.3
    titleBar.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = titleBar
    
    -- Drag
    local dragData = {dragging = false, startPos = nil, startMouse = nil}
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragData.dragging = true
            dragData.startPos = parent.Position
            dragData.startMouse = input.Position
            if self.dropdownOpen then
                self:closeDropdown()
            end
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragData.dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragData.dragging then
            local delta = input.Position - dragData.startMouse
            local newPos = UDim2.new(
                dragData.startPos.X.Scale, dragData.startPos.X.Offset + delta.X,
                dragData.startPos.Y.Scale, dragData.startPos.Y.Offset + delta.Y
            )
            parent.Position = newPos
            if self.dropdownOpen then
                self:updateDropdownPosition()
            end
        end
    end)
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 4, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = fSize
    titleLabel.Text = "♾️ " .. title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    -- Min Button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 18, 0, 16)
    minBtn.Position = UDim2.new(1, -38, 0, 5)
    minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    minBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
    minBtn.Font = Enum.Font.SourceSans
    minBtn.TextSize = 12
    minBtn.Text = "−"
    minBtn.BorderSizePixel = 0
    minBtn.ZIndex = 10
    minBtn.Parent = titleBar
    minBtn.MouseButton1Click:Connect(function()
        self:minimize()
    end)
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 2)
    minCorner.Parent = minBtn
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 18, 0, 16)
    closeBtn.Position = UDim2.new(1, -18, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.SourceSans
    closeBtn.TextSize = 12
    closeBtn.Text = "✕"
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 10
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        self:destroy()
    end)
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 2)
    closeCorner.Parent = closeBtn
    
    -- Hover effects
    minBtn.MouseEnter:Connect(function()
        minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    minBtn.MouseLeave:Connect(function()
        minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    end)
    closeBtn.MouseEnter:Connect(function()
        closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end)
    
    return titleBar
end

-- ============================================
-- BUILD TAB BAR
-- ============================================
function InfinityLib:buildTabBar(parent, fSize)
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 28)
    tabBar.Position = UDim2.new(0, 0, 0, 26)
    tabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    tabBar.BackgroundTransparency = 0.3
    tabBar.BorderSizePixel = 1
    tabBar.BorderColor3 = Color3.fromRGB(40, 40, 50)
    tabBar.Parent = parent
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 2)
    tabCorner.Parent = tabBar
    
    local tabs = self.config.tabs or {{name = "MAIN", active = true}}
    local tabWidth = 1 / #tabs
    
    for i, tabData in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(tabWidth, -1, 1, -2)
        btn.Position = UDim2.new((i-1) * tabWidth, 1, 0, 1)
        btn.BackgroundColor3 = tabData.active and Color3.fromRGB(40, 100, 180) or Color3.fromRGB(30, 30, 35)
        btn.BackgroundTransparency = 0.2
        btn.TextColor3 = tabData.active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = fSize
        btn.Text = tabData.name
        btn.BorderSizePixel = 0
        btn.ZIndex = 5
        btn.Parent = tabBar
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 3)
        btnCorner.Parent = btn
        
        self.tabs[tabData.name] = {
            button = btn,
            active = tabData.active or false
        }
        
        if tabData.active then
            self.activeTab = tabData.name
        end
        
        btn.MouseButton1Click:Connect(function()
            self:switchTab(tabData.name)
        end)
        
        btn.MouseEnter:Connect(function()
            if not self.tabs[tabData.name].active then
                btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            end
        end)
        btn.MouseLeave:Connect(function()
            if not self.tabs[tabData.name].active then
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            end
        end)
    end
    
    -- Jika tidak ada tab aktif, aktifkan pertama
    if not self.activeTab and #tabs > 0 then
        self:switchTab(tabs[1].name)
    end
end

-- ============================================
-- SWITCH TAB
-- ============================================
function InfinityLib:switchTab(tabName)
    for name, tab in pairs(self.tabs) do
        tab.active = false
        tab.button.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        tab.button.BackgroundTransparency = 0.2
        tab.button.TextColor3 = Color3.fromRGB(180, 180, 180)
    end
    
    if self.tabs[tabName] then
        self.tabs[tabName].active = true
        self.tabs[tabName].button.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
        self.tabs[tabName].button.BackgroundTransparency = 0.2
        self.tabs[tabName].button.TextColor3 = Color3.fromRGB(255, 255, 255)
        self.activeTab = tabName
        
        -- Show/hide content
        if self.tabContents then
            for name, content in pairs(self.tabContents) do
                content.Visible = (name == tabName)
            end
        end
    end
end

-- ============================================
-- BUILD TAB CONTENTS
-- ============================================
function InfinityLib:buildTabContents(parent, fLabel, fInput, fInfo, fResult, fProgress, fButton)
    -- Container untuk semua tab content
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -8, 1, -70)
    contentContainer.Position = UDim2.new(0, 4, 0, 56)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = parent
    self.contentContainer = contentContainer
    
    self.tabContents = {}
    local tabs = self.config.tabs or {{name = "MAIN", active = true}}
    
    for _, tabData in ipairs(tabs) do
        local tabFrame = Instance.new("Frame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.Position = UDim2.new(0, 0, 0, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.Visible = tabData.active or false
        tabFrame.Parent = contentContainer
        self.tabContents[tabData.name] = tabFrame
        
        if tabData.name == "MAIN" or tabData.name == "main" then
            self:buildMainTab(tabFrame, fLabel, fInput, fInfo, fResult, fProgress, fButton)
        elseif tabData.name == "STATS" or tabData.name == "stats" then
            self:buildStatsTab(tabFrame, fLabel)
        elseif tabData.name == "LOGS" or tabData.name == "logs" then
            self:buildLogsTab(tabFrame, fLabel)
        else
            -- Custom tab: kosong, bisa diisi oleh user
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            label.Font = Enum.Font.SourceSans
            label.TextSize = 16
            label.Text = "📄 " .. tabData.name
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.Parent = tabFrame
        end
    end
end

-- ============================================
-- BUILD MAIN TAB
-- ============================================
function InfinityLib:buildMainTab(parent, fLabel, fInput, fInfo, fResult, fProgress, fButton)
    -- Control Frame
    local controlFrame = Instance.new("Frame")
    controlFrame.Size = UDim2.new(1, 0, 0, 115)
    controlFrame.Position = UDim2.new(0, 0, 0, 0)
    controlFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    controlFrame.BackgroundTransparency = 0.3
    controlFrame.BorderSizePixel = 0
    controlFrame.ClipsDescendants = false
    controlFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = controlFrame
    
    -- Helper functions
    local function createLabel(text, x, y)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.18, 0, 0, 18)
        lbl.Position = UDim2.new(x, 0, y, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = fLabel
        lbl.Text = text
        lbl.TextXAlignment = Enum.TextXAlignment.Right
        lbl.Parent = controlFrame
        return lbl
    end
    
    local function createInput(text, x, y, w)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(w or 0.18, 0, 0, 22)
        box.Position = UDim2.new(x, 0, y, 0)
        box.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.Font = Enum.Font.SourceSans
        box.TextSize = fInput
        box.Text = text
        box.ClearTextOnFocus = false
        box.Parent = controlFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 2)
        corner.Parent = box
        
        return box
    end
    
    -- Baris 1
    createLabel("Dly:", 0.02, 2)
    self.delayBox = createInput(tostring(self.config.delay), 0.22, 0)
    createLabel("ID:", 0.44, 2)
    self.idBox = createInput(tostring(self.config.heroId), 0.57, 0, 0.22)
    
    -- Baris 2
    createLabel("Jml:", 0.02, 28)
    self.countBox = createInput(tostring(self.config.testCount), 0.22, 26)
    createLabel("Mul:", 0.44, 28)
    self.startBox = createInput(tostring(self.config.startExp), 0.57, 26, 0.22)
    
    -- Baris 3: Step
    createLabel("Step:", 0.02, 54)
    
    self.stepButton = Instance.new("TextButton")
    self.stepButton.Size = UDim2.new(0.18, 0, 0, 22)
    self.stepButton.Position = UDim2.new(0.22, 0, 0, 52)
    self.stepButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    self.stepButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.stepButton.Font = Enum.Font.SourceSans
    self.stepButton.TextSize = fInput
    self.stepButton.Text = tostring(self.config.step)
    self.stepButton.BorderSizePixel = 0
    self.stepButton.ZIndex = 100
    self.stepButton.Parent = controlFrame
    
    local stepCorner = Instance.new("UICorner")
    stepCorner.CornerRadius = UDim.new(0, 2)
    stepCorner.Parent = self.stepButton
    
    -- Limit Label
    local limitLabel = Instance.new("TextLabel")
    limitLabel.Size = UDim2.new(0.2, 0, 0, 18)
    limitLabel.Position = UDim2.new(0.44, 0, 0, 54)
    limitLabel.BackgroundTransparency = 1
    limitLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    limitLabel.Font = Enum.Font.SourceSansBold
    limitLabel.TextSize = fLabel
    limitLabel.Text = "MAX " .. self.config.maxExponent .. "!"
    limitLabel.TextXAlignment = Enum.TextXAlignment.Left
    limitLabel.Parent = controlFrame
    
    -- Info
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.8, 0, 0, 16)
    infoLabel.Position = UDim2.new(0.02, 0, 0, 80)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.TextSize = fInfo
    infoLabel.Text = "OFF = loop terus | max " .. self.config.maxExponent .. " auto-cancel"
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.Parent = controlFrame
    
    -- Scroll Frame (Results)
    self.scrollFrame = Instance.new("ScrollingFrame")
    self.scrollFrame.Size = UDim2.new(1, 0, 0, 82)
    self.scrollFrame.Position = UDim2.new(0, 0, 0, 120)
    self.scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    self.scrollFrame.BackgroundTransparency = 0.3
    self.scrollFrame.BorderSizePixel = 0
    self.scrollFrame.Parent = parent
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 3)
    scrollCorner.Parent = self.scrollFrame
    
    self.resultList = Instance.new("Frame")
    self.resultList.Size = UDim2.new(1, 0, 0, 0)
    self.resultList.BackgroundTransparency = 1
    self.resultList.Parent = self.scrollFrame
    self.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.resultCount = 0
    
    -- Progress Bar
    local progressFrame = Instance.new("Frame")
    progressFrame.Size = UDim2.new(1, 0, 0, 14)
    progressFrame.Position = UDim2.new(0, 0, 0, 206)
    progressFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    progressFrame.BackgroundTransparency = 0.3
    progressFrame.BorderSizePixel = 0
    progressFrame.Parent = parent
    
    local progCorner = Instance.new("UICorner")
    progCorner.CornerRadius = UDim.new(0, 2)
    progCorner.Parent = progressFrame
    
    self.progressBar = Instance.new("Frame")
    self.progressBar.Size = UDim2.new(0, 0, 1, 0)
    self.progressBar.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    self.progressBar.BackgroundTransparency = 0.5
    self.progressBar.BorderSizePixel = 0
    self.progressBar.Parent = progressFrame
    
    local pcorner = Instance.new("UICorner")
    pcorner.CornerRadius = UDim.new(0, 2)
    pcorner.Parent = self.progressBar
    
    self.progressText = Instance.new("TextLabel")
    self.progressText.Size = UDim2.new(1, 0, 1, 0)
    self.progressText.BackgroundTransparency = 1
    self.progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.progressText.Font = Enum.Font.SourceSansBold
    self.progressText.TextSize = fProgress
    self.progressText.Text = "0%"
    self.progressText.Parent = progressFrame
    
    -- Buttons
    local buttonFrame = Instance.new("Frame")
    buttonFrame.Size = UDim2.new(1, 0, 0, 26)
    buttonFrame.Position = UDim2.new(0, 0, 0, 223)
    buttonFrame.BackgroundTransparency = 1
    buttonFrame.Parent = parent
    
    self.testButton = Instance.new("TextButton")
    self.testButton.Size = UDim2.new(0.32, -2, 1, 0)
    self.testButton.Position = UDim2.new(0, 0, 0, 0)
    self.testButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
    self.testButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.testButton.Font = Enum.Font.SourceSansBold
    self.testButton.TextSize = fButton
    self.testButton.Text = "▶ START"
    self.testButton.Parent = buttonFrame
    
    local tcorner = Instance.new("UICorner")
    tcorner.CornerRadius = UDim.new(0, 3)
    tcorner.Parent = self.testButton
    
    self.testButton.MouseButton1Click:Connect(function()
        self:start()
    end)
    
    self.testButton.MouseEnter:Connect(function()
        if not self.running then
            self.testButton.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        end
    end)
    self.testButton.MouseLeave:Connect(function()
        if not self.running then
            self.testButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
        end
    end)
    
    self.stopButton = Instance.new("TextButton")
    self.stopButton.Size = UDim2.new(0.32, -2, 1, 0)
    self.stopButton.Position = UDim2.new(0.34, 0, 0, 0)
    self.stopButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    self.stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.stopButton.Font = Enum.Font.SourceSansBold
    self.stopButton.TextSize = fButton
    self.stopButton.Text = "⏹ STOP"
    self.stopButton.Visible = false
    self.stopButton.Parent = buttonFrame
    
    local scorrner = Instance.new("UICorner")
    scorrner.CornerRadius = UDim.new(0, 3)
    scorrner.Parent = self.stopButton
    
    self.stopButton.MouseButton1Click:Connect(function()
        self:stop()
    end)
    
    self.stopButton.MouseEnter:Connect(function()
        self.stopButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end)
    self.stopButton.MouseLeave:Connect(function()
        self.stopButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end)
    
    self.resetButton = Instance.new("TextButton")
    self.resetButton.Size = UDim2.new(0.32, -2, 1, 0)
    self.resetButton.Position = UDim2.new(0.68, 0, 0, 0)
    self.resetButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    self.resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.resetButton.Font = Enum.Font.SourceSansBold
    self.resetButton.TextSize = fButton
    self.resetButton.Text = "✕ CLR"
    self.resetButton.Parent = buttonFrame
    
    local rcorner = Instance.new("UICorner")
    rcorner.CornerRadius = UDim.new(0, 3)
    rcorner.Parent = self.resetButton
    
    self.resetButton.MouseButton1Click:Connect(function()
        self:clearResults()
    end)
    
    self.resetButton.MouseEnter:Connect(function()
        self.resetButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    end)
    self.resetButton.MouseLeave:Connect(function()
        self.resetButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    end)
    
    -- Input events
    self.delayBox.FocusLost:Connect(function()
        local val = tonumber(self.delayBox.Text)
        if not val or val < 0.1 then
            self.delayBox.Text = tostring(self.config.delay)
        else
            self.config.delay = val
        end
    end)
    
    self.idBox.FocusLost:Connect(function()
        local val = tonumber(self.idBox.Text)
        if val and val > 0 then
            self.config.heroId = val
        else
            self.idBox.Text = tostring(self.config.heroId)
        end
    end)
    
    self.startBox.FocusLost:Connect(function()
        local val = tonumber(self.startBox.Text)
        if not val or val < 1 then
            self.startBox.Text = tostring(self.config.startExp)
        elseif val > self.config.maxExponent then
            self.startBox.Text = tostring(self.config.maxExponent - 10)
            self.config.startExp = self.config.maxExponent - 10
        else
            self.config.startExp = val
        end
    end)
    
    self.countBox.FocusLost:Connect(function()
        local val = tonumber(self.countBox.Text)
        if not val or val < 1 then
            self.countBox.Text = tostring(self.config.testCount)
        elseif val > 30 then
            self.countBox.Text = "30"
            self.config.testCount = 30
        else
            self.config.testCount = val
        end
    end)
    
    self.stepButton.MouseButton1Click:Connect(function()
        self:toggleDropdown()
    end)
    
    self.stepButton.MouseEnter:Connect(function()
        self.stepButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    self.stepButton.MouseLeave:Connect(function()
        self.stepButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    end)
    
    return controlFrame
end

-- ============================================
-- BUILD STATS TAB
-- ============================================
function InfinityLib:buildStatsTab(parent, fSize)
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(1, -10, 1, -10)
    statsFrame.Position = UDim2.new(0, 5, 0, 5)
    statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    statsFrame.BackgroundTransparency = 0.3
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = statsFrame
    
    local stats = {
        {icon = "🔄", label = "Total Draws", key = "totalDraws"},
        {icon = "✅", label = "Success", key = "successDraws"},
        {icon = "❌", label = "Failed", key = "failDraws"},
        {icon = "⏱️", label = "Runtime", key = "runtime"},
        {icon = "📊", label = "Success Rate", key = "successRate"},
        {icon = "🎯", label = "Current ID", key = "heroId"},
        {icon = "⚡", label = "Mode", key = "mode"},
        {icon = "📈", label = "Max Exponent", key = "maxExponent"},
    }
    
    self.statsLabels = {}
    local yPos = 5
    local rowHeight = 26
    
    for _, stat in ipairs(stats) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, rowHeight)
        row.Position = UDim2.new(0, 0, 0, yPos)
        row.BackgroundTransparency = 1
        row.Parent = statsFrame
        
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 25, 1, 0)
        iconLabel.Position = UDim2.new(0, 2, 0, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        iconLabel.Font = Enum.Font.SourceSans
        iconLabel.TextSize = fSize
        iconLabel.Text = stat.icon
        iconLabel.TextXAlignment = Enum.TextXAlignment.Center
        iconLabel.Parent = row
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 30, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
        nameLabel.Font = Enum.Font.SourceSans
        nameLabel.TextSize = fSize
        nameLabel.Text = stat.label .. ":"
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.5, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.45, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        valueLabel.Font = Enum.Font.SourceSansBold
        valueLabel.TextSize = fSize
        valueLabel.Text = "0"
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = row
        
        self.statsLabels[stat.key] = valueLabel
        
        yPos = yPos + rowHeight + 2
    end
    
    -- Refresh button
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0.3, 0, 0, 28)
    refreshBtn.Position = UDim2.new(0.35, 0, 0, yPos + 10)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.Font = Enum.Font.SourceSansBold
    refreshBtn.TextSize = fSize
    refreshBtn.Text = "🔄 Refresh Stats"
    refreshBtn.Parent = statsFrame
    
    local rcorner = Instance.new("UICorner")
    rcorner.CornerRadius = UDim.new(0, 4)
    rcorner.Parent = refreshBtn
    
    refreshBtn.MouseButton1Click:Connect(function()
        self:updateStats()
        self:notify("📊 Stats di-refresh!", "success", 1.5)
    end)
    
    refreshBtn.MouseEnter:Connect(function()
        refreshBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 220)
    end)
    refreshBtn.MouseLeave:Connect(function()
        refreshBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
    end)
    
    -- Update stats pertama
    self:updateStats()
end

-- ============================================
-- BUILD LOGS TAB
-- ============================================
function InfinityLib:buildLogsTab(parent, fSize)
    local logsFrame = Instance.new("Frame")
    logsFrame.Size = UDim2.new(1, -10, 1, -10)
    logsFrame.Position = UDim2.new(0, 5, 0, 5)
    logsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    logsFrame.BackgroundTransparency = 0.3
    logsFrame.BorderSizePixel = 0
    logsFrame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = logsFrame
    
    -- Log scroll frame
    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, -10, 1, -40)
    logScroll.Position = UDim2.new(0, 5, 0, 5)
    logScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    logScroll.BackgroundTransparency = 0.3
    logScroll.BorderSizePixel = 0
    logScroll.Parent = logsFrame
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 3)
    scrollCorner.Parent = logScroll
    
    self.logList = Instance.new("Frame")
    self.logList.Size = UDim2.new(1, 0, 0, 0)
    self.logList.BackgroundTransparency = 1
    self.logList.Parent = logScroll
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.logCount = 0
    
    -- Clear logs button
    local clearLogs = Instance.new("TextButton")
    clearLogs.Size = UDim2.new(0.2, 0, 0, 26)
    clearLogs.Position = UDim2.new(0.8, -5, 0, -32)
    clearLogs.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    clearLogs.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearLogs.Font = Enum.Font.SourceSansBold
    clearLogs.TextSize = fSize
    clearLogs.Text = "🗑️ Clear"
    clearLogs.Parent = logsFrame
    
    local ccorner = Instance.new("UICorner")
    ccorner.CornerRadius = UDim.new(0, 4)
    ccorner.Parent = clearLogs
    
    clearLogs.MouseButton1Click:Connect(function()
        for _, child in pairs(self.logList:GetChildren()) do
            child:Destroy()
        end
        self.logCount = 0
        logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        self:notify("🗑️ Logs dibersihkan!", "info", 1.5)
    end)
    
    clearLogs.MouseEnter:Connect(function()
        clearLogs.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end)
    clearLogs.MouseLeave:Connect(function()
        clearLogs.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end)
    
    -- Log export button
    local exportLogs = Instance.new("TextButton")
    exportLogs.Size = UDim2.new(0.2, 0, 0, 26)
    exportLogs.Position = UDim2.new(0.6, -5, 0, -32)
    exportLogs.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
    exportLogs.TextColor3 = Color3.fromRGB(255, 255, 255)
    exportLogs.Font = Enum.Font.SourceSansBold
    exportLogs.TextSize = fSize
    exportLogs.Text = "📋 Export"
    exportLogs.Parent = logsFrame
    
    local ecorner = Instance.new("UICorner")
    ecorner.CornerRadius = UDim.new(0, 4)
    ecorner.Parent = exportLogs
    
    exportLogs.MouseButton1Click:Connect(function()
        local logs = {}
        for _, child in pairs(self.logList:GetChildren()) do
            if child:IsA("TextLabel") then
                table.insert(logs, child.Text)
            end
        end
        if #logs > 0 then
            setclipboard(table.concat(logs, "\n"))
            self:notify("📋 Logs disalin ke clipboard!", "success", 2)
        else
            self:notify("⚠️ Tidak ada logs untuk diexport!", "warning", 2)
        end
    end)
    
    exportLogs.MouseEnter:Connect(function()
        exportLogs.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
    end)
    exportLogs.MouseLeave:Connect(function()
        exportLogs.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
    end)
end

-- ============================================
-- BUILD MINI BUTTON
-- ============================================
function InfinityLib:buildMiniButton(screenGui, fSize)
    self.miniButton = Instance.new("TextButton")
    self.miniButton.Size = UDim2.new(0, 32, 0, 32)
    self.miniButton.Position = UDim2.new(1, -36, 1, -36)
    self.miniButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    self.miniButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.miniButton.Font = Enum.Font.SourceSans
    self.miniButton.TextSize = fSize
    self.miniButton.Text = "♾️"
    self.miniButton.Visible = false
    self.miniButton.Parent = screenGui
    
    local mcorner = Instance.new("UICorner")
    mcorner.CornerRadius = UDim.new(0, 16)
    mcorner.Parent = self.miniButton
    
    self.miniButton.MouseButton1Click:Connect(function()
        self:restore()
    end)
    
    self.miniButton.MouseEnter:Connect(function()
        self.miniButton.BackgroundColor3 = Color3.fromRGB(60, 220, 60)
    end)
    self.miniButton.MouseLeave:Connect(function()
        self.miniButton.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
    end)
end

-- ============================================
-- BUILD DROPDOWN
-- ============================================
function InfinityLib:buildDropdown(screenGui, fSize)
    self.dropdownContainer = Instance.new("Frame")
    self.dropdownContainer.Size = UDim2.new(0, 50, 0, 120)
    self.dropdownContainer.Position = UDim2.new(0, 0, 0, 0)
    self.dropdownContainer.BackgroundTransparency = 1
    self.dropdownContainer.ZIndex = 9999
    self.dropdownContainer.Visible = false
    self.dropdownContainer.Parent = screenGui
    
    local dropdownList = Instance.new("Frame")
    dropdownList.Size = UDim2.new(1, 0, 1, 0)
    dropdownList.Position = UDim2.new(0, 0, 0, 0)
    dropdownList.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    dropdownList.BackgroundTransparency = 0.1
    dropdownList.BorderSizePixel = 1
    dropdownList.BorderColor3 = Color3.fromRGB(80, 80, 90)
    dropdownList.ZIndex = 9999
    dropdownList.ClipsDescendants = true
    dropdownList.Parent = self.dropdownContainer
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 3)
    dropdownCorner.Parent = dropdownList
    
    local dropdownScroll = Instance.new("ScrollingFrame")
    dropdownScroll.Size = UDim2.new(1, 0, 1, 0)
    dropdownScroll.Position = UDim2.new(0, 0, 0, 0)
    dropdownScroll.BackgroundTransparency = 1
    dropdownScroll.BorderSizePixel = 0
    dropdownScroll.ZIndex = 9999
    dropdownScroll.Parent = dropdownList
    
    local dropdownContent = Instance.new("Frame")
    dropdownContent.Size = UDim2.new(1, 0, 0, 120)
    dropdownContent.BackgroundTransparency = 1
    dropdownContent.Parent = dropdownScroll
    dropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 120)
    
    self.stepOptions = {"OFF", 1, 2, 3, 6, 9, 12, 15}
    self.stepButtons = {}
    
    for i, step in ipairs(self.stepOptions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 15)
        btn.Position = UDim2.new(0, 0, 0, (i-1) * 15)
        btn.Text = tostring(step)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = fSize
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.ZIndex = 10000
        btn.Parent = dropdownContent
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 2)
        btnCorner.Parent = btn
        
        self.stepButtons[step] = btn
        
        btn.MouseButton1Down:Connect(function()
            self.isClickingStep = true
            self:selectStep(step)
        end)
        
        btn.MouseEnter:Connect(function()
            if btn.Text ~= self.currentStep then
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                btn.BackgroundTransparency = 0.2
            end
        end)
        
        btn.MouseLeave:Connect(function()
            if btn.Text ~= self.currentStep then
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                btn.BackgroundTransparency = 0.3
            end
        end)
    end
    
    self.currentStep = tostring(self.config.step)
    for s, btn in pairs(self.stepButtons) do
        if s == self.currentStep then
            btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
            btn.BackgroundTransparency = 0.3
        end
    end
end

-- ============================================
-- BUILD STATUS LABEL
-- ============================================
function InfinityLib:buildStatusLabel(parent, fSize)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 18)
    label.Position = UDim2.new(0, 4, 0, 56)
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    label.BackgroundTransparency = 0.3
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.SourceSans
    label.TextSize = fSize
    label.Text = "Status: Siap..."
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 2)
    corner.Parent = label
    
    return label
end

-- ============================================
-- SETUP EVENTS
-- ============================================
function InfinityLib:setupEvents()
    -- Close dropdown on scroll
    if self.scrollFrame then
        self.scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            self:closeDropdown()
        end)
    end
    
    -- Close dropdown on outside click
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.isClickingStep then return end
            if not self.dropdownOpen then return end
            
            task.wait(0.05)
            
            local mousePos = game:GetService("UserInputService"):GetMouseLocation()
            local dropPos = self.dropdownContainer and self.dropdownContainer.AbsolutePosition or Vector2.new(0,0)
            local dropSize = self.dropdownContainer and self.dropdownContainer.AbsoluteSize or Vector2.new(0,0)
            
            local inDropdown = (mousePos.X >= dropPos.X and mousePos.X <= dropPos.X + dropSize.X and
                               mousePos.Y >= dropPos.Y and mousePos.Y <= dropPos.Y + dropSize.Y)
            
            local stepPos = self.stepButton and self.stepButton.AbsolutePosition or Vector2.new(0,0)
            local stepSize = self.stepButton and self.stepButton.AbsoluteSize or Vector2.new(0,0)
            local inStep = (mousePos.X >= stepPos.X and mousePos.X <= stepPos.X + stepSize.X and
                           mousePos.Y >= stepPos.Y and mousePos.Y <= stepPos.Y + stepSize.Y)
            
            if not inDropdown and not inStep then
                self:closeDropdown()
            end
        end
    end)
    
    -- Update dropdown position on frame move
    if self.mainFrame then
        self.mainFrame:GetPropertyChangedSignal("Position"):Connect(function()
            if self.dropdownOpen then
                self:updateDropdownPosition()
            end
        end)
    end
    
    -- Update dropdown position every frame
    game:GetService("RunService").RenderStepped:Connect(function()
        if self.dropdownOpen then
            self:updateDropdownPosition()
        end
    end)
end

-- ============================================
-- DROPDOWN METHODS
-- ============================================
function InfinityLib:updateDropdownPosition()
    if not self.stepButton or not self.dropdownContainer then return end
    local stepPos = self.stepButton.AbsolutePosition
    local stepSize = self.stepButton.AbsoluteSize
    self.dropdownContainer.Position = UDim2.new(0, stepPos.X, 0, stepPos.Y + stepSize.Y + 1)
    self.dropdownContainer.Size = UDim2.new(0, 50, 0, 120)
end

function InfinityLib:toggleDropdown()
    if self.dropdownOpen then
        self:closeDropdown()
        return
    end
    self:updateDropdownPosition()
    self.dropdownContainer.Visible = true
    self.dropdownOpen = true
end

function InfinityLib:closeDropdown()
    if self.dropdownOpen then
        self.dropdownContainer.Visible = false
        self.dropdownOpen = false
    end
end

function InfinityLib:selectStep(step)
    self.isClickingStep = true
    self.currentStep = step
    self.stepButton.Text = tostring(step)
    self.config.step = step == "OFF" and 0 or tonumber(step) or 3
    
    for s, btn in pairs(self.stepButtons) do
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        btn.BackgroundTransparency = 0.3
    end
    if self.stepButtons[step] then
        self.stepButtons[step].BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        self.stepButtons[step].BackgroundTransparency = 0.3
    end
    
    self:closeDropdown()
    task.wait(0.05)
    self.isClickingStep = false
    self:notify("📊 Step diubah ke: " .. tostring(step), "info", 1.5)
end

-- ============================================
-- CORE METHODS
-- ============================================
function InfinityLib:addResult(text, color)
    self.resultCount = self.resultCount + 1
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, 18)
    label.Position = UDim2.new(0, 2, 0, (self.resultCount - 1) * 19)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 13 * (self.config.fontScale or 1)
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = self.resultList
    
    self.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, self.resultCount * 19 + 6)
    self.scrollFrame.CanvasPosition = Vector2.new(0, self.scrollFrame.CanvasSize.Y.Offset)
    
    -- Also add to logs
    self:addLog(text, color)
end

function InfinityLib:addLog(text, color)
    self.logCount = self.logCount + 1
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -4, 0, 16)
    label.Position = UDim2.new(0, 2, 0, (self.logCount - 1) * 17)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 11
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = self.logList
    
    local logScroll = self.logList and self.logList.Parent
    if logScroll then
        logScroll.CanvasSize = UDim2.new(0, 0, 0, self.logCount * 17 + 6)
        logScroll.CanvasPosition = Vector2.new(0, logScroll.CanvasSize.Y.Offset)
    end
end

function InfinityLib:updateStats()
    local runtime = os.time() - self.startTime
    local hours = math.floor(runtime / 3600)
    local minutes = math.floor((runtime % 3600) / 60)
    local seconds = runtime % 60
    local timeStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    
    local total = self.totalDraws or 0
    local success = self.successDraws or 0
    local rate = total > 0 and math.floor((success / total) * 100) or 0
    
    local statsMap = {
        totalDraws = tostring(total),
        successDraws = tostring(success),
        failDraws = tostring(total - success),
        runtime = timeStr,
        successRate = rate .. "%",
        heroId = tostring(self.config.heroId),
        mode = self.config.mode:upper(),
        maxExponent = tostring(self.config.maxExponent)
    }
    
    for key, label in pairs(self.statsLabels or {}) do
        if statsMap[key] then
            label.Text = statsMap[key]
        end
    end
end

function InfinityLib:updateProgress(current, total)
    if not self.progressBar or not self.progressText then return end
    local percent
    if total > 0 then
        percent = math.floor((current / total) * 100)
    else
        percent = 0
    end
    self.progressBar.Size = UDim2.new(percent / 100, 0, 1, 0)
    self.progressText.Text = percent .. "%"
    
    if percent < 30 then
        self.progressBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    elseif percent < 70 then
        self.progressBar.BackgroundColor3 = Color3.fromRGB(200, 200, 50)
    else
        self.progressBar.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    end
end

function InfinityLib:clearResults()
    if self.running then return end
    for _, child in pairs(self.resultList:GetChildren()) do
        child:Destroy()
    end
    self.resultCount = 0
    self.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    if self.progressBar then
        self.progressBar.Size = UDim2.new(0, 0, 1, 0)
    end
    if self.progressText then
        self.progressText.Text = "0%"
    end
    if self.statusLabel then
        self.statusLabel.Text = "Status: Siap..."
        self.statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    self:addResult("✅ Hasil dibersihkan", Color3.fromRGB(255, 200, 0))
    self:notify("🗑️ Hasil dibersihkan!", "info", 1.5)
end

function InfinityLib:minimize()
    self.isMinimized = true
    if self.mainFrame then
        self.mainFrame.Visible = false
    end
    if self.miniButton then
        self.miniButton.Visible = true
    end
    self:closeDropdown()
end

function InfinityLib:restore()
    self.isMinimized = false
    if self.miniButton then
        self.miniButton.Visible = false
    end
    if self.mainFrame then
        self.mainFrame.Visible = true
    end
end

function InfinityLib:destroy()
    if self.running then
        self.running = false
    end
    if self.gui then
        self.gui:Destroy()
    end
    self.gui = nil
end

-- ============================================
-- EVENT SYSTEM
-- ============================================
function InfinityLib:on(event, callback)
    if not self.events[event] then
        self.events[event] = {}
    end
    table.insert(self.events[event], callback)
end

function InfinityLib:emit(event, data)
    if self.events[event] then
        for _, cb in ipairs(self.events[event]) do
            pcall(cb, data)
        end
    end
end

-- ============================================
-- SETTERS
-- ============================================
function InfinityLib:setDelay(value)
    self.config.delay = value
    if self.delayBox then
        self.delayBox.Text = tostring(value)
    end
    self:notify("⏱️ Delay diubah ke: " .. value .. "s", "info", 1.5)
end

function InfinityLib:setHeroId(value)
    self.config.heroId = value
    if self.idBox then
        self.idBox.Text = tostring(value)
    end
    self:updateStats()
    self:notify("🎯 ID diubah ke: " .. value, "info", 1.5)
end

function InfinityLib:setMode(mode)
    self.config.mode = mode
    self:updateStats()
    self:notify("⚡ Mode diubah ke: " .. mode:upper(), "info", 1.5)
end

function InfinityLib:setStartExp(value)
    self.config.startExp = value
    if self.startBox then
        self.startBox.Text = tostring(value)
    end
end

function InfinityLib:setStep(value)
    self.config.step = value
    self:selectStep(tostring(value))
end

function InfinityLib:setTestCount(value)
    self.config.testCount = value
    if self.countBox then
        self.countBox.Text = tostring(value)
    end
end

-- ============================================
-- START / STOP
-- ============================================
function InfinityLib:start()
    if self.running then
        self:notify("⚠️ Already running!", "warning", 1.5)
        return
    end
    
    if not self.DrawHeroEvent then
        if not self:findEvent() then
            self:addResult("❌ Event DrawHero tidak ditemukan!", Color3.fromRGB(255, 0, 0))
            self:notify("❌ Event DrawHero tidak ditemukan!", "error", 3)
            return
        end
    end
    
    self.running = true
    self.loopCount = 0
    self.totalDraws = 0
    self.successDraws = 0
    self.failDraws = 0
    self.startTime = os.time()
    
    local config = self.config
    
    if self.testButton then
        self.testButton.Visible = false
    end
    if self.stopButton then
        self.stopButton.Visible = true
    end
    if self.statusLabel then
        self.statusLabel.Text = "⏳ Running..."
        self.statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    end
    
    self:addResult("===== MULAI =====", Color3.fromRGB(100, 200, 255))
    self:addResult("ID: " .. config.heroId .. " | Delay: " .. config.delay .. "s", Color3.fromRGB(200, 200, 200))
    self:notify("▶️ START - Mode: " .. config.mode:upper(), "success", 2)
    
    local isOff = (self.currentStep == "OFF")
    local step = isOff and 0 or (tonumber(self.currentStep) or config.step)
    
    self:emit("start", {mode = isOff and "farming" or "testing"})
    
    if isOff then
        -- FARMING MODE (LOOP)
        self:addResult("♾️ MODE OFF: LOOP TANPA HENTI", Color3.fromRGB(255, 200, 0))
        self:addResult("📌 Tekan STOP untuk berhenti", Color3.fromRGB(255, 200, 0))
        self:addResult("", Color3.fromRGB(200, 200, 200))
        self:notify("♾️ Farming mode aktif!", "success", 2)
        
        if self.progressText then
            self.progressText.Text = "∞"
        end
        if self.progressBar then
            self.progressBar.Size = UDim2.new(1, 0, 1, 0)
            self.progressBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        end
        
        local delay = config.delay
        local exp = config.startExp
        
        while self.running do
            self.loopCount = self.loopCount + 1
            self.totalDraws = self.totalDraws + 1
            
            if exp > config.maxExponent then
                self:addResult("⚠️ MELEWATI BATAS " .. config.maxExponent .. "!", Color3.fromRGB(255, 200, 0))
                self:addResult("⏹️ TEST DICANCEL OTOMATIS", Color3.fromRGB(255, 100, 0))
                self:notify("⚠️ Melewati batas " .. config.maxExponent .. "!", "warning", 2)
                break
            end
            
            local value = 10 ^ exp
            local success = pcall(function()
                return self.DrawHeroEvent:InvokeServer(config.heroId, -value)
            end)
            
            if success then
                self.successDraws = self.successDraws + 1
            else
                self.failDraws = self.failDraws + 1
            end
            
            local statusText = success and "✅" or "❌"
            local color = success and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            
            if self.loopCount % 5 == 0 or not success then
                self:addResult(string.format("%s [%d] e+%d", statusText, self.loopCount, exp), color)
            end
            
            if self.statusLabel then
                self.statusLabel.Text = string.format("♾️ Loop #%d | e+%d", self.loopCount, exp)
            end
            
            self:emit("draw", {
                loop = self.loopCount,
                exponent = exp,
                status = success and "success" or "failed",
                heroId = config.heroId
            })
            
            if not success then
                self:addResult("⏹️ GAGAL! STOP OTOMATIS", Color3.fromRGB(255, 100, 0))
                self:notify("❌ Gagal draw! Berhenti otomatis", "error", 3)
                break
            end
            
            if self.loopCount % 10 == 0 then
                self:updateStats()
            end
            
            task.wait(delay)
        end
        
        if self.running then
            self.running = false
        end
        
        if self.statusLabel then
            self.statusLabel.Text = "⏹️ Stopped - " .. self.loopCount .. " loops"
            self.statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
        
        self:addResult("", Color3.fromRGB(200, 200, 200))
        self:addResult("⏹️ BERHENTI - Loop #" .. self.loopCount, Color3.fromRGB(255, 200, 0))
        
        self:emit("stop", {loop = self.loopCount, mode = "farming"})
        self:notify("⏹️ Berhenti - " .. self.loopCount .. " loops", "info", 2)
        
    else
        -- TESTING MODE (STEP)
        local testCount = config.testCount
        local startExp = config.startExp
        local stepVal = step or config.step
        
        local maxPossibleExp = startExp + ((testCount - 1) * stepVal)
        if maxPossibleExp > config.maxExponent then
            local maxAllowed = math.floor((config.maxExponent - startExp) / stepVal) + 1
            if maxAllowed < 1 then
                self:addResult("❌ Mulai terlalu tinggi!", Color3.fromRGB(255, 0, 0))
                self:addResult("📊 Mulai max: " .. (config.maxExponent - stepVal), Color3.fromRGB(255, 200, 0))
                self:notify("❌ Mulai terlalu tinggi!", "error", 2)
                self:stop()
                return
            end
            testCount = maxAllowed
            self.countBox.Text = tostring(testCount)
            self:addResult("⚠️ Disesuaikan ke " .. testCount .. " test (max " .. config.maxExponent .. ")", Color3.fromRGB(255, 200, 0))
        end
        
        self:addResult(string.format("📊 1e+%d x%d | Step:%d", startExp, testCount, stepVal), Color3.fromRGB(200, 200, 200))
        self:notify("🔬 Testing mode aktif! " .. testCount .. " test", "info", 2)
        
        local lastSuccess = 0
        local firstFail = nil
        local currentTest = 0
        
        for i = 0, testCount - 1 do
            if not self.running then break end
            
            local exp = startExp + (i * stepVal)
            if exp > config.maxExponent then break end
            
            currentTest = currentTest + 1
            self.totalDraws = self.totalDraws + 1
            self:updateProgress(currentTest, testCount)
            
            local value = 10 ^ exp
            local success = pcall(function()
                return self.DrawHeroEvent:InvokeServer(config.heroId, -value)
            end)
            
            if success then
                self.successDraws = self.successDraws + 1
            else
                self.failDraws = self.failDraws + 1
            end
            
            local statusText = success and "✅" or "❌"
            local color = success and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            
            self:addResult(string.format("%s e+%d", statusText, exp), color)
            
            self:emit("draw", {
                test = currentTest,
                exponent = exp,
                status = success and "success" or "failed",
                heroId = config.heroId
            })
            
            if success then
                lastSuccess = exp
            else
                if not firstFail then
                    firstFail = exp
                end
                self:notify("❌ Gagal di e+ " .. exp, "error", 2)
                break
            end
            
            if currentTest % 5 == 0 then
                self:updateStats()
            end
            
            task.wait(config.delay)
        end
        
        self.running = false
        self:updateProgress(testCount, testCount)
        
        self:addResult("===== HASIL =====", Color3.fromRGB(100, 200, 255))
        
        local result = {maxExp = lastSuccess, failExp = firstFail}
        
        if firstFail then
            self:addResult(string.format("✅ Max: 1e+%d", lastSuccess), Color3.fromRGB(0, 255, 0))
            self:addResult(string.format("❌ Fail: 1e+%d", firstFail), Color3.fromRGB(255, 0, 0))
            local safeMin = math.max(1, lastSuccess - (stepVal * 2))
            self:addResult(string.format("📊 Aman: 1e+%d-1e+%d", safeMin, lastSuccess), Color3.fromRGB(255, 200, 0))
            if self.statusLabel then
                self.statusLabel.Text = string.format("✅ Selesai! Aman: 1e+%d", lastSuccess)
                self.statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            end
            result.complete = true
            self:notify("✅ Selesai! Maks: 1e+" .. lastSuccess, "success", 3)
        else
            self:addResult("✅ SEMUA BERHASIL!", Color3.fromRGB(0, 255, 0))
            if self.statusLabel then
                self.statusLabel.Text = "✅ Semua berhasil!"
                self.statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            end
            result.complete = true
            result.allSuccess = true
            self:notify("✅ Semua test berhasil!", "success", 3)
        end
        
        self:emit("complete", result)
        self:updateStats()
        
        if self.config.onComplete then
            pcall(self.config.onComplete, result)
        end
    end
    
    -- Reset UI
    if self.testButton then
        self.testButton.Visible = true
    end
    if self.stopButton then
        self.stopButton.Visible = false
    end
    if self.testButton then
        self.testButton.Text = "▶ START"
        self.testButton.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
    end
    
    self:updateStats()
end

function InfinityLib:stop()
    if self.running then
        self.running = false
        if self.statusLabel then
            self.statusLabel.Text = "⏹️ Menghentikan..."
            self.statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
        
        self:emit("stop", {loop = self.loopCount, manual = true})
        self:notify("⏹️ Menghentikan proses...", "warning", 2)
        
        if self.config.onStop then
            pcall(self.config.onStop, {loop = self.loopCount})
        end
    end
end

-- ============================================
-- EXPORT
-- ============================================
return InfinityLib
