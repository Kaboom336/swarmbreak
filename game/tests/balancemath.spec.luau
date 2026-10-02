local BalanceMath = load("BalanceMath")
local Config = load("Config")
local Enemies = load("Enemies")
local WaveTable = load("WaveTable")
local Weapons = load("Weapons")

test("DPS formula matches weapon stats and multipliers", function()
	local starter = Weapons.Defs.Starter
	eq(BalanceMath.damagePerSecond(starter), 40, "starter DPS")

	local scatter = Weapons.Defs.Scatter
	eq(
		BalanceMath.damagePerSecond(scatter),
		scatter.Damage * scatter.Pellets * scatter.FireRate,
		"shotgun DPS includes every pellet"
	)
	eq(BalanceMath.damagePerSecond(starter, 1.5, 1.25), 75, "DPS multipliers")
end)

test("wave 1 Walker TTK with the starter is at most one second", function()
	local healthScale = WaveTable.scaling(1)
	local ttk =
		BalanceMath.timeToKill(Enemies.Defs.Walker.Health, Weapons.Defs.Starter, healthScale)
	assert(ttk <= 1, "wave 1 Walker TTK exceeds one second: " .. tostring(ttk))
end)

test("wave 10 Walker TTK with a level 5 upgraded starter is in range", function()
	local healthScale = WaveTable.scaling(10)
	local damage = Config.Upgrades.Damage
	local damageMultiplier = damage.Base + damage.PerLevel * 5
	local ttk = BalanceMath.timeToKill(
		Enemies.Defs.Walker.Health,
		Weapons.Defs.Starter,
		healthScale,
		damageMultiplier
	)
	assert(ttk >= 0.5 and ttk <= 3, "wave 10 upgraded Walker TTK out of range: " .. tostring(ttk))
end)
