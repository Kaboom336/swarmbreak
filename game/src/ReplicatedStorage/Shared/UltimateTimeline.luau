--!strict
-- Pure Reaper Arc timing. Slow motion is deliberately only a local animation multiplier.
local UltimateTimeline = {}

UltimateTimeline.FullDuration = 1.5
UltimateTimeline.ShortDuration = 0.6
UltimateTimeline.ImpactFrameCount = 2
UltimateTimeline.ImpactFrameOccurrences = 1
UltimateTimeline.ImpactFrameSeconds = UltimateTimeline.ImpactFrameCount / 60
UltimateTimeline.ServerTimeScale = 1
UltimateTimeline.LocalAnimationScale = 0.35

function UltimateTimeline.duration(mode: string): number
	if mode == "Off" then
		return 0
	elseif mode == "Short" then
		return UltimateTimeline.ShortDuration
	end
	return UltimateTimeline.FullDuration
end

function UltimateTimeline.sample(
	mode: string,
	elapsed: number
): { Progress: number, Impact: boolean }
	local duration = UltimateTimeline.duration(mode)
	if duration <= 0 then
		return { Progress = 1, Impact = false }
	end
	local progress = math.clamp(elapsed / duration, 0, 1)
	local impactAt = if mode == "Short" then 0.42 else 0.5
	local impactSeconds = elapsed - duration * impactAt
	return {
		Progress = progress,
		Impact = impactSeconds >= 0 and impactSeconds < UltimateTimeline.ImpactFrameSeconds,
	}
end

return UltimateTimeline
