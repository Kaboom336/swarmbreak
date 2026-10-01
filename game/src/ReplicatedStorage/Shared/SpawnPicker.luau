--!strict
export type Position = {
	x: number,
	z: number,
}

local SpawnPicker = {
	ExcludeRadius = 30,
	ChargeSeconds = 2, -- placeholder
}

local function distanceSquared(a: Position, b: Position): number
	local x = a.x - b.x
	local z = a.z - b.z
	return x * x + z * z
end

local function minimumDistanceSquared(portal: Position, players: { Position }): number
	local minimum = math.huge
	for _, player in players do
		minimum = math.min(minimum, distanceSquared(portal, player))
	end
	return minimum
end

function SpawnPicker.pick(portals: { Position }, players: { Position }, roll01: number): number
	assert(#portals > 0, "SpawnPicker.pick requires at least one portal")

	local eligible = {}
	local minimumDistances = {}
	local excludeDistanceSquared = SpawnPicker.ExcludeRadius * SpawnPicker.ExcludeRadius

	for index, portal in portals do
		local minimum = minimumDistanceSquared(portal, players)
		minimumDistances[index] = minimum
		if minimum > excludeDistanceSquared then
			table.insert(eligible, index)
		end
	end

	if #eligible > 0 then
		local rolledIndex = math.floor(roll01 * #eligible) + 1
		rolledIndex = math.max(1, math.min(rolledIndex, #eligible))
		return eligible[rolledIndex]
	end

	local farthestIndex = 1
	for index = 2, #portals do
		if minimumDistances[index] > minimumDistances[farthestIndex] then
			farthestIndex = index
		end
	end
	return farthestIndex
end

return SpawnPicker
