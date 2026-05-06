--[[
    Arsenal Module — Client-side / working features only
    Arsenal validates: health, ammo, fire rate, reload, weapon inventory server-side.
    Movement is partially lenient. ESP/aimbot/visuals all work.
]]

local function load(UI, contentArea)
    local pages = {}

    -- COMBAT
    local c = UI.scrollPage(contentArea, "AR_Combat")
    UI.section(c, "Aimbot", 1)
    UI.toggle(c, "Aimbot Enabled", false, nil, 2)
    UI.dropdown(c, "Target Part", {"Head","Torso","Closest"}, "Head", nil, 3)
    UI.slider(c, "FOV Radius", 20, 500, 150, nil, 4)
    UI.slider(c, "Smoothing", 1, 30, 4, nil, 5)
    UI.toggle(c, "Prediction", true, nil, 6)
    UI.toggle(c, "Team Check", true, nil, 7)
    UI.toggle(c, "Wall Check", false, nil, 8)
    UI.section(c, "Triggerbot", 10)
    UI.toggle(c, "Triggerbot", false, nil, 11)
    UI.slider(c, "Trigger Delay (ms)", 0, 200, 50, nil, 12)
    UI.section(c, "Melee", 14)
    UI.toggle(c, "Auto Knife", false, nil, 15)
    UI.toggle(c, "Knife Aura", false, nil, 16)
    pages.Combat = c

    -- MOVEMENT (partially works in Arsenal)
    local m = UI.scrollPage(contentArea, "AR_Movement")
    UI.section(m, "Speed", 1)
    UI.toggle(m, "Speed Hack", false, nil, 2)
    UI.slider(m, "Walk Speed", 16, 80, 30, nil, 3)
    UI.section(m, "Mobility", 5)
    UI.toggle(m, "Fly", false, nil, 6)
    UI.slider(m, "Fly Speed", 10, 120, 50, nil, 7)
    UI.toggle(m, "Noclip", false, nil, 8)
    UI.toggle(m, "Infinite Jump", false, nil, 9)
    pages.Movement = m

    -- VISUAL
    local v = UI.scrollPage(contentArea, "AR_Visual")
    UI.section(v, "ESP", 1)
    UI.toggle(v, "Player ESP", false, nil, 2)
    UI.toggle(v, "Box ESP", false, nil, 3)
    UI.toggle(v, "Name Tags", false, nil, 4)
    UI.toggle(v, "Health Bar", false, nil, 5)
    UI.toggle(v, "Weapon Name", false, nil, 6)
    UI.toggle(v, "Tracers", false, nil, 7)
    UI.section(v, "Chams", 10)
    UI.toggle(v, "Player Chams", false, nil, 11)
    UI.toggle(v, "Through Walls", false, nil, 12)
    UI.section(v, "World", 15)
    UI.toggle(v, "Fullbright", false, nil, 16)
    UI.toggle(v, "No Fog", false, nil, 17)
    UI.toggle(v, "Remove Shadows", false, nil, 18)
    pages.Visual = v

    -- PLAYER (client visual only)
    local pl = UI.scrollPage(contentArea, "AR_Player")
    UI.section(pl, "Weapon Feel", 1)
    UI.toggle(pl, "No Recoil (Visual)", false, nil, 2)
    pages.Player = pl

    -- WORLD
    local w = UI.scrollPage(contentArea, "AR_World")
    UI.section(w, "Server", 1)
    UI.toggle(w, "Anti-AFK", false, nil, 2)
    UI.button(w, "Server Hop", nil, 3)
    UI.button(w, "Rejoin", nil, 4)
    pages.World = w

    -- MISC
    local mi = UI.scrollPage(contentArea, "AR_Misc")
    UI.section(mi, "Utility", 1)
    UI.toggle(mi, "FPS Unlocker", false, nil, 2)
    UI.toggle(mi, "Anti-Kick", false, nil, 3)
    UI.toggle(mi, "Chat Spammer", false, nil, 4)
    UI.toggle(mi, "Kill Sound", false, nil, 5)
    pages.Misc = mi

    return pages
end

return load
