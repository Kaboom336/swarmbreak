-- Offline expected-value model. No King Night in baseline; no passes, brew or rebirth.
-- Run from giant: lune run scene/econ-sim.luau [tune]
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local Config = luau.load(fs.readFile("src/ReplicatedStorage/PatchConfig.luau"), {
	environment = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2 },
	injectGlobals = true,
})()
local E, P, F = Config.Economy, Config.Progression, Config.Farm
local tune = process.args[1] == "tune"
for level = 0, Config.Upgrades.Boots.max do
	assert(Config.walkSpeed(level) == 16 + level * 2, "Boots speed ladder")
	for _, zone in Config.ZoneOrder do
		local runner = math.max(
			Config.MinCarrySpeed,
			Config.walkSpeed(level) * Config.Movement.sprintMult - Config.SlowPerPumpkin
		)
		assert(Config.GuardSpeed[zone] * runner < runner, "Clean runner must outrun every guard")
	end
end
assert(Config.walkSpeed(100) == 26 and Config.walkSpeed(-1) == 16, "Boots caps")
assert(Config.walkSpeed(5) * Config.Movement.sprintMult == 32.5, "Sprint stays x1.25")
do
	local attrs = {
		RoamFrom = roblox.Vector3.new(0, 0, 0),
		RoamTo = roblox.Vector3.new(10, 0, 0),
		RoamStart = 10,
		RoamEnd = 12,
	}
	local pet = {
		GetAttribute = function(_, key)
			return attrs[key]
		end,
	}
	assert(
		Config.roamPoint(pet, 9).X == 0
			and Config.roamPoint(pet, 11).X == 5
			and Config.roamPoint(pet, 13).X == 10,
		"Roam interpolation and endpoint clamps"
	)
end
local seedRanks = {}
for _, seed in Config.Seeds do
	seedRanks[seed.id] = E.rarityRanks[Config.Pets[seed.pet].rarity]
end
assert(
	E.nestIncome.KingletSeed
		== math.max(E.nestIncome.KingSeed, E.nestIncome.DragonSeed) * E.kingletMult,
	"Kinglet must earn 1.5x the best Zone7 pet"
)
for zoneIndex, id in Config.ZoneOrder do
	for pick = 1, #Config.Zones[id].pets do
		local current = Config.Zones[id].pets[pick]
		assert(
			E.crateSeed(zoneIndex, 1, pick) == current,
			"Ordinary crate must use the player's zone nest"
		)
		for tier = 2, 3 do
			local promoted = E.crateSeed(zoneIndex, tier, pick)
			assert(
				seedRanks[promoted] == math.min(seedRanks[current] + 1, E.rarityRanks.Mythic),
				"Epic/Legendary crate must promote exactly one pet rarity"
			)
		end
	end
end

local function run(crateTier, calibrate, sellCrates)
	local s = {
		candy = Config.StartCandy,
		zone = 1,
		tool = 1,
		boots = 0,
		pets = {},
		owned = {},
		stamps = {},
		steals = {},
		smashes = {},
		arrivals = { 0 },
		costs = {},
		rates = {},
		burst = 0,
		farmed = 0,
		tutorial = false,
	}
	local function stealSeconds()
		local zone = Config.Zones[Config.ZoneOrder[s.zone]]
		local distance = math.max(0, (zone.zMin + zone.zMax) / 2 - E.sim.penZ)
		local walk = Config.walkSpeed(s.boots) * Config.Movement.sprintMult
		-- Dash works only outbound; cooldown limits its expected distance per second.
		local outbound = walk
			+ (s.tool >= Config.Dash.tier and Config.Dash.distance / Config.Dash.cooldown or 0)
		local returning = math.max(Config.MinCarrySpeed, walk - Config.SlowPerPumpkin)
		return math.max(
			Config.HoardRefill,
			E.sim.stealSeconds
				- E.sim.travelBudget
				+ distance / outbound
				+ distance / returning
				+ Config.HoardHold
				+ Config.GuardianWake
		)
	end
	local function slots()
		return s.zone >= 5 and P.castleSlots or s.zone >= 3 and P.woodsSlots or P.baseSlots
	end
	local function mult()
		local count = 0
		for _ in s.stamps do
			count += 1
		end
		return 1 + count * P.stampBonus
	end
	local function place(id, bought)
		local income = E.nestIncome[id] * Config.HoardSize * Config.HoardMult
		local weakest = 1
		for i, pet in s.pets do
			if pet.income < s.pets[weakest].income then
				weakest = i
			end
		end
		if #s.pets < slots() then
			table.insert(s.pets, { income = income, bought = bought })
		elseif income > s.pets[weakest].income then
			local old = s.pets[weakest]
			s.candy += old.income * (old.bought and Config.SellPerIncome or Config.FullPenSellSeconds) * mult()
			s.pets[weakest] = { income = income, bought = bought }
		else
			s.candy += income * (bought and Config.SellPerIncome or Config.FullPenSellSeconds) * mult()
		end
		s.owned[id] = true
		for i, zone in Config.ZoneOrder do
			local pets = Config.Zones[zone].pets
			if s.owned[pets[1]] and s.owned[pets[2]] then
				s.stamps[i] = true
			end
		end
	end
	local function discount()
		local pets = Config.Zones[Config.ZoneOrder[s.zone]].pets
		return (s.smashes[s.zone] or 0) >= P.questSmashes
				and (s.steals[s.zone] or 0) >= P.questSteals
				and (s.owned[pets[1]] or s.owned[pets[2]])
				and 1 - P.gateDiscount
			or 1
	end
	for t = 1, E.sim.durationMinutes * 60 do
		if t == 1 then
			s.candy += Config.DailyCandy
		end
		local zone = Config.Zones[Config.ZoneOrder[s.zone]]
		local tool = Config.Tools[s.tool]
		local interval = not s.tutorial and F.firstSwingSeconds or Config.BonkCooldown
		local damage = tool.damage * (1 + F.critChance * (F.critMult - 1))
		local small = math.max(1, math.ceil(zone.hp / damage))
		local big = math.max(1, math.ceil(zone.hp * F.bigMult / damage))
		local hits = small * (1 - F.bigChance) + big * F.bigChance
		local targets = s.tool >= 3 and F.arcTargets or 1
		local breaks = P.activity * targets / (hits * interval)
		local farm = breaks
			* zone.candy
			* (1 + F.bigChance * (F.bigMult - 1))
			* (1 + (F.goldenMult - 1) / F.goldenOneIn)
		s.rates[s.zone] = farm * 60
		local pen = 0
		for _, pet in s.pets do
			pen += pet.income
		end
		local spooky = t >= Config.SpookyEvery and t % Config.SpookyEvery < Config.SpookyLength
		s.candy += (farm + pen * (spooky and Config.SpookyMult or 1)) * mult()
		s.farmed += farm
		if not s.tutorial and s.farmed >= Config.TutorialOrders[1].need then
			s.tutorial = true
			s.candy += Config.TutorialOrders[1].reward.candy
		end
		s.smashes[s.zone] = (s.smashes[s.zone] or 0) + breaks
		-- Buy Iron before stealing; subsequently buy the matching zone scythe.
		local desired = math.max(2, s.zone)
		if s.tool < desired and s.candy >= Config.Tools[s.tool + 1].cost then
			s.tool += 1
			s.candy -= Config.Tools[s.tool].cost
			if s.tool == 2 then
				s.nextSteal = t + stealSeconds()
			end
		end
		-- Buy each Boots level as soon as affordable, after the required scythe.
		if s.boots < Config.Upgrades.Boots.max then
			local cost = Config.upgradeCost("Boots", s.boots)
			if s.candy >= cost then
				s.candy -= cost
				s.boots += 1
			end
		end
		if s.nextSteal and t >= s.nextSteal then
			s.nextSteal = t + stealSeconds()
			s.steals[s.zone] = (s.steals[s.zone] or 0) + 1
			local pick = 1 + (s.steals[s.zone] - 1) % 2
			place(zone.pets[pick], false)
		end
		if crateTier and table.find(E.sim.crateMinutes, t / 60) then
			local id = E.crateSeed(s.zone, crateTier, 2)
			if sellCrates then
				s.candy += E.nestIncome[id] * Config.HoardSize * Config.HoardMult * Config.SellPerIncome * mult()
			else
				place(id, true)
			end
			-- Include the existing qualified victory candy payout, not just the pet.
			s.candy += math.floor(
				Config.KingNight.farmSeconds * zone.candy / (small * Config.BonkCooldown)
			) * mult()
		end
		local burst = 0
		while s.zone < #Config.ZoneOrder do
			local nextZone = Config.Zones[Config.ZoneOrder[s.zone + 1]]
			local cost = nextZone.cost
			if calibrate and s.zone > 1 then
				if t < P.arrivalMinutes[s.zone + 1] * 60 then
					break
				end
				cost = math.floor(s.candy / discount() / E.roundTo + 0.5) * E.roundTo
			end
			if s.candy < cost * discount() then
				break
			end
			s.costs[s.zone] = cost
			s.candy -= cost * discount()
			s.zone += 1
			s.arrivals[s.zone] = t / 60
			burst += 1
		end
		s.burst = math.max(s.burst, burst)
	end
	return s
end

local base = run(nil, tune)
print(
	"Expected-value assumptions: 50% farm uptime, equal nest rolls, Boots bought when affordable, outbound dash, distance-based round trips, weakest swap/sell, stamps, Spooky Hour; no teleports/passes/brew/rebirth."
)
for i, rate in base.rates do
	print(
		string.format(
			"Zone%d farm: %.2f candy/min before stamps; slots %d",
			i,
			rate,
			i >= 5 and P.castleSlots or i >= 3 and P.woodsSlots or P.baseSlots
		)
	)
end
for i = 2, #Config.ZoneOrder do
	local arrived = base.arrivals[i]
	print(
		string.format(
			"%s affordable: %s min; target %d; cost %s",
			Config.ZoneOrder[i],
			arrived and string.format("%.2f", arrived) or "NEVER",
			P.arrivalMinutes[i],
			tostring(base.costs[i - 1])
		)
	)
	if not tune then
		assert(
			arrived and math.abs(arrived / P.arrivalMinutes[i] - 1) <= E.sim.tolerance,
			"Arrival outside tolerance"
		)
	end
end
if tune then
	print("Tuned costs:", base.costs)
else
	for tier = 1, 4 do
		local result = run(tier, false)
		print(
			"Crates at 20/40 min, tier",
			tier,
			"arrivals",
			result.arrivals,
			"max gates bought in one second",
			result.burst
		)
		assert(result.burst <= 1, "A crate scenario skipped more than one gate at once")
		local sold = run(tier, false, true)
		print("Cash out crates, tier", tier, "max gates bought in one second", sold.burst)
		assert(sold.burst <= 1, "Cashing out crates skipped more than one gate at once")
	end
	print("Boots levels purchased:", base.boots)
	print("OK: Boots + dash arrivals within 25%; all crate tiers cross at most one gate at a time")
end
