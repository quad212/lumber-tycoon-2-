local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Positions
local HOME_POSITION = Vector3.new(-1176, 3.75, -149.54)
local SELL_POSITION = Vector3.new(-1147.74, 3.20, -242.30)

-- Matcha input detection codes
local INPUT_F = "102"
local INPUT_G = "103"

-- Matcha keypress codes
local KEY_E = 101
local KEY_ONE = 49

-- Timing
local ARRIVAL_DELAY = 1.0
local E_HOLD_TIME = 0.35
local MENU_DELAY = 1.0
local ONE_HOLD_TIME = 0.12
local SALE_DELAY = 0.8
local LOOP_DELAY = 3.0

-- State
local loopEnabled = false
local loopRunning = false
local toggleLocked = false
local cycleCount = 0

local function debugPrint(...)
	print("[DEBUG]", ...)
end

local function debugWarn(...)
	warn("[DEBUG]", ...)
end

-- Enable Matcha keyboard input
local setupSuccess, setupError = pcall(function()
	setrobloxinput(true)
end)

if setupSuccess then
	debugPrint("Roblox input enabled")
else
	debugWarn("setrobloxinput failed:", setupError)
end

debugPrint("keypress available:", type(keypress) == "function")
debugPrint("keyrelease available:", type(keyrelease) == "function")

local function getRootPart()
	local character = player.Character

	if not character then
		debugWarn("Character unavailable")
		return nil
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")

	if not hrp then
		hrp = character:WaitForChild("HumanoidRootPart", 5)
	end

	return hrp
end

local function teleport(position, locationName)
	local hrp = getRootPart()

	if not hrp then
		debugWarn("Teleport failed: HumanoidRootPart missing")
		return false
	end

	local success, err = pcall(function()
		hrp.CFrame = CFrame.new(
			position.X,
			position.Y,
			position.Z
		)
	end)

	if success then
		debugPrint(
			"Teleported to",
			locationName,
			position.X,
			position.Y,
			position.Z
		)
	else
		debugWarn("Teleport failed:", err)
	end

	return success
end

local function pressKey(keyCode, keyName, holdTime)
	if type(keypress) ~= "function" then
		debugWarn("keypress unavailable")
		return false
	end

	if type(keyrelease) ~= "function" then
		debugWarn("keyrelease unavailable")
		return false
	end

	debugPrint("Key down:", keyName, "| Code:", keyCode)

	local pressSuccess, pressError = pcall(function()
		keypress(keyCode)
	end)

	if not pressSuccess then
		debugWarn("Key down failed:", keyName, pressError)
		return false
	end

	task.wait(holdTime)

	debugPrint("Key up:", keyName, "| Code:", keyCode)

	local releaseSuccess, releaseError = pcall(function()
		keyrelease(keyCode)
	end)

	if not releaseSuccess then
		debugWarn("Key release failed:", keyName, releaseError)

		pcall(function()
			keyrelease(keyCode)
		end)

		return false
	end

	debugPrint("Key completed:", keyName)
	return true
end

local function waitWhileEnabled(seconds)
	local elapsed = 0

	while elapsed < seconds do
		if not loopEnabled then
			return false
		end

		local step = math.min(0.05, seconds - elapsed)

		task.wait(step)
		elapsed = elapsed + step
	end

	return loopEnabled
end

local function runSellCycle()
	cycleCount = cycleCount + 1
	debugPrint("Starting cycle:", cycleCount)

	-- Teleport to sell location
	if not teleport(SELL_POSITION, "SELL") then
		return false
	end

	debugPrint("Waiting at sell location")

	if not waitWhileEnabled(ARRIVAL_DELAY) then
		return false
	end

	-- Press and hold E
	debugPrint("Pressing E")

	if not pressKey(KEY_E, "E", E_HOLD_TIME) then
		return false
	end

	-- Wait for menu to open after E is released
	debugPrint("E released; waiting for menu")

	if not waitWhileEnabled(MENU_DELAY) then
		return false
	end

	-- Press 1
	debugPrint("Pressing 1")

	if not pressKey(KEY_ONE, "1", ONE_HOLD_TIME) then
		return false
	end

	-- Wait before leaving
	debugPrint("1 released; waiting for sale")

	if not waitWhileEnabled(SALE_DELAY) then
		return false
	end

	-- Return home only after E and 1 finish
	if not teleport(HOME_POSITION, "HOME") then
		return false
	end

	debugPrint("Cycle complete:", cycleCount)
	return true
end

local function startLoop()
	if loopRunning then
		return
	end

	loopRunning = true
	debugPrint("Sell loop started")

	task.spawn(function()
		while loopEnabled do
			local success = runSellCycle()

			if not success and loopEnabled then
				debugWarn("Cycle failed; retrying in 1 second")

				if not waitWhileEnabled(1) then
					break
				end
			elseif loopEnabled then
				debugPrint(
					"Waiting",
					LOOP_DELAY,
					"seconds before next cycle"
				)

				if not waitWhileEnabled(LOOP_DELAY) then
					break
				end
			end
		end

		-- Release keys in case the loop stops during a press
		pcall(function()
			if type(keyrelease) == "function" then
				keyrelease(KEY_E)
				keyrelease(KEY_ONE)
			end
		end)

		loopRunning = false
		debugPrint("Sell loop stopped")
	end)
end

local function toggleLoop()
	if toggleLocked then
		return
	end

	toggleLocked = true
	loopEnabled = not loopEnabled

	if loopEnabled then
		debugPrint("LOOP ON")
		startLoop()
	else
		debugPrint("LOOP OFF")
	end

	task.delay(0.3, function()
		toggleLocked = false
	end)
end

local inputEvent = UIS.InputBegan

if inputEvent == nil then
	debugWarn("InputBegan unavailable")
else
	inputEvent:Connect(function(input)
		if input == nil or input.KeyCode == nil then
			return
		end

		local key = tostring(input.KeyCode)

		-- F manually teleports home
		if key == INPUT_F then
			debugPrint("F pressed")

			task.spawn(function()
				teleport(HOME_POSITION, "HOME")
			end)

			return
		end

		-- G toggles automatic selling
		if key == INPUT_G then
			toggleLoop()
		end
	end)

	debugPrint("Keybind connection successful")
end

debugPrint("Script fully loaded")
debugPrint("F = teleport home")
debugPrint("G = toggle sell loop")
