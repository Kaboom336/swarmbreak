local Enemies = load("Enemies")
local Fit = load("Fit")

local PLAYER_HEIGHT = 5
local TARGET_HEIGHTS = {
	Walker = 10,
	Runner = 8,
	Spitter = 9,
	Flyer = 8,
	Tank = 16.9,
	Brute = 23.4,
	Queen = 26.4,
	Warden = 26.4,
	Swarmling = 6,
}

test("enemy heights stay within ten percent of their targets", function()
	for name, targetHeight in TARGET_HEIGHTS do
		local actualHeight = Enemies.Defs[name].Scale * PLAYER_HEIGHT
		local errorRatio = math.abs(actualHeight - targetHeight) / targetHeight
		assert(errorRatio <= 0.1, name .. " height")
	end
end)

test("wide imported meshes fit Walker by height", function()
	local fitted = Fit.sizeForRelativeHeight({ 10, 4, 2 }, Enemies.Defs.Walker.Scale, PLAYER_HEIGHT)
	eq(fitted[2], 10, "Walker height")
end)

test("wide bosses keep their footprint within MaxWidth", function()
	local scale = Fit.capWidth(Enemies.Defs.Warden.Scale, 12, 12, Enemies.Defs.Warden.MaxWidth)
	assert(12 * scale <= Enemies.Defs.Warden.MaxWidth + 1e-6, "Warden width")
	eq(Fit.capWidth(2, 3, 2, nil), 2, "no cap")
end)
