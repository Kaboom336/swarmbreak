--!strict
local fs = require("@lune/fs")
local ArenaLayout = load("ArenaLayout")
local ArenaModelGenerator = load("ArenaModelGenerator")
local CameraConfig = load("CameraConfig")
local Campaign = load("Campaign")
local EffectCurves = load("EffectCurves")
local Feel = load("Feel")
local LightingPresets = load("LightingPresets")
local PropScatter = load("PropScatter")
local Sounds = load("Sounds")
local Theme = load("Theme")
local VfxTextures = load("VfxTextures")

local function close(actual: number, expected: number, message: string)
	assert(math.abs(actual - expected) < 0.000001, message)
end

test("effect curves ease without linear motion", function()
	eq(EffectCurves.quadOut(0), 0, "quad start")
	eq(EffectCurves.quadOut(1), 1, "quad end")
	assert(EffectCurves.quadOut(0.5) > 0.5, "quad-out leads linear motion")
	eq(EffectCurves.exponentialOut(0), 0, "exponential start")
	eq(EffectCurves.exponentialOut(1), 1, "exponential end")
	assert(
		EffectCurves.exponentialOut(0.5) > EffectCurves.quadOut(0.5),
		"exponential-out is distinct"
	)
	assert(EffectCurves.easeIn(0.5) < 0.5, "magnet pull accelerates")
end)

test("VFX texture slots are explicit zero-price placeholders", function()
	for _, key in { "spark", "smoke", "slash", "ring", "goo", "softglow" } do
		eq(VfxTextures[key], 0, key .. " texture placeholder")
		eq(VfxTextures.asset(key), "", key .. " zero texture fallback")
	end
end)

test("prop scatter is deterministic, dense, and keeps protected lanes clear", function()
	local options = {
		Seed = 2048,
		Bounds = { x = 0, z = 0, Width = 96, Depth = 96 },
		Spacing = 8,
		Spawns = { { x = 32, z = 32 } },
		SpawnClearance = 10,
		Lanes = { { ax = -48, az = 0, bx = 48, bz = 0, HalfWidth = 4 } },
	}
	local first = PropScatter.generate(options)
	local second = PropScatter.generate(options)
	eq(#first, #second, "repeat count")
	assert(#first >= 70 and #first <= 150, "scatter density stays in its band")
	for index, prop in first do
		eq(prop.Kind, second[index].Kind, "repeat kind")
		close(prop.x, second[index].x, "repeat x")
		close(prop.z, second[index].z, "repeat z")
		assert(math.abs(prop.z) > 4, "gate lane remains clear")
		local dx, dz = prop.x - 32, prop.z - 32
		assert(dx * dx + dz * dz > 100, "spawn remains clear")
	end
end)

test("each campaign map has a distinct L1 grade", function()
	local seen = {}
	for _, map in Campaign.All do
		local preset = LightingPresets[map.LightingPreset]
		assert(preset ~= nil, map.Name .. " preset exists")
		assert(
			preset.Atmosphere.Density >= 0.25 and preset.Atmosphere.Density <= 0.38,
			"density about 0.3"
		)
		close(preset.ColorCorrection.Contrast, 0.15, map.Name .. " contrast")
		close(preset.ColorCorrection.Saturation, 0.15, map.Name .. " saturation")
		local signature = table.concat(preset.Sky.Tint, ",")
		assert(not seen[signature], map.Name .. " has a distinct sky tint")
		seen[signature] = true
	end
end)

test("kill feel uses exact local freezes and three sound layers", function()
	eq(Feel.Events.Kill.FreezeMs, 50, "kill hitstop")
	eq(Feel.Events.EliteKill.FreezeMs, 80, "elite hitstop")
	eq(Feel.GemMagnetRadius, 18, "gem magnet radius")
	assert(Feel.GhostKnockbackStuds >= 2 and Feel.GhostKnockbackStuds <= 4, "ghost knockback")
	for _, name in { "KillCrunch", "KillGoo", "KillTick" } do
		assert(Sounds[name] ~= nil, name .. " exists")
	end
end)

test("camera stays twelve studs out and fades nearby enemies", function()
	eq(CameraConfig.Distance, 12, "fixed camera distance")
	eq(CameraConfig.CrowdedDistance, 12, "camera does not zoom through enemies")
	eq(CameraConfig.EnemyFadeRadius, 4, "fade radius")
	eq(CameraConfig.EnemyFadeTransparency, 0.7, "normal fade")
	eq(CameraConfig.BossFadeMultiplier, 1.5, "boss multiplier")
end)

test("generated arena has no oversized Neon", function()
	local files = ArenaModelGenerator.build(ArenaLayout, Theme)
	local function walk(node)
		local properties = node.properties
		if properties and properties.Material == "Neon" then
			local size = properties.Size
			assert(
				math.max(size[1], size[2], size[3]) <= 1.5,
				properties.Name .. " is oversized Neon"
			)
		end
		for _, child in node.children or {} do
			walk(child)
		end
	end
	for _, file in files do
		walk(file.Contents)
	end
end)

test("kill effects use the shared pooled frame driver", function()
	local clientFx = fs.readFile("src/StarterPlayer/StarterPlayerScripts/ClientFX.luau")
	local hitMarkers = fs.readFile("src/StarterPlayer/StarterPlayerScripts/HitMarkers.client.luau")
	local enemyAnimator =
		fs.readFile("src/StarterPlayer/StarterPlayerScripts/EnemyAnimator.client.luau")
	assert(
		clientFx:find("RunService.RenderStepped:Connect", 1, true),
		"shared RenderStepped driver"
	)
	assert(clientFx:find("local gemPool = PoolSize.new", 1, true), "gem pool")
	assert(clientFx:find("local ghostPool = PoolSize.new", 1, true), "death ghost pool")
	assert(clientFx:find("local ringPool = PoolSize.new", 1, true), "ring pool")
	assert(not hitMarkers:find('Instance.new("Part")', 1, true), "hit path allocates a Part")
	assert(
		not hitMarkers:find('Instance.new("ParticleEmitter")', 1, true),
		"hit path allocates a ParticleEmitter"
	)
	assert(not enemyAnimator:find("Heartbeat:Wait", 1, true), "death ghost owns a frame loop")
end)
