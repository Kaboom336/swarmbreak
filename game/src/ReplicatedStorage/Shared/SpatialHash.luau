--!strict
-- Pure 3D spatial hash. Positions are plain tables so this module also runs under Lune.
export type Position = {
	x: number,
	y: number,
	z: number,
}

type Entry = {
	position: Position,
	key: string,
	order: number,
}

local SpatialHash = {}
SpatialHash.__index = SpatialHash

local function copyPosition(position: Position): Position
	return { x = position.x, y = position.y, z = position.z }
end

function SpatialHash.cellCoordinates(position: Position, cellSize: number): (number, number, number)
	assert(cellSize > 0, "SpatialHash cell size must be positive")
	return math.floor(position.x / cellSize),
		math.floor(position.y / cellSize),
		math.floor(position.z / cellSize)
end

function SpatialHash.cellKey(x: number, y: number, z: number): string
	return string.format("%d,%d,%d", x, y, z)
end

local function keyFor(position: Position, cellSize: number): string
	local x, y, z = SpatialHash.cellCoordinates(position, cellSize)
	return SpatialHash.cellKey(x, y, z)
end

function SpatialHash.new(cellSize: number)
	assert(cellSize > 0, "SpatialHash cell size must be positive")
	return setmetatable({
		cellSize = cellSize,
		cells = {},
		entries = {},
		nextOrder = 0,
	}, SpatialHash)
end

function SpatialHash:insert(item: any, position: Position)
	local existing: Entry? = self.entries[item]
	if existing then
		self:move(item, position)
		return
	end

	self.nextOrder += 1
	local key = keyFor(position, self.cellSize)
	local cell = self.cells[key]
	if not cell then
		cell = {}
		self.cells[key] = cell
	end
	cell[item] = true
	self.entries[item] = {
		position = copyPosition(position),
		key = key,
		order = self.nextOrder,
	}
end

function SpatialHash:move(item: any, position: Position): boolean
	local entry: Entry? = self.entries[item]
	if not entry then
		return false
	end

	local newKey = keyFor(position, self.cellSize)
	if newKey ~= entry.key then
		local oldCell = self.cells[entry.key]
		if oldCell then
			oldCell[item] = nil
			if next(oldCell) == nil then
				self.cells[entry.key] = nil
			end
		end
		local newCell = self.cells[newKey]
		if not newCell then
			newCell = {}
			self.cells[newKey] = newCell
		end
		newCell[item] = true
		entry.key = newKey
	end
	entry.position = copyPosition(position)
	return true
end

function SpatialHash:remove(item: any): boolean
	local entry: Entry? = self.entries[item]
	if not entry then
		return false
	end
	local cell = self.cells[entry.key]
	if cell then
		cell[item] = nil
		if next(cell) == nil then
			self.cells[entry.key] = nil
		end
	end
	self.entries[item] = nil
	return true
end

function SpatialHash:queryRadius(position: Position, radius: number): { any }
	assert(radius >= 0, "SpatialHash query radius must not be negative")
	local minX, minY, minZ = SpatialHash.cellCoordinates({
		x = position.x - radius,
		y = position.y - radius,
		z = position.z - radius,
	}, self.cellSize)
	local maxX, maxY, maxZ = SpatialHash.cellCoordinates({
		x = position.x + radius,
		y = position.y + radius,
		z = position.z + radius,
	}, self.cellSize)
	local radiusSquared = radius * radius
	local found = {}

	for x = minX, maxX do
		for y = minY, maxY do
			for z = minZ, maxZ do
				local cell = self.cells[SpatialHash.cellKey(x, y, z)]
				if cell then
					for item in cell do
						local entry: Entry = self.entries[item]
						local dx = entry.position.x - position.x
						local dy = entry.position.y - position.y
						local dz = entry.position.z - position.z
						local distanceSquared = dx * dx + dy * dy + dz * dz
						if distanceSquared <= radiusSquared then
							table.insert(found, {
								item = item,
								distanceSquared = distanceSquared,
								order = entry.order,
							})
						end
					end
				end
			end
		end
	end

	table.sort(found, function(a, b)
		return a.distanceSquared < b.distanceSquared
			or (a.distanceSquared == b.distanceSquared and a.order < b.order)
	end)
	local result = {}
	for _, value in found do
		table.insert(result, value.item)
	end
	return result
end

SpatialHash.radiusQuery = SpatialHash.queryRadius

return SpatialHash
