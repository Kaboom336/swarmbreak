local AimAssist = load("AimAssist")

local origin = { x = 0, z = 0 }
local facing = { x = 1, z = 0 }

test("an empty enemy list has no target", function()
	eq(AimAssist.pickTarget(origin, facing, {}, 50, 45), nil, "empty list")
end)

test("an enemy in the facing cone beats a nearer enemy behind", function()
	local enemies = {
		{ x = -2, z = 0 },
		{ x = 10, z = 1 },
	}
	eq(AimAssist.pickTarget(origin, facing, enemies, 50, 45), 2, "enemy in cone")
end)

test("without an enemy in the cone the nearest enemy wins", function()
	local enemies = {
		{ x = -8, z = 0 },
		{ x = 0, z = 4 },
	}
	eq(AimAssist.pickTarget(origin, facing, enemies, 50, 20), 2, "nearest enemy")
end)

test("enemies outside the maximum range are ignored", function()
	local enemies = {
		{ x = 51, z = 0 },
		{ x = -10, z = 0 },
	}
	eq(AimAssist.pickTarget(origin, facing, enemies, 50, 45), 2, "in-range enemy")
	eq(AimAssist.pickTarget(origin, facing, { enemies[1] }, 50, 45), nil, "all out of range")
end)

test("equal-distance targets use the lower index", function()
	local enemies = {
		{ x = 10, z = 2 },
		{ x = 10, z = -2 },
	}
	eq(AimAssist.pickTarget(origin, facing, enemies, 50, 45), 1, "stable tie")
end)
