--[[
    Phantom Forces Module — Fixed with proper nil guards
    All executor-specific functions wrapped in availability checks
]]

local Players = game:GetService("Players")
local RunSrv = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ═══════════════════════════════════════════
-- EXECUTOR CAPABILITY CHECK
-- ═══════════════════════════════════════════
local hasDrawing = pcall(function() return Drawing and Drawing.new end)
local hasHookMeta = typeof(hookmetamethod) == "function"
local hasNewCClosure = typeof(newcclosure) == "function"
local hasMouse1Click = typeof(mouse1click) == "function"
local hasGetNamecallMethod = typeof(getnamecallmethod) == "function"

local function safeDrawNew(class)
    if not hasDrawing then return nil end
    local ok, obj = pcall(Drawing.new, class)
    return ok and obj or nil
end

-- ═══════════════════════════════════════════
-- PF CHARACTER SYSTEM
-- ═══════════════════════════════════════════
-- PF stores characters in multiple possible locations

local function getPFCharFolder()
    return Workspace:FindFirstChild("Characters")
        or Workspace:FindFirstChild("Ignore")
        or Workspace
end

local function getPFChar(player)
    if not player then return nil end

    -- Method 1: Check Characters folder
    local charFolder = Workspace:FindFirstChild("Characters")
    if charFolder then
        local char = charFolder:FindFirstChild(player.Name)
        if char then return char end
    end

    -- Method 2: Check Ignore folder (some PF versions)
    local ignore = Workspace:FindFirstChild("Ignore")
    if ignore then
        local char = ignore:FindFirstChild(player.Name)
        if char then return char end
    end

    -- Method 3: Standard character
    if player.Character then
        return player.Character
    end

    -- Method 4: Search workspace directly
    local char = Workspace:FindFirstChild(player.Name)
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char
    end

    return nil
end

local function getPFRoot(player)
    local char = getPFChar(player)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

local function getPFHead(player)
    local char = getPFChar(player)
    if not char then return nil end
    return char:FindFirstChild("Head")
end

local function getPFHumanoid(player)
    local char = getPFChar(player)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function isPFAlive(player)
    local char = getPFChar(player)
    if not char then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then return true end

    -- Some PF versions don't use standard humanoid health
    local root = char:FindFirstChild("HumanoidRootPart")
    return root ~= nil
end

local function isTeammate(player)
    if not player or not LP then return false end
    if not LP.Team or not player.Team then return false end
    return LP.Team == player.Team
end

-- ═══════════════════════════════════════════
-- PF BONE MAPPING
-- ═══════════════════════════════════════════
local function getPFBone(char, boneName)
    if not char then return nil end

    local boneMap = {
        Head = {"Head"},
        Torso = {"UpperTorso", "Torso", "HumanoidRootPart"},
        Pelvis = {"LowerTorso", "Torso", "HumanoidRootPart"},
        Closest = nil, -- handled separately
    }

    if boneName == "Closest" then
        -- Return closest visible part to screen center
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local closest, minDist = nil, math.huge
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = part
                    end
                end
            end
        end
        return closest
    end

    local candidates = boneMap[boneName] or {"Head"}
    for _, name in ipairs(candidates) do
        local part = char:FindFirstChild(name)
        if part then return part end
    end

    -- Fallback: any BasePart
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then return part end
    end

    return nil
end

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    aimbotEnabled = false,
    targetBone = "Head",
    fov = 120,
    drawFov = false,
    smooth = 6,
    prediction = false,
    teamCheck = true,
    wallCheck = true,
    aimKey = Enum.KeyCode.E,

    silentAim = false,
    silentFov = 150,

    triggerbot = false,
    triggerDelay = 40,

    noRecoil = false,
    noSpread = false,
    noSway = false,

    espEnabled = false,
    boxESP = false,
    boxStyle = "Corner",
    nameTag = false,
    healthBar = false,
    distTag = false,
    tracers = false,
    tracerOrigin = "Bottom",
    chamsEnabled = false,
    crosshair = false,
    crosshairStyle = "Cross+Dot",
    crosshairSize = 8,
    crosshairThick = 2,
    fullbright = false,
    noFog = false,
    noParticles = false,
    noScope = false,
    removeDebris = false,
    wallhack = false,
    wallOpacity = 30,

    noFlash = false,
    noFlinch = false,
    antiSuppression = false,

    antiAfk = false,
    killSound = false,
    killSoundId = "",
}

-- ═══════════════════════════════════════════
-- DRAWING CACHE
-- ═══════════════════════════════════════════
local Draw = {
    fov = nil,
    crosshairLines = {},
    espCache = {},
}

local Connections = {}
local chamsCache = {}

local function addConn(c)
    if c then table.insert(Connections, c) end
end

local function w2s(pos)
    if not Camera then
        Camera = Workspace.CurrentCamera
        if not Camera then return Vector2.new(0, 0), false, 0 end
    end
    local screen, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

-- ═══════════════════════════════════════════
-- FOV CIRCLE (Drawing API)
-- ═══════════════════════════════════════════
if hasDrawing then
    Draw.fov = safeDrawNew("Circle")
    if Draw.fov then
        Draw.fov.Thickness = 1
        Draw.fov.Color = Color3.fromRGB(255, 255, 255)
        Draw.fov.Transparency = 0.6
        Draw.fov.Filled = false
        Draw.fov.NumSides = 64
        Draw.fov.Visible = false
    end
end

-- ═══════════════════════════════════════════
-- AIMBOT TARGET FINDER
-- ═══════════════════════════════════════════
local function getBestTarget(fovRadius, doTeamCheck)
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return nil end

    local best, bestDist = nil, fovRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        if doTeamCheck and isTeammate(player) then continue end
        if not isPFAlive(player) then continue end

        local char = getPFChar(player)
        if not char then continue end

        local part = getPFBone(char, State.targetBone)
        if not part then continue end

        local pos = part.Position

        -- Aim prediction
        if State.prediction then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local myChar = LP.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local dist = (myRoot.Position - root.Position).Magnitude
                    local travelTime = dist / 2000
                    pos = pos + root.Velocity * travelTime
                end
            end
        end

        local screen, onScreen = w2s(pos)
        if not onScreen then continue end

        local dist = (screen - center).Magnitude
        if dist < bestDist then
            -- Wall check
            if State.wallCheck then
                local origin = Camera.CFrame.Position
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Blacklist

                local ignoreList = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    local c = getPFChar(p)
                    if c then table.insert(ignoreList, c) end
                end
                -- Also ignore character folders
                local charFolder = Workspace:FindFirstChild("Characters")
                if charFolder then table.insert(ignoreList, charFolder) end
                local ignoreFolder = Workspace:FindFirstChild("Ignore")
                if ignoreFolder then table.insert(ignoreList, ignoreFolder) end

                params.FilterDescendantsInstances = ignoreList
                local result = Workspace:Raycast(origin, (pos - origin).Unit * (pos - origin).Magnitude, params)
                if result then continue end
            end

            bestDist = dist
            best = {player = player, part = part, position = pos}
        end
    end

    return best
end

-- ═══════════════════════════════════════════
-- ESP SYSTEM (Drawing API)
-- ═══════════════════════════════════════════
local function createESP(player)
    if not hasDrawing then return end
    if Draw.espCache[player] then return end

    local esp = {}

    esp.box = safeDrawNew("Quad")
    esp.name = safeDrawNew("Text")
    esp.healthBar = safeDrawNew("Line")
    esp.healthBarBg = safeDrawNew("Line")
    esp.distance = safeDrawNew("Text")
    esp.tracer = safeDrawNew("Line")

    -- Configure if created successfully
    if esp.box then
        esp.box.Thickness = 1
        esp.box.Filled = false
        esp.box.Visible = false
    end
    if esp.name then
        esp.name.Size = 13
        esp.name.Center = true
        esp.name.Outline = true
        esp.name.Font = 2
        esp.name.Visible = false
    end
    if esp.healthBar then
        esp.healthBar.Thickness = 2
        esp.healthBar.Visible = false
    end
    if esp.healthBarBg then
        esp.healthBarBg.Thickness = 4
        esp.healthBarBg.Color = Color3.fromRGB(0, 0, 0)
        esp.healthBarBg.Visible = false
    end
    if esp.distance then
        esp.distance.Size = 11
        esp.distance.Center = true
        esp.distance.Outline = true
        esp.distance.Font = 2
        esp.distance.Visible = false
        esp.distance.Color = Color3.fromRGB(200, 200, 200)
    end
    if esp.tracer then
        esp.tracer.Thickness = 1
        esp.tracer.Visible = false
    end

    Draw.espCache[player] = esp
end

local function removeESP(player)
    local esp = Draw.espCache[player]
    if not esp then return end
    for _, d in pairs(esp) do
        if d and typeof(d) ~= "string" and d.Remove then
            pcall(function() d:Remove() end)
        end
    end
    Draw.espCache[player] = nil
end

local function hideESP(esp)
    if not esp then return end
    for _, d in pairs(esp) do
        if d and typeof(d) ~= "string" then
            pcall(function() d.Visible = false end)
        end
    end
end

local function updateESP()
    if not hasDrawing then return end
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end

        if not Draw.espCache[player] then
            createESP(player)
        end
        local esp = Draw.espCache[player]
        if not esp then continue end

        -- Check if we should show ESP
        if not State.espEnabled then
            hideESP(esp)
            continue
        end

        local char = getPFChar(player)
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        local head = char and char:FindFirstChild("Head")
        local isEnemy = not isTeammate(player)
        local alive = isPFAlive(player)

        if not char or not root or not alive then
            hideESP(esp)
            continue
        end

        if State.teamCheck and not isEnemy then
            hideESP(esp)
            continue
        end

        local rootScreen, onScreen = w2s(root.Position)
        if not onScreen then
            hideESP(esp)
            continue
        end

        local color = isEnemy and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(60, 255, 60)
        local dist = (Camera.CFrame.Position - root.Position).Magnitude

        -- Calculate box bounds
        local headPos = head and head.Position or (root.Position + Vector3.new(0, 2, 0))
        local headTop = w2s(headPos + Vector3.new(0, 1.2, 0))
        local feetPos = w2s(root.Position - Vector3.new(0, 3, 0))
        local boxH = math.abs(feetPos.Y - headTop.Y)
        local boxW = boxH * 0.55
        local cx = (headTop.X + feetPos.X) / 2

        -- Box ESP
        if State.boxESP and esp.box then
            pcall(function()
                esp.box.PointA = Vector2.new(cx - boxW/2, headTop.Y)
                esp.box.PointB = Vector2.new(cx + boxW/2, headTop.Y)
                esp.box.PointC = Vector2.new(cx + boxW/2, feetPos.Y)
                esp.box.PointD = Vector2.new(cx - boxW/2, feetPos.Y)
                esp.box.Color = color
                esp.box.Visible = true
            end)
        elseif esp.box then
            pcall(function() esp.box.Visible = false end)
        end

        -- Name tag
        if State.nameTag and esp.name then
            pcall(function()
                esp.name.Text = player.Name
                esp.name.Position = Vector2.new(cx, headTop.Y - 16)
                esp.name.Color = color
                esp.name.Visible = true
            end)
        elseif esp.name then
            pcall(function() esp.name.Visible = false end)
        end

        -- Distance
        if State.distTag and esp.distance then
            pcall(function()
                esp.distance.Text = math.floor(dist) .. "m"
                esp.distance.Position = Vector2.new(cx, feetPos.Y + 2)
                esp.distance.Visible = true
            end)
        elseif esp.distance then
            pcall(function() esp.distance.Visible = false end)
        end

        -- Health bar
        if State.healthBar and esp.healthBar and esp.healthBarBg then
            pcall(function()
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hp = hum and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 1
                local barX = cx - boxW/2 - 6

                esp.healthBarBg.From = Vector2.new(barX, feetPos.Y)
                esp.healthBarBg.To = Vector2.new(barX, headTop.Y)
                esp.healthBarBg.Visible = true

                local barTop = feetPos.Y - (feetPos.Y - headTop.Y) * hp
                esp.healthBar.From = Vector2.new(barX, feetPos.Y)
                esp.healthBar.To = Vector2.new(barX, barTop)
                esp.healthBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
                esp.healthBar.Visible = true
            end)
        else
            if esp.healthBar then pcall(function() esp.healthBar.Visible = false end) end
            if esp.healthBarBg then pcall(function() esp.healthBarBg.Visible = false end) end
        end

        -- Tracers
        if State.tracers and esp.tracer then
            pcall(function()
                local origin
                if State.tracerOrigin == "Bottom" then
                    origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                elseif State.tracerOrigin == "Center" then
                    origin = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                else
                    origin = Vector2.new(Mouse.X, Mouse.Y)
                end
                esp.tracer.From = origin
                esp.tracer.To = feetPos
                esp.tracer.Color = color
                esp.tracer.Visible = true
            end)
        elseif esp.tracer then
            pcall(function() esp.tracer.Visible = false end)
        end
    end
end

-- ═══════════════════════════════════════════
-- CHAMS (Instance-based, no Drawing needed)
-- ═══════════════════════════════════════════
local function updateChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        local char = getPFChar(player)

        if State.chamsEnabled and char and isPFAlive(player) then
            if not chamsCache[player] then
                local ok, highlight = pcall(function()
                    local h = Instance.new("Highlight")
                    h.FillColor = isTeammate(player) and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 0, 50)
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.FillTransparency = 0.5
                    h.OutlineTransparency = 0.3
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Adornee = char
                    h.Parent = char
                    return h
                end)
                if ok then
                    chamsCache[player] = highlight
                end
            end
        else
            if chamsCache[player] then
                pcall(function() chamsCache[player]:Destroy() end)
                chamsCache[player] = nil
            end
        end
    end
end

-- ═══════════════════════════════════════════
-- CROSSHAIR
-- ═══════════════════════════════════════════
local function createCrosshair()
    if not hasDrawing then return end
    for _, l in ipairs(Draw.crosshairLines) do
        pcall(function() l:Remove() end)
    end
    Draw.crosshairLines = {}

    if State.crosshairStyle == "Cross" or State.crosshairStyle == "Cross+Dot" then
        for i = 1, 4 do
            local l = safeDrawNew("Line")
            if l then
                l.Color = Color3.fromRGB(0, 255, 200)
                l.Thickness = State.crosshairThick
                l.Visible = false
                table.insert(Draw.crosshairLines, l)
            end
        end
    end
    if State.crosshairStyle == "Dot" or State.crosshairStyle == "Cross+Dot" then
        local d = safeDrawNew("Circle")
        if d then
            d.Radius = 2
            d.Filled = true
            d.Color = Color3.fromRGB(0, 255, 200)
            d.Visible = false
            table.insert(Draw.crosshairLines, d)
        end
    end
    if State.crosshairStyle == "Circle" then
        local c = safeDrawNew("Circle")
        if c then
            c.Radius = State.crosshairSize
            c.Filled = false
            c.Thickness = State.crosshairThick
            c.Color = Color3.fromRGB(0, 255, 200)
            c.Visible = false
            table.insert(Draw.crosshairLines, c)
        end
    end
end

local function updateCrosshair()
    if not hasDrawing then return end
    if not State.crosshair then
        for _, d in ipairs(Draw.crosshairLines) do
            pcall(function() d.Visible = false end)
        end
        return
    end
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return end

    local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
    local sz, gap = State.crosshairSize, 3

    local lineIdx = 0
    if State.crosshairStyle == "Cross" or State.crosshairStyle == "Cross+Dot" then
        for i = 1, math.min(4, #Draw.crosshairLines) do
            local l = Draw.crosshairLines[i]
            if not l then continue end
            pcall(function()
                if i == 1 then l.From = Vector2.new(cx-gap-sz, cy); l.To = Vector2.new(cx-gap, cy)
                elseif i == 2 then l.From = Vector2.new(cx+gap, cy); l.To = Vector2.new(cx+gap+sz, cy)
                elseif i == 3 then l.From = Vector2.new(cx, cy-gap-sz); l.To = Vector2.new(cx, cy-gap)
                elseif i == 4 then l.From = Vector2.new(cx, cy+gap); l.To = Vector2.new(cx, cy+gap+sz)
                end
                l.Visible = true
            end)
            lineIdx = i
        end
    end

    -- Handle dot/circle
    for i = lineIdx + 1, #Draw.crosshairLines do
        local d = Draw.crosshairLines[i]
        if d then
            pcall(function()
                d.Position = Vector2.new(cx, cy)
                d.Visible = true
            end)
        end
    end
end

-- ═══════════════════════════════════════════
-- WALLHACK
-- ═══════════════════════════════════════════
local wallhackParts = {}

local function setWallhack(enabled)
    if enabled then
        -- Find map parts
        local searchIn = {
            Workspace:FindFirstChild("Map"),
            Workspace:FindFirstChild("Terrain"),
            Workspace:FindFirstChild("Environment"),
        }

        -- If no map folder found, search workspace children that aren't players
        if #searchIn == 0 or (not searchIn[1] and not searchIn[2]) then
            for _, child in ipairs(Workspace:GetChildren()) do
                if child:IsA("Model") or child:IsA("Folder") then
                    if child.Name ~= "Characters" and child.Name ~= "Ignore" and
                       not Players:GetPlayerFromCharacter(child) then
                        table.insert(searchIn, child)
                    end
                end
            end
        end

        for _, folder in ipairs(searchIn) do
            if not folder then continue end
            for _, part in ipairs(folder:GetDescendants()) do
                if part:IsA("BasePart") then
                    if not wallhackParts[part] then
                        wallhackParts[part] = part.Transparency
                    end
                    part.Transparency = math.max(part.Transparency, State.wallOpacity / 100)
                end
            end
        end
    else
        for part, orig in pairs(wallhackParts) do
            if part and part.Parent then
                pcall(function() part.Transparency = orig end)
            end
        end
        wallhackParts = {}
    end
end

-- ═══════════════════════════════════════════
-- HOOKS (Only if executor supports them)
-- ═══════════════════════════════════════════
local hooksInstalled = false

local function installHooks()
    if hooksInstalled then return end
    if not hasHookMeta or not hasGetNamecallMethod then
        warn("[Nexus PF] Executor doesn't support hookmetamethod — silent aim/no spread unavailable")
        return
    end

    hooksInstalled = true

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", (hasNewCClosure and newcclosure or function(f) return f end)(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        -- Silent Aim: redirect raycasts
        if State.silentAim and self == Workspace then
            if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                local target = getBestTarget(State.silentFov, State.teamCheck)
                if target then
                    local origin = Camera.CFrame.Position
                    local direction = (target.position - origin).Unit * 5000

                    if method == "Raycast" then
                        args[1] = origin
                        args[2] = direction
                        return oldNamecall(self, unpack(args))
                    else
                        args[1] = Ray.new(origin, direction)
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end

        return oldNamecall(self, ...)
    end))

    -- No Spread: hook Mouse.Hit
    if State.noSpread then
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", (hasNewCClosure and newcclosure or function(f) return f end)(function(self, key)
            if State.noSpread and self == Mouse and key == "Hit" then
                if Camera then
                    local ray = Camera:ViewportPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    return CFrame.new(ray.Origin, ray.Origin + ray.Direction * 1000)
                end
            end
            return oldIndex(self, key)
        end))
    end
end

-- ═══════════════════════════════════════════
-- VISUAL BYPASS LOOP
-- ═══════════════════════════════════════════
local function setupVisualBypasses()
    addConn(RunSrv.Heartbeat:Connect(function()
        -- Only run if any bypass is active
        if not (State.noScope or State.noFlash or State.antiSuppression or State.removeDebris) then
            return
        end

        local playerGui = LP:FindFirstChild("PlayerGui")
        if not playerGui then return end

        -- No scope overlay
        if State.noScope then
            pcall(function()
                for _, gui in ipairs(playerGui:GetDescendants()) do
                    if gui:IsA("ImageLabel") then
                        local name = gui.Name:lower()
                        if name:find("scope") or name:find("overlay") then
                            gui.Visible = false
                        end
                    end
                end
            end)
        end

        -- No flash
        if State.noFlash then
            pcall(function()
                for _, gui in ipairs(playerGui:GetDescendants()) do
                    if (gui:IsA("Frame") or gui:IsA("ImageLabel")) then
                        if gui.BackgroundColor3 == Color3.new(1, 1, 1) and gui.BackgroundTransparency < 0.5 then
                            gui.BackgroundTransparency = 1
                        end
                    end
                end
            end)
        end

        -- Anti suppression
        if State.antiSuppression then
            pcall(function()
                for _, gui in ipairs(playerGui:GetDescendants()) do
                    if gui:IsA("ImageLabel") then
                        local name = gui.Name:lower()
                        if name:find("suppress") or name:find("vignette") then
                            gui.ImageTransparency = 1
                        end
                    end
                end
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if effect:IsA("BlurEffect") then
                        effect.Size = 0
                    end
                end
            end)
        end

        -- Remove debris
        if State.removeDebris then
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                        obj.Enabled = false
                    end
                end
            end)
        end
    end))
end

-- ═══════════════════════════════════════════
-- MAIN RENDER LOOP (with full nil guards)
-- ═══════════════════════════════════════════
addConn(RunSrv.RenderStepped:Connect(function()
    -- Update camera reference
    Camera = Workspace.CurrentCamera
    if not Camera then return end

    -- FOV circle
    if Draw.fov then
        pcall(function()
            if State.drawFov and State.aimbotEnabled then
                Draw.fov.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                Draw.fov.Radius = State.fov
                Draw.fov.Visible = true
            else
                Draw.fov.Visible = false
            end
        end)
    end

    -- Aimbot camera lock
    if State.aimbotEnabled then
        local keyDown = pcall(function() return UIS:IsKeyDown(State.aimKey) end)
        if keyDown and UIS:IsKeyDown(State.aimKey) then
            local target = getBestTarget(State.fov, State.teamCheck)
            if target and target.position then
                local targetCF = CFrame.new(Camera.CFrame.Position, target.position)
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / math.max(State.smooth, 1))
            end
        end
    end

    -- ESP update
    pcall(updateESP)

    -- Chams update
    pcall(updateChams)

    -- Crosshair update
    pcall(updateCrosshair)

    -- Fullbright
    if State.fullbright then
        pcall(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        end)
    end

    -- No fog
    if State.noFog then
        pcall(function()
            Lighting.FogEnd = 100000
            Lighting.FogStart = 100000
        end)
    end

    -- No particles
    if State.noParticles then
        -- Don't do this every frame, too expensive
    end
end))

-- No particles (throttled)
spawn(function()
    while true do
        if State.noParticles then
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                        obj.Enabled = false
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- Triggerbot
spawn(function()
    while true do
        if State.triggerbot then
            pcall(function()
                local target = Mouse.Target
                if target then
                    -- Check if target belongs to an enemy player
                    local charFolder = getPFCharFolder()
                    local model = target.Parent
                    -- Walk up to find character model
                    for i = 1, 5 do
                        if not model then break end
                        if model.Parent == charFolder or model.Parent == Workspace then break end
                        model = model.Parent
                    end
                    if model then
                        local player = Players:FindFirstChild(model.Name)
                        if player and player ~= LP then
                            if not State.teamCheck or not isTeammate(player) then
                                task.wait(State.triggerDelay / 1000)
                                if hasMouse1Click then
                                    mouse1click()
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(0.016)
    end
end)

-- Anti AFK
spawn(function()
    while true do
        if State.antiAfk then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
        task.wait(60)
    end
end)

-- Player cleanup
addConn(Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    if chamsCache[player] then
        pcall(function() chamsCache[player]:Destroy() end)
        chamsCache[player] = nil
    end
end))

-- ═══════════════════════════════════════════
-- GUI LOADER
-- ═══════════════════════════════════════════

local function load(UI, contentArea)
    local pages = {}

    -- Install hooks safely
    pcall(installHooks)
    pcall(setupVisualBypasses)

    -- COMBAT
    local c = UI.scrollPage(contentArea, "PF_Combat")
    UI.section(c, "Aimbot (Camera Lock)", 1)
    UI.toggle(c, "Aimbot Enabled", false, function(v) State.aimbotEnabled = v end, 2)
    UI.dropdown(c, "Target Bone", {"Head","Torso","Pelvis","Closest"}, "Head", function(v) State.targetBone = v end, 3)
    UI.slider(c, "FOV Circle", 20, 600, 120, function(v) State.fov = v end, 4)
    UI.toggle(c, "Draw FOV", false, function(v) State.drawFov = v end, 5)
    UI.slider(c, "Smoothing", 1, 40, 6, function(v) State.smooth = v end, 6)
    UI.toggle(c, "Aim Prediction", false, function(v) State.prediction = v end, 7)
    UI.toggle(c, "Team Check", true, function(v) State.teamCheck = v end, 8)
    UI.toggle(c, "Wall Check", true, function(v) State.wallCheck = v end, 9)
    UI.keybind(c, "Aim Key", Enum.KeyCode.E, function(v) State.aimKey = v end, 10)

    UI.section(c, "Silent Aim (Requires hookmetamethod)", 12)
    UI.toggle(c, "Silent Aim", false, function(v)
        State.silentAim = v
        if v and not hooksInstalled then pcall(installHooks) end
    end, 13)
    UI.slider(c, "Silent FOV", 20, 600, 150, function(v) State.silentFov = v end, 14)
    if not hasHookMeta then
        UI.label(c, "⚠ Silent Aim unavailable — executor missing hookmetamethod", 15)
    end

    UI.section(c, "Weapon Bypasses", 17)
    UI.toggle(c, "No Recoil", false, function(v) State.noRecoil = v end, 18)
    UI.toggle(c, "No Spread", false, function(v)
        State.noSpread = v
        if v and not hooksInstalled then pcall(installHooks) end
    end, 19)
    if not hasHookMeta then
        UI.label(c, "⚠ No Spread unavailable — executor missing hookmetamethod", 20)
    end

    UI.section(c, "Triggerbot", 22)
    UI.toggle(c, "Triggerbot", false, function(v) State.triggerbot = v end, 23)
    UI.slider(c, "Trigger Delay (ms)", 0, 250, 40, function(v) State.triggerDelay = v end, 24)
    if not hasMouse1Click then
        UI.label(c, "⚠ Triggerbot unavailable — executor missing mouse1click", 25)
    end
    pages.Combat = c

    -- VISUAL
    local v = UI.scrollPage(contentArea, "PF_Visual")
    UI.section(v, "ESP", 1)
    UI.toggle(v, "Player ESP", false, function(val) State.espEnabled = val end, 2)
    UI.toggle(v, "Box ESP", false, function(val) State.boxESP = val end, 3)
    UI.dropdown(v, "Box Style", {"2D","Corner","3D"}, "Corner", function(val) State.boxStyle = val end, 4)
    UI.toggle(v, "Name Tags", false, function(val) State.nameTag = val end, 5)
    UI.toggle(v, "Health Bar", false, function(val) State.healthBar = val end, 6)
    UI.toggle(v, "Distance Tag", false, function(val) State.distTag = val end, 7)
    UI.toggle(v, "Tracers", false, function(val) State.tracers = val end, 8)
    UI.dropdown(v, "Tracer Origin", {"Bottom","Center","Mouse"}, "Bottom", function(val) State.tracerOrigin = val end, 9)
    if not hasDrawing then
        UI.label(v, "⚠ ESP unavailable — Drawing API not found", 10)
    end

    UI.section(v, "Chams (Works on all executors)", 12)
    UI.toggle(v, "Player Chams", false, function(val)
        State.chamsEnabled = val
        if not val then
            for p, h in pairs(chamsCache) do
                pcall(function() h:Destroy() end)
                chamsCache[p] = nil
            end
        end
    end, 13)

    UI.section(v, "Crosshair", 16)
    UI.toggle(v, "Custom Crosshair", false, function(val)
        State.crosshair = val
        if val then createCrosshair() end
    end, 17)
    UI.dropdown(v, "Shape", {"Cross","Dot","Circle","Cross+Dot"}, "Cross+Dot", function(val)
        State.crosshairStyle = val
        createCrosshair()
    end, 18)
    UI.slider(v, "Size", 2, 30, 8, function(val) State.crosshairSize = val end, 19)
    UI.slider(v, "Thickness", 1, 6, 2, function(val) State.crosshairThick = val end, 20)

    UI.section(v, "World Visuals", 22)
    UI.toggle(v, "Fullbright", false, function(val) State.fullbright = val end, 23)
    UI.toggle(v, "No Fog", false, function(val) State.noFog = val end, 24)
    UI.toggle(v, "No Particles", false, function(val) State.noParticles = val end, 25)
    UI.toggle(v, "No Scope Overlay", false, function(val) State.noScope = val end, 26)
    UI.toggle(v, "Remove Debris", false, function(val) State.removeDebris = val end, 27)
    UI.toggle(v, "Transparent Walls", false, function(val)
        State.wallhack = val
        pcall(setWallhack, val)
    end, 28)
    UI.slider(v, "Wall Opacity (%)", 0, 100, 30, function(val)
        State.wallOpacity = val
        if State.wallhack then pcall(setWallhack, true) end
    end, 29)
    pages.Visual = v

    -- PLAYER
    local pl = UI.scrollPage(contentArea, "PF_Player")
    UI.section(pl, "Screen Effects", 1)
    UI.toggle(pl, "No Flash", false, function(val) State.noFlash = val end, 2)
    UI.toggle(pl, "No Flinch (Visual)", false, function(val) State.noFlinch = val end, 3)
    UI.toggle(pl, "Anti-Suppression", false, function(val) State.antiSuppression = val end, 4)
    pages.Player = pl

    -- WORLD
    local w = UI.scrollPage(contentArea, "PF_World")
    UI.section(w, "Server", 1)
    UI.toggle(w, "Anti-AFK", false, function(val) State.antiAfk = val end, 2)
    UI.button(w, "Server Hop", function()
        pcall(function()
            local TeleportService = game:GetService("TeleportService")
            local HttpService = game:GetService("HttpService")
            local data = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            local servers = HttpService:JSONDecode(data)
            for _, s in ipairs(servers.data or {}) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                    break
                end
            end
        end)
    end, 3)
    UI.button(w, "Rejoin", function()
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end)
    end, 4)
    pages.World = w

    -- MISC
    local mi = UI.scrollPage(contentArea, "PF_Misc")
    UI.section(mi, "Utility", 1)
    UI.toggle(mi, "Chat Spammer", false, nil, 3)

    UI.section(mi, "Compatibility Info", 5)
    UI.label(mi, "Drawing API: " .. (hasDrawing and "✓ Available" or "✗ Missing"), 6)
    UI.label(mi, "hookmetamethod: " .. (hasHookMeta and "✓ Available" or "✗ Missing"), 7)
    UI.label(mi, "newcclosure: " .. (hasNewCClosure and "✓ Available" or "✗ Missing"), 8)
    UI.label(mi, "mouse1click: " .. (hasMouse1Click and "✓ Available" or "✗ Missing"), 9)
    UI.separator(mi, 10)
    UI.label(mi, "Movement hacks are SERVER-BLOCKED in PF", 11)
    UI.label(mi, "Silent Aim & No Spread require hookmetamethod", 12)
    pages.Misc = mi

    -- No movement tab (server-validated)
    pages.Movement = nil

    return pages
end

return load
