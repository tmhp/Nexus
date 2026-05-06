--[[
    Universal Module — Works on any Roblox game
    These are generic exploits that target the Roblox engine itself,
    not game-specific remotes or systems.
]]

local function load(UI, contentArea)
    local pages = {}

    -- COMBAT
    local c = UI.scrollPage(contentArea, "UNI_Combat")
    UI.section(c, "Aimbot (Generic)", 1)
    UI.toggle(c, "Aimbot Enabled", false, nil, 2)
    UI.dropdown(c, "Target Part", {"Head","Torso","HumanoidRootPart","Closest"}, "Head", nil, 3)
    UI.slider(c, "FOV Radius", 20, 600, 180, nil, 4)
    UI.toggle(c, "Draw FOV Circle", false, nil, 5)
    UI.slider(c, "Smoothing", 1, 30, 6, nil, 6)
    UI.toggle(c, "Team Check", true, nil, 7)
    UI.toggle(c, "Wall Check", false, nil, 8)
    UI.keybind(c, "Aim Key", Enum.KeyCode.E, nil, 9)
    UI.section(c, "Triggerbot", 11)
    UI.toggle(c, "Triggerbot", false, nil, 12)
    UI.slider(c, "Trigger Delay (ms)", 0, 300, 60, nil, 13)
    pages.Combat = c

    -- MOVEMENT
    local m = UI.scrollPage(contentArea, "UNI_Movement")
    UI.section(m, "Speed", 1)
    UI.toggle(m, "Speed Hack", false, nil, 2)
    UI.slider(m, "Walk Speed", 16, 500, 80, nil, 3)
    UI.section(m, "Flight", 5)
    UI.toggle(m, "Fly", false, nil, 6)
    UI.slider(m, "Fly Speed", 10, 500, 100, nil, 7)
    UI.keybind(m, "Fly Toggle Key", Enum.KeyCode.F, nil, 8)
    UI.section(m, "Misc Movement", 10)
    UI.toggle(m, "Noclip", false, nil, 11)
    UI.toggle(m, "Infinite Jump", false, nil, 12)
    UI.slider(m, "Jump Power", 50, 400, 100, nil, 13)
    UI.toggle(m, "TP to Mouse (Click)", false, nil, 14)
    UI.keybind(m, "TP Key", Enum.KeyCode.T, nil, 15)
    pages.Movement = m

    -- VISUAL
    local v = UI.scrollPage(contentArea, "UNI_Visual")
    UI.section(v, "Player ESP", 1)
    UI.toggle(v, "ESP Enabled", false, nil, 2)
    UI.toggle(v, "Box ESP", false, nil, 3)
    UI.dropdown(v, "Box Style", {"2D","Corner"}, "Corner", nil, 4)
    UI.toggle(v, "Name Tags", false, nil, 5)
    UI.toggle(v, "Health Bar", false, nil, 6)
    UI.toggle(v, "Distance Tag", false, nil, 7)
    UI.toggle(v, "Tracers", false, nil, 8)
    UI.dropdown(v, "Tracer Origin", {"Bottom","Center","Mouse"}, "Bottom", nil, 9)
    UI.section(v, "Chams", 11)
    UI.toggle(v, "Player Chams", false, nil, 12)
    UI.toggle(v, "Visible Only", false, nil, 13)
    UI.section(v, "Rendering", 15)
    UI.toggle(v, "Fullbright", false, nil, 16)
    UI.toggle(v, "No Fog", false, nil, 17)
    UI.toggle(v, "No Shadows", false, nil, 18)
    UI.toggle(v, "No Particles", false, nil, 19)
    pages.Visual = v

    -- PLAYER
    local pl = UI.scrollPage(contentArea, "UNI_Player")
    UI.section(pl, "Character", 1)
    UI.toggle(pl, "Freeze Character", false, nil, 2)
    UI.button(pl, "Reset Character", nil, 3)
    UI.button(pl, "TP to Spawn", nil, 4)
    UI.section(pl, "TP to Player", 6)
    UI.textbox(pl, "Player Name", "username...", nil, 7)
    UI.button(pl, "Teleport", nil, 8)
    pages.Player = pl

    -- WORLD
    local w = UI.scrollPage(contentArea, "UNI_World")
    UI.section(w, "Server", 1)
    UI.toggle(w, "Anti-AFK", false, nil, 2)
    UI.button(w, "Server Hop", nil, 3)
    UI.button(w, "Rejoin", nil, 4)
    UI.section(w, "Players", 6)
    UI.button(w, "Bring All (Client Visual)", nil, 7)
    UI.button(w, "Goto Random Player", nil, 8)
    pages.World = w

    -- MISC
    local mi = UI.scrollPage(contentArea, "UNI_Misc")
    UI.section(mi, "Performance", 1)
    UI.toggle(mi, "FPS Unlocker", false, nil, 2)
    UI.section(mi, "Chat", 4)
    UI.toggle(mi, "Chat Spammer", false, nil, 5)
    UI.textbox(mi, "Spam Message", "Nexus on top", nil, 6)
    UI.slider(mi, "Spam Delay (ms)", 100, 5000, 1000, nil, 7)
    UI.section(mi, "Misc", 9)
    UI.toggle(mi, "Hide Name", false, nil, 10)
    UI.toggle(mi, "Orbit Player", false, nil, 11)
    UI.textbox(mi, "Orbit Target", "username...", nil, 12)
    UI.slider(mi, "Orbit Radius", 5, 50, 15, nil, 13)
    UI.slider(mi, "Orbit Speed", 1, 20, 5, nil, 14)
    pages.Misc = mi

    return pages
end

return load
