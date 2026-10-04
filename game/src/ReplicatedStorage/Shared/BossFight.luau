--!strict
-- Pure Swarm Queen encounter rules. Runtime code consumes this table so the
-- server-authoritative damage rules and client presentation stay in sync.

export type FloorRect = { ax: number, az: number, bx: number, bz: number }
export type Gate = { Name: string, ZoneId: string, x: number, z: number }
export type GooPool = { x: number, z: number, Radius: number }

local BossFight = {}

BossFight.PhaseTwoHealthRatio = 0.55
BossFight.TelegraphSeconds = 0.8
BossFight.PhaseOneAttackInterval = 3
BossFight.PhaseTwoAttackInterval = BossFight.PhaseOneAttackInterval * 0.8
BossFight.AddEverySeconds = 12
BossFight.GooDamagePerSecond = 8
BossFight.GateClearance = 7
BossFight.AddGateNames = { "HiveGateNorth", "HiveGateSouth" }
BossFight.Attacks = {
	{ Name = "TailSweep", Shape = "Arc", TelegraphSeconds = BossFight.TelegraphSeconds },
	{ Name = "GooMortar", Shape = "ThreeCircles", TelegraphSeconds = BossFight.TelegraphSeconds },
	{ Name = "Charge", Shape = "Line", TelegraphSeconds = BossFight.TelegraphSeconds },
}

function BossFight.phaseForHealth(health: number, maxHealth: number): number
	if maxHealth <= 0 then
		return 1
	end
	return if health / maxHealth <= BossFight.PhaseTwoHealthRatio then 2 else 1
end

function BossFight.attackInterval(phase: number): number
	return if phase >= 2 then BossFight.PhaseTwoAttackInterval else BossFight.PhaseOneAttackInterval
end

function BossFight.canAdd(alive: number, capacity: number): boolean
	return alive < capacity
end

local function contained(rect: FloorRect, x: number, z: number, radius: number): boolean
	return x - radius >= rect.ax
		and x + radius <= rect.bx
		and z - radius >= rect.az
		and z + radius <= rect.bz
end

local function clearOfGates(gates: { Gate }, x: number, z: number, radius: number): boolean
	for _, gate in gates do
		if gate.ZoneId == "HiveCore" then
			local dx = x - gate.x
			local dz = z - gate.z
			if dx * dx + dz * dz < (radius + BossFight.GateClearance) ^ 2 then
				return false
			end
		end
	end
	return true
end

-- Candidates are expressed relative to the supplied floor bounds, then accepted only
-- when the entire circle is inside one of ArenaLayout.floorRects. That makes gaps and
-- missing floor authoritative instead of duplicating the arena geometry here.
function BossFight.gooPools(floorRects: { FloorRect }, gates: { Gate }): { GooPool }
	if #floorRects == 0 then
		return {}
	end
	local ax, az = math.huge, math.huge
	local bx, bz = -math.huge, -math.huge
	for _, rect in floorRects do
		ax = math.min(ax, rect.ax)
		az = math.min(az, rect.az)
		bx = math.max(bx, rect.bx)
		bz = math.max(bz, rect.bz)
	end
	local centerX, centerZ = (ax + bx) / 2, (az + bz) / 2
	local radius = math.min(10, (bx - ax) / 12, (bz - az) / 12)
	local offsets = {
		{ -36, -28 },
		{ 0, -34 },
		{ 34, -24 },
		{ -34, 28 },
		{ 4, 30 },
		{ 36, 24 },
	}
	local pools = {}
	for _, offset in offsets do
		local x, z = centerX + offset[1], centerZ + offset[2]
		local onFloor = false
		for _, rect in floorRects do
			if contained(rect, x, z, radius) then
				onFloor = true
				break
			end
		end
		if onFloor and clearOfGates(gates, x, z, radius) then
			table.insert(pools, { x = x, z = z, Radius = radius })
		end
	end
	return pools
end

return BossFight
