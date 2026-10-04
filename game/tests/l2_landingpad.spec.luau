local fs = require("@lune/fs")
local serde = require("@lune/serde")

local ArenaLayout = load("ArenaLayout")
local LightingPresets = load("LightingPresets")

local source = fs.readFile("assets/art/LandingPad.json")
local shippedSource = fs.readFile("src/ReplicatedStorage/Shared/Art/LandingPad.json")
local manifest = serde.decode("json", source)
local shippedManifest = serde.decode("json", shippedSource)

local function distanceToSegment(px, pz, ax, az, bx, bz)
	local dx, dz = bx - ax, bz - az
	local lengthSquared = dx * dx + dz * dz
	local t = math.clamp(((px - ax) * dx + (pz - az) * dz) / lengthSquared, 0, 1)
	local x, z = ax + dx * t, az + dz * t
	return math.sqrt((px - x) ^ 2 + (pz - z) ^ 2)
end

test("Landing Pad manifests parse and every mesh has an asset id", function()
	eq(#manifest.Parts, #shippedManifest.Parts, "shipped part count")
	assert(#manifest.Parts > 0, "manifest is empty")
	assert(#manifest.Parts <= 1500, "Landing Pad exceeds the part budget")
	for index, definition in manifest.Parts do
		if definition.ClassName == "MeshPart" then
			assert(
				type(definition.MeshId) == "string" and definition.MeshId:match("%d+$"),
				"MeshPart " .. index .. " has no MeshId"
			)
		end
	end
end)

test("Landing Pad combat lanes and core are clear of collidable obstacles", function()
	local lanes = {
		{ -40, -72, 0, 0 },
		{ -40, 72, 0, 0 },
		{ -72, 0, 0, 0 },
	}
	for index, definition in manifest.Parts do
		if definition.CanCollide and definition.Kind ~= "Floor" then
			local x, z = definition.CFrame[1], definition.CFrame[3]
			assert(x * x + z * z >= 20 ^ 2, "collidable part " .. index .. " blocks the core")
			for _, lane in lanes do
				assert(
					distanceToSegment(x, z, lane[1], lane[2], lane[3], lane[4]) >= 6,
					"collidable part " .. index .. " blocks a gate lane"
				)
			end
		end
	end
end)

test("Landing Pad keeps invisible primitive floor collision as a safety net", function()
	local builder = fs.readFile("src/ServerScriptService/ArenaBuilder.server.luau")
	assert(builder:find('zone.Id ~= "LandingPad"', 1, true), "Landing Pad needs zone handling")
	assert(builder:find("floor.Transparency = 1", 1, true), "safety floor must be invisible")
	assert(builder:find("floor.CanCollide = true", 1, true), "safety floor must collide")
	local landingPad = ArenaLayout.Zones[1]
	local safety = serde.decode("json", fs.readFile("src/Workspace/Arena/Floor.model.json"))
	local size = safety.properties.Size
	local position = safety.properties.CFrame.CFrame.position
	for index, rect in ArenaLayout.floorRects(landingPad) do
		assert(position[1] - size[1] / 2 <= rect.ax, "safety floor misses rect " .. index)
		assert(position[1] + size[1] / 2 >= rect.bx, "safety floor misses rect " .. index)
		assert(position[3] - size[3] / 2 <= rect.az, "safety floor misses rect " .. index)
		assert(position[3] + size[3] / 2 >= rect.bz, "safety floor misses rect " .. index)
	end
end)

test("ArtLoader uses mesh options and tolerates failed assets", function()
	local loader = fs.readFile("src/ServerStorage/ArtLoader.luau")
	local start = assert(loader:find("CreateMeshPartAsync", 1, true), "mesh API call missing")
	local call = loader:sub(start, (loader:find("})", start, true)) or #loader)
	assert(call:find("CollisionFidelity%s*="), "CollisionFidelity must be an options key")
	assert(call:find("RenderFidelity%s*="), "RenderFidelity must be an options key")
	assert(loader:find("pcall", 1, true), "mesh loads must be protected")
	assert(loader:find("task.wait", 1, true), "large manifests must yield")
end)

test("Landing Pad mood is shipped as a capped lighting preset", function()
	local mood = serde.decode("json", fs.readFile("assets/art/LandingPadMood.json"))
	local preset = LightingPresets.LandingPad
	assert(preset ~= nil, "LandingPad preset is missing")
	assert(preset.Bloom.Intensity <= 0.5, "LandingPad bloom is too intense")
	assert(preset.Bloom.Threshold >= 1.5, "LandingPad bloom threshold is too low")
	assert(math.abs(preset.Lighting.ClockTime - mood.ClockTime) < 0.000001, "ClockTime differs")
	assert(
		fs.readFile("src/StarterPlayer/StarterPlayerScripts/ZoneLighting.client.luau")
			:find('zone.Id == "LandingPad"', 1, true),
		"LandingPad mood is not zone-aware"
	)
end)
