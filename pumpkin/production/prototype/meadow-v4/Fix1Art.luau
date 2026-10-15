-- Studio pass 1: native, thick hill caps and voxel cave scenery. No new collision.
local Art = {}
function Art.transform(data, routes)
	local out = {}
	local function copy(p)
		local q = table.clone(p)
		q.position, q.size, q.rotation, q.color =
			table.clone(p.position), table.clone(p.size), table.clone(p.rotation), table.clone(p.color)
		return q
	end
	local function nearRoute(p)
		local radius = math.sqrt(p.size[1] ^ 2 + p.size[3] ^ 2) / 2 + 11
		local floor = -math.huge
		for _, route in pairs(routes) do
			for i = 2, #route do
				local a, b = route[i - 1], route[i]
				local dx, dz = b.x - a.x, b.z - a.z
				local t = math.clamp(
					((p.position[1] - a.x) * dx + (-p.position[3] - a.z) * dz) / math.max(0.001, dx * dx + dz * dz),
					0,
					1
				)
				if (p.position[1] - a.x - dx * t) ^ 2 + (-p.position[3] - a.z - dz * t) ^ 2 < radius ^ 2 then
					floor = math.max(floor, a.y + (b.y - a.y) * t + 20.1)
				end
			end
		end
		return floor
	end
	for _, source in ipairs(data) do
		local p = copy(source)
		local name = p.name
		if name == "LookContinuousTurf" or name == "LookHillEarthBank" or name == "LookHillGrassBank" then
			continue -- Remove the paper-thin triangulated skin and its exposed skirts.
		end
		local tunnel = name:find("Tunnel") or name:find("LookHill") or name:find("LookSkylight")
		if tunnel then
			if p.material == "Rock" or p.material == "Basalt" then
				p.material = "Slate"
			end
			if p.material == "Wood" then
				p.material = "WoodPlanks"
			end
		end
		if name == "TunnelHillTurf" then
			-- Retain the authored walkable collider; grow its visible cap downwards.
			table.insert(out, p)
			local cap = copy(p)
			cap.name, cap.transparency, cap.collidable = "Fix1SolidGrassCap", 0, false
			local minimum = nearRoute(p)
			local nx, ny, nz = p.rotation[2], p.rotation[5], p.rotation[8]
			local low = p.position[2] - (math.abs(p.rotation[4]) * p.size[1] + math.abs(p.rotation[6]) * p.size[3]) / 2
			local depth = math.min(4, math.max(1.4, (low - minimum) / math.max(ny, 0.1) + 0.7))
			cap.size[2] = depth
			local shift = (depth - 1.4) / 2
			cap.position = { p.position[1] - nx * shift, p.position[2] - ny * shift, p.position[3] - nz * shift }
			table.insert(out, cap)
			-- Interlocked slate backing ties the turf to the existing 410 solid earth columns.
			local bottom = low - ny * (depth - 0.7)
			if bottom - 6 >= minimum then
				local rock = copy(cap)
				rock.name, rock.material, rock.color = "Fix1HillSlateBacking", "Slate", { 97, 107, 119 }
				rock.size[2] = 6
				local offset = depth / 2 + 2.9
				rock.position =
					{ cap.position[1] - nx * offset, cap.position[2] - ny * offset, cap.position[3] - nz * offset }
				table.insert(out, rock)
			end
			continue
		end
		if tunnel and p.shape == "Ball" and not name:find("Puddle") then
			if p.collidable then
				local collider = copy(p)
				collider.transparency = 1
				table.insert(out, collider)
			end
			-- Three overlapping rectangular masses within the previous prop bounds.
			for i = 1, 3 do
				local q = copy(p)
				q.name, q.shape = name .. "Voxel" .. i, "Block"
				q.collidable = false -- Keep the original hidden collision hull and route clearance.
				q.size = {
					p.size[1] * (i == 1 and 0.7 or 0.45),
					p.size[2] * (i == 1 and 1 or 0.65),
					p.size[3] * (i == 1 and 0.7 or 0.5),
				}
				q.position[1] += i == 2 and -p.size[1] * 0.25 or i == 3 and p.size[1] * 0.25 or 0
				q.position[2] -= i == 1 and 0 or p.size[2] * 0.175
				table.insert(out, q)
			end
			continue
		end
		if name == "TunnelMushroomGlow" then
			p.name, p.material, p.color = "Fix1MushroomCap", "Slate", { 85, 166, 180 }
			for i = 1, 2 do
				local dot = copy(p)
				dot.name, dot.material, dot.color = "Fix1MushroomSpot", "Neon", { 131, 248, 225 }
				dot.size = { 0.25, 0.08, 0.25 }
				dot.position[1] += (i == 1 and -0.3 or 0.3)
				dot.position[2] += p.size[2] / 2 + 0.04
				table.insert(out, dot)
			end
		elseif name == "TunnelMushroomStem" then
			p.material = "WoodPlanks"
		elseif name == "TunnelSkylightGlow" then
			p.transparency = 1
		elseif name == "TunnelExitAmberCrystal" then
			p.name, p.color = "Fix1AmethystCrystal", { 171, 116, 225 }
		end
		table.insert(out, p)
	end
	return out
end
return Art
