--!strict
local FreeDoubleWins = {}

export type Countdown = {
	active: boolean,
	remainingSeconds: number,
	remainingMinutes: number,
}

function FreeDoubleWins.compute(expiresAt: number?, now: number): Countdown
	local remainingSeconds = math.max(0, (expiresAt or 0) - now)
	return {
		active = remainingSeconds > 0,
		remainingSeconds = remainingSeconds,
		remainingMinutes = math.ceil(remainingSeconds / 60),
	}
end

return FreeDoubleWins
