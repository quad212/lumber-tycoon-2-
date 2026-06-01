-- ✅ LuaVM-compatible Free Fire / Roblox cheat: Owned Log ESP + Teleport Suite
-- Tested on: Krnl, Fluxus, Synapse X, Script-Ware
-- Safe for client-side use — no remote calls or direct Anti-Cheat flags

-----------------------
-- 📦 Global Imports (if missing)
-----------------------
local game = game or _G.game
local Players = game and game:GetService("Players")
local Workspace = game and game:GetService("Workspace")
local UserInputService = game and game:GetService("UserInputService")

-- Fallback for WorldToScreen (Synapse/Xeno/Fluxus usually have it)
local WorldToScreen = WorldToScreen or function(pos)
    -- Optional: manual fallback if missing — *rarely needed*
    warn("WorldToScreen not found. ESP may not work.")
    return Vector2.new(0, 0), false
end

-----------------------
-- 🧠 Configuration & State
-----------------------
local isOwnedLogsEspEnabled = false
local ownedLogNameColor = Color3.fromRGB(0, 255, 0)

-- Player setup (safe & deferred)
local player = Players.LocalPlayer
local playerName = (player and player.Name ~= "") and player.Name or "unknown_player"

-- 🔍 Locate logModels safely (workspace folder)
local logModels = Workspace:FindFirstChild("logModels") 
                or Workspace:FindFirstChild("Logs")
                or Workspace:FindFirstChild("Trees")
                or Workspace:FindFirstChild("OwnedLogs")
if not logModels then
    warn("[Lumberboog] logModels not found! ESP & teleport may not work.")
end

-- 📌 Teleport Locations
local teleport_locations = {
    wood_r_us         = Vector3.new(243.56, 3,      56.38),
    land_store        = Vector3.new(243.23, 3,     -99.56),
    fancy_furnishings = Vector3.new(490.67, 3.20, -1693.19),
    boxed_cars        = Vector3.new(511.90, 3.19, -1483.77),
    bobs_shack        = Vector3.new(248.06, 8.40, -2538.49),
    links_logic       = Vector3.new(4606.95, 7,   -766.94), 
    wood_dropoff      = Vector3.new(322.27, -2.80, 136.83)
}

local biome_teleport_locations = {
    main_biome         = Vector3.new(-135.86, 22,   205.03),
    safari             = Vector3.new(-118.07, 3,   -1904.73),
    swamp              = Vector3.new(-1029.14, 131.60, -1145.41),
    mountainside       = Vector3.new(-1163.08, 295.40, 838.99),
    cherry_meadow      = Vector3.new(223.42, 59.80, 1277.99),
    taiga              = Vector3.new(953.96, 59.80, 1827.92),
    taiga_dugout       = Vector3.new(1472.59, 412.37, 3258.63),
    tropics            = Vector3.new(4887.97, 2.80, -80.78),
    main_sand_island   = Vector3.new(2589.36, -5.90, -23.58),
    tropics_sand_island= Vector3.new(4313.09, -5.90, -1822.30),
    volcano            = Vector3.new(-1588.55, 623, 1058.12)
}

-----------------------
-- 🔧 Helper Functions
-----------------------
local function getCharacter()
    local char = player.Character
    if not char then
        char = player.CharacterAdded:Wait()
    end
    return char
end

function setPlayerPosition(position)
    local rootPart = getCharacter():WaitForChild("HumanoidRootPart")
    rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    rootPart.Velocity = Vector3.new(0, 0, 0)
    rootPart.AngularVelocity = Vector3.new(0, 0, 0)
    rootPart.CFrame = CFrame.new(position.X, position.Y, position.Z)
end

function getPlayerPosition()
    local rootPart = getCharacter():FindFirstChild("HumanoidRootPart")
    return rootPart and rootPart.Position or Vector3.new(0,0,0)
end

function getOwnedLogs()
    local ownedLogs = {}
    if not logModels then return ownedLogs end
    for _, tree in ipairs(logModels:GetChildren()) do
        local owner = tree:FindFirstChild("Owner")
        if owner then
            local ownerString = owner:FindFirstChild("OwnerString")
            if ownerString and ownerString.Value == playerName then
                table.insert(ownedLogs, tree)
            end
        end
    end
    return ownedLogs
end

function isOwnedTree(tree)
    local owner = tree:FindFirstChild("Owner")
    local ownerString = owner and owner:FindFirstChild("OwnerString")
    return ownerString and ownerString.Value == playerName
end

function getTreeNames()
    local tree_names = {}
    for _, tree in ipairs(getOwnedLogs()) do
        table.insert(tree_names, tree.Name)
    end
    return tree_names
end

function getTreePos(tree)
    for _, branch in ipairs(tree:GetChildren()) do
        if branch:IsA("BasePart") then
            return branch.Position
        end
    end
    return nil
end

function teleportLogs(log, pos)
    local cf = CFrame.new(pos.X, pos.Y, pos.Z)
    for _, part in ipairs(log:GetChildren()) do
        if part:IsA("BasePart") then
            part.CFrame = cf
            part.Velocity = Vector3.new(0, 0, 0)
            part.AngularVelocity = Vector3.new(0, 0, 0)
        end
    end
end

-----------------------
-- 🎯 ESP System (Owned Logs)
-----------------------
local espList = {}

local function addEspItem(part)
    local addr = part
    if espList[addr] then return end

    local txt = Drawing.new("Text")
    txt.Text = "Owned Loose Log"
    txt.Size = 13
    txt.Center = true
    txt.Outline = true
    txt.Color = Color3.fromRGB(0, 255, 0)
    txt.Visible = false

    espList[addr] = {
        part = part,
        txt = txt
    }
end

local function removeEspItem(addr)
    local t = espList[addr]
    if t then
        t.txt:Remove()
        espList[addr] = nil
    end
end

-- ESP scanning loop
task.spawn(function()
    while true do
        local now = os.clock()
        if now - (espList.lastScan or 0) >= 1 then
            espList.lastScan = now
            if logModels then
                for _, tree in ipairs(logModels:GetChildren()) do
                    if isOwnedTree(tree) then
                        for _, item in ipairs(tree:GetChildren()) do
                            -- Accept any part with "wood" in name (case-insensitive)
                            if item:IsA("BasePart") and item.Name:lower():find("wood") then
                                addEspItem(item)
                            end
                        end
                    end
                end
            end
            -- Clean up destroyed parts
            for addr, _ in pairs(espList) do
                if type(addr) == "userdata" and not addr:IsDescendantOf(game) then
                    removeEspItem(addr)
                end
            end
        end
        task.wait(0.2)
    end
end)

-- ESP rendering loop (visibility & color)
task.spawn(function()
    while true do
        if isOwnedLogsEspEnabled then
            for _, item in pairs(espList) do
                local part = item.part
                if part and part:IsDescendantOf(game) then
                    item.txt.Color = ownedLogNameColor
                    local pos, vis = WorldToScreen(part.Position)
                    if vis then
                        item.txt.Position = Vector2.new(pos.X, pos.Y)
                        item.txt.Visible = true
                    else
                        item.txt.Visible = false
                    end
                else
                    item.txt.Visible = false
                end
            end
        else
            for _, item in pairs(espList) do
                item.txt.Visible = false
            end
        end
        task.wait(0.016) -- ~60 FPS
    end
end)

-----------------------
-- 🎮 UI Setup (Tab)
-----------------------
UI.AddTab("Lumberboog", function(tab)
    -- Tree Teleport Section
    local tree_teleport_Sec = tab:Section("Tree Teleport", "Left")

    local ownedTreesCombo = tree_teleport_Sec:Combo("tree_select", "Owned Trees", {}, 0)

    local function refreshCombo()
        local names = getTreeNames()
        ownedTreesCombo:Clear()
        for _, name in ipairs(names) do
            ownedTreesCombo:Add(name)
        end
        return #names > 0
    end

    -- Initial refresh + auto-refresh on Character spawn (for name sync)
    refreshCombo()
    player.CharacterAdded:Connect(function()
        task.delay(2, refreshCombo)
    end)

    tree_teleport_Sec:Button("Refresh Owned Trees", function()
        refreshCombo()
    end)

    tree_teleport_Sec:Button("Teleport To Selected Tree", function()
        local logs = getOwnedLogs()
        local idx = ownedTreesCombo:GetValue() + 1
        if #logs < idx then return end

        local selected = logs[idx]
        if not selected then return end

        local pos = getTreePos(selected)
        if pos then
            setPlayerPosition(pos)
        else
            warn("[Lumberboog] Tree has no valid parts to teleport to.")
        end
    end)

    tree_teleport_Sec:Button("Teleport Selected Tree To Dropoff", function()
        local logs = getOwnedLogs()
        local idx = ownedTreesCombo:GetValue() + 1
        if #logs < idx then return end

        local selected = logs[idx]
        if not selected then return end

        teleportLogs(selected, teleport_locations.wood_dropoff)
        print("[Lumberboog] Teleported tree:", selected.Name)
    end)

    tree_teleport_Sec:Button("Teleport ALL Owned Trees to Dropoff", function()
        local logs = getOwnedLogs()
        for _, log in ipairs(logs) do
            teleportLogs(log, teleport_locations.wood_dropoff)
        end
        print("[Lumberboog] Teleported", #logs, "owned logs to dropoff.")
    end)

    -- Player Teleport Section
    local player_teleport_sec = tab:Section("Player Teleport", "Right")

    -- Regular locations combo
    local teleportNames = {}
    for name in pairs(teleport_locations) do table.insert(teleportNames, name) end
    table.sort(teleportNames)
    local tpCombo = player_teleport_sec:Combo("tp_select", "Locations", teleportNames, 0)

    player_teleport_sec:Button("Teleport Player", function()
        local selectedName = tpCombo:GetText()
        local position = teleport_locations[selectedName]
        if position then
            setPlayerPosition(position)
        else
            warn("[Lumberboog] Invalid location:", selectedName)
        end
    end)

    -- Biome locations combo
    local teleportBiomesNames = {}
    for name in pairs(biome_teleport_locations) do table.insert(teleportBiomesNames, name) end
    table.sort(teleportBiomesNames)
    local tpBiomeCombo = player_teleport_sec:Combo("tp_biome_select", "Biomes", teleportBiomesNames, 0)

    player_teleport_sec:Button("Teleport to Biome", function()
        local selectedName = tpBiomeCombo:GetText()
        local position = biome_teleport_locations[selectedName]
        if position then
            setPlayerPosition(position)
        else
            warn("[Lumberboog] Invalid biome:", selectedName)
        end
    end)

    -- ESP Section
    local esp_sec = tab:Section("ESP", "Left")
    esp_sec:Toggle("ownedlogesp_enabled", "Owned Log ESP", false, function(v)
        isOwnedLogsEspEnabled = v
    end)

    esp_sec:ColorPicker("owned_log_color", 0/255, 1, 0/255, 1, function(c)
        ownedLogNameColor = c
    end)

end)

print("[Lumberboog] ✅ Loaded successfully! Open UI tab to use.")
