--!strict
-- Run from game/: lune run ../tools/combat_soak.luau [seed ...]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local modulePath = if fs.isDir("src")
	then "src/ReplicatedStorage/Shared/CombatSoak.luau"
	else "game/src/ReplicatedStorage/Shared/CombatSoak.luau"
local CombatSoak = luau.load(fs.readFile(modulePath), { debugName = modulePath })()

local seeds = {}
for _, value in process.args do
	local seed = tonumber(value)
	if seed then
		table.insert(seeds, seed)
	end
end
if #seeds == 0 then
	seeds = CombatSoak.DEFAULT_SEEDS
end

local failed = false
for _, seed in seeds do
	local result = CombatSoak.run({
		seed = seed,
		durationSeconds = CombatSoak.DEFAULT_DURATION_SECONDS,
	})
	print(CombatSoak.formatSummary(result))
	failed = failed or not result.ok
end

if failed then
	process.exit(1)
end
