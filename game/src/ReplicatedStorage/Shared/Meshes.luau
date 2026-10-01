--!strict
-- Uploaded mesh ids for the Blender-made models in assets/models/ (see game/ASSETS.md).
-- 0 = not uploaded yet: builders use the part-built fallback. Filled in on the laptop after the 3D import.
-- Keys are "<group>/<Name>/<Part>" as named in assets/models/manifest.json.
local Meshes = {}

Meshes.Ids = {} :: { [string]: number }

-- Parts whose name ends in _Glow get the Neon material; wings get Transparency 0.4.
function Meshes.id(group: string, model: string, part: string): number
	return Meshes.Ids[group .. "/" .. model .. "/" .. part] or 0
end

function Meshes.has(group: string, model: string): boolean
	local prefix = group .. "/" .. model .. "/"
	for key, id in Meshes.Ids do
		if id ~= 0 and string.sub(key, 1, #prefix) == prefix then
			return true
		end
	end
	return false
end

return Meshes
