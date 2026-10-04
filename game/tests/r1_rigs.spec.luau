--!strict
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local EnemyAnimCurves = load("EnemyAnimCurves")
local EnemyFamilies = load("EnemyFamilies")

local roles = { "Mite", "Runner", "Shooter", "Tank", "Flyer" }

for _, role in roles do
	test(role .. " rig JSON satisfies the animation contract", function()
		local source = fs.readFile("assets/rigs/" .. role .. ".json")
		eq(
			fs.readFile("src/ReplicatedStorage/Shared/Rigs/" .. role .. ".json"),
			source,
			role .. " shipped JSON"
		)
		local data = serde.decode("json", source)
		local partCounts = {}
		for _, part in data.Parts do
			partCounts[part.Name] = (partCounts[part.Name] or 0) + 1
		end

		eq(data.PrimaryPart, "Body", role .. " primary part")
		eq(partCounts.Body, 1, role .. " Body")
		eq(partCounts.Head, 1, role .. " Head")
		eq(partCounts.Eye_Glow, 2, role .. " Eye_Glow count")

		local necks = 0
		local hips = 0
		for _, motor in data.Motor6Ds do
			if motor.Name == "Neck" and motor.Part0 == "Body" and motor.Part1 == "Head" then
				necks += 1
			end
			local index = motor.Name:match("^Hip_(%d+)$")
			if index then
				hips += 1
				eq(motor.Part0, "Body", role .. " " .. motor.Name .. " Part0")
				eq(motor.Part1, "Leg_" .. index, role .. " " .. motor.Name .. " Part1")
				eq(partCounts["Leg_" .. index], 1, role .. " matching Leg")
			end
		end
		eq(necks, 1, role .. " Neck")
		assert(hips >= 4, role .. " needs at least four hips")
	end)
end

test("Nest maps every combat role to its enemy and rig", function()
	local expected = {
		Swarmer = { Enemy = "Walker", Rig = "Mite" },
		Runner = { Enemy = "Runner", Rig = "Runner" },
		Shooter = { Enemy = "Spitter", Rig = "Shooter" },
		Tank = { Enemy = "Tank", Rig = "Tank" },
		Flyer = { Enemy = "Flyer", Rig = "Flyer" },
	}
	for role, mapping in expected do
		eq(EnemyFamilies.resolve("Nest", role), mapping.Enemy, role .. " enemy")
		eq(EnemyFamilies.resolveRig("Nest", role), mapping.Rig, role .. " rig")
	end
end)

test("numbered rig hips use odd-even antiphase", function()
	eq(EnemyAnimCurves.RigGaitPhase.Odd, 0, "odd hip phase")
	eq(EnemyAnimCurves.RigGaitPhase.Even, math.pi, "even hip phase")
	eq(EnemyAnimCurves.rigGaitPhase(1), EnemyAnimCurves.RigGaitPhase.Odd, "Hip_1")
	eq(EnemyAnimCurves.rigGaitPhase(2), EnemyAnimCurves.RigGaitPhase.Even, "Hip_2")
	assert(
		math.abs(EnemyAnimCurves.rigGaitPhase(2) - EnemyAnimCurves.rigGaitPhase(1)) == math.pi,
		"tripod phases must be pi radians apart"
	)
end)

test("CreateMeshPartAsync gets an options table, not Enum args", function()
	local source = fs.readFile("src/ServerStorage/EnemyRigBuilder.luau")
	local start = source:find("CreateMeshPartAsync", 1, true)
	assert(start, "rig builder must call CreateMeshPartAsync")
	local call = source:sub(start, (source:find("\n\t\t%)", start)) or #source)
	assert(call:find("CollisionFidelity%s*=") ~= nil, "CollisionFidelity must be an options key")
	assert(call:find("RenderFidelity%s*=") ~= nil, "RenderFidelity must be an options key")
	assert(
		call:find(",%s*Enum%.") == nil,
		"Enum values passed positionally fail with 'Unable to cast to Dictionary'"
	)
end)
