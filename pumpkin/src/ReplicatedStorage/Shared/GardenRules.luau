--!strict
local Rules = {
	SmallDiameter = 3.2,
	BigDiameter = 5.6,
	SmallSeconds = 8,
	BigSeconds = 28,
	UpgradeCost = 60,
	GhostGold = 5,
	GhostRespawn = 9,
	ShrineGoal = 30,
	ChainSeconds = 2.5,
	ChainDistance = 18,
}
function Rules.crop(age: number, rank: number): (number, boolean)
	local small = math.max(0.7, Rules.SmallDiameter * math.clamp(age / Rules.SmallSeconds, 0, 1))
	local extra = if rank >= 1
		then (Rules.BigDiameter - Rules.SmallDiameter) * math.clamp(
			(age - Rules.SmallSeconds) / (Rules.BigSeconds - Rules.SmallSeconds),
			0,
			1
		)
		else 0
	return small + extra, age >= Rules.SmallSeconds
end
function Rules.harvestDiameter(age: number, rank: number): number
	local diameter = Rules.crop(age, rank)
	return diameter
end
function Rules.charges(diameter: number): number
	return if diameter >= Rules.BigDiameter then 5 else 3
end
function Rules.movement(previous: any, current: any, dt: number, bounds: any): (boolean, number?)
	for _, value in { current.x, current.y, current.z, previous.x, previous.y, previous.z, dt } do
		if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
			return false
		end
	end
	if
		dt < 0
		or current.x < bounds.minX
		or current.x > bounds.maxX
		or current.z < bounds.minZ
		or current.z > bounds.maxZ
		or math.abs(current.y - bounds.floorY) > 35
	then
		return false
	end
	local distance = math.sqrt((current.x - previous.x) ^ 2 + (current.z - previous.z) ^ 2)
	if math.abs(current.y - previous.y) > 80 * math.min(dt, 0.5) + 3 then
		return false
	end
	local available = math.clamp(previous.budget or 2, 0, 2) + 28 * math.min(dt, 0.5)
	return distance <= available, math.clamp(available - distance, 0, 2)
end
function Rules.upgrade(profile: any): (boolean, string)
	if profile.PumpkinRank >= 1 then
		return false, "Big pumpkins unlocked! Leave a vine growing."
	end
	if profile.Gold < Rules.UpgradeCost then
		return false, "Free ghosts to earn 60 gold."
	end
	profile.Gold -= Rules.UpgradeCost
	profile.PumpkinRank = 1
	return true, "Big pumpkins unlocked! Wait for a vine to grow big."
end
function Rules.chain(first: any, second: any): boolean
	return first.owner ~= second.owner
		and not first.used
		and second.time >= first.time
		and second.time - first.time <= Rules.ChainSeconds
		and second.distance <= Rules.ChainDistance
end
function Rules.segmentDistance(
	px: number,
	pz: number,
	ax: number,
	az: number,
	bx: number,
	bz: number
): number
	local dx, dz = bx - ax, bz - az
	local length = dx * dx + dz * dz
	local t = if length > 0 then math.clamp(((px - ax) * dx + (pz - az) * dz) / length, 0, 1) else 0
	return math.sqrt((px - ax - dx * t) ^ 2 + (pz - az - dz * t) ^ 2)
end
return Rules
