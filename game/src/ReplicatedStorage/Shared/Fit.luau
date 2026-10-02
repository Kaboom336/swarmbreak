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

function Fit.sizeForRelativeHeight(
	size: Size,
	relativeHeight: number,
	referenceHeight: number
): Size
	local scale = Fit.scaleFor(size, { math.huge, referenceHeight * relativeHeight, math.huge })
	return { size[1] * scale, size[2] * scale, size[3] * scale }
end

-- Shrink a height-based scale so the footprint stays within maxWidth (no cap when nil).
function Fit.capWidth(scale: number, width: number, depth: number, maxWidth: number?): number
	if not maxWidth then
		return scale
	end
	return math.min(scale, maxWidth / math.max(width, depth))
end

return Fit
