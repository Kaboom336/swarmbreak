local Ultimate = load("UltimateTimeline")

test("Reaper Arc timelines meet duration and impact-frame limits", function()
	eq(Ultimate.duration("Full") <= 1.5, true, "full duration")
	eq(Ultimate.duration("Short") <= 0.6, true, "short duration")
	eq(Ultimate.duration("Off"), 0, "off duration")
	eq(Ultimate.ImpactFrameCount <= 2, true, "impact is at most two frames")
	eq(Ultimate.ImpactFrameOccurrences, 1, "impact happens once")
end)

test("Reaper Arc leaves server time untouched", function()
	eq(Ultimate.ServerTimeScale, 1, "server time scale")
	eq(Ultimate.LocalAnimationScale < 1, true, "slow feel is client animation only")
end)
