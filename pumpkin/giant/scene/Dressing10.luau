-- Arena round 10 dressing: jump pads on the four roads and glowing jack-o'-lanterns lining
-- them. Run in Edit mode after PatchMap.luau.
local ServerStorage = game:GetService("ServerStorage")
local kit = ServerStorage.KitSource
local garden = workspace.Garden

for _, name in { "JumpPads", "RoadLanterns" } do
	local old = garden:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end
local pads = Instance.new("Folder")
pads.Name = "JumpPads"
pads.Parent = garden
local lanterns = Instance.new("Folder")
lanterns.Name = "RoadLanterns"
lanterns.Parent = garden

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace.Terrain }
local function ground(x: number, z: number): number
	local hit = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -240, 0), params)
	return hit and hit.Position.Y or 0
end

local DIAG = {
	Vector3.new(1, 0, 1).Unit,
	Vector3.new(1, 0, -1).Unit,
	Vector3.new(-1, 0, -1).Unit,
	Vector3.new(-1, 0, 1).Unit,
}
for _, d in DIAG do
	-- One pad flings you out toward the fields, one flings you back toward the market.
	for _, spec in { { r = 46, dir = d }, { r = 80, dir = -d } } do
		local p = d * spec.r
		local y = ground(p.X, p.Z)
		local pad = Instance.new("Part")
		pad.Name = "Pad"
		pad.Shape = Enum.PartType.Cylinder
		pad.Material = Enum.Material.Neon
		pad.Color = Color3.fromRGB(255, 150, 40)
		pad.Anchored = true
		pad.CanCollide = false
		pad.Size = Vector3.new(0.4, 7, 7)
		pad.CFrame = CFrame.new(p.X, y + 0.25, p.Z) * CFrame.Angles(0, 0, math.rad(90))
		pad:SetAttribute("Dir", spec.dir)
		pad.Parent = pads
		local ring = pad:Clone()
		ring.Name = "Rim"
		ring.Material = Enum.Material.Slate
		ring.Color = Color3.fromRGB(60, 40, 70)
		ring.Size = Vector3.new(0.3, 8.4, 8.4)
		ring.CFrame = pad.CFrame * CFrame.new(-0.1, 0, 0)
		ring:SetAttribute("Dir", nil)
		ring.Parent = pad
		local arrow = Instance.new("BillboardGui")
		arrow.Size = UDim2.fromOffset(60, 60)
		arrow.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		arrow.LightInfluence = 0
		arrow.MaxDistance = 80
		arrow.Parent = pad
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 200, 90)
		label.Text = "⏫"
		label.Parent = arrow
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 150, 40)
		light.Range = 12
		light.Brightness = 1.5
		light.Parent = pad
	end
	-- Jack-o'-lanterns along both sides of the road.
	local side = Vector3.new(d.Z, 0, -d.X)
	for r = 40, 82, 14 do
		for _, s in { -1, 1 } do
			local p = d * r + side * s * 9
			if (p - (d * 64 + side * 12)).Magnitude < 10 then
				continue -- leave room for the cauldron
			end
			local y = ground(p.X, p.Z) - 0.1
			local m = kit.pumpkin_orange_jackolantern:Clone()
			m:ScaleTo(2.5 * 0.8)
			local bcf, bsize = m:GetBoundingBox()
			m.WorldPivot = CFrame.new(bcf.X, bcf.Y - bsize.Y / 2, bcf.Z)
			local at = Vector3.new(p.X, y, p.Z)
			m:PivotTo(CFrame.lookAt(at, at - side * s))
			for _, part in m:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
					part.CanCollide = false
				end
			end
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 140, 40)
			light.Range = 10
			light.Brightness = 1.4
			light.Parent = m:FindFirstChildWhichIsA("BasePart", true)
			m.Parent = lanterns
		end
	end
end

return string.format("%d pads, %d lanterns", #pads:GetChildren(), #lanterns:GetChildren())
