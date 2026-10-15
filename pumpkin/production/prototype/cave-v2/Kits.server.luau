local Kit = require(script.Parent.KitLibrary)
local Plan = require(script.Parent.KitPlan)
local map = workspace.CaveV2
Kit.init()
local folder = Instance.new("Folder")
folder.Name = "CaveKitDressing"
folder.Parent = map
local lanes = Plan.lanes(map)
local count, dropped, failed = 0, 0, 0
local function add(name, base, size, fitted)
	local m = Kit.spawn(name, "cave", base, size)
	if not m then
		failed += 1
		return
	end
	if fitted then
		local ok = Kit.fit(m, size, base)
		if not ok then
			m:Destroy()
			failed += 1
			return
		end
	end
	if not Plan.laneClear(m:GetDescendants(), lanes) then
		m:Destroy()
		dropped += 1
		return
	end
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanQuery = false
			p.CanCollide = false
			p.CanTouch = false
		end
	end
	m:SetAttribute("KitAssemblyId", "cave:" .. (count + 1))
	m.Parent = folder
	count += 1
	return m
end
for i, g in Plan.groups(map, "cave") do
	local m = add(g.name, g.base, g.size, g.fitted)
	if m then
		for _, p in g.parts do
			p.Transparency = 1
			p.CanCollide = false
			p.CanQuery = false
			p:SetAttribute("KitAssemblyId", m:GetAttribute("KitAssemblyId"))
		end
	end
	if i % 20 == 0 then
		task.wait()
	end
end
-- Complete fence bays with a post at BOTH endpoints, including every joint.
-- Existing native edge geometry is replaced only after all three kits fit.
local originals = map:GetChildren()
local indexed = {}
for _, p in originals do
	local index = p:GetAttribute("ConnectKitIndex")
	if index then
		indexed[index] = p
	end
end
local nodes = {}
local function joint(p)
	if nodes[p] then
		return nodes[p]
	end
	local position = p.CFrame.Position - Vector3.new(0, p.Size.Y / 2, 0)
	local nearest, distance, sign, offset = nil, math.huge, 1, 0
	for _, lane in lanes do
		local q = lane.CFrame:PointToObjectSpace(position)
		local metric = q.X ^ 2 + math.max(0, math.abs(q.Z) - lane.Size.Z / 2) ^ 2 + q.Y ^ 2
		if metric < distance then
			nearest, distance, sign, offset =
				lane, metric, q.X < 0 and -1 or 1, math.max(0, lane.Size.X / 2 + 2 - math.abs(q.X))
		end
	end
	nodes[p] = position + nearest.CFrame.RightVector * sign * offset
	return nodes[p]
end
local fenceBays = {}
for _, bay in require(script.Parent.CaveFenceData) do
	local key = table.concat(bay.posts, ":")
	fenceBays[key] = fenceBays[key] or { posts = bay.posts, rails = {} }
	for _, index in bay.rails do
		table.insert(fenceBays[key].rails, index)
	end
end
local fenceCount = 0
for _, bay in fenceBays do
	local pa, pb = indexed[bay.posts[1]], indexed[bay.posts[2]]
	local a, b = joint(pa), joint(pb)
	local right = (b - a).Unit
	local back = right:Cross(Vector3.yAxis).Unit
	local up = back:Cross(right).Unit
	local mid = (a + b) / 2
	local base = CFrame.new(mid.X, mid.Y, mid.Z, right.X, up.X, back.X, right.Y, up.Y, back.Y, right.Z, up.Z, back.Z)
	local rail = add("kenney_nature-kit__fence_simple", base, Vector3.new((b - a).Magnitude, 3.4, 0.4), true)
	if rail then
		local posts = {}
		for _, point in { a, b } do
			local m = add("kenney_mini-dungeon__column", CFrame.new(point), Vector3.new(0.8, 4, 0.8), true)
			if m then
				table.insert(posts, m)
			end
		end
		if #posts == 2 then
			rail:SetAttribute("FenceEndpoints", 2)
			for _, index in bay.rails do
				indexed[index].Transparency = 1
				indexed[index].CanQuery = false
			end
		else
			rail:Destroy()
			for _, post in posts do
				post:Destroy()
			end
		end
	end
	fenceCount += 1
	if fenceCount % 10 == 0 then
		task.wait()
	end
end
-- Mining station / cave shoulders. Candidates are checked against every deck,
-- independent of height, and grounded on existing rock rather than floating.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
local ground = {}
for _, p in originals do
	if p:IsA("BasePart") and p.CanCollide and not p:GetAttribute("WalkableLaneFloor") then
		table.insert(ground, p)
	end
end
groundParams.FilterDescendantsInstances = ground
groundParams.RespectCanCollide = true
local names = {
	"kenney_mini-dungeon__barrel",
	"kenney_mini-dungeon__chest",
	"kenney_survival-kit__box",
	"kenney_survival-kit__box-large",
	"kenney_mini-dungeon__wall",
	"kenney_mini-dungeon__wood-structure",
	"kenney_mini-dungeon__wood-support",
	"kenney_mini-dungeon__wall-opening",
	"kenney_nature-kit__cliff_cave_rock",
	"kenney_mini-dungeon__rocks",
	"quaternius-nature__Mushroom_Common",
	"kenney_nature-kit__mushroom_tan",
}
local anchors = {
	Vector3.new(150, 48, -140),
	Vector3.new(183, 48, -140),
	Vector3.new(204, 0, 22),
	Vector3.new(150, 0, 67),
	Vector3.new(71, 0, 54),
	Vector3.new(-42, 0, 97),
}
for _, anchor in anchors do
	for i, name in names do
		local x, z = anchor.X + ((i - 1) % 4) * 5, anchor.Z + math.floor((i - 1) / 4) * 6
		local hit = workspace:Raycast(Vector3.new(x, anchor.Y + 8, z), Vector3.new(0, -24, 0), groundParams)
		if hit then
			local size = i <= 4 and Vector3.new(4, 4, 4) or i <= 8 and Vector3.new(4, 10, 3) or Vector3.new(3, 3, 3)
			add(name, CFrame.new(hit.Position), size, false)
		end
		task.wait()
	end
end
count = #folder:GetChildren()
map:SetAttribute("KitSwapped", count)
map:SetAttribute("KitLanePlacementsDropped", dropped)
map:SetAttribute("KitFallbacks", failed)
map:SetAttribute("KitSwapVersion", 2)
print(string.format("[CaveKits] accepted=%d excluded=%d unavailable=%d", count, dropped, failed))
