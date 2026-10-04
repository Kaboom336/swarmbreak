local EnemyFamilies = load("EnemyFamilies")
local WaveTable = load("WaveTable")

test("every enemy family fills all five combat roles", function()
	for familyId, family in EnemyFamilies.All do
		for _, role in EnemyFamilies.RequiredRoles do
			assert(family.Roles[role], familyId .. " is missing " .. role)
		end
	end
end)

test("Nest roles resolve to existing enemy keys", function()
	local expected = {
		Swarmer = "Walker",
		Runner = "Runner",
		Shooter = "Spitter",
		Tank = "Tank",
		Flyer = "Flyer",
		Elite = "Brute",
	}
	for role, enemyKey in expected do
		eq(EnemyFamilies.resolve("Nest", role), enemyKey, role)
	end
end)

test("wave compositions use roles and resolve through a family", function()
	for wave, composition in WaveTable.Compositions do
		for role in composition do
			assert(EnemyFamilies.isRole(role) or role == "Boss", "wave uses raw key " .. role)
		end
		local resolved = WaveTable.resolveComposition(composition, "Nest", "Queen")
		assert(next(resolved), "resolved wave " .. wave .. " is empty")
	end
end)
