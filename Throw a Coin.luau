local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local HOME_POSITION = Vector3.new(-1176, 3.75, -149.54)
local SELL_POSITION = Vector3.new(-1147.74, 3.20, -242.30)

-- Matcha input detection codes
local INPUT_F = "102"
local INPUT_G = "103"

-- Windows virtual-key codes
local KEY_E = 0x45
local KEY_ONE = 0x31

-- Timing
local ARRIVAL_DELAY = 0.35
local E_SPAM_DURATION = 1.25
local E_TAP_GAP = 0.05
local MENU_DELAY = 0.65
local ONE_HOLD_TIME = 0.08
local SALE_DELAY = 0.55
local LOOP_DELAY = 3.0

local DEBUG_ENABLED = true

--==================================================
-- STATE
--==================================================

local loopEnabled = false
local loopRunning = false
local toggleLocked = false
local cycleCount = 0
local runId = 0

--==================================================
-- LOGGING
--==================================================

local function debugPrint(...)
	if DEBUG_ENABLED then
		print("[DEBUG]", ...)
	end
end

local function debugWarn(...)
	warn("[DEBUG]", ...)
end

--==================================================
-- MATCHA SETUP
--==================================================

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

--==================================================
-- HELPERS
--==================================================

local function releaseAllKeys()
	pcall(function()
		if type(keyrelease) == "function" then
			keyrelease(KEY_E)
			keyrelease(KEY_ONE)
		end
	end)

	debugPrint("Released E and 1")
end

local function isWindowFocused()
	if type(isrbxactive) ~= "function" then
		return true
	end

	local success, focused = pcall(isrbxactive)

	if not success then
		return true
	end

	return focused ~= false
end

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

	if not success then
		debugWarn("Teleport failed:", err)
		return false
	end

	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end)

	debugPrint(
		"Teleported to",
		locationName,
		position.X,
		position.Y,
		position.Z
	)

	return true
end

local function shouldContinue(currentRunId)
	return loopEnabled and currentRunId == runId
end

local function interruptibleWait(seconds, currentRunId)
	local endTime = tick() + seconds

	while tick() < endTime do
		if not shouldContinue(currentRunId) then
			return false
		end

		task.wait(0.03)
	end

	return shouldContinue(currentRunId)
end

local function tapKey(keyCode, keyName, holdTime, currentRunId)
	if not shouldContinue(currentRunId) then
		return false
	end

	if type(keypress) ~= "function" then
		debugWarn("keypress unavailable")
		return false
	end

	if type(keyrelease) ~= "function" then
		debugWarn("keyrelease unavailable")
		return false
	end

	if not isWindowFocused() then
		debugWarn("Roblox window is not focused")
		return false
	end

	local success, err = pcall(function()
		keypress(keyCode)

		local endTime = tick() + (holdTime or 0.05)

		while tick() < endTime do
			if not shouldContinue(currentRunId) then
				break
			end

			task.wait(0.01)
		end

		keyrelease(keyCode)
	end)

	pcall(function()
		keyrelease(keyCode)
	end)

	if not success then
		debugWarn("Key failed:", keyName, err)
		return false
	end

	if not shouldContinue(currentRunId) then
		return false
	end

	debugPrint("Tapped key:", keyName)
	return true
end

local function spamE(currentRunId)
	if type(keypress) ~= "function"
		or type(keyrelease) ~= "function" then

		debugWarn("Keyboard functions unavailable")
		return false
	end

	debugPrint("Starting E spam")

	local startedAt = tick()
	local tapCount = 0

	while shouldContinue(currentRunId)
		and tick() - startedAt < E_SPAM_DURATION do

		if isWindowFocused() then
			local success = pcall(function()
				keypress(KEY_E)
				task.wait(0.02)
				keyrelease(KEY_E)
			end)

			if success then
				tapCount = tapCount + 1
			end
		end

		if not interruptibleWait(E_TAP_GAP, currentRunId) then
			break
		end
	end

	pcall(function()
		keyrelease(KEY_E)
	end)

	debugPrint("E spam finished | Taps:", tapCount)

	return shouldContinue(currentRunId) and tapCount > 0
end

--==================================================
-- SELL CYCLE
--==================================================

local function runSellCycle(currentRunId)
	if not shouldContinue(currentRunId) then
		return false
	end

	cycleCount = cycleCount + 1
	debugPrint("Starting cycle:", cycleCount)

	if not teleport(SELL_POSITION, "SELL") then
		return false
	end

	if not interruptibleWait(ARRIVAL_DELAY, currentRunId) then
		return false
	end

	if not spamE(currentRunId) then
		return false
	end

	if not interruptibleWait(MENU_DELAY, currentRunId) then
		return false
	end

	debugPrint("Pressing 1")

	if not tapKey(KEY_ONE, "1", ONE_HOLD_TIME, currentRunId) then
		return false
	end

	if not interruptibleWait(SALE_DELAY, currentRunId) then
		return false
	end

	if not teleport(HOME_POSITION, "HOME") then
		return false
	end

	debugPrint("Cycle complete:", cycleCount)
	return true
end

--==================================================
-- LOOP CONTROL
--==================================================

local function startLoop()
	if loopRunning then
		debugPrint("Loop already running")
		return
	end

	loopRunning = true

	local currentRunId = runId

	debugPrint("Sell loop started")

	task.spawn(function()
		while shouldContinue(currentRunId) do
			local success = runSellCycle(currentRunId)

			if not shouldContinue(currentRunId) then
				break
			end

			if not success then
				debugWarn("Cycle failed; retrying")

				if not interruptibleWait(1, currentRunId) then
					break
				end
			else
				debugPrint(
					"Waiting",
					LOOP_DELAY,
					"seconds before next cycle"
				)

				if not interruptibleWait(LOOP_DELAY, currentRunId) then
					break
				end
			end
		end

		releaseAllKeys()

		if currentRunId == runId then
			loopRunning = false
		else
			loopRunning = false
		end

		debugPrint("Sell loop fully stopped")
	end)
end

local function stopEverything()
	loopEnabled = false
	runId = runId + 1

	debugPrint("Stopping everything")

	releaseAllKeys()

	task.spawn(function()
		teleport(HOME_POSITION, "HOME")
	end)

	debugPrint("LOOP OFF")
end

local function toggleLoop()
	if toggleLocked then
		return
	end

	toggleLocked = true

	if loopEnabled then
		stopEverything()
	else
		runId = runId + 1
		loopEnabled = true

		debugPrint("LOOP ON")
		startLoop()
	end

	task.delay(0.3, function()
		toggleLocked = false
	end)
end

--==================================================
-- KEYBINDS
--==================================================

local inputEvent = UIS.InputBegan

if inputEvent == nil then
	debugWarn("InputBegan unavailable")
else
	inputEvent:Connect(function(input)
		if input == nil or input.KeyCode == nil then
			return
		end

		local key = tostring(input.KeyCode)

		-- F manually stops everything and returns home
		if key == INPUT_F then
			debugPrint("F pressed")
			stopEverything()
			return
		end

		-- G toggles everything
		if key == INPUT_G then
			toggleLoop()
		end
	end)

	debugPrint("Keybind connection successful")
end

debugPrint("Script fully loaded")
debugPrint("F = stop and teleport home")
debugPrint("G = toggle everything")
