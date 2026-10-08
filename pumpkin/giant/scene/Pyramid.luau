-- Arena round 5 scene: replace the round altar and dishes with a 4-tier Pumpkin Pyramid.
-- 40 slots (16/12/8/4) on the tier rims, the giant on top, offering stones on each side,
-- a progress board, the Witch's Cauldron and the upgrade board. Run in Edit mode.
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KIT_SCALE = 2.5
local kit = ServerStorage.KitSource
local garden = workspace.Garden
local art = garden.Art
local CENTER = Vector3.new(0, 0, -18)

local function place(name, cf, scale, parent)
	local m = kit[name]:Clone()
	m:ScaleTo(KIT_SCALE * (scale or 1))
	local bcf, bsize = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(bcf.X, bcf.Y - bsize.Y / 2, bcf.Z)
	m:PivotTo(cf)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	m.Parent = parent or art
	return m
end
local function at(x, z, yaw, y)
	return CFrame.new(x, y or 0, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end
local function addFlame(model, lit)
	local _, size = model:GetBoundingBox()
	local top = model:GetPivot().Position + Vector3.new(0, size.Y + 0.25, 0)
	local f = Instance.new("Part")
	f.Name = "Flame"
	f.Shape = Enum.PartType.Ball
	f.Material = Enum.Material.Neon
	f.Color = Color3.fromRGB(255, 170, 60)
	f.Size = Vector3.new(0.45, 0.7, 0.45)
	f.Anchored = true
	f.CanCollide = false
	f.CastShadow = false
	f.Transparency = lit and 0 or 1
	f.CFrame = CFrame.new(top)
	f.Parent = model
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 160, 70)
	l.Range = 8
	l.Brightness = 0.8
	l.Enabled = lit
	l.Parent = f
end

-- 1. Clear the old altar, dishes and anything standing where the pyramid goes.
for _, name in { "Sockets", "AltarStep", "Altar", "AltarTop", "GiantCollider", "Pyramid", "GiantPlain", "ProgressBoard", "Cauldron", "UpgradeBoard" } do
	local old = garden:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end
for _, m in art:GetChildren() do
	local p = m:GetPivot().Position
	local flat = Vector3.new(p.X, 0, p.Z) - CENTER
	if math.abs(flat.X) < 33 and math.abs(flat.Z) < 33 and not string.match(m.Name, "^path_") and m.Name ~= "arch" then
		m:Destroy()
	end
end
for _, m in art:GetChildren() do
	if m.Name == "arch" then
		m:PivotTo(at(0, 26, 0))
	end
	if m.Name == "shrine_candles" then
		m:PivotTo(at(-34, -50, 30))
	end
end

-- 2. Pyramid tiers.
local pyramid = Instance.new("Model")
pyramid.Name = "Pyramid"
pyramid.Parent = garden
local TIERS = {
	{ width = 48, top = 4, perSide = 4, color = Color3.fromRGB(84, 76, 98) },
	{ width = 38, top = 8, perSide = 3, color = Color3.fromRGB(96, 88, 112) },
	{ width = 28, top = 12, perSide = 2, color = Color3.fromRGB(108, 98, 124) },
	{ width = 18, top = 16, perSide = 1, color = Color3.fromRGB(120, 110, 138) },
}
for i, tier in TIERS do
	local block = Instance.new("Part")
	block.Name = "Tier" .. i
	block.Anchored = true
	block.Material = Enum.Material.Slate
	block.Color = tier.color
	local h = tier.top + 2
	block.Size = Vector3.new(tier.width, h, tier.width)
	block.CFrame = CFrame.new(CENTER + Vector3.new(0, tier.top - h / 2, 0))
	block.Parent = pyramid
	local trim = Instance.new("Part")
	trim.Name = "Trim" .. i
	trim.Anchored = true
	trim.Material = Enum.Material.Slate
	trim.Color = Color3.fromRGB(52, 44, 62)
	trim.Size = Vector3.new(tier.width + 0.6, 0.6, tier.width + 0.6)
	trim.CFrame = CFrame.new(CENTER + Vector3.new(0, tier.top - 0.3, 0))
	trim.Parent = pyramid
	-- Corner candles light up when the tier is finished.
	local half = tier.width / 2 - 1.2
	for _, c in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		local candle = place("candle_triple", at(CENTER.X + c[1] * half, CENTER.Z + c[2] * half, 45, tier.top), 1.1, pyramid)
		candle.Name = "TierCandle" .. i
		addFlame(candle, false)
	end
end

-- 3. Slots on each tier's rim, filled bottom tier first.
local slots = Instance.new("Folder")
slots.Name = "Slots"
slots.Parent = pyramid
local jackMesh = kit.pumpkin_orange_jackolantern:FindFirstChildWhichIsA("MeshPart", true)
local SLOT_WIDTH = 4.4
local index = 0
for t, tier in TIERS do
	local nextWidth = TIERS[t + 1] and TIERS[t + 1].width or 0
	local ring = (tier.width / 2 + nextWidth / 2) / 2
	if t == #TIERS then
		ring = tier.width / 2 - 2.6
	end
	local spacing = (tier.width - 6) / math.max(tier.perSide, 1)
	for side = 0, 3 do
		local yaw = side * math.pi / 2
		local outward = Vector3.new(math.sin(yaw), 0, math.cos(yaw))
		local along = Vector3.new(outward.Z, 0, -outward.X)
		for k = 1, tier.perSide do
			local offset = (k - (tier.perSide + 1) / 2) * spacing
			if t == #TIERS then
				offset = 0
			end
			index += 1
			local pos = CENTER + outward * ring + along * offset + Vector3.new(0, tier.top, 0)
			local slot = Instance.new("Part")
			slot.Name = string.format("Slot%02d", index)
			slot.Anchored = true
			slot.CanCollide = false
			slot.Transparency = 1
			slot.Size = Vector3.new(SLOT_WIDTH, 0.2, SLOT_WIDTH)
			slot.CFrame = CFrame.lookAt(pos, pos + outward)
			slot:SetAttribute("Tier", t)
			slot:SetAttribute("Index", index)
			slot.Parent = slots
			local ghost = jackMesh:Clone()
			ghost.Name = "Ghost"
			ghost.Anchored = true
			ghost.CanCollide = false
			ghost.CanQuery = false
			ghost.CastShadow = false
			ghost.Material = Enum.Material.ForceField
			ghost.Color = Color3.fromRGB(255, 160, 60)
			ghost.Transparency = 0.45
			ghost.Size = jackMesh.Size * (SLOT_WIDTH / jackMesh.Size.X)
			ghost.CFrame = slot.CFrame * CFrame.new(0, ghost.Size.Y / 2, 0)
			ghost.Parent = slot
		end
	end
end

-- 4. The giant sits on a plinth above the top tier, so as it grows it overhangs the
-- slots instead of swallowing them. It starts as a plain pumpkin and becomes a carved jack.
local GIANT_BASE_Y = 22
local plinth = Instance.new("Part")
plinth.Name = "Plinth"
plinth.Shape = Enum.PartType.Cylinder
plinth.Anchored = true
plinth.Material = Enum.Material.Slate
plinth.Color = Color3.fromRGB(70, 60, 84)
plinth.Size = Vector3.new(GIANT_BASE_Y - 16, 7, 7)
plinth.CFrame = CFrame.new(CENTER + Vector3.new(0, (16 + GIANT_BASE_Y) / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
plinth.Parent = pyramid
local giant = garden.Giant
giant.Size = jackMesh.Size * 8
giant.CFrame = CFrame.new(CENTER + Vector3.new(0, GIANT_BASE_Y + giant.Size.Y / 2, 0)) * CFrame.Angles(0, math.rad(180), 0)
giant.Transparency = 1
local plainMesh = kit.pumpkin_orange:FindFirstChildWhichIsA("MeshPart", true)
local plain = plainMesh:Clone()
plain.Name = "GiantPlain"
plain.Anchored = true
plain.CanCollide = false
plain.Size = plainMesh.Size * (giant.Size.X / plainMesh.Size.X)
plain.CFrame = CFrame.new(CENTER + Vector3.new(0, GIANT_BASE_Y + plain.Size.Y / 2, 0))
plain.Parent = garden
local gold = ReplicatedStorage:FindFirstChild("GiantGold")
if gold then
	gold.Size = giant.Size
end

-- 5. Offering stones at the foot of each side: hold E here to place what you carry.
local offerings = Instance.new("Folder")
offerings.Name = "Offerings"
offerings.Parent = pyramid
for side = 0, 3 do
	local yaw = side * math.pi / 2
	local outward = Vector3.new(math.sin(yaw), 0, math.cos(yaw))
	local pos = CENTER + outward * (TIERS[1].width / 2 + 3.5)
	local stone = place("plaque_candles", CFrame.lookAt(pos, pos + outward), 1.2, offerings)
	stone.Name = "Offering"
	local pad = Instance.new("Part")
	pad.Name = "Pad"
	pad.Anchored = true
	pad.CanCollide = false
	pad.Transparency = 1
	pad.Size = Vector3.new(6, 1, 6)
	pad.CFrame = CFrame.new(pos + outward * 2 + Vector3.new(0, 1, 0))
	pad.Parent = stone
	addFlame(stone, true)
end

-- 6. Progress board on posts, left of the pyramid, facing the spawn.
local board = Instance.new("Part")
board.Name = "ProgressBoard"
board.Anchored = true
board.Material = Enum.Material.Wood
board.Color = Color3.fromRGB(88, 58, 38)
board.Size = Vector3.new(20, 7, 0.8)
board.CFrame = CFrame.new(-31, 10, 8) * CFrame.Angles(0, math.rad(200), 0)
board.Parent = garden
local gui = Instance.new("SurfaceGui")
gui.Name = "Gui"
gui.Face = Enum.NormalId.Back
gui.PixelsPerStud = 40
gui.LightInfluence = 0
gui.Parent = board
local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.fromScale(1, 0.55)
title.Font = Enum.Font.FredokaOne
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255, 196, 70)
title.Text = "GIANT #1"
title.Parent = gui
local count = title:Clone()
count.Name = "Count"
count.Position = UDim2.fromScale(0, 0.52)
count.Size = UDim2.fromScale(1, 0.42)
count.TextColor3 = Color3.fromRGB(255, 240, 220)
count.Text = "0 / 40  ·  Tier 1"
count.Parent = gui
for _, x in { -8, 8 } do
	local post = Instance.new("Part")
	post.Anchored = true
	post.Material = Enum.Material.Wood
	post.Color = Color3.fromRGB(70, 46, 30)
	post.Size = Vector3.new(0.8, 13.5, 0.8)
	post.CFrame = board.CFrame * CFrame.new(x, -3, 0.8)
	post.Parent = board
end

-- 7. Witch's Cauldron (Strength) on the right side of the path, and the upgrade board beside it.
local cauldron = Instance.new("Model")
cauldron.Name = "Cauldron"
cauldron.Parent = garden
local CPOS = Vector3.new(22, 0, 26)
local pot = Instance.new("Part")
pot.Name = "Pot"
pot.Shape = Enum.PartType.Cylinder
pot.Anchored = true
pot.Material = Enum.Material.Metal
pot.Color = Color3.fromRGB(34, 30, 40)
pot.Size = Vector3.new(4.5, 7, 7)
pot.CFrame = CFrame.new(CPOS + Vector3.new(0, 2.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
pot.Parent = cauldron
local rim = pot:Clone()
rim.Name = "Rim"
rim.Size = Vector3.new(0.8, 7.8, 7.8)
rim.CFrame = CFrame.new(CPOS + Vector3.new(0, 4.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
rim.Parent = cauldron
local brew = pot:Clone()
brew.Name = "Brew"
brew.Material = Enum.Material.Neon
brew.Color = Color3.fromRGB(120, 230, 80)
brew.Size = Vector3.new(0.3, 6.2, 6.2)
brew.CFrame = CFrame.new(CPOS + Vector3.new(0, 4.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
brew.Parent = cauldron
local bubbles = Instance.new("ParticleEmitter")
bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
bubbles.Color = ColorSequence.new(Color3.fromRGB(150, 255, 110))
bubbles.LightEmission = 1
bubbles.Size = NumberSequence.new(0.6, 0)
bubbles.Lifetime = NumberRange.new(0.8, 1.4)
bubbles.Rate = 10
bubbles.Speed = NumberRange.new(2, 4)
bubbles.EmissionDirection = Enum.NormalId.Right
bubbles.Parent = brew
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(120, 255, 90)
glow.Range = 14
glow.Brightness = 1.5
glow.Parent = brew
for _, a in { 0, 120, 240 } do
	local leg = Instance.new("Part")
	leg.Anchored = true
	leg.Material = Enum.Material.Metal
	leg.Color = Color3.fromRGB(34, 30, 40)
	leg.Size = Vector3.new(0.8, 1.6, 0.8)
	leg.CFrame = CFrame.new(CPOS + Vector3.new(math.cos(math.rad(a)) * 2.6, 0.4, math.sin(math.rad(a)) * 2.6))
	leg.Parent = cauldron
end
local spoon = Instance.new("Part")
spoon.Name = "Spoon"
spoon.Anchored = true
spoon.Material = Enum.Material.Wood
spoon.Color = Color3.fromRGB(120, 80, 50)
spoon.Size = Vector3.new(0.5, 7, 0.5)
spoon.CFrame = CFrame.new(CPOS + Vector3.new(1, 6, 0)) * CFrame.Angles(0, 0, math.rad(-20))
spoon.Parent = cauldron
local stirPad = Instance.new("Part")
stirPad.Name = "StirPad"
stirPad.Anchored = true
stirPad.CanCollide = false
stirPad.Transparency = 1
stirPad.Size = Vector3.new(2, 2, 2)
stirPad.CFrame = CFrame.new(CPOS + Vector3.new(0, 3, 0))
stirPad.Parent = cauldron
local sign = place("plaque", at(CPOS.X - 5, CPOS.Z + 4, -60), 1, cauldron)
sign.Name = "CauldronPlaque"

local up = Instance.new("Part")
up.Name = "UpgradeBoard"
up.Anchored = true
up.Material = Enum.Material.Wood
up.Color = Color3.fromRGB(88, 58, 38)
up.Size = Vector3.new(12, 9, 0.8)
up.CFrame = CFrame.new(23, 6, 38) * CFrame.Angles(0, math.rad(-120), 0)
up.Parent = garden
for _, x in { -5, 5 } do
	local post = Instance.new("Part")
	post.Anchored = true
	post.Material = Enum.Material.Wood
	post.Color = Color3.fromRGB(70, 46, 30)
	post.Size = Vector3.new(0.8, 10, 0.8)
	post.CFrame = up.CFrame * CFrame.new(x, -1.5, 0.8)
	post.Parent = up
end

-- 8. Templates for the scripts.
local templates = ServerStorage.KitTemplates
local oldGhost = ReplicatedStorage:FindFirstChild("GhostJack")
if oldGhost then
	oldGhost:Destroy()
end

return string.format("pyramid built: %d slots", index)
