--!strict
-- Pure cooperative-revive rules. Runtime code owns characters and prompts; this module owns policy.

export type Cooldown = {
	Wave: number,
	Used: { [number]: boolean },
}

local Revive = {}

Revive.MaxDistance = 10
Revive.HoldSeconds = 3
Revive.WindowSeconds = 10

function Revive.isEligible(
	rescuerAlive: boolean,
	targetDowned: boolean,
	distance: number,
	usedThisWave: boolean
): boolean
	return rescuerAlive
		and targetDowned
		and distance >= 0
		and distance <= Revive.MaxDistance
		and not usedThisWave
end

function Revive.holdProgress(heldSeconds: number): number
	return math.clamp(heldSeconds / Revive.HoldSeconds, 0, 1)
end

function Revive.isTimedOut(downedAt: number, now: number): boolean
	return now - downedAt >= Revive.WindowSeconds
end

function Revive.newCooldown(wave: number): Cooldown
	return { Wave = wave, Used = {} }
end

function Revive.resetCooldown(cooldown: Cooldown, wave: number): Cooldown
	if cooldown.Wave == wave then
		return cooldown
	end
	return Revive.newCooldown(wave)
end

function Revive.wasUsed(cooldown: Cooldown, playerId: number, wave: number): boolean
	return cooldown.Wave == wave and cooldown.Used[playerId] == true
end

function Revive.markUsed(cooldown: Cooldown, playerId: number, wave: number): Cooldown
	local used = {}
	if cooldown.Wave == wave then
		for id, value in cooldown.Used do
			used[id] = value
		end
	end
	used[playerId] = true
	return { Wave = wave, Used = used }
end

return Revive
