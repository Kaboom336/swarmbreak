-- Read-only source asset census, independent of scene author claims.
local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
for _, path in { "assets/PumpkinMap.rbxm", "assets/PetModels.rbxm" } do
	local roots = roblox.deserializeModel(fs.readFile(path))
	local counts, executable = {}, 0
	for _, root in roots do
		local instances = root:GetDescendants()
		table.insert(instances, root)
		for _, instance in instances do
			counts[instance.ClassName] = (counts[instance.ClassName] or 0) + 1
			if instance:IsA("LuaSourceContainer") then
				executable += 1
			end
		end
	end
	print(path, counts, "LuaSourceContainer=" .. executable)
	assert(executable == 0, "Executable imported art")
end
