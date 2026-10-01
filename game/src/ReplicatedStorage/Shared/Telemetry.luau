--!strict
-- One contract for the soft-launch funnel. This module stays pure so event payloads can be
-- checked before a server hands them to AnalyticsService.

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
} :: { [string]: { string } }

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

	return { name = name, fields = copied }
end

return Telemetry
