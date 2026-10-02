local VfxDefs = load("VfxDefs")

local effectNames = { "Goo", "Crack", "Debris", "CoinBurst" }

local function hasTrigger(effect, wanted)
	for _, trigger in effect.Triggers or {} do
		if trigger == wanted then
			return true
		end
	end
	return false
end

test("floor decals fade within six seconds and obey the live cap", function()
	assert(VfxDefs.MaxLiveDecals > 0, "live decal cap must be positive")
	for _, name in { "Goo", "Crack" } do
		local effect = VfxDefs[name]
		eq(effect.Kind, "Decal", name .. " kind")
		assert(effect.Lifetime <= 6, name .. " lasts longer than six seconds")
		assert(effect.FadeOutSeconds > 0, name .. " does not fade")
		assert(effect.FadeOutSeconds <= effect.Lifetime, name .. " fades after removal")
		eq(effect.MaxLive, VfxDefs.MaxLiveDecals, name .. " live cap")
	end
end)

test("goo uses teal and green colours", function()
	for _, color in VfxDefs.Goo.Colors do
		local red, green, blue = color[1], color[2], color[3]
		assert(green > red, "goo colour is red")
		assert(green >= blue, "goo colour is neither teal nor green")
	end
end)

test("added effect colours are never red", function()
	for _, name in effectNames do
		for _, color in VfxDefs[name].Colors do
			local red, green, blue = color[1], color[2], color[3]
			assert(not (red > green * 1.25 and red > blue * 1.25), name .. " contains red")
		end
	end
end)

test("slam and landing effects include cracks and debris", function()
	for _, name in { "Crack", "Debris" } do
		local effect = VfxDefs[name]
		assert(hasTrigger(effect, "BossSlam"), name .. " missing boss slam trigger")
		assert(hasTrigger(effect, "BigBugLanding"), name .. " missing big-bug landing trigger")
	end
end)

test("coin bursts fly to the player", function()
	eq(VfxDefs.CoinBurst.Kind, "Burst", "coin burst kind")
	eq(VfxDefs.CoinBurst.Motion, "FlyToPlayer", "coin burst motion")
end)
