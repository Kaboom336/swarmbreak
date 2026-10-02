--!strict
-- Pure policy for reducing animation work on distant enemies.

local AnimCull = {}

AnimCull.FullDistance = 80 -- placeholder
AnimCull.FarEvery = 3 -- placeholder

function AnimCull.shouldUpdate(
	distance: number,
	onScreen: boolean,
	enemyIndex: number,
	frame: number
): boolean
	if distance <= AnimCull.FullDistance then
		return true
	end
	if not onScreen then
		return false
	end
	return (frame + enemyIndex) % AnimCull.FarEvery == 0
end

return AnimCull
