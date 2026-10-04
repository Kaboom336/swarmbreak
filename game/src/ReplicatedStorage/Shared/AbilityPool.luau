--!strict
export type Ability = {
	Id: string,
	Name: string,
	Cooldown: number,
	Implemented: boolean,
	Price: number,
}
export type Loadout = {
	Abilities: { string },
	Ultimate: string,
}

local AbilityPool = {}

AbilityPool.ByWeapon = {
	Reaper = {
		{ Id = "HeavySweep", Name = "Heavy Sweep", Cooldown = 5, Implemented = true, Price = 0 },
		{ Id = "DashSpin", Name = "Dash Spin", Cooldown = 7, Implemented = true, Price = 0 },
		{
			Id = "CrescentPull",
			Name = "Crescent Pull",
			Cooldown = 9,
			Implemented = true,
			Price = 0,
		},
		{ Id = "SoulStep", Name = "Soul Step", Cooldown = 8, Implemented = false, Price = 0 },
		{
			Id = "HarvestGuard",
			Name = "Harvest Guard",
			Cooldown = 12,
			Implemented = false,
			Price = 0,
		},
		{ Id = "GrimEcho", Name = "Grim Echo", Cooldown = 10, Implemented = false, Price = 0 },
	},
} :: { [string]: { Ability } }

AbilityPool.Ultimates = { Reaper = "ReaperArc" }
AbilityPool.Defaults = {
	Reaper = { Abilities = { "HeavySweep", "DashSpin" }, Ultimate = "ReaperArc" },
} :: { [string]: Loadout }

function AbilityPool.forWeapon(weaponId: string): { Ability }
	return AbilityPool.ByWeapon[weaponId] or {}
end

function AbilityPool.find(weaponId: string, abilityId: string): Ability?
	for _, ability in AbilityPool.forWeapon(weaponId) do
		if ability.Id == abilityId then
			return ability
		end
	end
	return nil
end

function AbilityPool.defaultLoadout(weaponId: string): Loadout
	local loadout = AbilityPool.Defaults[weaponId]
	if not loadout then
		return { Abilities = {}, Ultimate = "" }
	end
	return { Abilities = table.clone(loadout.Abilities), Ultimate = loadout.Ultimate }
end

function AbilityPool.isValidLoadout(weaponId: string, loadout: any): boolean
	if
		type(loadout) ~= "table"
		or type(loadout.Abilities) ~= "table"
		or #loadout.Abilities ~= 2
	then
		return false
	end
	if loadout.Abilities[1] == loadout.Abilities[2] then
		return false
	end
	for _, abilityId in loadout.Abilities do
		if type(abilityId) ~= "string" or not AbilityPool.find(weaponId, abilityId) then
			return false
		end
	end
	return loadout.Ultimate == AbilityPool.Ultimates[weaponId]
end

return AbilityPool
