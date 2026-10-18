-- Isolated native geometry; no dependency on guardian/Keeper code.

-- Bound synchronous construction/scans; offline builders have no task.
local yieldWork = 0
local yieldDeadline = os.clock() + .01
local function yieldBuild()
 yieldWork += 1
 if yieldWork % 300 == 0 and os.clock() >= yieldDeadline then
  if task then task.wait() end
  yieldDeadline = os.clock() + .01
 end
end
local MeadowV4 = {}
local data = require(script.Parent.Data)
local art = require(script.Parent.Fix1Art)
local routes = require(script.Parent.RouteData)
local fix2 = require(script.Parent.Fix2Routes)
local drops = require(script.Parent.ReachableDrops)
local polish = require(script.Parent.Polish)
function MeadowV4.build(parent: Instance, origin: Vector3?): Model
	local model = Instance.new("Model")
	model.Name = "MeadowV4"
	local offset = origin or Vector3.zero
	for _, item in polish.transform(fix2.transform(art.transform(data, routes), routes), routes) do
		yieldBuild()
		local p = Instance.new(if item.shape == "Wedge" then "WedgePart" else "Part")
		p.Name = item.name
		p.Anchored = true
		p.CanCollide, p.CanQuery, p.CanTouch = item.collidable, item.collidable, false
		p.Size = Vector3.new(unpack(item.size))
		p.Color = Color3.fromRGB(unpack(item.color))
		p.Material = Enum.Material[item.material]
		if p:IsA("Part") then
			p.Shape = Enum.PartType[item.shape]
		end
		p.Transparency = item.transparency
		local r, v = item.rotation, item.position
		p.CFrame = CFrame.new(
			v[1],
			v[2],
			v[3],
			r[1],
			r[2],
			r[3],
			r[4],
			r[5],
			r[6],
			r[7],
			r[8],
			r[9]
		)
		p:SetAttribute("MeadowV4Category", item.category)
		if item.polishCleared then p:SetAttribute("MeadowPolishCleared", true) end
		p:SetAttribute("WalkableLaneFloor", drops.isLane(item, routes))
		if drops.isLane(item, routes) then
			p:AddTag("AuthoredLaneFloor")
			p:SetAttribute("LaneId", item.name:match("^Fix2Lane_(.-)_%d+$")
				or item.name:match("^Fix2Junction_(.-)_%d+$") or item.name:match("^(.-)%d+$") or item.name)
		end
		p:SetAttribute(
			"SurfaceRole",
			if item.collidable then (if item.category == "cover" then "Cover" else "Floor") else "Scenery"
		)
		p.Parent = model
		if item.category == "light" then
			local light = Instance.new("PointLight")
			light.Color = p.Color
			light.Brightness, light.Range = 1.5, 18
			light.Parent = p
		end
	end
	-- Build every section in island-local coordinates, then translate once.
	local court = require(script.Parent.Gameplay).PvpCourt
	local deck = Instance.new("Part")
	deck.Name, deck.Size = "PvpCourtFloor", Vector3.new(18, 1.2, 18)
	deck.CFrame = CFrame.new(court.x, court.y - .48, -court.z)
	deck.Anchored, deck.CanCollide, deck.CanQuery, deck.CanTouch = true, true, true, false
	deck.Color, deck.Material = Color3.fromRGB(101, 148, 64), Enum.Material.Grass
	deck:SetAttribute("WalkableLaneFloor", true)
	deck:SetAttribute("SurfaceRole", "Floor")
	deck:SetAttribute("MeadowV4Category", "lane")
	deck:SetAttribute("LaneId", "pvp_court")
	deck:AddTag("AuthoredLaneFloor")
	deck.Parent = model
	-- Section dressing is cosmetic: a failed prop must never take the island down with it.
	local sections = {}
	for _, module in script.Parent:GetChildren() do yieldBuild();
		if module:IsA("ModuleScript") and (module.Name:match("^Section%d+$") or module.Name == "Outsmart"
			or module:GetAttribute("MeadowDressing") == true) then table.insert(sections, module) end
	end
	table.sort(sections, function(a, b)
		if a.Name == "Outsmart" then return false end
		if b.Name == "Outsmart" then return true end
		return a.Name < b.Name
	end)
	for _, module in sections do
		-- Yield between sections so heavy dressing cannot trip Roblox's script timeout (offline builders have no task).
		if task then task.wait() end
		local ok, err = pcall(function() require(module).build(model, Vector3.zero) end)
		if not ok then warn("[MeadowV4] " .. module.Name .. " dressing skipped: " .. tostring(err)) end
	end
	-- One owner-approved gameplay slice; shared local frame before translation.
	local raid = script.Parent:FindFirstChild("RaidSlice")
	if raid then require(raid).build(model, Vector3.zero) end
	-- Audit after every section, including fix8's additional authored bait lane.
	-- Preserve section failure isolation while retaining a visible failure reason.
	local clearanceOK, clearanceProblem = pcall(function()
		require(script.Parent.Section1).clearProps(model)
	end)
	if not clearanceOK then model:SetAttribute("PvpMapClearanceFailure", tostring(clearanceProblem)) end
	local visual = script.Parent:FindFirstChild("VisualSimplify")
	if visual then require(visual).apply(model) end
	for _, p in model:GetDescendants() do yieldBuild();
		if p:IsA("BasePart") then p.CFrame = CFrame.new(offset) * p.CFrame end
	end
	model:SetAttribute("MeadowOrigin", offset)
	model.Parent = parent
	return model
end
MeadowV4.Build = MeadowV4.build
return MeadowV4
