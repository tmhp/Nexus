--[[
    Universal Module — Functional implementations
    Generic exploits targeting the Roblox engine
]]

local Players = game:GetService("Players")
local RunSrv = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LP:GetMouse()

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    -- Combat
    aimbotEnabled = false,
    aimbotTarget = nil,
    aimbotPart = "Head",
    aimbotFov = 180,
    aimbotSmooth = 6,
    aimbotTeamCheck = true,
    aimbotWallCheck = false,
    aimbotKey = Enum.KeyCode.E,
    drawFov = false,
    fovShape = "Circle",

    silentEnabled = false,
    silentMethod = "Raycast",
    silentFov = 120,
    silentTeamCheck = true,
    silentTarget = nil,

    triggerbotEnabled = false,
    triggerDelay = 60,
    autoFire = false,

    -- Movement
    speedHack = false,
    walkSpeed = 80,
    speedMethod = "WalkSpeed",
    flyEnabled = false,
    flySpeed = 100,
    smoothFly = true,
    flyKey = Enum.KeyCode.F,
    infJump = false,
    jumpPower = 100,
    autoJump = false,
    noclip = false,
    noclipKey = Enum.KeyCode.V,
    tpToMouse = false,
    tpKey = Enum.KeyCode.T,
    lowGravity = false,
    gravityValue = 196,

    -- Visual
    espEnabled = false,
    espTeamCheck = true,
    espMaxDist = 2000,
    espRefresh = 33,
    rainbowESP = false,
    boxESP = false,
    boxStyle = "Corner",
    boxThickness = 1,
    nameTag = false,
    displayName = false,
    distTag = false,
    healthBar = false,
    healthBarSide = "Left",
    tracers = false,
    tracerOrigin = "Bottom",
    skeletonESP = false,
    headDot = false,
    chamsEnabled = false,
    chamsType = "Highlight",
    fullbright = false,
    noFog = false,
    noShadows = false,
    customCrosshair = false,
    crosshairStyle = "Cross",
    crosshairSize = 6,
    crosshairGap = 3,
    crosshairThickness = 1,

    -- Player
    godMode = false,
    invisible = false,
    anchored = false,
    autoRespawn = false,
    respawnDelay = 500,

    -- World
    antiAfk = false,
    remoteSpy = false,
    logRemotes = false,
    blockRemotes = false,

    -- Misc
    lagSwitch = false,
    lagKey = Enum.KeyCode.P,
    lagDuration = 500,
    chatSpammer = false,
    spamMessage = "Nexus on top",
    spamDelay = 1000,
    orbitEnabled = false,
    orbitTarget = "",
    orbitRadius = 15,
    orbitSpeed = 5,

    -- Storage
    savedPosition = nil,
}

-- ═══════════════════════════════════════════
-- DRAWING OBJECTS
-- ═══════════════════════════════════════════
local Drawings = {
    fovCircle = nil,
    crosshairLines = {},
    espCache = {},
}

-- ═══════════════════════════════════════════
-- CONNECTIONS (for cleanup)
-- ═══════════════════════════════════════════
local Connections = {}
local function addConn(conn)
    table.insert(Connections, conn)
end

-- ═══════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════
local function getCharacter(player)
    return player and player.Character
end

local function getRoot(player)
    local char = getCharacter(player)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
end

local function getHumanoid(player)
    local char = getCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player)
    local hum = getHumanoid(player)
    return hum and hum.Health > 0
end

local function isTeammate(player)
    if not State.aimbotTeamCheck then return false end
    if not LP.Team or not player.Team then return false end
    return LP.Team == player.Team
end

local function w2s(pos)
    local screen, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

local function getClosestBone(char, targetPart)
    if targetPart == "Closest" then
        local closest, minDist = nil, math.huge
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local screen = w2s(part.Position)
                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local dist = (screen - center).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = part
                end
            end
        end
        return closest
    elseif targetPart == "Random" then
        local parts = {}
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") then table.insert(parts, p) end
        end
        return parts[math.random(#parts)]
    else
        return char:FindFirstChild(targetPart) or char:FindFirstChild("HumanoidRootPart")
    end
end

local function wallCheck(origin, target)
    local ray = Ray.new(origin, (target - origin).Unit * (target - origin).Magnitude)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist

    local ignoreList = {getCharacter(LP)}
    for _, p in ipairs(Players:GetPlayers()) do
        if getCharacter(p) then
            table.insert(ignoreList, getCharacter(p))
        end
    end
    params.FilterDescendantsInstances = ignoreList

    local result = Workspace:Raycast(origin, (target - origin), params)
    return result == nil
end

-- ═══════════════════════════════════════════
-- FOV CIRCLE
-- ═══════════════════════════════════════════
local function createFovCircle()
    if Drawings.fovCircle then
        Drawings.fovCircle:Remove()
    end
    Drawings.fovCircle = Drawing.new("Circle")
    Drawings.fovCircle.Color = Color3.fromRGB(255, 255, 255)
    Drawings.fovCircle.Thickness = 1
    Drawings.fovCircle.Transparency = 0.6
    Drawings.fovCircle.Filled = false
    Drawings.fovCircle.NumSides = 64
    Drawings.fovCircle.Visible = false
end
createFovCircle()

-- ═══════════════════════════════════════════
-- AIMBOT CORE
-- ═══════════════════════════════════════════
local function getBestTarget(fov, teamCheck)
    local best, bestDist = nil, fov
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        if teamCheck and isTeammate(player) then continue end
        if not isAlive(player) then continue end

        local char = getCharacter(player)
        if not char then continue end

        local part = getClosestBone(char, State.aimbotPart)
        if not part then continue end

        local screen, onScreen = w2s(part.Position)
        if not onScreen then continue end

        local dist = (screen - center).Magnitude
        if dist < bestDist then
            if State.aimbotWallCheck and not wallCheck(Camera.CFrame.Position, part.Position) then
                continue
            end
            bestDist = dist
            best = player
        end
    end

    return best
end

-- ═══════════════════════════════════════════
-- ESP DRAWING SYSTEM
-- ═══════════════════════════════════════════
local function getESPColor(player, isEnemy)
    if State.rainbowESP then
        return Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end
    return isEnemy and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 50)
end

local function createESPForPlayer(player)
    if Drawings.espCache[player] then return end

    local esp = {
        box = Drawing.new("Quad"),
        name = Drawing.new("Text"),
        healthBar = Drawing.new("Line"),
        healthBarBg = Drawing.new("Line"),
        distance = Drawing.new("Text"),
        tracer = Drawing.new("Line"),
        headDot = Drawing.new("Circle"),
        skeleton = {},
    }

    -- Box
    esp.box.Thickness = State.boxThickness
    esp.box.Filled = false
    esp.box.Visible = false
    esp.box.Color = Color3.fromRGB(255, 50, 50)

    -- Name
    esp.name.Size = 13
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.Font = 2
    esp.name.Visible = false

    -- Health bar
    esp.healthBar.Thickness = 2
    esp.healthBar.Visible = false
    esp.healthBarBg.Thickness = 4
    esp.healthBarBg.Color = Color3.fromRGB(0, 0, 0)
    esp.healthBarBg.Visible = false

    -- Distance
    esp.distance.Size = 11
    esp.distance.Center = true
    esp.distance.Outline = true
    esp.distance.Font = 2
    esp.distance.Visible = false
    esp.distance.Color = Color3.fromRGB(200, 200, 200)

    -- Tracer
    esp.tracer.Thickness = 1
    esp.tracer.Visible = false

    -- Head dot
    esp.headDot.Radius = 4
    esp.headDot.Filled = true
    esp.headDot.Visible = false
    esp.headDot.Color = Color3.fromRGB(255, 255, 255)

    -- Skeleton lines
    local bonePairs = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"},
    }
    for _, pair in ipairs(bonePairs) do
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Visible = false
        table.insert(esp.skeleton, {line = line, from = pair[1], to = pair[2]})
    end

    Drawings.espCache[player] = esp
end

local function removeESPForPlayer(player)
    local esp = Drawings.espCache[player]
    if not esp then return end

    esp.box:Remove()
    esp.name:Remove()
    esp.healthBar:Remove()
    esp.healthBarBg:Remove()
    esp.distance:Remove()
    esp.tracer:Remove()
    esp.headDot:Remove()
    for _, bone in ipairs(esp.skeleton) do
        bone.line:Remove()
    end
    Drawings.espCache[player] = nil
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end

        local esp = Drawings.espCache[player]
        if not esp then
            createESPForPlayer(player)
            esp = Drawings.espCache[player]
        end
        if not esp then continue end

        local char = getCharacter(player)
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local isEnemy = not isTeammate(player)

        if not State.espEnabled or not char or not root or not hum or hum.Health <= 0 then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.healthBar.Visible = false
            esp.healthBarBg.Visible = false
            esp.distance.Visible = false
            esp.tracer.Visible = false
            esp.headDot.Visible = false
            for _, bone in ipairs(esp.skeleton) do bone.line.Visible = false end
            continue
        end

        if State.espTeamCheck and not isEnemy then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.healthBar.Visible = false
            esp.healthBarBg.Visible = false
            esp.distance.Visible = false
            esp.tracer.Visible = false
            esp.headDot.Visible = false
            for _, bone in ipairs(esp.skeleton) do bone.line.Visible = false end
            continue
        end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > State.espMaxDist then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.healthBar.Visible = false
            esp.healthBarBg.Visible = false
            esp.distance.Visible = false
            esp.tracer.Visible = false
            esp.headDot.Visible = false
            for _, bone in ipairs(esp.skeleton) do bone.line.Visible = false end
            continue
        end

        local rootPos, onScreen = w2s(root.Position)
        if not onScreen then
            esp.box.Visible = false
            esp.name.Visible = false
            esp.healthBar.Visible = false
            esp.healthBarBg.Visible = false
            esp.distance.Visible = false
            esp.tracer.Visible = false
            esp.headDot.Visible = false
            for _, bone in ipairs(esp.skeleton) do bone.line.Visible = false end
            continue
        end

        local color = getESPColor(player, isEnemy)

        -- Calculate box bounds
        local headTop = head and w2s(head.Position + Vector3.new(0, 1.5, 0)) or rootPos
        local feetPos = w2s(root.Position - Vector3.new(0, 3, 0))
        local boxHeight = math.abs(feetPos.Y - headTop.Y)
        local boxWidth = boxHeight * 0.55

        -- BOX ESP
        if State.boxESP then
            local cx = (headTop.X + feetPos.X) / 2

            if State.boxStyle == "Corner" then
                -- Draw corner box using quad (approximate)
                esp.box.PointA = Vector2.new(cx - boxWidth / 2, headTop.Y)
                esp.box.PointB = Vector2.new(cx + boxWidth / 2, headTop.Y)
                esp.box.PointC = Vector2.new(cx + boxWidth / 2, feetPos.Y)
                esp.box.PointD = Vector2.new(cx - boxWidth / 2, feetPos.Y)
            else
                esp.box.PointA = Vector2.new(cx - boxWidth / 2, headTop.Y)
                esp.box.PointB = Vector2.new(cx + boxWidth / 2, headTop.Y)
                esp.box.PointC = Vector2.new(cx + boxWidth / 2, feetPos.Y)
                esp.box.PointD = Vector2.new(cx - boxWidth / 2, feetPos.Y)
            end
            esp.box.Color = color
            esp.box.Thickness = State.boxThickness
            esp.box.Visible = true
        else
            esp.box.Visible = false
        end

        -- NAME TAGS
        if State.nameTag then
            local displayText = State.displayName and player.DisplayName or player.Name
            esp.name.Text = displayText
            esp.name.Position = Vector2.new((headTop.X + feetPos.X) / 2, headTop.Y - 16)
            esp.name.Color = color
            esp.name.Visible = true
        else
            esp.name.Visible = false
        end

        -- DISTANCE TAG
        if State.distTag then
            esp.distance.Text = math.floor(dist) .. "m"
            esp.distance.Position = Vector2.new((headTop.X + feetPos.X) / 2, feetPos.Y + 2)
            esp.distance.Visible = true
        else
            esp.distance.Visible = false
        end

        -- HEALTH BAR
        if State.healthBar then
            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local cx = (headTop.X + feetPos.X) / 2
            local barX = cx - boxWidth / 2 - 6

            esp.healthBarBg.From = Vector2.new(barX, feetPos.Y)
            esp.healthBarBg.To = Vector2.new(barX, headTop.Y)
            esp.healthBarBg.Visible = true

            local barTop = feetPos.Y - (feetPos.Y - headTop.Y) * hp
            esp.healthBar.From = Vector2.new(barX, feetPos.Y)
            esp.healthBar.To = Vector2.new(barX, barTop)
            esp.healthBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
            esp.healthBar.Visible = true
        else
            esp.healthBar.Visible = false
            esp.healthBarBg.Visible = false
        end

        -- TRACERS
        if State.tracers then
            local originPos
            if State.tracerOrigin == "Bottom" then
                originPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            elseif State.tracerOrigin == "Center" then
                originPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            elseif State.tracerOrigin == "Mouse" then
                originPos = Vector2.new(Mouse.X, Mouse.Y)
            else
                originPos = Vector2.new(Camera.ViewportSize.X / 2, 0)
            end
            esp.tracer.From = originPos
            esp.tracer.To = feetPos
            esp.tracer.Color = color
            esp.tracer.Visible = true
        else
            esp.tracer.Visible = false
        end

        -- HEAD DOT
        if State.headDot and head then
            local headScreen, headOnScreen = w2s(head.Position)
            if headOnScreen then
                esp.headDot.Position = headScreen
                esp.headDot.Color = color
                esp.headDot.Visible = true
            else
                esp.headDot.Visible = false
            end
        else
            esp.headDot.Visible = false
        end

        -- SKELETON
        if State.skeletonESP then
            for _, bone in ipairs(esp.skeleton) do
                local fromPart = char:FindFirstChild(bone.from)
                local toPart = char:FindFirstChild(bone.to)
                if fromPart and toPart then
                    local fromScreen, fromOn = w2s(fromPart.Position)
                    local toScreen, toOn = w2s(toPart.Position)
                    if fromOn and toOn then
                        bone.line.From = fromScreen
                        bone.line.To = toScreen
                        bone.line.Color = color
                        bone.line.Visible = true
                    else
                        bone.line.Visible = false
                    end
                else
                    bone.line.Visible = false
                end
            end
        else
            for _, bone in ipairs(esp.skeleton) do bone.line.Visible = false end
        end
    end
end

-- ═══════════════════════════════════════════
-- CROSSHAIR
-- ═══════════════════════════════════════════
local function createCrosshair()
    for _, line in ipairs(Drawings.crosshairLines) do line:Remove() end
    Drawings.crosshairLines = {}

    if State.crosshairStyle == "Cross" or State.crosshairStyle == "Cross+Dot" then
        for i = 1, 4 do
            local line = Drawing.new("Line")
            line.Color = Color3.fromRGB(0, 255, 255)
            line.Thickness = State.crosshairThickness
            line.Visible = false
            table.insert(Drawings.crosshairLines, line)
        end
    end
    if State.crosshairStyle == "Dot" or State.crosshairStyle == "Cross+Dot" then
        local dot = Drawing.new("Circle")
        dot.Radius = 2
        dot.Filled = true
        dot.Color = Color3.fromRGB(0, 255, 255)
        dot.Visible = false
        table.insert(Drawings.crosshairLines, dot)
    end
    if State.crosshairStyle == "Circle" then
        local circ = Drawing.new("Circle")
        circ.Radius = State.crosshairSize
        circ.Filled = false
        circ.Color = Color3.fromRGB(0, 255, 255)
        circ.Thickness = State.crosshairThickness
        circ.Visible = false
        table.insert(Drawings.crosshairLines, circ)
    end
end

local function updateCrosshair()
    if not State.customCrosshair then
        for _, d in ipairs(Drawings.crosshairLines) do d.Visible = false end
        return
    end

    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y / 2
    local sz = State.crosshairSize
    local gap = State.crosshairGap

    if State.crosshairStyle == "Cross" or State.crosshairStyle == "Cross+Dot" then
        if Drawings.crosshairLines[1] then
            Drawings.crosshairLines[1].From = Vector2.new(cx - gap - sz, cy)
            Drawings.crosshairLines[1].To = Vector2.new(cx - gap, cy)
            Drawings.crosshairLines[1].Visible = true
        end
        if Drawings.crosshairLines[2] then
            Drawings.crosshairLines[2].From = Vector2.new(cx + gap, cy)
            Drawings.crosshairLines[2].To = Vector2.new(cx + gap + sz, cy)
            Drawings.crosshairLines[2].Visible = true
        end
        if Drawings.crosshairLines[3] then
            Drawings.crosshairLines[3].From = Vector2.new(cx, cy - gap - sz)
            Drawings.crosshairLines[3].To = Vector2.new(cx, cy - gap)
            Drawings.crosshairLines[3].Visible = true
        end
        if Drawings.crosshairLines[4] then
            Drawings.crosshairLines[4].From = Vector2.new(cx, cy + gap)
            Drawings.crosshairLines[4].To = Vector2.new(cx, cy + gap + sz)
            Drawings.crosshairLines[4].Visible = true
        end
    end

    -- Handle dot/circle elements
    for i, d in ipairs(Drawings.crosshairLines) do
        if d.ClassName == "Circle" then
            d.Position = Vector2.new(cx, cy)
            d.Visible = true
        end
    end
end

-- ═══════════════════════════════════════════
-- CHAMS
-- ═══════════════════════════════════════════
local chamsCache = {}

local function updateChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        local char = getCharacter(player)

        if State.chamsEnabled and char and isAlive(player) then
            if not chamsCache[player] then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0.3
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = char
                highlight.Parent = char
                chamsCache[player] = highlight
            end
        else
            if chamsCache[player] then
                chamsCache[player]:Destroy()
                chamsCache[player] = nil
            end
        end
    end
end

-- ═══════════════════════════════════════════
-- SILENT AIM (Hooks)
-- ═══════════════════════════════════════════
local oldNamecall
local oldIndex

local function setupSilentAim()
    if oldNamecall then return end -- Already hooked

    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if State.silentEnabled then
            -- Hook FindPartOnRay / FindPartOnRayWithIgnoreList / Raycast
            if method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "Raycast" then
                local target = getBestTarget(State.silentFov, State.silentTeamCheck)
                if target then
                    local char = getCharacter(target)
                    if char then
                        local part = char:FindFirstChild(State.aimbotPart) or char:FindFirstChild("Head")
                        if part then
                            local origin = Camera.CFrame.Position
                            local direction = (part.Position - origin).Unit * 1000

                            if method == "Raycast" then
                                -- Modify raycast direction
                                args[1] = origin
                                args[2] = direction
                            else
                                args[1] = Ray.new(origin, direction)
                            end
                        end
                    end
                end
            end
        end

        return oldNamecall(self, unpack(args))
    end)

    -- Hook Mouse.Hit for silent aim method "Mouse.Hit"
    if State.silentMethod == "Mouse.Hit" or State.silentMethod == "Both" then
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if State.silentEnabled then
                if self == Mouse and (key == "Hit" or key == "Target") then
                    local target = getBestTarget(State.silentFov, State.silentTeamCheck)
                    if target then
                        local char = getCharacter(target)
                        if char then
                            local part = char:FindFirstChild(State.aimbotPart) or char:FindFirstChild("Head")
                            if part then
                                if key == "Hit" then
                                    return part.CFrame
                                elseif key == "Target" then
                                    return part
                                end
                            end
                        end
                    end
                end
            end
            return oldIndex(self, key)
        end)
    end
end

-- ═══════════════════════════════════════════
-- REMOTE SPY
-- ═══════════════════════════════════════════
local remoteSpyHook

local function setupRemoteSpy()
    if remoteSpyHook then return end

    remoteSpyHook = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if (method == "FireServer" or method == "InvokeServer") and State.remoteSpy then
            if State.logRemotes then
                local remoteName = self.Name or "Unknown"
                local argStr = ""
                for i, arg in ipairs(args) do
                    argStr = argStr .. tostring(arg) .. (i < #args and ", " or "")
                end
                print(string.format("[RemoteSpy] %s:%s(%s)", method, remoteName, argStr))
            end

            if State.blockRemotes then
                return nil
            end
        end

        return remoteSpyHook(self, ...)
    end)
end

-- ═══════════════════════════════════════════
-- MAIN LOOPS
-- ═══════════════════════════════════════════

-- RenderStepped loop (visuals + aim)
addConn(RunSrv.RenderStepped:Connect(function(dt)
    -- FOV Circle
    if Drawings.fovCircle then
        if State.drawFov and State.aimbotEnabled then
            Drawings.fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            Drawings.fovCircle.Radius = State.aimbotFov
            Drawings.fovCircle.Visible = true
        else
            Drawings.fovCircle.Visible = false
        end
    end

    -- Aimbot
    if State.aimbotEnabled and UIS:IsKeyDown(State.aimbotKey) then
        local target = getBestTarget(State.aimbotFov, State.aimbotTeamCheck)
        if target then
            local char = getCharacter(target)
            if char then
                local part = getClosestBone(char, State.aimbotPart)
                if part then
                    local targetCF = CFrame.new(Camera.CFrame.Position, part.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / State.aimbotSmooth)
                end
            end
        end
    end

    -- Crosshair
    updateCrosshair()

    -- ESP (throttled)
    updateESP()
end))

-- Heartbeat loop (gameplay logic)
addConn(RunSrv.Heartbeat:Connect(function(dt)
    local char = getCharacter(LP)
    if not char then return end
    local hum = getHumanoid(LP)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    -- Speed hack
    if State.speedHack then
        if State.speedMethod == "WalkSpeed" then
            hum.WalkSpeed = State.walkSpeed
        elseif State.speedMethod == "CFrame" then
            if hum.MoveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + hum.MoveDirection * (State.walkSpeed / 50) * dt
            end
        elseif State.speedMethod == "Velocity" then
            if hum.MoveDirection.Magnitude > 0 then
                root.Velocity = hum.MoveDirection * State.walkSpeed + Vector3.new(0, root.Velocity.Y, 0)
            end
        end
    end

    -- Fly
    if State.flyEnabled then
        local bp = root:FindFirstChild("NexusFlyBP")
        local bg = root:FindFirstChild("NexusFlyBG")

        if not bp then
            bp = Instance.new("BodyPosition")
            bp.Name = "NexusFlyBP"
            bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bp.D = State.smoothFly and 200 or 50
            bp.P = State.smoothFly and 5000 or 20000
            bp.Parent = root
        end
        if not bg then
            bg = Instance.new("BodyGyro")
            bg.Name = "NexusFlyBG"
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.D = 200
            bg.P = 5000
            bg.Parent = root
        end

        local moveDir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
        end

        bp.Position = root.Position + moveDir * State.flySpeed * dt * 2
        bg.CFrame = Camera.CFrame
        hum.PlatformStand = true
    else
        local bp = root:FindFirstChild("NexusFlyBP")
        local bg = root:FindFirstChild("NexusFlyBG")
        if bp then bp:Destroy() end
        if bg then bg:Destroy() end
        if hum.PlatformStand then hum.PlatformStand = false end
    end

    -- Noclip
    if State.noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- God Mode (client-side: constantly set health)
    if State.godMode then
        hum.Health = hum.MaxHealth
    end

    -- Low Gravity
    if State.lowGravity then
        Workspace.Gravity = State.gravityValue
    end

    -- Invisible
    if State.invisible then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
    end

    -- Orbit
    if State.orbitEnabled and State.orbitTarget ~= "" then
        local targetPlayer = Players:FindFirstChild(State.orbitTarget)
        if targetPlayer then
            local targetRoot = getRoot(targetPlayer)
            if targetRoot then
                local angle = tick() * State.orbitSpeed
                local offset = Vector3.new(
                    math.cos(angle) * State.orbitRadius,
                    0,
                    math.sin(angle) * State.orbitRadius
                )
                root.CFrame = CFrame.new(targetRoot.Position + offset, targetRoot.Position)
            end
        end
    end

    -- Chams
    updateChams()
end))

-- Infinite jump
addConn(UIS.JumpRequest:Connect(function()
    if State.infJump then
        local hum = getHumanoid(LP)
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

-- Key binds
addConn(UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == State.flyKey then
        State.flyEnabled = not State.flyEnabled
    elseif input.KeyCode == State.noclipKey then
        State.noclip = not State.noclip
    elseif input.KeyCode == State.tpKey and State.tpToMouse then
        local char = getCharacter(LP)
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 5, 0))
        end
    elseif input.KeyCode == State.lagKey and State.lagSwitch then
        -- Temporarily disable network
        local nc = LP:FindFirstChildOfClass("PlayerScripts")
        settings():GetService("NetworkSettings").IncomingReplicationLag = State.lagDuration / 1000
        task.delay(State.lagDuration / 1000, function()
            settings():GetService("NetworkSettings").IncomingReplicationLag = 0
        end)
    end
end))

-- Triggerbot
spawn(function()
    while true do
        if State.triggerbotEnabled then
            local target = Mouse.Target
            if target then
                local model = target:FindFirstAncestorOfClass("Model")
                if model then
                    local player = Players:GetPlayerFromCharacter(model)
                    if player and player ~= LP then
                        local shouldFire = true
                        if State.aimbotTeamCheck and isTeammate(player) then
                            shouldFire = false
                        end
                        if shouldFire then
                            task.wait(State.triggerDelay / 1000)
                            mouse1click()
                        end
                    end
                end
            end
        end
        task.wait(0.01)
    end
end)

-- Anti AFK
spawn(function()
    while true do
        if State.antiAfk then
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
        task.wait(60)
    end
end)

-- Chat Spammer
spawn(function()
    while true do
        if State.chatSpammer and State.spamMessage ~= "" then
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest"):FireServer(State.spamMessage, "All")
            end)
        end
        task.wait(State.spamDelay / 1000)
    end
end)

-- Fullbright / No Fog
addConn(RunSrv.RenderStepped:Connect(function()
    if State.fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end
    if State.noFog then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
    end
    if State.noShadows then
        Lighting.GlobalShadows = false
    end
end))

-- Auto respawn
addConn(LP.CharacterRemoving:Connect(function()
    if State.autoRespawn then
        task.wait(State.respawnDelay / 1000)
        -- Force respawn
        pcall(function()
            LP:LoadCharacter()
        end)
    end
end))

-- ═══════════════════════════════════════════
-- GUI LOADER
-- ═══════════════════════════════════════════

local function load(UI, contentArea)
    local pages = {}

    -- Setup hooks
    pcall(setupSilentAim)
    pcall(setupRemoteSpy)

    ---------------------------------------------------------------------------
    -- COMBAT
    ---------------------------------------------------------------------------
    local c = UI.scrollPage(contentArea, "UNI_Combat")

    UI.section(c, "Aimbot (Generic)", 1)
    UI.toggle(c, "Aimbot Enabled", false, function(v) State.aimbotEnabled = v end, 2)
    UI.dropdown(c, "Target Part", {"Head","Torso","HumanoidRootPart","Closest","Random"}, "Head", function(v) State.aimbotPart = v end, 3)
    UI.slider(c, "FOV Radius", 20, 800, 180, function(v) State.aimbotFov = v end, 4)
    UI.toggle(c, "Draw FOV Circle", false, function(v) State.drawFov = v end, 5)
    UI.dropdown(c, "FOV Shape", {"Circle","Square"}, "Circle", function(v) State.fovShape = v end, 6)
    UI.slider(c, "Smoothing", 1, 50, 6, function(v) State.aimbotSmooth = v end, 7)
    UI.toggle(c, "Team Check", true, function(v) State.aimbotTeamCheck = v end, 8)
    UI.toggle(c, "Wall Check", false, function(v) State.aimbotWallCheck = v end, 9)
    UI.keybind(c, "Aim Key", Enum.KeyCode.E, function(v) State.aimbotKey = v end, 11)

    UI.section(c, "Silent Aim", 15)
    UI.toggle(c, "Silent Aim Enabled", false, function(v) State.silentEnabled = v end, 16)
    UI.dropdown(c, "Silent Method", {"Raycast","Mouse.Hit","Both"}, "Raycast", function(v) State.silentMethod = v end, 17)
    UI.slider(c, "Silent FOV", 20, 600, 120, function(v) State.silentFov = v end, 18)
    UI.toggle(c, "Silent Team Check", true, function(v) State.silentTeamCheck = v end, 19)

    UI.section(c, "Triggerbot", 21)
    UI.toggle(c, "Triggerbot", false, function(v) State.triggerbotEnabled = v end, 22)
    UI.slider(c, "Trigger Delay (ms)", 0, 500, 60, function(v) State.triggerDelay = v end, 23)

    pages.Combat = c

    ---------------------------------------------------------------------------
    -- MOVEMENT
    ---------------------------------------------------------------------------
    local m = UI.scrollPage(contentArea, "UNI_Movement")

    UI.section(m, "Speed", 1)
    UI.toggle(m, "Speed Hack", false, function(v) State.speedHack = v end, 2)
    UI.slider(m, "Walk Speed", 16, 500, 80, function(v) State.walkSpeed = v end, 3)
    UI.dropdown(m, "Speed Method", {"WalkSpeed","CFrame","Velocity"}, "WalkSpeed", function(v) State.speedMethod = v end, 4)

    UI.section(m, "Flight", 6)
    UI.toggle(m, "Fly", false, function(v) State.flyEnabled = v end, 7)
    UI.slider(m, "Fly Speed", 10, 800, 100, function(v) State.flySpeed = v end, 8)
    UI.toggle(m, "Smooth Fly", true, function(v) State.smoothFly = v end, 9)
    UI.keybind(m, "Fly Toggle Key", Enum.KeyCode.F, function(v) State.flyKey = v end, 10)

    UI.section(m, "Jump", 12)
    UI.toggle(m, "Infinite Jump", false, function(v) State.infJump = v end, 13)
    UI.slider(m, "Jump Power", 50, 600, 100, function(v)
        State.jumpPower = v
        local hum = getHumanoid(LP)
        if hum then hum.JumpPower = v end
    end, 14)

    UI.section(m, "Misc Movement", 18)
    UI.toggle(m, "Noclip", false, function(v) State.noclip = v end, 19)
    UI.keybind(m, "Noclip Key", Enum.KeyCode.V, function(v) State.noclipKey = v end, 20)
    UI.toggle(m, "TP to Mouse (Click)", false, function(v) State.tpToMouse = v end, 23)
    UI.keybind(m, "TP Key", Enum.KeyCode.T, function(v) State.tpKey = v end, 24)
    UI.slider(m, "Gravity Override", 0, 400, 196, function(v) State.gravityValue = v end, 25)
    UI.toggle(m, "Low Gravity", false, function(v)
        State.lowGravity = v
        if not v then Workspace.Gravity = 196.2 end
    end, 26)

    pages.Movement = m

    ---------------------------------------------------------------------------
    -- VISUAL
    ---------------------------------------------------------------------------
    local v = UI.scrollPage(contentArea, "UNI_Visual")

    UI.section(v, "ESP — Master", 1)
    UI.toggle(v, "ESP Enabled", false, function(val) State.espEnabled = val end, 2)
    UI.toggle(v, "Team Check", true, function(val) State.espTeamCheck = val end, 3)
    UI.slider(v, "Max Render Distance", 100, 10000, 2000, function(val) State.espMaxDist = val end, 4)
    UI.toggle(v, "Rainbow ESP", false, function(val) State.rainbowESP = val end, 6)

    UI.section(v, "ESP — Boxes", 8)
    UI.toggle(v, "Box ESP", false, function(val) State.boxESP = val end, 9)
    UI.dropdown(v, "Box Style", {"2D Full","Corner","3D Wire"}, "Corner", function(val) State.boxStyle = val end, 10)
    UI.slider(v, "Box Thickness", 1, 5, 1, function(val) State.boxThickness = val end, 11)

    UI.section(v, "ESP — Tags", 18)
    UI.toggle(v, "Name Tags", false, function(val) State.nameTag = val end, 19)
    UI.toggle(v, "Display Name", false, function(val) State.displayName = val end, 20)
    UI.toggle(v, "Distance Tag", false, function(val) State.distTag = val end, 21)

    UI.section(v, "ESP — Health", 27)
    UI.toggle(v, "Health Bar", false, function(val) State.healthBar = val end, 28)
    UI.dropdown(v, "Health Bar Side", {"Left","Right","Top","Bottom"}, "Left", function(val) State.healthBarSide = val end, 29)

    UI.section(v, "ESP — Tracers", 34)
    UI.toggle(v, "Tracers", false, function(val) State.tracers = val end, 35)
    UI.dropdown(v, "Tracer Origin", {"Bottom","Center","Mouse","Top"}, "Bottom", function(val) State.tracerOrigin = val end, 36)

    UI.section(v, "ESP — Skeleton", 40)
    UI.toggle(v, "Skeleton ESP", false, function(val) State.skeletonESP = val end, 41)

    UI.section(v, "ESP — Head Dot", 45)
    UI.toggle(v, "Head Dot", false, function(val) State.headDot = val end, 46)

    UI.section(v, "Chams", 51)
    UI.toggle(v, "Player Chams", false, function(val)
        State.chamsEnabled = val
        if not val then
            for p, h in pairs(chamsCache) do
                h:Destroy()
                chamsCache[p] = nil
            end
        end
    end, 52)

    UI.section(v, "Rendering", 59)
    UI.toggle(v, "Fullbright", false, function(val) State.fullbright = val end, 60)
    UI.toggle(v, "No Fog", false, function(val) State.noFog = val end, 61)
    UI.toggle(v, "No Shadows", false, function(val) State.noShadows = val end, 62)

    UI.section(v, "Crosshair", 67)
    UI.toggle(v, "Custom Crosshair", false, function(val)
        State.customCrosshair = val
        createCrosshair()
    end, 68)
    UI.dropdown(v, "Crosshair Style", {"Cross","Dot","Circle","Cross+Dot"}, "Cross", function(val)
        State.crosshairStyle = val
        createCrosshair()
    end, 69)
    UI.slider(v, "Crosshair Size", 2, 20, 6, function(val) State.crosshairSize = val end, 70)
    UI.slider(v, "Crosshair Gap", 0, 15, 3, function(val) State.crosshairGap = val end, 71)
    UI.slider(v, "Crosshair Thickness", 1, 4, 1, function(val) State.crosshairThickness = val end, 72)

    pages.Visual = v

    ---------------------------------------------------------------------------
    -- PLAYER
    ---------------------------------------------------------------------------
    local pl = UI.scrollPage(contentArea, "UNI_Player")

    UI.section(pl, "Character", 1)
    UI.toggle(pl, "God Mode (Client)", false, function(val) State.godMode = val end, 2)
    UI.toggle(pl, "Invisible (Client)", false, function(val)
        State.invisible = val
        if not val then
            local char = getCharacter(LP)
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0
                    end
                end
            end
        end
    end, 4)
    UI.button(pl, "Reset Character", function()
        local hum = getHumanoid(LP)
        if hum then hum.Health = 0 end
    end, 6)

    UI.section(pl, "Teleport", 19)
    UI.textbox(pl, "Player Name", "username...", function(val)
        -- Store for use
        State._tpPlayerName = val
    end, 20)
    UI.button(pl, "Teleport to Player", function()
        local name = State._tpPlayerName or ""
        for _, p in ipairs(Players:GetPlayers()) do
            if string.lower(p.Name):find(string.lower(name)) then
                local theirRoot = getRoot(p)
                local myRoot = getRoot(LP)
                if theirRoot and myRoot then
                    myRoot.CFrame = theirRoot.CFrame * CFrame.new(0, 0, 5)
                end
                break
            end
        end
    end, 21)
    UI.button(pl, "Save Position", function()
        local root = getRoot(LP)
        if root then
            State.savedPosition = root.CFrame
            UI.notify("Player", "Position saved", 2, "success")
        end
    end, 25)
    UI.button(pl, "Load Saved Position", function()
        if State.savedPosition then
            local root = getRoot(LP)
            if root then
                root.CFrame = State.savedPosition
            end
        end
    end, 26)

    pages.Player = pl

    ---------------------------------------------------------------------------
    -- WORLD
    ---------------------------------------------------------------------------
    local w = UI.scrollPage(contentArea, "UNI_World")

    UI.section(w, "Server", 1)
    UI.toggle(w, "Anti-AFK", false, function(val) State.antiAfk = val end, 2)
    UI.button(w, "Server Hop", function()
        local servers = HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        ))
        for _, server in ipairs(servers.data or {}) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LP)
                break
            end
        end
    end, 3)
    UI.button(w, "Rejoin", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end, 4)

    UI.section(w, "Spy", 28)
    UI.toggle(w, "Remote Spy", false, function(val) State.remoteSpy = val end, 29)
    UI.toggle(w, "Log Remote Calls", false, function(val) State.logRemotes = val end, 30)
    UI.toggle(w, "Block Remote Calls", false, function(val) State.blockRemotes = val end, 31)

    pages.World = w

    ---------------------------------------------------------------------------
    -- MISC
    ---------------------------------------------------------------------------
    local mi = UI.scrollPage(contentArea, "UNI_Misc")

    UI.section(mi, "Performance", 1)
    UI.toggle(mi, "Lag Switch", false, function(val) State.lagSwitch = val end, 4)
    UI.keybind(mi, "Lag Switch Key", Enum.KeyCode.P, function(val) State.lagKey = val end, 5)
    UI.slider(mi, "Lag Duration (ms)", 100, 5000, 500, function(val) State.lagDuration = val end, 6)

    UI.section(mi, "Chat", 8)
    UI.toggle(mi, "Chat Spammer", false, function(val) State.chatSpammer = val end, 9)
    UI.textbox(mi, "Spam Message", "Nexus on top", function(val) State.spamMessage = val end, 10)
    UI.slider(mi, "Spam Delay (ms)", 100, 5000, 1000, function(val) State.spamDelay = val end, 11)

    UI.section(mi, "Player Trolling", 15)
    UI.toggle(mi, "Orbit Player", false, function(val) State.orbitEnabled = val end, 17)
    UI.textbox(mi, "Orbit Target", "username...", function(val) State.orbitTarget = val end, 18)
    UI.slider(mi, "Orbit Radius", 5, 50, 15, function(val) State.orbitRadius = val end, 19)
    UI.slider(mi, "Orbit Speed", 1, 20, 5, function(val) State.orbitSpeed = val end, 20)

    pages.Misc = mi

    return pages
end

return load
