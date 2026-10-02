--!strict
-- Pure timing and sizing rules for held-weapon feel.

export type RecoilPose = {
	BackStuds: number,
	UpDegrees: number,
}

local WeaponPose = {}

WeaponPose.RecoilOutSeconds = 0.08
WeaponPose.RecoilBackSeconds = 0.12
WeaponPose.RecoilSeconds = WeaponPose.RecoilOutSeconds + WeaponPose.RecoilBackSeconds
WeaponPose.RecoilBackStuds = 0.25
WeaponPose.RecoilUpDegrees = 6

WeaponPose.SwingWindupSeconds = 0.08
WeaponPose.SwingArcSeconds = 0.16
WeaponPose.SwingSeconds = WeaponPose.SwingWindupSeconds + WeaponPose.SwingArcSeconds
WeaponPose.SwingWindupDegrees = -35
WeaponPose.SwingPeakDegrees = 100

WeaponPose.TargetLengths = {
	Gun = 2.6,
	Rifle = 3.4,
	Melee = 4.5,
	OrbitalEmitter = 1.2,
}

local rifles = {
	Marksman = true,
	Arc = true,
	Hornet = true,
	Nova = true,
	Ion = true,
}

local function smoothstep(value: number): number
	local t = math.clamp(value, 0, 1)
	return t * t * (3 - 2 * t)
end

function WeaponPose.recoilAt(seconds: number): RecoilPose
	local alpha = 0
	if seconds >= 0 and seconds <= WeaponPose.RecoilOutSeconds then
		alpha = smoothstep(seconds / WeaponPose.RecoilOutSeconds)
	elseif seconds < WeaponPose.RecoilSeconds then
		alpha = 1
			- smoothstep((seconds - WeaponPose.RecoilOutSeconds) / WeaponPose.RecoilBackSeconds)
	end
	return {
		BackStuds = WeaponPose.RecoilBackStuds * alpha,
		UpDegrees = WeaponPose.RecoilUpDegrees * alpha,
	}
end

function WeaponPose.swingAt(seconds: number): number
	if seconds < 0 or seconds >= WeaponPose.SwingSeconds then
		return 0
	end
	if seconds <= WeaponPose.SwingWindupSeconds then
		return WeaponPose.SwingWindupDegrees * smoothstep(seconds / WeaponPose.SwingWindupSeconds)
	end

	local arc = (seconds - WeaponPose.SwingWindupSeconds) / WeaponPose.SwingArcSeconds
	if arc <= 0.75 then
		return WeaponPose.SwingWindupDegrees
			+ (WeaponPose.SwingPeakDegrees - WeaponPose.SwingWindupDegrees)
				* smoothstep(arc / 0.75)
	end
	return WeaponPose.SwingPeakDegrees * (1 - smoothstep((arc - 0.75) / 0.25))
end

function WeaponPose.targetLength(id: string, kind: string): number
	if kind == "Melee" then
		return WeaponPose.TargetLengths.Melee
	elseif kind == "Orbital" then
		return WeaponPose.TargetLengths.OrbitalEmitter
	elseif kind == "Beam" or rifles[id] then
		return WeaponPose.TargetLengths.Rifle
	end
	return WeaponPose.TargetLengths.Gun
end

return WeaponPose
