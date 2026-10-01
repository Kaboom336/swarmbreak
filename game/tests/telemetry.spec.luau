local Telemetry = load("Telemetry")

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
