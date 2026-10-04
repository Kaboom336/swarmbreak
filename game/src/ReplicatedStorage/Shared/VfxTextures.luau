--!strict
-- Engine-shipped textures only: these do not depend on uploaded or store assets.
local VfxTextures = {
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	slash = "rbxasset://textures/particles/sparkles_main.dds",
	ring = "rbxasset://textures/particles/explosion01_implosion_main.dds",
	goo = "rbxasset://textures/particles/smoke_main.dds",
	softglow = "rbxasset://textures/particles/flare_main.dds",
}

function VfxTextures.asset(name: string): string
	local id = VfxTextures[name]
	return if type(id) == "string" and id:sub(1, 11) == "rbxasset://" then id else ""
end

return VfxTextures
