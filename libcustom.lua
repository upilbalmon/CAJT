--// ============================================
--// UI LIBRARY (CAJT UI) - BERBASIS REFERENSI AutoFarm.lua
--// ============================================
local CAJTUI = {}
CAJTUI.__index = CAJTUI

--// Variabel global UI
local UIInstances = {
    Windows = {},
    Tabs = {},
    Sections = {},
    Components = {},
}

--// ============================================
--// UTILITY FUNCTIONS
--// ============================================
local function CreateCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = instance
    return corner
end

local function CreateStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(40, 40, 45)
    stroke.Thickness = thickness or 1
    stroke.Parent = instance
    return stroke
end

--// ============================================
--// THEME (TERINSPIRASI DARI AutoFarm.lua)
--// ============================================
local Theme = {
    Background = Color3.fromRGB(25, 25, 25),
    Surface = Color3.fromRGB(30, 30, 35),
    SurfaceLight = Color3.fromRGB(40, 40, 45),
    Primary = Color3.fromRGB(40, 180, 40),
    PrimaryHover = Color3.fromRGB(60, 220, 60),
    PrimaryActive = Color3.fromRGB(30, 160, 30),
    Danger = Color3.fromRGB(180, 40, 40),
    DangerHover = Color3.fromRGB(220, 60, 60),
    Text = Color3.fromRGB(220, 220, 220),
    TextSecondary = Color3.fromRGB(180, 180, 200),
    TextMuted = Color3.fromRGB(150, 150, 150),
    Border = Color3.fromRGB(50, 50, 55),
    Red = Color3.fromRGB(255, 100, 100),
    Green = Color3.fromRGB(100, 200, 100),
    Yellow = Color3.fromRGB(255, 165, 0),
    Blue = Color3.fromRGB(40, 80, 180),
    BlueHover = Color3.fromRGB(60, 120, 220),
}

--// ============================================
--// WINDOW (TERINSPIRASI DARI AutoFarm.lua)
--// ============================================
function CAJTUI:CreateWindow(config)
    local gui = Instance.new("ScreenGui")
    gui.Name = "CAJTUI_Main"
    gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999

    -- Main Frame (seperti di AutoFarm.lua)
    local frame = Instance.new("Frame")
    frame.Size = config.Size or UDim2.new(0, 420, 0, 400)
    frame.Position = config.Position or UDim2.new(0.5, -210, 0.5, -200)
    frame.BackgroundColor3 = Theme.Background
    frame.BackgroundTransparency = config.Transparency or 0.2
    frame.BorderSizePixel = 0
    frame.Parent = gui
    frame.Draggable = true
    frame.Active = true
    frame.ClipsDescendants = true

    CreateCorner(frame, 6)

    -- Title Bar (seperti di AutoFarm.lua)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 25)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.Parent = frame
    CreateCorner(titleBar, 6)

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.new(0, 5, 0, 0)
    title.Text = config.Title or "CAJT UI"
    title.TextColor3 = Theme.Text
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSans
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Minimize Button (seperti di AutoFarm.lua)
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 25, 0, 25)
    minBtn.Position = UDim2.new(1, -50, 0, 0)
    minBtn.Text = "−"
    minBtn.Font = Enum.Font.SourceSans
    minBtn.TextSize = 16
    minBtn.TextColor3 = Theme.Text
    minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    minBtn.BackgroundTransparency = 0.3
    minBtn.BorderSizePixel = 0
    minBtn.Parent = titleBar
    CreateCorner(minBtn, 4)

    -- Close Button (seperti di AutoFarm.lua)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -25, 0, 0)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.SourceSans
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Theme.Text
    closeBtn.BackgroundColor3 = Theme.Danger
    closeBtn.BackgroundTransparency = 0.3
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    CreateCorner(closeBtn, 4)

    -- Hover effects
    minBtn.MouseEnter:Connect(function()
        minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    minBtn.MouseLeave:Connect(function()
        minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)

    closeBtn.MouseEnter:Connect(function()
        closeBtn.BackgroundColor3 = Theme.DangerHover
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.BackgroundColor3 = Theme.Danger
    end)

    -- Minimize function
    local minimized = false
    local originalSize = frame.Size
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, 25)
        else
            frame.Size = originalSize
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    -- Tab Navigation Bar (TAMBAHAN: TAB)
    local navBar = Instance.new("Frame")
    navBar.Size = UDim2.new(1, 0, 0, 30)
    navBar.Position = UDim2.new(0, 0, 0, 25)
    navBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    navBar.BackgroundTransparency = 0.3
    navBar.BorderSizePixel = 0
    navBar.Parent = frame

    -- Tab Container
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(1, -10, 1, 0)
    tabContainer.Position = UDim2.new(0, 5, 0, 0)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 3
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabContainer.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
    tabContainer.ScrollingDirection = Enum.ScrollingDirection.X
    tabContainer.Parent = navBar

    -- UIListLayout untuk tab button
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabContainer

    -- Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, 0, 1, -55)
    contentContainer.Position = UDim2.new(0, 0, 0, 55)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = frame

    -- Mini Button (untuk restore setelah minimize, seperti di AutoFarm.lua)
    local miniBtn = Instance.new("TextButton")
    miniBtn.Size = UDim2.new(0, 40, 0, 40)
    miniBtn.Position = UDim2.new(1, -50, 1, -50)
    miniBtn.BackgroundColor3 = Theme.Primary
    miniBtn.Text = "⤴"
    miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    miniBtn.Font = Enum.Font.SourceSans
    miniBtn.TextSize = 20
    miniBtn.Visible = false
    miniBtn.Parent = gui
    CreateCorner(miniBtn, 20)

    miniBtn.MouseEnter:Connect(function()
        miniBtn.BackgroundColor3 = Theme.PrimaryHover
    end)
    miniBtn.MouseLeave:Connect(function()
        miniBtn.BackgroundColor3 = Theme.Primary
    end)
    miniBtn.MouseButton1Click:Connect(function()
        minimized = false
        miniBtn.Visible = false
        frame.Visible = true
        frame.Size = originalSize
    end)

    -- Store window data
    local windowData = {
        Gui = gui,
        Frame = frame,
        MiniButton = miniBtn,
        NavBar = navBar,
        TabContainer = tabContainer,
        ContentContainer = contentContainer,
        Tabs = {},
        ActiveTab = nil,
        OriginalSize = originalSize,
        Minimized = minimized,
    }

    table.insert(UIInstances.Windows, windowData)

    -- Return window object
    local window = setmetatable({
        _data = windowData,
        _gui = gui,
        _frame = frame,
        _content = contentContainer,
        _tabs = {},
    }, {
        __index = CAJTUI,
    })

    return window
end

--// ============================================
--// TAB
--// ============================================
function CAJTUI:CreateTab(config)
    local window = self
    local data = window._data

    -- Create Tab Button
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 100, 1, -4)
    tabBtn.Position = UDim2.new(0, 0, 0, 2)
    tabBtn.Text = config.Title or "Tab"
    tabBtn.TextColor3 = Theme.TextSecondary
    tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabBtn.BackgroundTransparency = 0.5
    tabBtn.BorderSizePixel = 0
    tabBtn.Font = Enum.Font.SourceSans
    tabBtn.TextSize = 12
    tabBtn.Parent = data.TabContainer
    CreateCorner(tabBtn, 4)

    -- Tab Content Panel
    local contentPanel = Instance.new("ScrollingFrame")
    contentPanel.Size = UDim2.new(1, -10, 1, -5)
    contentPanel.Position = UDim2.new(0, 5, 0, 2)
    contentPanel.BackgroundTransparency = 1
    contentPanel.BorderSizePixel = 0
    contentPanel.ScrollBarThickness = 4
    contentPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentPanel.ScrollingDirection = Enum.ScrollingDirection.Y
    contentPanel.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
    contentPanel.Visible = false
    contentPanel.Parent = data.ContentContainer

    -- Hover effect
    tabBtn.MouseEnter:Connect(function()
        if data.ActiveTab ~= tabBtn then
            tabBtn.BackgroundTransparency = 0.3
            tabBtn.TextColor3 = Theme.Text
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if data.ActiveTab ~= tabBtn then
            tabBtn.BackgroundTransparency = 0.5
            tabBtn.TextColor3 = Theme.TextSecondary
        end
    end)

    -- Tab click
    tabBtn.MouseButton1Click:Connect(function()
        -- Deactivate all tabs
        for _, btn in pairs(data.TabContainer:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundTransparency = 0.5
                btn.TextColor3 = Theme.TextSecondary
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            end
        end
        for _, panel in pairs(data.ContentContainer:GetChildren()) do
            if panel:IsA("ScrollingFrame") then
                panel.Visible = false
            end
        end

        -- Activate this tab
        tabBtn.BackgroundTransparency = 0.1
        tabBtn.TextColor3 = Theme.Primary
        tabBtn.BackgroundColor3 = Theme.Primary
        contentPanel.Visible = true
        data.ActiveTab = tabBtn
    end)

    -- Store tab data
    local tabData = {
        Button = tabBtn,
        Panel = contentPanel,
        Sections = {},
        Components = {},
    }
    table.insert(data.Tabs, tabData)
    table.insert(window._tabs, tabData)

    -- If first tab, activate it
    if #data.Tabs == 1 then
        for _, btn in pairs(data.TabContainer:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundTransparency = 0.5
                btn.TextColor3 = Theme.TextSecondary
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            end
        end
        for _, panel in pairs(data.ContentContainer:GetChildren()) do
            if panel:IsA("ScrollingFrame") then
                panel.Visible = false
            end
        end
        tabBtn.BackgroundTransparency = 0.1
        tabBtn.TextColor3 = Theme.Primary
        tabBtn.BackgroundColor3 = Theme.Primary
        contentPanel.Visible = true
        data.ActiveTab = tabBtn
    end

    -- Return tab object
    return setmetatable({
        _data = tabData,
        _panel = contentPanel,
        _window = window,
    }, {
        __index = CAJTUI,
    })
end

--// ============================================
--// SECTION
--// ============================================
function CAJTUI:CreateSection(config)
    local tab = self
    local panel = tab._panel

    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, config.Height or 100)
    section.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    section.BackgroundTransparency = 0.3
    section.BorderSizePixel = 0
    section.Parent = panel
    CreateCorner(section, 4)

    -- Section Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 20)
    title.Position = UDim2.new(0, 5, 0, 2)
    title.BackgroundTransparency = 1
    title.Text = config.Title or "Section"
    title.TextColor3 = Theme.TextSecondary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.SourceSans
    title.TextSize = 12
    title.Parent = section

    -- Section Content Container
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -25)
    content.Position = UDim2.new(0, 0, 0, 25)
    content.BackgroundTransparency = 1
    content.Parent = section

    -- Section Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -10, 0, 1)
    divider.Position = UDim2.new(0, 5, 0, 22)
    divider.BackgroundColor3 = Theme.Border
    divider.BorderSizePixel = 0
    divider.Parent = section

    local sectionData = {
        Section = section,
        Content = content,
        Components = {},
    }
    table.insert(tab._data.Sections, sectionData)

    return setmetatable({
        _data = sectionData,
        _content = content,
        _section = section,
        _tab = tab,
    }, {
        __index = CAJTUI,
    })
end

--// ============================================
--// BUTTON (STYLE DARI AutoFarm.lua)
--// ============================================
function CAJTUI:CreateButton(config)
    local section = self
    local content = section._content

    local height = config.Height or 28
    local yOffset = #section._data.Components * (height + 6) + 5

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, height)
    btn.Position = UDim2.new(0, 5, 0, yOffset)
    btn.Text = config.Name or "Button"
    
    -- Style sesuai AutoFarm.lua
    if config.Variant == "Primary" then
        btn.BackgroundColor3 = Theme.Primary
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif config.Variant == "Danger" then
        btn.BackgroundColor3 = Theme.Danger
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif config.Variant == "Blue" then
        btn.BackgroundColor3 = Theme.Blue
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        btn.TextColor3 = Theme.Text
    end
    
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 11
    btn.Parent = content
    CreateCorner(btn, 4)

    -- Hover effect (seperti di AutoFarm.lua)
    btn.MouseEnter:Connect(function()
        if config.Variant == "Primary" then
            btn.BackgroundColor3 = Theme.PrimaryHover
        elseif config.Variant == "Danger" then
            btn.BackgroundColor3 = Theme.DangerHover
        elseif config.Variant == "Blue" then
            btn.BackgroundColor3 = Theme.BlueHover
        else
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        btn.BackgroundTransparency = 0.2
    end)
    btn.MouseLeave:Connect(function()
        if config.Variant == "Primary" then
            btn.BackgroundColor3 = Theme.Primary
        elseif config.Variant == "Danger" then
            btn.BackgroundColor3 = Theme.Danger
        elseif config.Variant == "Blue" then
            btn.BackgroundColor3 = Theme.Blue
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
        btn.BackgroundTransparency = 0.3
    end)

    btn.MouseButton1Click:Connect(function()
        if config.Callback then
            task.spawn(config.Callback)
        end
    end)

    table.insert(section._data.Components, btn)

    local totalHeight = #section._data.Components * (height + 6) + 10
    section._section.Size = UDim2.new(1, 0, 0, totalHeight)

    return btn
end

--// ============================================
--// INPUT (STYLE DARI AutoFarm.lua)
--// ============================================
function CAJTUI:CreateInput(config)
    local section = self
    local content = section._content

    local height = config.Height or 24
    local yOffset = #section._data.Components * (height + 30) + 5
    local label = nil

    if config.Title then
        label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 16)
        label.Position = UDim2.new(0, 5, 0, yOffset)
        label.BackgroundTransparency = 1
        label.Text = config.Title
        label.TextColor3 = Theme.TextSecondary
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.SourceSans
        label.TextSize = 11
        label.Parent = content
        table.insert(section._data.Components, label)
        yOffset = yOffset + 20
    end

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -10, 0, height)
    input.Position = UDim2.new(0, 5, 0, yOffset)
    input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    input.BackgroundTransparency = 0.3
    input.TextColor3 = Theme.Text
    input.PlaceholderColor3 = Theme.TextMuted
    input.BorderSizePixel = 0
    input.Font = Enum.Font.SourceSans
    input.TextSize = 11
    input.Text = config.Default or ""
    input.PlaceholderText = config.Placeholder or ""
    input.ClearTextOnFocus = false
    input.Selectable = true
    input.TextEditable = true
    input.MultiLine = false
    input.Parent = content
    CreateCorner(input, 4)

    -- Store value
    local value = input.Text

    input:GetPropertyChangedSignal("Text"):Connect(function()
        value = input.Text
        if config.Callback then
            task.spawn(function()
                config.Callback(value)
            end)
        end
    end)

    table.insert(section._data.Components, input)

    local totalHeight = #section._data.Components * (height + 30) + 10
    section._section.Size = UDim2.new(1, 0, 0, totalHeight)

    return {
        _input = input,
        Set = function(self, text)
            input.Text = text
            value = text
        end,
        GetValue = function(self)
            return value
        end,
    }
end

--// ============================================
--// TOGGLE (STYLE DARI AutoFarm.lua AutoDetectButton)
--// ============================================
function CAJTUI:CreateToggle(config)
    local section = self
    local content = section._content

    local height = 24
    local yOffset = #section._data.Components * (height + 6) + 5

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, height)
    container.Position = UDim2.new(0, 5, 0, yOffset)
    container.BackgroundTransparency = 1
    container.Parent = content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = config.Name or "Toggle"
    label.TextColor3 = Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 11
    label.Parent = container

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 50, 1, 0)
    toggle.Position = UDim2.new(1, -50, 0, 0)
    toggle.Text = config.Default and "ON" or "OFF"
    toggle.Font = Enum.Font.SourceSans
    toggle.TextSize = 10
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.BorderSizePixel = 0
    toggle.Parent = container
    CreateCorner(toggle, 4)

    local state = config.Default or false

    local function updateToggle()
        if state then
            toggle.BackgroundColor3 = Theme.Primary
            toggle.Text = "ON"
        else
            toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            toggle.Text = "OFF"
        end
    end
    updateToggle()

    toggle.MouseButton1Click:Connect(function()
        state = not state
        updateToggle()
        if config.Callback then
            task.spawn(function()
                config.Callback(state)
            end)
        end
    end)

    table.insert(section._data.Components, container)

    local totalHeight = #section._data.Components * (height + 6) + 10
    section._section.Size = UDim2.new(1, 0, 0, totalHeight)

    return {
        Set = function(self, newState)
            state = newState
            updateToggle()
        end,
        GetValue = function(self)
            return state
        end,
    }
end

--// ============================================
--// DROPDOWN
--// ============================================
function CAJTUI:CreateDropdown(config)
    local section = self
    local content = section._content

    local height = 24
    local yOffset = #section._data.Components * (height + 30) + 5

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 16)
    label.Position = UDim2.new(0, 5, 0, yOffset)
    label.BackgroundTransparency = 1
    label.Text = config.Name or "Dropdown"
    label.TextColor3 = Theme.TextSecondary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 11
    label.Parent = content
    table.insert(section._data.Components, label)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, height)
    btn.Position = UDim2.new(0, 5, 0, yOffset + 20)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BackgroundTransparency = 0.3
    btn.TextColor3 = Theme.Text
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 11
    btn.Text = config.Default or config.Options[1] or ""
    btn.Parent = content
    CreateCorner(btn, 4)

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -10, 0, 0)
    list.Position = UDim2.new(0, 5, 0, yOffset + 20 + height)
    list.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    list.BackgroundTransparency = 0.3
    list.BorderSizePixel = 0
    list.Visible = false
    list.ClipsDescendants = true
    list.Parent = content
    CreateCorner(list, 4)

    local listHeight = 0
    for i, option in ipairs(config.Options or {}) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 24)
        optBtn.Position = UDim2.new(0, 0, 0, (i-1) * 24)
        optBtn.Text = option
        optBtn.TextColor3 = Theme.Text
        optBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        optBtn.BackgroundTransparency = 0.1
        optBtn.BorderSizePixel = 0
        optBtn.Font = Enum.Font.SourceSans
        optBtn.TextSize = 11
        optBtn.Parent = list
        CreateCorner(optBtn, 3)

        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundTransparency = 0.3
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundTransparency = 0.1
        end)

        optBtn.MouseButton1Click:Connect(function()
            btn.Text = option
            list.Visible = false
            list.Size = UDim2.new(1, -10, 0, 0)
            if config.Callback then
                task.spawn(function()
                    config.Callback(option)
                end)
            end
        end)

        listHeight = listHeight + 24
    end

    list.Size = UDim2.new(1, -10, 0, listHeight)

    btn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        if list.Visible then
            list.Size = UDim2.new(1, -10, 0, listHeight)
        else
            list.Size = UDim2.new(1, -10, 0, 0)
        end
    end)

    table.insert(section._data.Components, btn)
    table.insert(section._data.Components, list)

    local totalHeight = #section._data.Components * (height + 30) + 10
    section._section.Size = UDim2.new(1, 0, 0, totalHeight)

    return {
        Set = function(self, value)
            btn.Text = value
        end,
        GetValue = function(self)
            return btn.Text
        end,
    }
end

--// ============================================
--// LABEL (STYLE DARI AutoFarm.lua StatusLabel)
--// ============================================
function CAJTUI:CreateLabel(config)
    local section = self
    local content = section._content

    local height = config.Height or 18
    local yOffset = #section._data.Components * (height + 4) + 5

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, height)
    label.Position = UDim2.new(0, 5, 0, yOffset)
    label.BackgroundTransparency = 1
    label.Text = config.Title or ""
    label.TextColor3 = config.Color == "Red" and Theme.Red or 
                       config.Color == "Green" and Theme.Green or
                       config.Color == "Yellow" and Theme.Yellow or
                       Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = config.Size or 11
    label.TextWrapped = true
    label.Parent = content

    table.insert(section._data.Components, label)

    local function updateHeight()
        local textSize = label.TextBounds.Y
        if textSize > height then
            label.Size = UDim2.new(1, -10, 0, textSize + 4)
        end
    end
    label:GetPropertyChangedSignal("Text"):Connect(updateHeight)
    task.wait(0.05)
    updateHeight()

    local totalHeight = 0
    for _, comp in pairs(section._data.Components) do
        if comp:IsA("TextLabel") and comp.Parent == content then
            totalHeight = totalHeight + comp.Size.Y.Offset + 4
        elseif comp:IsA("Frame") and comp.Parent == content then
            totalHeight = totalHeight + comp.Size.Y.Offset + 4
        end
    end
    section._section.Size = UDim2.new(1, 0, 0, totalHeight + 10)

    return {
        Set = function(self, text)
            label.Text = text
            task.wait(0.05)
            updateHeight()
        end,
        SetColor = function(self, color)
            label.TextColor3 = color == "Red" and Theme.Red or 
                               color == "Green" and Theme.Green or
                               color == "Yellow" and Theme.Yellow or
                               Theme.Text
        end,
    }
end

--// ============================================
--// DIVIDER
--// ============================================
function CAJTUI:CreateDivider(config)
    local section = self
    local content = section._content

    local yOffset = #section._data.Components * (20 + 4) + 5

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -20, 0, 1)
    divider.Position = UDim2.new(0, 10, 0, yOffset)
    divider.BackgroundColor3 = Theme.Border
    divider.BorderSizePixel = 0
    divider.Parent = content

    table.insert(section._data.Components, divider)

    local totalHeight = #section._data.Components * 25 + 10
    section._section.Size = UDim2.new(1, 0, 0, totalHeight)
end

--// ============================================
--// NOTIFICATION (STYLE DARI AutoFarm.lua)
--// ============================================
function CAJTUI:Notify(config)
    local gui = Instance.new("ScreenGui")
    gui.Name = "CAJTUI_Notification"
    gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 45)
    frame.Position = UDim2.new(1, -315, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = gui
    CreateCorner(frame, 6)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -15, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 3)
    title.BackgroundTransparency = 1
    title.Text = config.Title or "Notification"
    title.TextColor3 = Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 12
    title.Parent = frame

    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -15, 0, 18)
    content.Position = UDim2.new(0, 10, 0, 23)
    content.BackgroundTransparency = 1
    content.Text = config.Content or ""
    content.TextColor3 = Theme.TextSecondary
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.Font = Enum.Font.SourceSans
    content.TextSize = 10
    content.Parent = frame

    task.wait(config.Duration or 3)
    frame:TweenPosition(UDim2.new(1, -315, 0, -60), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
    task.wait(0.4)
    gui:Destroy()
end

--// ============================================
--// EXPORT
--// ============================================
return CAJTUI
