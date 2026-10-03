--!strict
-- Pure per-enemy damage ledger and assist-reward allocation.
local DamageCredit = {}

DamageCredit.AssistWindow = 10
DamageCredit.MaxContributors = 8
DamageCredit.AssistPoolFraction = 0.5

export type Contribution = {
	Damage: number,
	LastHitAt: number,
}

export type Ledger = { [number]: Contribution }

export type Reward = {
	UserId: number,
	Damage: number,
	Coins: number,
}

type Allocation = Reward & {
	Remainder: number,
}

local function validNumber(value: number): boolean
	return value == value and value > 0 and value < math.huge
end

function DamageCredit.new(): Ledger
	return {}
end

function DamageCredit.expire(ledger: Ledger, now: number)
	for userId, contribution in ledger do
		if now - contribution.LastHitAt > DamageCredit.AssistWindow then
			ledger[userId] = nil
		end
	end
end

local function contributorCount(ledger: Ledger): number
	local count = 0
	for _ in ledger do
		count += 1
	end
	return count
end

local function weakestContributor(ledger: Ledger): number?
	local weakestId: number? = nil
	local weakest: Contribution? = nil
	for userId, contribution in ledger do
		if
			not weakest
			or contribution.Damage < weakest.Damage
			or (contribution.Damage == weakest.Damage and contribution.LastHitAt < weakest.LastHitAt)
			or (
				contribution.Damage == weakest.Damage
				and contribution.LastHitAt == weakest.LastHitAt
				and userId > (weakestId :: number)
			)
		then
			weakestId = userId
			weakest = contribution
		end
	end
	return weakestId
end

-- Records real health removed, not requested damage. Invalid and zero damage is ignored.
function DamageCredit.record(ledger: Ledger, userId: number, damage: number, now: number)
	if userId <= 0 or not validNumber(damage) or now ~= now then
		return
	end
	DamageCredit.expire(ledger, now)
	local contribution = ledger[userId]
	if contribution then
		contribution.Damage += damage
		contribution.LastHitAt = now
		return
	end
	if contributorCount(ledger) >= DamageCredit.MaxContributors then
		local weakestId = weakestContributor(ledger)
		if weakestId then
			ledger[weakestId] = nil
		end
	end
	ledger[userId] = { Damage = damage, LastHitAt = now }
end

local function connected(connectedUserIds: { [number]: boolean }?, userId: number): boolean
	return connectedUserIds == nil or connectedUserIds[userId] == true
end

-- Splits one capped integer pool among eligible helpers using largest remainders. The killer
-- remains the sole kill owner and is never included in these rewards.
function DamageCredit.split(
	ledger: Ledger,
	killerUserId: number,
	killCoins: number,
	now: number,
	connectedUserIds: { [number]: boolean }?
): { Reward }
	DamageCredit.expire(ledger, now)
	if not connected(connectedUserIds, killerUserId) then
		return {}
	end
	local allocations: { Allocation } = {}
	local totalDamage = 0
	for userId, contribution in ledger do
		if
			userId ~= killerUserId
			and contribution.Damage > 0
			and connected(connectedUserIds, userId)
		then
			totalDamage += contribution.Damage
			table.insert(allocations, {
				UserId = userId,
				Damage = contribution.Damage,
				Coins = 0,
				Remainder = 0,
			})
		end
	end
	if totalDamage <= 0 then
		return {}
	end

	local pool = math.max(0, math.floor(killCoins * DamageCredit.AssistPoolFraction + 0.5))
	local assigned = 0
	for _, reward in allocations do
		local exact = pool * reward.Damage / totalDamage
		reward.Coins = math.floor(exact)
		reward.Remainder = exact - reward.Coins
		assigned += reward.Coins
	end
	table.sort(allocations, function(a, b)
		if a.Remainder == b.Remainder then
			return a.UserId < b.UserId
		end
		return a.Remainder > b.Remainder
	end)
	for index = 1, pool - assigned do
		allocations[index].Coins += 1
	end
	table.sort(allocations, function(a, b)
		return a.UserId < b.UserId
	end)
	local rewards: { Reward } = {}
	for _, allocation in allocations do
		table.insert(rewards, {
			UserId = allocation.UserId,
			Damage = allocation.Damage,
			Coins = allocation.Coins,
		})
	end
	return rewards
end

function DamageCredit.clear(ledger: Ledger)
	table.clear(ledger)
end

return DamageCredit
