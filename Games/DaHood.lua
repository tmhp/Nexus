--[[
    Da Hood Module — Client-side / working features only
    Da Hood has minimal anti-cheat. Movement, combat, and most exploits work.
    Server validates: health (god mode unreliable), cash amounts.
]]

local function load(UI, contentArea)
    local pages = {}

    -- COMBAT
    local c = UI.scrollPage(contentArea, "DH_Combat")
    UI.section(c, "Aimlock", 1)
    UI.toggle(c, "Aimlock Enabled", false, nil, 2)
    UI.keybind(c, "Lock Key", Enum.KeyCode.E, nil, 3)
    UI.dropdown(c, "Lock Part", {"Head","Torso","Random"}, "Head", nil, 4)
    UI.slider(c, "Lock FOV", 30, 600, 200, nil, 5)
    UI.toggle(c, "Prediction", true, nil, 6)
    UI.slider(c, "Prediction Factor", 1, 30, 12, nil, 7)
    UI.toggle(c, "Visible Check", false, nil, 8)
    UI.section(c, "Triggerbot", 10)
    UI.toggle(c, "Auto Shoot", false, nil, 11)
    UI.toggle(c, "Silent Aim", false, nil, 12)
    UI.section(c, "Melee", 15)
    UI.toggle(c, "Auto Stomp", false, nil, 16)
    UI.toggle(c, "Auto Pickup", false, nil, 17)
    UI.toggle(c, "Grab Aura", false, nil, 18)
    pages.Combat = c

    -- MOVEMENT (Da Hood is very lenient)
    local m = UI.scrollPage(contentArea, "DH_Movement")
    UI.section(m, "Speed", 1)
    UI.toggle(m, "Speed Hack", false, nil, 2)
    UI.slider(m, "Walk Speed", 16, 200, 60, nil, 3)
    UI.section(m, "Flight", 5)
    UI.toggle(m, "Fly", false, nil, 6)
    UI.slider(m, "Fly Speed", 10, 300, 80, nil, 7)
    UI.toggle(m, "Noclip", false, nil, 8)
    UI.toggle(m, "Infinite Jump", false, nil, 9)
    pages.Movement = m

    -- VISUAL
    local v = UI.scrollPage(contentArea, "DH_Visual")
    UI.section(v, "ESP", 1)
    UI.toggle(v, "Player ESP", false, nil, 2)
    UI.toggle(v, "Box ESP", false, nil, 3)
    UI.toggle(v, "Tracers", false, nil, 4)
    UI.toggle(v, "Show Cash", false, nil, 5)
    UI.toggle(v, "Show Gun", false, nil, 6)
    UI.toggle(v, "Dropped Item ESP", false, nil, 7)
    UI.section(v, "World", 10)
    UI.toggle(v, "Fullbright", false, nil, 11)
    UI.toggle(v, "No Fog", false, nil, 12)
    pages.Visual = v

    -- PLAYER
    local pl = UI.scrollPage(contentArea, "DH_Player")
    UI.section(pl, "Character", 1)
    UI.toggle(pl, "No Ragdoll", false, nil, 2)
    UI.toggle(pl, "Anti-Stomp", false, nil, 3)
    pages.Player = pl

    -- WORLD
    local w = UI.scrollPage(contentArea, "DH_World")
    UI.section(w, "Server", 1)
    UI.toggle(w, "Anti-AFK", false, nil, 2)
    UI.button(w, "Server Hop", nil, 3)
    UI.button(w, "Rejoin", nil, 4)
    UI.section(w, "Teleports", 6)
    UI.button(w, "TP: Gun Store", nil, 7)
    UI.button(w, "TP: Bank", nil, 8)
    UI.button(w, "TP: Gas Station", nil, 9)
    UI.button(w, "TP: Taco Shop", nil, 10)
    pages.World = w

    -- MISC
    local mi = UI.scrollPage(contentArea, "DH_Misc")
    UI.section(mi, "Utility", 1)
    UI.toggle(mi, "FPS Unlocker", false, nil, 2)
    UI.toggle(mi, "Anti-Kick", false, nil, 3)
    UI.toggle(mi, "Chat Spammer", false, nil, 4)
    UI.section(mi, "Troll", 6)
    UI.toggle(mi, "Fling Player", false, nil, 7)
    UI.toggle(mi, "Invisible", false, nil, 8)
    pages.Misc = mi

    return pages
end

return load
