--!strict
-- Pure rules for enemies that can no longer be fought: gone, fallen, outside the map, or wedged.
-- A wave only ends when every enemy dies, so one of these used to stall the round forever.
local EnemyWatchdog = {
	CheckSeconds = 1,
	FallY = -25,
	MaxRadius = 560, -- past the far edge of Hive Core (x 480), so only escaped enemies trip it
	StuckSeconds = 10,
	StuckMoveStuds = 1,
	NoProgressSeconds = 15, -- eca9fb2: a Walker ran in place on a wall top
	ProgressStuds = 3,
	ProgressMinDistance = 35, -- slot-waiting circlers stay well inside this
	AirborneSeconds = 4, -- f96b4f8: a Walker sat in Freefall on top of the boss gate
}

export type Verdict = "Ok" | "Forget" | "Kill" | "Respawn"

function EnemyWatchdog.verdict(
	hasModel: boolean,
	hasRoot: boolean,
	x: number,
	y: number,
	z: number,
	stuckSeconds: number,
	airborneSeconds: number?,
	noProgressSeconds: number?
): Verdict
	if not hasModel or not hasRoot then
		return "Forget" -- destroyed without dying: drop it from the alive count
	end
	if y < EnemyWatchdog.FallY or math.sqrt(x * x + z * z) > EnemyWatchdog.MaxRadius then
		return "Kill"
	end
	if
		stuckSeconds >= EnemyWatchdog.StuckSeconds
		or (airborneSeconds or 0) >= EnemyWatchdog.AirborneSeconds
		or (noProgressSeconds or 0) >= EnemyWatchdog.NoProgressSeconds
	then
		return "Respawn"
	end
	return "Ok"
end

-- Seconds an enemy has been stuck after this check: moving resets, holding still accumulates.
function EnemyWatchdog.nextStuck(previous: number, moved: number, chasing: boolean): number
	if not chasing or moved >= EnemyWatchdog.StuckMoveStuds then
		return 0
	end
	return previous + EnemyWatchdog.CheckSeconds
end

-- Seconds a ground enemy has spent off the floor (falling, or perched where it can't walk).
function EnemyWatchdog.nextAirborne(previous: number, airborne: boolean, flying: boolean): number
	if flying or not airborne then
		return 0
	end
	return previous + EnemyWatchdog.CheckSeconds
end

export type Progress = { Best: number, Seconds: number }

-- Seconds a chaser has gone without closing ProgressStuds on its target.
function EnemyWatchdog.nextProgress(
	previous: Progress,
	distance: number,
	chasing: boolean
): Progress
	if not chasing then
		return { Best = math.huge, Seconds = 0 }
	end
	if distance <= previous.Best - EnemyWatchdog.ProgressStuds then
		return { Best = distance, Seconds = 0 }
	end
	return {
		Best = math.min(previous.Best, distance),
		Seconds = previous.Seconds + EnemyWatchdog.CheckSeconds,
	}
end

return EnemyWatchdog
