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
		},
		Rigs = {
			Swarmer = "Mite",
			Runner = "Runner",
			Shooter = "Shooter",
			Tank = "Tank",
			Flyer = "Flyer",
		},
	},
} :: { [string]: Family }

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
