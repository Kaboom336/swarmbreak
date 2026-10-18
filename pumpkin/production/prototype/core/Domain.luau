-- Pure data/economy operations. No Roblox services, yields or client-controlled rolls.
local Domain = {}
function Domain.copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in value do
		result[key] = Domain.copy(child)
	end
	return result
end
function Domain.finite(n)
	return type(n) == "number" and n == n and math.abs(n) < math.huge
end
function Domain.default()
	return {
		version = 1,
		coins = 0,
		bank = 0,
		pets = {},
		discovered = {},
		pending = nil,
		escapes = 0,
		unlocks = { Meadow = true },
		feed = false,
		shieldUsed = false,
		firstHitUsed = false,
		crownStamps = {},
		awardReceipts = {},
	}
end
function Domain.validate(data, config)
	if type(data) ~= "table" or data.version ~= config.Schema then
		return false, "unknown schema"
	end
	for _, key in { "coins", "bank", "escapes" } do
		if not Domain.finite(data[key]) or data[key] < 0 then
			return false, "invalid " .. key
		end
	end
	if
		type(data.pets) ~= "table"
		or #data.pets > config.MaxPets
		or type(data.discovered) ~= "table"
		or type(data.unlocks) ~= "table"
	then
		return false, "invalid collection"
	end
	local seen = {}
	for _, field in { "crownStamps", "awardReceipts" } do
		if data[field] ~= nil and type(data[field]) ~= "table" then return false, "invalid " .. field end
		for key, value in data[field] or {} do
			if type(key) ~= "string" or value ~= true then return false, "invalid receipt/stamp" end
		end
	end
	local function validPet(pet)
		if type(pet) ~= "table" or type(pet.id) ~= "string" or seen[pet.id] then
			return false
		end
		if not config.Rarities[pet.tier] then
			return false
		end
		seen[pet.id] = true
		if pet.reward then
			local reward = pet.reward
			if type(reward) ~= "table" or reward.version ~= 1
				or type(reward.map) ~= "string" or not Domain.finite(reward.zone) or reward.zone < 1
				or reward.zone % 1 ~= 0 or (reward.kind ~= "Pet" and reward.kind ~= "Relic")
				or type(reward.name) ~= "string" or type(reward.model) ~= "string"
				or not Domain.finite(reward.rate) or reward.rate <= 0 then return false end
		end
		if
			pet.x ~= nil
			and (not Domain.finite(pet.x) or not Domain.finite(pet.z) or not Domain.finite(pet.yaw))
		then
			return false
		end
		return true
	end
	for _, pet in data.pets do
		if not validPet(pet) then
			return false, "invalid pet"
		end
	end
	if data.pending and not validPet(data.pending) then
		return false, "invalid cargo"
	end
	return true
end
function Domain.roll(config, unit)
	assert(Domain.finite(unit) and unit >= 0 and unit < 1, "roll range")
	local total = 0
	for _, rarity in config.Rarities do
		assert(Domain.finite(rarity.weight) and rarity.weight >= 0, "weight")
		total += rarity.weight
	end
	assert(total > 0, "empty roll table")
	local target, sum = unit * total, 0
	for i, rarity in config.Rarities do
		sum += rarity.weight
		if target < sum then
			return i
		end
	end
	error("unreachable roll")
end
function Domain.secure(data, config, id, tier, flags, reward)
	if data.awardReceipts and data.awardReceipts[id] then return true end
	if data.pending and data.pending.id == id then
		return true
	end
	for _, pet in data.pets do
		if pet.id == id then
			return true
		end
	end
	if data.pending or #data.pets >= config.MaxPets then
		return false, "plot full / open cargo first"
	end
	if type(id) ~= "string" or not config.Rarities[tier] then
		return false, "invalid award"
	end
	data.pending = { id = id, tier = #data.pets == 0 and 1 or tier, placed = false }
	if reward then
		data.pending.reward = Domain.copy(reward)
		-- First successful ever earner retains the existing guaranteed Common Pup.
		if data.escapes == 0 then
			data.pending.reward.kind, data.pending.reward.name, data.pending.reward.model = "Pet", "Pup", "Pup"
			data.pending.reward.rate = reward.baseRate or 1
		end
		data.crownStamps, data.awardReceipts = data.crownStamps or {}, data.awardReceipts or {}
		data.crownStamps[reward.map .. ":" .. reward.zone] = true
		data.awardReceipts[id] = true
	end
	data.escapes += 1
	data.shieldUsed, data.firstHitUsed = flags.shieldUsed == true, flags.firstHitUsed == true
	return true
end
function Domain.place(data, id, x, z, yaw)
	local cargo = data.pending
	if not cargo or cargo.id ~= id or cargo.placed then
		return false, "not secured/unplaced"
	end
	if not Domain.finite(x) or not Domain.finite(z) or not Domain.finite(yaw) then
		return false, "invalid placement"
	end
	cargo.x, cargo.z, cargo.yaw, cargo.placed = x, z, yaw % 360, true
	return true
end
function Domain.open(data, config, id)
	local cargo = data.pending
	if not cargo or cargo.id ~= id or not cargo.placed then
		return false, "not placed/already opened"
	end
	if #data.pets >= config.MaxPets then
		return false, "plot full"
	end
	data.pending = nil
	table.insert(data.pets, cargo)
	data.discovered[cargo.reward and cargo.reward.name or config.Rarities[cargo.tier].pet] = true
	return true, cargo
end
function Domain.rate(data, config)
	local rate = 0
	for i, pet in data.pets do
		rate += (pet.reward and pet.reward.rate or config.Rarities[pet.tier].rate) + (data.feed and i == 1 and 1 or 0)
	end
	return rate
end
function Domain.tick(data, config, seconds)
	assert(Domain.finite(seconds) and seconds >= 0 and seconds % 1 == 0, "whole online seconds")
	data.bank += Domain.rate(data, config) * seconds
end
function Domain.collect(data)
	local amount = data.bank
	data.coins += amount
	data.bank = 0
	return true, amount
end
return Domain
