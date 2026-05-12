--[[
    Nexus v3.1 — Main Loader (Improved)
    + Auto game detection
    + Better error handling & recovery
    + Config persistence via executor filesystem
    + Performance monitoring
    + Module hot-reload support
    Toggle: RightShift | Minimize: RightControl
]]

local Players = game:GetService("Players")
local TweenSrv = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpSrv = game:GetService("HttpService")
local RunSrv = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local LP = Players.LocalPlayer

-- GitHub repo
local BASE_URL = "https://raw.githubusercontent.com/tmhp/Nexus/refs/heads/main/"
local VERSION = "3.1"

local function fetchScript(path)
    local success, result = pcall(function()
        return game:HttpGet(BASE_URL .. path, true)
    end)
    if success then return result end
    warn("[Nexus] Failed to fetch: " .. path .. " — " .. tostring(result))
    return nil
end

-- Cleanup previous instance
if LP.PlayerGui:FindFirstChild("Nexus_Panel") then
    LP.PlayerGui:FindFirstChild("Nexus_Panel"):Destroy()
end

---------- LOAD UI LIBRARY ----------
local uiSuccess, UI = pcall(function()
    local src = fetchScript("UILib.lua")
    if not src then error("Failed to download UILib") end
    return loadstring(src)()
end)

if not uiSuccess then
    warn("[Nexus] Failed to load UILib: " .. tostring(UI))
    return
end

local C = UI.Theme

---------- AUTO GAME DETECTION ----------
local GameIDs = {
    [292439477]  = "Phantom Forces",
    [2753915549] = "Blox Fruits",
    [286090429]  = "Arsenal",
    [2788229376] = "Da Hood",
    [142823291]  = "Murder Mystery 2",
    [606849621]  = "Jailbreak",
    [6284583030] = "Pet Simulator X",
    [4520749081] = "King Legacy",
    [3260590327] = "Tower Defense",
    [3837841034] = "Anime Fighters",
}

local function detectGame()
    local placeId = game.PlaceId

    -- Direct match
    if GameIDs[placeId] then
        return GameIDs[placeId]
    end

    -- Try to match by universe ID (handles multiple places in same game)
    local success, gameInfo = pcall(function()
        return MarketplaceService:GetProductInfo(placeId)
    end)
    if success and gameInfo then
        local gameName = gameInfo.Name or ""
        for _, name in pairs(GameIDs) do
            if gameName:lower():find(name:lower()) then
                return name
            end
        end
    end

    return "Universal"
end

---------- GAME MODULE REGISTRY ----------
local GameModules = {
    ["Universal"]        = "Games/Universal",
    ["Blox Fruits"]      = "Games/BloxFruits",
    ["Arsenal"]          = "Games/Arsenal",
    ["Da Hood"]          = "Games/DaHood",
    ["Phantom Forces"]   = "Games/PhantomForces",
    ["Murder Mystery 2"] = nil,
    ["Jailbreak"]        = nil,
    ["Pet Simulator X"]  = nil,
    ["King Legacy"]      = nil,
    ["Tower Defense"]    = nil,
    ["Anime Fighters"]   = nil,
}

local TABS = {"Combat", "Movement", "Visual", "Player", "World", "Misc", "Settings"}
local tabBtns = {}
local activeTab = nil
local activeGamePages = {}
local currentGame = "Universal"

---------- CONFIG SYSTEM ----------
local ConfigSystem = {}

function ConfigSystem.getPath()
    return "Nexus/configs/"
end

function ConfigSystem.save(name)
    local config = UI.getConfig()
    config._game = currentGame
    config._version = VERSION

    local json = HttpSrv:JSONEncode(config)
    local path = ConfigSystem.getPath() .. name .. ".json"

    pcall(function()
        if not isfolder("Nexus") then makefolder("Nexus") end
        if not isfolder("Nexus/configs") then makefolder("Nexus/configs") end
        writefile(path, json)
    end)
end

function ConfigSystem.load(name)
    local path = ConfigSystem.getPath() .. name .. ".json"
    local success, data = pcall(function()
        return readfile(path)
    end)
    if success and data then
        local config = HttpSrv:JSONDecode(data)
        UI.loadConfig(config)
        return true
    end
    return false
end

function ConfigSystem.list()
    local configs = {}
    pcall(function()
        if isfolder("Nexus/configs") then
            for _, file in ipairs(listfiles("Nexus/configs")) do
                if file:sub(-5) == ".json" then
                    local name = file:match("([^/\\]+)%.json$")
                    if name then table.insert(configs, name) end
                end
            end
        end
    end)
    return configs
end

---------- ROOT GUI ----------
local gui = Instance.new("ScreenGui")
gui.Name = "Nexus_Panel"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LP.PlayerGui

UI.initNotifications(gui)

-- Drop shadow
local shadow = Instance.new("ImageLabel", gui)
shadow.Size = UDim2.new(0, 680, 0, 480)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6015897843"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.4
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.ZIndex = 0

-- Main frame
local main = Instance.new("Frame", gui)
main.Name = "Main"
main.Size = UDim2.new(0, 640, 0, 440)
main.Position = UDim2.new(0.5, -320, 0.5, -220)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
UI.corner(main, 10)
UI.stroke(main, C.border, 1)

local function updateShadow()
    shadow.Position = UDim2.new(0, main.AbsolutePosition.X - 20, 0, main.AbsolutePosition.Y - 20)
end
main:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateShadow)
task.defer(updateShadow)

---------- TOP BAR ----------
local topbar = Instance.new("Frame", main)
topbar.Name = "Topbar"
topbar.Size = UDim2.new(1, 0, 0, 38)
topbar.BackgroundColor3 = C.topbar
topbar.BorderSizePixel = 0
UI.corner(topbar, 10)

local topFix = Instance.new("Frame", topbar)
topFix.Size = UDim2.new(1, 0, 0, 12)
topFix.Position = UDim2.new(0, 0, 1, -12)
topFix.BackgroundColor3 = C.topbar
topFix.BorderSizePixel = 0

local accentLine = Instance.new("Frame", topbar)
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 1, -1)
accentLine.BackgroundColor3 = C.accent
accentLine.BorderSizePixel = 0
UI.gradient(accentLine, C.accent, C.accent2, 0)

local title = Instance.new("TextLabel", topbar)
title.Size = UDim2.new(0, 100, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Nexus"
title.TextColor3 = C.accent
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

local verLbl = Instance.new("TextLabel", topbar)
verLbl.Size = UDim2.new(0, 50, 1, 0)
verLbl.Position = UDim2.new(0, 68, 0, 1)
verLbl.BackgroundTransparency = 1
verLbl.Text = "v" .. VERSION
verLbl.TextColor3 = Color3.fromRGB(60, 60, 80)
verLbl.Font = Enum.Font.Gotham
verLbl.TextSize = 10
verLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize & Close
local minBtn = Instance.new("TextButton", topbar)
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -68, 0, 5)
minBtn.BackgroundColor3 = C.card
minBtn.BorderSizePixel = 0
minBtn.Text = "—"
minBtn.TextColor3 = C.dim
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
UI.corner(minBtn, 6)

local closeBtn = Instance.new("TextButton", topbar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 5)
closeBtn.BackgroundColor3 = C.card
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = C.danger
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
UI.corner(closeBtn, 6)

closeBtn.MouseEnter:Connect(function() UI.tween(closeBtn, {BackgroundColor3 = C.danger}, 0.15); closeBtn.TextColor3 = Color3.new(1,1,1) end)
closeBtn.MouseLeave:Connect(function() UI.tween(closeBtn, {BackgroundColor3 = C.card}, 0.15); closeBtn.TextColor3 = C.danger end)
minBtn.MouseEnter:Connect(function() UI.tween(minBtn, {BackgroundColor3 = C.cardHov}, 0.15) end)
minBtn.MouseLeave:Connect(function() UI.tween(minBtn, {BackgroundColor3 = C.card}, 0.15) end)

local minimized = false
local fullSize = UDim2.new(0, 640, 0, 440)
local minSize = UDim2.new(0, 640, 0, 38)

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    UI.tween(main, {Size = minimized and minSize or fullSize}, 0.3)
    UI.tween(shadow, {Size = minimized and UDim2.new(0, 680, 0, 78) or UDim2.new(0, 680, 0, 480)}, 0.3)
    minBtn.Text = minimized and "+" or "—"
end)

closeBtn.MouseButton1Click:Connect(function()
    -- Auto save on close
    pcall(function() ConfigSystem.save("autosave") end)
    UI.cleanup()
    UI.tween(main, {Size = UDim2.new(0, 640, 0, 0)}, 0.3)
    UI.tween(shadow, {ImageTransparency = 1}, 0.3)
    task.delay(0.35, function() gui:Destroy() end)
end)

---------- DRAGGING ----------
local dragging, dragStart, startPos = false, nil, nil

topbar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
    end
end)

UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

---------- SIDEBAR ----------
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 150, 1, -38)
sidebar.Position = UDim2.new(0, 0, 0, 38)
sidebar.BackgroundColor3 = C.sidebar
sidebar.BorderSizePixel = 0

local sideDiv = Instance.new("Frame", sidebar)
sideDiv.Size = UDim2.new(0, 1, 1, -10)
sideDiv.Position = UDim2.new(1, 0, 0, 5)
sideDiv.BackgroundColor3 = C.border
sideDiv.BorderSizePixel = 0

---------- GAME SELECTOR ----------
local gameFrame = Instance.new("Frame", sidebar)
gameFrame.Size = UDim2.new(1, -16, 0, 34)
gameFrame.Position = UDim2.new(0, 8, 0, 10)
gameFrame.BackgroundColor3 = C.card
gameFrame.BorderSizePixel = 0
UI.corner(gameFrame, 6)
UI.stroke(gameFrame, C.accent, 1)

local gameIcon = Instance.new("ImageLabel", gameFrame)
gameIcon.Size = UDim2.new(0, 16, 0, 16)
gameIcon.Position = UDim2.new(0, 9, 0.5, -8)
gameIcon.BackgroundTransparency = 1
gameIcon.Image = "rbxassetid://82270605307346"
gameIcon.ImageColor3 = C.accent
gameIcon.ScaleType = Enum.ScaleType.Fit

local gameLbl = Instance.new("TextLabel", gameFrame)
gameLbl.Size = UDim2.new(1, -50, 1, 0)
gameLbl.Position = UDim2.new(0, 28, 0, 0)
gameLbl.BackgroundTransparency = 1
gameLbl.Text = currentGame
gameLbl.TextColor3 = C.text
gameLbl.Font = Enum.Font.GothamSemibold
gameLbl.TextSize = 11
gameLbl.TextXAlignment = Enum.TextXAlignment.Left

local gameArrow = Instance.new("TextLabel", gameFrame)
gameArrow.Size = UDim2.new(0, 20, 1, 0)
gameArrow.Position = UDim2.new(1, -22, 0, 0)
gameArrow.BackgroundTransparency = 1
gameArrow.Text = "▼"
gameArrow.TextColor3 = C.dim
gameArrow.Font = Enum.Font.Gotham
gameArrow.TextSize = 9

local gameNames = {}
for name, _ in pairs(GameModules) do
    table.insert(gameNames, name)
end
table.sort(gameNames)

local dropOpen = false
local dropFrame = Instance.new("ScrollingFrame", sidebar)
dropFrame.Size = UDim2.new(1, -16, 0, 0)
dropFrame.Position = UDim2.new(0, 8, 0, 46)
dropFrame.BackgroundColor3 = C.card
dropFrame.BorderSizePixel = 0
dropFrame.Visible = false
dropFrame.ScrollBarThickness = 3
dropFrame.ScrollBarImageColor3 = C.accent
dropFrame.CanvasSize = UDim2.new(0, 0, 0, #gameNames * 28)
dropFrame.ClipsDescendants = true
dropFrame.ZIndex = 20
UI.corner(dropFrame, 6)
UI.stroke(dropFrame, C.border, 1)

---------- CONTENT AREA ----------
local content = Instance.new("Frame", main)
content.Name = "Content"
content.Size = UDim2.new(1, -152, 1, -40)
content.Position = UDim2.new(0, 152, 0, 40)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ClipsDescendants = true

---------- SETTINGS PAGE ----------
local settingsPage = UI.scrollPage(content, "Settings")

UI.section(settingsPage, "Interface", 1)
UI.dropdown(settingsPage, "Theme", {"Midnight","Ocean","Blood","Emerald","Rose"}, "Midnight", function(val)
    UI.setTheme(val)
    UI.notify("Theme", "Switched to " .. val, 2, "success")
end, 2)
UI.toggle(settingsPage, "Show Watermark", true, nil, 5)

UI.section(settingsPage, "Configuration", 7)
UI.textbox(settingsPage, "Config Name", "default", function(val)
    -- Store for save/load buttons
    settingsPage._configName = val
end, 8)
UI.button(settingsPage, "Save Config", function()
    local name = settingsPage._configName or "default"
    ConfigSystem.save(name)
    UI.notify("Config", "Saved '" .. name .. "'", 2, "success")
end, 9)
UI.button(settingsPage, "Load Config", function()
    local name = settingsPage._configName or "default"
    if ConfigSystem.load(name) then
        UI.notify("Config", "Loaded '" .. name .. "'", 2, "success")
    else
        UI.notify("Config", "Config '" .. name .. "' not found", 2, "error")
    end
end, 10)
UI.toggle(settingsPage, "Auto-Save on Close", true, nil, 11)
UI.toggle(settingsPage, "Auto-Load on Start", false, nil, 12)

UI.section(settingsPage, "Keybinds", 14)
UI.keybind(settingsPage, "Toggle GUI", Enum.KeyCode.RightShift, nil, 15)
UI.keybind(settingsPage, "Panic Key (Destroy)", Enum.KeyCode.End, function(key)
    -- Panic key destroys everything
end, 16)

UI.section(settingsPage, "About", 18)
UI.label(settingsPage, "Nexus v" .. VERSION .. " — Modular Multi-Game Cheat", 19)
UI.label(settingsPage, "Detected Game: " .. detectGame(), 20)
UI.label(settingsPage, "Place ID: " .. tostring(game.PlaceId), 21)

---------- GAME MODULE LOADING ----------
local function clearGamePages()
    for _, pages in pairs(activeGamePages) do
        for _, page in pairs(pages) do
            if page and page.Parent then page:Destroy() end
        end
    end
    activeGamePages = {}
end

local function loadGameModule(gameName)
    clearGamePages()
    currentGame = gameName
    gameLbl.Text = gameName

    local modulePath = GameModules[gameName]
    if modulePath then
        local success, loader = pcall(function()
            local src = fetchScript(modulePath .. ".lua")
            if not src then error("Download failed") end
            return loadstring(src)()
        end)
        if success and loader then
            local pages = loader(UI, content)
            activeGamePages[gameName] = pages
            UI.notify("Game", "Loaded " .. gameName, 2, "success")
        else
            -- Create placeholder
            local pages = {}
            for _, tabName in ipairs({"Combat","Movement","Visual","Player","World","Misc"}) do
                local p = UI.scrollPage(content, gameName .. "_" .. tabName)
                UI.section(p, tabName, 1)
                UI.label(p, "Failed to load " .. gameName .. " module", 2)
                UI.label(p, "Error: " .. tostring(loader), 3)
                UI.label(p, "Using Universal fallback", 4)
                pages[tabName] = p
            end
            activeGamePages[gameName] = pages
            UI.notify("Game", gameName .. " load failed — " .. tostring(loader), 3, "error")
        end
    else
        local pages = {}
        for _, tabName in ipairs({"Combat","Movement","Visual","Player","World","Misc"}) do
            local p = UI.scrollPage(content, gameName .. "_" .. tabName)
            UI.section(p, tabName, 1)
            UI.label(p, "Module for " .. gameName .. " coming soon", 2)
            UI.toggle(p, "Placeholder", false, nil, 3)
            pages[tabName] = p
        end
        activeGamePages[gameName] = pages
        UI.notify("Game", gameName .. " — no module yet", 2, "warning")
    end

    if activeTab then
        switchTab(activeTab)
    end
end

---------- TAB SWITCHING ----------
function switchTab(name)
    for _, pages in pairs(activeGamePages) do
        for _, page in pairs(pages) do
            if page then page.Visible = false end
        end
    end
    settingsPage.Visible = false

    if activeTab and tabBtns[activeTab] then
        local old = tabBtns[activeTab]
        UI.tween(old.btn, {BackgroundTransparency = 1}, 0.2)
        UI.tween(old.ind, {BackgroundTransparency = 1}, 0.2)
        if old.icon then UI.tween(old.icon, {ImageColor3 = C.dim}, 0.2) end
        if old.lbl then UI.tween(old.lbl, {TextColor3 = C.dim}, 0.2) end
    end

    activeTab = name
    local cur = tabBtns[name]
    if cur then
        UI.tween(cur.btn, {BackgroundTransparency = 0.85}, 0.2)
        UI.tween(cur.ind, {BackgroundTransparency = 0}, 0.2)
        if cur.icon then UI.tween(cur.icon, {ImageColor3 = C.accent}, 0.2) end
        if cur.lbl then UI.tween(cur.lbl, {TextColor3 = C.text}, 0.2) end
    end

    if name == "Settings" then
        settingsPage.Visible = true
    elseif activeGamePages[currentGame] and activeGamePages[currentGame][name] then
        activeGamePages[currentGame][name].Visible = true
    end
end

---------- BUILD TAB BUTTONS ----------
local tabContainer = Instance.new("Frame", sidebar)
tabContainer.Size = UDim2.new(1, -16, 1, -58)
tabContainer.Position = UDim2.new(0, 8, 0, 54)
tabContainer.BackgroundTransparency = 1
tabContainer.BorderSizePixel = 0
UI.listLayout(tabContainer, 3)

local tabIcons = {
    Combat   = "rbxassetid://137721700219376",
    Movement = "rbxassetid://125699255905634",
    Visual   = "rbxassetid://10596856521",
    Player   = "rbxassetid://18416804485",
    World    = "rbxassetid://11395780614",
    Misc     = "rbxassetid://11435662333",
    Settings = "rbxassetid://183390140",
}

for idx, name in ipairs(TABS) do
    local btn = Instance.new("TextButton", tabContainer)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = C.accent
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.LayoutOrder = idx
    UI.corner(btn, 6)

    local icon = Instance.new("ImageLabel", btn)
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 16, 0, 16)
    icon.Position = UDim2.new(0, 10, 0.5, -8)
    icon.BackgroundTransparency = 1
    icon.Image = tabIcons[name] or ""
    icon.ImageColor3 = C.dim
    icon.ScaleType = Enum.ScaleType.Fit

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -34, 1, 0)
    lbl.Position = UDim2.new(0, 32, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = C.dim
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0, 3, 0.6, 0)
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    indicator.BackgroundColor3 = C.accent
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    UI.corner(indicator, 2)

    btn.MouseEnter:Connect(function()
        if activeTab ~= name then
            UI.tween(btn, {BackgroundTransparency = 0.88}, 0.15)
            UI.tween(icon, {ImageColor3 = C.text}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= name then
            UI.tween(btn, {BackgroundTransparency = 1}, 0.15)
            UI.tween(icon, {ImageColor3 = C.dim}, 0.15)
        end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(name) end)

    tabBtns[name] = {btn = btn, ind = indicator, icon = icon, lbl = lbl}
end

---------- GAME DROPDOWN BUTTONS ----------
for i, gName in ipairs(gameNames) do
    local gb = Instance.new("TextButton", dropFrame)
    gb.Size = UDim2.new(1, -6, 0, 26)
    gb.Position = UDim2.new(0, 3, 0, (i - 1) * 28 + 2)
    gb.BackgroundColor3 = C.sidebar
    gb.BackgroundTransparency = 0.5
    gb.BorderSizePixel = 0
    gb.Text = gName
    gb.TextColor3 = C.text
    gb.Font = Enum.Font.Gotham
    gb.TextSize = 11
    gb.ZIndex = 21
    UI.corner(gb, 4)

    -- Highlight detected game
    if gName == detectGame() then
        gb.TextColor3 = C.accent
        gb.Font = Enum.Font.GothamBold
    end

    gb.MouseEnter:Connect(function() UI.tween(gb, {BackgroundTransparency = 0}, 0.1) end)
    gb.MouseLeave:Connect(function() UI.tween(gb, {BackgroundTransparency = 0.5}, 0.1) end)
    gb.MouseButton1Click:Connect(function()
        dropOpen = false
        dropFrame.Visible = false
        UI.tween(dropFrame, {Size = UDim2.new(1, -16, 0, 0)}, 0.15)
        loadGameModule(gName)
    end)
end

gameFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dropOpen = not dropOpen
        if dropOpen then
            dropFrame.Visible = true
            UI.tween(dropFrame, {Size = UDim2.new(1, -16, 0, math.min(#gameNames * 28 + 4, 180))}, 0.2)
        else
            UI.tween(dropFrame, {Size = UDim2.new(1, -16, 0, 0)}, 0.15)
            task.delay(0.2, function() dropFrame.Visible = false end)
        end
    end
end)

---------- WATERMARK ----------
local watermark = Instance.new("Frame", gui)
watermark.Size = UDim2.new(0, 200, 0, 28)
watermark.Position = UDim2.new(0, 10, 0, 10)
watermark.BackgroundColor3 = C.bg
watermark.BackgroundTransparency = 0.3
watermark.BorderSizePixel = 0
UI.corner(watermark, 6)
UI.stroke(watermark, C.border, 1)

local wmAccent = Instance.new("Frame", watermark)
wmAccent.Size = UDim2.new(0, 3, 0.6, 0)
wmAccent.Position = UDim2.new(0, 6, 0.2, 0)
wmAccent.BackgroundColor3 = C.accent
wmAccent.BorderSizePixel = 0
UI.corner(wmAccent, 2)

local wmText = Instance.new("TextLabel", watermark)
wmText.Size = UDim2.new(1, -18, 1, 0)
wmText.Position = UDim2.new(0, 14, 0, 0)
wmText.BackgroundTransparency = 1
wmText.Font = Enum.Font.GothamSemibold
wmText.TextSize = 11
wmText.TextColor3 = C.text
wmText.TextXAlignment = Enum.TextXAlignment.Left

spawn(function()
    while gui and gui.Parent do
        local fps = math.floor(1 / RunSrv.RenderStepped:Wait())
        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        wmText.Text = string.format("Nexus v%s | %d FPS | %dms | %s", VERSION, fps, ping, os.date("%H:%M"))
        task.wait(0.5)
    end
end)

---------- KEYBINDS ----------
local guiVisible = true
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        guiVisible = not guiVisible
        gui.Enabled = guiVisible
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        minimized = not minimized
        UI.tween(main, {Size = minimized and minSize or fullSize}, 0.3)
        UI.tween(shadow, {Size = minimized and UDim2.new(0, 680, 0, 78) or UDim2.new(0, 680, 0, 480)}, 0.3)
        minBtn.Text = minimized and "+" or "—"
    elseif input.KeyCode == Enum.KeyCode.End then
        -- Panic key
        UI.cleanup()
        gui:Destroy()
    end
end)

---------- TITLE PULSE ----------
spawn(function()
    while gui and gui.Parent do
        UI.tween(title, {TextColor3 = C.accent2}, 2)
        task.wait(2)
        UI.tween(title, {TextColor3 = C.accent}, 2)
        task.wait(2)
    end
end)

---------- INIT ----------
local detectedGame = detectGame()
currentGame = detectedGame

-- Always load universal first (as base)
loadGameModule("Universal")

-- If a specific game was detected, also load its module
if detectedGame ~= "Universal" and GameModules[detectedGame] then
    -- Load game-specific on top
    task.delay(1, function()
        loadGameModule(detectedGame)
    end)
end

switchTab("Combat")

-- Try auto-load config
pcall(function()
    if ConfigSystem.load("autosave") then
        UI.notify("Config", "Auto-loaded previous session", 2, "info")
    end
end)

UI.notify("Nexus", "v" .. VERSION .. " loaded — " .. detectedGame .. " detected", 3, "success")
print("[Nexus v" .. VERSION .. "] Loaded — Game: " .. detectedGame)
