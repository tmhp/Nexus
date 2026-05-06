--[[
    Nexus UILib — Reusable component factory
    Usage: local UI = loadfile("UILib.lua")()
]]

local TweenSrv = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local UI = {}
UI.__index = UI

-- Theme
UI.Theme = {
    bg       = Color3.fromRGB(12,12,18),
    sidebar  = Color3.fromRGB(16,16,24),
    topbar   = Color3.fromRGB(18,18,26),
    card     = Color3.fromRGB(24,24,34),
    cardHov  = Color3.fromRGB(30,30,42),
    accent   = Color3.fromRGB(130,80,255),
    accent2  = Color3.fromRGB(60,200,255),
    accent3  = Color3.fromRGB(255,90,180),
    text     = Color3.fromRGB(225,225,235),
    dim      = Color3.fromRGB(100,100,125),
    on       = Color3.fromRGB(60,220,130),
    off      = Color3.fromRGB(70,70,90),
    danger   = Color3.fromRGB(220,50,70),
    border   = Color3.fromRGB(36,36,50),
    glow     = Color3.fromRGB(130,80,255),
}

local C = UI.Theme
local FONT_B = Enum.Font.GothamBold
local FONT_S = Enum.Font.GothamSemibold
local FONT_R = Enum.Font.Gotham

function UI.tween(obj, props, t)
    TweenSrv:Create(obj, TweenInfo.new(t or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

function UI.corner(obj, r)
    local c = Instance.new("UICorner", obj)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

function UI.stroke(obj, col, th)
    local s = Instance.new("UIStroke", obj)
    s.Color = col or C.border
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

function UI.pad(obj, t, b, l, r)
    local p = Instance.new("UIPadding", obj)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or t or 0)
    p.PaddingLeft = UDim.new(0, l or t or 0)
    p.PaddingRight = UDim.new(0, r or t or 0)
    return p
end

function UI.gradient(obj, c1, c2, rot)
    local g = Instance.new("UIGradient", obj)
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 90
    return g
end

function UI.listLayout(obj, spacing, dir)
    local l = Instance.new("UIListLayout", obj)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, spacing or 5)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    return l
end

---------- NOTIFICATION SYSTEM ----------
local notifHolder = nil

function UI.initNotifications(parent)
    notifHolder = Instance.new("Frame", parent)
    notifHolder.Name = "Notifications"
    notifHolder.Size = UDim2.new(0, 260, 1, 0)
    notifHolder.Position = UDim2.new(1, -270, 0, 10)
    notifHolder.BackgroundTransparency = 1
    notifHolder.BorderSizePixel = 0
    UI.listLayout(notifHolder, 6)
end

function UI.notify(title, msg, duration)
    if not notifHolder then return end
    duration = duration or 3
    local n = Instance.new("Frame", notifHolder)
    n.Size = UDim2.new(1, 0, 0, 60)
    n.BackgroundColor3 = C.card
    n.BorderSizePixel = 0
    n.BackgroundTransparency = 1
    UI.corner(n, 8)
    UI.stroke(n, C.accent, 1)

    local accentBar = Instance.new("Frame", n)
    accentBar.Size = UDim2.new(0, 3, 0.7, 0)
    accentBar.Position = UDim2.new(0, 6, 0.15, 0)
    accentBar.BackgroundColor3 = C.accent
    accentBar.BorderSizePixel = 0
    UI.corner(accentBar, 2)

    local tLbl = Instance.new("TextLabel", n)
    tLbl.Size = UDim2.new(1, -24, 0, 20)
    tLbl.Position = UDim2.new(0, 16, 0, 8)
    tLbl.BackgroundTransparency = 1
    tLbl.Text = title
    tLbl.TextColor3 = C.accent
    tLbl.Font = FONT_B
    tLbl.TextSize = 13
    tLbl.TextXAlignment = Enum.TextXAlignment.Left

    local mLbl = Instance.new("TextLabel", n)
    mLbl.Size = UDim2.new(1, -24, 0, 20)
    mLbl.Position = UDim2.new(0, 16, 0, 28)
    mLbl.BackgroundTransparency = 1
    mLbl.Text = msg
    mLbl.TextColor3 = C.dim
    mLbl.Font = FONT_R
    mLbl.TextSize = 11
    mLbl.TextXAlignment = Enum.TextXAlignment.Left
    mLbl.TextWrapped = true

    -- Animate in
    UI.tween(n, {BackgroundTransparency = 0.05}, 0.3)
    task.delay(duration, function()
        UI.tween(n, {BackgroundTransparency = 1}, 0.4)
        task.delay(0.5, function() n:Destroy() end)
    end)
end

---------- SECTION HEADER ----------
function UI.section(parent, title, order)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -12, 0, 24)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = string.upper(title)
    lbl.TextColor3 = C.dim
    lbl.Font = FONT_B
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local line = Instance.new("Frame", f)
    line.Size = UDim2.new(1, -#title * 7, 0, 1)
    line.Position = UDim2.new(0, #title * 7 + 8, 0.5, 0)
    line.BackgroundColor3 = C.border
    line.BorderSizePixel = 0

    return f
end

---------- TOGGLE ----------
function UI.toggle(parent, name, default, callback, order)
    callback = callback or function() end
    local state = default or false

    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -12, 0, 34)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0
    UI.corner(f, 6)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = C.text
    lbl.Font = FONT_R
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local togBg = Instance.new("Frame", f)
    togBg.Size = UDim2.new(0, 38, 0, 20)
    togBg.Position = UDim2.new(1, -50, 0.5, -10)
    togBg.BackgroundColor3 = state and C.on or C.off
    togBg.BorderSizePixel = 0
    UI.corner(togBg, 10)

    local circ = Instance.new("Frame", togBg)
    circ.Size = UDim2.new(0, 16, 0, 16)
    circ.Position = UDim2.new(0, state and 20 or 2, 0, 2)
    circ.BackgroundColor3 = Color3.new(1, 1, 1)
    circ.BorderSizePixel = 0
    UI.corner(circ, 8)

    -- Hover
    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        state = not state
        UI.tween(togBg, {BackgroundColor3 = state and C.on or C.off}, 0.2)
        UI.tween(circ, {Position = UDim2.new(0, state and 20 or 2, 0, 2)}, 0.2)
        callback(state)
    end)

    return {frame = f, getState = function() return state end}
end

---------- SLIDER ----------
function UI.slider(parent, name, min, max, default, callback, order)
    callback = callback or function() end

    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -12, 0, 50)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0
    UI.corner(f, 6)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -60, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = C.text
    lbl.Font = FONT_R
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", f)
    valLbl.Size = UDim2.new(0, 46, 0, 22)
    valLbl.Position = UDim2.new(1, -56, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = C.accent
    valLbl.Font = FONT_S
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", f)
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 34)
    track.BackgroundColor3 = C.off
    track.BorderSizePixel = 0
    UI.corner(track, 3)

    local pct = math.clamp((default - min) / (max - min), 0, 1)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    UI.corner(fill, 3)
    UI.gradient(fill, C.accent, C.accent2, 0)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    UI.corner(knob, 7)

    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    local sliding = false
    local hitbox = Instance.new("TextButton", f)
    hitbox.Size = UDim2.new(1, 0, 0, 24)
    hitbox.Position = UDim2.new(0, 0, 0, 26)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -7, 0.5, -7)
            local val = math.floor(min + rel * (max - min))
            valLbl.Text = tostring(val)
            callback(val)
        end
    end)

    return f
end

---------- DROPDOWN ----------
function UI.dropdown(parent, name, options, default, callback, order)
    callback = callback or function() end
    local selected = default or options[1]
    local open = false

    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -12, 0, 34)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0
    f.ClipsDescendants = false
    f.ZIndex = 5
    UI.corner(f, 6)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = C.text
    lbl.Font = FONT_R
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 5

    local selBtn = Instance.new("TextButton", f)
    selBtn.Size = UDim2.new(0.48, 0, 0, 26)
    selBtn.Position = UDim2.new(0.5, 0, 0, 4)
    selBtn.BackgroundColor3 = C.sidebar
    selBtn.BorderSizePixel = 0
    selBtn.Text = "  " .. selected .. "  ▼"
    selBtn.TextColor3 = C.accent2
    selBtn.Font = FONT_R
    selBtn.TextSize = 11
    selBtn.ZIndex = 5
    UI.corner(selBtn, 4)
    UI.stroke(selBtn, C.border, 1)

    local dropList = Instance.new("Frame", f)
    dropList.Size = UDim2.new(0.48, 0, 0, 0)
    dropList.Position = UDim2.new(0.5, 0, 1, 2)
    dropList.BackgroundColor3 = C.sidebar
    dropList.BorderSizePixel = 0
    dropList.Visible = false
    dropList.ZIndex = 10
    dropList.ClipsDescendants = true
    UI.corner(dropList, 6)
    UI.stroke(dropList, C.border, 1)

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton", dropList)
        ob.Size = UDim2.new(1, -6, 0, 24)
        ob.Position = UDim2.new(0, 3, 0, (i - 1) * 26 + 2)
        ob.BackgroundColor3 = C.card
        ob.BackgroundTransparency = 0.5
        ob.BorderSizePixel = 0
        ob.Text = opt
        ob.TextColor3 = C.text
        ob.Font = FONT_R
        ob.TextSize = 11
        ob.ZIndex = 11
        UI.corner(ob, 4)
        ob.MouseEnter:Connect(function() UI.tween(ob, {BackgroundTransparency = 0}, 0.1) end)
        ob.MouseLeave:Connect(function() UI.tween(ob, {BackgroundTransparency = 0.5}, 0.1) end)
        ob.MouseButton1Click:Connect(function()
            selected = opt
            selBtn.Text = "  " .. opt .. "  ▼"
            open = false
            dropList.Visible = false
            UI.tween(dropList, {Size = UDim2.new(0.48, 0, 0, 0)}, 0.15)
            callback(opt)
        end)
    end

    selBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            dropList.Visible = true
            UI.tween(dropList, {Size = UDim2.new(0.48, 0, 0, math.min(#options * 26 + 4, 160))}, 0.2)
        else
            UI.tween(dropList, {Size = UDim2.new(0.48, 0, 0, 0)}, 0.15)
            task.delay(0.2, function() dropList.Visible = false end)
        end
    end)

    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    return {frame = f, getSelected = function() return selected end}
end

---------- BUTTON ----------
function UI.button(parent, name, callback, order)
    callback = callback or function() end

    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -12, 0, 32)
    btn.BackgroundColor3 = C.accent
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = FONT_S
    btn.TextSize = 13
    btn.LayoutOrder = order or 0
    UI.corner(btn, 6)
    UI.gradient(btn, C.accent, C.accent2, 0)

    btn.MouseEnter:Connect(function() UI.tween(btn, {BackgroundTransparency = 0.15}, 0.15) end)
    btn.MouseLeave:Connect(function() UI.tween(btn, {BackgroundTransparency = 0}, 0.15) end)
    btn.MouseButton1Click:Connect(function()
        UI.tween(btn, {Size = UDim2.new(1, -16, 0, 30)}, 0.08)
        task.delay(0.08, function() UI.tween(btn, {Size = UDim2.new(1, -12, 0, 32)}, 0.1) end)
        callback()
    end)

    return btn
end

---------- KEYBIND ----------
function UI.keybind(parent, name, defaultKey, callback, order)
    callback = callback or function() end
    local currentKey = defaultKey or Enum.KeyCode.Unknown
    local listening = false

    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -12, 0, 34)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0
    UI.corner(f, 6)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = C.text
    lbl.Font = FONT_R
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local kBtn = Instance.new("TextButton", f)
    kBtn.Size = UDim2.new(0, 60, 0, 24)
    kBtn.Position = UDim2.new(1, -72, 0.5, -12)
    kBtn.BackgroundColor3 = C.sidebar
    kBtn.BorderSizePixel = 0
    kBtn.Text = currentKey.Name
    kBtn.TextColor3 = C.accent
    kBtn.Font = FONT_S
    kBtn.TextSize = 11
    UI.corner(kBtn, 4)
    UI.stroke(kBtn, C.border, 1)

    kBtn.MouseButton1Click:Connect(function()
        listening = true
        kBtn.Text = "..."
        UI.tween(kBtn, {BackgroundColor3 = C.accent}, 0.15)
        kBtn.TextColor3 = Color3.new(1, 1, 1)
    end)

    UIS.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            currentKey = input.KeyCode
            kBtn.Text = currentKey.Name
            listening = false
            UI.tween(kBtn, {BackgroundColor3 = C.sidebar}, 0.15)
            kBtn.TextColor3 = C.accent
            callback(currentKey)
        end
    end)

    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    return f
end

---------- TEXTBOX ----------
function UI.textbox(parent, name, placeholder, callback, order)
    callback = callback or function() end

    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -12, 0, 34)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0
    UI.corner(f, 6)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.4, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = C.text
    lbl.Font = FONT_R
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", f)
    box.Size = UDim2.new(0.5, 0, 0, 24)
    box.Position = UDim2.new(0.47, 0, 0.5, -12)
    box.BackgroundColor3 = C.sidebar
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = placeholder or "..."
    box.PlaceholderColor3 = C.dim
    box.TextColor3 = C.text
    box.Font = FONT_R
    box.TextSize = 12
    box.ClearTextOnFocus = false
    UI.corner(box, 4)
    UI.stroke(box, C.border, 1)

    box.FocusLost:Connect(function(enter)
        if enter then callback(box.Text) end
    end)

    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    return f
end

---------- LABEL ----------
function UI.label(parent, text, order)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, -12, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.dim
    lbl.Font = FONT_R
    lbl.TextSize = 12
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order or 0
    return lbl
end

---------- SEPARATOR ----------
function UI.separator(parent, order)
    local s = Instance.new("Frame", parent)
    s.Size = UDim2.new(1, -20, 0, 1)
    s.BackgroundColor3 = C.border
    s.BorderSizePixel = 0
    s.LayoutOrder = order or 0
    return s
end

---------- SCROLLING PAGE ----------
function UI.scrollPage(parent, name)
    local scroll = Instance.new("ScrollingFrame", parent)
    scroll.Name = name
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Visible = false
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = C.accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    UI.listLayout(scroll, 5)
    UI.pad(scroll, 6, 6, 6, 6)
    return scroll
end

return UI

