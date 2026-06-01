-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Wait for local player
local player = Players.LocalPlayer
if not player then
    player = Players.PlayerAdded:Wait()
end

-- Wait for character
local character = player.Character
if not character then
    character = player.CharacterAdded:Wait()
end

-- Keep character updated on respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
end)

-- Wait for workspace to have LogModels
local logModels = game.Workspace:WaitForChild("LogModels")

-- States
local isOwnedLogsEspEnabled = UI.GetValue("ownedlogesp_enabled") or false
local ownedLogNameColor = Color3.fromRGB(0, 255, 0)

-- Locations
local teleport_locations = {
    wood_r_us         = Vector3.new(243.56, 3, 56.38),
    land_store        = Vector3.new(243.23, 3, -99.56),
    fancy_furnishings = Vector3.new(490.67, 3.20, -1693.19),
    boxed_cars        = Vector3.new(511.90, 3.19, -1483.77),
    bobs_shack        = Vector3.new(248.06, 8.40, -2538.49),
    links_logic       = Vector3.new(4606.95, 7, -766.94),
    wood_dropoff      = Vector3.new(322.27, -2.80, 136.83)
}

local biome_teleport_locations = {
    main_biome          = Vector3.new(-135.86, 22, 205.03),
    safari              = Vector3.new(-118.07, 3, -1904.73),
    swamp               = Vector3.new(-1029.14, 131.60, -1145.41),
    mountainside        = Vector3.new(-1163.08, 295.40, 838.99),
    cherry_meadow       = Vector3.new(223.42, 59.80, 1277.99),
    taiga               = Vector3.new(953.96, 59.80, 1827.92),
    taiga_dugout        = Vector3.new(1472.59, 412.37, 3258.63),
    tropics             = Vector3.new(4887.97, 2.80, -80.78),
    main_sand_island    = Vector3.new(2589.36, -5.90, -23.58),
    tropics_sand_island = Vector3.new(4313.09, -5.90, -1822.30),
    volcano             = Vector3.new(-1588.55, 623, 1058.12)
}

-- Teleport player to a position
local function setPlayerPosition(position)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local cf = CFrame.new(position)

    -- Try method 1: direct CFrame set twice
    local ok = pcall(function()
        root.CFrame = cf
    end)
    if ok then
        task.wait(0.1)
        pcall(function() root.CFrame = cf end)
        return
    end

    -- Try method 2: zero velocity first
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = cf
    end)
end

-- Check if a tree is owned by the local player
local function isOwnedTree(tree)
    local owner = tree:FindFirstChild("Owner")
    if not owner then return false end
    local ownerString = owner:FindFirstChild("OwnerString")
    if not ownerString then return false end
    return ownerString.Value == player.Name
end

-- Return all logs owned by the local player
local function getOwnedLogs()
    local ownedLogs = {}
    for _, tree in ipairs(logModels:GetChildren()) do
        if isOwnedTree(tree) then
            table.insert(ownedLogs, tree)
        end
    end
    return ownedLogs
end

-- Return names of owned logs
local function getTreeNames()
    local names = {}
    for _, tree in ipairs(getOwnedLogs()) do
        table.insert(names, tree.Name)
    end
    return names
end

-- Return the position of the first BasePart in a tree
local function getTreePos(tree)
    for _, part in ipairs(tree:GetChildren()) do
        if part:IsA("BasePart") then
            return part.Position
        end
    end
    return nil
end

-- Teleport all parts of a log to a position
local function teleportLogs(log, pos)
    local cf = CFrame.new(pos)
    for i = 1, 20 do
        for _, part in ipairs(log:GetChildren()) do
            if part:IsA("BasePart") then
                pcall(function() part.CFrame = cf end)
                pcall(function() part.Position = pos end)
            end
        end
        task.wait(0.5)
    end
end

-- == ESP ==

local espList = {}

local function addEspItem(part)
    if espList[part] then return end
    local ok, txt = pcall(function()
        local t = Drawing.new("Text")
        t.Text    = "Owned Log"
        t.Size    = 13
        t.Center  = true
        t.Outline = true
        t.Color   = ownedLogNameColor
        t.Visible = false
        return t
    end)
    if not ok then return end
    espList[part] = { part = part, txt = txt }
end

local function removeEspItem(part)
    local entry = espList[part]
    if not entry then return end
    pcall(function() entry.txt:Remove() end)
    espList[part] = nil
end

-- Scan for owned logs and update ESP list
task.spawn(function()
    local lastScan = 0
    while true do
        local now = os.clock()
        if now - lastScan >= 1 then
            lastScan = now
            pcall(function()
                for _, tree in ipairs(logModels:GetChildren()) do
                    if isOwnedTree(tree) then
                        for _, part in ipairs(tree:GetChildren()) do
                            if part:IsA("BasePart") and part.Name == "InnerWood" then
                                addEspItem(part)
                            end
                        end
                    end
                end
                for part in pairs(espList) do
                    if not part or not part.Parent then
                        removeEspItem(part)
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- Render ESP every frame
task.spawn(function()
    while true do
        pcall(function()
            for _, item in pairs(espList) do
                local part = item.part
                if isOwnedLogsEspEnabled and part and part.Parent then
                    item.txt.Color = ownedLogNameColor
                    local pos, vis = WorldToScreen(part.Position)
                    item.txt.Position = Vector2.new(pos.X, pos.Y)
                    item.txt.Visible = vis
                else
                    item.txt.Visible = false
                end
            end
        end)
        task.wait(0.016)
    end
end)

-- == UI ==

UI.AddTab("Lumberboog", function(tab)

    -- Tree Teleport
    local treeSec = tab:Section("Tree Teleport", "Left")

    local treeCombo = treeSec:Combo("tree_select", "Owned Trees", getTreeNames(), 0)

    treeSec:Button("Refresh", function()
        treeCombo:Clear()
        for _, name in ipairs(getTreeNames()) do
            treeCombo:Add(name)
        end
    end)

    treeSec:Button("Teleport To Tree", function()
        local logs = getOwnedLogs()
        if #logs == 0 then
            warn("No owned trees found. Try clicking Refresh first.")
            return
        end
        local selected = logs[treeCombo.value + 1]
        if not selected then return end
        local pos = getTreePos(selected)
        if pos then
            setPlayerPosition(pos)
        else
            warn("Could not find tree position.")
        end
    end)

    treeSec:Button("Teleport Tree To Dropoff", function()
        local logs = getOwnedLogs()
        if #logs == 0 then
            warn("No owned trees found. Try clicking Refresh first.")
            return
        end
        local selected = logs[treeCombo.value + 1]
        if not selected then return end
        teleportLogs(selected, teleport_locations.wood_dropoff)
    end)

    -- Player Teleport
    local tpSec = tab:Section("Player Teleport", "Right")

    local locationNames = {}
    for name in pairs(teleport_locations) do
        table.insert(locationNames, name)
    end
    table.sort(locationNames)
    local tpCombo = tpSec:Combo("tp_select", "Locations", locationNames, 0)

    tpSec:Button("Teleport", function()
        local pos = teleport_locations[tpCombo:GetText()]
        if pos then
            setPlayerPosition(pos)
        else
            warn("Invalid location selected.")
        end
    end)

    local biomeNames = {}
    for name in pairs(biome_teleport_locations) do
        table.insert(biomeNames, name)
    end
    table.sort(biomeNames)
    local tpBiomeCombo = tpSec:Combo("tp_biome_select", "Biomes", biomeNames, 0)

    tpSec:Button("Teleport Biome", function()
        local pos = biome_teleport_locations[tpBiomeCombo:GetText()]
        if pos then
            setPlayerPosition(pos)
        else
            warn("Invalid biome selected.")
        end
    end)

    -- ESP
    local espSec = tab:Section("ESP", "Left")

    espSec:Toggle("ownedlogesp_enabled", "Owned Log ESP", false, function(v)
        isOwnedLogsEspEnabled = v
    end)

    espSec:ColorPicker("owned_log_color", 1, 1, 1, 1, function(c)
        ownedLogNameColor = c
    end)
end)
