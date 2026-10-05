--!strict
local fs = require("@lune/fs")
local Config = load("Config")
local VisualRules = load("VisualRules")

test("contact effects derive their dimensions from VisualDiameter", function()
	eq(
		math.abs(VisualRules.contactShadowDiameter(10) - 7.2) < 1e-9,
		true,
		"shadow scales with visual diameter"
	)
	eq(VisualRules.contactShadowDiameter(1), 3.2, "shadow minimum")
	eq(VisualRules.contactShadowDiameter(100), 16, "shadow cap")
	eq(VisualRules.groundContactOffset(10), -4.1, "dust reaches pumpkin underside")
end)

test("responsive stats preserve the hero text minimum", function()
	eq(VisualRules.heroTextSize(true), 28, "mobile hero text")
	eq(VisualRules.heroTextSize(false), 28, "desktop hero text")
end)

test("pumpkin lights and map lamps have bounded mobile budgets", function()
	local lowBrightness, lowRange = VisualRules.cappedPumpkinLight(2.5)
	local highBrightness, highRange = VisualRules.cappedPumpkinLight(100)
	eq(lowBrightness >= 0.55, true, "small pumpkin brightness")
	eq(lowRange >= 7, true, "small pumpkin range")
	eq(highBrightness <= 1.2, true, "large pumpkin brightness cap")
	eq(highRange <= 16, true, "large pumpkin range cap")
	eq(VisualRules.MAX_ACTIVE_MAP_LIGHTS <= 12, true, "map light count")
	eq(VisualRules.MAP_LIGHT_RANGE <= 18, true, "map light range")
end)

test(
	"all fifteen configured pets are required and active assets reject scripts and remotes",
	function()
		eq(#VisualRules.petModelNames(Config.Eggs), 15, "required pet model count")
		for _, className in
			{ "Script", "LocalScript", "ModuleScript", "RemoteEvent", "RemoteFunction" }
		do
			eq(VisualRules.assetClassAllowed(className), false, className)
		end
		eq(VisualRules.assetClassAllowed("MeshPart"), true, "mesh parts allowed")
	end
)

test("Q4-D source contains the authored prop and egg kit", function()
	local source = fs.readFile("src/ServerScriptService/MapFallback.luau")
	for _, marker in
		{
			"JackOLantern",
			"Fence",
			"Gravestone",
			"CandyArch",
			"LampPost",
			"EggModel",
			"DominantLandmark",
			"FinishSetPiece",
		}
	do
		eq(source:find(marker, 1, true) ~= nil, true, marker)
	end
end)

test("Q4-C review fixes stay wired into the HUD runtime", function()
	local source = fs.readFile("src/StarterPlayer/StarterPlayerScripts/Hud.client.luau")
	eq(
		source:find('GetAttribute("VisualDiameter")', 1, true) ~= nil,
		true,
		"visual diameter attribute"
	)
	eq(
		source:find("VisualRules.heroTextSize(layout.mobile)", 1, true) ~= nil,
		true,
		"responsive hero minimum"
	)
	eq(source:find("position.Y - 2.8", 1, true), nil, "no interpolated guide height")
	eq(
		source:find("local floorHit = workspace:Raycast", 1, true) ~= nil,
		true,
		"guide floor raycast"
	)
	eq(
		source:find("VisualRules.groundContactOffset(visualDiameter)", 1, true) ~= nil,
		true,
		"refreshed dust offset"
	)
end)
