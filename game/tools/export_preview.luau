-- Runs the part builders under the shim and writes preview/data.json for the preview page.
-- Usage: lune run tools/export_preview.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local Shim = require("./roblox_shim")

local RS = Shim.service("ReplicatedStorage")
local SS = Shim.service("ServerStorage")
local shared = Shim.Instance.new("Folder")
shared.Name = "Shared"
shared.Parent = RS

-- Register every module file as a ModuleScript instance so `script.Parent.X` and
-- `ReplicatedStorage.Shared.X` resolve to something require() can load.
local modulePaths = {}
local function register(dir, parent)
	for _, f in fs.readDir(dir) do
		if f:match("%.luau$") and not f:match("%.server%.luau$") and not f:match("%.client%.luau$") then
			local name = f:gsub("%.luau$", "")
			local m = Shim.Instance.new("ModuleScript")
			m.Name = name
			m.Parent = parent
			modulePaths[m] = dir .. "/" .. f
		end
	end
end
register("src/ReplicatedStorage/Shared", shared)
register("src/ServerStorage", SS)

local cache = {}
local function makeEnv(scriptInst)
	local env = table.clone(Shim.env)
	env.script = scriptInst
	env.require = function(target)
		if type(target) == "string" then
			return require(target)
		end
		if cache[target] ~= nil then
			return cache[target]
		end
		local path = modulePaths[target]
		assert(path, "cannot require " .. tostring(target))
		local fn = luau.load(fs.readFile(path), { debugName = path, environment = makeEnv(target) })
		local result = fn()
		cache[target] = result
		return result
	end
	return env
end
local function requireByName(parent, name)
	local inst = parent:FindFirstChild(name)
	return makeEnv(inst).require(inst)
end

local Enemies = requireByName(shared, "Enemies")
local Weapons = requireByName(shared, "Weapons")
local Theme = requireByName(shared, "Theme")
local Evolutions = requireByName(shared, "Evolutions")
local Config = requireByName(shared, "Config")
local Monetization = requireByName(shared, "Monetization")
local EnemyBuilder = requireByName(SS, "EnemyBuilder")
local WeaponModels = requireByName(SS, "WeaponModels")

local V3, CF = Shim.Vector3, Shim.CFrame
local out = { enemies = {}, weapons = {}, arena = {}, data = {} }

-- enemies
for _, typeName in { "Walker", "Runner", "Flyer", "Tank", "Spitter", "Brute", "Queen", "Warden" } do
	local def = Enemies.Defs[typeName]
	local rig = EnemyBuilder.build(typeName, V3.new(def.Size[1], def.Size[2], def.Size[3]), CF.new(0, 0, 0))
	local parts = Shim.exportParts(rig.Model)
	-- drop the invisible root so silhouettes read
	local visible = {}
	for _, p in parts do
		if p.name ~= "HumanoidRootPart" then
			table.insert(visible, p)
		end
	end
	table.insert(out.enemies, {
		id = typeName,
		name = def.Name,
		boss = def.Boss == true,
		flying = def.Flying,
		ranged = def.Ranged == true,
		health = def.Health,
		speed = def.Speed,
		damage = def.Damage,
		coins = def.Coins,
		hip = rig.HipHeight,
		parts = visible,
	})
	print(string.format("enemy %-8s %3d parts, hip %.2f", typeName, #visible, rig.HipHeight))
end

-- weapons
local ids = {}
for id in Weapons.Defs do
	table.insert(ids, id)
end
table.sort(ids, function(a, b)
	local ra = table.find(Weapons.RarityOrder, Weapons.Defs[a].Rarity)
	local rb = table.find(Weapons.RarityOrder, Weapons.Defs[b].Rarity)
	if ra ~= rb then
		return ra < rb
	end
	return a < b
end)
for _, id in ids do
	local def = Weapons.Defs[id]
	local model = WeaponModels.build(id)
	local parts = Shim.exportParts(model)
	table.insert(out.weapons, {
		id = id,
		name = def.Name,
		rarity = def.Rarity,
		kind = def.Kind,
		damage = def.Damage,
		fireRate = def.FireRate,
		range = def.Range,
		pellets = def.Pellets,
		description = def.Description,
		power = Weapons.power(def),
		parts = parts,
	})
	print(string.format("weapon %-9s %2d parts", id, #parts))
end

-- arena: static JSON + ArenaBuilder decorations
local arena = Shim.Instance.new("Folder")
arena.Name = "Arena"
arena.Parent = Shim.env.workspace
local function fromJson(node, parent)
	local inst = Shim.Instance.new(node.className)
	local props = node.properties or {}
	for k, val in props do
		if k == "CFrame" then
			local p = val.position
			local o = val.orientation or { 0, 0, 0 }
			inst.CFrame = CF.new(p[1], p[2], p[3]) * CF.Angles(math.rad(o[1]), math.rad(o[2]), math.rad(o[3]))
		elseif k == "Size" then
			inst.Size = V3.new(val[1], val[2], val[3])
		elseif k == "Color" then
			inst.Color = Shim.env.Color3.new(val[1], val[2], val[3])
		else
			inst[k] = val
		end
	end
	inst.Parent = parent
	for _, child in node.children or {} do
		fromJson(child, inst)
	end
end
for _, f in fs.readDir("src/Workspace/Arena") do
	if f:match("%.model%.json$") then
		fromJson(serde.decode("json", fs.readFile("src/Workspace/Arena/" .. f)), arena)
	end
end
local enemiesFolder = Shim.Instance.new("Folder")
enemiesFolder.Name = "Enemies"
enemiesFolder.Parent = Shim.env.workspace
do
	local scriptInst = Shim.Instance.new("Script")
	scriptInst.Name = "ArenaBuilder"
	local src = fs.readFile("src/ServerScriptService/ArenaBuilder.server.luau")
	luau.load(src, { debugName = "ArenaBuilder", environment = makeEnv(scriptInst) })()
end
out.arena = Shim.exportParts(arena)
print(string.format("arena %d parts", #out.arena))

-- plain data for the cards
out.data = {
	config = { NormalWaves = Config.NormalWaves, BossEvery = Config.BossEvery, Intermission = Config.IntermissionSeconds },
	theme = Theme,
	rarityOdds = Weapons.RarityOdds,
	rarityColor = Weapons.RarityColor,
	elements = Evolutions.Elements,
	elementOrder = Evolutions.Order,
	effects = Evolutions.Effects,
	bossShards = Evolutions.BossShards,
	passes = Monetization.GamePasses,
	products = Monetization.DeveloperProducts,
	weightsByWave = (function()
		local t = {}
		for w = 1, 15 do
			t[w] = Enemies.weightsForWave(w)
		end
		return t
	end)(),
}

fs.writeFile("preview/data.json", serde.encode("json", out))
print("wrote preview/data.json")
