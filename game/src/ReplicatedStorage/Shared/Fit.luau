--!strict

local Fit = {}

export type Size = { number }

function Fit.scaleFor(boundsSize: Size, targetSize: Size): number
	local scale = math.huge
	for axis = 1, 3 do
		local bound = boundsSize[axis]
		local target = targetSize[axis]
		if bound <= 0 or target <= 0 then
			return 1
		end
		scale = math.min(scale, target / bound)
	end
	return scale
end

return Fit
