--!strict
-- Pure audio routing and gain math. Runtime SoundGroups live in ClientFX.
local Mix = {}

export type Category = "Music" | "Sfx" | "Ui"

Mix.Duck = {
	Attack = 0.08,
	Hold = 0.75,
	Release = 0.45,
	Gain = 0.3,
}

local uiSounds = {
	Buy = true,
	Coin = true,
	Crate = true,
	Deny = true,
}

local duckingStingers = {
	BossRoar = true,
	BossThunder = true,
	GameOver = true,
	WaveClear = true,
}

local function clamp01(value: any, fallback: number): number
	if type(value) ~= "number" or value ~= value then
		return fallback
	end
	return math.clamp(value, 0, 1)
end

function Mix.categoryForSound(name: string): Category
	if name == "Music" then
		return "Music"
	elseif uiSounds[name] then
		return "Ui"
	end
	return "Sfx"
end

function Mix.isDuckingStinger(name: string): boolean
	return duckingStingers[name] == true
end

-- Returns 1 before/after the envelope and reaches duckGain for the hold segment.
function Mix.envelope(
	elapsed: number,
	attack: number,
	hold: number,
	release: number,
	duckGain: number
): number
	local low = clamp01(duckGain, 1)
	local attackTime = math.max(0, attack)
	local holdTime = math.max(0, hold)
	local releaseTime = math.max(0, release)
	if elapsed < 0 then
		return 1
	elseif attackTime > 0 and elapsed < attackTime then
		return 1 + (low - 1) * (elapsed / attackTime)
	end
	elapsed -= attackTime
	if elapsed <= holdTime then
		return low
	end
	elapsed -= holdTime
	if releaseTime > 0 and elapsed < releaseTime then
		return low + (1 - low) * (elapsed / releaseTime)
	end
	return 1
end

function Mix.duckGain(elapsed: number): number
	return Mix.envelope(elapsed, Mix.Duck.Attack, Mix.Duck.Hold, Mix.Duck.Release, Mix.Duck.Gain)
end

function Mix.busVolume(volume: any, muted: boolean, gain: any?): number
	if muted then
		return 0
	end
	return math.clamp(clamp01(volume, 0) * clamp01(gain, 1), 0, 1)
end

function Mix.busVolumes(
	musicVolume: any,
	sfxVolume: any,
	muted: boolean,
	musicGain: any?
): { [Category]: number }
	return {
		Music = Mix.busVolume(musicVolume, muted, musicGain),
		Sfx = Mix.busVolume(sfxVolume, muted),
		Ui = Mix.busVolume(sfxVolume, muted),
	}
end

return Mix
