--!nocheck
-- VoxelModels: every pet + guard built with the VoxelKit builder (uniform cubes, flat colours, top studs).
-- Run in the Studio command bar: builds ServerStorage.VoxelOut/{Pets,Guards} at the origin and returns part counts.
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

-- ===== Canvas helpers: author in 3D, export to build() layers =====
-- x = 1..W left->right seen from the front, y = 1..H bottom->top, z = 1..D (z = 1 is the FRONT / face side).
local function Cv(W, D, H)
	local c = { W = W, D = D, H = H, g = {} }
	for y = 1, H do
		local L = {}
		c.g[y] = L
		for z = 1, D do
			local R = {}
			L[z] = R
			for x = 1, W do
				R[x] = "."
			end
		end
	end
	return c
end
local function S(c, ch, x, y, z) -- set one voxel
	if x >= 1 and x <= c.W and y >= 1 and y <= c.H and z >= 1 and z <= c.D then
		c.g[y][z][x] = ch
	end
end
local function B(c, ch, x0, x1, y0, y1, z0, z1) -- fill box (inclusive)
	for y = y0, y1 do
		for z = z0, z1 do
			for x = x0, x1 do
				S(c, ch, x, y, z)
			end
		end
	end
end
local function M(c, ch, x0, x1, y0, y1, z0, z1) -- box + its mirror across the X centre
	B(c, ch, x0, x1, y0, y1, z0, z1)
	B(c, ch, c.W + 1 - x1, c.W + 1 - x0, y0, y1, z0, z1)
end
local function E(c, ch, cx, cy, cz, rx, ry, rz, p) -- super-ellipsoid
	p = p or 2
	for y = 1, c.H do
		for z = 1, c.D do
			for x = 1, c.W do
				if math.abs((x - cx) / rx) ^ p + math.abs((y - cy) / ry) ^ p + math.abs((z - cz) / rz) ^ p <= 1 then
					c.g[y][z][x] = ch
				end
			end
		end
	end
end
local function F(c, ch, x, y) -- paint the front-most filled voxel at (x, y)
	if y < 1 or y > c.H then
		return
	end
	for z = 1, c.D do
		if c.g[y][z][x] ~= "." then
			c.g[y][z][x] = ch
			return
		end
	end
end
local function FM(c, ch, x, y)
	F(c, ch, x, y)
	F(c, ch, c.W + 1 - x, y)
end
local function RC(c, from, to, f) -- recolour voxels of `from` where f(x, y, z)
	for y = 1, c.H do
		for z = 1, c.D do
			for x = 1, c.W do
				if c.g[y][z][x] == from and f(x, y, z) then
					c.g[y][z][x] = to
				end
			end
		end
	end
end
local function P(c, x0, ytop, z, pat, mirror) -- paint a front-view picture (rows top->bottom) on plane z
	for i, row in ipairs(pat) do
		for j = 1, #row do
			local ch = string.sub(row, j, j)
			if ch ~= "." then
				S(c, ch, x0 + j - 1, ytop - i + 1, z)
				if mirror then
					S(c, ch, c.W - (x0 + j - 1) + 1, ytop - i + 1, z)
				end
			end
		end
	end
end
local function OUT(c) -- canvas -> build() layers, stacking identical consecutive layers
	local layers, prev = {}, nil
	for y = 1, c.H do
		local rs = {}
		for z = 1, c.D do
			rs[z] = table.concat(c.g[y][z])
		end
		local s = table.concat(rs, "\n")
		if prev and prev[1] == s then
			prev[2] += 1
		else
			prev = { s, 1 }
			table.insert(layers, prev)
		end
	end
	return layers
end

local ALL = {}
local function add(group, name, voxel, layers, pal)
	table.insert(ALL, { group, name, voxel, layers, pal })
end

add("Pets", "PumpkinPup", 0.6, PUP, PUP_PAL)
add("Guards", "Scarecrow", 1.0, SC, SC_PAL)

-- ===================== PETS (voxel 0.6) =====================

-- GoldenPup: PumpkinPup recolour, gold fur
add("Pets", "GoldenPup", 0.6, PUP, { o = "FF7A1A", d = "D9530F", g = "3FA535", b = "E8C040", k = "141414" })

-- Crow: black crow standing, orange beak + feet, tiny straw hat
do
	local c = Cv(8, 11, 14)
	M(c, "o", 3, 3, 1, 2, 6, 6) -- legs
	M(c, "o", 3, 3, 1, 1, 4, 5) -- toes forward
	B(c, "k", 2, 7, 3, 7, 4, 9) -- body
	M(c, ".", 2, 2, 3, 3, 4, 4)
	M(c, ".", 2, 2, 3, 3, 9, 9)
	M(c, ".", 2, 2, 7, 7, 9, 9)
	M(c, "w", 1, 1, 4, 7, 5, 9) -- folded wings
	M(c, "w", 1, 1, 5, 6, 10, 10) -- wing tips
	B(c, "k", 3, 6, 5, 6, 10, 10) -- tail fan
	B(c, "k", 3, 6, 6, 7, 11, 11)
	B(c, "k", 2, 7, 8, 11, 3, 7) -- head
	M(c, ".", 2, 2, 11, 11, 3, 3)
	M(c, ".", 2, 2, 11, 11, 7, 7)
	M(c, ".", 2, 2, 8, 8, 7, 7)
	B(c, "o", 4, 5, 9, 10, 2, 2) -- beak
	B(c, "o", 4, 5, 9, 9, 1, 1) -- beak tip
	M(c, "e", 3, 3, 10, 10, 3, 3) -- eyes (pale on black)
	B(c, "y", 3, 6, 12, 12, 3, 6) -- hat brim
	B(c, "r", 4, 5, 13, 13, 4, 5) -- hat band
	B(c, "y", 4, 5, 14, 14, 4, 5) -- hat crown
	add("Pets", "Crow", 0.6, OUT(c), { k = "1A1A22", w = "34344A", o = "FF8A1A", e = "F2EEDF", y = "E8C040", r = "C8302A" })
end

-- Ghosty: rounded white sheet ghost, tattered hem, pink cheeks
do
	local c = Cv(9, 8, 11)
	E(c, "w", 5, 6, 4.5, 4.3, 5.2, 3.6, 2.4)
	B(c, "w", 2, 8, 1, 5, 2, 7) -- skirt
	M(c, ".", 2, 2, 1, 5, 2, 2)
	M(c, ".", 2, 2, 1, 5, 7, 7)
	for x = 2, 8, 2 do
		B(c, ".", x, x, 1, 1, 1, 8) -- tattered hem
	end
	M(c, "w", 1, 1, 4, 5, 4, 5) -- arm nubs
	RC(c, "w", "s", function(_, y)
		return y <= 2
	end)
	FM(c, "k", 4, 8) -- eyes
	FM(c, "p", 3, 7) -- cheeks
	add("Pets", "Ghosty", 0.6, OUT(c), { w = "F4F4F8", s = "DCDCEA", k = "141414", p = "FF9AC8" })
end

-- Cat body (shared by BlackCat and KingCat). ox shifts it right inside a wider canvas.
local function cat(c, ox)
	B(c, "b", 2 + ox, 7 + ox, 1, 4, 5, 9) -- haunches
	M(c, ".", 2 + ox, 2 + ox, 4, 4, 9, 9)
	M(c, "b", 3 + ox, 3 + ox, 1, 6, 3, 4) -- front legs
	M(c, "b", 3 + ox, 3 + ox, 1, 1, 2, 2) -- paws
	B(c, "b", 3 + ox, 6 + ox, 5, 8, 4, 8) -- chest
	B(c, "b", 1 + ox, 8 + ox, 9, 13, 2, 7) -- head
	M(c, ".", 1 + ox, 1 + ox, 13, 13, 2, 2)
	M(c, ".", 1 + ox, 1 + ox, 13, 13, 7, 7)
	M(c, ".", 1 + ox, 1 + ox, 9, 9, 2, 2)
	M(c, ".", 1 + ox, 1 + ox, 9, 9, 7, 7)
	B(c, "i", 4 + ox, 5 + ox, 9, 9, 1, 1) -- muzzle
	B(c, "n", 4 + ox, 5 + ox, 10, 10, 1, 1) -- nose
	M(c, "e", 3 + ox, 3 + ox, 11, 11, 2, 2) -- eyes
	M(c, "b", 1 + ox, 3 + ox, 14, 14, 3, 4) -- ears
	M(c, "b", 1 + ox, 2 + ox, 15, 15, 3, 3)
	M(c, "i", 2 + ox, 2 + ox, 14, 14, 3, 3) -- inner ear
	B(c, "b", 8 + ox, 8 + ox, 1, 1, 3, 9) -- tail wrapped on the ground
	B(c, "b", 7 + ox, 7 + ox, 1, 1, 2, 2)
end

-- BlackCat: sitting black cat, neon orange eyes
do
	local c = Cv(8, 9, 15)
	cat(c, 0)
	add("Pets", "BlackCat", 0.6, OUT(c), { b = "1C1C24", i = "3A3A48", n = "FF8AB0", e = "*FF9A1A" })
end

-- KingCat: purple cat with bat wings and a gold crown
do
	local c = Cv(14, 9, 16)
	cat(c, 3)
	P(c, 1, 13, 8, { -- left bat wing, mirrored
		"w....",
		"ww...",
		"wwww.",
		"wwwww",
		".w.ww",
		"....w",
	}, true)
	B(c, "y", 6, 9, 14, 14, 3, 6) -- crown ring
	B(c, ".", 7, 8, 14, 14, 4, 5)
	M(c, "y", 6, 6, 15, 15, 3, 3) -- crown points
	M(c, "y", 6, 6, 15, 15, 6, 6)
	B(c, "j", 7, 8, 14, 14, 3, 3) -- neon gem
	add("Pets", "KingCat", 0.6, OUT(c), {
		b = "7A3BE0",
		i = "B98AF5",
		n = "FF8AB0",
		e = "141414",
		w = "3A1A5A",
		y = "E8C040",
		j = "*FF5FB0",
	})
end

-- CandyBat: wings spread, candy-corn bands (yellow / orange / white)
do
	local c = Cv(14, 6, 14)
	B(c, "b", 6, 9, 2, 8, 2, 5) -- body
	B(c, "b", 5, 10, 9, 12, 1, 5) -- head
	M(c, ".", 5, 5, 12, 12, 1, 1)
	M(c, ".", 5, 5, 9, 9, 5, 5)
	M(c, "b", 5, 6, 13, 13, 3, 4) -- ears
	M(c, "b", 5, 5, 14, 14, 3, 3)
	for z = 3, 4 do
		P(c, 1, 12, z, {
			"w....",
			"ww...",
			"www..",
			"wwww.",
			"wwwww",
			"wwwww",
			".w.ww",
			"....w",
		}, true)
	end
	RC(c, "b", "y", function(_, y)
		return y <= 5
	end)
	RC(c, "w", "y", function(_, y)
		return y <= 5
	end)
	RC(c, "b", "o", function(_, y)
		return y <= 8
	end)
	RC(c, "w", "o", function(_, y)
		return y <= 8
	end)
	RC(c, "b", "w", function()
		return true
	end)
	M(c, "k", 6, 6, 11, 11, 1, 1) -- eyes
	M(c, "d", 7, 7, 1, 1, 3, 4) -- feet
	add("Pets", "CandyBat", 0.6, OUT(c), { y = "FFD21A", o = "FF7A1A", w = "F4F4F8", k = "141414", d = "3A2A1A" })
end

-- BonePup: skeleton dog, rib slices, skull head
do
	local c = Cv(9, 12, 12)
	M(c, "w", 3, 3, 1, 3, 3, 3) -- front legs
	M(c, "w", 3, 3, 1, 3, 9, 9) -- back legs
	M(c, "w", 3, 3, 1, 1, 2, 2) -- front paws
	B(c, "g", 4, 6, 4, 6, 3, 9) -- dark core
	for z = 3, 9, 2 do
		B(c, "w", 3, 7, 4, 6, z, z) -- ribs
	end
	B(c, "w", 5, 5, 7, 7, 3, 10) -- spine
	B(c, "w", 5, 5, 7, 8, 11, 11) -- tail
	B(c, "w", 5, 5, 9, 10, 12, 12)
	B(c, "w", 2, 8, 7, 10, 2, 5) -- skull
	M(c, ".", 2, 2, 10, 10, 2, 2)
	M(c, ".", 2, 2, 7, 7, 5, 5)
	B(c, "w", 3, 7, 7, 8, 1, 1) -- snout
	B(c, "g", 3, 7, 6, 6, 1, 3) -- jaw
	S(c, "k", 5, 8, 1) -- nose
	M(c, "k", 3, 3, 9, 9, 2, 2) -- eye sockets
	M(c, "w", 2, 2, 11, 12, 4, 4) -- bone ears
	add("Pets", "BonePup", 0.6, OUT(c), { w = "F2EEDF", g = "A8A8B4", k = "141414" })
end

-- FrostOwl: icy blue owl, white face discs, neon ice ear tufts
do
	local c = Cv(8, 8, 13)
	M(c, "y", 3, 3, 1, 1, 2, 3) -- feet
	B(c, "b", 2, 7, 2, 7, 3, 7) -- body
	M(c, ".", 2, 2, 2, 2, 3, 3)
	M(c, ".", 2, 2, 2, 2, 7, 7)
	B(c, "w", 3, 6, 3, 6, 2, 2) -- belly
	M(c, "l", 4, 4, 5, 5, 2, 2)
	M(c, "l", 3, 3, 3, 3, 2, 2)
	M(c, "d", 1, 1, 3, 7, 4, 7) -- wings
	B(c, "b", 1, 8, 8, 11, 2, 7) -- head
	M(c, ".", 1, 1, 11, 11, 2, 2)
	M(c, ".", 1, 1, 8, 8, 7, 7)
	M(c, "w", 2, 3, 9, 11, 1, 1) -- face discs
	M(c, "k", 3, 3, 10, 10, 1, 1) -- eyes
	B(c, "y", 4, 5, 8, 9, 1, 1) -- beak
	M(c, "b", 1, 2, 12, 12, 3, 5) -- ear tufts
	M(c, "n", 1, 1, 13, 13, 4, 4)
	add("Pets", "FrostOwl", 0.6, OUT(c), {
		b = "9EDCF5",
		d = "5AA8D8",
		w = "F4F4F8",
		l = "CDEFFA",
		y = "E8C040",
		k = "141414",
		n = "*BFF4FF",
	})
end

-- LavaSlime: orange slime cube, neon lava top + drips, carved pumpkin face, tiny stem
do
	local c = Cv(8, 8, 8)
	B(c, "o", 1, 8, 1, 6, 1, 8)
	M(c, ".", 1, 1, 2, 6, 1, 1)
	M(c, ".", 1, 1, 2, 6, 8, 8)
	B(c, "o", 2, 7, 7, 7, 2, 7)
	B(c, "n", 3, 6, 7, 7, 3, 6) -- lava pool on top
	M(c, "n", 2, 2, 7, 7, 4, 5)
	M(c, "n", 1, 1, 5, 6, 4, 4) -- drips
	M(c, "n", 1, 1, 6, 6, 6, 6)
	B(c, "n", 3, 3, 4, 6, 8, 8)
	B(c, "n", 6, 6, 5, 6, 8, 8)
	RC(c, "o", "d", function(_, y)
		return y == 1
	end)
	P(c, 1, 6, 1, {
		"..f..f..",
		".ff..ff.",
		"........",
		".f.ff.f.",
		"..ffff..",
	})
	B(c, "g", 4, 5, 8, 8, 4, 5) -- stem
	add("Pets", "LavaSlime", 0.6, OUT(c), { o = "FF7A1A", d = "D9530F", n = "*FF4A10", f = "*FFE11A", g = "3FA535" })
end

-- Moth: purple fore-wings with neon eye-spots, orange hind-wings, fuzzy cream head
do
	local c = Cv(12, 7, 11)
	B(c, "o", 6, 7, 2, 5, 3, 6) -- abdomen
	B(c, "c", 5, 8, 6, 6, 2, 5) -- fuzzy collar
	B(c, "c", 5, 8, 7, 9, 1, 4) -- head
	M(c, "k", 5, 5, 8, 8, 1, 1) -- eyes
	M(c, "a", 5, 5, 10, 10, 3, 3) -- antennae
	M(c, "a", 3, 4, 11, 11, 3, 3)
	M(c, "a", 6, 6, 1, 1, 3, 3) -- legs
	M(c, "a", 6, 6, 1, 1, 5, 5)
	for z = 4, 5 do
		P(c, 1, 10, z, {
			"pp...",
			"ppp..",
			"pppp.",
			"ppppp",
			"ppppp",
			".pppp",
			".pppp",
			"..ppp",
			"...pp",
		}, true)
	end
	RC(c, "p", "h", function(_, y)
		return y <= 4
	end)
	M(c, "s", 2, 3, 7, 8, 4, 4) -- eye-spots
	add("Pets", "Moth", 0.6, OUT(c), {
		p = "7A3BE0",
		h = "FF8A2A",
		o = "E8862A",
		c = "F2EEDF",
		k = "141414",
		a = "3A2A1A",
		s = "*FFB21A",
	})
end

-- Toad: low wide green toad, eye bumps, leaf hat
do
	local c = Cv(9, 9, 8)
	B(c, "g", 1, 9, 1, 3, 3, 8) -- body
	M(c, ".", 1, 1, 3, 3, 3, 3)
	M(c, ".", 1, 1, 3, 3, 8, 8)
	B(c, "g", 2, 8, 4, 4, 4, 8) -- back hump
	B(c, "g", 2, 8, 2, 5, 1, 4) -- head
	M(c, ".", 2, 2, 5, 5, 1, 1)
	RC(c, "g", "l", function(_, y, z)
		return z == 1 and y == 2
	end)
	M(c, "d", 2, 3, 1, 1, 1, 2) -- front feet
	M(c, "d", 1, 2, 1, 3, 6, 9) -- haunches
	M(c, "g", 2, 3, 6, 6, 2, 3) -- eye bumps
	M(c, "k", 3, 3, 6, 6, 2, 2) -- eyes
	B(c, "f", 4, 6, 6, 6, 2, 4) -- leaf hat
	S(c, "f", 5, 6, 1)
	S(c, "f", 5, 6, 5)
	B(c, "v", 5, 5, 6, 6, 2, 4) -- leaf vein
	S(c, "n", 5, 7, 3) -- stem
	S(c, "d", 3, 4, 6)
	S(c, "d", 7, 4, 7)
	add("Pets", "Toad", 0.6, OUT(c), {
		g = "3E8E2E",
		d = "2A6620",
		l = "C8E07A",
		k = "141414",
		f = "8FE04A",
		v = "6CC23A",
		n = "7A4A26",
	})
end

-- GummyBear: pink bear, orange belly/snout/inner ears
do
	local c = Cv(8, 7, 12)
	M(c, "p", 2, 3, 1, 2, 3, 5) -- legs
	B(c, "p", 2, 7, 3, 7, 2, 6) -- body
	M(c, ".", 2, 2, 7, 7, 2, 2)
	M(c, ".", 2, 2, 7, 7, 6, 6)
	B(c, "o", 4, 5, 3, 6, 1, 1) -- belly
	M(c, "o", 3, 3, 4, 5, 1, 1)
	M(c, "p", 1, 1, 5, 6, 3, 5) -- arms
	B(c, "p", 1, 8, 8, 11, 2, 6) -- head
	M(c, ".", 1, 1, 11, 11, 2, 2)
	M(c, ".", 1, 1, 8, 8, 2, 2)
	M(c, ".", 1, 1, 11, 11, 6, 6)
	B(c, "o", 3, 6, 8, 9, 1, 1) -- snout
	B(c, "n", 4, 5, 9, 9, 1, 1) -- nose
	M(c, "k", 3, 3, 10, 10, 2, 2) -- eyes
	M(c, "p", 1, 2, 12, 12, 3, 4) -- ears
	M(c, "o", 2, 2, 12, 12, 3, 3)
	add("Pets", "GummyBear", 0.6, OUT(c), { p = "FF5FB0", o = "FF9A3A", n = "5A2A1A", k = "141414" })
end

-- PumpkinDragon: ribbed pumpkin body, orange head + tail, green wings / horns / stem
do
	local c = Cv(13, 14, 12)
	M(c, "d", 4, 5, 1, 1, 5, 6) -- legs
	M(c, "d", 4, 5, 1, 1, 10, 11)
	B(c, "o", 4, 10, 2, 6, 5, 11) -- pumpkin body
	for _, y in ipairs({ 2, 6 }) do
		M(c, ".", 4, 4, y, y, 5, 5)
		M(c, ".", 4, 4, y, y, 11, 11)
	end
	RC(c, "o", "d", function(x)
		return x == 5 or x == 9
	end)
	B(c, "o", 6, 8, 6, 7, 4, 5) -- neck
	B(c, "o", 5, 9, 7, 10, 2, 5) -- head
	M(c, ".", 5, 5, 10, 10, 2, 2)
	B(c, "o", 6, 8, 7, 8, 1, 1) -- snout
	M(c, "k", 5, 5, 9, 9, 2, 2) -- eyes
	M(c, "g", 5, 5, 11, 11, 4, 5) -- horns
	M(c, "g", 5, 5, 12, 12, 5, 5)
	B(c, "g", 7, 7, 7, 8, 8, 8) -- pumpkin stem on the back
	S(c, "g", 8, 8, 8)
	for z = 7, 8 do
		P(c, 1, 11, z, {
			"w..",
			"ww.",
			"www",
			".ww",
			"..w",
			"..g",
		}, true)
	end
	B(c, "o", 7, 7, 3, 3, 12, 12) -- tail
	B(c, "o", 7, 7, 3, 4, 13, 13)
	S(c, "o", 7, 4, 14)
	S(c, "g", 7, 5, 14)
	add("Pets", "PumpkinDragon", 0.6, OUT(c), { o = "FF7A1A", d = "D9530F", g = "3FA535", w = "7FD14A", k = "141414" })
end

-- Kinglet: mini pumpkin king. Pumpkin head with neon carved face, gold crown, purple robe + cape, vine arms
do
	local c = Cv(9, 9, 14)
	M(c, "n", 3, 4, 1, 1, 3, 5) -- boots
	B(c, "p", 3, 7, 2, 6, 3, 6) -- robe
	B(c, "y", 3, 7, 4, 4, 3, 6) -- gold belt
	B(c, "w", 2, 8, 6, 6, 3, 7) -- ermine collar
	M(c, "k", 3, 3, 6, 6, 3, 3)
	B(c, "c", 2, 8, 2, 5, 7, 7) -- cape
	M(c, "c", 2, 2, 2, 5, 5, 6)
	B(c, "y", 2, 8, 2, 2, 7, 7)
	M(c, "v", 2, 2, 4, 5, 4, 4) -- vine arms
	M(c, "v", 1, 1, 4, 4, 3, 3)
	E(c, "o", 5, 9.5, 4.5, 4.6, 3.2, 4.1, 3) -- pumpkin head
	RC(c, "o", "d", function(x)
		return x == 2 or x == 5 or x == 8
	end)
	FM(c, "f", 3, 11) -- carved eyes
	FM(c, "f", 4, 11)
	FM(c, "f", 3, 9) -- grin
	for x = 4, 6 do
		F(c, "f", x, 8)
	end
	B(c, "y", 3, 7, 13, 13, 3, 7) -- crown
	B(c, ".", 4, 6, 13, 13, 4, 6)
	S(c, "g", 5, 13, 5)
	for _, z in ipairs({ 3, 7 }) do
		S(c, "y", 3, 14, z)
		S(c, "y", 5, 14, z)
		S(c, "y", 7, 14, z)
	end
	add("Pets", "Kinglet", 0.6, OUT(c), {
		o = "FF7A1A",
		d = "D9530F",
		f = "*FFB21A",
		y = "E8C040",
		p = "7A3BE0",
		c = "4A1E7A",
		w = "F4F4F8",
		k = "141414",
		v = "3FA535",
		g = "3FA535",
		n = "2A1A10",
	})
end

-- MysteryPumpkin: stepped octagon rings, grooves, green stem, neon "?" on the front
do
	local c = Cv(11, 11, 13)
	local rings = { 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3 }
	for y, r in ipairs(rings) do
		for z = 1, 11 do
			for x = 1, 11 do
				local dx, dz = math.abs(x - 6), math.abs(z - 6)
				if dx <= r and dz <= r and dx + dz <= 2 * r - 2 then
					c.g[y][z][x] = (dx == 3 or dz == 3) and "d" or "o"
				end
			end
		end
	end
	P(c, 4, 9, 1, {
		".fff.",
		"f...f",
		"....f",
		"..ff.",
		"..f..",
		".....",
		"..f..",
	})
	B(c, "g", 6, 6, 12, 13, 6, 6) -- stem
	S(c, "g", 7, 13, 6)
	B(c, "l", 7, 8, 12, 12, 6, 7) -- leaf
	add("Pets", "MysteryPumpkin", 0.6, OUT(c), { o = "FF7A1A", d = "D9530F", f = "*FFE11A", g = "3FA535", l = "7FD14A" })
end

-- ===================== GUARDS (voxel 1.0, Pumpkin King 1.2) =====================

-- SkeletonKnight: bone skeleton, grey helmet, red plume, sword in the right hand
do
	local c = Cv(11, 6, 20)
	M(c, "w", 4, 5, 1, 1, 2, 4) -- feet
	M(c, "w", 5, 5, 2, 6, 3, 3) -- leg bones
	M(c, "w", 4, 4, 4, 4, 3, 3) -- knees
	B(c, "w", 4, 8, 7, 7, 2, 4) -- pelvis
	B(c, "w", 6, 6, 8, 13, 4, 4) -- spine
	for _, y in ipairs({ 9, 11 }) do
		B(c, "w", 4, 8, y, y, 2, 4) -- ribs
	end
	B(c, "w", 6, 6, 9, 12, 2, 2) -- sternum
	B(c, "w", 3, 9, 13, 13, 2, 4) -- shoulders
	B(c, "w", 3, 3, 8, 12, 3, 3) -- left arm
	B(c, "w", 9, 9, 9, 12, 3, 3) -- right arm
	S(c, "w", 10, 9, 3) -- right hand
	S(c, "y", 10, 7, 3) -- pommel
	S(c, "b", 10, 8, 3) -- grip
	S(c, "b", 10, 10, 3)
	B(c, "y", 10, 10, 11, 11, 2, 4) -- crossguard
	B(c, "s", 10, 10, 12, 18, 3, 3) -- blade
	S(c, "w", 6, 14, 3) -- neck
	B(c, "w", 4, 8, 15, 17, 1, 5) -- skull
	B(c, "w", 5, 7, 14, 14, 1, 3) -- jaw
	M(c, "k", 5, 5, 16, 16, 1, 1) -- eye sockets
	B(c, "h", 3, 9, 18, 18, 1, 6) -- helmet top
	M(c, "h", 3, 3, 15, 17, 1, 6) -- helmet sides
	B(c, "h", 4, 8, 15, 17, 6, 6) -- helmet back
	B(c, "h", 6, 6, 17, 17, 1, 1) -- nasal guard
	B(c, "r", 6, 6, 19, 19, 2, 6) -- plume
	B(c, "r", 6, 6, 20, 20, 3, 6)
	add("Guards", "SkeletonKnight", 1.0, OUT(c), {
		w = "F2EEDF",
		h = "8C8C96",
		s = "D8DCE4",
		r = "C8302A",
		b = "5E3A1E",
		y = "E8C040",
		k = "141414",
	})
end

-- TreeEnt: bark trunk on two root legs, angry glowing eyes, branch arms, green/purple leafy crown
do
	local c = Cv(17, 10, 21)
	B(c, "t", 6, 12, 1, 12, 3, 8) -- trunk
	B(c, ".", 9, 9, 1, 3, 1, 10) -- split into two legs
	M(c, "t", 4, 5, 1, 1, 4, 6) -- side roots
	M(c, "t", 6, 8, 1, 1, 2, 2) -- front roots
	M(c, "t", 6, 7, 1, 1, 9, 9) -- back roots
	RC(c, "t", "d", function(x)
		return x == 7 or x == 11
	end)
	S(c, "e", 8, 9, 3) -- angry eyes
	S(c, "e", 10, 9, 3)
	M(c, "k", 7, 7, 11, 11, 3, 3) -- brows slant down to the middle
	M(c, "k", 8, 8, 10, 10, 3, 3)
	S(c, "t", 9, 8, 2) -- knot nose
	for i = 0, 3 do
		M(c, "t", 5 - i, 5 - i, 9 + i, 10 + i, 5, 6) -- branch arms reaching up and out
	end
	M(c, "t", 3, 3, 9, 9, 5, 5) -- twig
	M(c, "t", 2, 2, 8, 8, 5, 5)
	M(c, "l", 1, 2, 14, 15, 4, 7) -- leaf tufts at the hands
	E(c, "l", 9, 17, 5.5, 7.4, 4.6, 5.2, 2.2) -- crown
	RC(c, "l", "g", function(_, y)
		return y <= 14
	end)
	local berries = { { 4, 16, 3 }, { 14, 15, 4 }, { 9, 20, 5 }, { 7, 17, 1 }, { 12, 18, 2 }, { 6, 19, 8 }, { 13, 16, 9 } }
	RC(c, "l", "p", function(x, y, z)
		for _, b in ipairs(berries) do
			if math.abs(x - b[1]) <= 1 and math.abs(y - b[2]) <= 1 and math.abs(z - b[3]) <= 1 then
				return true
			end
		end
		return false
	end)
	add("Guards", "TreeEnt", 1.0, OUT(c), {
		t = "6B4226",
		d = "4A2C18",
		k = "1E120A",
		e = "*D8FF3A",
		l = "4CAF3A",
		g = "2E7D24",
		p = "7A3BE0",
	})
end

-- SwampToad: long low toad (about 3:1), neon yellow eyes, small purple hat, dark back spots
do
	local c = Cv(14, 18, 9)
	E(c, "g", 7.5, 1, 10, 6.6, 5, 8.2, 2.6) -- low dome body
	RC(c, "g", "l", function(_, y, z)
		return y <= 2 and z <= 4
	end)
	RC(c, "g", "d", function(x, y, z)
		return y >= 4
			and (
				(x >= 5 and x <= 6 and z >= 9 and z <= 10)
				or (x >= 9 and x <= 10 and z >= 12 and z <= 13)
				or (x >= 6 and x <= 7 and z >= 15 and z <= 16)
			)
	end)
	M(c, "d", 2, 3, 1, 2, 1, 3) -- front legs
	M(c, "d", 1, 2, 1, 4, 12, 16) -- haunches
	M(c, "d", 1, 3, 1, 1, 17, 18) -- hind feet
	M(c, "g", 3, 5, 5, 7, 3, 5) -- eye bumps
	M(c, "y", 4, 5, 6, 7, 3, 3) -- eyes
	M(c, "k", 5, 5, 6, 6, 3, 3) -- pupils
	B(c, "p", 6, 9, 6, 6, 5, 8) -- hat brim
	B(c, "p", 7, 8, 7, 8, 6, 7) -- hat crown
	B(c, "b", 7, 8, 7, 7, 6, 6) -- hat band (front)
	add("Guards", "SwampToad", 1.0, OUT(c), {
		g = "4C9A2A",
		d = "2E6B1E",
		l = "C8E07A",
		y = "*FFE11A",
		k = "141414",
		p = "7A3BE0",
		b = "2A1A3A",
	})
end

-- Vampire: pale face, black hair, black suit, purple/black cape with red lining and high collar
do
	local c = Cv(11, 8, 17)
	M(c, "n", 4, 5, 1, 1, 2, 4) -- shoes
	M(c, "n", 4, 5, 2, 6, 3, 4) -- legs
	B(c, "n", 4, 8, 7, 11, 3, 5) -- torso
	B(c, "w", 6, 6, 8, 11, 3, 3) -- shirt
	S(c, "j", 6, 11, 3) -- neon brooch
	M(c, "n", 3, 3, 7, 11, 3, 4) -- arms
	M(c, "s", 3, 3, 6, 6, 3, 4) -- hands
	B(c, "r", 3, 9, 2, 12, 6, 6) -- red lining
	B(c, "c", 2, 10, 2, 12, 7, 7) -- cape back
	M(c, "c", 2, 2, 3, 12, 4, 6) -- cape sides
	M(c, "r", 2, 2, 3, 12, 4, 4) -- lining shows at the front edge
	B(c, "c", 1, 11, 1, 2, 7, 8) -- flared hem
	B(c, "h", 1, 11, 1, 1, 7, 8)
	B(c, "r", 3, 9, 12, 14, 6, 6) -- high collar
	B(c, "c", 3, 9, 12, 14, 7, 7)
	M(c, "c", 2, 2, 12, 15, 5, 7)
	M(c, "r", 2, 2, 12, 15, 5, 5)
	S(c, "s", 6, 12, 4) -- neck
	B(c, "s", 4, 8, 13, 16, 1, 5) -- head
	M(c, "e", 5, 5, 15, 15, 1, 1) -- eyes
	B(c, "h", 4, 8, 17, 17, 1, 5) -- hair
	B(c, "h", 4, 8, 16, 16, 1, 1)
	B(c, "h", 4, 8, 13, 16, 5, 5)
	M(c, "h", 4, 4, 15, 16, 2, 4)
	add("Guards", "Vampire", 1.0, OUT(c), {
		n = "22222A",
		w = "F4F4F8",
		j = "*FF2040",
		s = "EDE4F0",
		c = "5A2A9A",
		r = "C8302A",
		h = "141418",
		e = "C8102A",
	})
end

-- CandyGolem: big pink gummy bear holding a swirl lollipop
do
	local c = Cv(17, 8, 19)
	B(c, "p", 3, 5, 1, 4, 3, 6) -- legs
	B(c, "p", 8, 10, 1, 4, 3, 6)
	B(c, "p", 2, 11, 5, 10, 2, 7) -- body
	for _, x in ipairs({ 2, 11 }) do
		B(c, ".", x, x, 10, 10, 2, 2)
		B(c, ".", x, x, 10, 10, 7, 7)
	end
	B(c, "l", 4, 9, 5, 9, 1, 1) -- belly
	for _, q in ipairs({ { 4, 5 }, { 9, 5 }, { 4, 9 }, { 9, 9 } }) do
		S(c, ".", q[1], q[2], 1)
	end
	B(c, "p", 1, 1, 6, 10, 3, 5) -- left arm
	B(c, "p", 12, 12, 7, 10, 3, 5) -- right arm
	B(c, "s", 14, 14, 4, 13, 4, 4) -- lollipop stick
	B(c, "p", 13, 15, 8, 9, 3, 5) -- fist round the stick
	for y = 12, 20 do
		for x = 10, 18 do
			local dx, dy = x - 14, y - 16
			local d = math.sqrt(dx * dx + dy * dy)
			if d <= 3.4 then
				local a = math.atan2(dy, dx) + d * 0.9
				local k = math.floor(a / (math.pi / 3)) % 2
				S(c, d < 0.5 and "a" or (k == 0 and "r" or "w"), x, y, 4)
			end
		end
	end
	B(c, "p", 3, 10, 11, 15, 2, 7) -- head
	for _, x in ipairs({ 3, 10 }) do
		S(c, ".", x, 15, 2)
		S(c, ".", x, 15, 7)
		S(c, ".", x, 11, 2)
	end
	B(c, "l", 5, 8, 11, 12, 1, 1) -- snout
	B(c, "k", 6, 7, 12, 12, 1, 1) -- nose
	S(c, "k", 5, 14, 2) -- eyes
	S(c, "k", 8, 14, 2)
	B(c, "p", 3, 4, 16, 16, 3, 5) -- ears
	B(c, "p", 9, 10, 16, 16, 3, 5)
	S(c, "l", 4, 16, 3)
	S(c, "l", 9, 16, 3)
	add("Guards", "CandyGolem", 1.0, OUT(c), {
		p = "FF5FB0",
		l = "FF9AC8",
		k = "141414",
		s = "F4F4F8",
		r = "FF2A4A",
		w = "F4F4F8",
		a = "*FFE11A",
	})
end

-- PumpkinKing: huge jack-o'-lantern head with neon carved face, gold crown, purple royal cape, vine arms
do
	local c = Cv(19, 15, 24)
	M(c, "n", 7, 8, 1, 1, 6, 9) -- boots
	M(c, "v", 7, 8, 2, 3, 7, 8) -- vine legs
	B(c, "p", 6, 14, 4, 9, 5, 10) -- robe
	M(c, ".", 6, 6, 4, 4, 5, 5)
	B(c, "y", 6, 14, 6, 6, 5, 10) -- gold belt
	B(c, "w", 5, 15, 10, 10, 4, 11) -- ermine collar
	for _, x in ipairs({ 7, 10, 13 }) do
		S(c, "k", x, 10, 4)
	end
	B(c, "c", 4, 16, 2, 10, 11, 12) -- cape
	B(c, "c", 3, 17, 1, 2, 11, 13) -- flared hem
	B(c, "w", 3, 17, 1, 1, 11, 13) -- ermine hem
	M(c, "c", 4, 4, 2, 9, 7, 10) -- cape wraps the sides
	for _, q in ipairs({ { 5, 9, "v" }, { 4, 9, "v" }, { 3, 8, "v" }, { 2, 7, "v" }, { 2, 6, "v" }, { 2, 5, "v" }, { 3, 4, "v" }, { 3, 9, "f" }, { 1, 6, "f" } }) do
		M(c, q[3], q[1], q[1], q[2], q[2], 7, 8) -- vine arms with leaves
	end
	E(c, "o", 10, 16, 7.5, 9.4, 5.6, 7.3, 4) -- pumpkin head
	RC(c, "o", "d", function(x)
		return x == 4 or x == 10 or x == 16
	end)
	local face = {
		{ 19, { 6 } },
		{ 18, { 5, 6, 7 } },
		{ 17, { 4, 5, 6, 7, 8 } },
		{ 16, { 10 } },
		{ 15, { 9, 10, 11 } },
		{ 14, { 4 } },
		{ 13, { 5, 6, 7, 9, 10 } },
		{ 12, { 6, 7, 8, 9 } },
	}
	for _, row in ipairs(face) do
		for _, x in ipairs(row[2]) do
			FM(c, "f", x, row[1])
		end
	end
	B(c, "y", 6, 14, 22, 23, 5, 10) -- crown ring
	B(c, ".", 7, 13, 22, 23, 6, 9)
	for _, x in ipairs({ 6, 10, 14 }) do
		S(c, "y", x, 24, 5)
		S(c, "y", x, 24, 10)
	end
	M(c, "y", 6, 6, 24, 24, 7, 8)
	for _, x in ipairs({ 8, 12 }) do
		S(c, "j", x, 22, 5) -- gems
	end
	S(c, "j", 10, 23, 5)
	B(c, "g", 10, 10, 22, 23, 7, 8) -- stem inside the crown
	add("Guards", "PumpkinKing", 1.2, OUT(c), {
		o = "FF7A1A",
		d = "D9530F",
		f = "*FFB21A",
		y = "E8C040",
		j = "7A3BE0",
		p = "7A3BE0",
		c = "5A2A9A",
		w = "F4F4F8",
		k = "141414",
		v = "3FA535",
		g = "3FA535",
		n = "2A1A10",
	})
end

-- ===================== OUTPUT =====================
local SS = game:GetService("ServerStorage")
local old = SS:FindFirstChild("VoxelOut")
if old then
	old:Destroy()
end
local outF = Instance.new("Folder")
outF.Name = "VoxelOut"
local groups = {}
for _, g in ipairs({ "Pets", "Guards" }) do
	local f = Instance.new("Folder")
	f.Name = g
	f.Parent = outF
	groups[g] = f
end
local lines = {}
for _, m in ipairs(ALL) do
	local model, n = build(m[2], m[3], m[4], m[5], Vector3.new(0, 0, 0))
	model.Parent = groups[m[1]]
	table.insert(lines, string.format("%s/%s %d", m[1], m[2], n))
end
outF.Parent = SS
return "VoxelOut: " .. table.concat(lines, ", ")
