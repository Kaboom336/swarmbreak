--!strict
-- Pure audience policy for server-authored combat effects.

local FxAudience = {}

export type Point3 = {
	x: number,
	y: number,
	z: number,
}

-- Effects not listed here are global. This keeps announcements and future
-- non-positional effects on the existing broadcast path.
FxAudience.Radii = table.freeze({
	shot = 220,
	swing = 100,
	beam = 220,
	chain = 140,
	pull = 140,
	spit = 180,
	tell = 180,
	death = 180,
})

FxAudience.BucketSeconds = 0.05

function FxAudience.radiusFor(effectName: string): number?
	return FxAudience.Radii[effectName]
end

function FxAudience.isGlobal(effectName: string): boolean
	return FxAudience.radiusFor(effectName) == nil
end

local function distanceSquared(a: Point3, b: Point3): number
	local dx = a.x - b.x
	local dy = a.y - b.y
	local dz = a.z - b.z
	return dx * dx + dy * dy + dz * dz
end

-- Character lookup stays in the router. Supplying no position represents a
-- player whose character/root is missing, which keeps this module pure.
function FxAudience.selectPlayers<T>(
	players: { T },
	positions: { [T]: Point3 },
	origin: Point3,
	radius: number,
	sourcePlayer: T?
): { T }
	local selected = {}
	local includedSource = false
	local radiusSquared = radius * radius

	for _, player in players do
		if player == sourcePlayer then
			includedSource = true
			table.insert(selected, player)
		else
			local position = positions[player]
			if position and distanceSquared(position, origin) <= radiusSquared then
				table.insert(selected, player)
			end
		end
	end

	-- The originating player must see their own action even while their
	-- character is being replaced or if their root has not replicated yet.
	if sourcePlayer ~= nil and not includedSource then
		table.insert(selected, sourcePlayer)
	end

	return selected
end

function FxAudience.bucketFor(timestamp: number): number
	return math.floor(timestamp / FxAudience.BucketSeconds)
end

function FxAudience.coalescingKey(
	effectName: string,
	origin: Point3,
	timestamp: number,
	discriminator: string?
): string
	return table.concat({
		effectName,
		tostring(FxAudience.bucketFor(timestamp)),
		string.format("%.4f", origin.x),
		string.format("%.4f", origin.y),
		string.format("%.4f", origin.z),
		discriminator or "",
	}, "|")
end

return FxAudience
