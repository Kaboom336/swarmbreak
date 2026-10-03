--!strict
-- Permanent kits bought with Gems. Pure data and profile helpers, shared by the server and HUD.

export type Mods = {
	DamageMultByKind: { [string]: number },
	MaxHealth: number,
	Speed: number,
	OrbsAdd: number,
	HealOnKill: number,
}

export type KitDef = {
	Id: string,
	Label: string,
	Blurb: string,
	UnlockGems: number,
	StartWeapon: string,
	Signature: SignatureDef,
	Mods: Mods,
}

export type SignatureDef = {
	Id: string,
	Label: string,
	Icon: string,
	Cooldown: number,
	Effect: string,
}

type KitProfile = {
	Gems: number,
	KitsOwned: { [string]: boolean },
}

local Kits = {}

Kits.Order = { "Soldier", "Brawler", "Engineer", "Medic" }

Kits.Defs = {
	Soldier = {
		Id = "Soldier",
		Label = "Soldier",
		Blurb = "+10% Hitscan damage",
		UnlockGems = 0,
		StartWeapon = "Burst", -- start weapons stay Common: a free kit must not hand out crate loot
		Signature = {
			Id = "FragBurst",
			Label = "Frag Burst",
			Icon = "FRAG",
			Cooldown = 12,
			Effect = "FragBurst",
		},
		Mods = {
			DamageMultByKind = { Hitscan = 0.10 },
			MaxHealth = 0,
			Speed = 0,
			OrbsAdd = 0,
			HealOnKill = 0,
		},
	},
	Brawler = {
		Id = "Brawler",
		Label = "Brawler",
		Blurb = "+25 max HP, +15% Melee damage",
		UnlockGems = 0,
		StartWeapon = "Blade",
		Signature = {
			Id = "GroundSlam",
			Label = "Ground Slam",
			Icon = "SLAM",
			Cooldown = 10,
			Effect = "GroundSlam",
		},
		Mods = {
			DamageMultByKind = { Melee = 0.15 },
			MaxHealth = 25,
			Speed = 0,
			OrbsAdd = 0,
			HealOnKill = 0,
		},
	},
	Engineer = {
		Id = "Engineer",
		Label = "Engineer",
		Blurb = "+1 orb, +10% Orbital damage",
		UnlockGems = 0,
		StartWeapon = "Starter",
		Signature = {
			Id = "TurretDrop",
			Label = "Turret Drop",
			Icon = "TURRET",
			Cooldown = 18,
			Effect = "TurretDrop",
		},
		Mods = {
			DamageMultByKind = { Orbital = 0.10 },
			MaxHealth = 0,
			Speed = 0,
			OrbsAdd = 1,
			HealOnKill = 0,
		},
	},
	Medic = {
		Id = "Medic",
		Label = "Medic",
		Blurb = "Heal 2 HP per kill, +1 speed",
		UnlockGems = 0,
		StartWeapon = "Starter",
		Signature = {
			Id = "HealPulse",
			Label = "Heal Pulse",
			Icon = "HEAL",
			Cooldown = 14,
			Effect = "HealPulse",
		},
		Mods = {
			DamageMultByKind = {},
			MaxHealth = 0,
			Speed = 1,
			OrbsAdd = 0,
			HealOnKill = 2,
		},
	},
}

function Kits.startWeapon(id: string): string
	local def: KitDef = Kits.Defs[id] or Kits.Defs.Soldier
	return def.StartWeapon
end

-- Pure cooldown gate shared by the server and specs. readyAt is the previous cast's deadline.
function Kits.trySignature(id: string, now: number, readyAt: number): (boolean, number)
	local def: KitDef? = Kits.Defs[id]
	if not def then
		for _, kitId in Kits.Order do
			if Kits.Defs[kitId].Signature.Id == id then
				def = Kits.Defs[kitId]
				break
			end
		end
	end
	def = def or Kits.Defs.Soldier
	if now < readyAt then
		return false, readyAt
	end
	return true, now + (def :: KitDef).Signature.Cooldown
end

-- Resolve a kit for one weapon kind into damage, max HP, speed, orbs and healing numbers.
function Kits.mods(id: string, weaponKind: string): (number, number, number, number, number)
	local def: KitDef = Kits.Defs[id] or Kits.Defs.Soldier
	return 1 + (def.Mods.DamageMultByKind[weaponKind] or 0),
		def.Mods.MaxHealth,
		def.Mods.Speed,
		def.Mods.OrbsAdd,
		def.Mods.HealOnKill
end

function Kits.isUnlocked(profile: KitProfile, id: string): boolean
	return Kits.Defs[id] ~= nil and profile.KitsOwned[id] == true
end

-- Buy a kit in place. A failed purchase leaves the profile unchanged.
function Kits.unlock(profile: KitProfile, id: string): (KitProfile, boolean, string)
	local def: KitDef? = Kits.Defs[id]
	if not def then
		return profile, false, "Unknown kit."
	end
	if Kits.isUnlocked(profile, id) then
		return profile, false, "Already owned."
	end
	if profile.Gems < def.UnlockGems then
		return profile, false, string.format("Need %d Gems.", def.UnlockGems)
	end
	profile.Gems -= def.UnlockGems
	profile.KitsOwned[id] = true
	return profile, true, ""
end

return Kits
