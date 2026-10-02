--!strict
-- Enemy definitions as plain data (arrays for size/color so tests can load this file).
export type EnemyDef = {
	Name: string,
	Health: number,
	Speed: number,
	Damage: number,
	Size: { number }, -- x, y, z studs
	Scale: number, -- height relative to a player
	Color: { number }, -- r, g, b 0..255
	Flying: boolean,
	Ranged: boolean?, -- attacks from range instead of contact
	Range: number?,
	AttackCooldown: number?,
	Coins: number,
	Boss: boolean?,
	Summons: string?, -- boss spawns this type while alive
	SummonEvery: number?,
}

local Defs: { [string]: EnemyDef } = {
	Walker = {
		Name = "Walker",
		Health = 20,
		Speed = 7,
		Damage = 8,
		Size = { 3, 5, 2 },
		Scale = 1.2,
		Color = { 120, 60, 60 },
		Flying = false,
		Coins = 5,
	},
	Runner = {
		Name = "Runner",
		Health = 18,
		Speed = 22,
		Damage = 5,
		Size = { 2, 4, 1.5 },
		Scale = 1.0,
		Color = { 220, 160, 40 },
		Flying = false,
		Coins = 6,
	},
	Flyer = {
		Name = "Flyer",
		Health = 25,
		Speed = 16,
		Damage = 6,
		Size = { 3, 2, 3 },
		Scale = 1.1,
		Color = { 90, 90, 200 },
		Flying = true,
		Coins = 7,
	},
	Tank = {
		Name = "Tank",
		Health = 160,
		Speed = 8,
		Damage = 16,
		Size = { 5, 7, 4 },
		Scale = 1.6,
		Color = { 70, 90, 70 },
		Flying = false,
		Coins = 14,
	},
	Spitter = {
		Name = "Spitter",
		Health = 30,
		Speed = 10,
		Damage = 7,
		Size = { 2.5, 4.5, 2 },
		Scale = 1.1,
		Color = { 120, 200, 80 },
		Flying = false,
		Ranged = true,
		Range = 45,
		AttackCooldown = 2,
		Coins = 9,
	},
	-- Bosses
	Brute = {
		Name = "Big Brute",
		Health = 900,
		Speed = 9,
		Damage = 25,
		Size = { 8, 12, 6 },
		Scale = 2.6,
		Color = { 60, 20, 20 },
		Flying = false,
		Coins = 60,
		Boss = true,
	},
	Queen = {
		Name = "Swarm Queen",
		Health = 1800,
		Speed = 7,
		Damage = 20,
		Size = { 10, 9, 10 },
		Scale = 3.0,
		Color = { 150, 40, 120 },
		Flying = false,
		Coins = 120,
		Boss = true,
		Summons = "Runner",
		SummonEvery = 6,
	},
	Warden = {
		Name = "Sky King",
		Health = 3000,
		Speed = 14,
		Damage = 30,
		Size = { 12, 5, 12 },
		Scale = 3.2,
		Color = { 30, 30, 60 },
		Flying = true,
		Ranged = true,
		Range = 60,
		AttackCooldown = 1.5,
		Coins = 250,
		Boss = true,
	},
}

local Enemies = { Defs = Defs }

-- Spawn weights per wave. Later waves add tougher types.
function Enemies.weightsForWave(wave: number): { [string]: number }
	local w: { [string]: number } = { Walker = 5 }
	if wave >= 2 then
		w.Runner = 3
	end
	if wave >= 3 then
		w.Flyer = 2
	end
	if wave >= 6 then
		w.Tank = 1 + math.floor((wave - 6) / 3)
	end
	if wave >= 8 then
		w.Spitter = 2
	end
	return w
end

function Enemies.bossForWave(wave: number): string?
	if wave == 5 then
		return "Brute"
	elseif wave == 10 then
		return "Queen"
	elseif wave == 15 then
		return "Warden"
	elseif wave > 15 and wave % 5 == 0 then
		-- infinite mode: cycle the three bosses
		local cycle = { "Brute", "Queen", "Warden" }
		return cycle[((wave / 5 - 1) % 3) + 1]
	end
	return nil
end

-- Pick a type name from weights using a roll in [0, 1).
function Enemies.pickFromWeights(weights: { [string]: number }, roll01: number): string
	local names = {}
	for name in weights do
		table.insert(names, name)
	end
	table.sort(names)
	local total = 0
	for _, name in names do
		total += weights[name]
	end
	local r = roll01 * total
	for _, name in names do
		r -= weights[name]
		if r < 0 then
			return name
		end
	end
	return names[#names]
end

return Enemies
