-- ============================================
-- PATTERN CALCULATOR (GAYA REFERENSI - FIXED)
-- Pola: aa=1e21, bb=1e24, ..., zz=1e96
--        aaa=1e99, ..., zzz=1e174, aaaa=1e177, ...
-- Rumus: k = panjang huruf (min 2, semua huruf sama)
--        i = index huruf (a=0 ... z=25)
--        n = 26*(k-2) + 1 + i
--        exponent = 18 + 3*n
-- ============================================

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Hapus GUI lama jika ada
local existing = gui:FindFirstChild("PatternCalculator")
if existing then
    existing:Destroy()
    task.wait(0.05)
end

------ MAIN SCREENGUI ------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PatternCalculator"
screenGui.Parent = gui
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999

------ MAIN FRAME ------
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 300)
frame.Position = UDim2.new(0.5, -120, 0.5, -150)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Draggable = true
frame.Active = true

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

------ TITLE BAR ------
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 25)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)  -- FIXED: UDim.new(0, 8) bukan UDim.new(0, 8, 0, 0)
titleCorner.Parent = titleBar

-- Title Text
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0.1, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Text = "🧮 PATTERN"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -25, 0, 0)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

-- Minimize Button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 25, 0, 25)
minBtn.Position = UDim2.new(1, -50, 0, 0)
minBtn.Text = "-"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minBtn

------ CONTENT FRAME ------
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -10, 1, -35)
content.Position = UDim2.new(0, 5, 0, 30)
content.BackgroundTransparency = 1
content.Parent = frame

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 18)
subtitle.Position = UDim2.new(0, 0, 0, 0)
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 10
subtitle.Text = "[huruf]  aaa, bbbb, zzzzz"
subtitle.TextXAlignment = Enum.TextXAlignment.Center
subtitle.Parent = content

-- Input Box
local input = Instance.new("TextBox")
input.Size = UDim2.new(1, 0, 0, 32)
input.Position = UDim2.new(0, 0, 0, 22)
input.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.Font = Enum.Font.Gotham
input.TextSize = 16
input.PlaceholderText = "contoh: aaaaa"
input.Text = ""
input.ClearTextOnFocus = false
input.Parent = content

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 4)
inputCorner.Parent = input

-- Button Row
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, 0, 0, 30)
btnRow.Position = UDim2.new(0, 0, 0, 60)
btnRow.BackgroundTransparency = 1
btnRow.Parent = content

-- Hitung Button
local button = Instance.new("TextButton")
button.Size = UDim2.new(0.48, 0, 1, 0)
button.Position = UDim2.new(0, 0, 0, 0)
button.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 12
button.Text = "HITUNG"
button.Parent = btnRow

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = button

-- Clear Button
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.48, 0, 1, 0)
clearBtn.Position = UDim2.new(0.52, 0, 0, 0)
clearBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 12
clearBtn.Text = "CLEAR"
clearBtn.Parent = btnRow

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 6)
clearCorner.Parent = clearBtn

-- Result Frame
local resultFrame = Instance.new("Frame")
resultFrame.Size = UDim2.new(1, 0, 0, 45)
resultFrame.Position = UDim2.new(0, 0, 0, 96)
resultFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
resultFrame.BorderSizePixel = 1
resultFrame.BorderColor3 = Color3.fromRGB(60, 60, 70)
resultFrame.Parent = content

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 4)
resultCorner.Parent = resultFrame

-- Result Label
local result = Instance.new("TextLabel")
result.Size = UDim2.new(1, -8, 1, -4)
result.Position = UDim2.new(0, 4, 0, 2)
result.BackgroundTransparency = 1
result.TextColor3 = Color3.fromRGB(100, 255, 150)
result.Font = Enum.Font.GothamBold
result.TextSize = 14
result.Text = ""
result.TextWrapped = true
result.TextXAlignment = Enum.TextXAlignment.Left
result.Parent = resultFrame

-- Status Label
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 16)
status.Position = UDim2.new(0, 0, 0, 148)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(180, 180, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 10
status.Text = "📊 Masukkan huruf berulang"
status.TextXAlignment = Enum.TextXAlignment.Center
status.Parent = content

-- Info Label
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 14)
info.Position = UDim2.new(0, 0, 0, 166)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(120, 120, 140)
info.Font = Enum.Font.Gotham
info.TextSize = 9
info.Text = "Enter = Hitung"
info.TextXAlignment = Enum.TextXAlignment.Center
info.Parent = content

------ CORE LOGIC ------
local function hitungPattern(word)
    word = string.lower(word)
    local len = #word
    if len < 2 then
        return nil, "Minimal 2 huruf"
    end
    
    local firstChar = string.sub(word, 1, 1)
    if not firstChar:match("%a") then
        return nil, "Harus huruf a-z"
    end
    
    for c in word:gmatch(".") do
        if c ~= firstChar or not c:match("%a") then
            return nil, "Huruf harus sama semua (contoh: aaaaa)"
        end
    end
    
    local i = string.byte(firstChar) - 97
    -- DEAD CODE DIHAPUS: if i < 0 or i > 25 then ... end
    
    local k = len
    local n = 26 * (k - 2) + 1 + i
    local exponent = 18 + 3 * n
    return exponent, n
end

local function updateResult(text, isSuccess)
    if isSuccess then
        result.Text = text
        result.TextColor3 = Color3.fromRGB(100, 255, 100)
        status.Text = "✅ " .. text
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        result.Text = "⚠️ " .. text
        result.TextColor3 = Color3.fromRGB(255, 100, 100)
        status.Text = "❌ " .. text
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

local function clearAll()
    input.Text = ""
    result.Text = ""
    result.TextColor3 = Color3.fromRGB(100, 255, 150)
    status.Text = "📊 Masukkan huruf berulang"
    status.TextColor3 = Color3.fromRGB(180, 180, 200)
end

local function hitung()
    local text = input.Text
    if text == "" then
        updateResult("Masukkan huruf!", false)
        return
    end
    
    local exponent, nOrErr = hitungPattern(text)
    if exponent then
        updateResult(string.format("1e+%d  (n=%d)", exponent, nOrErr), true)
    else
        updateResult(nOrErr, false)
    end
end

------ EVENT HANDLERS ------
button.MouseButton1Click:Connect(hitung)

clearBtn.MouseButton1Click:Connect(clearAll)

-- Fokus hilang dengan Enter → panggil hitung()
input.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        hitung()
    end
end)

input.Focused:Connect(function()
    if input.Text == "" then
        input.PlaceholderText = "contoh: aaaaa"
    end
end)

-- Close button
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Minimize button
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        frame.Size = UDim2.new(0, 120, 0, 25)
        minBtn.Text = "+"
        content.Visible = false
        subtitle.Visible = false
        status.Visible = false
        info.Visible = false
    else
        frame.Size = UDim2.new(0, 240, 0, 300)
        minBtn.Text = "-"
        content.Visible = true
        subtitle.Visible = true
        status.Visible = true
        info.Visible = true
    end
end)

-- DOUBLE-TRIGGER ENTER DIHAPUS: tidak ada InputBegan untuk Enter
-- Cukup andalkan input.FocusLost yang sudah ada

print("✅ Pattern Calculator (Gaya Referensi - Fixed) Loaded!")
print("📝 Format: huruf berulang (aa, bbb, zzzz, ...)")
