--!strict

local ModelKey = {}

function ModelKey.make(group: string, name: string): string
	return group .. "/" .. name
end

return ModelKey
