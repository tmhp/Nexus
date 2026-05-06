--[[
    Phantom Forces Module — Only features that work client-side
    PF is heavily server-authoritative: movement, health, ammo,
    fire rate, bullet physics, and inventory are all server-validated.
    This module only includes client-side visuals and camera-based aim.
]]

local function load(UI, contentArea)
    local pages = {}

    -- COMBAT (camera-based aim only, no server-side exploits)
    local c = UI.scrollPage(contentArea, "PF_Combat")
    UI.section(c, "Aimbot (Camera Lock)", 1)
    UI.toggle(c, "Aimbot Enabled", false, nil, 2)
    UI.dropdown(c, "Target Bone", {"Head","Torso","Pelvis","Closest"}, "Head", nil, 3)
    UI.slider(c, "FOV Circle", 20, 600, 120, nil, 4)
    UI.toggle(c, "Draw FOV", false, nil, 5)
    UI.slider(c, "Smoothing", 1, 40, 6, nil, 6)
    UI.toggle(c, "Aim Prediction", false, nil, 7)
    UI.toggle(c, "Team Check", true, nil, 8)
    UI.toggle(c, "Wall Check", true, nil, 9)
    UI.keybind(c, "Aim Key", Enum.KeyCode.E, nil, 10)
    UI.section(c, "Triggerbot", 12)
    UI.toggle(c, "Triggerbot", false, nil, 13)
    UI.slider(c, "Trigger Delay (ms)", 0, 250, 40, nil, 14)
    pages.Combat = c

    -- VISUAL (all client-side rendering)
    local v = UI.scrollPage(contentArea, "PF_Visual")
    UI.section(v, "ESP", 1)
    UI.toggle(v, "Player ESP", false, nil, 2)
    UI.toggle(v, "Box ESP", false, nil, 3)
    UI.dropdown(v, "Box Style", {"2D","Corner","3D"}, "Corner", nil, 4)
    UI.toggle(v, "Name Tags", false, nil, 5)
    UI.toggle(v, "Health Bar", false, nil, 6)
    UI.toggle(v, "Distance Tag", false, nil, 7)
    UI.toggle(v, "Tracers", false, nil, 8)
    UI.dropdown(v, "Tracer Origin", {"Bottom","Center","Mouse"}, "Bottom", nil, 9)
    UI.section(v, "Chams", 12)
    UI.toggle(v, "Player Chams", false, nil, 13)
    UI.toggle(v, "Visible Only", false, nil, 14)
    UI.section(v, "Crosshair", 16)
    UI.toggle(v, "Custom Crosshair", false, nil, 17)
    UI.dropdown(v, "Shape", {"Cross","Dot","Circle","Cross+Dot"}, "Cross+Dot", nil, 18)
    UI.slider(v, "Size", 2, 30, 8, nil, 19)
    UI.slider(v, "Thickness", 1, 6, 2, nil, 20)
    UI.section(v, "World Visuals", 22)
    UI.toggle(v, "Fullbright", false, nil, 23)
    UI.toggle(v, "No Fog", false, nil, 24)
    UI.toggle(v, "No Particles", false, nil, 25)
    UI.toggle(v, "No Scope Overlay", false, nil, 26)
    UI.toggle(v, "Remove Debris", false, nil, 27)
    UI.toggle(v, "Transparent Walls", false, nil, 28)
    UI.slider(v, "Wall Opacity", 0, 100, 30, nil, 29)
    pages.Visual = v

    -- PLAYER (client-side visual tweaks only)
    local pl = UI.scrollPage(contentArea, "PF_Player")
    UI.section(pl, "Screen Effects", 1)
    UI.toggle(pl, "No Flash", false, nil, 2)
    UI.toggle(pl, "No Flinch (Visual)", false, nil, 3)
    UI.toggle(pl, "Anti-Suppression", false, nil, 4)
    pages.Player = pl

    -- WORLD
    local w = UI.scrollPage(contentArea, "PF_World")
    UI.section(w, "Server", 1)
    UI.toggle(w, "Anti-AFK", false, nil, 2)
    UI.button(w, "Server Hop", nil, 3)
    UI.button(w, "Rejoin", nil, 4)
    pages.World = w

    -- MISC
    local mi = UI.scrollPage(contentArea, "PF_Misc")
    UI.section(mi, "Utility", 1)
    UI.toggle(mi, "FPS Unlocker", false, nil, 2)
    UI.toggle(mi, "Chat Spammer", false, nil, 3)
    UI.section(mi, "Audio", 5)
    UI.toggle(mi, "Kill Sound", false, nil, 6)
    UI.textbox(mi, "Sound ID", "rbxassetid://...", nil, 7)
    UI.section(mi, "Info", 9)
    UI.toggle(mi, "Kill Feed Logger", false, nil, 10)
    pages.Misc = mi

    -- No Movement tab — PF server-validates all movement
    pages.Movement = nil

    return pages
end

return load
