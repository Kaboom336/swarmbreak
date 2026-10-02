local Quality = load("Quality")

local function sampleMany(state, frameTime, count)
	for _ = 1, count do
		state = Quality.sample(state, frameTime)
	end
	return state
end

test("noisy samples do not downgrade a healthy client", function()
	local state = Quality.new("Auto")
	for i = 1, Quality.WindowSize * 3 do
		local frameTime = if i % 5 == 0 then 1 / 30 else 1 / 75
		state = Quality.sample(state, frameTime)
	end
	eq(state.Tier, "High", "occasional slow frames stay high")
end)

test("auto downgrades after a full slow window", function()
	local state =
		sampleMany(Quality.new("Auto"), Quality.DowngradeFrameTime, Quality.WindowSize - 1)
	eq(state.Tier, "High", "partial window")
	state = Quality.sample(state, Quality.DowngradeFrameTime)
	eq(state.Tier, "Low", "full slow window")
end)

test("auto recovers only at the recovery threshold", function()
	local state = sampleMany(Quality.new("Auto"), 1 / 30, Quality.WindowSize)
	eq(state.Tier, "Low", "downgraded")
	state = sampleMany(state, Quality.RecoveryFrameTime, Quality.WindowSize)
	eq(state.Tier, "High", "recovered")
end)

test("hysteresis prevents quality flapping", function()
	local state = sampleMany(Quality.new("Auto"), 1 / 30, Quality.WindowSize)
	state = sampleMany(state, 1 / 50, Quality.WindowSize * 2)
	eq(state.Tier, "Low", "middle-band samples stay low")
	state = sampleMany(state, 1 / 60, Quality.WindowSize)
	eq(state.Tier, "High", "fast samples recover")
	state = sampleMany(state, 1 / 50, Quality.WindowSize * 2)
	eq(state.Tier, "High", "middle-band samples stay high")
end)

test("low budgets never exceed high budgets", function()
	local low = Quality.Budgets.Low
	local high = Quality.Budgets.High
	assert(low.FX <= high.FX, "FX budget ordering")
	assert(low.Particles <= high.Particles, "particle budget ordering")
	assert(low.Animation <= high.Animation, "animation budget ordering")
end)

test("manual tiers ignore frame-time classification", function()
	local low = sampleMany(Quality.new("Low"), 1 / 120, Quality.WindowSize * 2)
	local high = sampleMany(Quality.new("High"), 1 / 15, Quality.WindowSize * 2)
	eq(low.Tier, "Low", "manual low")
	eq(high.Tier, "High", "manual high")
end)
