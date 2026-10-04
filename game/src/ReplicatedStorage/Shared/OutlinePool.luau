--!strict
-- Pure nearest-target selection for the client Highlight pool.
local OutlinePool = {}

OutlinePool.MaxActive = 20

export type Candidate = {
	Target: any,
	Distance: number,
}

function OutlinePool.nearest(candidates: { Candidate }): { Candidate }
	local sorted = {}
	for _, candidate in candidates do
		table.insert(sorted, candidate)
	end
	table.sort(sorted, function(a, b)
		return a.Distance < b.Distance
	end)

	local nearest = {}
	for index = 1, math.min(#sorted, OutlinePool.MaxActive) do
		table.insert(nearest, sorted[index])
	end
	return nearest
end

return OutlinePool
