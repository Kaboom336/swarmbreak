local AutoAim = load("AutoAim")
local Settings = load("Settings")

local origin = { x = 0, z = 0 }

test("auto-fire defaults on", function()
	eq(Settings.AutoFire, true, "auto-fire default")
end)

local function target(x, z, options)
	options = options or {}
	return {
		position = { x = x, y = options.y, z = z },
		velocity = options.velocity,
		boss = options.boss,
		visible = options.visible ~= false,
	}
end

test("the closest visible target wins", function()
	local targets = {
		target(20, 0),
		target(8, 0),
		target(12, 0),
	}
	eq(AutoAim.pickTarget(origin, targets, 50, nil), 2, "closest target")
end)

test("a boss within 1.3 times the closest distance wins", function()
	local targets = {
		target(10, 0),
		target(13, 0, { boss = true }),
	}
	eq(AutoAim.pickTarget(origin, targets, 50, nil), 2, "nearby boss")
end)

test("an enemy closing in receives a modest priority boost", function()
	local targets = {
		target(10, 0),
		target(11, 0, { velocity = { x = -20, z = 0 } }),
	}
	eq(AutoAim.pickTarget(origin, targets, 50, nil), 2, "closing target")
end)

test("the current target is kept until another is fifteen percent closer", function()
	local targets = {
		target(8.6, 0),
		target(10, 0),
	}
	eq(AutoAim.pickTarget(origin, targets, 50, 2), 2, "hysteresis keeps current")

	targets[1] = target(8.5, 0)
	eq(AutoAim.pickTarget(origin, targets, 50, 2), 1, "fifteen percent closer wins")
end)

test("out of range and blocked targets are ignored", function()
	local targets = {
		target(0, 0, { y = 51 }),
		target(10, 0, { visible = false }),
	}
	eq(AutoAim.pickTarget(origin, targets, 50, nil), nil, "no eligible target")
end)

test("cadence never beats one over the fire rate", function()
	eq(AutoAim.canFire(10.24, 10, 4), false, "too early")
	eq(AutoAim.canFire(10.25, 10, 4), true, "exact interval")
	eq(AutoAim.canFire(10, nil, 4), true, "first shot")
	eq(AutoAim.canFire(10, 9, 0), false, "invalid rate")
end)
