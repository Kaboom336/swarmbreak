--!strict
-- Families translate stable wave roles into the concrete enemy keys used by combat.
export type Roles = { [string]: string }
export type Family = { Roles: Roles, Rigs: Roles? }

local EnemyFamilies = {}

EnemyFamilies.RequiredRoles = { "Swarmer", "Runner", "Shooter", "Tank", "Flyer" }
EnemyFamilies.All = {
	Nest = {
		Roles = {
			Swarmer = "Walker",
			Runner = "Runner",
			Shooter = "Spitter",
			Tank = "Tank",
			Flyer = "Flyer",
			Elite = "Brute",
			Boss = "Queen",
		},
		Rigs = {
			Swarmer = "Mite",
			Runner = "Runner",
			Shooter = "Shooter",
			Tank = "Tank",
			Flyer = "Flyer",
			Boss = "Queen",
		},
	},
} :: { [string]: Family }

-- Rig height in studs per role (S6 bands; a player is about 5). Rigs scale to these, not
-- to the old primitive Size, which made every Nest rig about twice its band.
EnemyFamilies.RigHeights = {
	Swarmer = 4.5,
	Runner = 5.5,
	Shooter = 6.5,
	Tank = 10,
	Flyer = 6,
	Elite = 18,
	Boss = 16,
} :: { [string]: number }

function EnemyFamilies.roleForEnemy(familyId: string, enemyType: string): string?
	local family = EnemyFamilies.All[familyId]
	if not family then
		return nil
	end
	for role, mappedEnemy in family.Roles do
		if mappedEnemy == enemyType then
			return role
		end
	end
	return nil
end

function EnemyFamilies.rigHeight(familyId: string, enemyType: string): number?
	local role = EnemyFamilies.roleForEnemy(familyId, enemyType)
	return if role then EnemyFamilies.RigHeights[role] else nil
end

function EnemyFamilies.isRole(role: string): boolean
	return table.find(EnemyFamilies.RequiredRoles, role) ~= nil or role == "Elite"
end

function EnemyFamilies.resolve(familyId: string, role: string): string?
	local family = EnemyFamilies.All[familyId]
	return if family then family.Roles[role] else nil
end

function EnemyFamilies.resolveRig(familyId: string, role: string): string?
	local family = EnemyFamilies.All[familyId]
	return if family and family.Rigs then family.Rigs[role] else nil
end

function EnemyFamilies.rigForEnemy(familyId: string, enemyType: string): string?
	local family = EnemyFamilies.All[familyId]
	if not family or not family.Rigs then
		return nil
	end
	for role, mappedEnemy in family.Roles do
		if mappedEnemy == enemyType then
			return family.Rigs[role]
		end
	end
	return nil
end

return EnemyFamilies
