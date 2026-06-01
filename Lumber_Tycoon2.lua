-- States
local isOwnedLogsEspEnabled = UI.GetValue("ownedlogesp_enabled") or false
local ownedLogNameColor = Color3.fromRGB(0, 255, 0)

-- Workspaces
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local logModels = game.Workspace.LogModels

-- Locations
teleport_locations = {
	wood_r_us = Vector3.new(243.56, 3, 56.38),
	land_store = Vector3.new(243.23, 3, -99.56),
	fancy_furnishings = Vector3.new(490.67, 3.20, -1693.19),
	boxed_cars = Vector3.new(511.90, 3.19, -1483.77),
	bobs_shack = Vector3.new(248.06, 8.40, -2538.49),
	links_logic = Vector3.new(4606.95, 7, -766.94), 
	wood_dropoff = Vector3.new(322.27, -2.80, 136.83)
}
biome_teleport_locations = {
	main_biome = Vector3.new(-135.86, 22, 205.03),
	safari = Vector3.new(-118.07, 3, -1904.73),
	swamp = Vector3.new(-1029.14, 131.60, -1145.41),
	montainside = Vector3.new(-1163.08, 295.40, 838.99),
	cherry_meadow = Vector3.new(223.42, 59.80, 1277.99),
	taiga = Vector3.new(953.96, 59.80, 1827.92),
	taiga_dugout = Vector3.new(1472.59, 412.37, 3258.63),
	tropics = Vector3.new(4887.97, 2.80, -80.78),
	main_sand_island = Vector3.new(2589.36, -5.90, -23.58),
	tropics_sand_island = Vector3.new(4313.09, -5.90, -1822.30),
	volcano = Vector3.new(-1588.55, 623, 1058.12)
}

-- Get Owned Logs
function getOwnedLogs()
    local ownedLogs = {}
    for _, tree in logModels:GetChildren() do
        local owner = tree:FindFirstChild("Owner")
        if owner then
            local ownerString = owner:FindFirstChild("OwnerString")
            if ownerString and ownerString.Value == player.Name then
                table.insert(ownedLogs, tree)
            end
        end
    end
    return ownedLogs
end

-- Check if specified tree is owned (For ESP)
function isOwnedTree(tree)
    local owner = tree:FindFirstChild("Owner")
    local ownerString = owner and owner:FindFirstChild("OwnerString")
    return ownerString and ownerString.Value == player.Name
end

-- Set Player Position
function setPlayerPosition(position)
    local rootPart = character:WaitForChild("HumanoidRootPart")
    rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    rootPart.CFrame = CFrame.new(position.X, position.Y, position.Z)
end

-- Get Player Position
function getPlayerPosition()
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local position = rootPart.Position
    return position 
end

-- Get tree names (From owned logs for combobox)
function getTreeNames()
    local tree_names = {}
    for _, tree in ipairs(getOwnedLogs()) do
        table.insert(tree_names, tree.Name)
    end
    return tree_names
end

-- Get a tree position
function getTreePos(tree)
	for _, branch in ipairs(tree:GetChildren()) do
		if branch:IsA("BasePart") then
			return branch.Position
		end
	end
	return nil
end

-- Teleport log to pos
function teleportLogs(log, pos)
	local cf = CFrame.new(pos.X, pos.Y, pos.Z)
	for i = 1, 20 do
		for _, part in ipairs(log:GetChildren()) do
			if part:IsA("BasePart") then
				part.CFrame = cf
			end
		end
		task.wait(0.5)
	end
end

-- ESP
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

local lastScan = 0
task.spawn(function()
    while true do
        local now = os.clock()
        if now - lastScan >= 1 then
            lastScan = now
            for _, tree in ipairs(logModels:GetChildren()) do
                if isOwnedTree(tree) then
                    for _, item in ipairs(tree:GetChildren()) do
                        if item:IsA("BasePart") and item.Name == "InnerWood" then
                            addEspItem(item)
                        end
                    end
                end
            end
            for addr, t in pairs(espList) do
                if not addr or not addr.Parent then
                    removeEspItem(addr)
                end
            end
        end
        task.wait(0.2)
    end
end)

task.spawn(function()
    while true do
        if isOwnedLogsEspEnabled then
            for _, item in pairs(espList) do
                local part = item.part
                if part and part.Parent then
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
        task.wait(0.016)
    end
end)

UI.AddTab("Lumberboog", function(tab)
	-- Tree teleport Section
    local tree_teleport_Sec = tab:Section("Tree Teleport", "Left")

    local treeNames = getTreeNames()
    local ownedTreesCombo = tree_teleport_Sec:Combo("tree_select", "Owned Trees", treeNames, 0)

    tree_teleport_Sec:Button("Refresh", function()
        ownedTreesCombo:Clear()
        for _, name in ipairs(getTreeNames()) do
            ownedTreesCombo:Add(name)
        end
    end)

    tree_teleport_Sec:Button("Teleport To Tree", function()
        local logs = getOwnedLogs()
        print("Owned logs found:", #logs)
        local idx = ownedTreesCombo.value + 1
        print("Selected index:", idx)
        local selected = logs[idx]
        if not selected then
            print("No tree selected")
            return
        end
        local pos = getTreePos(selected)
        print("Tree pos:", pos)
        if pos then
            setPlayerPosition(pos)
        end
    end)

	tree_teleport_Sec:Button("Teleport Tree To Dropoff", function()
		local logs = getOwnedLogs()
        print("Owned logs found:", #logs)
		local idx = ownedTreesCombo.value + 1
        print("Selected index:", idx)
        local selected = logs[idx]
        if not selected then
            print("No tree selected")
            return
        end
        teleportLogs(selected, teleport_locations.wood_dropoff)
    end)

	-- Player Teleport Section
	local player_teleport_sec = tab:Section("Player Teleport", "Right")

	local teleportNames = {}
	for name, _ in pairs(teleport_locations) do
	    table.insert(teleportNames, name)
	end
    table.sort(teleportNames)
	local tpCombo = player_teleport_sec:Combo("tp_select", "Locations", teleportNames, 0)

	player_teleport_sec:Button("Teleport", function()
	    local selectedName = tpCombo:GetText()
	    local position = teleport_locations[selectedName]
	    if position then
	        setPlayerPosition(position)
	    end
	end)

	local teleportBiomesNames = {}
	for name, _ in pairs(biome_teleport_locations) do
		table.insert(teleportBiomesNames, name)
	end
	table.sort(teleportBiomesNames)
	local tpBiomeCombo = player_teleport_sec:Combo("tp_biome_select", "Biomes", teleportBiomesNames, 0)

	player_teleport_sec:Button("Teleport Biome", function()
		local selectedName = tpBiomeCombo:GetText()
	    local position = biome_teleport_locations[selectedName]
	    if position then
	        setPlayerPosition(position)
	    end
	end)

	-- ESP Section
    local esp_sec = tab:Section("ESP", "Left")
	esp_sec:Toggle("ownedlogesp_enabled", "Owned Log ESP", false, function(v)
        isOwnedLogsEspEnabled = v
    end)
	esp_sec:ColorPicker("owned_log_color", 1, 1, 1, 1, function(c)
        ownedLogNameColor = c
    end)
end)
