--!strict
-- Run from game/: lune run ../tools/content_audit.luau
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local SHARED = "src/ReplicatedStorage/Shared/"
local cache: { [string]: any } = {}

local function loadShared(name: string): any
	if cache[name] ~= nil then
		return cache[name]
	end
	local parent = setmetatable({}, {
		__index = function(_, key: string): string
			return "MODULE:" .. key
		end,
	})
	local environment = setmetatable({
		script = { Parent = parent, Name = name },
		require = function(target: any): any
			if type(target) == "string" and string.sub(target, 1, 7) == "MODULE:" then
				return loadShared(string.sub(target, 8))
			end
			return require(target)
		end,
	}, { __index = _G })
	local chunk = luau.load(fs.readFile(SHARED .. name .. ".luau"), {
		debugName = name,
		environment = environment,
	})
	local result = chunk()
	cache[name] = result
	return result
end

local names = {
	"Weapons",
	"Evolutions",
	"Enemies",
	"WaveRewards",
	"Kits",
	"Quests",
	"SfxMap",
	"Sounds",
	"ModelAssets",
	"Monetization",
	"EnemyTells",
	"VfxDefs",
}
local catalogs = {}
for _, name in names do
	catalogs[name] = loadShared(name)
end

local ContentAudit = loadShared("ContentAudit")
local diagnostics = ContentAudit.audit(catalogs)
if #diagnostics == 0 then
	print(string.format("Content audit: OK (%d catalogs, no diagnostics)", #names))
	return
end

print(string.format("Content audit: FAILED (%d diagnostics)", #diagnostics))
for _, diagnostic in diagnostics do
	print("  " .. ContentAudit.format(diagnostic))
end
process.exit(1)
