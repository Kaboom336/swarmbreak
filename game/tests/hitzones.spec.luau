local Enemies = load("Enemies")
local HitZones = load("HitZones")

test("every enemy has exactly one named weak point", function()
	for enemyType in Enemies.Defs do
		local zones = HitZones.Defs[enemyType]
		assert(zones, enemyType .. " needs hit zones")
		local weakPoints = 0
		for _, zone in zones do
			if zone.WeakPoint then
				weakPoints += 1
				assert(zone.Label ~= "", enemyType .. " weak point needs a label")
				assert(#zone.Patterns > 0, enemyType .. " weak point needs a pattern")
			end
		end
		eq(weakPoints, 1, enemyType .. " weak-point count")
	end
	for enemyType in HitZones.Defs do
		assert(Enemies.Defs[enemyType], enemyType .. " is not an enemy")
	end
end)

test("specific patterns take precedence over broad patterns", function()
	local iris = HitZones.zoneForPart("Warden", "Iris_Glow")
	assert(iris, "Iris_Glow should match")
	eq(iris.Id, "Eye", "weak eye must win before the generic glow armor pattern")

	local halo = HitZones.zoneForPart("Warden", "Halo_Glow")
	assert(halo, "Halo_Glow should match")
	eq(halo.Id, "Aegis", "non-eye glow should use armor")
end)

test("unknown enemies parts and tags are neutral", function()
	eq(HitZones.zoneForPart("Walker", "Torso"), nil, "ordinary body part")
	eq(HitZones.resolve("Walker", nil, "Hitscan").Multiplier, 1, "missing tag")
	eq(HitZones.resolve("Walker", "NotAZone", "Hitscan").Multiplier, 1, "unknown tag")
	eq(HitZones.resolve("Unknown", "Eyes", "Hitscan").Multiplier, 1, "unknown enemy")
end)

test("all configured multipliers and feedback colors are bounded", function()
	local bounds = HitZones.MultiplierBounds
	for enemyType, zones in HitZones.Defs do
		for _, zone in zones do
			assert(zone.Multiplier >= bounds.Min, enemyType .. " multiplier below minimum")
			assert(zone.Multiplier <= bounds.Max, enemyType .. " multiplier above maximum")
			eq(#zone.FeedbackColor, 3, enemyType .. " feedback color channels")
			for _, channel in zone.FeedbackColor do
				assert(channel >= 0 and channel <= 255, enemyType .. " invalid feedback color")
			end
		end
	end
end)

test("precision multipliers apply to hitscan only", function()
	local core = HitZones.zoneForPart("Flyer", "Core_Glow")
	assert(core, "Flyer core should be tagged")
	eq(HitZones.resolve("Flyer", core.Id, "Hitscan").Multiplier, 2, "hitscan precision")
	for _, kind in { "Melee", "Orbital", "Beam" } do
		eq(HitZones.resolve("Flyer", core.Id, kind).Multiplier, 1, kind .. " stays neutral")
	end
end)
