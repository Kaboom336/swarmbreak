-- Reuse the authored JSON islands as coloured blocks, with no editable/GPU mesh allocation.
local Blocks = {}
local cache = setmetatable({}, { __mode = "k" })
function Blocks.bounds(section)
	if cache[section] then
		return cache[section]
	end
	local parents = {}
	-- Emergency path: one coloured bounds block per section, never an invisible asset.
	if #section.triangles == 0 then
		local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, vertex in ipairs(section.vertices) do
			local v = Vector3.new(table.unpack(vertex))
			lo, hi = lo:Min(v), hi:Max(v)
		end
		return { { center = (lo + hi) / 2, size = (hi - lo):Max(Vector3.new(0.02, 0.02, 0.02)) } }
	end
	local function root(i)
		parents[i] = parents[i] or i
		if parents[i] ~= i then
			parents[i] = root(parents[i])
		end
		return parents[i]
	end
	for _, tri in ipairs(section.triangles) do
		local a = root(tri[1] + 1)
		parents[root(tri[2] + 1)], parents[root(tri[3] + 1)] = a, a
	end
	local groups, result = {}, {}
	for i, vertex in ipairs(section.vertices) do
		local id, v = root(i), Vector3.new(table.unpack(vertex))
		local b = groups[id]
		if b then
			b.lo, b.hi = b.lo:Min(v), b.hi:Max(v)
		else
			groups[id] = { lo = v, hi = v }
		end
	end
	for _, b in pairs(groups) do
		table.insert(result, { center = (b.lo + b.hi) / 2, size = (b.hi - b.lo):Max(Vector3.new(0.02, 0.02, 0.02)) })
	end
	cache[section] = result
	return result
end
function Blocks.section(section, model, placement, material, attach)
	local count = 0
	for _, b in ipairs(Blocks.bounds(section)) do
		local part = Instance.new("Part")
		part.Name, part.Size = section.name, b.size
		part.Color, part.Material = Color3.fromRGB(table.unpack(section.color)), material
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
		part.CFrame, part.Parent = placement * CFrame.new(b.center), model
		if attach then
			attach(part)
		end
		count += 1
	end
	return count
end
function Blocks.log(label, count)
	local ok, meshMb = pcall(function()
		local stats = game:GetService("Stats")
		assert(stats.MemoryTrackingEnabled, "tracking disabled")
		return stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.GraphicsMeshParts)
	end)
	print(
		string.format(
			"[%s] native Parts=%d; EditableMeshes=0 (0 bytes allocated); session GraphicsMeshParts MB=%s",
			label,
			count,
			ok and string.format("%.3f", meshMb) or "UNKNOWN (tracking unavailable)"
		)
	)
end
return Blocks
