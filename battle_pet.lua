-- ============================================================
--  Battle Pet  |  QoL Script  (PlaceId: 81272814168643)
--  Executor: Universal / Synapse X / KRNL / Fluxus / Mobile compatible
-- ============================================================
--  Features:
--    ✅ Auto Battle       – fires StartBattle remote repeatedly
--    ✅ Auto Claim        – auto-claims battle rewards
--    ✅ Auto Equip Best   – equips your strongest team before queue
--    ✅ Fast Match Speed  – sets match to 2x speed
--    ✅ Battle Stats HUD  – shows wins/level from live GUI
--    ✅ Notification mute – removes popup sound spam
-- ============================================================

local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local UIS           = game:GetService("UserInputService")
local SoundService  = game:GetService("SoundService")
local LP            = Players.LocalPlayer
local PGui          = LP:WaitForChild("PlayerGui")

-- Remote shortcuts
local Remotes           = RS:WaitForChild("Remotes")
local ClientSignals     = RS:WaitForChild("ClientSignals")

local R_StartBattle      = Remotes:WaitForChild("StartBattle")
local R_ClaimBattleRew   = Remotes:WaitForChild("ClaimBattleRewards")
local R_EquipBestTeam    = Remotes:WaitForChild("EquipBestTeam")
local R_SetMatchSpeed    = Remotes:WaitForChild("SetMatchSpeed")

local S_StartBattleReq  = ClientSignals:WaitForChild("StartBattleRequest")
local S_BattleEnded      = ClientSignals:WaitForChild("BattleEnded")
local S_BattlePrepared  = ClientSignals:WaitForChild("BattlePrepared")

-- ============================================================
--  STATE
-- ============================================================
local Config = {
    AutoBattle      = false,
    AutoClaim       = false,
    AutoEquipBest   = false,
    FastSpeed       = false,
    MutePopups      = false,
    ShowHUD         = true,
}

local inBattle        = false
local battleCount     = 0
local lastBattleTime  = 0
local BATTLE_COOLDOWN = 3  -- seconds between queues

-- ============================================================
--  CORE FUNCTIONS
-- ============================================================

local function Notify(msg)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Battle Pet QoL", Text = msg, Duration = 3
        })
    end)
end

local function QueueBattle()
    if (tick() - lastBattleTime) < BATTLE_COOLDOWN then return end
    lastBattleTime = tick()
    pcall(function() S_StartBattleReq:Fire() end)
end

local function ClaimRewards()
    pcall(function() R_ClaimBattleRew:InvokeServer() end)
end

local function EquipBest()
    pcall(function() R_EquipBestTeam:InvokeServer() end)
end

local function SetSpeed(fast)
    -- 1 = normal, 2 = fast (game's SetMatchSpeed remote)
    pcall(function() R_SetMatchSpeed:InvokeServer(fast and 2 or 1) end)
end

-- ============================================================
--  AUDIO / MUTE CONTROLLER (Universal Listener Engine)
-- ============================================================
local function HandleSound(sound)
    if sound:IsA("Sound") then
        local function checkMute()
            if Config.MutePopups then
                local name = string.lower(sound.Name)
                if name:find("popup") or name:find("claim") or name:find("reward") or name:find("notification") or name:find("win") then
                    sound.Volume = 0
                end
            end
        end
        sound:GetPropertyChangedSignal("Playing"):Connect(function()
            if sound.Playing then checkMute() end
        end)
        if sound.Playing then checkMute() end
    end
end

-- Listen everywhere game sounds typically spawn
game.DescendantAdded:Connect(HandleSound)
for _, desc in ipairs(game:GetDescendants()) do
    task.spawn(HandleSound, desc)
end

-- ============================================================
--  AUTO BATTLE LOOP
-- ============================================================
S_BattleEnded.Event:Connect(function()
    inBattle = false
    battleCount += 1

    task.wait(0.5)

    if Config.AutoClaim then
        task.wait(0.3)
        ClaimRewards()
        pcall(function()
            local btn = PGui:FindFirstChild("Round", true)
            if btn then
                local none = btn:FindFirstChild("None", true)
                if none and none:IsA("GuiButton") then none:Fire("MouseButton1Click") end
            end
        end)
    end

    if Config.AutoBattle then
        task.wait(1.5)
        if Config.AutoEquipBest then EquipBest() task.wait(0.3) end
        QueueBattle()
    end
end)

S_BattlePrepared.Event:Connect(function()
    inBattle = true
    if Config.FastSpeed then SetSpeed(true) end
end)

-- ============================================================
--  GUI
-- ============================================================
if PGui:FindFirstChild("BattlePetQoL_GUI") then
    PGui:FindFirstChild("BattlePetQoL_GUI"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name              = "BattlePetQoL_GUI"
ScreenGui.ResetOnSpawn      = false
ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder      = 999

-- Compatibility safeguards for protected GUIs
pcall(function() 
    if syn and syn.protect_gui then 
        syn.protect_gui(ScreenGui) 
    end 
end)
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = PGui end

local Main = Instance.new("Frame", ScreenGui)
Main.Name              = "Main"
Main.Size              = UDim2.new(0, 220, 0, 340)
Main.Position          = UDim2.new(0, 16, 0.5, -170)
Main.BackgroundColor3  = Color3.fromRGB(15, 15, 22)
Main.BorderSizePixel   = 0
Main.Active            = true
Main.Draggable         = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local mStroke = Instance.new("UIStroke", Main)
mStroke.Color = Color3.fromRGB(80, 180, 255); mStroke.Thickness = 1.5

local TBar = Instance.new("Frame", Main)
TBar.Size = UDim2.new(1,0,0,34); TBar.BackgroundColor3 = Color3.fromRGB(30,100,200)
TBar.BorderSizePixel = 0
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0,10)
local TFix = Instance.new("Frame", TBar)
TFix.Size = UDim2.new(1,0,0.5,0); TFix.Position = UDim2.new(0,0,0.5,0)
TFix.BackgroundColor3 = Color3.fromRGB(30,100,200); TFix.BorderSizePixel = 0
local TLbl = Instance.new("TextLabel", TBar)
TLbl.Size = UDim2.new(1,-8,1,0); TLbl.Position = UDim2.new(0,8,0,0)
TLbl.BackgroundTransparency = 1; TLbl.TextColor3 = Color3.new(1,1,1)
TLbl.Font = Enum.Font.GothamBold; TLbl.TextSize = 14
TLbl.TextXAlignment = Enum.TextXAlignment.Left
TLbl.Text = "⚔  Battle Pet  QoL"

local CloseBtn = Instance.new("TextButton", TBar)
CloseBtn.Size = UDim2.new(0,26,0,26); CloseBtn.Position = UDim2.new(1,-30,0,4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13; CloseBtn.Text = "✕"; CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,6)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local Hint = Instance.new("TextLabel", ScreenGui)
Hint.Size = UDim2.new(0,170,0,20); Hint.Position = UDim2.new(0,16,0,6)
Hint.BackgroundColor3 = Color3.fromRGB(15,15,22)
Hint.BackgroundTransparency = 0.3; Hint.BorderSizePixel = 0
Hint.TextColor3 = Color3.fromRGB(100,160,255)
Hint.Font = Enum.Font.Gotham; Hint.TextSize = 11
Hint.Text = "RightShift to reopen"
Instance.new("UICorner", Hint).CornerRadius = UDim.new(0,6)

UIS.InputBegan:Connect(function(inp, gpe)
    if not gpe and inp.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1,-8,1,-44); Scroll.Position = UDim2.new(0,4,0,40)
Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(80,180,255)
Scroll.CanvasSize = UDim2.new(0,0,0,0)

local List = Instance.new("UIListLayout", Scroll)
List.Padding = UDim.new(0,5); List.SortOrder = Enum.SortOrder.LayoutOrder
local Pad = Instance.new("UIPadding", Scroll)
Pad.PaddingTop = UDim.new(0,4); Pad.PaddingLeft = UDim.new(0,4); Pad.PaddingRight = UDim.new(0,4)

local function Section(text)
    local lbl = Instance.new("TextLabel", Scroll)
    lbl.Size = UDim2.new(1,-8,0,18); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(80,180,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = "  " .. text:upper()
end

local function Toggle(label, icon, default, cb)
    local row = Instance.new("Frame", Scroll)
    row.Size = UDim2.new(1,-8,0,34); row.BackgroundColor3 = Color3.fromRGB(24,24,36)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-52,1,0); lbl.Position = UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(210,210,230)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = icon .. "  " .. label

    local tf = Instance.new("Frame", row)
    tf.Size = UDim2.new(0,38,0,20); tf.Position = UDim2.new(1,-46,0.5,-10)
    tf.BackgroundColor3 = default and Color3.fromRGB(30,130,220) or Color3.fromRGB(50,50,70)
    tf.BorderSizePixel = 0
    Instance.new("UICorner", tf).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame", tf)
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = default and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
    knob.BackgroundColor3 = Color3.new(1,1,1); knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local on = default
    local function refresh()
        TweenService:Create(tf, TweenInfo.new(0.15), {
            BackgroundColor3 = on and Color3.fromRGB(30,130,220) or Color3.fromRGB(50,50,70)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
        }):Play()
    end

    row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            on = not on; refresh(); cb(on)
        end
    end)
end

local function StatRow(label, icon)
    local row = Instance.new("Frame", Scroll)
    row.Size = UDim2.new(1,-8,0,28); row.BackgroundColor3 = Color3.fromRGB(18,18,28)
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-8,1,0); lbl.Position = UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(180,220,255)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = icon .. "  " .. label .. ": –"
    return lbl
end

-- Build items
Section("Automation")

Toggle("Auto Battle", "⚔️", false, function(v)
    Config.AutoBattle = v
    Notify("Auto Battle: " .. (v and "ON" or "OFF"))
    if v and not inBattle then
        if Config.AutoEquipBest then EquipBest() task.wait(0.3) end
        QueueBattle()
    end
end)

Toggle("Auto Claim Rewards", "🎁", false, function(v)
    Config.AutoClaim = v
    Notify("Auto Claim: " .. (v and "ON" or "OFF"))
end)

Toggle("Auto Equip Best Team", "🐾", false, function(v)
    Config.AutoEquipBest = v
    if v then EquipBest() end
    Notify("Auto Equip Best: " .. (v and "ON" or "OFF"))
end)

Toggle("2× Match Speed", "⚡", false, function(v)
    Config.FastSpeed = v
    if inBattle then SetSpeed(v) end
    Notify("Fast Speed: " .. (v and "ON" or "OFF"))
end)

Toggle("Mute Popups", "🔇", false, function(v)
    Config.MutePopups = v
    Notify("Mute Notification SFX: " .. (v and "ON" or "OFF"))
end)

Section("Stats (Live)")

local winsLbl   = StatRow("Session Wins", "🏆")
local battleLbl = StatRow("Battles Started", "🔢")

RunService.Heartbeat:Connect(function()
    battleLbl.Text = "🔢  Battles Started: " .. battleCount

    pcall(function()
        local winsEl = PGui:FindFirstChild("Main", true)
        if winsEl then
            local winsFrame = winsEl:FindFirstChild("Wins", true)
            if winsFrame then
                local amt = winsFrame:FindFirstChild("Amount")
                if amt then
                    winsLbl.Text = "🏆  Wins: " .. (amt.Text or "–")
                end
            end
        end
    end)
end)

Section("Manual Controls")

local equipBtn = Instance.new("TextButton", Scroll)
equipBtn.Size = UDim2.new(1,-8,0,32); equipBtn.BackgroundColor3 = Color3.fromRGB(30,80,160)
equipBtn.TextColor3 = Color3.new(1,1,1); equipBtn.Font = Enum.Font.GothamBold
equipBtn.TextSize = 13; equipBtn.Text = "🐾  Equip Best Team Now"
equipBtn.BorderSizePixel = 0
Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0,8)
equipBtn.MouseButton1Click:Connect(function()
    EquipBest()
    Notify("Equipped best team!")
end)

local queueBtn = Instance.new("TextButton", Scroll)
queueBtn.Size = UDim2.new(1,-8,0,32); queueBtn.BackgroundColor3 = Color3.fromRGB(30,130,60)
queueBtn.TextColor3 = Color3.new(1,1,1); queueBtn.Font = Enum.Font.GothamBold
queueBtn.TextSize = 13; queueBtn.Text = "⚔️  Queue Battle Now"
queueBtn.BorderSizePixel = 0
Instance.new("UICorner", queueBtn).CornerRadius = UDim.new(0,8)
queueBtn.MouseButton1Click:Connect(function()
    QueueBattle()
    Notify("Battle queued!")
end)

List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 15)
end)

Notify("Battle Pet QoL loaded! RightShift = toggle GUI")
