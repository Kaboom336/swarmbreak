-- Shared footprint contract. Server calls this before consuming secured cargo.
local Placement = {}
function Placement.height(slot)
	return ((slot - 1) % 4) * 3.5
end
function Placement.center(slot)
	return slot <= 4 and -52 or 52, 96 - (slot - 1) % 4 * 64
end
local function finite(n)
	return type(n) == "number" and n == n and math.abs(n) < math.huge
end
function Placement.validate(config, slot, x, z, angle, occupied)
	if not finite(x) or not finite(z) or not finite(angle) then
		return false, "invalid placement"
	end
	if #occupied >= config.MaxActivePets then
		return false, "active pet limit"
	end
	local cx, cz = Placement.center(slot)
	local half = config.PetFootprint / 2
	local extent = half * (math.abs(math.cos(math.rad(angle))) + math.abs(math.sin(math.rad(angle))))
	local dx, dz = x - cx, z - cz
	if
		math.abs(dx) + extent > config.PlotWidth / 2 - config.PlotInset
		or math.abs(dz) + extent > config.PlotDepth / 2 - config.PlotInset
	then
		return false, "out of bounds"
	end
	-- Twelve by twelve gate reserve, plus its eight-wide route to the centre.
	local inward = cx < 0 and 1 or -1
	if
		dx * inward + extent > 16 and math.abs(dz) < 6 + extent
		or dx * inward + extent > 0 and math.abs(dz) < 4 + extent
	then
		return false, "keep entrance clear"
	end
	for _, pet in occupied do
		local other = pet.extent or half
		if
			math.abs(x - pet.x) < extent + other + config.PetSpacing
			and math.abs(z - pet.z) < extent + other + config.PetSpacing
		then
			return false, "overlap"
		end
	end
	return true, extent
end
return Placement
