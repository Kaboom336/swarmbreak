-- Reuse the inspected, locally authored golden-acorn mesh; no uploads/asset IDs.
local AssetService = game:GetService("AssetService")
local Data = require(game:GetService("ReplicatedStorage"):WaitForChild("HomeArtGeometry")).Acorn
local Props = {}
local template, retained, building
local function base(parent, name, size, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Color = name, size, color
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Material, p.Parent = Enum.Material.Wood, parent
	return p
end
function Props.build(kind, parent)
	local model = Instance.new("Model")
	model.Name, model.Parent = "KeeperProp_" .. kind, parent
	local pieces = {}
	if kind == "lob" then
		local log = base(model, "HeavyLog", Vector3.new(8, 6, 6), Color3.fromRGB(96, 55, 25))
		log.Shape = Enum.PartType.Cylinder
		table.insert(pieces, { part = log, cf = CFrame.identity })
		for _, side in ipairs({ -1, 1 }) do
			local cut = base(model, "CutEnd", Vector3.new(0.06, 5.8, 5.8), Color3.fromRGB(179, 127, 67))
			cut.Shape = Enum.PartType.Cylinder
			table.insert(pieces, { part = cut, cf = CFrame.new(side * 4.01, 0, 0) })
		end
	else
		while building do
			task.wait()
		end
		if not template then
			building = true
			local ok, err = pcall(function()
				template, retained = {}, {}
				for _, section in ipairs(Data) do
					local mesh = assert(AssetService:CreateEditableMesh(), "acorn mesh budget unavailable")
					table.insert(retained, mesh)
					local lo, hi =
						Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
					for _, v in ipairs(section.vertices) do
						local p = Vector3.new(table.unpack(v))
						lo = lo:Min(p)
						hi = hi:Max(p)
					end
					local centre, ids = (lo + hi) / 2, {}
					for i, v in ipairs(section.vertices) do
						ids[i] = mesh:AddVertex(Vector3.new(table.unpack(v)) - centre)
					end
					for _, t in ipairs(section.triangles) do
						mesh:AddTriangle(ids[t[1] + 1], ids[t[2] + 1], ids[t[3] + 1])
					end
					-- Content is a Roblox engine global absent from the offline roblox_min std.
					-- selene: allow(undefined_variable)
					local p = AssetService:CreateMeshPartAsync(Content.fromObject(mesh))
					p.Name = section.name
					p.Color = section.name:lower():find("cap") and Color3.fromRGB(75, 101, 38)
						or section.name:lower():find("stem") and Color3.fromRGB(65, 48, 26)
						or Color3.fromRGB(151, 90, 43)
					p.Material = Enum.Material.Wood
					p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
					p.Size *= 0.5 -- Source acorn is 3 studs tall; readable 1.5-stud projectile.
					table.insert(template, { part = p, cf = CFrame.new((centre - Vector3.new(0, 2.28, 0)) * 0.5) })
				end
			end)
			building = false
			if not ok then
				for _, e in ipairs(template or {}) do
					e.part:Destroy()
				end
				for _, mesh in ipairs(retained or {}) do
					mesh:Destroy()
				end
				template = nil
				model:Destroy()
				error(err)
			end
		end
		for _, entry in ipairs(template) do
			local p = entry.part:Clone()
			p.Parent = model
			table.insert(pieces, { part = p, cf = entry.cf })
		end
	end
	return { model = model, pieces = pieces }
end
function Props.move(entry, cf, visible)
	for _, piece in ipairs(entry.pieces) do
		piece.part.CFrame = cf * piece.cf
		piece.part.Transparency = visible and 0 or 1
	end
end
return Props
