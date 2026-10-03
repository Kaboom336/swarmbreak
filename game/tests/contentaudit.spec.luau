--!strict
local ContentAudit = load("ContentAudit")

local function realCatalogs()
	return {
		Weapons = load("Weapons"),
		Evolutions = load("Evolutions"),
		Enemies = load("Enemies"),
		WaveRewards = load("WaveRewards"),
		Kits = load("Kits"),
		Quests = load("Quests"),
		SfxMap = load("SfxMap"),
		Sounds = load("Sounds"),
		ModelAssets = load("ModelAssets"),
		Monetization = load("Monetization"),
		EnemyTells = load("EnemyTells"),
		VfxDefs = load("VfxDefs"),
	}
end

local function deepClone(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value do
		copy[deepClone(key)] = deepClone(child)
	end
	return copy
end

local function findDiagnostic(diagnostics, code: string, pathPart: string): any
	for _, diagnostic in diagnostics do
		if diagnostic.Code == code and string.find(diagnostic.Path, pathPart, 1, true) then
			return diagnostic
		end
	end
	return nil
end

local function expectDiagnostic(catalogs, code: string, pathPart: string)
	local diagnostics = ContentAudit.audit(catalogs)
	local diagnostic = findDiagnostic(diagnostics, code, pathPart)
	assert(
		diagnostic ~= nil,
		string.format("missing %s at %s; got %d diagnostics", code, pathPart, #diagnostics)
	)
	assert(string.find(ContentAudit.format(diagnostic), "[" .. code .. "]", 1, true))
end

test("real content catalogs have no drift", function()
	local diagnostics = ContentAudit.audit(realCatalogs())
	assert(#diagnostics == 0, if diagnostics[1] then ContentAudit.format(diagnostics[1]) else "")
end)

test(
	"ordered catalogs report duplicate ids, order keys, dangling keys, and dead entries",
	function()
		local catalogs = deepClone(realCatalogs())
		catalogs.Kits.Defs.Brawler.Id = "Soldier"
		table.insert(catalogs.Quests.Order, catalogs.Quests.Order[1])
		table.insert(catalogs.WaveRewards.Order, "Missing Card")
		table.remove(catalogs.VfxDefs.Order, #catalogs.VfxDefs.Order)
		expectDiagnostic(catalogs, "DUPLICATE_ID", "Kits.Defs")
		expectDiagnostic(catalogs, "DUPLICATE_ORDER_KEY", "Quests.Order")
		expectDiagnostic(catalogs, "DANGLING_KEY", "WaveRewards.Order")
		expectDiagnostic(catalogs, "DEAD_ENTRY", "VfxDefs.Definitions")
	end
)

test("embedded ids must match their catalog keys", function()
	local catalogs = deepClone(realCatalogs())
	catalogs.Weapons.Defs.Starter.Id = "Sidearm"
	expectDiagnostic(catalogs, "ID_KEY_MISMATCH", "Weapons.Defs")
end)

test("every required reverse mapping is present", function()
	local catalogs = deepClone(realCatalogs())
	catalogs.Sounds.ForWeapon.Starter = nil
	catalogs.EnemyTells.Defs.Walker = nil
	catalogs.ModelAssets["enemies/Walker"] = nil
	expectDiagnostic(catalogs, "MISSING_ENTRY", "Sounds.ForWeapon")
	expectDiagnostic(catalogs, "MISSING_ENTRY", "EnemyTells.Defs")
	expectDiagnostic(catalogs, "MISSING_ENTRY", "ModelAssets.enemies")
end)

test("duplicate model and published commerce ids are rejected", function()
	local catalogs = deepClone(realCatalogs())
	catalogs.ModelAssets["weapons/Arc"] = catalogs.ModelAssets["weapons/Blade"]
	catalogs.Monetization.GamePasses.DoubleCoins.Id = 123
	catalogs.Monetization.GamePasses.ExtraDash.Id = 123
	expectDiagnostic(catalogs, "DUPLICATE_NUMERIC_ID", "ModelAssets")
	expectDiagnostic(catalogs, "DUPLICATE_NUMERIC_ID", "Monetization.GamePasses")
end)

test("evolution effect, boss, and enemy summon references are checked", function()
	local catalogs = deepClone(realCatalogs())
	catalogs.Evolutions.Elements.Nature.Tiers[2].Effect = "MissingEffect"
	catalogs.Evolutions.BossShards.Brute = "MissingElement"
	catalogs.Enemies.Defs.Queen.Summons = "MissingEnemy"
	expectDiagnostic(catalogs, "DANGLING_KEY", "Evolutions.Elements")
	expectDiagnostic(catalogs, "DANGLING_KEY", "Evolutions.BossShards")
	expectDiagnostic(catalogs, "DANGLING_KEY", "Enemies.Defs")
end)

test("weapon kind, rarity, crate, and evolution effect dead entries are checked", function()
	local catalogs = deepClone(realCatalogs())
	table.insert(catalogs.Weapons.KindOrder, "Launcher")
	table.insert(catalogs.Weapons.RarityOrder, "Mythic")
	catalogs.Weapons.Crates.Unlisted = deepClone(catalogs.Weapons.Crates.Gem)
	catalogs.Evolutions.Effects.Unused = { Label = "Unused", Value = 1 }
	expectDiagnostic(catalogs, "DEAD_ENTRY", "Weapons.KindOrder")
	expectDiagnostic(catalogs, "DEAD_ENTRY", "Weapons.RarityOrder")
	expectDiagnostic(catalogs, "DEAD_ENTRY", "Weapons.Crates")
	expectDiagnostic(catalogs, "DEAD_ENTRY", "Evolutions.Effects")
end)

test("reward and kit weapon contracts reject unknown kinds and fields", function()
	local catalogs = deepClone(realCatalogs())
	catalogs.WaveRewards.Defs["Long Barrel"].Kinds[1] = "Launcher"
	catalogs.WaveRewards.Defs.Sharp.Apply.UnknownBoost = 1
	catalogs.Kits.Defs.Soldier.Mods.DamageMultByKind.Launcher = 0.1
	expectDiagnostic(catalogs, "DANGLING_KEY", 'WaveRewards.Defs["Long Barrel"].Kinds')
	expectDiagnostic(catalogs, "DANGLING_KEY", 'WaveRewards.Defs["Sharp"].Apply')
	expectDiagnostic(catalogs, "DANGLING_KEY", "Kits.Defs")
end)

test("sound maps and enemy tells reject missing sounds", function()
	local catalogs = deepClone(realCatalogs())
	catalogs.SfxMap.ByEvent["wave start"] = "MissingSound"
	catalogs.Sounds.ForWeapon.Starter = "MissingSound"
	catalogs.EnemyTells.Defs.Walker.SoundKey = "MissingSound"
	expectDiagnostic(catalogs, "DANGLING_KEY", "SfxMap.ByEvent")
	expectDiagnostic(catalogs, "DANGLING_KEY", "Sounds.ForWeapon")
	expectDiagnostic(catalogs, "DANGLING_KEY", "EnemyTells.Defs")
end)

test("weapon crate products reject missing monetization keys", function()
	local catalogs = deepClone(realCatalogs())
	catalogs.Weapons.Crates.Basic.Product = "MissingProduct"
	expectDiagnostic(catalogs, "DANGLING_KEY", "Weapons.Crates")
end)

test("orphan weapon sounds, enemy tells, and models are dead entries", function()
	local catalogs = deepClone(realCatalogs())
	catalogs.Sounds.ForWeapon.MissingWeapon = "Hit"
	catalogs.EnemyTells.Defs.MissingEnemy = deepClone(catalogs.EnemyTells.Defs.Walker)
	catalogs.ModelAssets["weapons/MissingWeapon"] = 999999999
	expectDiagnostic(catalogs, "DEAD_ENTRY", "Sounds.ForWeapon")
	expectDiagnostic(catalogs, "DEAD_ENTRY", "EnemyTells.Defs")
	expectDiagnostic(catalogs, "DEAD_ENTRY", "ModelAssets")
end)

test("diagnostics have stable path ordering", function()
	local catalogs = deepClone(realCatalogs())
	catalogs.SfxMap.ByEvent.z = "MissingZ"
	catalogs.SfxMap.ByEvent.a = "MissingA"
	local diagnostics = ContentAudit.audit(catalogs)
	for index = 2, #diagnostics do
		assert(diagnostics[index - 1].Path <= diagnostics[index].Path, "paths are not sorted")
	end
end)
