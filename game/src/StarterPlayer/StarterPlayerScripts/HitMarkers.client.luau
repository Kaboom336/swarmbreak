--!strict
-- Floating damage numbers where your shots land.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AnimCurves = require(ReplicatedStorage.Shared.AnimCurves)
local Feel = require(ReplicatedStorage.Shared.Feel)
local SfxMap = require(ReplicatedStorage.Shared.SfxMap)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))
local HitMarker = ReplicatedStorage:WaitForChild("Remotes").HitMarker :: RemoteEvent

local function xpGemPop(position: Vector3)
	local gem = Instance.new("Part")
	gem.Name = "XPGemPop"
	gem.Shape = Enum.PartType.Ball
	gem.Size = Vector3.new(0.45, 0.7, 0.45)
	gem.Anchored = true
	gem.CanCollide = false
	gem.CanQuery = false
	gem.CanTouch = false
	gem.CastShadow = false
	gem.Material = Enum.Material.Neon
	gem.Color = ClientFX.c3(Theme.Loot)
	gem.CFrame = CFrame.new(position)
	gem.Parent = workspace:FindFirstChild("ClientFX") or workspace
	task.spawn(function()
		local startedAt = os.clock()
		while gem.Parent do
			local elapsed = os.clock() - startedAt
			if elapsed >= AnimCurves.GemPopDuration then
				break
			end
			local pose = AnimCurves.gemPop(elapsed)
			gem.CFrame = CFrame.new(position + Vector3.new(0, pose.BounceHeight, 0))
				* CFrame.Angles(0, math.rad(pose.SpinDegrees), math.rad(45))
			RunService.Heartbeat:Wait()
		end
		gem:Destroy()
	end)
end

HitMarker.OnClientEvent:Connect(
	function(pos: Vector3, damage: number, killed: boolean, target: Model?, critical: boolean?)
		local isCritical = critical == true
		local event = Feel.eventFor(killed, isCritical)
		if target and target.Parent then
			local previous = target:FindFirstChild("HitFlash")
			if previous then
				previous:Destroy()
			end
			local highlight = Instance.new("Highlight")
			highlight.Name = "HitFlash"
			highlight.Adornee = target
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.FillColor = Color3.new(1, 1, 1)
			highlight.FillTransparency = 0
			highlight.OutlineTransparency = 1
			highlight.Parent = target
			task.delay(Feel.HitFlashSeconds, function()
				highlight:Destroy()
			end)
		end
		local sparkColor = if killed
			then ClientFX.c3(Theme.Goo)
			else if isCritical
				then ClientFX.c3(Theme.SignalOrange)
				else ClientFX.c3(Theme.Text)
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
			local enemyType = if target then target:GetAttribute("EnemyType") else nil
			if type(enemyType) ~= "string" and target then
				enemyType = target.Name
			end
			local gooColor = Feel.deathBurstColor(enemyType, Theme.Goo)
			ClientFX.gooDecal(pos, ClientFX.c3(gooColor), 2.5, 3)
			xpGemPop(pos)
		end
		if killed then
			ClientFX.shakeFor("Kill", "Full")
		end
		local budget = Feel.Events[event]
		local numberColor = if killed
			then ClientFX.c3(Theme.Loot)
			else if isCritical
				then ClientFX.c3(Theme.SignalOrange)
				else ClientFX.c3(Theme.Text)
		ClientFX.damageNumber(
			pos,
			(if isCritical then "CRIT " else "") .. tostring(damage),
			numberColor,
			budget.NumberScale,
			Feel.DamageNumberSeconds,
			Feel.DamageNumberRiseStuds,
			isCritical
		)
	end
)
