local fs, luau, rb = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox")
for _, file in fs.readDir("prototype/core") do
	if file:sub(-5) == ".luau" then
		for level = 0, 2 do
			luau.compile(fs.readFile("prototype/core/" .. file), { optimizationLevel = level })
		end
	end
end
local config, domain, profiles, tests =
	require("./core/Config"),
	require("./core/Domain"),
	require("./core/Profiles"),
	require("./core/Tests")
local rules = require("../slice-v2/prototype/LootRules")
local loot = require("../slice-v2/prototype/GreyboxConfig")
print("PASS Luau syntax O0/O1/O2")
print(tests.run(config, domain, profiles, rules, loot, require("./core/Service")))
local old = rb.deserializePlace(fs.readFile("prototype/guardian-greybox.pre-core.rbxl"))
local new = rb.deserializePlace(fs.readFile("prototype/guardian-greybox.rbxl"))
local allowed = {
	["ReplicatedStorage.GreyboxLootRules"] = true,
	["ServerScriptService.Greybox"] = true,
	["StarterPlayer.StarterPlayerScripts.HomeArt"] = true,
}
local preserved = 0
local function compare(a, b, path)
	for _, child in a:GetChildren() do
		local p = path == "" and child.Name or path .. "." .. child.Name
		local actual = assert(b:FindFirstChild(child.Name), "missing " .. p)
		assert(actual.ClassName == child.ClassName, "class changed " .. p)
		if child:IsA("LuaSourceContainer") and not allowed[p] then
			assert(actual.Source == child.Source, "unrelated script changed " .. p)
			preserved += 1
		end
		compare(child, actual, p)
	end
end
compare(old, new, "")
assert(
	new.ReplicatedStorage.TreasureCore.Config.Source == fs.readFile("prototype/core/Config.luau")
)
assert(new.ServerScriptService:GetAttribute("CoreLoopTestResult") == "NOT RUN")
assert(
	fs.readFile("prototype/guardian-greybox.rbxl")
		== fs.readFile("slice-v2/prototype/guardian-greybox.rbxl")
)
print(
	"PASS preserved "
		.. preserved
		.. " unrelated scripts; unchanged existing test runners; main/canonical parity"
)
