--!strict
local VfxDefs = load("VfxDefs")

local REQUIRED_EFFECTS = {
	"HitSpark",
	"MuzzleFlash",
	"DeathBurst",
	"SpawnBuildIn",
	"Telegraph",
	"PickupMagnet",
	"BossWeakPoint",
}

local function sameColor(first, second)
	return first[1] == second[1] and first[2] == second[2] and first[3] == second[3]
end

test("every effect fades in and out", function()
	for _, name in REQUIRED_EFFECTS do
		local effect = VfxDefs.Definitions[name]
		assert(effect ~= nil, name .. " definition is missing")
		local transparency = effect.Transparency
		assert(#transparency >= 2, name .. " needs at least two transparency keypoints")
		eq(transparency[1].Time, 0, name .. " first transparency time")
		eq(transparency[1].Value, 1, name .. " must start transparent")
		eq(transparency[#transparency].Time, 1, name .. " last transparency time")
		eq(transparency[#transparency].Value, 1, name .. " must end transparent")
	end
end)

test("particle rates stay under the mobile cap", function()
	for _, name in REQUIRED_EFFECTS do
		local effect = VfxDefs.Definitions[name]
		assert(effect.Rate >= 0, name .. " rate is below zero")
		assert(effect.Rate <= VfxDefs.MaxRate, name .. " rate exceeds the mobile cap")
	end
	eq(VfxDefs.MaxRate, 100, "documented mobile rate cap")
end)

test("worst-case particle load stays inside its budget", function()
	local total = VfxDefs.worstCaseEmitsPerSecond()
	assert(total > 0, "worst-case load should include the configured effects")
	assert(total <= VfxDefs.EmitBudgetPerSecond, "worst-case load exceeds the particle budget")
end)

test("enemy telegraphs use warm colors and never player hues", function()
	local telegraph = VfxDefs.Definitions.Telegraph
	for _, color in telegraph.Colors do
		assert(color[1] > color[2] and color[2] > color[3], "telegraph color is not warm")
		for _, playerHue in VfxDefs.PlayerHues do
			assert(not sameColor(color, playerHue), "telegraph reuses a player hue")
		end
	end
end)
