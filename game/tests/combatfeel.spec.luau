--!strict
local fs = require("@lune/fs")
local AimAssist = load("AimAssist")
local Feel = load("Feel")

local origin = { x = 0, z = 0 }
local facing = { x = 1, z = 0 }

test("PC aim assist picks the nearest enemy inside its six degree cone", function()
	local insideNear = math.rad(5)
	local insideFar = math.rad(-4)
	local outside = math.rad(7)
	local enemies = {
		{ x = math.cos(outside) * 4, z = math.sin(outside) * 4 },
		{ x = math.cos(insideFar) * 15, z = math.sin(insideFar) * 15 },
		{ x = math.cos(insideNear) * 8, z = math.sin(insideNear) * 8 },
	}

	eq(AimAssist.PcConeDegrees, 6, "PC cone angle")
	eq(
		AimAssist.pickTargetInCone(origin, facing, enemies, 20, AimAssist.PcConeDegrees),
		3,
		"nearest target in cone"
	)
	eq(
		AimAssist.pickTargetInCone(origin, facing, { enemies[1] }, 20, AimAssist.PcConeDegrees),
		nil,
		"target outside cone"
	)
	eq(
		AimAssist.pickTargetInCone(origin, facing, { enemies[2] }, 10, AimAssist.PcConeDegrees),
		nil,
		"target outside weapon range"
	)
end)

test("combat feedback timings are immediate but readable", function()
	assert(Feel.TracerSeconds >= 0.06 and Feel.TracerSeconds <= 0.16, "tracer timing")
	assert(
		Feel.MuzzleFlashSeconds >= 0.04 and Feel.MuzzleFlashSeconds <= 0.1,
		"muzzle flash timing"
	)
	assert(Feel.HitFlashSeconds >= 0.04 and Feel.HitFlashSeconds <= 0.08, "hit flash timing")
	assert(Feel.HitSparkSeconds >= 0.2 and Feel.HitSparkSeconds <= 0.5, "hit spark timing")
	assert(Feel.CoinFlightSeconds >= 0.35 and Feel.CoinFlightSeconds <= 0.8, "coin pop timing")
	assert(Feel.KnockbackSpeed >= 4 and Feel.KnockbackSpeed <= 14, "knockback speed")
end)

test("non-button HUD objects are wired to let combat clicks through", function()
	local source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Hud.client.luau")
	assert(source:find('descendant:IsA("GuiObject")', 1, true), "HUD checks GUI descendants")
	assert(source:find('not descendant:IsA("GuiButton")', 1, true), "HUD preserves buttons")
	assert(source:find("descendant.Active = false", 1, true), "HUD disables frame input capture")
	assert(source:find("screen.DescendantAdded:Connect", 1, true), "HUD covers frames added later")
end)
