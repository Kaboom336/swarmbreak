-- Engine-independent assertions reused by StudioPass and offline verification.
local Tests = {}
function Tests.RavineTest(P)
	assert(P.isRavineFall(0, -2, 0, true), "fall threshold")
	assert(not P.isRavineFall(0, 4, 0, true), "bridge above floor")
	assert(not P.isRavineFall(0, -2, 0, false), "grounded excluded")
	assert(not P.isRavineFall(90, -2, 0, true), "banks excluded")
	assert(not P.isRavineFall(-22, -12, 10, false), "ramp walking excluded")
	assert(P.canPickup(nil, 17), "unowned pickup")
	assert(not P.canPickup(17, 18), "rival cannot double carry")
	assert(not P.canPickup(17, 17), "owner cannot double carry")
	for _, c in
		{
			{ 0, 0, 30, 0, 24 },
			{ 0, 0, -30, 0, -24 },
			{ 30, -3, 30, 30, -24 },
			{ -22, 3, 30, -42, 24 },
			{ 70, 0, 30, 84, 0 },
			{
				-70,
				0,
				30,
				-84,
				0,
			},
		}
	do
		local x, z = P.rim(c[1], c[2], c[3])
		assert(x == c[4] and z == c[5], "reachable rim")
	end
	return "14 policy assertions; physical fall/climb requires manual check"
end
function Tests.TunnelTest(_, P)
	local n = 0
	local function check(value, message)
		assert(value, message)
		n += 1
	end
	check(P.inside(-76, 3, -20), "entrance")
	check(P.inside(-76, 3, 40), "trunk")
	check(P.inside(-60, 3, 85), "south branch")
	check(not P.inside(-100, 3, 20), "surface excluded")
	check(not P.inside(-76, 30, 40), "roof excluded")
	check(not P.inside(-76, -3, 40), "buried excluded")
	check(P.inMud(-76, 3, -7) and P.inMud(-76, 3, 17), "full mud length")
	check(not P.inMud(-76, 3, 18), "mud ends")
	check(P.Tuning.MudLength / P.Tuning.MudSpeed == 3, "mud occupancy")
	check(P.Tuning.ShadowSeconds == 0.7, "warning")
	check(P.interval(7.99) == 2.4, "before rumble")
	check(P.interval(8) == 0.9, "rumble threshold")
	check(P.predict(-76, 78, 0.59) == 1 and P.predict(-76, 78, 0.61) == 2, "near probability")
	check(P.predict(-61, 99, 0.59) == 2 and P.predict(-61, 99, 0.61) == 1, "south probability")
	check(#P.path(1) == 7 and #P.path(2) == 9, "surface paths")
	check(P.path(1)[7].z == P.Exits[1].z, "near endpoint")
	check(P.path(2)[9].z == P.Exits[2].z, "south endpoint")
	check(P.Tuning.ExitWaitTimeout > 105 / 16 + 1.5, "hold covers crossing")
	check(P.Tuning.Width >= 12 and P.Tuning.Width <= 14, "width")
	check(P.Tuning.Ceiling >= 20, "headroom")
	local x, z = P.hazardTarget(-76, 0, 0, 8)
	check(x == -76 and math.abs(z - 8.4) < 0.00001, "motion lead")
	x, z = P.hazardTarget(-76, 0, 0, 0)
	check(x == -76 and z == 0, "stationary lead")
	x, z = P.hazardTarget(-76, 76, 0, 16)
	check(P.inside(x, 3, z), "boundary lead")
	check(not P.shouldIntercept("A", 1, 100, "A", 1, 100), "repick dedupe")
	check(P.shouldIntercept("A", 1, 100, "A", 1, 110), "new visit")
	check(P.shouldIntercept("A", 1, 100, "B", 1, 100), "handoff")
	check(P.shouldIntercept(nil, nil, nil, "A", 1, 100), "first dispatch")
	check(P.Tuning.ExitGuardRadius == 12, "mouth coverage")
	check(
		(P.Exits[1].x - P.Exits[2].x) ^ 2 + (P.Exits[1].z - P.Exits[2].z) ^ 2 > (2 * P.Tuning.ExitGuardRadius) ^ 2,
		"exit discs separate"
	)
	return tostring(n) .. " policy assertions; live hazards/intercept require manual check"
end
return Tests
