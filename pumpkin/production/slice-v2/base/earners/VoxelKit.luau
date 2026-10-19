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
					p.CanCollide = false
					p.CanTouch = false
					p.CanQuery = false
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

return build

