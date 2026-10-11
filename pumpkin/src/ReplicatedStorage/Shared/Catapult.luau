--!strict
local Config = require(script.Parent.Config)

local Catapult = {}

function Catapult.rank(value: any): number
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return 0
	end
	return math.clamp(math.floor(value), 0, Config.CatapultMaxRank)
end

function Catapult.settings(angle: any, power: any): any?
	if type(angle) ~= "number" or type(power) ~= "number" then
		return nil
	end
	if
		angle ~= angle
		or power ~= power
		or math.abs(angle) == math.huge
		or math.abs(power) == math.huge
	then
		return nil
	end
	return { angle = math.clamp(angle, 15, 60), power = math.clamp(power, 0.5, 1) }
end

function Catapult.upgradeCost(rank: number): number?
	local current = Catapult.rank(rank)
	return if current == Config.CatapultMaxRank
		then nil
		else Config.CatapultUpgradeBaseCost * 2 ^ current
end

function Catapult.buy(profile: any): (boolean, string)
	local cost = Catapult.upgradeCost(profile.CatapultRank)
	if not cost then
		return false, "FULLY UPGRADED"
	end
	if profile.Wins < cost then
		return false, "NEED " .. cost .. " WINS"
	end
	profile.Wins -= cost
	profile.CatapultRank = Catapult.rank(profile.CatapultRank) + 1
	return true, "CATAPULT UPGRADED!"
end

function Catapult.rewardMultiplier(rank: number): number
	return 1 + Catapult.rank(rank) * Config.CatapultRewardStep
end

-- Return to ground before the first pickup/hazard. Server and prediction share the arc.
function Catapult.height(elapsed: number, settings: any): number
	local duration = 0.65 + settings.power * 0.45
	local alpha = math.clamp(elapsed / duration, 0, 1)
	local height = math.sin(math.rad(settings.angle)) * settings.power * Config.CatapultArcHeight
	return 4 * alpha * (1 - alpha) * height
end

return Catapult
