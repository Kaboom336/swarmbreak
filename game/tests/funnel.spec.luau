local Funnel = load("Funnel")

local function fieldsFor(name: string)
	if name == "evolve_in_run" then
		return { recipe = "Railstorm", wave = 3, seconds = 42 }
	elseif name == "death" then
		return { wave = 3, seconds = 42 }
	end
	return { seconds = 42 }
end

test("every funnel event builds with its required fields", function()
	local expected = {
		"run_start",
		"first_hit",
		"first_kill",
		"first_levelup",
		"first_damage_taken",
		"evolve_in_run",
		"death",
	}
	for _, name in expected do
		local event = Funnel.build(name, fieldsFor(name))
		eq(event.name, name, name .. " event name")
		eq(event.fields.seconds, 42, name .. " seconds")
	end
end)

test("required fields cannot be omitted", function()
	for name, requiredFields in Funnel.Events do
		for _, missing in requiredFields do
			local fields = fieldsFor(name)
			fields[missing] = nil
			local ok = pcall(function()
				Funnel.build(name, fields)
			end)
			eq(ok, false, name .. " requires " .. missing)
		end
	end
end)

test("times must be non-negative", function()
	for name in Funnel.Events do
		local fields = fieldsFor(name)
		fields.seconds = -0.1
		local ok = pcall(function()
			Funnel.build(name, fields)
		end)
		eq(ok, false, name .. " negative seconds")
	end
end)

test("events fire once per run", function()
	local seen = Funnel.newRun()
	for name in Funnel.Events do
		local first = Funnel.once(seen, name, fieldsFor(name))
		assert(first ~= nil, name .. " did not fire first time")
		eq(Funnel.once(seen, name, fieldsFor(name)), nil, name .. " fired twice")
	end

	local nextRun = Funnel.newRun()
	assert(Funnel.once(nextRun, "first_hit", fieldsFor("first_hit")) ~= nil)
end)
