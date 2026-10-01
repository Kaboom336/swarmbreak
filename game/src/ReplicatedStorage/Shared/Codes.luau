--!strict
-- Redeemable codes and their persistent rewards. Pure + tested.
export type Reward = {
	Gems: number?,
	Shard: string?,
	Crate: string?,
}

export type CodeDef = {
	Reward: Reward,
	MinWave: number?,
	ExpiresDay: number?,
}

export type Profile = {
	Gems: number,
	Shards: { [string]: number },
	BestWave: number,
	Redeemed: { [string]: boolean },
	[any]: any,
}

local Codes = {}

Codes.Defs = {
	WELCOME = { Reward = { Gems = 100 } }, -- placeholder
	OUTPOST = { Reward = { Shard = "Tech" } }, -- placeholder
	WAVE10 = { Reward = { Gems = 150 }, MinWave = 10 }, -- placeholder
	GEMCRATE = { Reward = { Crate = "Gem" } }, -- placeholder
	OCTOBER = { Reward = { Gems = 50 }, ExpiresDay = 21000 }, -- placeholder
} :: { [string]: CodeDef }

local function normalized(code: string): string
	return string.upper(string.match(code, "^%s*(.-)%s*$") or "")
end

local function copyReward(reward: Reward): Reward
	return {
		Gems = reward.Gems,
		Shard = reward.Shard,
		Crate = reward.Crate,
	}
end

function Codes.check(code: string, profile: Profile, today: number): (boolean, string)
	local key = normalized(code)
	local def = Codes.Defs[key]
	if not def then
		return false, "Unknown code."
	end
	if profile.Redeemed[key] == true then
		return false, "Code already redeemed."
	end
	if def.ExpiresDay ~= nil and today > def.ExpiresDay then
		return false, "This code has expired."
	end
	if def.MinWave ~= nil and profile.BestWave < def.MinWave then
		return false, string.format("Reach wave %d first.", def.MinWave)
	end
	return true, ""
end

function Codes.redeem(profile: Profile, code: string, today: number): (Profile, Reward?)
	local ok = Codes.check(code, profile, today)
	if not ok then
		return profile, nil
	end

	local key = normalized(code)
	local reward = copyReward(Codes.Defs[key].Reward)
	local updated = table.clone(profile)
	updated.Shards = table.clone(profile.Shards)
	updated.Redeemed = table.clone(profile.Redeemed)
	updated.Redeemed[key] = true
	updated.Gems += reward.Gems or 0
	if reward.Shard ~= nil then
		updated.Shards[reward.Shard] = (updated.Shards[reward.Shard] or 0) + 1
	end
	return updated, reward
end

return Codes
