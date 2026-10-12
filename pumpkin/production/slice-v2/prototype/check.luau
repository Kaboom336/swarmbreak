local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Config = require("./GreyboxConfig")
local Layout = require("./Layout")
for _, name in fs.readDir(".") do
	if string.sub(name, -5) == ".luau" then
		for level = 0, 2 do
			luau.compile(fs.readFile(name), { optimizationLevel = level, debugLevel = 2 })
		end
		print("COMPILE PASS " .. name .. " O0/O1/O2 debug2")
	end
end
Layout.selfTest(Config, print)
local invalid = Layout.assemble(Config, 101, false)
invalid.pieces[2].inZ += 1
assert(not pcall(Layout.validate, Config, invalid), "broken snap must be rejected")
invalid = Layout.assemble(Config, 101, false)
invalid.route = 113
assert(not pcall(Layout.validate, Config, invalid), "overlong route must be rejected")
local first = Layout.assemble(Config, 101, true)
assert(first.route == 108 and #first.pieces == 4, "first-run recipe")
print("PASS invalid snap/route rejection and fixed first run")

if fs.isFile("guardian-greybox.rbxl") then
	local roblox = require("@lune/roblox")
	local place = roblox.deserializePlace(fs.readFile("guardian-greybox.rbxl"))
	local mappings = {
		{ "ServerScriptService", "Greybox", "Greybox.server.luau" },
		{ "ReplicatedStorage", "GreyboxConfig", "GreyboxConfig.luau" },
		{ "ReplicatedStorage", "GreyboxLayout", "Layout.luau" },
	}
	for _, map in mappings do
		local node = place:FindFirstChild(map[1]):FindFirstChild(map[2])
		assert(node and node.Source == fs.readFile(map[3]), "built source mismatch: " .. map[3])
	end
	local client =
		place:FindFirstChild("StarterPlayer"):FindFirstChild("StarterPlayerScripts"):FindFirstChild("Greybox")
	assert(client.Source == fs.readFile("Greybox.client.luau"), "client mapping")
	assert(place:FindFirstChild("ServerScriptService"):GetAttribute("GreyboxSeed") == 0, "hidden seed attribute")
	print("PASS built binary contains matching server/client/config/layout source and seed attribute")
end
