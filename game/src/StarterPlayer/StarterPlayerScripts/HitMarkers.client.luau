--!strict
-- Floating damage numbers where your shots land.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Feel = require(ReplicatedStorage.Shared.Feel)
local SfxMap = require(ReplicatedStorage.Shared.SfxMap)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))
local HitMarker = ReplicatedStorage:WaitForChild("Remotes").HitMarker :: RemoteEvent
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local numberState: Feel.NumberState = {}

<<<<<<< HEAD
HitMarker.OnClientEvent:Connect(
	function(pos: Vector3, damage: number, killed: boolean, critical: boolean?)
		local isCritical = critical == true
		local event: Feel.EventName = if killed
			then "Kill"
			else if isCritical then "Crit" else "Hit"
		if killed then
			local soundName = SfxMap.forEvent("enemy kill")
			if soundName then
				ClientFX.sound(soundName)
			end
		end
=======
local feedbackGui = Instance.new("ScreenGui")
feedbackGui.Name = "HitFeedback"
feedbackGui.ResetOnSpawn = false
feedbackGui.DisplayOrder = 5
feedbackGui.Parent = playerGui

local function coinCounterPosition(): Vector2
	local hud = playerGui:FindFirstChild("Hud")
	local counter = hud and (hud:FindFirstChild("Coins", true) or hud:FindFirstChild("Stats", true))
	if counter and counter:IsA("GuiObject") then
		return counter.AbsolutePosition + counter.AbsoluteSize / 2
	end
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	return Vector2.new(viewport.X - 56, 34)
end

local function flyCoinToCounter(worldPosition: Vector3)
	local camera = workspace.CurrentCamera
	local screenPosition = Vector2.new(0, 0)
	if camera then
		local projected, visible = camera:WorldToViewportPoint(worldPosition)
		screenPosition = if visible
			then Vector2.new(projected.X, projected.Y)
			else camera.ViewportSize / 2
	end

	local coin = Instance.new("TextLabel")
	coin.Name = "CoinPickup"
	coin.AnchorPoint = Vector2.new(0.5, 0.5)
	coin.Position = UDim2.fromOffset(screenPosition.X, screenPosition.Y)
	coin.Size = UDim2.fromOffset(26, 26)
	coin.BackgroundColor3 = Color3.fromRGB(255, 210, 60)
	coin.BorderSizePixel = 0
	coin.Font = Enum.Font.GothamBlack
	coin.Text = "+"
	coin.TextColor3 = Color3.fromRGB(80, 45, 10)
	coin.TextSize = 20
	coin.ZIndex = 5
	coin.Parent = feedbackGui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = coin

	TweenService:Create(
		coin,
		TweenInfo.new(Feel.CoinFlightSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Position = UDim2.fromOffset(coinCounterPosition().X, coinCounterPosition().Y),
			Size = UDim2.fromOffset(14, 14),
			Rotation = 360,
			BackgroundTransparency = 0.25,
			TextTransparency = 0.25,
		}
	):Play()
	task.delay(Feel.CoinFlightSeconds, function()
		coin:Destroy()
		ClientFX.sound("Coin")
	end)
end

HitMarker.OnClientEvent:Connect(
	function(pos: Vector3, damage: number, killed: boolean, critical: boolean?)
		local isCritical = critical == true
		local event = Feel.eventFor(killed, isCritical)
		local sparkColor = if killed
			then Color3.fromRGB(255, 210, 60)
			else if isCritical then Color3.fromRGB(255, 150, 60) else Color3.new(1, 1, 1)
		ClientFX.burst(
			pos,
			sparkColor,
			if isCritical then Feel.CritSparkCount else Feel.HitSparkCount,
			if isCritical then Feel.CritSparkScale else Feel.HitSparkScale,
			if isCritical then Feel.CritSparkSpeed else Feel.HitSparkSpeed,
			Feel.HitSparkSeconds,
			true
		)
		ClientFX.flash(pos, Color3.new(1, 1, 1), Feel.HitFlashRange, Feel.HitFlashSeconds)
		local soundName = if killed then SfxMap.forEvent("enemy kill") else "Hit"
		if soundName then
			ClientFX.sound(soundName, pos)
		end
		if killed then
			flyCoinToCounter(pos)
		end
>>>>>>> codex/w9-hit-feedback
		ClientFX.shakeFor(event, "Full")
		local allowed: boolean
		numberState, allowed = Feel.allowNumber(numberState, os.clock())
		if not allowed then
			return
		end
		local budget = Feel.Events[event]
		local anchor = Instance.new("Part")
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.Position = pos
		anchor.Parent = workspace
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(80, 30)
		bb.AlwaysOnTop = true
		bb.Parent = anchor
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBlack
		t.TextSize = math.round(18 * budget.NumberScale)
<<<<<<< HEAD
		t.TextColor3 = if isCritical
			then Color3.fromRGB(255, 105, 220)
			else if killed then Color3.fromRGB(255, 80, 80) else Color3.fromRGB(255, 240, 150)
		t.TextStrokeTransparency = 0.3
		t.Text = if isCritical then "CRIT " .. tostring(damage) else tostring(damage)
		t.Parent = bb
		TweenService:Create(bb, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
			StudsOffset = Vector3.new(0, 3, 0),
		}):Play()
		TweenService
			:Create(t, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 })
			:Play()
		Debris:AddItem(anchor, 0.7)
=======
		t.TextColor3 = if killed
			then Color3.fromRGB(255, 210, 60)
			else if isCritical then Color3.fromRGB(255, 150, 60) else Color3.new(1, 1, 1)
		t.TextStrokeTransparency = 0.3
		t.Text = (if isCritical then "CRIT " else "") .. tostring(damage)
		t.Parent = bb
		TweenService:Create(bb, TweenInfo.new(Feel.DamageNumberSeconds, Enum.EasingStyle.Quad), {
			StudsOffset = Vector3.new(0, Feel.DamageNumberRiseStuds, 0),
		}):Play()
		TweenService:Create(
			t,
			TweenInfo.new(Feel.DamageNumberSeconds),
			{ TextTransparency = 1, TextStrokeTransparency = 1 }
		):Play()
		Debris:AddItem(anchor, Feel.DamageNumberSeconds + 0.1)
>>>>>>> codex/w9-hit-feedback
	end
)
