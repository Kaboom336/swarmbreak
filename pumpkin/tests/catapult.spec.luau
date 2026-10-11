local Catapult = load("Catapult")
local Config = load("Config")
local ProfileSchema = load("ProfileSchema")

test("catapult rejects malformed and nonfinite network input", function()
	eq(Catapult.settings("35", 1), nil)
	eq(Catapult.settings(35, {}), nil)
	eq(Catapult.settings(0 / 0, 1), nil)
	eq(Catapult.settings(35, math.huge), nil)
	local bounded = Catapult.settings(-100, 100)
	eq(bounded.angle, 15)
	eq(bounded.power, 1)
end)

test("launch arcs respond to power and angle and land before gameplay decisions", function()
	local low = Catapult.settings(15, 0.5)
	local high = Catapult.settings(60, 1)
	eq(Catapult.height(0, high), 0)
	eq(Catapult.height(1.1, high), 0)
	eq(Catapult.height(0.4, high) > Catapult.height(0.4, low), true)
	for _, angle in { 15, 35, 60 } do
		for _, power in { 0.5, 0.75, 1 } do
			local settings = Catapult.settings(angle, power)
			for step = 0, 150 do
				local height = Catapult.height(step / 100, settings)
				eq(height >= 0 and height <= Config.CatapultArcHeight, true)
			end
			eq(Catapult.height(Config.RideGentleStartSeconds, settings), 0)
		end
	end
end)

test("catapult upgrades charge once and cap without overspending", function()
	local profile = ProfileSchema.default()
	profile.Wins = 24
	eq(Catapult.buy(profile), false)
	eq(profile.Wins, 24)
	eq(profile.CatapultRank, 0)
	profile.Wins = 25
	eq(Catapult.buy(profile), true)
	eq(profile.Wins, 0)
	eq(profile.CatapultRank, 1)
	eq(Catapult.upgradeCost(1), 50)
	eq(Catapult.buy(profile), false)
	profile.Wins = 10000
	for _ = 2, Config.CatapultMaxRank do
		eq(Catapult.buy(profile), true)
	end
	local balance = profile.Wins
	eq(Catapult.buy(profile), false)
	eq(profile.Wins, balance)
	eq(Catapult.rewardMultiplier(profile.CatapultRank), 1.75)
end)

test("old profiles keep progress and receive safe catapult defaults", function()
	local old = ProfileSchema.fromStored({ Size = 50, Wins = 200 })
	eq(old.CatapultRank, 0)
	eq(old.Size, 50)
	eq(old.Wins, 200)
	eq(ProfileSchema.fromStored({ CatapultRank = 3 }).CatapultRank, 3)
	eq(ProfileSchema.fromStored({ CatapultRank = math.huge }).CatapultRank, 0)
	eq(ProfileSchema.fromStored({ CatapultRank = 999 }).CatapultRank, Config.CatapultMaxRank)
end)
