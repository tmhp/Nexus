--[[
    Blox Fruits Module — Client-side / working features only
    BF is lenient on anti-cheat. Movement exploits, ESP, farm bots,
    and TP all work. Server validates: health, inventory storage, area gates.
]]

local function load(UI, contentArea)
    local pages = {}

    -- COMBAT
    local c = UI.scrollPage(contentArea, "BF_Combat")
    UI.section(c, "Aimbot", 1)
    UI.toggle(c, "Fruit Aimbot", false, nil, 2)
    UI.dropdown(c, "Target Part", {"Head","Torso","HumanoidRootPart"}, "Torso", nil, 3)
    UI.slider(c, "FOV Radius", 30, 600, 200, nil, 4)
    UI.slider(c, "Smoothing", 1, 25, 8, nil, 5)
    UI.toggle(c, "Prediction", false, nil, 6)
    UI.toggle(c, "Team Check", true, nil, 7)
    UI.section(c, "Auto Combat", 10)
    UI.toggle(c, "Auto Attack", false, nil, 11)
    UI.toggle(c, "Kill Aura", false, nil, 12)
    UI.slider(c, "Aura Range", 10, 80, 30, nil, 13)
    UI.keybind(c, "Combo Key", Enum.KeyCode.Q, nil, 14)
    pages.Combat = c

    -- MOVEMENT (BF is lenient on movement — these work)
    local m = UI.scrollPage(contentArea, "BF_Movement")
    UI.section(m, "Speed", 1)
    UI.toggle(m, "Speed Hack", false, nil, 2)
    UI.slider(m, "Walk Speed", 16, 500, 100, nil, 3)
    UI.section(m, "Flight", 5)
    UI.toggle(m, "Fly", false, nil, 6)
    UI.slider(m, "Fly Speed", 20, 600, 150, nil, 7)
    UI.toggle(m, "Noclip", false, nil, 8)
    UI.section(m, "Teleport", 10)
    UI.toggle(m, "TP to Player", false, nil, 11)
    UI.button(m, "TP to First Sea", nil, 12)
    UI.button(m, "TP to Second Sea", nil, 13)
    UI.button(m, "TP to Third Sea", nil, 14)
    UI.toggle(m, "Infinite Jump", false, nil, 15)
    UI.slider(m, "Jump Power", 50, 400, 120, nil, 16)
    pages.Movement = m

    -- VISUAL
    local v = UI.scrollPage(contentArea, "BF_Visual")
    UI.section(v, "ESP", 1)
    UI.toggle(v, "Player ESP", false, nil, 2)
    UI.toggle(v, "Fruit ESP", false, nil, 3)
    UI.toggle(v, "Chest ESP", false, nil, 4)
    UI.toggle(v, "NPC ESP", false, nil, 5)
    UI.toggle(v, "Flower ESP", false, nil, 6)
    UI.section(v, "Display", 10)
    UI.toggle(v, "Box ESP", false, nil, 11)
    UI.toggle(v, "Name Tags", false, nil, 12)
    UI.toggle(v, "Health Bar", false, nil, 13)
    UI.toggle(v, "Tracers", false, nil, 14)
    UI.dropdown(v, "Tracer Origin", {"Bottom","Center","Mouse"}, "Bottom", nil, 15)
    UI.section(v, "World", 18)
    UI.toggle(v, "Fullbright", false, nil, 19)
    UI.toggle(v, "No Fog", false, nil, 20)
    pages.Visual = v

    -- PLAYER
    local pl = UI.scrollPage(contentArea, "BF_Player")
    UI.section(pl, "Stats", 1)
    UI.toggle(pl, "Auto Stats", false, nil, 2)
    UI.dropdown(pl, "Stat Priority", {"Melee","Defense","Sword","Fruit"}, "Melee", nil, 3)
    UI.section(pl, "Farm", 5)
    UI.toggle(pl, "Auto Farm", false, nil, 6)
    UI.dropdown(pl, "Farm Mode", {"Nearest NPC","Quest NPCs","Boss Farm"}, "Quest NPCs", nil, 7)
    UI.toggle(pl, "Auto Quest", false, nil, 8)
    UI.toggle(pl, "Auto Collect", false, nil, 9)
    UI.slider(pl, "Farm Radius", 20, 400, 100, nil, 10)
    UI.section(pl, "Fruit", 12)
    UI.toggle(pl, "Auto Eat Fruit", false, nil, 13)
    UI.toggle(pl, "Fruit Sniper", false, nil, 14)
    pages.Player = pl

    -- WORLD
    local w = UI.scrollPage(contentArea, "BF_World")
    UI.section(w, "Server", 1)
    UI.toggle(w, "Anti-AFK", false, nil, 2)
    UI.button(w, "Server Hop", nil, 3)
    UI.button(w, "Rejoin", nil, 4)
    UI.section(w, "Islands", 6)
    UI.button(w, "TP: Pirate Island", nil, 7)
    UI.button(w, "TP: Marine Fort", nil, 8)
    UI.button(w, "TP: Skylands", nil, 9)
    UI.button(w, "TP: Colosseum", nil, 10)
    UI.button(w, "TP: Graveyard", nil, 11)
    UI.button(w, "TP: Ice Island", nil, 12)
    pages.World = w

    -- MISC
    local mi = UI.scrollPage(contentArea, "BF_Misc")
    UI.section(mi, "Utility", 1)
    UI.toggle(mi, "FPS Unlocker", false, nil, 2)
    UI.toggle(mi, "Anti-Kick", false, nil, 3)
    UI.toggle(mi, "Hide Name", false, nil, 4)
    UI.section(mi, "Raids", 6)
    UI.toggle(mi, "Auto Raid", false, nil, 7)
    UI.dropdown(mi, "Raid Type", {"Normal","Elite","Alliance"}, "Normal", nil, 8)
    pages.Misc = mi

    return pages
end

return load
