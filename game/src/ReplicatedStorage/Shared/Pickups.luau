--!strict
-- Pure pickup rules. The server owns pickup positions and rewards; clients only render them.
local Pickups = {}

Pickups.DropOdds = {
	Coin = 0.85,
	XP = 1,
	Vacuum = 0.015,
}
Pickups.AttractionRadius = 18
Pickups.CollectionRadius = 3.5
Pickups.VacuumDuration = 6
Pickups.Lifetime = 20
Pickups.FlySpeed = 48

export type Point = { x: number?, y: number?, z: number?, X: number?, Y: number?, Z: number? }
export type Candidate = {
	Id: number,
	Position: Point,
	Eligible: boolean,
	VacuumUntil: number?,
}
export type Drop = {
	Collected: boolean?,
	TargetId: number?,
	Position: Point,
	ExpiresAt: number?,
}

local function component(point: Point, lower: string, upper: string): number
	-- Roblox vectors expose uppercase components; plain test/data points use lowercase keys.
	return (point :: any)[upper] or (point :: any)[lower] or 0
end

local function distanceSquared(a: Point, b: Point): number
	local dx = component(a, "x", "X") - component(b, "x", "X")
	local dy = component(a, "y", "Y") - component(b, "y", "Y")
	local dz = component(a, "z", "Z") - component(b, "z", "Z")
	return dx * dx + dy * dy + dz * dz
end

function Pickups.shouldDrop(kind: string, roll01: number): boolean
	local odds = Pickups.DropOdds[kind]
	return odds ~= nil and roll01 >= 0 and roll01 < odds
end

function Pickups.inRange(a: Point, b: Point, radius: number): boolean
	return radius >= 0 and distanceSquared(a, b) <= radius * radius
end

function Pickups.isVacuumActive(expiresAt: number?, now: number): boolean
	return expiresAt ~= nil and now < expiresAt
end

function Pickups.vacuumExpiry(now: number): number
	return now + Pickups.VacuumDuration
end

-- Vacuum owners have first claim from any distance. Otherwise the nearest eligible player
-- inside the magnet radius wins. User id makes exact-distance ties deterministic.
function Pickups.chooseTarget(
	origin: Point,
	candidates: { Candidate },
	now: number,
	radius: number?
): Candidate?
	local limit = radius or Pickups.AttractionRadius
	local best: Candidate? = nil
	local bestDistance = math.huge
	local bestVacuum = false
	for _, candidate in candidates do
		if candidate.Eligible then
			local vacuum = Pickups.isVacuumActive(candidate.VacuumUntil, now)
			local distance = distanceSquared(origin, candidate.Position)
			if vacuum or distance <= limit * limit then
				local betterClass = vacuum and not bestVacuum
				local sameClass = vacuum == bestVacuum
				local betterDistance = sameClass and distance < bestDistance
				local tied = sameClass and distance == bestDistance
				if
					best == nil
					or betterClass
					or betterDistance
					or (tied and candidate.Id < (best :: Candidate).Id)
				then
					best = candidate
					bestDistance = distance
					bestVacuum = vacuum
				end
			end
		end
	end
	return best
end

-- Atomically validates and claims a drop. Callers award the value only when this returns true.
function Pickups.tryCollect(drop: Drop, collector: Candidate, now: number): (boolean, string)
	if drop.Collected then
		return false, "collected"
	end
	if drop.ExpiresAt and now >= drop.ExpiresAt then
		return false, "expired"
	end
	if not collector.Eligible then
		return false, "ineligible"
	end
	if drop.TargetId ~= collector.Id then
		return false, "target"
	end
	if not Pickups.inRange(drop.Position, collector.Position, Pickups.CollectionRadius) then
		return false, "range"
	end
	drop.Collected = true
	return true, ""
end

return Pickups
