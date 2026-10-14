-- Isolated native geometry; no dependency on guardian/Keeper code.
local MeadowV4 = {}
local data = require(script.Parent.Data)
function MeadowV4.build(parent: Instance, origin: Vector3?): Model
	local model = Instance.new("Model")
	model.Name = "MeadowV4"
	local offset = origin or Vector3.zero
	for _, item in data do
		local p = Instance.new(if item.shape == "Wedge" then "WedgePart" else "Part")
		p.Name = item.name
		p.Anchored = true
		p.CanCollide, p.CanQuery, p.CanTouch = item.collidable, item.collidable, false
		p.Size = Vector3.new(unpack(item.size))
		p.Color = Color3.fromRGB(unpack(item.color))
		p.Material = Enum.Material[item.material]
		if p:IsA("Part") then p.Shape = Enum.PartType[item.shape] end
		p.Transparency = item.transparency
		local r, v = item.rotation, item.position
		p.CFrame = CFrame.new(v[1] + offset.X, v[2] + offset.Y, v[3] + offset.Z,
			r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9])
		p:SetAttribute("MeadowV4Category", item.category)
		p:SetAttribute("SurfaceRole", if item.collidable then (if item.category == "cover" then "Cover" else "Floor") else "Scenery")
		p.Parent = model
		if item.category == "light" then
			local light = Instance.new("PointLight")
			light.Color = p.Color
			light.Brightness, light.Range = 1.5, 18
			light.Parent = p
		end
	end
	model.Parent = parent
	return model
end
MeadowV4.Build = MeadowV4.build
return MeadowV4
