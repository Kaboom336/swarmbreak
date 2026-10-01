--!strict
-- Weapon catalog: guns, melee, orbitals and beams, over 4 rarities. Pure data + crate math.
-- Kinds:
--   Hitscan  - click to fire rays (pellets, spread)
--   Melee    - swing: damages everything in a cone in front; Slam = ground AoE ring
--   Orbital  - blades circle the player and damage on contact, always on
--   Beam     - hold to sweep a continuous beam; damage ticks while it touches
export type Rarity = "Common" | "Rare" | "Epic" | "Legendary"
export type Kind = "Hitscan" | "Melee" | "Orbital" | "Beam"
export type WeaponDef = {
	Id: string,
	Name: string,
	Rarity: Rarity,
	Kind: Kind,
	Damage: number, -- per hit (Hitscan/Melee), per orb per touch (Orbital), per tick (Beam)
	FireRate: number, -- actions per second (Hitscan/Melee), ticks per second (Beam), touches per second per orb (Orbital)
	Range: number, -- studs: ray length, melee reach, orbit radius, beam length
	Pellets: number, -- rays per shot (Hitscan) / number of orbs (Orbital)
	Spread: number, -- degrees (Hitscan) / cone half-angle (Melee)
	Slam: boolean?, -- melee: hits all around instead of a cone
	Lunge: number?, -- melee: forward dash studs on swing
	Description: string,
}

local function def(fields: WeaponDef): WeaponDef
	return fields
end

local Weapons = {}

Weapons.Defs = {
	-- Common
	Starter = def({
		Id = "Starter",
		Name = "Starter Pistol",
		Rarity = "Common",
		Kind = "Hitscan",
		Damage = 10,
		FireRate = 4,
		Range = 80,
		Pellets = 1,
		Spread = 0,
		Description = "Reliable sidearm.",
	}),
	Burst = def({
		Id = "Burst",
		Name = "Burst SMG",
		Rarity = "Common",
		Kind = "Hitscan",
		Damage = 6,
		FireRate = 9,
		Range = 60,
		Pellets = 1,
		Spread = 2,
		Description = "Sprays fast, kicks a little.",
	}),
	Blade = def({
		Id = "Blade",
		Name = "Rusty Blade",
		Rarity = "Common",
		Kind = "Melee",
		Damage = 18,
		FireRate = 2.2,
		Range = 9,
		Pellets = 1,
		Spread = 60,
		Description = "Wide swing. Hits everything in front.",
	}),
	-- Rare
	Scatter = def({
		Id = "Scatter",
		Name = "Shotgun",
		Rarity = "Rare",
		Kind = "Hitscan",
		Damage = 7,
		FireRate = 1.6,
		Range = 35,
		Pellets = 6,
		Spread = 8,
		Description = "Six pellets. Get close.",
	}),
	Marksman = def({
		Id = "Marksman",
		Name = "Sniper Rifle",
		Rarity = "Rare",
		Kind = "Hitscan",
		Damage = 34,
		FireRate = 1.2,
		Range = 160,
		Pellets = 1,
		Spread = 0,
		Description = "One shot, long reach.",
	}),
	Hammer = def({
		Id = "Hammer",
		Name = "Shock Hammer",
		Rarity = "Rare",
		Kind = "Melee",
		Damage = 55,
		FireRate = 0.9,
		Range = 12,
		Pellets = 1,
		Spread = 180,
		Slam = true,
		Description = "Slam the ground. Hits all around you.",
	}),
	Guardian = def({
		Id = "Guardian",
		Name = "Spinning Blades",
		Rarity = "Rare",
		Kind = "Orbital",
		Damage = 12,
		FireRate = 2,
		Range = 7,
		Pellets = 2,
		Spread = 0,
		Description = "Two blades circle you and cut whatever they touch.",
	}),
	-- Epic
	Arc = def({
		Id = "Arc",
		Name = "Laser Rifle",
		Rarity = "Epic",
		Kind = "Hitscan",
		Damage = 20,
		FireRate = 7,
		Range = 120,
		Pellets = 1,
		Spread = 1,
		Description = "Fast energy bolts.",
	}),
	Hornet = def({
		Id = "Hornet",
		Name = "Triple Rocket",
		Rarity = "Epic",
		Kind = "Hitscan",
		Damage = 18,
		FireRate = 3,
		Range = 90,
		Pellets = 3,
		Spread = 5,
		Description = "Three-bolt volleys.",
	}),
	Saber = def({
		Id = "Saber",
		Name = "Energy Sword",
		Rarity = "Epic",
		Kind = "Melee",
		Damage = 30,
		FireRate = 4,
		Range = 10,
		Pellets = 1,
		Spread = 70,
		Lunge = 6,
		Description = "Lightning-fast slashes with a short lunge.",
	}),
	Storm = def({
		Id = "Storm",
		Name = "Lightning Orbs",
		Rarity = "Epic",
		Kind = "Orbital",
		Damage = 14,
		FireRate = 2.5,
		Range = 9,
		Pellets = 4,
		Spread = 0,
		Description = "Four charged orbs spin around you.",
	}),
	Ion = def({
		Id = "Ion",
		Name = "Laser Beam",
		Rarity = "Epic",
		Kind = "Beam",
		Damage = 9,
		FireRate = 8,
		Range = 70,
		Pellets = 1,
		Spread = 0,
		Description = "Hold to sweep a beam that melts everything it touches.",
	}),
	-- Legendary
	Nova = def({
		Id = "Nova",
		Name = "Heavy Cannon",
		Rarity = "Legendary",
		Kind = "Hitscan",
		Damage = 48,
		FireRate = 2.2,
		Range = 110,
		Pellets = 4,
		Spread = 4,
		Description = "Four heavy bolts per shot.",
	}),
	Reaper = def({
		Id = "Reaper",
		Name = "Dark Scythe",
		Rarity = "Legendary",
		Kind = "Melee",
		Damage = 90,
		FireRate = 1.6,
		Range = 14,
		Pellets = 1,
		Spread = 120,
		Lunge = 12,
		Description = "A scythe swing with a long lunge. Clears crowds.",
	}),
	Halo = def({
		Id = "Halo",
		Name = "Sun Orbs",
		Rarity = "Legendary",
		Kind = "Orbital",
		Damage = 22,
		FireRate = 3,
		Range = 12,
		Pellets = 6,
		Spread = 0,
		Description = "Six burning suns orbit you at range.",
	}),
} :: { [string]: WeaponDef }

Weapons.RarityOrder = { "Common", "Rare", "Epic", "Legendary" }
Weapons.KindOrder = { "Hitscan", "Melee", "Orbital", "Beam" }
Weapons.RarityColor = {
	Common = { 200, 200, 200 },
	Rare = { 70, 140, 255 },
	Epic = { 170, 80, 255 },
	Legendary = { 255, 170, 30 },
}

-- ---------- crates ----------
-- Three crates, odds in percent. Roblox policy: display the odds (and the pity rule) wherever a
-- crate is sold. Gem = the free path to a second weapon (Gems earned in runs; never Legendary).
-- Basic and Epic = Robux products (Monetization.DeveloperProducts keys) that count toward pity.
export type Odds = { [string]: number }
export type Crate = {
	Label: string,
	Gems: number?, -- costs Gems (the free path)
	Product: string?, -- Monetization.DeveloperProducts key (the Robux path)
	Odds: Odds,
	Pity: boolean, -- counts toward the guaranteed Legendary
}

Weapons.Crates = {
	Gem = {
		Label = "Gem crate",
		Gems = 150,
		Odds = { Common = 70, Rare = 25, Epic = 5, Legendary = 0 },
		Pity = false,
	},
	Basic = {
		Label = "Weapon crate",
		Product = "WeaponCrate",
		Odds = { Common = 65, Rare = 25, Epic = 8.5, Legendary = 1.5 },
		Pity = true,
	},
	Epic = {
		Label = "Epic crate",
		Product = "EpicCrate",
		Odds = { Common = 0, Rare = 55, Epic = 35, Legendary = 10 },
		Pity = true,
	},
} :: { [string]: Crate }
Weapons.CrateOrder = { "Gem", "Basic", "Epic" }
-- Kept as an alias of the Basic crate so older callers still work.
Weapons.RarityOdds = Weapons.Crates.Basic.Odds

-- Gems paid back when a crate rolls a weapon the player already owns.
Weapons.DuplicateGems =
	{ Common = 30, Rare = 80, Epic = 200, Legendary = 500 } :: { [string]: number }
-- Pity: every Robux crate counts, and the PityAt-th crate since the last Legendary is Legendary.
Weapons.PityAt = 40

local function ordinal(n: number): string
	local tens = n % 100
	local ones = n % 10
	local suffix = if tens >= 11 and tens <= 13
		then "th"
		elseif ones == 1 then "st"
		elseif ones == 2 then "nd"
		elseif ones == 3 then "rd"
		else "th"
	return tostring(n) .. suffix
end

-- Odds of one crate in words (default Basic). Rarities at 0% are left out; a pity crate
-- also says the guarantee in words, as the policy asks.
function Weapons.oddsText(crateKey: string?): string
	local crate = Weapons.Crates[crateKey or "Basic"]
	local parts = {}
	for _, r in Weapons.RarityOrder do
		local pct = crate.Odds[r] or 0
		if pct > 0 then
			table.insert(parts, string.format("%s %s%%", r, tostring(pct)))
		end
	end
	local out = table.concat(parts, "  ")
	if crate.Pity then
		out ..= string.format(
			"  Legendary guaranteed by the %s Robux crate",
			ordinal(Weapons.PityAt)
		)
	end
	return out
end

-- roll01 in [0, 1), odds default to the Basic crate. Deterministic so tests can cover it.
-- Rarities with 0 weight are skipped, and the fallback is the last rarity with any weight,
-- so a crate whose Legendary weight is 0 can never return Legendary.
function Weapons.rollRarity(roll01: number, odds: Odds?): Rarity
	local o = odds or Weapons.Crates.Basic.Odds
	local r = roll01 * 100
	local acc = 0
	local last: Rarity = "Common"
	for _, rarity in Weapons.RarityOrder do
		local weight = o[rarity] or 0
		if weight > 0 then
			acc += weight
			last = rarity :: Rarity
			if r < acc then
				return last
			end
		end
	end
	return last
end

-- Pity, applied after the roll: the crate being opened is number cratesSinceLegendary + 1.
function Weapons.applyPity(rarity: Rarity, cratesSinceLegendary: number): Rarity
	if cratesSinceLegendary + 1 >= Weapons.PityAt then
		return "Legendary"
	end
	return rarity
end

-- The counter after a pity crate opened: back to 0 on a Legendary, else one more.
function Weapons.nextPityCount(rarity: Rarity, count: number): number
	return if rarity == "Legendary" then 0 else count + 1
end

function Weapons.idsOfRarity(rarity: Rarity): { string }
	local ids = {}
	for id, w in Weapons.Defs do
		if w.Rarity == rarity then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

-- Full crate roll (default Basic): rarity then a weapon of that rarity. Two rolls in [0, 1).
function Weapons.rollCrate(roll01: number, roll02: number, crateKey: string?): string
	local crate = Weapons.Crates[crateKey or "Basic"]
	local rarity = Weapons.rollRarity(roll01, crate.Odds)
	local ids = Weapons.idsOfRarity(rarity)
	local idx = math.floor(roll02 * #ids) + 1
	return ids[math.clamp(idx, 1, #ids)]
end

-- Rough damage-per-second estimate used to sort the hotbar.
function Weapons.power(w: WeaponDef): number
	if w.Kind == "Orbital" then
		return w.Damage * w.FireRate * w.Pellets * 0.6
	elseif w.Kind == "Melee" then
		return w.Damage * w.FireRate * 1.5 -- multi-target
	elseif w.Kind == "Beam" then
		return w.Damage * w.FireRate
	end
	return w.Damage * w.FireRate * w.Pellets
end

return Weapons
