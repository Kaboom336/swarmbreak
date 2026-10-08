-- Arena round 6 scene polish: clear the spawn view, face the spawn at the patch and pyramid,
-- big floating signposts, a readable SHOP board, warmer dusk fog and a few warm lamps.
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local kit = ServerStorage.KitSource
local garden = workspace.Garden
local art = garden.Art

local function place(name, cf, scale)
	local m = kit[name]:Clone()
	m:ScaleTo(2.5 * (scale or 1))
	local bcf, bsize = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(bcf.X, bcf.Y - bsize.Y / 2, bcf.Z)
	m:PivotTo(cf)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	m.Parent = art
	return m
end

-- 1. Nothing tall between the spawn camera and the garden.
local removed = 0
for _, m in art:GetChildren() do
	if string.match(m.Name, "^tree_") then
		local p = m:GetPivot().Position
		if math.abs(p.X) < 16 and p.Z > 44 and p.Z < 95 then
			m:Destroy()
			removed += 1
		end
	end
end

-- 2. Spawn faces between the patch and the pyramid.
local spawn = garden:FindFirstChildOfClass("SpawnLocation") or workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then
	local at = Vector3.new(0, 0.5, 47)
	spawn.CFrame = CFrame.lookAt(at, Vector3.new(-12, 0.5, 10))
end

-- 3. Floating signposts.
local function signpost(name: string, text: string, color: Color3, position: Vector3)
	local old = garden:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local anchor = Instance.new("Part")
	anchor.Name = name
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position
	anchor.Parent = garden
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(230, 58)
	bb.LightInfluence = 0
	bb.MaxDistance = 220
	bb.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = bb
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(30, 12, 40)
	stroke.Parent = label
end
signpost("SignPumpkins", "PUMPKINS", Color3.fromRGB(255, 160, 50), Vector3.new(-27, 14, 20))
signpost("SignPyramid", "PYRAMID", Color3.fromRGB(255, 214, 80), Vector3.new(0, 30, -18))
signpost("SignCauldron", "CAULDRON", Color3.fromRGB(150, 255, 110), Vector3.new(22, 13, 26))
signpost("SignShop", "SHOP", Color3.fromRGB(110, 210, 255), Vector3.new(23, 14, 38))

-- 4. The upgrade board reads SHOP on both faces.
local board = garden:FindFirstChild("UpgradeBoard")
if board then
	for _, c in board:GetChildren() do
		if c:IsA("SurfaceGui") then
			c:Destroy()
		end
	end
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.PixelsPerStud = 30
		gui.LightInfluence = 0
		gui.Parent = board
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.fromScale(1, 0.6)
		title.Font = Enum.Font.FredokaOne
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(255, 214, 80)
		title.Text = "SHOP"
		title.Parent = gui
		local sub = title:Clone()
		sub.Position = UDim2.fromScale(0, 0.6)
		sub.Size = UDim2.fromScale(1, 0.3)
		sub.TextColor3 = Color3.fromRGB(255, 240, 220)
		sub.Text = "Upgrades inside"
		sub.Parent = gui
	end
end

-- 5. Warmer dusk haze and a few warm lamps where players work.
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then
	atmosphere.Color = Color3.fromRGB(232, 160, 150)
	atmosphere.Decay = Color3.fromRGB(120, 70, 120)
	atmosphere.Density = 0.36
end
for _, spec in { { -10, 30 }, { 14, 32 }, { -40, 8 } } do
	local lamp = place("post_lantern", CFrame.new(spec[1], 0, spec[2]), 1.1)
	lamp.Name = "WarmLamp"
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 80)
	light.Range = 18
	light.Brightness = 1.6
	light.Parent = lamp:FindFirstChildWhichIsA("BasePart", true)
end

-- 6. Small map: stream everything so clients always see every pyramid slot.
workspace.StreamingEnabled = false

return "polish6 done, trees removed: " .. removed
