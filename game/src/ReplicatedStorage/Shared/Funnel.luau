--!strict
-- Pure schema and per-run dedupe for the first-minute telemetry funnel.
local Telemetry = require(script.Parent.Telemetry)

export type EventName =
	"run_start"
	| "first_hit"
	| "first_kill"
	| "first_levelup"
	| "first_damage_taken"
	| "evolve_in_run"
	| "death"
export type Run = { [string]: boolean }

local Funnel = {}

Funnel.Events = {
	run_start = { "seconds" },
	first_hit = { "seconds" },
	first_kill = { "seconds" },
	first_levelup = { "seconds" },
	first_damage_taken = { "seconds" },
	evolve_in_run = { "recipe", "wave", "seconds" },
	death = { "wave", "seconds" },
} :: { [EventName]: { string } }

function Funnel.newRun(): Run
	return {}
end

function Funnel.build(name: EventName, fields: Telemetry.Fields): Telemetry.Event
	for _, fieldName in Funnel.Events[name] do
		assert(fields[fieldName] ~= nil, name .. " requires " .. fieldName)
	end
	local seconds = fields.seconds
	assert(type(seconds) == "number" and seconds >= 0, name .. " seconds must be non-negative")
	return Telemetry.build(name, fields)
end

function Funnel.once(run: Run, name: EventName, fields: Telemetry.Fields): Telemetry.Event?
	if run[name] then
		return nil
	end
	local event = Funnel.build(name, fields)
	run[name] = true
	return event
end

return Funnel
