--!strict
local Config = load("Config")
local Grow = load("Grow")

local function near(actual: number, expected: number, tolerance: number, message: string)
	if math.abs(actual - expected) > tolerance then
		error(string.format("%s: expected %.8f, got %.8f", message, expected, actual), 2)
	end
end

test("grow math applies the configured base amount", function()
	eq(Grow.amount(), Config.SizePerClick, "unmodified grow amount")
	eq(Grow.amount({ doubleSize = true }), Config.SizePerClick * 2, "double size amount")
end)

test("rate limiter accepts ten requests per sliding second", function()
	local limiter = Grow.newRateLimiter(10, 1)
	for index = 1, 10 do
		eq(limiter:allow("player", (index - 1) * 0.01), true, "request within limit")
	end
	eq(limiter:allow("player", 0.99), false, "eleventh request")
	eq(limiter:allow("player", 1), true, "oldest request expired")
	limiter:clear("player")
	eq(limiter:allow("player", 1.01), true, "cleared player")
end)

test("multiplier stacking combines additive bonuses before pass multipliers", function()
	local multiplier = Grow.multiplier({
		rebirths = 2,
		petMultipliers = { 1.2, 2 },
		doubleSize = true,
		vip = true,
	})
	-- Base 1 + rebirth bonus 1 + pet contribution (3.2 - 1), then x2 and x1.5.
	near(multiplier, 12.6, 1e-9, "stacked multiplier")
	eq(Grow.multiplier({ petMultipliers = {} }), 1, "no equipped pets")
end)

test("pumpkin scale follows the logarithmic curve and cap", function()
	near(Grow.pumpkinScale(0), 1, 1e-9, "zero size")
	near(Grow.pumpkinScale(9), 2.5, 1e-9, "one log decade")
	near(Grow.pumpkinScale(99), 4, 1e-9, "two log decades")
	eq(Grow.pumpkinScale(1e100), Config.PumpkinMaxScale, "scale cap")
	eq(Grow.pumpkinScale(-10), 1, "negative size is clamped")
end)
