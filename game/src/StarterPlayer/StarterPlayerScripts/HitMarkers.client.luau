--!strict
-- Floating damage numbers where your shots land.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Feel = require(ReplicatedStorage.Shared.Feel)
local SfxMap = require(ReplicatedStorage.Shared.SfxMap)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))
local HitMarker = ReplicatedStorage:WaitForChild("Remotes").HitMarker :: RemoteEvent

HitMarker.OnClientEvent:Connect(
	function(
		pos: Vector3,
		damage: number,
		killed: boolean,
		target: Model?,
		critical: boolean?,
		eliteKill: boolean?
	)
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
		local soundName = if killed then nil else "Hit"
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
			ClientFX.gemPop(pos, ClientFX.c3(Theme.Loot))
			if target then
				ClientFX.hitstop(target, eliteKill == true)
			end
			for _, layer in { "kill crunch", "kill goo", "kill tick" } do
				local layerName = SfxMap.forEvent(layer)
				if layerName then
					ClientFX.sound(layerName, pos, if layer == "kill tick" then 0.16 else 0)
				end
			end
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
