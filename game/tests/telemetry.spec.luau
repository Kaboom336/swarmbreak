local Telemetry = load("Telemetry")
local Sounds = load("Sounds")

test("sound ids use approved formats", function()
	local allowed = {
		["rbxasset://sounds/electronicpingshort.wav"] = true,
		["rbxasset://sounds/Rocket shot.wav"] = true,
		["rbxasset://sounds/Shoulder fired rocket.wav"] = true,
		["rbxasset://sounds/flashbulb.wav"] = true,
		["rbxasset://sounds/Launching rocket.wav"] = true,
		["rbxasset://sounds/impact_explosion_02.mp3"] = true,
		["rbxasset://sounds/hit.wav"] = true,
		["rbxasset://sounds/splat.wav"] = true,
		["rbxasset://sounds/uuhhh.mp3"] = true,
		["rbxasset://sounds/action_jump.mp3"] = true,
		["rbxasset://sounds/switch.wav"] = true,
		["rbxasset://sounds/button.wav"] = true,
		["rbxasset://sounds/collide.wav"] = true,
		["rbxasset://sounds/snap.wav"] = true,
		["rbxasset://sounds/bass.wav"] = true,
		["rbxasset://sounds/victory.wav"] = true,
		["rbxasset://sounds/HalloweenGhost.wav"] = true,
		["rbxasset://sounds/HalloweenLightning.wav"] = true,
		["rbxasset://sounds/impact_water.mp3"] = true,
		["rbxasset://sounds/impact_explosion_01.mp3"] = true,
		[""] = true,
	}

	for name, sound in Sounds do
		if type(sound) == "table" and sound.Id ~= nil then
			assert(sound.Id ~= "rbxasset://sounds/swoosh.wav", name .. " uses unapproved swoosh")
			assert(
				sound.Id:match("^rbxassetid://%d+$") ~= nil or allowed[sound.Id] == true,
				name .. " has an unapproved sound id: " .. sound.Id
			)
		end
	end
end)

test("telemetry field formatting is stable", function()
	local fields = { weapon = "Starter", players = 2, kit = "Scout" }
	eq(Telemetry.formatFields(fields), "kit=Scout players=2 weapon=Starter", "sorted fields")
	eq(Telemetry.formatFields(fields), "kit=Scout players=2 weapon=Starter", "repeat formatting")
	eq(Telemetry.formatFields({}), "", "empty fields")
end)

test("every telemetry event has a field list", function()
	local expected = {
		"RunStart",
		"WaveReached",
		"CardPicked",
		"RunEnd",
		"QuitMidRun",
		"CrateOpened",
		"CodeRedeemed",
		"PurchasePrompted",
	}
	for _, name in expected do
		local fields = Telemetry.Events[name]
		assert(type(fields) == "table", name .. " has no field list")
		assert(#fields > 0, name .. " has an empty field list")
	end
end)

test("unknown events are rejected", function()
	local ok = pcall(function()
		Telemetry.build("MadeUpEvent", {})
	end)
	eq(ok, false, "unknown event")
end)

test("extra fields are rejected", function()
	local ok = pcall(function()
		Telemetry.build("WaveReached", { wave = 4, surprise = "no" })
	end)
	eq(ok, false, "extra field")
end)

test("field values must be numbers or strings", function()
	local ok = pcall(function()
		Telemetry.build("WaveReached", { wave = true })
	end)
	eq(ok, false, "boolean field")
end)

test("seconds are rounded to whole numbers", function()
	local event = Telemetry.build("WaveReached", { wave = 3, seconds = 12.6 })
	eq(event.fields.seconds, 13, "rounded seconds")
end)

test("build output does not alias its input", function()
	local fields = { wave = 5, seconds = 8.2 }
	local event = Telemetry.build("WaveReached", fields)
	fields.wave = 99
	eq(event.name, "WaveReached", "event name")
	eq(event.fields.wave, 5, "copied field")
	assert(event.fields ~= fields, "fields table was reused")
end)
