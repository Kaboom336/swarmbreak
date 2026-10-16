-- Presentation only. Geometry, query flags, lane identity and routes stay intact.
local P = {}
function P.clearZone(position, routes)
	local x, y, z = position[1], position[2], position[3]
	-- Quiet summit camp; do not clear scenery on floors below it.
	if math.abs(y - 48) < 12 and x*x + (z+99)^2 < 31^2 then return true end
	-- First 30 horizontal studs from BOTH ends of every authored route.
	for _, route in routes do
		for _, reverse in {false, true} do
			local remaining = 30
			for j = 2, #route do
				local i = if reverse then #route-j+2 else j
				local a, b = route[if reverse then i else i-1], route[if reverse then i-1 else i]
				local dx, dz = b.x-a.x, -(b.z-a.z)
				local length = math.sqrt(dx*dx+dz*dz)
				local limit = math.min(1, remaining/math.max(length, 0.001))
				local t = math.clamp(((x-a.x)*dx+(z+a.z)*dz)/math.max(length*length,0.001),0,limit)
				if (x-a.x-dx*t)^2+(z+a.z-dz*t)^2 < 16^2
					and math.abs(y-a.y-(b.y-a.y)*t) < 8 then return true end
				remaining -= length
				if remaining <= 0 then break end
			end
		end
	end
	return false
end
function P.color(color, material, name)
	local c = Color3.fromRGB(unpack(color))
	local h,s,v = c:ToHSV()
	if material == "Grass" then
		return Color3.fromHSV(h,math.min(0.92,s*1.35),math.min(0.94,v*1.22))
	elseif name:find("Petal") or name:find("Flower") and not name:find("Stem") then
		return Color3.fromHSV(h,math.min(0.85,s*1.2),math.min(1,v*1.08))
	elseif name:find("Pav") or material == "Sand" or material == "Cobblestone" then
		return Color3.fromHSV(h*0.78,math.min(0.68,s*1.4),math.min(0.98,v*1.16))
	end
	return c
end
function P.transform(data, routes)
	local out = {}
	for _, source in data do
		local p = table.clone(source)
		local c = P.color(p.color,p.material,p.name)
		p.color = {c.R*255,c.G*255,c.B*255}
		-- Only remove small, nonphysical dressing. Never invisible collision hulls.
		local small = math.max(unpack(p.size)) <= 12
		local prop = p.name:find("Flower") or p.name:find("Bush") or p.name:find("Pebble")
			or p.name:find("Mushroom") or p.name:find("GrassTuft")
		if small and prop and not p.collidable and P.clearZone(p.position,routes) then
			p.transparency, p.polishCleared = 1, true
		end
		table.insert(out,p)
	end
	return out
end
return P
