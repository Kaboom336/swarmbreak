local Fit = load("Fit")
local ModelKey = load("ModelKey")
local ModelParts = load("ModelParts")

test("model keys use group and name", function()
	eq(ModelKey.make("enemies", "Walker"), "enemies/Walker")
	eq(ModelKey.make("weapons", "Starter"), "weapons/Starter")
	eq(ModelKey.make("arena", "BossGate"), "arena/BossGate")
end)

test("only the Glow suffix marks neon parts", function()
	eq(ModelParts.isGlow("Eyes_Glow"), true)
	eq(ModelParts.isGlow("Glow_Eyes"), false)
	eq(ModelParts.isGlow("Afterglow"), false)
end)

test("fit scale preserves proportions inside the target", function()
	eq(Fit.scaleFor({ 10, 4, 2 }, { 5, 8, 4 }), 0.5)
	eq(Fit.scaleFor({ 2, 4, 8 }, { 4, 8, 16 }), 2)
	eq(Fit.scaleFor({ 0, 4, 8 }, { 4, 8, 16 }), 1)
end)

test("rig part names map to animation motors", function()
	local expected = {
		Head = "Neck",
		Jaw = "Jaw",
		Arm_L = "Shoulder_L",
		Arm_R = "Shoulder_R",
		Leg_L = "Hip_L",
		Leg_R = "Hip_R",
		Leg_1 = "Leg_1",
		Leg_6 = "Leg_6",
		Wing_1 = "Wing_1",
		Wing_4 = "Wing_4",
	}
	for partName, motorName in expected do
		eq(ModelParts.motorFor(partName), motorName, partName)
	end
	eq(ModelParts.motorFor("Eyes_Glow"), nil)
	eq(ModelParts.parentFor("Jaw"), "Head")
	eq(ModelParts.parentFor("Wing_2"), "Torso")
end)
