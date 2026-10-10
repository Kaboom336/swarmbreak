--!nocheck
-- VoxelKit: Steal-an-Egg style voxel builder (uniform cubes, flat colours, top studs).
-- layers: bottom->top. Each entry is a grid string, or {grid, repeatCount}.
-- A grid string = whitespace-separated rows; row 1 is the FRONT (+Z), char 1 is -X.
-- Each char is a palette key; '.' (or a short row) is empty. Palette: "RRGGBB", "*RRGGBB" = Neon.

local function rows(s)
	local t = {}
	for r in string.gmatch(s, "%S+") do
		table.insert(t, r)
	end
	return t
end

local function build(name, voxel, layers, palette, origin)
	local v = voxel
	local model = Instance.new("Model")
	model.Name = name
	local base = CFrame.new(origin)
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 0.2, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = base
	root.Parent = model
	model.PrimaryPart = root

	-- parse + global extents
	local parsed, W, D = {}, 0, 0
	for _, e in ipairs(layers) do
		local g, n = e, 1
		if type(e) == "table" then
			g, n = e[1], e[2] or 1
		end
		local rs = rows(g)
		D = math.max(D, #rs)
		for _, r in ipairs(rs) do
			W = math.max(W, #r)
		end
		table.insert(parsed, { rs, n })
	end

	local mats = {}
	local function look(k)
		local c = palette[k]
		if not mats[k] then
			local neon = string.sub(c, 1, 1) == "*"
			local hex = neon and string.sub(c, 2) or c
			mats[k] = { Color3.fromHex(hex), neon and Enum.Material.Neon or Enum.Material.Plastic }
		end
		return mats[k][1], mats[k][2]
	end

	local count = 0
	local y0 = 0
	for _, L in ipairs(parsed) do
		local rs, n = L[1], L[2]
		local used = {}
		local function at(z, x)
			local r = rs[z]
			if not r or x > #r then
				return "."
			end
			return string.sub(r, x, x)
		end
		for z = 1, D do
			for x = 1, W do
				local ch = at(z, x)
				if ch ~= "." and palette[ch] and not used[z * 1000 + x] then
					-- run along X
					local x1 = x
					while x1 < W and at(z, x1 + 1) == ch and not used[z * 1000 + x1 + 1] do
						x1 += 1
					end
					-- extend along Z
					local z1 = z
					while z1 < D do
						local ok = true
						for xx = x, x1 do
							if at(z1 + 1, xx) ~= ch or used[(z1 + 1) * 1000 + xx] then
								ok = false
								break
							end
						end
						if not ok then
							break
						end
						z1 += 1
					end
					for zz = z, z1 do
						for xx = x, x1 do
							used[zz * 1000 + xx] = true
						end
					end
					local col, mat = look(ch)
					local p = Instance.new("Part")
					p.Name = "V"
					p.Anchored = true
					p.Material = mat
					p.Color = col
					p.TopSurface = Enum.SurfaceType.Studs
					p.BottomSurface = Enum.SurfaceType.Smooth
					p.FrontSurface = Enum.SurfaceType.Smooth
					p.BackSurface = Enum.SurfaceType.Smooth
					p.LeftSurface = Enum.SurfaceType.Smooth
					p.RightSurface = Enum.SurfaceType.Smooth
					p.Size = Vector3.new((x1 - x + 1) * v, n * v, (z1 - z + 1) * v)
					local cx = ((x + x1) / 2 - 0.5 - W / 2) * v
					local cz = (D / 2 - ((z + z1) / 2 - 0.5)) * v
					local cy = (y0 + n / 2) * v
					p.CFrame = base * CFrame.new(cx, cy, cz)
					p.Parent = model
					count += 1
				end
			end
		end
		y0 += n
	end
	return model, count
end

-- PumpkinPup: 9 wide x 12 long x 9 tall @0.6. Jack-o'-lantern head, brown pup body, floppy ears, tail up.
local PUP_PAL = {
	o = "FF7A1A", -- pumpkin
	d = "D9530F", -- pumpkin rib grooves
	g = "3FA535", -- stem
	b = "7A4A26", -- pup fur
	k = "141414", -- eyes / nose
}
local PUP = {
	{ [[
. . . . .
..bb.bb..
..bb.bb..
. .
..bb.bb..
..bb.bb..
]], 2 }, -- legs
	[[
. . . .
..bbbbb..
..bbbbb..
..bbbbb..
..bbbbb..
..bbbbb..
..bbbbb..
..bbbbb..
]], -- belly
	[[
. .
..oodoo..
..oodoo..
..oodoo..
..bbbbb..
..bbbbb..
..bbbbb..
..bbbbb..
..bbbbb..
..bbbbb..
]], -- chin of pumpkin + body
	[[
...bkb...
..oodoo..
.doodood.
bdoodoodb
.doodood.
..oodoo..
..bbbbb..
..bbbbb..
..bbbbb..
..bbbbb..
..bbbbb..
....b....
]], -- muzzle + nose, ears, back
	[[
.
..okdko..
.doodood.
bdoodoodb
.doodood.
..oodoo..
. . . . .
....b....
]], -- eyes, ears, tail tip
	[[
. .
..oodoo..
..oodoo..
..oodoo..
]], -- pumpkin crown
	[[
. . .
....gg...
]], -- stem + leaf
	[[
. . .
....g....
]],
}

-- Scarecrow guard: 13 wide (arms out) x 7 deep x 16 tall @1.0.
local SC_PAL = {
	o = "FF7A1A",
	d = "D9530F",
	k = "141414",
	y = "E8C040", -- straw (hat, hands)
	r = "C8302A", -- shirt + hat band
	p = "2F5FD0", -- pants
	n = "5E3A1E", -- boots + rope belt
}
local SC = {
	[[
.
....nn.nn....
....nn.nn....
....nn.nn....
....nn.nn....
]], -- boots, toes forward
	{ [[
. .
....pp.pp....
....pp.pp....
....pp.pp....
]], 2 }, -- legs
	[[
. .
....nnnnn....
....nnnnn....
....nnnnn....
]], -- rope belt
	{ [[
. .
....rrrrr....
....rrrrr....
....rrrrr....
]], 2 }, -- shirt
	{ [[
. .
....rrrrr....
yrrrrrrrrrrry
....rrrrr....
]], 2 }, -- arms straight out, straw hands
	[[
. .
....oodoo....
....oodoo....
....oodoo....
]], -- pumpkin base
	{ [[
.
....oodoo....
...doodood...
...doodood...
...doodood...
....oodoo....
]], 2 },
	[[
.
....okdko....
...doodood...
...doodood...
...doodood...
....oodoo....
]], -- tiny square eyes
	[[
. .
....oodoo....
....oodoo....
....oodoo....
]], -- pumpkin top
	[[
...yyyyyyy...
..yyyyyyyyy..
..yyyyyyyyy..
..yyyyyyyyy..
..yyyyyyyyy..
..yyyyyyyyy..
...yyyyyyy...
]], -- hat brim
	[[
.
....rrrrr....
....rrrrr....
....rrrrr....
....rrrrr....
....rrrrr....
]], -- hat band
	[[
. .
.....yyy.....
.....yyy.....
.....yyy.....
]], -- hat crown
}

local folder = workspace:FindFirstChild("VoxelTest")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "VoxelTest"
	folder.Parent = workspace
end
for _, n in ipairs({ "PumpkinPup", "Scarecrow" }) do
	local old = folder:FindFirstChild(n)
	if old then
		old:Destroy()
	end
end

local pup, pc = build("PumpkinPup", 0.6, PUP, PUP_PAL, Vector3.new(1490, 0, 100))
pup.Parent = folder
local sc, sn = build("Scarecrow", 1.0, SC, SC_PAL, Vector3.new(1520, 0, 100))
sc.Parent = folder

return string.format("VoxelTest: PumpkinPup %d parts, Scarecrow %d parts", pc, sn)
