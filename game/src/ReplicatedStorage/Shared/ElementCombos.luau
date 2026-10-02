--!strict
-- Pure co-op element status and combo data. Callers keep the last trigger time per enemy.

export type Element = "Nature" | "Tech" | "Lightning" | "Dark"
export type Color = { number }
export type StatusDefinition = {
	Name: string,
	Duration: number,
}
export type ComboDefinition = {
	Name: string,
	BonusDamageMultiplier: number,
	Radius: number,
	Color: Color,
	Cooldown: number,
}
export type PlayerId = string | number

local ElementCombos = {}

ElementCombos.Elements = { "Nature", "Tech", "Lightning", "Dark" } :: { Element }
ElementCombos.Cooldown = 1.5

ElementCombos.Statuses = {
	Nature = { Name = "Root", Duration = 4 },
	Tech = { Name = "Mark", Duration = 5 },
	Lightning = { Name = "Charge", Duration = 3 },
	Dark = { Name = "Curse", Duration = 4 },
} :: { [Element]: StatusDefinition }

local Combos: { [string]: ComboDefinition } = {
	["Nature+Tech"] = {
		Name = "Vine Circuit",
		BonusDamageMultiplier = 1.4,
		Radius = 10,
		Color = { 80, 235, 160 },
		Cooldown = ElementCombos.Cooldown,
	},
	["Nature+Lightning"] = {
		Name = "Chain Storm",
		BonusDamageMultiplier = 1.6,
		Radius = 14,
		Color = { 180, 240, 255 },
		Cooldown = ElementCombos.Cooldown,
	},
	["Nature+Dark"] = {
		Name = "Blight Bloom",
		BonusDamageMultiplier = 1.5,
		Radius = 11,
		Color = { 145, 90, 190 },
		Cooldown = ElementCombos.Cooldown,
	},
	["Tech+Lightning"] = {
		Name = "Power Surge",
		BonusDamageMultiplier = 1.7,
		Radius = 12,
		Color = { 85, 220, 255 },
		Cooldown = ElementCombos.Cooldown,
	},
	["Tech+Dark"] = {
		Name = "Void Burst",
		BonusDamageMultiplier = 1.8,
		Radius = 13,
		Color = { 175, 75, 235 },
		Cooldown = ElementCombos.Cooldown,
	},
	["Lightning+Dark"] = {
		Name = "Shadow Storm",
		BonusDamageMultiplier = 2,
		Radius = 15,
		Color = { 125, 115, 255 },
		Cooldown = ElementCombos.Cooldown,
	},
}

ElementCombos.Combos = Combos

local order: { [string]: number } = {}
for index, element in ElementCombos.Elements do
	order[element] = index
end

local function comboKey(first: string, second: string): string?
	local firstIndex = order[first]
	local secondIndex = order[second]
	if firstIndex == nil or secondIndex == nil or firstIndex == secondIndex then
		return nil
	end
	if firstIndex < secondIndex then
		return first .. "+" .. second
	end
	return second .. "+" .. first
end

function ElementCombos.resolve(
	carriedElement: string,
	hitElement: string,
	statusPlayer: PlayerId?,
	hitPlayer: PlayerId?
): ComboDefinition?
	if statusPlayer ~= nil and hitPlayer ~= nil and statusPlayer == hitPlayer then
		return nil
	end

	local key = comboKey(carriedElement, hitElement)
	if key == nil then
		return nil
	end
	return Combos[key]
end

function ElementCombos.canTrigger(now: number, last: number?, cooldown: number?): boolean
	if last == nil then
		return true
	end
	return now - last >= (cooldown or ElementCombos.Cooldown)
end

return ElementCombos
