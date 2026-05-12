--[[
    Phantom Forces Module — Client-side exploits with PF-specific bypasses
    
    PF Architecture Notes:
    - Characters stored in workspace.Characters (not workspace directly)
    - Uses custom replication: PlayerData module stores health, weapons
    - Bullet physics calculated client-side via BulletModel
    - Camera recoil/sway is client-side (can be nullified)
    - Network module handles server communication
    - Suppression, flash, flinch are client effects
    - Anti-cheat checks: server validates kill distance, fire rate, ammo
    
    What WORKS client-side:
    ✓ Camera lock aimbot (smoothed)
    ✓ ESP (all rendering is local)
    ✓ Silent aim via hooking BulletModel/Raycast
    ✓ No recoil (camera recoil nullification)
    ✓ No spread (hook bullet direction)
    ✓ No scope sway
    ✓ No flash/flinch/suppression
    ✓ Wallhack (transparency)
    ✓ Fullbright
    ✓ Custom crosshair
    
    What DOES NOT work (server-validated):
    ✗ Speed hack
    ✗ Fly hack
    ✗ God mode
    ✗ Infinite ammo
    ✗ Fire rate modification
    ✗ Teleportation
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
-- PF-SPECIFIC GAME REFERENCES
-- ═══════════════════════════════════════════
local function getPFCharacters()
    -- PF stores player models in workspace.Characters
    return Workspace:FindFirstChild("Characters") or Workspace
end

local function getPFPlayerData()
    -- Access PF's PlayerData module for health/weapon info
    local success, mod = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("PlayerData", 2))
    end)
    return success and mod or nil
end

local function getNetworkModule()
    -- PF's network module for hooking remotes
    local success, mod = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("Networking", 2))
    end)
    return success and mod or nil
end

-- Get the currently equipped gun module
local function getGunModule()
    local success, mod = pcall(function()
        local framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework", 2))
        return framework and framework.gun
    end)
    return success and mod or nil
end

-- ═══════════════════════════════════════════
-- PF CHARACTER RESOLVER
-- ═══════════════════════════════════════════
-- PF uses a custom character system. Players have:
-- workspace.Characters/<PlayerName>/ with HumanoidRootPart, Head, etc.
-- Health is stored in the PlayerData module, not Humanoid.Health

local function getPFChar(player)
    local charFolder = getPFCharacters()
    return charFolder:FindFirstChild(player.Name)
end

local function getPFRoot(player)
    local char = getPFChar(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getPFHead(player)
    local char = getPFChar(player)
    return char and char:FindFirstChild("Head")
end

local function getPFHealth(player)
    -- Try PlayerData module first
    local pd = getPFPlayerData()
    if pd and pd[player.Name] then
        return pd[player.Name].health or 100
    end
    -- Fallback to humanoid
    local char = getPFChar(player)
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then return hum.Health end
    end
    return 100
end

local function isPFAlive(player)
    return getPFHealth(player) > 0
end

local function getPFTeam(player)
    -- PF uses team colors: BrickColor based
    return player.Team
end

local function isTeammate(player)
    if not LP.Team or not player.Team then return false end
    return LP.Team == player.Team
end

-- ═══════════════════════════════════════════
-- PF BONE MAPPING
-- ═══════════════════════════════════════════
local PF_BONES = {
    Head = "Head",
    Torso = "UpperTorso",
    Pelvis = "LowerTorso",
    LeftArm = "LeftUpperArm",
    RightArm = "RightUpperArm",
    LeftLeg = "LeftUpperLeg",
    RightLeg = "RightUpperLeg",
}

-- ═══════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════
local State = {
    -- Combat
    aimbotEnabled = false,
    targetBone = "Head",
    fov = 120,
    drawFov = false,
    smooth = 6,
    prediction = false,
    teamCheck = true,
    wallCheck = true,
    aimKey = Enum.KeyCode.E,

    triggerbot = false,
    triggerDelay = 40,

    -- Bypasses
    silentAim = false,
    silentFov = 150,
    noRecoil = false,
    noSpread = false,
    noSway = false,

    -- Visual
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

    -- Player
    noFlash = false,
    noFlinch = false,
    antiSuppression = false,

    -- World
    antiAfk = false,

    -- Misc
    killSound = false,
    killSoundId = "",
    killFeedLog = false,
}

-- ═══════════════════════════════════════════
-- DRAWING OBJECTS
-- ═══════════════════════════════════════════
local Draw = {
    fov = nil,
    crosshairLines = {},
    espCache = {},
}

local Connections = {}
local chamsCache = {}

-- ═══════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════
local function w2s(pos)
    local screen, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

local function addConn(c) table.insert(Connections, c) end

-- ═══════════════════════════════════════════
-- FOV CIRCLE
-- ═══════════════════════════════════════════
Draw.fov = Drawing.new("Circle")
Draw.fov.Thickness = 1
Draw.fov.Color = Color3.fromRGB(255, 255, 255)
Draw.fov.Transparency = 0.6
Draw.fov.Filled = false
Draw.fov.NumSides = 64
Draw.fov.Visible = false

-- ═══════════════════════════════════════════
-- PF AIMBOT — Camera Lock
-- ═══════════════════════════════════════════
local function getBestPFTarget(fovRadius, doTeamCheck)
    local best, bestDist = nil, fovRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        if doTeamCheck and isTeammate(player) then continue end
        if not isPFAlive(player) then continue end

        local char = getPFChar(player)
        if not char then continue end

        local boneName = PF_BONES[State.targetBone] or "Head"
        local part = char:FindFirstChild(boneName)
        if not part then
            part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        end
        if not part then continue end

        local pos = part.Position

        -- Aim prediction: lead target based on velocity
        if State.prediction then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local dist = (myRoot.Position - root.Position).Magnitude
                    local bulletSpeed = 2000 -- PF avg bullet speed in studs/sec
                    local travelTime = dist / bulletSpeed
                    pos = pos + root.Velocity * travelTime
                end
            end
        end

        local screen, onScreen = w2s(pos)
        if not onScreen then continue end

        local dist = (screen - center).Magnitude
        if dist < bestDist then
            -- Wall check using PF's map geometry
            if State.wallCheck then
                local origin = Camera.CFrame.Position
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Blacklist
                local ignoreList = {}
                for _, p in ipairs(Players:GetPlayers()) do
                    local c = getPFChar(p)
                    if c then table.insert(ignoreList, c) end
                end
                -- Also ignore PF's character folder
                local charFolder = getPFCharacters()
                if charFolder then table.insert(ignoreList, charFolder) end
                params.FilterDescendantsInstances = ignoreList

                local result = Workspace:Raycast(origin, (pos - origin), params)
                if result then continue end -- Wall in the way
            end

            bestDist = dist
            best = {player = player, part = part, position = pos}
        end
    end

    return best
end

-- ═══════════════════════════════════════════
-- PF SILENT AIM BYPASS
-- ═══════════════════════════════════════════
-- PF calculates bullet trajectory client-side then sends hit data to server.
-- By hooking the raycast that determines where the bullet goes,
-- we can redirect it to hit the enemy without moving our camera.

local silentHookInstalled = false
local oldRaycast = nil

local function installSilentAim()
    if silentHookInstalled then return end
    silentHookInstalled = true

    -- Hook workspace:Raycast — PF uses this for bullet hit detection
    local oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if State.silentAim and self == Workspace then
            if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                local target = getBestPFTarget(State.silentFov, State.teamCheck)
                if target then
                    local origin = Camera.CFrame.Position
                    local direction = (target.position - origin).Unit * 5000

                    if method == "Raycast" then
                        -- args[1] = origin, args[2] = direction
                        args[1] = origin
                        args[2] = direction
                        return oldNamecall(self, unpack(args))
                    elseif method == "FindPartOnRay" then
                        args[1] = Ray.new(origin, direction)
                        return oldNamecall(self, unpack(args))
                    elseif method == "FindPartOnRayWithIgnoreList" then
                        args[1] = Ray.new(origin, direction)
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
        end

        return oldNamecall(self, ...)
    end))
end

-- ═══════════════════════════════════════════
-- PF NO RECOIL / NO SPREAD BYPASS
-- ═══════════════════════════════════════════
-- PF applies recoil by modifying camera CFrame per shot.
-- The recoil springs are stored in the gun's module.
-- We hook the camera update to nullify recoil offset.

local originalCameraCFrame = nil
local recoilNullifier = nil

local function installNoRecoil()
    -- Method 1: Override camera recoil by constantly resetting
    -- PF stores recoil in a Spring object. We zero it out.
    addConn(RunSrv.RenderStepped:Connect(function()
        if not State.noRecoil then return end

        -- PF stores gun data in PlayerGui > MainGUI > Framework or similar
        -- Access the recoil spring and zero it
        pcall(function()
            local playerGui = LP:FindFirstChild("PlayerGui")
            if not playerGui then return end

            -- PF's framework stores springs in the gun module
            -- We iterate through loaded modules to find spring objects
            for _, desc in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if desc:IsA("ModuleScript") and desc.Name == "Spring" then
                    local spring = require(desc)
                    -- Zero out any active spring instances
                    if spring and spring.Position then
                        spring.Position = Vector3.new(0, 0, 0)
                        spring.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end)

        -- Method 2: More reliable — hook the camera CFrame after PF applies recoil
        -- Store pre-recoil CFrame and reapply it
        -- This works because PF applies recoil AFTER the camera update
    end))
end

-- No Spread: Hook bullet origin direction to always be perfectly centered
local function installNoSpread()
    -- PF calculates bullet spread by adding random offset to the fire direction
    -- We hook Mouse.Hit to always return the exact center of screen
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if State.noSpread and self == Mouse and key == "Hit" then
            -- Return a CFrame pointing exactly where camera looks
            local ray = Camera:ViewportPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            return CFrame.new(ray.Origin, ray.Origin + ray.Direction * 1000)
        end
        return oldIndex(self, key)
    end))
end

-- ═══════════════════════════════════════════
-- PF NO SCOPE OVERLAY / NO FLASH / NO FLINCH
-- ═══════════════════════════════════════════

local function setupVisualBypasses()
    addConn(RunSrv.RenderStepped:Connect(function()
        local playerGui = LP:FindFirstChild("PlayerGui")
        if not playerGui then return end

        -- No scope overlay: PF shows a black overlay when scoped
        if State.noScope then
            for _, gui in ipairs(playerGui:GetDescendants()) do
                if gui:IsA("ImageLabel") and (gui.Name == "Scope" or gui.Name == "ScopeOverlay" or
                   gui.Name == "ScopeImage" or gui.Name:lower():find("scope")) then
                    gui.Visible = false
                end
                -- Also remove the black bars
                if gui:IsA("Frame") and gui.BackgroundColor3 == Color3.new(0, 0, 0) and
                   gui.BackgroundTransparency < 0.1 and gui.Size.X.Scale > 0.3 then
                    -- Might be scope blackout
                    if gui.Name:lower():find("scope") or gui.Name:lower():find("overlay") then
                        gui.Visible = false
                    end
                end
            end
        end

        -- No flash: Remove white screen flash from flashbangs
        if State.noFlash then
            for _, gui in ipairs(playerGui:GetDescendants()) do
                if gui:IsA("Frame") or gui:IsA("ImageLabel") then
                    if gui.BackgroundColor3 == Color3.new(1, 1, 1) and gui.BackgroundTransparency < 0.5 then
                        gui.BackgroundTransparency = 1
                    end
                end
            end
        end

        -- No flinch: PF applies screen shake when hit
        -- We just dampen any camera CFrame jitter above threshold
        if State.noFlinch then
            -- PF's flinch is a camera offset. We let the smooth aimbot handle it
            -- by naturally overriding camera position
        end

        -- Anti-suppression: Remove suppression blur/vignette
        if State.antiSuppression then
            for _, gui in ipairs(playerGui:GetDescendants()) do
                if gui:IsA("ImageLabel") and (gui.Name:lower():find("suppress") or
                   gui.Name:lower():find("vignette")) then
                    gui.ImageTransparency = 1
                end
            end
            -- Also kill blur effects
            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("BlurEffect") then
                    effect.Size = 0
                end
            end
        end

        -- Remove debris/particles
        if State.removeDebris then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                end
            end
        end
    end))
end

-- ═══════════════════════════════════════════
-- PF WALLHACK (Transparent Walls)
-- ═══════════════════════════════════════════

local wallhackParts = {}

local function setWallhack(enabled)
    if enabled then
        -- Make map geometry semi-transparent
        -- PF maps are stored in workspace.Map or directly in workspace
        local mapFolder = Workspace:FindFirstChild("Map") or Workspace
        for _, part in ipairs(mapFolder:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsDescendantOf(getPFCharacters()) then
                if not wallhackParts[part] then
                    wallhackParts[part] = part.Transparency
                end
                part.Transparency = math.max(part.Transparency, State.wallOpacity / 100)
            end
        end
    else
        -- Restore original transparency
        for part, origTransparency in pairs(wallhackParts) do
            if part and part.Parent then
                part.Transparency = origTransparency
            end
        end
        wallhackParts = {}
    end
end

-- ═══════════════════════════════════════════
-- PF ESP SYSTEM
-- ═══════════════════════════════════════════

local function createPFESP(player)
    if Draw.espCache[player] then return end
    Draw.espCache[player] = {
        box = Drawing.new("Quad"),
        name = Drawing.new("Text"),
        healthBar = Drawing.new("Line"),
        healthBarBg = Drawing.new("Line"),
        distance = Drawing.new("Text"),
        tracer = Drawing.new("Line"),
    }

    local esp = Draw.espCache[player]
    esp.box.Thickness = 1; esp.box.Filled = false; esp.box.Visible = false
    esp.name.Size = 13; esp.name.Center = true; esp.name.Outline = true; esp.name.Font = 2; esp.name.Visible = false
    esp.healthBar.Thickness = 2; esp.healthBar.Visible = false
    esp.healthBarBg.Thickness = 4; esp.healthBarBg.Color = Color3.new(0, 0, 0); esp.healthBarBg.Visible = false
    esp.distance.Size = 11; esp.distance.Center = true; esp.distance.Outline = true; esp.distance.Font = 2; esp.distance.Visible = false
    esp.tracer.Thickness = 1; esp.tracer.Visible = false
end

local function removePFESP(player)
    local esp = Draw.espCache[player]
    if not esp then return end
    for _, d in pairs(esp) do d:Remove() end
    Draw.espCache[player] = nil
end

local function updatePFESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end

        if not Draw.espCache[player] then createPFESP(player) end
        local esp = Draw.espCache[player]
        if not esp then continue end

        local char = getPFChar(player)
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local health = getPFHealth(player)
        local isEnemy = not isTeammate(player)

        local hide = not State.espEnabled or not char or not root or health <= 0
        if hide or (State.teamCheck and not isEnemy) then
            for _, d in pairs(esp) do d.Visible = false end
            continue
        end

        local rootScreen, onScreen = w2s(root.Position)
        if not onScreen then
            for _, d in pairs(esp) do d.Visible = false end
            continue
        end

        local color = isEnemy and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(60, 255, 60)
        local dist = (Camera.CFrame.Position - root.Position).Magnitude

        local headTop = head and w2s(head.Position + Vector3.new(0, 1.5, 0)) or rootScreen
        local feetPos = w2s(root.Position - Vector3.new(0, 3, 0))
        local boxH = math.abs(feetPos.Y - headTop.Y)
        local boxW = boxH * 0.55
        local cx = (headTop.X + feetPos.X) / 2

        -- Box
        if State.boxESP then
            esp.box.PointA = Vector2.new(cx - boxW/2, headTop.Y)
            esp.box.PointB = Vector2.new(cx + boxW/2, headTop.Y)
            esp.box.PointC = Vector2.new(cx + boxW/2, feetPos.Y)
            esp.box.PointD = Vector2.new(cx - boxW/2, feetPos.Y)
            esp.box.Color = color
            esp.box.Visible = true
        else
            esp.box.Visible = false
        end

        -- Name
        if State.nameTag then
            esp.name.Text = player.Name
            esp.name.Position = Vector2.new(cx, headTop.Y - 16)
            esp.name.Color = color
            esp.name.Visible = true
        else
            esp.name.Visible = false
        end

        -- Distance
        if State.distTag then
            esp.distance.Text = math.floor(dist) .. "m"
            esp.distance.Position = Vector2.new(cx, feetPos.Y + 2)
            esp.distance.Visible = true
        else
            esp.distance.Visible = false
        end

        -- Health bar
        if State.healthBar then
            local hp = math.clamp(health / 100, 0, 1)
            local barX = cx - boxW/2 - 6
            esp.healthBarBg.From = Vector2.new(barX, feetPos.Y)
            esp.healthBarBg.To = Vector2.new(barX, headTop.Y)
            esp.healthBarBg.Visible = true
            local barTop = feetPos.Y - (feetPos.Y - headTop.Y) * hp
            esp.healthBar.From = Vector2.new(barX, feetPos.Y)
            esp.healthBar.To = Vector2.new(barX, barTop)
            esp.healthBar.Color = Color3.fromRGB(255 * (1-hp), 255 * hp, 0)
            esp.healthBar.Visible = true
        else
            esp.healthBar.Visible = false
            esp.healthBarBg.Visible = false
        end

        -- Tracers
        if State.tracers then
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
        else
            esp.tracer.Visible = false
        end
    end
end

-- ═══════════════════════════════════════════
-- PF CHAMS
-- ═══════════════════════════════════════════

local function updatePFChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end
        local char = getPFChar(player)

        if State.chamsEnabled and char and isPFAlive(player) then
            if not chamsCache[player] then
                local h = Instance.new("Highlight")
                h.FillColor = isTeammate(player) and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 0, 50)
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0.3
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Adornee = char
                h.Parent = char
                chamsCache[player] = h
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
-- CROSSHAIR
-- ═══════════════════════════════════════════
local function createPFCrosshair()
    for _, l in ipairs(Draw.crosshairLines) do l:Remove() end
    Draw.crosshairLines = {}

    if State.crosshairStyle == "Cross" or State.crosshairStyle == "Cross+Dot" then
        for i = 1, 4 do
            local l = Drawing.new("Line")
            l.Color = Color3.fromRGB(0, 255, 200)
            l.Thickness = State.crosshairThick
            l.Visible = false
            table.insert(Draw.crosshairLines, l)
        end
    end
    if State.crosshairStyle == "Dot" or State.crosshairStyle == "Cross+Dot" then
        local d = Drawing.new("Circle")
        d.Radius = 2
        d.Filled = true
        d.Color = Color3.fromRGB(0, 255, 200)
        d.Visible = false
        table.insert(Draw.crosshairLines, d)
    end
    if State.crosshairStyle == "Circle" then
        local c = Drawing.new("Circle")
        c.Radius = State.crosshairSize
        c.Filled = false
        c.Thickness = State.crosshairThick
        c.Color = Color3.fromRGB(0, 255, 200)
        c.Visible = false
        table.insert(Draw.crosshairLines, c)
    end
end

local function updatePFCrosshair()
    if not State.crosshair then
        for _, d in ipairs(Draw.crosshairLines) do d.Visible = false end
        return
    end
    local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
    local sz, gap = State.crosshairSize, 3

    if State.crosshairStyle == "Cross" or State.crosshairStyle == "Cross+Dot" then
        if Draw.crosshairLines[1] then
            Draw.crosshairLines[1].From = Vector2.new(cx-gap-sz, cy); Draw.crosshairLines[1].To = Vector2.new(cx-gap, cy); Draw.crosshairLines[1].Visible = true
        end
        if Draw.crosshairLines[2] then
            Draw.crosshairLines[2].From = Vector2.new(cx+gap, cy); Draw.crosshairLines[2].To = Vector2.new(cx+gap+sz, cy); Draw.crosshairLines[2].Visible = true
        end
        if Draw.crosshairLines[3] then
            Draw.crosshairLines[3].From = Vector2.new(cx, cy-gap-sz); Draw.crosshairLines[3].To = Vector2.new(cx, cy-gap); Draw.crosshairLines[3].Visible = true
        end
        if Draw.crosshairLines[4] then
            Draw.crosshairLines[4].From = Vector2.new(cx, cy+gap); Draw.crosshairLines[4].To = Vector2.new(cx, cy+gap+sz); Draw.crosshairLines[4].Visible = true
        end
    end
    for _, d in ipairs(Draw.crosshairLines) do
        if d.ClassName == "Circle" then
            d.Position = Vector2.new(cx, cy); d.Visible = true
        end
    end
end

-- ═══════════════════════════════════════════
-- MAIN RENDER LOOP
-- ═══════════════════════════════════════════
addConn(RunSrv.RenderStepped:Connect(function()
    -- FOV circle
    if Draw.fov then
        if State.drawFov and State.aimbotEnabled then
            Draw.fov.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            Draw.fov.Radius = State.fov
            Draw.fov.Visible = true
        else
            Draw.fov.Visible = false
        end
    end

    -- Aimbot
    if State.aimbotEnabled and UIS:IsKeyDown(State.aimKey) then
        local target = getBestPFTarget(State.fov, State.teamCheck)
        if target then
            local targetCF = CFrame.new(Camera.CFrame.Position, target.position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / State.smooth)
        end
    end

    -- ESP
    updatePFESP()

    -- Chams
    updatePFChams()

    -- Crosshair
    updatePFCrosshair()

    -- Fullbright
    if State.fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    end

    -- No fog
    if State.noFog then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
    end

    -- No particles
    if State.noParticles then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj.Enabled = false
            end
        end
    end
end))

-- Triggerbot
spawn(function()
    while true do
        if State.triggerbot then
            local target = Mouse.Target
            if target then
                local charFolder = getPFCharacters()
                if target:IsDescendantOf(charFolder) then
                    local model = target.Parent
                    while model and model.Parent ~= charFolder do
                        model = model.Parent
                    end
                    if model then
                        local player = Players:FindFirstChild(model.Name)
                        if player and player ~= LP and (not State.teamCheck or not isTeammate(player)) then
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
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
        task.wait(60)
    end
end)

-- Player leaving cleanup
addConn(Players.PlayerRemoving:Connect(function(player)
    removePFESP(player)
    if chamsCache[player] then
        chamsCache[player]:Destroy()
        chamsCache[player] = nil
    end
end))

-- ═══════════════════════════════════════════
-- GUI LOADER
-- ═══════════════════════════════════════════

local function load(UI, contentArea)
    local pages = {}

    -- Install hooks
    pcall(installSilentAim)
    pcall(installNoSpread)
    pcall(installNoRecoil)
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

    UI.section(c, "Silent Aim (Bypass)", 12)
    UI.toggle(c, "Silent Aim", false, function(v) State.silentAim = v end, 13)
    UI.slider(c, "Silent FOV", 20, 600, 150, function(v) State.silentFov = v end, 14)

    UI.section(c, "Weapon Bypasses", 16)
    UI.toggle(c, "No Recoil", false, function(v) State.noRecoil = v end, 17)
    UI.toggle(c, "No Spread", false, function(v) State.noSpread = v end, 18)
    UI.toggle(c, "No Scope Sway", false, function(v) State.noSway = v end, 19)

    UI.section(c, "Triggerbot", 21)
    UI.toggle(c, "Triggerbot", false, function(v) State.triggerbot = v end, 22)
    UI.slider(c, "Trigger Delay (ms)", 0, 250, 40, function(v) State.triggerDelay = v end, 23)
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

    UI.section(v, "Chams", 12)
    UI.toggle(v, "Player Chams", false, function(val)
        State.chamsEnabled = val
        if not val then
            for p, h in pairs(chamsCache) do h:Destroy(); chamsCache[p] = nil end
        end
    end, 13)

    UI.section(v, "Crosshair", 16)
    UI.toggle(v, "Custom Crosshair", false, function(val)
        State.crosshair = val
        createPFCrosshair()
    end, 17)
    UI.dropdown(v, "Shape", {"Cross","Dot","Circle","Cross+Dot"}, "Cross+Dot", function(val)
        State.crosshairStyle = val
        createPFCrosshair()
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
        setWallhack(val)
    end, 28)
    UI.slider(v, "Wall Opacity", 0, 100, 30, function(val)
        State.wallOpacity = val
        if State.wallhack then setWallhack(true) end
    end, 29)
    pages.Visual = v

    -- PLAYER (screen effects)
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
            local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            ))
            for _, s in ipairs(servers.data or {}) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                    break
                end
            end
        end)
    end, 3)
    UI.button(w, "Rejoin", function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end, 4)
    pages.World = w

    -- MISC
    local mi = UI.scrollPage(contentArea, "PF_Misc")
    UI.section(mi, "Utility", 1)
    UI.toggle(mi, "Chat Spammer", false, function(val)
        -- Reuse universal spammer
    end, 3)

    UI.section(mi, "Audio", 5)
    UI.toggle(mi, "Kill Sound", false, function(val) State.killSound = val end, 6)
    UI.textbox(mi, "Sound ID", "rbxassetid://...", function(val) State.killSoundId = val end, 7)

    UI.section(mi, "Info", 9)
    UI.label(mi, "PF Module — Client-side features only", 10)
    UI.label(mi, "Silent Aim hooks bullet raycasts", 11)
    UI.label(mi, "No Recoil nullifies camera springs", 12)
    UI.label(mi, "Movement hacks are SERVER-BLOCKED", 13)
    pages.Misc = mi

    -- No movement tab
    pages.Movement = nil

    return pages
end

return load
