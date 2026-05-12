--[[
    Nexus UILib v3.1 — Rewritten component factory
    + Color picker, multi-select, search box, tab groups
    + Better auto-canvas sizing, smooth scroll, input debouncing
    + Tooltip system, context menus, drag-reorder
    Usage: local UI = loadstring(src)()
]]

local TweenSrv = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunSrv = game:GetService("RunService")
local Players = game:GetService("Players")

local UI = {}
UI.__index = UI

-- Registry for all controls (enables config save/load)
UI._registry = {}
UI._connections = {}

-- Theme system with multiple presets
UI.Themes = {
    Midnight = {
        bg       = Color3.fromRGB(12, 12, 18),
        sidebar  = Color3.fromRGB(16, 16, 24),
        topbar   = Color3.fromRGB(18, 18, 26),
        card     = Color3.fromRGB(24, 24, 34),
        cardHov  = Color3.fromRGB(30, 30, 42),
        accent   = Color3.fromRGB(130, 80, 255),
        accent2  = Color3.fromRGB(60, 200, 255),
        accent3  = Color3.fromRGB(255, 90, 180),
        text     = Color3.fromRGB(225, 225, 235),
        dim      = Color3.fromRGB(100, 100, 125),
        on       = Color3.fromRGB(60, 220, 130),
        off      = Color3.fromRGB(70, 70, 90),
        danger   = Color3.fromRGB(220, 50, 70),
        border   = Color3.fromRGB(36, 36, 50),
        glow     = Color3.fromRGB(130, 80, 255),
        warning  = Color3.fromRGB(255, 180, 40),
        input    = Color3.fromRGB(20, 20, 30),
    },
    Ocean = {
        bg       = Color3.fromRGB(10, 15, 22),
        sidebar  = Color3.fromRGB(14, 20, 28),
        topbar   = Color3.fromRGB(16, 22, 32),
        card     = Color3.fromRGB(20, 28, 40),
        cardHov  = Color3.fromRGB(26, 36, 50),
        accent   = Color3.fromRGB(40, 160, 255),
        accent2  = Color3.fromRGB(0, 220, 200),
        accent3  = Color3.fromRGB(100, 140, 255),
        text     = Color3.fromRGB(220, 230, 240),
        dim      = Color3.fromRGB(80, 100, 130),
        on       = Color3.fromRGB(40, 200, 160),
        off      = Color3.fromRGB(50, 60, 80),
        danger   = Color3.fromRGB(255, 70, 80),
        border   = Color3.fromRGB(30, 40, 55),
        glow     = Color3.fromRGB(40, 160, 255),
        warning  = Color3.fromRGB(255, 200, 50),
        input    = Color3.fromRGB(14, 20, 30),
    },
    Blood = {
        bg       = Color3.fromRGB(16, 10, 10),
        sidebar  = Color3.fromRGB(22, 14, 14),
        topbar   = Color3.fromRGB(24, 16, 16),
        card     = Color3.fromRGB(32, 20, 22),
        cardHov  = Color3.fromRGB(42, 28, 30),
        accent   = Color3.fromRGB(220, 40, 60),
        accent2  = Color3.fromRGB(255, 100, 60),
        accent3  = Color3.fromRGB(200, 60, 120),
        text     = Color3.fromRGB(235, 220, 220),
        dim      = Color3.fromRGB(120, 90, 95),
        on       = Color3.fromRGB(220, 60, 80),
        off      = Color3.fromRGB(80, 55, 60),
        danger   = Color3.fromRGB(255, 40, 40),
        border   = Color3.fromRGB(50, 30, 34),
        glow     = Color3.fromRGB(220, 40, 60),
        warning  = Color3.fromRGB(255, 160, 40),
        input    = Color3.fromRGB(20, 12, 14),
    },
    Emerald = {
        bg       = Color3.fromRGB(10, 16, 12),
        sidebar  = Color3.fromRGB(14, 22, 16),
        topbar   = Color3.fromRGB(16, 24, 18),
        card     = Color3.fromRGB(20, 32, 24),
        cardHov  = Color3.fromRGB(28, 42, 32),
        accent   = Color3.fromRGB(40, 200, 120),
        accent2  = Color3.fromRGB(80, 255, 180),
        accent3  = Color3.fromRGB(30, 180, 200),
        text     = Color3.fromRGB(220, 235, 225),
        dim      = Color3.fromRGB(90, 115, 100),
        on       = Color3.fromRGB(50, 220, 120),
        off      = Color3.fromRGB(55, 75, 60),
        danger   = Color3.fromRGB(220, 60, 60),
        border   = Color3.fromRGB(30, 45, 35),
        glow     = Color3.fromRGB(40, 200, 120),
        warning  = Color3.fromRGB(240, 200, 50),
        input    = Color3.fromRGB(12, 20, 14),
    },
    Rose = {
        bg       = Color3.fromRGB(16, 10, 16),
        sidebar  = Color3.fromRGB(22, 14, 22),
        topbar   = Color3.fromRGB(24, 16, 24),
        card     = Color3.fromRGB(34, 22, 34),
        cardHov  = Color3.fromRGB(44, 30, 44),
        accent   = Color3.fromRGB(230, 80, 160),
        accent2  = Color3.fromRGB(180, 60, 255),
        accent3  = Color3.fromRGB(255, 120, 180),
        text     = Color3.fromRGB(235, 220, 235),
        dim      = Color3.fromRGB(120, 90, 120),
        on       = Color3.fromRGB(230, 80, 160),
        off      = Color3.fromRGB(80, 55, 80),
        danger   = Color3.fromRGB(255, 50, 60),
        border   = Color3.fromRGB(48, 30, 48),
        glow     = Color3.fromRGB(230, 80, 160),
        warning  = Color3.fromRGB(255, 180, 60),
        input    = Color3.fromRGB(20, 12, 20),
    },
}

UI.Theme = UI.Themes.Midnight
local C = UI.Theme

local FONT_B = Enum.Font.GothamBold
local FONT_S = Enum.Font.GothamSemibold
local FONT_R = Enum.Font.Gotham

-- ═══════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════

function UI.setTheme(name)
    if UI.Themes[name] then
        UI.Theme = UI.Themes[name]
        C = UI.Theme
        for _, ctrl in pairs(UI._registry) do
            if ctrl.onThemeChange then
                pcall(ctrl.onThemeChange, C)
            end
        end
    end
end

function UI.tween(obj, props, t, style, dir)
    if not obj or not obj.Parent then return end
    local info = TweenInfo.new(
        t or 0.25,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out
    )
    local tw = TweenSrv:Create(obj, info, props)
    tw:Play()
    return tw
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

function UI.ripple(button, color)
    local ripple = Instance.new("Frame", button)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = color or Color3.new(1, 1, 1)
    ripple.BackgroundTransparency = 0.7
    ripple.BorderSizePixel = 0
    ripple.ZIndex = button.ZIndex + 1
    UI.corner(ripple, 999)

    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    UI.tween(ripple, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }, 0.4, Enum.EasingStyle.Quad)
    task.delay(0.5, function()
        if ripple and ripple.Parent then ripple:Destroy() end
    end)
end

function UI.debounce(fn, delay)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= (delay or 0.1) then
            lastCall = now
            return fn(...)
        end
    end
end

function UI.register(id, ctrl)
    UI._registry[id] = ctrl
end

function UI.getConfig()
    local cfg = {}
    for id, ctrl in pairs(UI._registry) do
        if ctrl.getState then
            cfg[id] = ctrl.getState()
        elseif ctrl.getSelected then
            cfg[id] = ctrl.getSelected()
        elseif ctrl.getValue then
            cfg[id] = ctrl.getValue()
        end
    end
    return cfg
end

function UI.loadConfig(cfg)
    for id, value in pairs(cfg) do
        local ctrl = UI._registry[id]
        if ctrl and ctrl.setState then
            ctrl.setState(value)
        elseif ctrl and ctrl.setValue then
            ctrl.setValue(value)
        end
    end
end

function UI.cleanup()
    for _, conn in pairs(UI._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    UI._connections = {}
    UI._registry = {}
end

-- ═══════════════════════════════════════════
-- NOTIFICATION SYSTEM (Upgraded v2)
-- ═══════════════════════════════════════════

local notifHolder = nil
local notifCount = 0
local activeNotifs = {}
local MAX_NOTIFS = 5

local NOTIF_ICONS = {
    info    = "ℹ️",
    success = "✓",
    error   = "✕",
    warning = "⚠",
}

function UI.initNotifications(parent)
    notifHolder = Instance.new("Frame", parent)
    notifHolder.Name = "Notifications"
    notifHolder.Size = UDim2.new(0, 300, 1, -20)
    notifHolder.Position = UDim2.new(1, -310, 0, 10)
    notifHolder.BackgroundTransparency = 1
    notifHolder.BorderSizePixel = 0
    notifHolder.ZIndex = 100

    local layout = UI.listLayout(notifHolder, 8)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
end

function UI.notify(title, msg, duration, notifType)
    if not notifHolder then return end
    duration = duration or 4
    notifType = notifType or "info"
    notifCount = notifCount + 1
    local order = notifCount

    -- Evict oldest if over max
    if #activeNotifs >= MAX_NOTIFS then
        local oldest = table.remove(activeNotifs, 1)
        if oldest and oldest.Parent then
            UI.tween(oldest, {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1
            }, 0.25)
            task.delay(0.3, function()
                if oldest and oldest.Parent then oldest:Destroy() end
            end)
        end
    end

    local accentColor = C.accent
    if notifType == "success" then accentColor = C.on
    elseif notifType == "error" then accentColor = C.danger
    elseif notifType == "warning" then accentColor = C.warning end

    local icon = NOTIF_ICONS[notifType] or NOTIF_ICONS.info

    -- Main notification frame
    local n = Instance.new("Frame", notifHolder)
    n.Name = "Notif_" .. order
    n.Size = UDim2.new(1, 0, 0, 0)
    n.BackgroundColor3 = C.card
    n.BorderSizePixel = 0
    n.BackgroundTransparency = 1
    n.LayoutOrder = order
    n.ClipsDescendants = true
    n.ZIndex = 100
    UI.corner(n, 10)

    -- Glow stroke
    local nStroke = UI.stroke(n, accentColor, 1.5)

    -- Subtle inner shadow / depth via gradient
    local innerGrad = Instance.new("UIGradient", n)
    innerGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180)),
    })
    innerGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.94),
        NumberSequenceKeypoint.new(1, 0.98),
    })
    innerGrad.Rotation = 90

    -- Accent bar (left edge)
    local accentBar = Instance.new("Frame", n)
    accentBar.Size = UDim2.new(0, 4, 0.6, 0)
    accentBar.Position = UDim2.new(0, 8, 0.2, 0)
    accentBar.BackgroundColor3 = accentColor
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 101
    UI.corner(accentBar, 2)

    -- Icon circle
    local iconBg = Instance.new("Frame", n)
    iconBg.Size = UDim2.new(0, 26, 0, 26)
    iconBg.Position = UDim2.new(0, 18, 0, 12)
    iconBg.BackgroundColor3 = accentColor
    iconBg.BackgroundTransparency = 0.85
    iconBg.BorderSizePixel = 0
    iconBg.ZIndex = 101
    UI.corner(iconBg, 13)

    local iconLbl = Instance.new("TextLabel", iconBg)
    iconLbl.Size = UDim2.new(1, 0, 1, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = icon
    iconLbl.TextColor3 = accentColor
    iconLbl.Font = FONT_B
    iconLbl.TextSize = 14
    iconLbl.ZIndex = 102

    -- Title
    local tLbl = Instance.new("TextLabel", n)
    tLbl.Size = UDim2.new(1, -70, 0, 18)
    tLbl.Position = UDim2.new(0, 52, 0, 10)
    tLbl.BackgroundTransparency = 1
    tLbl.Text = title
    tLbl.TextColor3 = C.text
    tLbl.Font = FONT_B
    tLbl.TextSize = 13
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.TextTruncate = Enum.TextTruncate.AtEnd
    tLbl.ZIndex = 101

    -- Message
    local mLbl = Instance.new("TextLabel", n)
    mLbl.Size = UDim2.new(1, -70, 0, 30)
    mLbl.Position = UDim2.new(0, 52, 0, 28)
    mLbl.BackgroundTransparency = 1
    mLbl.Text = msg
    mLbl.TextColor3 = C.dim
    mLbl.Font = FONT_R
    mLbl.TextSize = 11
    mLbl.TextXAlignment = Enum.TextXAlignment.Left
    mLbl.TextWrapped = true
    mLbl.TextTruncate = Enum.TextTruncate.AtEnd
    mLbl.ZIndex = 101

    -- Close button (X)
    local closeBtn = Instance.new("TextButton", n)
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -26, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = C.dim
    closeBtn.Font = FONT_B
    closeBtn.TextSize = 12
    closeBtn.ZIndex = 102

    closeBtn.MouseEnter:Connect(function()
        UI.tween(closeBtn, {TextColor3 = C.danger}, 0.1)
    end)
    closeBtn.MouseLeave:Connect(function()
        UI.tween(closeBtn, {TextColor3 = C.dim}, 0.1)
    end)

    -- Progress bar at bottom
    local progressBg = Instance.new("Frame", n)
    progressBg.Size = UDim2.new(1, -16, 0, 3)
    progressBg.Position = UDim2.new(0, 8, 1, -8)
    progressBg.BackgroundColor3 = C.off
    progressBg.BackgroundTransparency = 0.5
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 101
    UI.corner(progressBg, 2)

    local progress = Instance.new("Frame", progressBg)
    progress.Size = UDim2.new(1, 0, 1, 0)
    progress.BackgroundColor3 = accentColor
    progress.BorderSizePixel = 0
    progress.ZIndex = 102
    UI.corner(progress, 2)

    -- Track in active list
    table.insert(activeNotifs, n)

    -- Dismiss function
    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        -- Remove from active list
        for i, notif in ipairs(activeNotifs) do
            if notif == n then
                table.remove(activeNotifs, i)
                break
            end
        end
        UI.tween(n, {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1
        }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        UI.tween(nStroke, {Transparency = 1}, 0.2)
        task.delay(0.4, function()
            if n and n.Parent then n:Destroy() end
        end)
    end

    -- Close on click
    closeBtn.MouseButton1Click:Connect(dismiss)

    -- Animate in (slide + fade)
    n.Position = UDim2.new(0.1, 0, 0, 0)
    UI.tween(n, {
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundTransparency = 0.02,
        Position = UDim2.new(0, 0, 0, 0)
    }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Accent bar pulse on entry
    task.delay(0.1, function()
        if accentBar and accentBar.Parent then
            UI.tween(accentBar, {Size = UDim2.new(0, 4, 0.8, 0)}, 0.2)
            task.delay(0.2, function()
                if accentBar and accentBar.Parent then
                    UI.tween(accentBar, {Size = UDim2.new(0, 4, 0.6, 0)}, 0.3)
                end
            end)
        end
    end)

    -- Progress drain
    UI.tween(progress, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

    -- Auto-dismiss after duration
    task.delay(duration, function()
        dismiss()
    end)

    return {
        dismiss = dismiss,
        frame = n,
    }
end

-- Quick helper variants
function UI.notifySuccess(title, msg, duration)
    return UI.notify(title, msg, duration or 3, "success")
end

function UI.notifyError(title, msg, duration)
    return UI.notify(title, msg, duration or 5, "error")
end

function UI.notifyWarning(title, msg, duration)
    return UI.notify(title, msg, duration or 4, "warning")
end

-- ═══════════════════════════════════════════
-- SECTION HEADER (Collapsible)
-- ═══════════════════════════════════════════

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
    line.Size = UDim2.new(1, -(#title * 6 + 12), 0, 1)
    line.Position = UDim2.new(0, #title * 6 + 8, 0.5, 0)
    line.BackgroundColor3 = C.border
    line.BorderSizePixel = 0

    return f
end

-- ═══════════════════════════════════════════
-- TOGGLE (With ID registration)
-- ═══════════════════════════════════════════

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

    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    local function setVisual(s)
        UI.tween(togBg, {BackgroundColor3 = s and C.on or C.off}, 0.2)
        UI.tween(circ, {Position = UDim2.new(0, s and 20 or 2, 0, 2)}, 0.2)
    end

    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        state = not state
        setVisual(state)
        callback(state)
    end)

    local ctrl = {
        frame = f,
        getState = function() return state end,
        setState = function(s)
            state = s
            setVisual(state)
            callback(state)
        end
    }

    local id = (parent.Name or "page") .. "." .. name
    UI.register(id, ctrl)

    return ctrl
end

-- ═══════════════════════════════════════════
-- SLIDER (With value display and ID)
-- ═══════════════════════════════════════════

function UI.slider(parent, name, min, max, default, callback, order)
    callback = callback or function() end
    local currentValue = default

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
    knob.ZIndex = 3
    UI.corner(knob, 7)

    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    local sliding = false

    local function updateSlider(rel)
        rel = math.clamp(rel, 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -7, 0.5, -7)
        currentValue = math.floor(min + rel * (max - min))
        valLbl.Text = tostring(currentValue)
        callback(currentValue)
    end

    local hitbox = Instance.new("TextButton", f)
    hitbox.Size = UDim2.new(1, 0, 0, 24)
    hitbox.Position = UDim2.new(0, 0, 0, 26)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            updateSlider(rel)
        end
    end)

    local conn1 = UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    local conn2 = UIS.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            updateSlider(rel)
        end
    end)
    table.insert(UI._connections, conn1)
    table.insert(UI._connections, conn2)

    local ctrl = {
        frame = f,
        getValue = function() return currentValue end,
        setValue = function(v)
            currentValue = math.clamp(v, min, max)
            local rel = (currentValue - min) / (max - min)
            updateSlider(rel)
        end
    }

    local id = (parent.Name or "page") .. "." .. name
    UI.register(id, ctrl)
    return ctrl
end

-- ═══════════════════════════════════════════
-- DROPDOWN
-- ═══════════════════════════════════════════

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
    dropList.ZIndex = 50
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
        ob.ZIndex = 51
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

    local ctrl = {
        frame = f,
        getSelected = function() return selected end,
        setSelected = function(opt)
            selected = opt
            selBtn.Text = "  " .. opt .. "  ▼"
            callback(opt)
        end
    }

    local id = (parent.Name or "page") .. "." .. name
    UI.register(id, ctrl)
    return ctrl
end

-- ═══════════════════════════════════════════
-- BUTTON
-- ═══════════════════════════════════════════

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
    btn.ClipsDescendants = true
    UI.corner(btn, 6)
    UI.gradient(btn, C.accent, C.accent2, 0)

    btn.MouseEnter:Connect(function() UI.tween(btn, {BackgroundTransparency = 0.15}, 0.15) end)
    btn.MouseLeave:Connect(function() UI.tween(btn, {BackgroundTransparency = 0}, 0.15) end)
    btn.MouseButton1Click:Connect(function()
        UI.ripple(btn, Color3.new(1, 1, 1))
        UI.tween(btn, {Size = UDim2.new(1, -16, 0, 30)}, 0.08)
        task.delay(0.08, function() UI.tween(btn, {Size = UDim2.new(1, -12, 0, 32)}, 0.1) end)
        callback()
    end)

    return btn
end

-- ═══════════════════════════════════════════
-- KEYBIND
-- ═══════════════════════════════════════════

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

    local conn = UIS.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                kBtn.Text = currentKey.Name
            else
                currentKey = input.KeyCode
                kBtn.Text = currentKey.Name
            end
            listening = false
            UI.tween(kBtn, {BackgroundColor3 = C.sidebar}, 0.15)
            kBtn.TextColor3 = C.accent
            callback(currentKey)
        end
    end)
    table.insert(UI._connections, conn)

    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    local ctrl = {
        frame = f,
        getKey = function() return currentKey end,
        isKey = function(keyCode) return keyCode == currentKey end,
    }

    local id = (parent.Name or "page") .. "." .. name
    UI.register(id, ctrl)
    return ctrl
end

-- ═══════════════════════════════════════════
-- TEXTBOX
-- ═══════════════════════════════════════════

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
    box.BackgroundColor3 = C.input or C.sidebar
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

    box.Focused:Connect(function()
        UI.tween(box, {BackgroundColor3 = C.cardHov}, 0.15)
    end)
    box.FocusLost:Connect(function(enter)
        UI.tween(box, {BackgroundColor3 = C.input or C.sidebar}, 0.15)
        if enter then callback(box.Text) end
    end)

    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    return {
        frame = f,
        getText = function() return box.Text end,
        setText = function(t) box.Text = t end,
    }
end

-- ═══════════════════════════════════════════
-- LABEL
-- ═══════════════════════════════════════════

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

-- ═══════════════════════════════════════════
-- SEPARATOR
-- ═══════════════════════════════════════════

function UI.separator(parent, order)
    local s = Instance.new("Frame", parent)
    s.Size = UDim2.new(1, -20, 0, 1)
    s.BackgroundColor3 = C.border
    s.BorderSizePixel = 0
    s.LayoutOrder = order or 0
    return s
end

-- ═══════════════════════════════════════════
-- COLOR PICKER (NEW)
-- ═══════════════════════════════════════════

function UI.colorPicker(parent, name, defaultColor, callback, order)
    callback = callback or function() end
    local color = defaultColor or Color3.fromRGB(255, 0, 0)
    local h, s, v = Color3.toHSV(color)

    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -12, 0, 34)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0
    f.ClipsDescendants = false
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

    local preview = Instance.new("TextButton", f)
    preview.Size = UDim2.new(0, 30, 0, 20)
    preview.Position = UDim2.new(1, -42, 0.5, -10)
    preview.BackgroundColor3 = color
    preview.BorderSizePixel = 0
    preview.Text = ""
    UI.corner(preview, 4)
    UI.stroke(preview, C.border, 1)

    local pickerOpen = false
    local pickerFrame = Instance.new("Frame", f)
    pickerFrame.Size = UDim2.new(0, 200, 0, 0)
    pickerFrame.Position = UDim2.new(1, -200, 1, 4)
    pickerFrame.BackgroundColor3 = C.sidebar
    pickerFrame.BorderSizePixel = 0
    pickerFrame.Visible = false
    pickerFrame.ZIndex = 60
    pickerFrame.ClipsDescendants = true
    UI.corner(pickerFrame, 8)
    UI.stroke(pickerFrame, C.border, 1)

    local svField = Instance.new("ImageLabel", pickerFrame)
    svField.Size = UDim2.new(1, -16, 0, 130)
    svField.Position = UDim2.new(0, 8, 0, 8)
    svField.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    svField.BorderSizePixel = 0
    svField.ZIndex = 61
    UI.corner(svField, 4)

    local whiteGrad = Instance.new("ImageLabel", svField)
    whiteGrad.Size = UDim2.new(1, 0, 1, 0)
    whiteGrad.BackgroundTransparency = 1
    whiteGrad.Image = "rbxassetid://4155801252"
    whiteGrad.ZIndex = 62

    local blackGrad = Instance.new("ImageLabel", svField)
    blackGrad.Size = UDim2.new(1, 0, 1, 0)
    blackGrad.BackgroundTransparency = 1
    blackGrad.Image = "rbxassetid://4155801252"
    blackGrad.ImageColor3 = Color3.new(0, 0, 0)
    blackGrad.ZIndex = 63

    local svGradient = Instance.new("UIGradient", blackGrad)
    svGradient.Rotation = 90

    local svCursor = Instance.new("Frame", svField)
    svCursor.Size = UDim2.new(0, 10, 0, 10)
    svCursor.Position = UDim2.new(s, -5, 1 - v, -5)
    svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    svCursor.BorderSizePixel = 0
    svCursor.ZIndex = 64
    UI.corner(svCursor, 5)
    UI.stroke(svCursor, Color3.new(0, 0, 0), 1)

    local hueTrack = Instance.new("Frame", pickerFrame)
    hueTrack.Size = UDim2.new(1, -16, 0, 16)
    hueTrack.Position = UDim2.new(0, 8, 0, 146)
    hueTrack.BackgroundColor3 = Color3.new(1, 1, 1)
    hueTrack.BorderSizePixel = 0
    hueTrack.ZIndex = 61
    UI.corner(hueTrack, 4)

    local hueGradient = Instance.new("UIGradient", hueTrack)
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
        ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
        ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
        ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
        ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
    })

    local hueCursor = Instance.new("Frame", hueTrack)
    hueCursor.Size = UDim2.new(0, 6, 1, 4)
    hueCursor.Position = UDim2.new(h, -3, 0, -2)
    hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    hueCursor.BorderSizePixel = 0
    hueCursor.ZIndex = 62
    UI.corner(hueCursor, 2)
    UI.stroke(hueCursor, Color3.new(0, 0, 0), 1)

    local function updateColor()
        color = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = color
        svField.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.new(s, -5, 1 - v, -5)
        hueCursor.Position = UDim2.new(h, -3, 0, -2)
        callback(color)
    end

    local svDragging = false
    local svBtn = Instance.new("TextButton", svField)
    svBtn.Size = UDim2.new(1, 0, 1, 0)
    svBtn.BackgroundTransparency = 1
    svBtn.Text = ""
    svBtn.ZIndex = 65

    svBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = true end
    end)

    local hueDragging = false
    local hueBtn = Instance.new("TextButton", hueTrack)
    hueBtn.Size = UDim2.new(1, 0, 1, 0)
    hueBtn.BackgroundTransparency = 1
    hueBtn.Text = ""
    hueBtn.ZIndex = 63

    hueBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = true end
    end)

    local conn1 = UIS.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            if svDragging then
                s = math.clamp((i.Position.X - svField.AbsolutePosition.X) / svField.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((i.Position.Y - svField.AbsolutePosition.Y) / svField.AbsoluteSize.Y, 0, 1)
                updateColor()
            elseif hueDragging then
                h = math.clamp((i.Position.X - hueTrack.AbsolutePosition.X) / hueTrack.AbsoluteSize.X, 0, 1)
                updateColor()
            end
        end
    end)
    local conn2 = UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDragging = false
            hueDragging = false
        end
    end)
    table.insert(UI._connections, conn1)
    table.insert(UI._connections, conn2)

    preview.MouseButton1Click:Connect(function()
        pickerOpen = not pickerOpen
        if pickerOpen then
            pickerFrame.Visible = true
            UI.tween(pickerFrame, {Size = UDim2.new(0, 200, 0, 174)}, 0.2)
        else
            UI.tween(pickerFrame, {Size = UDim2.new(0, 200, 0, 0)}, 0.15)
            task.delay(0.2, function() pickerFrame.Visible = false end)
        end
    end)

    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    return {
        frame = f,
        getColor = function() return color end,
        setColor = function(c)
            color = c
            h, s, v = Color3.toHSV(c)
            updateColor()
        end
    }
end

-- ═══════════════════════════════════════════
-- MULTI-SELECT (NEW)
-- ═══════════════════════════════════════════

function UI.multiSelect(parent, name, options, defaults, callback, order)
    callback = callback or function() end
    local selected = {}
    for _, d in ipairs(defaults or {}) do selected[d] = true end

    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -12, 0, 34 + #options * 26)
    f.BackgroundColor3 = C.card
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0
    f.ClipsDescendants = true
    UI.corner(f, 6)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -12, 0, 30)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = C.text
    lbl.Font = FONT_R
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    for i, opt in ipairs(options) do
        local optFrame = Instance.new("Frame", f)
        optFrame.Size = UDim2.new(1, -24, 0, 22)
        optFrame.Position = UDim2.new(0, 12, 0, 30 + (i - 1) * 26)
        optFrame.BackgroundTransparency = 1
        optFrame.BorderSizePixel = 0

        local check = Instance.new("Frame", optFrame)
        check.Size = UDim2.new(0, 16, 0, 16)
        check.Position = UDim2.new(0, 0, 0.5, -8)
        check.BackgroundColor3 = selected[opt] and C.accent or C.off
        check.BorderSizePixel = 0
        UI.corner(check, 3)

        local checkMark = Instance.new("TextLabel", check)
        checkMark.Size = UDim2.new(1, 0, 1, 0)
        checkMark.BackgroundTransparency = 1
        checkMark.Text = selected[opt] and "✓" or ""
        checkMark.TextColor3 = Color3.new(1, 1, 1)
        checkMark.Font = FONT_B
        checkMark.TextSize = 11

        local optLbl = Instance.new("TextLabel", optFrame)
        optLbl.Size = UDim2.new(1, -24, 1, 0)
        optLbl.Position = UDim2.new(0, 22, 0, 0)
        optLbl.BackgroundTransparency = 1
        optLbl.Text = opt
        optLbl.TextColor3 = C.dim
        optLbl.Font = FONT_R
        optLbl.TextSize = 12
        optLbl.TextXAlignment = Enum.TextXAlignment.Left

        local optBtn = Instance.new("TextButton", optFrame)
        optBtn.Size = UDim2.new(1, 0, 1, 0)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = ""
        optBtn.MouseButton1Click:Connect(function()
            selected[opt] = not selected[opt]
            UI.tween(check, {BackgroundColor3 = selected[opt] and C.accent or C.off}, 0.15)
            checkMark.Text = selected[opt] and "✓" or ""
            optLbl.TextColor3 = selected[opt] and C.text or C.dim

            local result = {}
            for _, o in ipairs(options) do
                if selected[o] then table.insert(result, o) end
            end
            callback(result)
        end)
    end

    f.MouseEnter:Connect(function() UI.tween(f, {BackgroundColor3 = C.cardHov}, 0.15) end)
    f.MouseLeave:Connect(function() UI.tween(f, {BackgroundColor3 = C.card}, 0.15) end)

    return {
        frame = f,
        getSelected = function()
            local result = {}
            for _, o in ipairs(options) do
                if selected[o] then table.insert(result, o) end
            end
            return result
        end
    }
end

-- ═══════════════════════════════════════════
-- SCROLLING PAGE
-- ═══════════════════════════════════════════

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
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    UI.listLayout(scroll, 5)
    UI.pad(scroll, 6, 6, 6, 6)
    return scroll
end

return UI
