--!strict
-- Pure batched steering math for Humanoid-free swarmlings.
export type Point = { x: number, y: number, z: number }
export type Unit = {
	Position: Point,
	Speed: number,
}
export type Transform = Point & {
	lookX: number,
	lookZ: number,
}

local SwarmlingStep = {}

local function nearest(position: Point, targets: { Point }): Point?
	local closest = nil
	local closestDistance = math.huge
	for _, target in targets do
		local dx = target.x - position.x
		local dz = target.z - position.z
		local distance = dx * dx + dz * dz
		if distance < closestDistance then
			closest = target
			closestDistance = distance
		end
	end
	return closest
end

function SwarmlingStep.step(units: { Unit }, targets: { Point }, dt: number): { Transform }
	local transforms = table.create(#units)
	local elapsed = math.max(0, dt)
	for _, unit in units do
		local position = unit.Position
		local target = nearest(position, targets)
		local lookX, lookZ = 0, -1
		local x, z = position.x, position.z
		if target then
			local dx = target.x - x
			local dz = target.z - z
			local distance = math.sqrt(dx * dx + dz * dz)
			if distance > 0 then
				lookX, lookZ = dx / distance, dz / distance
				local distanceToMove = math.min(math.max(0, unit.Speed) * elapsed, distance)
				x += lookX * distanceToMove
				z += lookZ * distanceToMove
			end
		end
		table.insert(transforms, {
			x = x,
			y = position.y,
			z = z,
			lookX = lookX,
			lookZ = lookZ,
		})
	end
	return transforms
end

return SwarmlingStep
