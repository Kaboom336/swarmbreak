--!strict
-- Families translate stable wave roles into the concrete enemy keys used by combat.
export type Roles = { [string]: string }
export type Family = { Roles: Roles }

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
	},
} :: { [string]: Family }

function EnemyFamilies.isRole(role: string): boolean
	return table.find(EnemyFamilies.RequiredRoles, role) ~= nil or role == "Elite"
end

function EnemyFamilies.resolve(familyId: string, role: string): string?
	local family = EnemyFamilies.All[familyId]
	return if family then family.Roles[role] else nil
end

return EnemyFamilies
