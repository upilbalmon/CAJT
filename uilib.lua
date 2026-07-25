--// ============================================
--// UI LIBRARY SEDERHANA (CAJT UI)
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

local function CreateShadow(instance, size, color)
    local shadow = Instance.new("UIShadow")
    shadow.Size = size or 8
    shadow.Color = color or Color3.fromRGB(0, 0, 0)
    shadow.Parent = instance
    return shadow
end

--// ============================================
--// THEME
--// ============================================
local Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    Surface = Color3.fromRGB(30, 30, 35),
    SurfaceLight = Color3.fromRGB(40, 40, 45),
    Primary = Color3.fromRGB(0, 150, 255),
    PrimaryHover = Color3.fromRGB(40, 180, 255),
    PrimaryActive = Color3.fromRGB(0, 120, 220),
    Success = Color3.fromRGB(40, 200, 80),
    Danger = Color3.fromRGB(220, 50, 50),
    Warning = Color3.fromRGB(255, 180, 0),
    Text = Color3.fromRGB(220, 220, 220),
    TextSecondary = Color3.fromRGB(160, 160, 170),
    TextMuted = Color3.fromRGB(100, 100, 110),
    Border = Color3.fromRGB(50, 50, 55),
    Shadow = Color3.fromRGB(0, 0, 0),
}

--// ============================================
--// WINDOW
--// ============================================
function CAJTUI:CreateWindow(config)
    local gui = Instance.new("ScreenGui")
    gui.Name = "CAJTUI_Main"
    gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true

    -- Main Frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 520, 0, 480)
    frame.Position = UDim2.new(0.5, -260, 0.5, -240)
    frame.BackgroundColor3 = Theme.Background
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = gui
    frame.Draggable = true
    frame.Active = true
    frame.ClipsDescendants = true
    
    CreateCorner(frame, 10)
    CreateStroke(frame, Theme.Border, 1)

    -- Shadow
    local shadow = Instance.new("UIShadow")
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Parent = frame

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = Theme.Surface
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.Parent = frame
    CreateCorner(titleBar, 10)

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = config.Title or "CAJT UI"
    title.TextColor3 = Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = titleBar

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 2.5)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.Text
    closeBtn.BackgroundColor3 = Theme.Danger
    closeBtn.BackgroundTransparency = 0.3
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = titleBar
    CreateCorner(closeBtn, 6)
    
    closeBtn.MouseEnter:Connect(function()
        closeBtn.BackgroundTransparency = 0.1
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.BackgroundTransparency = 0.3
    end)
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    -- Minimize Button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 30, 0, 30)
    minBtn.Position = UDim2.new(1, -70, 0, 2.5)
    minBtn.Text = "−"
    minBtn.TextColor3 = Theme.Text
    minBtn.BackgroundColor3 = Theme.SurfaceLight
    minBtn.BackgroundTransparency = 0.3
    minBtn.BorderSizePixel = 0
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 18
    minBtn.Parent = titleBar
    CreateCorner(minBtn, 6)
    
    local minimized = false
    minBtn.MouseEnter:Connect(function()
        minBtn.BackgroundTransparency = 0.1
    end)
    minBtn.MouseLeave:Connect(function()
        minBtn.BackgroundTransparency = 0.3
    end)
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            frame.Size = UDim2.new(0, 520, 0, 35)
        else
            frame.Size = UDim2.new(0, 520, 0, 480)
        end
    end)

    -- Tab Navigation Bar
    local navBar = Instance.new("Frame")
    navBar.Size = UDim2.new(1, 0, 0, 40)
    navBar.Position = UDim2.new(0, 0, 0, 35)
    navBar.BackgroundColor3 = Theme.Surface
    navBar.BackgroundTransparency = 0.2
    navBar.BorderSizePixel = 0
    navBar.Parent = frame

    -- Tab Container (Scrolling untuk banyak tab)
    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(1, -10, 1, 0)
    tabContainer.Position = UDim2.new(0, 5, 0, 0)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.ScrollBarThickness = 3
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabContainer.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
    tabContainer.Parent = navBar

    -- Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, 0, 1, -75)
    contentContainer.Position = UDim2.new(0, 0, 0, 75)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = frame

    -- Store window data
    local windowData = {
        Gui = gui,
        Frame = frame,
        NavBar = navBar,
        TabContainer = tabContainer,
        ContentContainer = contentContainer,
        Tabs = {},
        ActiveTab = nil,
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
    tabBtn.Size = UDim2.new(0, 100, 1, -6)
    tabBtn.Position = UDim2.new(0, 0, 0, 3)
    tabBtn.Text = config.Title or "Tab"
    tabBtn.TextColor3 = Theme.TextSecondary
    tabBtn.BackgroundColor3 = Theme.Surface
    tabBtn.BackgroundTransparency = 0.5
    tabBtn.BorderSizePixel = 0
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.TextSize = 13
    tabBtn.Parent = data.TabContainer
    CreateCorner(tabBtn, 6)

    -- Tab Content Panel
    local contentPanel = Instance.new("ScrollingFrame")
    contentPanel.Size = UDim2.new(1, -20, 1, -10)
    contentPanel.Position = UDim2.new(0, 10, 0, 5)
    contentPanel.BackgroundTransparency = 1
    contentPanel.BorderSizePixel = 0
    contentPanel.ScrollBarThickness = 4
    contentPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
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

    -- Tab button click
    tabBtn.MouseButton1Click:Connect(function()
        -- Deactivate all tabs
        for _, btn in pairs(data.TabContainer:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundTransparency = 0.5
                btn.TextColor3 = Theme.TextSecondary
                btn.BackgroundColor3 = Theme.Surface
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
        tabBtn.BackgroundColor3 = Theme.SurfaceLight
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
        tabBtn.MouseButton1Click:Fire()
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

    -- Section container
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, config.Height or 0)
    section.BackgroundColor3 = Theme.Surface
    section.BackgroundTransparency = 0.1
    section.BorderSizePixel = 0
    section.Parent = panel
    CreateCorner(section, 8)

    -- Section Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 25)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = config.Title or "Section"
    title.TextColor3 = Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = section

    -- Section Content Container
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -35)
    content.Position = UDim2.new(0, 0, 0, 35)
    content.BackgroundTransparency = 1
    content.Parent = section

    -- Section Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -20, 0, 1)
    divider.Position = UDim2.new(0, 10, 0, 32)
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
--// BUTTON
--// ============================================
function CAJTUI:CreateButton(config)
    local section = self
    local content = section._content

    -- Auto adjust height
    local height = config.Height or 32
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, height)
    btn.Position = UDim2.new(0, 10, 0, #section._data.Components * (height + 6) + 5)
    btn.Text = config.Name or "Button"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = config.Variant == "Danger" and Theme.Danger or Theme.Primary
    btn.BackgroundTransparency = 0.1
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = content
    CreateCorner(btn, 6)

    -- Hover
    btn.MouseEnter:Connect(function()
        btn.BackgroundTransparency = 0.2
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundTransparency = 0.1
    end)

    -- Click
    btn.MouseButton1Click:Connect(function()
        if config.Callback then
            task.spawn(config.Callback)
        end
    end)

    table.insert(section._data.Components, btn)
    
    -- Update section height
    local totalHeight = #section._data.Components * (height + 6) + 15
    section._section.Size = UDim2.new(1, 0, 0, totalHeight)

    return btn
end

--// ============================================
--// INPUT
--// ============================================
function CAJTUI:CreateInput(config)
    local section = self
    local content = section._content

    local height = config.Height or 28
    local label = nil
    
    -- Label jika ada
    if config.Title then
        label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 18)
        label.Position = UDim2.new(0, 10, 0, #section._data.Components * (height + 30) + 5)
        label.BackgroundTransparency = 1
        label.Text = config.Title
        label.TextColor3 = Theme.TextSecondary
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.Parent = content
        table.insert(section._data.Components, label)
    end

    local yOffset = #section._data.Components * (height + 30) + 5
    if label then yOffset = yOffset + 20 end
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 0, height)
    input.Position = UDim2.new(0, 10, 0, yOffset)
    input.BackgroundColor3 = Theme.SurfaceLight
    input.BackgroundTransparency = 0.3
    input.TextColor3 = Theme.Text
    input.PlaceholderColor3 = Theme.TextMuted
    input.BorderSizePixel = 0
    input.Font = Enum.Font.Gotham
    input.TextSize = 13
    input.Text = config.Default or ""
    input.PlaceholderText = config.Placeholder or ""
    input.Parent = content
    CreateCorner(input, 6)

    -- Update position for next component
    local totalHeight = #section._data.Components * (height + 30) + 40
    if label then totalHeight = totalHeight + 22 end
    section._section.Size = UDim2.new(1, 0, 0, totalHeight)

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

    -- Return input object with methods
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
--// TOGGLE
--// ============================================
function CAJTUI:CreateToggle(config)
    local section = self
    local content = section._content

    local height = 30
    local yOffset = #section._data.Components * (height + 6) + 5
    
    -- Container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, height)
    container.Position = UDim2.new(0, 10, 0, yOffset)
    container.BackgroundTransparency = 1
    container.Parent = content

    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = config.Name or "Toggle"
    label.TextColor3 = Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = container

    -- Toggle Button
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 44, 0, 24)
    toggle.Position = UDim2.new(1, -44, 0.5, -12)
    toggle.BackgroundColor3 = Theme.SurfaceLight
    toggle.BackgroundTransparency = 0.3
    toggle.BorderSizePixel = 0
    toggle.Parent = container
    CreateCorner(toggle, 12)

    -- Toggle Indicator
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 18, 0, 18)
    indicator.Position = UDim2.new(0, 3, 0.5, -9)
    indicator.BackgroundColor3 = Theme.TextMuted
    indicator.BorderSizePixel = 0
    indicator.Parent = toggle
    CreateCorner(indicator, 9)

    local state = config.Default or false
    
    local function updateToggle()
        if state then
            toggle.BackgroundColor3 = Theme.Primary
            indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            indicator.Position = UDim2.new(0, 23, 0.5, -9)
        else
            toggle.BackgroundColor3 = Theme.SurfaceLight
            indicator.BackgroundColor3 = Theme.TextMuted
            indicator.Position = UDim2.new(0, 3, 0.5, -9)
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
    local totalHeight = #section._data.Components * (height + 6) + 15
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

    local height = 30
    local yOffset = #section._data.Components * (height + 6) + 5
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 18)
    label.Position = UDim2.new(0, 10, 0, yOffset)
    label.BackgroundTransparency = 1
    label.Text = config.Name or "Dropdown"
    label.TextColor3 = Theme.TextSecondary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = content
    table.insert(section._data.Components, label)

    -- Dropdown Button
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, height)
    btn.Position = UDim2.new(0, 10, 0, yOffset + 22)
    btn.BackgroundColor3 = Theme.SurfaceLight
    btn.BackgroundTransparency = 0.3
    btn.TextColor3 = Theme.Text
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Text = config.Default or config.Options[1] or ""
    btn.Parent = content
    CreateCorner(btn, 6)

    -- Dropdown List
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -20, 0, 0)
    list.Position = UDim2.new(0, 10, 0, yOffset + 22 + height)
    list.BackgroundColor3 = Theme.Surface
    list.BackgroundTransparency = 0.1
    list.BorderSizePixel = 0
    list.Visible = false
    list.ClipsDescendants = true
    list.Parent = content
    CreateCorner(list, 6)

    local listHeight = 0
    local optionButtons = {}
    
    for i, option in ipairs(config.Options or {}) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 28)
        optBtn.Position = UDim2.new(0, 0, 0, (i-1) * 28)
        optBtn.Text = option
        optBtn.TextColor3 = Theme.Text
        optBtn.BackgroundColor3 = Theme.SurfaceLight
        optBtn.BackgroundTransparency = 0.1
        optBtn.BorderSizePixel = 0
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 12
        optBtn.Parent = list
        CreateCorner(optBtn, 4)
        
        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundTransparency = 0.3
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundTransparency = 0.1
        end)
        
        optBtn.MouseButton1Click:Connect(function()
            btn.Text = option
            list.Visible = false
            list.Size = UDim2.new(1, -20, 0, 0)
            if config.Callback then
                task.spawn(function()
                    config.Callback(option)
                end)
            end
        end)
        
        listHeight = listHeight + 28
        table.insert(optionButtons, optBtn)
    end
    
    list.Size = UDim2.new(1, -20, 0, listHeight)

    btn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        if list.Visible then
            list.Size = UDim2.new(1, -20, 0, listHeight)
        else
            list.Size = UDim2.new(1, -20, 0, 0)
        end
    end)

    table.insert(section._data.Components, btn)
    table.insert(section._data.Components, list)
    
    local totalHeight = #section._data.Components * (height + 40) + 30
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
--// LABEL / PARAGRAPH
--// ============================================
function CAJTUI:CreateLabel(config)
    local section = self
    local content = section._content

    local height = config.Height or 20
    local yOffset = #section._data.Components * (height + 4) + 5
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, height)
    label.Position = UDim2.new(0, 10, 0, yOffset)
    label.BackgroundTransparency = 1
    label.Text = config.Title or ""
    label.TextColor3 = config.Color == "Red" and Theme.Danger or 
                       config.Color == "Green" and Theme.Success or
                       config.Color == "Yellow" and Theme.Warning or
                       Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = config.Size or 13
    label.TextWrapped = true
    label.Parent = content

    -- Store the actual label for updates
    table.insert(section._data.Components, label)
    
    -- Auto height jika wrap
    local function updateHeight()
        local textSize = label.TextBounds.Y
        if textSize > height then
            label.Size = UDim2.new(1, -20, 0, textSize + 4)
        end
    end
    label:GetPropertyChangedSignal("Text"):Connect(updateHeight)
    task.wait(0.1)
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
            label.TextColor3 = color == "Red" and Theme.Danger or 
                               color == "Green" and Theme.Success or
                               color == "Yellow" and Theme.Warning or
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
    divider.Size = UDim2.new(1, -40, 0, 1)
    divider.Position = UDim2.new(0, 20, 0, yOffset)
    divider.BackgroundColor3 = Theme.Border
    divider.BorderSizePixel = 0
    divider.Parent = content

    table.insert(section._data.Components, divider)
    
    local totalHeight = #section._data.Components * 25 + 10
    section._section.Size = UDim2.new(1, 0, 0, totalHeight)
end

--// ============================================
--// NOTIFICATION
--// ============================================
function CAJTUI:Notify(config)
    local gui = Instance.new("ScreenGui")
    gui.Name = "CAJTUI_Notification"
    gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 50)
    frame.Position = UDim2.new(1, -335, 0, 10)
    frame.BackgroundColor3 = Theme.Surface
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = gui
    CreateCorner(frame, 8)
    CreateStroke(frame, Theme.Border, 1)

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = config.Title or "Notification"
    title.TextColor3 = Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = frame

    -- Content
    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -20, 0, 20)
    content.Position = UDim2.new(0, 10, 0, 24)
    content.BackgroundTransparency = 1
    content.Text = config.Content or ""
    content.TextColor3 = Theme.TextSecondary
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.Font = Enum.Font.Gotham
    content.TextSize = 11
    content.Parent = frame

    -- Auto dismiss
    task.wait(config.Duration or 3)
    frame:TweenPosition(UDim2.new(1, -335, 0, -60), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
    task.wait(0.4)
    gui:Destroy()
end

--// ============================================
--// EXPORT
--// ============================================
return CAJTUI
