local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Config = require("./GreyboxConfig")
local Layout = require("./Layout")
local LoopTest = require("./LoopTest")
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

-- Audit the actual walking route, including reversed segments, for all recipe variants.
-- Sample a 1.5-stud character clearance against the same authored cover bounds.
for seed = 1, 50 do
	local layout = Layout.assemble(Config, seed, false)
	local route = LoopTest.route(layout)
	local previous = { x = 0, z = -4 }
	local covers = {}
	for _, p in layout.pieces do
		if string.sub(p.id, 1, 3) == "P02" then
			table.insert(covers, { x = -8, z = p.z - 3, hx = 4, hz = 2 })
			table.insert(covers, { x = 8, z = p.z + 3, hx = 4, hz = 2 })
		elseif p.id == "P07" then
			for _, x in { -12, 12 } do
				table.insert(covers, { x = x, z = p.z - 4, hx = 4, hz = 4 })
			end
		end
	end
	for _, point in route do
		for n = 0, 100 do
			local x = previous.x + (point.x - previous.x) * n / 100
			local z = previous.z + (point.z - previous.z) * n / 100
			local floorFound = false
			for _, p in layout.pieces do
				if z >= p.inZ and z <= p.z + p.depth / 2 and math.abs(x) + 1.5 < p.width / 2 - 0.5 then
					floorFound = true
				end
			end
			assert(floorFound, "loop route leaves floor/rail clearance: " .. point.name)
			for _, cover in covers do
				assert(
					math.abs(x - cover.x) >= cover.hx + 1.5 or math.abs(z - cover.z) >= cover.hz + 1.5,
					"loop route intersects cover: " .. point.name
				)
			end
		end
		previous = point
	end
	local nest = layout.pieces[#layout.pieces]
	assert(math.abs(previous.z - (nest.z + 16)) == 4, "loop endpoint outside steal range")
end
print("PASS full-loop route floor/rail/cover clearance for 50 seeds (outbound and same reversed segments)")

if fs.isFile("guardian-greybox.rbxl") then
	local roblox = require("@lune/roblox")
	local place = roblox.deserializePlace(fs.readFile("guardian-greybox.rbxl"))
	local mappings = {
		{ "ServerScriptService", "Greybox", "Greybox.server.luau" },
		{ "ServerScriptService", "GreyboxLoopTestRunner", "LoopTest.luau" },
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
	assert(place:FindFirstChild("ServerScriptService"):GetAttribute("GreyboxLoopTest") == false, "manual Play trigger")
	assert(
		place:FindFirstChild("ServerScriptService"):GetAttribute("GreyboxLoopTestSuccess") == false,
		"build must start locked"
	)
	assert(
		place:FindFirstChild("ServerScriptService"):GetAttribute("GreyboxLoopTestResult") == "NOT RUN",
		"do not ship a fabricated runtime PASS"
	)
	print(
		"PASS built binary contains matching server/client/config/layout/loop-test source; manual trigger and owner gate locked"
	)
end
