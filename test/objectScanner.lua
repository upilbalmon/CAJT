local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- ===== THEME (iOS Compact Style) =====
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

-- Fungsi untuk menghancurkan GUI lama
local function destroyExistingGUI()
    local playerGui = player:WaitForChild("PlayerGui")
    local existingGUI = playerGui:FindFirstChild("ObjectScannerGUI")
    if existingGUI then
        existingGUI:Destroy()
        return true
    end
    return false
end
destroyExistingGUI()

-- Tunggu PlayerGui
local PlayerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

-- Variabel Utama
local isScanning = false
local scanConnection = nil
local scannedObjects = {}
local currentFilter = "truss"
local searchRadius = 15000
local displayCount = 5
local isUpdating = false

-- ===== UI COMPONENTS =====

-- Fungsi membuat iOS Switch
local function CreateiOSSwitch(parent, position, initialState, labelText)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 28)
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
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local track = Instance.new("TextButton")
    track.Size = UDim2.new(0, 44, 0, 24)
    track.Position = UDim2.new(1, -44, 0.5, -12)
    track.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    track.BackgroundTransparency = 0
    track.BorderSizePixel = 0
    track.AutoButtonColor = false
    track.Text = ""
    track.Parent = container
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 12)
    trackCorner.Parent = track
    
    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BackgroundTransparency = 0
    knob.BorderSizePixel = 0
    knob.AutoButtonColor = false
    knob.Text = ""
    knob.Parent = track
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 10)
    knobCorner.Parent = knob
    
    local knobShadow = Instance.new("UIShadow")
    knobShadow.Color = Color3.fromRGB(0, 0, 0)
    knobShadow.Transparency = 0.2
    knobShadow.Offset = UDim2.new(0, 0, 0, 1)
    knobShadow.Parent = knob
    
    local isOn = initialState or false
    local onToggle = nil
    
    local function updateSwitch()
        local targetPosition = isOn and UDim2.new(0, 22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
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

-- ===== GUI CREATION =====
local function CreateGUI()
    local MainFrame = Instance.new("ScreenGui")
    MainFrame.Name = "ObjectScannerGUI"
    MainFrame.Parent = PlayerGui
    MainFrame.ResetOnSpawn = false
    MainFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 0, 0, 0)
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
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
    TitleBar.Size = UDim2.new(1, 0, 0, 38)
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
    TitleText.Text = "🔍 Object Scanner"
    TitleText.TextColor3 = THEME.textPrimary
    TitleText.BackgroundTransparency = 1
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 15
    TitleText.Parent = TitleBar

    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 24, 0, 24)
    CloseButton.Position = UDim2.new(1, -30, 0, 7)
    CloseButton.Text = "✕"
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 12
    CloseButton.TextColor3 = THEME.textWhite
    CloseButton.BackgroundColor3 = THEME.primaryRed
    CloseButton.AutoButtonColor = false
    CloseButton.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 12)
    CloseCorner.Parent = CloseButton

    -- Minimize Button
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
    MinimizeButton.Position = UDim2.new(1, -58, 0, 7)
    MinimizeButton.Text = "−"
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.TextSize = 16
    MinimizeButton.TextColor3 = THEME.textWhite
    MinimizeButton.BackgroundColor3 = THEME.primaryYellow
    MinimizeButton.AutoButtonColor = false
    MinimizeButton.Parent = TitleBar

    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 12)
    MinimizeCorner.Parent = MinimizeButton

    -- Content
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -12, 1, -48)
    Content.Position = UDim2.new(0, 6, 0, 42)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    -- ===== 1. STATUS GROUP (0-40) =====
    local StatusGroup = Instance.new("Frame")
    StatusGroup.Size = UDim2.new(1, 0, 0, 40)
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

    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -10, 1, 0)
    StatusLabel.Position = UDim2.new(0, 5, 0, 0)
    StatusLabel.Text = "⏸ Stopped"
    StatusLabel.TextColor3 = THEME.primaryRed
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.TextSize = 13
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Parent = StatusGroup

    -- ===== 2. FILTER GROUP (46-206) =====
    local FilterGroup = Instance.new("Frame")
    FilterGroup.Size = UDim2.new(1, 0, 0, 160)
    FilterGroup.Position = UDim2.new(0, 0, 0, 46)
    FilterGroup.BackgroundColor3 = THEME.cardBackground
    FilterGroup.BackgroundTransparency = 0
    FilterGroup.BorderSizePixel = 0
    FilterGroup.Parent = Content

    local FilterCorner = Instance.new("UICorner")
    FilterCorner.CornerRadius = UDim.new(0, 8)
    FilterCorner.Parent = FilterGroup

    local FilterBorder = Instance.new("UIStroke")
    FilterBorder.Color = THEME.separator
    FilterBorder.Thickness = 0.5
    FilterBorder.Parent = FilterGroup

    -- BARIS 1: Filter Keyword
    local FilterLabel = Instance.new("TextLabel")
    FilterLabel.Size = UDim2.new(1, -10, 0, 22)
    FilterLabel.Position = UDim2.new(0, 5, 0, 4)
    FilterLabel.Text = "Filter Keyword"
    FilterLabel.TextColor3 = THEME.textPrimary
    FilterLabel.BackgroundTransparency = 1
    FilterLabel.Font = Enum.Font.GothamBold
    FilterLabel.TextSize = 12
    FilterLabel.TextXAlignment = Enum.TextXAlignment.Left
    FilterLabel.Parent = FilterGroup

    -- BARIS 2: Dropdown + Radius + Show Top
    -- Dropdown Filter (kiri)
    local DropdownBtn = Instance.new("TextButton")
    DropdownBtn.Size = UDim2.new(0, 110, 0, 28)
    DropdownBtn.Position = UDim2.new(0, 5, 0, 28)
    DropdownBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    DropdownBtn.Text = "truss"
    DropdownBtn.TextColor3 = THEME.textPrimary
    DropdownBtn.Font = Enum.Font.GothamMedium
    DropdownBtn.TextSize = 13
    DropdownBtn.AutoButtonColor = false
    DropdownBtn.Parent = FilterGroup
    local DropCorner = Instance.new("UICorner")
    DropCorner.CornerRadius = UDim.new(0, 6)
    DropCorner.Parent = DropdownBtn

    local DropArrow = Instance.new("TextLabel")
    DropArrow.Size = UDim2.new(0, 20, 1, 0)
    DropArrow.Position = UDim2.new(1, -22, 0, 0)
    DropArrow.Text = "▼"
    DropArrow.TextColor3 = THEME.textSecondary
    DropArrow.Font = Enum.Font.GothamMedium
    DropArrow.TextSize = 10
    DropArrow.BackgroundTransparency = 1
    DropArrow.Parent = DropdownBtn

    -- Dropdown List
    local DropdownList = Instance.new("Frame")
    DropdownList.Size = UDim2.new(0, 110, 0, 90)
    DropdownList.Position = UDim2.new(0, 5, 0, 56)
    DropdownList.BackgroundColor3 = THEME.cardBackground
    DropdownList.BorderSizePixel = 0
    DropdownList.Visible = false
    DropdownList.ZIndex = 100
    DropdownList.Parent = FilterGroup
    local ListCorner = Instance.new("UICorner")
    ListCorner.CornerRadius = UDim.new(0, 8)
    ListCorner.Parent = DropdownList

    local ListShadow = Instance.new("UIShadow")
    ListShadow.Parent = DropdownList

    local filterOptions = {"truss", "ladderbase", "touch"}
    for i, opt in ipairs(filterOptions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Position = UDim2.new(0, 0, 0, (i-1)*30)
        btn.BackgroundColor3 = THEME.cardBackground
        btn.Text = opt
        btn.TextColor3 = THEME.textPrimary
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 13
        btn.AutoButtonColor = false
        btn.Parent = DropdownList
        btn.ZIndex = 100
        
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = THEME.buttonHover
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = THEME.cardBackground
        end)
        btn.MouseButton1Click:Connect(function()
            currentFilter = opt
            DropdownBtn.Text = opt
            DropdownList.Visible = false
            clearLog()
            if isScanning then
                scanObjects()
            end
        end)
    end

    DropdownBtn.MouseButton1Click:Connect(function()
        DropdownList.Visible = not DropdownList.Visible
    end)

    -- Radius Input (tengah)
    local RadiusBox = Instance.new("TextBox")
    RadiusBox.Size = UDim2.new(0, 90, 0, 28)
    RadiusBox.Position = UDim2.new(0, 120, 0, 28)
    RadiusBox.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    RadiusBox.PlaceholderText = "Radius"
    RadiusBox.Text = "15000"
    RadiusBox.TextColor3 = THEME.textPrimary
    RadiusBox.Font = Enum.Font.GothamMedium
    RadiusBox.TextSize = 13
    RadiusBox.ClearTextOnFocus = false
    RadiusBox.Parent = FilterGroup
    local RadiusCorner = Instance.new("UICorner")
    RadiusCorner.CornerRadius = UDim.new(0, 6)
    RadiusCorner.Parent = RadiusBox

    local RadiusApply = Instance.new("TextButton")
    RadiusApply.Size = UDim2.new(0, 35, 0, 28)
    RadiusApply.Position = UDim2.new(0, 214, 0, 28)
    RadiusApply.BackgroundColor3 = THEME.primaryBlue
    RadiusApply.Text = "Set"
    RadiusApply.TextColor3 = THEME.textWhite
    RadiusApply.Font = Enum.Font.GothamBold
    RadiusApply.TextSize = 11
    RadiusApply.AutoButtonColor = false
    RadiusApply.Parent = FilterGroup
    local RadiusApplyCorner = Instance.new("UICorner")
    RadiusApplyCorner.CornerRadius = UDim.new(0, 6)
    RadiusApplyCorner.Parent = RadiusApply

    RadiusApply.MouseButton1Click:Connect(function()
        local num = tonumber(RadiusBox.Text)
        if num and num > 0 then
            searchRadius = num
            clearLog()
            if isScanning then
                scanObjects()
            end
        end
    end)

    -- Show Top Dropdown (kanan)
    local ShowLabel = Instance.new("TextLabel")
    ShowLabel.Size = UDim2.new(0, 60, 0, 22)
    ShowLabel.Position = UDim2.new(1, -120, 0, 4)
    ShowLabel.Text = "Show Top"
    ShowLabel.TextColor3 = THEME.textPrimary
    ShowLabel.BackgroundTransparency = 1
    ShowLabel.Font = Enum.Font.GothamMedium
    ShowLabel.TextSize = 11
    ShowLabel.TextXAlignment = Enum.TextXAlignment.Right
    ShowLabel.Parent = FilterGroup

    local ShowDropdownBtn = Instance.new("TextButton")
    ShowDropdownBtn.Size = UDim2.new(0, 55, 0, 28)
    ShowDropdownBtn.Position = UDim2.new(1, -60, 0, 28)
    ShowDropdownBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    ShowDropdownBtn.Text = "5"
    ShowDropdownBtn.TextColor3 = THEME.textPrimary
    ShowDropdownBtn.Font = Enum.Font.GothamMedium
    ShowDropdownBtn.TextSize = 13
    ShowDropdownBtn.AutoButtonColor = false
    ShowDropdownBtn.Parent = FilterGroup
    local ShowDropCorner = Instance.new("UICorner")
    ShowDropCorner.CornerRadius = UDim.new(0, 6)
    ShowDropCorner.Parent = ShowDropdownBtn

    local ShowArrow = Instance.new("TextLabel")
    ShowArrow.Size = UDim2.new(0, 15, 1, 0)
    ShowArrow.Position = UDim2.new(1, -17, 0, 0)
    ShowArrow.Text = "▼"
    ShowArrow.TextColor3 = THEME.textSecondary
    ShowArrow.Font = Enum.Font.GothamMedium
    ShowArrow.TextSize = 10
    ShowArrow.BackgroundTransparency = 1
    ShowArrow.Parent = ShowDropdownBtn

    local ShowDropdownList = Instance.new("Frame")
    ShowDropdownList.Size = UDim2.new(0, 55, 0, 120)
    ShowDropdownList.Position = UDim2.new(1, -60, 0, 56)
    ShowDropdownList.BackgroundColor3 = THEME.cardBackground
    ShowDropdownList.BorderSizePixel = 0
    ShowDropdownList.Visible = false
    ShowDropdownList.ZIndex = 100
    ShowDropdownList.Parent = FilterGroup
    local ShowListCorner = Instance.new("UICorner")
    ShowListCorner.CornerRadius = UDim.new(0, 8)
    ShowListCorner.Parent = ShowDropdownList

    local ShowListShadow = Instance.new("UIShadow")
    ShowListShadow.Parent = ShowDropdownList

    local showOptions = {"1", "3", "5", "10"}
    for i, opt in ipairs(showOptions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Position = UDim2.new(0, 0, 0, (i-1)*30)
        btn.BackgroundColor3 = THEME.cardBackground
        btn.Text = opt
        btn.TextColor3 = THEME.textPrimary
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 13
        btn.AutoButtonColor = false
        btn.Parent = ShowDropdownList
        btn.ZIndex = 100
        
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = THEME.buttonHover
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = THEME.cardBackground
        end)
        btn.MouseButton1Click:Connect(function()
            displayCount = tonumber(opt)
            ShowDropdownBtn.Text = opt
            ShowDropdownList.Visible = false
            if isScanning then
                scanObjects()
            end
        end)
    end

    ShowDropdownBtn.MouseButton1Click:Connect(function()
        ShowDropdownList.Visible = not ShowDropdownList.Visible
    end)

    -- BARIS 3: Custom Input
    local CustomBox = Instance.new("TextBox")
    CustomBox.Size = UDim2.new(0, 200, 0, 28)
    CustomBox.Position = UDim2.new(0, 5, 0, 62)
    CustomBox.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    CustomBox.PlaceholderText = "custom keyword"
    CustomBox.Text = ""
    CustomBox.TextColor3 = THEME.textPrimary
    CustomBox.Font = Enum.Font.GothamMedium
    CustomBox.TextSize = 13
    CustomBox.ClearTextOnFocus = false
    CustomBox.Parent = FilterGroup
    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 6)
    BoxCorner.Parent = CustomBox

    local ApplyBtn = Instance.new("TextButton")
    ApplyBtn.Size = UDim2.new(0, 55, 0, 28)
    ApplyBtn.Position = UDim2.new(0, 210, 0, 62)
    ApplyBtn.BackgroundColor3 = THEME.primaryBlue
    ApplyBtn.Text = "Apply"
    ApplyBtn.TextColor3 = THEME.textWhite
    ApplyBtn.Font = Enum.Font.GothamBold
    ApplyBtn.TextSize = 12
    ApplyBtn.AutoButtonColor = false
    ApplyBtn.Parent = FilterGroup
    local ApplyCorner = Instance.new("UICorner")
    ApplyCorner.CornerRadius = UDim.new(0, 6)
    ApplyCorner.Parent = ApplyBtn

    ApplyBtn.MouseButton1Click:Connect(function()
        local inputText = string.lower(CustomBox.Text)
        if inputText ~= "" then
            currentFilter = inputText
            DropdownBtn.Text = inputText
            clearLog()
            if isScanning then
                scanObjects()
            end
            DropdownList.Visible = false
        end
    end)

    -- BARIS 4: Separator
    local Separator = Instance.new("Frame")
    Separator.Size = UDim2.new(1, -10, 0, 1)
    Separator.Position = UDim2.new(0, 5, 0, 96)
    Separator.BackgroundColor3 = THEME.separator
    Separator.BackgroundTransparency = 0
    Separator.BorderSizePixel = 0
    Separator.Parent = FilterGroup

    -- BARIS 5: Info Filter
    local FilterInfo = Instance.new("TextLabel")
    FilterInfo.Size = UDim2.new(1, -10, 0, 20)
    FilterInfo.Position = UDim2.new(0, 5, 0, 100)
    FilterInfo.Text = "ℹ️ Filter: truss | Radius: 15000 | Show: 5"
    FilterInfo.TextColor3 = THEME.textSecondary
    FilterInfo.BackgroundTransparency = 1
    FilterInfo.Font = Enum.Font.Gotham
    FilterInfo.TextSize = 10
    FilterInfo.TextXAlignment = Enum.TextXAlignment.Center
    FilterInfo.Parent = FilterGroup

    -- ===== 3. LOG FRAME (212-366) =====
    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(1, -20, 0, 154)
    logFrame.Position = UDim2.new(0, 10, 0, 212)
    logFrame.BackgroundColor3 = THEME.cardBackground
    logFrame.BackgroundTransparency = 0
    logFrame.Parent = Content
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 8)
    logCorner.Parent = logFrame

    -- Header Log
    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -10, 0, 25)
    headerLabel.Position = UDim2.new(0, 5, 0, 2)
    headerLabel.Text = "📋 Scan Results"
    headerLabel.TextColor3 = THEME.primaryBlue
    headerLabel.BackgroundTransparency = 1
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextSize = 13
    headerLabel.TextXAlignment = Enum.TextXAlignment.Center
    headerLabel.Parent = logFrame

    -- ScrollingFrame (LANGSUNG di logFrame)
    local ResultScroll = Instance.new("ScrollingFrame")
    ResultScroll.Size = UDim2.new(1, -10, 1, -35)
    ResultScroll.Position = UDim2.new(0, 5, 0, 30)
    ResultScroll.BackgroundTransparency = 1
    ResultScroll.ScrollBarThickness = 3
    ResultScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ResultScroll.Parent = logFrame

    local ResultLayout = Instance.new("UIListLayout")
    ResultLayout.Padding = UDim.new(0, 3)
    ResultLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ResultLayout.Parent = ResultScroll

    ResultLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ResultScroll.CanvasSize = UDim2.new(0, 0, 0, ResultLayout.AbsoluteContentSize.Y + 5)
    end)

    -- Empty Label
    local EmptyLabel = Instance.new("TextLabel")
    EmptyLabel.Size = UDim2.new(1, 0, 0, 30)
    EmptyLabel.BackgroundTransparency = 1
    EmptyLabel.Text = "No objects found"
    EmptyLabel.TextColor3 = THEME.textSecondary
    EmptyLabel.Font = Enum.Font.GothamMedium
    EmptyLabel.TextSize = 13
    EmptyLabel.Visible = true
    EmptyLabel.Parent = ResultScroll

    -- ===== 4. CONTROL GROUP (374-424) =====
    local ControlGroup = Instance.new("Frame")
    ControlGroup.Size = UDim2.new(1, 0, 0, 50)
    ControlGroup.Position = UDim2.new(0, 0, 0, 374)
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

    local StartBtn = Instance.new("TextButton")
    StartBtn.Size = UDim2.new(0, 100, 0, 34)
    StartBtn.Position = UDim2.new(0, 10, 0, 8)
    StartBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
    StartBtn.Text = "▶ Start"
    StartBtn.TextColor3 = THEME.textWhite
    StartBtn.Font = Enum.Font.GothamBold
    StartBtn.TextSize = 13
    StartBtn.AutoButtonColor = false
    StartBtn.Parent = ControlGroup
    local StartCorner = Instance.new("UICorner")
    StartCorner.CornerRadius = UDim.new(0, 8)
    StartCorner.Parent = StartBtn

    local StopBtn = Instance.new("TextButton")
    StopBtn.Size = UDim2.new(0, 100, 0, 34)
    StopBtn.Position = UDim2.new(1, -110, 0, 8)
    StopBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    StopBtn.Text = "⏹ Stop"
    StopBtn.TextColor3 = THEME.textWhite
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.TextSize = 13
    StopBtn.AutoButtonColor = false
    StopBtn.Parent = ControlGroup
    local StopCorner = Instance.new("UICorner")
    StopCorner.CornerRadius = UDim.new(0, 8)
    StopCorner.Parent = StopBtn
    StopBtn.Active = false

    -- ===== RETURN GUI TABLE =====
    return {
        MainFrame = MainFrame,
        Frame = Frame,
        Content = Content,
        StatusLabel = StatusLabel,
        StartBtn = StartBtn,
        StopBtn = StopBtn,
        CloseButton = CloseButton,
        MinimizeButton = MinimizeButton,
        TitleText = TitleText,
        ResultScroll = ResultScroll,
        EmptyLabel = EmptyLabel,
        ResultLayout = ResultLayout,
        FilterInfo = FilterInfo,
        DropdownBtn = DropdownBtn,
        RadiusBox = RadiusBox,
        ShowDropdownBtn = ShowDropdownBtn,
        CustomBox = CustomBox,
        logFrame = logFrame,
        headerLabel = headerLabel,
    }
end

-- ===== GUI INSTANCE =====
local GUI = CreateGUI()

-- ===== FUNGSI UTAMA =====

local function clearLog()
    scannedObjects = {}
    for _, child in ipairs(GUI.ResultScroll:GetChildren()) do
        if child ~= GUI.EmptyLabel and child:IsA("Frame") then
            child:Destroy()
        end
    end
    GUI.EmptyLabel.Visible = true
    GUI.ResultScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
end

local function updateRoot()
    character = player.Character or player.CharacterAdded:Wait()
    if character then
        root = character:WaitForChild("HumanoidRootPart")
    end
end

-- ===== UPDATE TAMPILAN LOG =====
local function updateResultDisplay()
    if isUpdating then return end
    isUpdating = true
    
    local toRemove = {}
    for _, child in ipairs(GUI.ResultScroll:GetChildren()) do
        if child ~= GUI.EmptyLabel and child:IsA("Frame") then
            table.insert(toRemove, child)
        end
    end
    for _, child in ipairs(toRemove) do
        child:Destroy()
    end
    
    GUI.ResultScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    if #scannedObjects == 0 then
        GUI.EmptyLabel.Visible = true
        GUI.StatusLabel.Text = "🔍 No objects found"
        GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 204, 0)
        isUpdating = false
        return
    end
    
    GUI.EmptyLabel.Visible = false
    
    local displayLimit = math.min(displayCount, #scannedObjects)
    
    for rank = 1, displayLimit do
        local obj = scannedObjects[rank]
        if obj then
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, -4, 0, 36)
            item.BackgroundTransparency = 0.15
            item.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0, 6)
            itemCorner.Parent = item
            
            local rankColor = Color3.fromRGB(200, 200, 200)
            local rankText = ""
            if rank == 1 then
                rankColor = Color3.fromRGB(255, 215, 0)
                rankText = "🥇"
            elseif rank == 2 then
                rankColor = Color3.fromRGB(192, 192, 192)
                rankText = "🥈"
            elseif rank == 3 then
                rankColor = Color3.fromRGB(205, 127, 50)
                rankText = "🥉"
            else
                rankText = string.format("#%d", rank)
            end
            
            local rankLabel = Instance.new("TextLabel")
            rankLabel.Size = UDim2.new(0, 30, 1, 0)
            rankLabel.Position = UDim2.new(0, 4, 0, 0)
            rankLabel.BackgroundTransparency = 1
            rankLabel.Text = rankText
            rankLabel.TextColor3 = rankColor
            rankLabel.Font = Enum.Font.GothamBold
            rankLabel.TextSize = 13
            rankLabel.TextXAlignment = Enum.TextXAlignment.Center
            rankLabel.Parent = item
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0, 140, 0, 17)
            nameLabel.Position = UDim2.new(0, 38, 0, 2)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = obj.Name
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 12
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = item
            
            local distLabel = Instance.new("TextLabel")
            distLabel.Size = UDim2.new(0, 90, 0, 17)
            distLabel.Position = UDim2.new(1, -95, 0, 2)
            distLabel.BackgroundTransparency = 1
            distLabel.Text = string.format("📏 %.1f", obj.Distance)
            distLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
            distLabel.Font = Enum.Font.GothamMedium
            distLabel.TextSize = 11
            distLabel.TextXAlignment = Enum.TextXAlignment.Right
            distLabel.Parent = item
            
            local posLabel = Instance.new("TextLabel")
            posLabel.Size = UDim2.new(1, -45, 0, 15)
            posLabel.Position = UDim2.new(0, 38, 0, 20)
            posLabel.BackgroundTransparency = 1
            posLabel.Text = string.format("📍 X:%.0f Y:%.0f Z:%.0f", 
                obj.Position.X, obj.Position.Y, obj.Position.Z)
            posLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
            posLabel.Font = Enum.Font.Gotham
            posLabel.TextSize = 10
            posLabel.TextXAlignment = Enum.TextXAlignment.Left
            posLabel.Parent = item
            
            if rank <= 3 then
                local border = Instance.new("UIStroke")
                border.Color = rankColor
                border.Thickness = 1
                border.Transparency = 0.4
                border.Parent = item
            end
            
            item.Parent = GUI.ResultScroll
        end
    end
    
    local childCount = 0
    for _, child in ipairs(GUI.ResultScroll:GetChildren()) do
        if child:IsA("Frame") then
            childCount = childCount + 1
        end
    end
    GUI.ResultScroll.CanvasSize = UDim2.new(0, 0, 0, childCount * 39 + 10)
    
    GUI.StatusLabel.Text = string.format("✅ Found %d objects (showing top %d)", 
        #scannedObjects, displayLimit)
    GUI.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    
    isUpdating = false
end

-- ===== FUNGSI SCAN =====
local function scanObjects()
    if isUpdating then return end
    
    if not character or not root then
        updateRoot()
        return
    end
    
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = {character}
    
    local parts = Workspace:GetPartBoundsInRadius(root.Position, searchRadius, overlap)
    scannedObjects = {}
    
    for _, part in ipairs(parts) do
        if part and part.Position and part.Name then
            local lowerName = string.lower(part.Name)
            if string.find(lowerName, string.lower(currentFilter)) then
                local distance = (root.Position - part.Position).Magnitude
                table.insert(scannedObjects, {
                    Name = part.Name,
                    Position = part.Position,
                    Distance = distance
                })
            end
        end
    end
    
    table.sort(scannedObjects, function(a, b)
        return a.Distance < b.Distance
    end)
    
    updateResultDisplay()
end

-- ===== FUNGSI START/STOP =====
local function startScanning()
    if isScanning then return end
    
    if not character or not root then
        updateRoot()
        if not character or not root then
            GUI.StatusLabel.Text = "❌ Character not found!"
            GUI.StatusLabel.TextColor3 = THEME.primaryRed
            return
        end
    end
    
    isScanning = true
    clearLog()
    GUI.StatusLabel.Text = "🔄 Scanning..."
    GUI.StatusLabel.TextColor3 = THEME.primaryBlue
    
    GUI.StartBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    GUI.StartBtn.Text = "⏳ Running"
    GUI.StartBtn.Active = false
    
    GUI.StopBtn.BackgroundColor3 = THEME.primaryRed
    GUI.StopBtn.Text = "⏹ Stop"
    GUI.StopBtn.Active = true
    
    task.spawn(function()
        while isScanning do
            scanObjects()
            task.wait(0.5)
        end
    end)
end

local function stopScanning()
    if not isScanning then return end
    
    isScanning = false
    if scanConnection then
        scanConnection:Disconnect()
        scanConnection = nil
    end
    
    GUI.StatusLabel.Text = "⏸ Stopped"
    GUI.StatusLabel.TextColor3 = THEME.primaryRed
    
    GUI.StartBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
    GUI.StartBtn.Text = "▶ Start"
    GUI.StartBtn.Active = true
    
    GUI.StopBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    GUI.StopBtn.Text = "⏹ Stopped"
    GUI.StopBtn.Active = false
end

-- ===== EVENT HANDLERS =====

GUI.StartBtn.MouseButton1Click:Connect(startScanning)
GUI.StopBtn.MouseButton1Click:Connect(stopScanning)

local function setupHover(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        if btn.Active ~= false then
            btn.BackgroundColor3 = hoverColor
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.Active ~= false then
            btn.BackgroundColor3 = normalColor
        end
    end)
end
setupHover(GUI.StartBtn, Color3.fromRGB(52, 199, 89), Color3.fromRGB(40, 180, 70))
setupHover(GUI.StopBtn, THEME.primaryRed, Color3.fromRGB(220, 50, 40))

GUI.CloseButton.MouseButton1Click:Connect(function()
    stopScanning()
    GUI.MainFrame:Destroy()
end)

GUI.CloseButton.MouseEnter:Connect(function()
    GUI.CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 70)
end)
GUI.CloseButton.MouseLeave:Connect(function()
    GUI.CloseButton.BackgroundColor3 = THEME.primaryRed
end)

local minimized = false
GUI.MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        GUI.Frame.Size = UDim2.new(0, 120, 0, 38)
        GUI.MinimizeButton.Text = "+"
        GUI.Content.Visible = false
        GUI.TitleText.Position = UDim2.new(0.5, -50, 0, 0)
        GUI.TitleText.TextXAlignment = Enum.TextXAlignment.Center
    else
        GUI.Frame.Size = UDim2.new(0, 380, 0, 480)
        GUI.MinimizeButton.Text = "−"
        GUI.Content.Visible = true
        GUI.TitleText.Position = UDim2.new(0.15, 0, 0, 0)
        GUI.TitleText.TextXAlignment = Enum.TextXAlignment.Left
    end
end)

GUI.MinimizeButton.MouseEnter:Connect(function()
    GUI.MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
end)
GUI.MinimizeButton.MouseLeave:Connect(function()
    GUI.MinimizeButton.BackgroundColor3 = THEME.primaryYellow
end)

local function onKeyPress(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.X then
        if isScanning then
            stopScanning()
        else
            startScanning()
        end
    end
end
UserInputService.InputBegan:Connect(onKeyPress)

-- ===== DRAGGING SYSTEM =====
local frame = GUI.Frame
local isDragging = false
local dragStartPos = nil
local frameStartPos = nil

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = input.Position
        frameStartPos = frame.Position
    end
end)

frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        dragStartPos = nil
    end
end)

RunService.Heartbeat:Connect(function()
    if isDragging and dragStartPos then
        local mousePos = UserInputService:GetMouseLocation()
        local delta = mousePos - dragStartPos
        frame.Position = UDim2.new(
            0, frameStartPos.X.Offset + delta.X,
            0, frameStartPos.Y.Offset + delta.Y
        )
    end
end)

-- ===== ANIMATION =====
frame.Size = UDim2.new(0, 0, 0, 0)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
task.delay(0.1, function()
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 380, 0, 480),
        Position = UDim2.new(0.5, -190, 0.5, -240)
    }):Play()
end)

-- ===== CLEANUP =====
local function cleanup()
    if scanConnection then
        scanConnection:Disconnect()
        scanConnection = nil
    end
    if GUI and GUI.MainFrame then
        GUI.MainFrame:Destroy()
    end
end

player:GetPropertyChangedSignal("Character"):Connect(function()
    if not player.Character then
        cleanup()
    end
end)

print("🔍 Object Scanner loaded successfully!")
