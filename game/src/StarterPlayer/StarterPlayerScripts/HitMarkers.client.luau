--!strict
-- Floating damage numbers where your shots land.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Feel = require(ReplicatedStorage.Shared.Feel)
local SfxMap = require(ReplicatedStorage.Shared.SfxMap)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientFX = require(script.Parent:WaitForChild("ClientFX"))
local AnimeEffects = require(script.Parent:WaitForChild("AnimeEffects"))
local HitMarker = ReplicatedStorage:WaitForChild("Remotes").HitMarker :: RemoteEvent

HitMarker.OnClientEvent:Connect(
	function(
		pos: Vector3,
		damage: number,
		killed: boolean,
		target: Model?,
		critical: boolean?,
		eliteKill: boolean?,
		hitNormal: Vector3?
	)
		local isCritical = critical == true
		AnimeEffects.hitMarker(isCritical)
		local event = Feel.eventFor(killed, isCritical)
		if target and target.Parent then
			ClientFX.hitFlash(target, Feel.HitFlashSeconds)
		end
		local sparkColor = if killed
			then ClientFX.c3(Theme.Goo)
			else if isCritical
				then ClientFX.c3(Theme.SignalOrange)
				else ClientFX.c3(Theme.Hero)
		ClientFX.hitSpark(pos, sparkColor, hitNormal or Vector3.new(0, 0, 1))
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
			ClientFX.gooDecal(pos, ClientFX.c3(gooColor), 2.5, 0.4)
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
			else if isCritical then ClientFX.c3(Theme.Loot) else ClientFX.c3(Theme.Text)
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
