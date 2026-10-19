-- Add future definitions here; unregistered definitions retain the existing placeholder.
local build=require(script.Parent.VoxelKit)
local definitions={[1]=require(script.Parent.CopperCompass)}
return function(def,mutation,origin)
	local entry=definitions[def]
	return entry and entry.create(build,mutation,origin) or nil
end
