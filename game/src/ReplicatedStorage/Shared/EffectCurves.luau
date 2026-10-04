--!strict
-- Pure easing curves used by the single client FX driver.
local EffectCurves = {}

local function unit(value: number): number
	return math.clamp(value, 0, 1)
end

function EffectCurves.quadOut(value: number): number
	local t = unit(value)
	return 1 - (1 - t) * (1 - t)
end

function EffectCurves.exponentialOut(value: number): number
	local t = unit(value)
	if t == 0 or t == 1 then
		return t
	end
	return 1 - 2 ^ (-10 * t)
end

function EffectCurves.easeIn(value: number): number
	local t = unit(value)
	return t * t
end

return EffectCurves
