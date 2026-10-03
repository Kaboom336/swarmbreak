--!strict
-- Pure cross-catalog validation. This module deliberately uses no Roblox APIs so it can run
-- in the game, in Lune tests, and from the offline content_audit tool.

export type Diagnostic = {
	Code: string,
	Path: string,
	Message: string,
}

export type Catalogs = {
	Weapons: any,
	Evolutions: any,
	Enemies: any,
	WaveRewards: any,
	Kits: any,
	Quests: any,
	SfxMap: any,
	Sounds: any,
	ModelAssets: any,
	Monetization: any,
	EnemyTells: any,
	VfxDefs: any,
}

local ContentAudit = {}

local function add(out: { Diagnostic }, code: string, path: string, message: string)
	table.insert(out, { Code = code, Path = path, Message = message })
end

local function sortedKeys(values: { [any]: any }): { any }
	local keys = {}
	for key in values do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return keys
end

local function setOf(values: { any }): { [any]: boolean }
	local out = {}
	for _, value in values do
		out[value] = true
	end
	return out
end

-- Validate the common Defs + Order catalog shape. Exposed for focused unit tests and for
-- future catalogs; it does not mutate either input.
function ContentAudit.validateOrderedCatalog(
	catalogName: string,
	defs: { [string]: any },
	order: { string },
	idField: string?,
	defsField: string?
): { Diagnostic }
	local out: { Diagnostic } = {}
	local defsPath = catalogName .. "." .. (defsField or "Defs")
	local ordered = {}
	for index, key in order do
		local path = string.format("%s.Order[%d]", catalogName, index)
		if ordered[key] then
			add(out, "DUPLICATE_ORDER_KEY", path, string.format("%q appears more than once", key))
		else
			ordered[key] = true
		end
		if defs[key] == nil then
			add(out, "DANGLING_KEY", path, string.format("%q has no %s entry", key, defsPath))
		end
	end

	local ids = {}
	for _, key in sortedKeys(defs) do
		local def = defs[key]
		if not ordered[key] then
			add(
				out,
				"DEAD_ENTRY",
				string.format("%s[%q]", defsPath, key),
				"definition is not present in Order"
			)
		end
		if idField then
			local id = def[idField]
			if id ~= key then
				add(
					out,
					"ID_KEY_MISMATCH",
					string.format("%s[%q].%s", defsPath, key, idField),
					string.format("expected %q, got %q", key, tostring(id))
				)
			end
			if id ~= nil then
				if ids[id] then
					add(
						out,
						"DUPLICATE_ID",
						string.format("%s[%q].%s", defsPath, key, idField),
						string.format(
							"%q is already used by %s[%q]",
							tostring(id),
							defsPath,
							ids[id]
						)
					)
				else
					ids[id] = key
				end
			end
		end
	end
	return out
end

local function append(out: { Diagnostic }, more: { Diagnostic })
	for _, diagnostic in more do
		table.insert(out, diagnostic)
	end
end

local function validateUniqueOrder(out: { Diagnostic }, path: string, order: { string })
	local seen = {}
	for index, key in order do
		if seen[key] then
			add(
				out,
				"DUPLICATE_ORDER_KEY",
				string.format("%s[%d]", path, index),
				string.format("%q appears more than once", key)
			)
		else
			seen[key] = true
		end
	end
end

local function reference(
	out: { Diagnostic },
	targets: { [any]: any },
	value: any,
	path: string,
	targetName: string
)
	if targets[value] == nil then
		add(
			out,
			"DANGLING_KEY",
			path,
			string.format("%q does not exist in %s", tostring(value), targetName)
		)
	end
end

local function requireMapping(
	out: { Diagnostic },
	sources: { [string]: any },
	mapping: { [string]: any },
	path: string
)
	for _, key in sortedKeys(sources) do
		if mapping[key] == nil then
			add(
				out,
				"MISSING_ENTRY",
				string.format("%s[%q]", path, key),
				"required entry is missing"
			)
		end
	end
end

local function validateNumericIds(
	out: { Diagnostic },
	values: { [string]: any },
	path: string,
	field: string?
)
	local seen = {}
	for _, key in sortedKeys(values) do
		local value = if field then values[key][field] else values[key]
		-- Monetization intentionally uses 0 as an unpublished placeholder.
		if type(value) == "number" and value > 0 then
			if seen[value] then
				add(
					out,
					"DUPLICATE_NUMERIC_ID",
					string.format("%s[%q]%s", path, key, if field then "." .. field else ""),
					string.format("%d is already used by %s[%q]", value, path, seen[value])
				)
			else
				seen[value] = key
			end
		end
	end
end

function ContentAudit.audit(catalogs: Catalogs): { Diagnostic }
	local out: { Diagnostic } = {}
	local weapons = catalogs.Weapons
	local evolutions = catalogs.Evolutions
	local enemies = catalogs.Enemies
	local rewards = catalogs.WaveRewards
	local kits = catalogs.Kits
	local quests = catalogs.Quests
	local sounds = catalogs.Sounds
	local models = catalogs.ModelAssets
	local monetization = catalogs.Monetization
	local tells = catalogs.EnemyTells
	local vfx = catalogs.VfxDefs

	append(
		out,
		ContentAudit.validateOrderedCatalog(
			"Evolutions",
			evolutions.Elements,
			evolutions.Order,
			"Name"
		)
	)
	append(
		out,
		ContentAudit.validateOrderedCatalog("WaveRewards", rewards.Defs, rewards.Order, "Id")
	)
	append(out, ContentAudit.validateOrderedCatalog("Kits", kits.Defs, kits.Order, "Id"))
	append(out, ContentAudit.validateOrderedCatalog("Quests", quests.Defs, quests.Order, "Id"))
	append(
		out,
		ContentAudit.validateOrderedCatalog(
			"VfxDefs",
			vfx.Definitions,
			vfx.Order,
			nil,
			"Definitions"
		)
	)
	validateUniqueOrder(out, "Weapons.KindOrder", weapons.KindOrder)
	validateUniqueOrder(out, "Weapons.RarityOrder", weapons.RarityOrder)
	validateUniqueOrder(out, "Weapons.CrateOrder", weapons.CrateOrder)

	-- Weapons has no presentation order, so validate its embedded ids separately.
	local weaponIds = {}
	local usedKinds = {}
	local usedRarities = {}
	for _, key in sortedKeys(weapons.Defs) do
		local weapon = weapons.Defs[key]
		local id = weapon.Id
		if id ~= key then
			add(
				out,
				"ID_KEY_MISMATCH",
				string.format("Weapons.Defs[%q].Id", key),
				string.format("expected %q, got %q", key, tostring(id))
			)
		end
		if weaponIds[id] then
			add(
				out,
				"DUPLICATE_ID",
				string.format("Weapons.Defs[%q].Id", key),
				string.format("%q is already used by Weapons.Defs[%q]", tostring(id), weaponIds[id])
			)
		else
			weaponIds[id] = key
		end
		reference(
			out,
			setOf(weapons.KindOrder),
			weapon.Kind,
			string.format("Weapons.Defs[%q].Kind", key),
			"Weapons.KindOrder"
		)
		reference(
			out,
			setOf(weapons.RarityOrder),
			weapon.Rarity,
			string.format("Weapons.Defs[%q].Rarity", key),
			"Weapons.RarityOrder"
		)
		usedKinds[weapon.Kind] = true
		usedRarities[weapon.Rarity] = true
	end
	for index, kind in weapons.KindOrder do
		if not usedKinds[kind] then
			add(
				out,
				"DEAD_ENTRY",
				string.format("Weapons.KindOrder[%d]", index),
				"kind is used by no weapon"
			)
		end
	end
	for index, rarity in weapons.RarityOrder do
		if not usedRarities[rarity] then
			add(
				out,
				"DEAD_ENTRY",
				string.format("Weapons.RarityOrder[%d]", index),
				"rarity is used by no weapon"
			)
		end
	end
	local orderedCrates = setOf(weapons.CrateOrder)
	for index, crateName in weapons.CrateOrder do
		if weapons.Crates[crateName] == nil then
			add(
				out,
				"DANGLING_KEY",
				string.format("Weapons.CrateOrder[%d]", index),
				string.format("%q has no Weapons.Crates entry", crateName)
			)
		end
	end
	for _, crateName in sortedKeys(weapons.Crates) do
		if not orderedCrates[crateName] then
			add(
				out,
				"DEAD_ENTRY",
				string.format("Weapons.Crates[%q]", crateName),
				"crate is not present in CrateOrder"
			)
		end
		for rarity in weapons.Crates[crateName].Odds do
			reference(
				out,
				setOf(weapons.RarityOrder),
				rarity,
				string.format("Weapons.Crates[%q].Odds[%q]", crateName, rarity),
				"Weapons.RarityOrder"
			)
		end
	end
	for rarity in weapons.DuplicateGems do
		reference(
			out,
			setOf(weapons.RarityOrder),
			rarity,
			string.format("Weapons.DuplicateGems[%q]", rarity),
			"Weapons.RarityOrder"
		)
	end

	local weaponKinds = setOf(weapons.KindOrder)
	local usedEffects = {}
	for _, elementName in sortedKeys(evolutions.Elements) do
		for tierIndex, tier in evolutions.Elements[elementName].Tiers do
			if tier.Effect ~= nil then
				usedEffects[tier.Effect] = true
				reference(
					out,
					evolutions.Effects,
					tier.Effect,
					string.format(
						"Evolutions.Elements[%q].Tiers[%d].Effect",
						elementName,
						tierIndex
					),
					"Evolutions.Effects"
				)
			end
		end
	end
	for _, effect in sortedKeys(evolutions.Effects) do
		if not usedEffects[effect] then
			add(
				out,
				"DEAD_ENTRY",
				string.format("Evolutions.Effects[%q]", effect),
				"effect is used by no evolution tier"
			)
		end
	end
	for _, boss in sortedKeys(evolutions.BossShards) do
		local enemy = enemies.Defs[boss]
		if enemy == nil or enemy.Boss ~= true then
			add(
				out,
				"DANGLING_KEY",
				string.format("Evolutions.BossShards[%q]", boss),
				"key must name a boss in Enemies.Defs"
			)
		end
		reference(
			out,
			evolutions.Elements,
			evolutions.BossShards[boss],
			string.format("Evolutions.BossShards[%q]", boss),
			"Evolutions.Elements"
		)
	end
	for _, enemyName in sortedKeys(enemies.Defs) do
		local enemy = enemies.Defs[enemyName]
		if enemy.Boss == true and evolutions.BossShards[enemyName] == nil then
			add(
				out,
				"MISSING_ENTRY",
				string.format("Evolutions.BossShards[%q]", enemyName),
				"boss has no shard reward"
			)
		end
		if enemy.Summons ~= nil then
			reference(
				out,
				enemies.Defs,
				enemy.Summons,
				string.format("Enemies.Defs[%q].Summons", enemyName),
				"Enemies.Defs"
			)
		end
	end

	local rewardFields = setOf(rewards.Fields)
	rewardFields.HealNow = true
	for _, id in sortedKeys(rewards.Defs) do
		local def = rewards.Defs[id]
		for index, kind in def.Kinds or {} do
			reference(
				out,
				weaponKinds,
				kind,
				string.format("WaveRewards.Defs[%q].Kinds[%d]", id, index),
				"Weapons.KindOrder"
			)
		end
		for field in def.Apply do
			reference(
				out,
				rewardFields,
				field,
				string.format("WaveRewards.Defs[%q].Apply[%q]", id, field),
				"WaveRewards.Fields"
			)
		end
	end
	for _, id in sortedKeys(kits.Defs) do
		for kind in kits.Defs[id].Mods.DamageMultByKind do
			reference(
				out,
				weaponKinds,
				kind,
				string.format("Kits.Defs[%q].Mods.DamageMultByKind[%q]", id, kind),
				"Weapons.KindOrder"
			)
		end
	end

	for _, crateName in sortedKeys(weapons.Crates) do
		local product = weapons.Crates[crateName].Product
		if product ~= nil then
			reference(
				out,
				monetization.DeveloperProducts,
				product,
				string.format("Weapons.Crates[%q].Product", crateName),
				"Monetization.DeveloperProducts"
			)
		end
	end
	for _, eventName in sortedKeys(catalogs.SfxMap.ByEvent) do
		reference(
			out,
			sounds,
			catalogs.SfxMap.ByEvent[eventName],
			string.format("SfxMap.ByEvent[%q]", eventName),
			"Sounds"
		)
	end
	for _, weaponName in sortedKeys(sounds.ForWeapon) do
		if weapons.Defs[weaponName] == nil then
			add(
				out,
				"DEAD_ENTRY",
				string.format("Sounds.ForWeapon[%q]", weaponName),
				"mapping names no weapon in Weapons.Defs"
			)
		end
		reference(
			out,
			sounds,
			sounds.ForWeapon[weaponName],
			string.format("Sounds.ForWeapon[%q]", weaponName),
			"Sounds"
		)
	end
	requireMapping(out, weapons.Defs, sounds.ForWeapon, "Sounds.ForWeapon")

	for _, enemyName in sortedKeys(tells.Defs) do
		if enemies.Defs[enemyName] == nil then
			add(
				out,
				"DEAD_ENTRY",
				string.format("EnemyTells.Defs[%q]", enemyName),
				"tell names no enemy in Enemies.Defs"
			)
		end
		reference(
			out,
			sounds,
			tells.Defs[enemyName].SoundKey,
			string.format("EnemyTells.Defs[%q].SoundKey", enemyName),
			"Sounds"
		)
	end
	requireMapping(out, enemies.Defs, tells.Defs, "EnemyTells.Defs")

	for _, modelKey in sortedKeys(models) do
		local group, name = string.match(modelKey, "^([^/]+)/(.+)$")
		if group == "weapons" and weapons.Defs[name] == nil then
			add(
				out,
				"DEAD_ENTRY",
				string.format("ModelAssets[%q]", modelKey),
				"model names no weapon in Weapons.Defs"
			)
		elseif group == "enemies" and enemies.Defs[name] == nil then
			add(
				out,
				"DEAD_ENTRY",
				string.format("ModelAssets[%q]", modelKey),
				"model names no enemy in Enemies.Defs"
			)
		end
	end
	local weaponModels = {}
	local enemyModels = {}
	for key in models do
		local group, name = string.match(key, "^([^/]+)/(.+)$")
		if group == "weapons" then
			weaponModels[name] = true
		elseif group == "enemies" then
			enemyModels[name] = true
		end
	end
	requireMapping(out, weapons.Defs, weaponModels, "ModelAssets.weapons")
	requireMapping(out, enemies.Defs, enemyModels, "ModelAssets.enemies")
	validateNumericIds(out, models, "ModelAssets", nil)
	validateNumericIds(out, monetization.GamePasses, "Monetization.GamePasses", "Id")
	validateNumericIds(out, monetization.DeveloperProducts, "Monetization.DeveloperProducts", "Id")

	table.sort(out, function(a, b)
		if a.Path ~= b.Path then
			return a.Path < b.Path
		elseif a.Code ~= b.Code then
			return a.Code < b.Code
		end
		return a.Message < b.Message
	end)
	return out
end

function ContentAudit.format(diagnostic: Diagnostic): string
	return string.format("[%s] %s: %s", diagnostic.Code, diagnostic.Path, diagnostic.Message)
end

return ContentAudit
