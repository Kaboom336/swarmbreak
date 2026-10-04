local BossFight = load("BossFight")
local PoolSize = load("PoolSize")
local ScreenEffects = load("ScreenEffects")

test("boss damage trail catches the fill within 0.4 seconds", function()
	local fill = 0.35
	local previousTrail = 0.9
	assert(ScreenEffects.trailRatio(previousTrail, fill, 0) >= fill, "trail starts behind fill")
	assert(
		ScreenEffects.trailRatio(previousTrail, fill, ScreenEffects.TrailSeconds - 0.001) > fill,
		"trail remains visible during its drain"
	)
	eq(
		ScreenEffects.trailRatio(previousTrail, fill, ScreenEffects.TrailSeconds),
		fill,
		"trail ends at fill"
	)
	eq(
		ScreenEffects.trailRatio(previousTrail, fill, ScreenEffects.TrailSeconds + 1),
		fill,
		"trail never remains late"
	)
end)

test("boss phase notch positions use BossFight thresholds", function()
	local notches = ScreenEffects.phaseNotches()
	eq(#notches, 1, "queen phase notch count")
	eq(notches[1], BossFight.PhaseTwoHealthRatio, "queen phase two notch")
end)

test("boss UI shake never exceeds four pixels", function()
	for step = 0, 20 do
		local x, y = ScreenEffects.shakeOffset(step / 20)
		assert(math.abs(x) <= 4, "x shake exceeds four pixels")
		assert(math.abs(y) <= 4, "y shake exceeds four pixels")
	end
end)

test("low health vignette is not red dominant", function()
	local color = ScreenEffects.VignetteColor
	assert(color[1] <= math.max(color[2], color[3]), "vignette is red dominant")
end)

test("damage number entries return to their pool", function()
	local pool = PoolSize.new(2, function(index)
		return { Id = index }
	end)
	local first = PoolSize.acquire(pool)
	PoolSize.release(pool, first)
	eq(PoolSize.acquire(pool), first, "damage number entry is reused")
end)

test("boss bar fits 667 by 375 below the top HUD", function()
	local bar = ScreenEffects.bossBarRect(667, 375, 0.6, 0)
	assert(bar.x >= 0 and bar.x + bar.w <= 667, "boss bar fits phone width")
	assert(bar.y >= 0 and bar.y + bar.h <= 375, "boss bar fits phone height")
	assert(bar.y >= 36 * 0.6, "boss bar stays below top HUD")
end)
