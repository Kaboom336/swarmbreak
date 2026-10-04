--!strict
-- Seeded, pure scatter data. Runtime builders decide how each prop kind is assembled.
export type Position = { x: number, z: number }
export type Lane = { ax: number, az: number, bx: number, bz: number, HalfWidth: number }
export type Options = {
	Seed: number,
	Bounds: { x: number?, z: number?, Width: number, Depth: number },
	Spacing: number?,
	Spawns: { Position }?,
	SpawnClearance: number?,
	Lanes: { Lane }?,
}
export type Prop = Position & { Kind: string, Rotation: number, Scale: number }

local PropScatter = {}
PropScatter.Kinds = { "Crate", "Pipe", "Antenna", "Rock", "GooPuddle", "Cable" }
PropScatter.DefaultSpacing = 8

local function random(state: number): (number, number)
	local nextState = (state * 48271) % 2147483647
	return nextState, nextState / 2147483647
end

local function distanceSquaredToLane(x: number, z: number, lane: Lane): number
	local dx, dz = lane.bx - lane.ax, lane.bz - lane.az
	local lengthSquared = dx * dx + dz * dz
	local t = if lengthSquared > 0
		then math.clamp(((x - lane.ax) * dx + (z - lane.az) * dz) / lengthSquared, 0, 1)
		else 0
	local px, pz = lane.ax + dx * t, lane.az + dz * t
	return (x - px) ^ 2 + (z - pz) ^ 2
end

function PropScatter.generate(options: Options): { Prop }
	local spacing = options.Spacing or PropScatter.DefaultSpacing
	local halfWidth, halfDepth = options.Bounds.Width / 2, options.Bounds.Depth / 2
	local centerX, centerZ = options.Bounds.x or 0, options.Bounds.z or 0
	local clearance = options.SpawnClearance or 10
	local state = math.max(1, math.floor(math.abs(options.Seed)) % 2147483647)
	local props = {}
	local columns = math.floor(options.Bounds.Width / spacing)
	local rows = math.floor(options.Bounds.Depth / spacing)
	for row = 0, rows - 1 do
		for column = 0, columns - 1 do
			local jitterX, jitterZ, choose, rotation, scale
			state, jitterX = random(state)
			state, jitterZ = random(state)
			state, choose = random(state)
			state, rotation = random(state)
			state, scale = random(state)
			local x = centerX
				- halfWidth
				+ (column + 0.5) * spacing
				+ (jitterX - 0.5) * spacing * 0.45
			local z = centerZ - halfDepth + (row + 0.5) * spacing + (jitterZ - 0.5) * spacing * 0.45
			local clear = true
			for _, spawn in options.Spawns or {} do
				if (x - spawn.x) ^ 2 + (z - spawn.z) ^ 2 <= clearance * clearance then
					clear = false
					break
				end
			end
			if clear then
				for _, lane in options.Lanes or {} do
					if distanceSquaredToLane(x, z, lane) <= lane.HalfWidth * lane.HalfWidth then
						clear = false
						break
					end
				end
			end
			if clear then
				table.insert(props, {
					x = x,
					z = z,
					Kind = PropScatter.Kinds[math.min(
						#PropScatter.Kinds,
						math.floor(choose * #PropScatter.Kinds) + 1
					)],
					Rotation = rotation * math.pi * 2,
					Scale = 0.8 + scale * 0.4,
				})
			end
		end
	end
	return props
end

return PropScatter
