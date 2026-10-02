--!strict

local ModelParts = {}

function ModelParts.isGlow(name: string): boolean
	return name:sub(-5) == "_Glow"
end

function ModelParts.motorFor(name: string): string?
	if name == "Head" then
		return "Neck"
	elseif name == "Jaw" then
		return "Jaw"
	elseif name == "Arm_L" then
		return "Shoulder_L"
	elseif name == "Arm_R" then
		return "Shoulder_R"
	elseif name == "Leg_L" then
		return "Hip_L"
	elseif name == "Leg_R" then
		return "Hip_R"
	elseif name:match("^Leg_%d+$") or name:match("^Wing_%d+$") then
		return name
	end
	return nil
end

function ModelParts.parentFor(name: string): string?
	if name == "Jaw" then
		return "Head"
	elseif ModelParts.motorFor(name) then
		return "Torso"
	end
	return nil
end

return ModelParts
