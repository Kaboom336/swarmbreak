--!strict
-- Pure construction of the checked-in arena model JSON data.

export type Position = {
	x: number,
	z: number,
}

export type SizedPosition = Position & {
	Width: number,
	Height: number,
	Depth: number,
}

export type Prop = SizedPosition & {
	Kind: "Crate" | "LowWall",
}

export type Beacon = Position & {
	Name: string,
	Width: number,
	Height: number,
	Color: { number },
}

export type Layout = {
	Floor: number,
	Spawns: { Position },
	Bunkers: { SizedPosition },
	Ring: {
		OuterDiameter: number,
		Height: number,
		Thickness: number,
		Gap: number,
	},
	Props: { Prop },
	Beacons: { Beacon },
}

export type Theme = {
	Floor: { number },
	Metal: { number },
	MetalDark: { number },
}

export type OutputFile = {
	Name: string,
	Contents: { [string]: any },
}

local IDENTITY = {
	{ 1, 0, 0 },
	{ 0, 1, 0 },
	{ 0, 0, 1 },
}

local function color(values: { number }): { number }
	return { values[1] / 255, values[2] / 255, values[3] / 255 }
end

local function explicitCFrame(
	x: number,
	y: number,
	z: number,
	orientation: { { number } }?
): { [string]: any }
	return {
		CFrame = {
			position = { x, y, z },
			orientation = orientation or IDENTITY,
		},
	}
end

local function part(
	name: string,
	size: { number },
	position: { number },
	partColor: { number },
	material: string,
	orientation: { { number } }?,
	extraProperties: { [string]: any }?
): { [string]: any }
	local properties: { [string]: any } = {
		Name = name,
		Anchored = true,
		Size = size,
		Color = partColor,
		Material = material,
		TopSurface = "Smooth",
		BottomSurface = "Smooth",
		CFrame = explicitCFrame(position[1], position[2], position[3], orientation),
	}
	if extraProperties then
		for key, value in extraProperties do
			properties[key] = value
		end
	end
	return {
		name = name,
		className = "Part",
		properties = properties,
	}
end

local function folder(children: { { [string]: any } }): { [string]: any }
	return {
		className = "Folder",
		properties = {},
		children = children,
	}
end

local ArenaModelGenerator = {}

function ArenaModelGenerator.build(layout: Layout, theme: Theme): { OutputFile }
	local floor = part(
		"Floor",
		{ layout.Floor, 2, layout.Floor },
		{ 0, 0, 0 },
		color(theme.Floor),
		"Slate",
		nil,
		nil
	)
	floor.name = nil

	local spawns = {}
	for index, position in layout.Spawns do
		table.insert(
			spawns,
			part(
				"Spawn" .. index,
				{ 6, 1, 6 },
				{ position.x, 1.5, position.z },
				{ 0.2, 0.2, 0.2 },
				"SmoothPlastic",
				nil,
				{ Transparency = 1, CanCollide = false }
			)
		)
	end

	local pieces = {}
	for index, spec in layout.Bunkers do
		table.insert(
			pieces,
			part(
				"Bunker" .. index,
				{ spec.Width, spec.Height, spec.Depth },
				{ spec.x, 1 + spec.Height / 2, spec.z },
				color(theme.MetalDark),
				"DiamondPlate",
				nil,
				nil
			)
		)
	end

	local ring = layout.Ring
	local ringRadius = (ring.OuterDiameter - ring.Thickness) / 2
	local segmentCount = 12
	local arcStride = 2 * math.pi * ringRadius / segmentCount
	local segmentLength = 2 * arcStride - ring.Gap
	for index = 0, segmentCount - 1 do
		if index % 3 ~= 0 then
			local angle = index * 2 * math.pi / segmentCount
			local rotation = -angle - math.pi / 2
			local cosine = math.cos(rotation)
			local sine = math.sin(rotation)
			table.insert(
				pieces,
				part(
					"Ring",
					{ segmentLength, ring.Height, ring.Thickness },
					{
						ringRadius * math.cos(angle),
						1 + ring.Height / 2,
						ringRadius * math.sin(angle),
					},
					color(theme.Metal),
					"Metal",
					{
						{ cosine, 0, sine },
						{ 0, 1, 0 },
						{ -sine, 0, cosine },
					},
					nil
				)
			)
		end
	end

	for _, spec in layout.Props do
		table.insert(
			pieces,
			part(
				spec.Kind,
				{ spec.Width, spec.Height, spec.Depth },
				{ spec.x, 1 + spec.Height / 2, spec.z },
				color(if spec.Kind == "Crate" then theme.Metal else theme.MetalDark),
				if spec.Kind == "Crate" then "DiamondPlate" else "Metal",
				nil,
				nil
			)
		)
	end

	for _, spec in layout.Beacons do
		table.insert(
			pieces,
			part(
				"Beacon" .. spec.Name,
				{ spec.Width, spec.Height, spec.Width },
				{ spec.x, 1 + spec.Height / 2, spec.z },
				color(spec.Color),
				"Neon",
				nil,
				{ CanCollide = false, CanQuery = false }
			)
		)
	end

	return {
		{ Name = "Floor.model.json", Contents = floor },
		{ Name = "EnemySpawns.model.json", Contents = folder(spawns) },
		{ Name = "ArenaLayout.model.json", Contents = folder(pieces) },
	}
end

return ArenaModelGenerator
