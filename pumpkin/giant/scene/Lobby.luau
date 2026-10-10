-- Lobby rebuild (LOBBY-SPEC.md). Run in Studio Edit via execute_luau. Rebuilds workspace.Garden.Patches
-- as Steal an Egg style pens (X-brace fence, 10 round wooden discs = Plot Index 1..10, navy sign),
-- the King centrepiece, paths, pennants and decor. Keeps every contract name.
local O = Vector3.new(1500, 0, 0)
local G = workspace.Garden
local K = game.ServerStorage.KitSource
local function hex(h) return Color3.fromHex(h) end
local function part(parent, size, cf, color, mat, name, shape)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Name = name or "Part"
	p.Parent = parent
	return p
end
local CYL = Enum.PartType.Cylinder
local UP = CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis X -> Y

-- 1. Clear old pens and hub clutter.
G.Patches:ClearAllChildren()
local hub = G.Art.Decor:FindFirstChild("Hub")
if hub then hub:Destroy() end
for _, p in G.Art:GetChildren() do
	if p.Name == "SpawnPill" then p:Destroy() end
end
for _, n in { "LobbyDecor", "Paths", "Centre" } do
	local f = G.Art:FindFirstChild(n)
	if f then f:Destroy() end
end
local decor = Instance.new("Folder", G.Art)
decor.Name = "LobbyDecor"

-- 2. Pens.
local W, D = 36, 30
local pens = {
	{ 1428, 17, 0 }, { 1476, 17, 0 }, { 1524, 17, 0 }, { 1572, 17, 0 },
	{ 1397, 56, 1 }, { 1603, 56, -1 }, { 1397, 104, 1 }, { 1603, 104, -1 },
}
local order = { 2, 3, 1, 4, 5, 6, 7, 8 }
local RAIL, POST = hex("#8E4312"), hex("#40303A")
for i, pd in pens do
	local c = Vector3.new(pd[1], 0, pd[2])
	local face = pd[3] == 0 and Vector3.new(0, 0, 1) or Vector3.new(pd[3], 0, 0)
	local cf = CFrame.lookAt(c, c + face) -- -Z = toward the centre (front)
	local function at(x, y, z) return cf * CFrame.new(x, y, -z) end -- z>0 = front
	local pen = Instance.new("Model", G.Patches)
	pen.Name = "Pen" .. i
	pen:SetAttribute("Order", order[i])
	pen:SetAttribute("Id", i)
	local soil = part(pen, Vector3.new(W, 0.2, D), at(0, 0.1, 0), hex("#6CC232"), nil, "Soil")
	soil.TopSurface = Enum.SurfaceType.Studs
	-- X-brace fence on back + sides, front open in the middle (10 studs).
	local function bay(a, b)
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		for _, h in { 0.8, 4.2 } do
			part(pen, Vector3.new(0.6, 0.6, len), CFrame.lookAt(mid + Vector3.new(0, h, 0), b + Vector3.new(0, h, 0)), RAIL, nil, "Rail")
		end
		local diag = math.sqrt(len * len + 3.4 * 3.4)
		local ang = math.atan2(3.4, len)
		for _, s in { 1, -1 } do
			local cfm = CFrame.lookAt(mid + Vector3.new(0, 2.5, 0), b + Vector3.new(0, 2.5, 0)) * CFrame.Angles(s * ang, 0, 0)
			part(pen, Vector3.new(0.45, 0.45, diag), cfm, RAIL, nil, "Brace")
		end
		local p = part(pen, Vector3.new(1, 5.5, 1), CFrame.new(a + Vector3.new(0, 2.75, 0)), POST, nil, "Post")
		p.TopSurface = Enum.SurfaceType.Studs
	end
	local function run(x0, z0, x1, z1, gapCentre)
		local A, B = at(x0, 0, z0).Position, at(x1, 0, z1).Position
		local len = (B - A).Magnitude
		local n = math.max(1, math.round(len / 8))
		for k = 0, n - 1 do
			local a = A + (B - A) * (k / n)
			local b = A + (B - A) * ((k + 1) / n)
			if not (gapCentre and ((a + b) / 2 - (A + B) / 2).Magnitude < 5) then
				bay(a, b)
			end
		end
		local p = part(pen, Vector3.new(1, 5.5, 1), CFrame.new(B + Vector3.new(0, 2.75, 0)), POST, nil, "Post")
		p.TopSurface = Enum.SurfaceType.Studs
	end
	run(-W / 2, -D / 2, W / 2, -D / 2) -- back
	run(-W / 2, -D / 2, -W / 2, D / 2) -- left
	run(W / 2, -D / 2, W / 2, D / 2) -- right
	run(-W / 2, D / 2, W / 2, D / 2, true) -- front with gate
	-- 10 wooden discs (Plot parts, Index 1..10) in a loose 2x5, back two rows; front strip for pets.
	local rng = Random.new(i * 7)
	local idx = 0
	for _, z in { -9, 1 } do
		for k = -2, 2 do
			idx += 1
			local x = k * 7 + rng:NextNumber(-1, 1)
			local zz = z + rng:NextNumber(-1, 1)
			local base = at(x, 0, -zz).Position
			part(pen, Vector3.new(0.5, 7.4, 7.4), CFrame.new(base + Vector3.new(0, 0.3, 0)) * UP, hex("#6B4A2F"), Enum.Material.Wood, "DiscRim", CYL)
			local plot = part(pen, Vector3.new(0.3, 6.6, 6.6), CFrame.new(base + Vector3.new(0, 0.45, 0)) * UP, hex("#92674A"), Enum.Material.Wood, "Plot", CYL)
			plot:SetAttribute("Index", idx)
		end
	end
	-- Navy sign front-left.
	local sp = Instance.new("Model", pen)
	sp.Name = "SignPost"
	local g = at(-W / 2 + 4, 0, D / 2 + 2).Position
	part(sp, Vector3.new(0.8, 6, 0.8), CFrame.new(g + Vector3.new(0, 3, 0)), hex("#18294A"), nil, "Pole")
	local board = part(sp, Vector3.new(7, 4.5, 0.5), CFrame.lookAt(g + Vector3.new(0, 7.5, 0), g + Vector3.new(0, 7.5, 0) + face), hex("#18294A"), nil, "Board")
	local bar = part(sp, Vector3.new(7, 1, 0.55), CFrame.lookAt(g + Vector3.new(0, 5.6, 0), g + Vector3.new(0, 5.6, 0) + face), hex("#C20A1A"), nil, "Bar")
	local bb = Instance.new("BillboardGui", board)
	bb.Name = "OwnerSign"
	bb.Size = UDim2.fromScale(7, 2)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.MaxDistance = 140
	bb.LightInfluence = 0
	local lab = Instance.new("TextLabel", bb)
	lab.Name = "Label"
	lab.Size = UDim2.fromScale(1, 1)
	lab.BackgroundTransparency = 1
	lab.Font = Enum.Font.FredokaOne
	lab.TextScaled = true
	lab.TextColor3 = Color3.new(1, 1, 1)
	lab.Text = "Free base"
	Instance.new("UIStroke", lab).Thickness = 3
	task.wait()
end

-- 3. Centrepiece: King on a 3-tier slate plinth over a purple swirl pool.
local centre = Instance.new("Folder", G.Art)
centre.Name = "Centre"
local KC = Vector3.new(1500, 0, 70)
part(centre, Vector3.new(0.3, 40, 40), CFrame.new(KC + Vector3.new(0, 0.15, 0)) * UP, hex("#6A2BC2"), Enum.Material.Neon, "SwirlPool", CYL).Transparency = 0.3
for t, w in { 34, 26, 18 } do
	local tier = part(centre, Vector3.new(w, 2, w), CFrame.new(KC + Vector3.new(0, t * 2 - 1, 0)), hex("#4A4458"), Enum.Material.Slate, "Tier" .. t)
	tier.TopSurface = Enum.SurfaceType.Studs
end
local light = Instance.new("PointLight", centre:FindFirstChild("SwirlPool"))
light.Color = hex("#B060FF")
light.Range = 30
light.Brightness = 2
local M = G.Market
local shiftTo = KC + Vector3.new(0, 6, 0)
local jf = M:FindFirstChild("KingFace")
if jf then
	local d = shiftTo - Vector3.new(jf.Position.X, 0, jf.Position.Z) * Vector3.new(1, 0, 1)
	d = Vector3.new(d.X, 0, d.Z)
	local cur = Vector3.new(jf.Position.X, 0, jf.Position.Z)
	local delta = Vector3.new(KC.X - cur.X, 0, KC.Z - cur.Z)
	for _, n in { "Plinth", "MeterRing", "GiantJack", "KingFace", "KingGlow", "SignJack" } do
		local p = M:FindFirstChild(n)
		if p then
			if p:IsA("BasePart") then p.CFrame = p.CFrame + delta + Vector3.new(0, 6, 0) else p:PivotTo(p:GetPivot() + delta + Vector3.new(0, 6, 0)) end
		end
	end
end
M.Plaza.CFrame = CFrame.new(KC + Vector3.new(0, -1, 0)) * UP

-- 4. Paths: main path from spawn to safe line + ring around the King + spurs.
local paths = Instance.new("Folder", G.Art)
paths.Name = "Paths"
local STONE, EDGE = hex("#4B4560"), hex("#E8701A")
local function strip(a, b, w)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	part(paths, Vector3.new(w + 1, 0.12, len), CFrame.lookAt(mid + Vector3.new(0, 0.06, 0), b + Vector3.new(0, 0.06, 0)), EDGE, nil, "PathEdge")
	local s = part(paths, Vector3.new(w, 0.16, len), CFrame.lookAt(mid + Vector3.new(0, 0.08, 0), b + Vector3.new(0, 0.08, 0)), STONE, Enum.Material.Cobblestone, "Path")
	s.CanCollide = true
end
strip(Vector3.new(1500, 0, 102), Vector3.new(1500, 0, 150), 14)
for k = 0, 23 do
	local a0, a1 = k / 24 * math.pi * 2, (k + 1) / 24 * math.pi * 2
	strip(KC + Vector3.new(math.cos(a0) * 32, 0, math.sin(a0) * 32), KC + Vector3.new(math.cos(a1) * 32, 0, math.sin(a1) * 32), 10)
end
for _, pd in pens do
	local c = Vector3.new(pd[1], 0, pd[2])
	local face = pd[3] == 0 and Vector3.new(0, 0, 1) or Vector3.new(pd[3], 0, 0)
	local gate = c + face * (D / 2 + 1)
	local toward = (Vector3.new(KC.X, 0, KC.Z) - gate).Unit
	local stop = Vector3.new(KC.X, 0, KC.Z) - toward * 37
	strip(gate, stop, 8)
end
task.wait()

-- 5. Pennants over stalls and decor.
local function pennant(at, text)
	local p = part(decor, Vector3.new(18, 6, 0.4), CFrame.new(at), hex("#FF9A3C"), nil, "Pennant")
	local sg = Instance.new("SurfaceGui", p)
	sg.Face = Enum.NormalId.Back
	sg.PixelsPerStud = 30
	local l = Instance.new("TextLabel", sg)
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UIStroke", l).Thickness = 4
	for _, dx in { -9, 9 } do
		part(decor, Vector3.new(0.6, 22, 0.6), CFrame.new(at + Vector3.new(dx, -11 + 3, 0.4)), hex("#3B2350"), nil, "PennantPole")
	end
end
local function stallPos(n)
	local m = M:FindFirstChild(n)
	if m then local cfm = m:GetBoundingBox() return cfm.Position end
end
for n, t in { Seeds = "SHOP", Upgrades = "UPGRADES", Sell = "SELL" } do
	local p = stallPos(n)
	if p then pennant(Vector3.new(p.X, 22, p.Z - 6), t) end
end
local function placeKit(name, at, h)
	local src = K:FindFirstChild(name)
	if not src then return end
	local m = src:Clone()
	local _, s = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * (h / s.Y))
	local cf2, s2 = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + (at + Vector3.new(0, s2.Y / 2, 0) - cf2.Position))
	for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.Anchored = true end end
	m.Parent = decor
end
for k = 0, 23, 3 do
	local a = k / 24 * math.pi * 2
	placeKit((k % 2 == 0) and "pumpkin_orange_jackolantern" or "gravestone", KC + Vector3.new(math.cos(a) * 39, 0, math.sin(a) * 39), 3)
end
for _, z in { 110, 125, 140 } do
	placeKit("post_lantern", Vector3.new(1490, 0, z), 9)
	placeKit("post_lantern", Vector3.new(1510, 0, z), 9)
end
for _, p in { { 1385, -2 }, { 1615, -2 }, { 1385, 140 }, { 1615, 140 } } do
	placeKit("tree_dead_large", Vector3.new(p[1], 0, p[2]), 20)
end
-- Spawn on the path.
local spawn = G:FindFirstChild("SpawnLocation")
if spawn then spawn.CFrame = CFrame.new(1500, 0.3, 130) spawn.Size = Vector3.new(10, 0.3, 8) end
return "lobby built " .. #G.Patches:GetChildren() .. " pens"
