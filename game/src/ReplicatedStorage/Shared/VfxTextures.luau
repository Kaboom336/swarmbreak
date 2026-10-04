--!strict
-- Asset placeholders. Zero keeps the existing untextured particle look until sprites are uploaded.
local VfxTextures = {
	spark = 0,
	smoke = 0,
	slash = 0,
	ring = 0,
	goo = 0,
	softglow = 0,
}

function VfxTextures.asset(name: string): string
	local id = VfxTextures[name]
	return if type(id) == "number" and id > 0 then "rbxassetid://" .. tostring(id) else ""
end

return VfxTextures
