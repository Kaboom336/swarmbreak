--!strict
local Rules = {}
Rules.MaxRank = 8
Rules.Gravity = 55
Rules.DefaultControls = { yaw = 5, angle = 35, power = 1 }
function Rules.integer(value: any, maximum: number): number
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return 0
	end
	return math.clamp(math.floor(value), 0, maximum)
end
function Rules.cost(rank: number): number
	return 20 * (rank + 1) * (rank + 1)
end
function Rules.diameter(rank: number): number
	return 2.5 + 0.55 * Rules.integer(rank, Rules.MaxRank)
end
function Rules.controls(value: any): any
	if type(value) ~= "table" then
		return nil
	end
	for _, name in { "yaw", "angle", "power" } do
		local n = value[name]
		if type(n) ~= "number" or n ~= n or math.abs(n) == math.huge then
			return nil
		end
	end
	return {
		yaw = math.clamp(value.yaw, -40, 40),
		angle = math.clamp(value.angle, 15, 70),
		power = math.clamp(value.power, 0.55, 1.25),
	}
end
function Rules.upgrade(profile: any, kind: any): (boolean, string)
	local field = if kind == "pumpkin"
		then "PumpkinRank"
		elseif kind == "launcher" then "LauncherRank"
		else nil
	if not field then
		return false, "Choose a pumpkin or launcher upgrade."
	end
	local rank = Rules.integer(profile[field], Rules.MaxRank)
	if rank >= Rules.MaxRank then
		return false, "Fully upgraded!"
	end
	local cost = Rules.cost(rank)
	if profile.Gold < cost then
		return false, "Need " .. cost .. " gold."
	end
	profile.Gold -= cost
	profile[field] = rank + 1
	return true, "Upgrade ready!"
end
function Rules.newWave(count: number, number: number?): any
	return {
		number = number or 1,
		count = count,
		remaining = count,
		hits = {},
		contributors = {},
		paid = false,
	}
end
function Rules.hit(wave: any, target: number, userId: number): boolean
	if wave.paid or target % 1 ~= 0 or target < 1 or target > wave.count or wave.hits[target] then
		return false
	end
	wave.hits[target] = true
	wave.remaining -= 1
	wave.contributors[userId] = true
	return true
end
function Rules.depart(wave: any, userId: number)
	wave.contributors[userId] = nil
end
function Rules.bonus(wave: any): { [number]: number }
	local awards = {}
	if wave.remaining > 0 or wave.paid then
		return awards
	end
	wave.paid = true
	for id in wave.contributors do
		awards[id] = 15
	end
	return awards
end
function Rules.segmentDistance(
	px: number,
	py: number,
	pz: number,
	ax: number,
	ay: number,
	az: number,
	bx: number,
	by: number,
	bz: number
): number
	local x, y, z = bx - ax, by - ay, bz - az
	local length = x * x + y * y + z * z
	local t = if length > 0
		then math.clamp(((px - ax) * x + (py - ay) * y + (pz - az) * z) / length, 0, 1)
		else 0
	return math.sqrt((px - ax - x * t) ^ 2 + (py - ay - y * t) ^ 2 + (pz - az - z * t) ^ 2)
end
return Rules
