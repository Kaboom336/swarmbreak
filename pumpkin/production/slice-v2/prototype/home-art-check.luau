local fs, serde, luau = require("@lune/fs"), require("@lune/serde"), require("@lune/luau")
local roblox = require("@lune/roblox")
local assets = serde.decode("json", fs.readFile("../home-art/assets.json"))
local function same(a, b)
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in pairs(a) do
		if not same(v, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end
local data = luau.load(fs.readFile("HomeArtGeometry.luau"), {
	environment = {
		game = {
			GetService = function()
				return {
					JSONDecode = function(_, s)
						return serde.decode("json", s)
					end,
				}
			end,
		},
	},
})()
assert(same(data, assets), "mounted geometry differs from rendered geometry")
for key, file in pairs({
	Crow = "crow/blender/crow_parts.json",
	Acorn = "golden-acorn/blender/golden-acorn_parts.json",
	OpenAcorn = "golden-acorn/blender/golden-acorn-open_parts.json",
}) do
	assert(
		same(data[key], serde.decode("json", fs.readFile("../../models/" .. file))),
		"approved geometry changed " .. key
	)
end
for key, sections in pairs(data) do
	local triangles = 0
	for _, section in ipairs(sections) do
		for _, v in ipairs(section.vertices) do
			assert(#v == 3, "vertex dimension")
			for _, n in ipairs(v) do
				assert(n == n and math.abs(n) < 1000, "invalid vertex")
			end
		end
		for _, tri in ipairs(section.triangles) do
			assert(#tri == 3, "triangle dimension")
			for _, i in ipairs(tri) do
				assert(i % 1 == 0 and i >= 0 and i < #section.vertices, "invalid triangle index")
			end
			local a, b, c = table.unpack(tri)
			local V = roblox.Vector3
			assert(
				(V.new(table.unpack(section.vertices[b + 1])) - V.new(table.unpack(section.vertices[a + 1]))):Cross(
					V.new(table.unpack(section.vertices[c + 1])) - V.new(table.unpack(section.vertices[a + 1]))
				).Magnitude > 1e-9,
				"degenerate triangle"
			)
		end
		triangles += #section.triangles
	end
	print("PASS geometry " .. key .. " " .. triangles .. " triangles")
end
for _, key in ipairs({ "Pup", "Crow" }) do
	for _, s in ipairs(data[key]) do
		for _, v in ipairs(s.vertices) do
			assert(math.abs(v[1]) <= 2 and math.abs(v[3]) <= 2, "pet exceeds unchanged 4x4 footprint")
		end
	end
end
local old = roblox.deserializePlace(fs.readFile("guardian-greybox.pre-home-art.rbxl"))
local new = roblox.deserializePlace(fs.readFile("guardian-greybox.rbxl"))
-- Round 3 explicitly changes HOME floor adapters and the loop's HOME walk heights.
local allowed = { GreyboxScene = true, GreyboxPlacement = true, Greybox = true, GreyboxLoopTestRunner = true }
local checked = 0
for _, node in ipairs(old:GetDescendants()) do
	if node:IsA("LuaSourceContainer") and not allowed[node.Name] then
		local path = {}
		local current = node
		while current.Parent do
			table.insert(path, 1, current.Name)
			current = current.Parent
		end
		local target = new
		for _, name in ipairs(path) do
			target = assert(target:FindFirstChild(name), name)
		end
		local isHomeClient = node.Name == "Greybox" and node:IsA("LocalScript")
		if not isHomeClient then
			assert(target.Source == node.Source, "pre-art runtime source changed " .. node.Name)
		end
		checked += 1
	end
end
local oldScene = old.ReplicatedStorage.GreyboxScene.Source
local newScene = new.ReplicatedStorage.GreyboxScene.Source
oldScene = oldScene
	:gsub("Vector3.new%(64, 0.8, 0.8%)", "Vector3.new(64, 1.05, 1.05)")
	:gsub("Vector3.new%(1.4, 4.5, 1.4%)", "Vector3.new(2.2, 4.5, 2.2)")
oldScene = oldScene:gsub('("HomeReferenceCamera",.-)\n\t\t\t\t55,', "%1\n\t\t\t\t40,", 1)
local function withoutEnvironment(source)
	local start = assert(source:find("function Scene.environment(", 1, true))
	local finish = assert(source:find("function Scene.pollen(", start, true))
	return source:sub(1, start - 1) .. source:sub(finish)
end
assert(
	withoutEnvironment(oldScene) == withoutEnvironment(newScene),
	"Scene changed outside accepted HOME cosmetics/camera/environment"
)
assert(new.ReplicatedStorage.HomeArtGeometry.Source == fs.readFile("HomeArtGeometry.luau"), "geometry mount mismatch")
assert(
	new.StarterPlayer.StarterPlayerScripts.HomeArt.Source == fs.readFile("HomeArt.client.luau"),
	"client mount mismatch"
)
for _, file in ipairs({ "HomeArt.client.luau", "HomeArtGeometry.luau", "home-art-export.luau" }) do
	for level = 0, 2 do
		luau.compile(fs.readFile(file), { optimizationLevel = level })
	end
end
print(
	"PASS "
		.. checked
		.. " protected pre-art runtime sources byte-identical; HOME placement/preview/loop-height adapters excepted explicitly; mount parity; O0/O1/O2"
)
print("Studio visual/audio/multiplayer/performance and three live tests: NOT RUN")
