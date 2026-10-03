--!strict
-- One contract for the soft-launch funnel. Event payloads and their text formatting can be
-- checked before a server hands them to AnalyticsService.

local RunService = if game ~= nil then game:GetService("RunService") else nil

export type FieldValue = number | string
export type Fields = { [string]: FieldValue }
export type Event = {
	name: string,
	fields: Fields,
}

local Telemetry = {}

Telemetry.Events = {
	RunStart = { "players", "weapon", "kit" },
	WaveReached = { "wave", "seconds" },
	CardPicked = { "wave", "card", "seconds" },
	RunEnd = { "result", "wave", "kills", "coins", "gems", "seconds" },
	QuitMidRun = { "wave", "seconds" },
	CrateOpened = { "crate", "rarity", "weapon", "result" },
	CodeRedeemed = { "code", "reward" },
	PurchasePrompted = { "kind", "item" },
	run_start = { "seconds" },
	first_hit = { "seconds" },
	first_kill = { "seconds" },
	first_levelup = { "seconds" },
	first_damage_taken = { "seconds" },
	evolve_in_run = { "recipe", "wave", "seconds" },
	death = { "wave", "seconds" },
} :: { [string]: { string } }

function Telemetry.formatFields(fields: Fields): string
	local names = {}
	for name in fields do
		table.insert(names, name)
	end
	table.sort(names)

	local parts = {}
	for _, name in names do
		table.insert(parts, name .. "=" .. tostring(fields[name]))
	end
	return table.concat(parts, " ")
end

function Telemetry.build(name: string, fields: Fields): Event
	local fieldList = Telemetry.Events[name]
	assert(fieldList ~= nil, "Unknown telemetry event: " .. name)

	local allowed = {}
	for _, fieldName in fieldList do
		allowed[fieldName] = true
	end

	local copied: Fields = {}
	for fieldName, value in fields do
		assert(allowed[fieldName] == true, "Unknown field for " .. name .. ": " .. fieldName)
		local valueType = type(value)
		assert(
			valueType == "number" or valueType == "string",
			"Telemetry fields must be numbers or strings: " .. fieldName
		)
		copied[fieldName] = if fieldName == "seconds" and valueType == "number"
			then math.round(value :: number)
			else value
	end

	local event = { name = name, fields = copied }
	if RunService ~= nil and RunService:IsStudio() then
		print("[funnel] " .. name, Telemetry.formatFields(copied))
	end
	return event
end

return Telemetry
