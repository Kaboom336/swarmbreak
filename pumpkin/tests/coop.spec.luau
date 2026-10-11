local Rules = load("CoopRules")
local Schema = load("ProfileSchema")
test("coop preserves legacy wins without converting to gold", function()
	local p = Schema.fromStored({ Wins = 500, TotalWins = 600 })
	eq(p.Wins, 500)
	eq(p.Gold, 0)
	eq(p.PumpkinRank, 0)
end)
test("coop rejects malformed controls and bounds finite controls", function()
	eq(Rules.controls(nil), nil)
	eq(Rules.controls({ yaw = 0 / 0, angle = 35, power = 1 }), nil)
	eq(Rules.controls({ yaw = math.huge, angle = 35, power = 1 }), nil)
	local c = Rules.controls({ yaw = 200, angle = 0, power = 9 })
	eq(c.yaw, 40)
	eq(c.angle, 15)
	eq(c.power, 1.25)
end)
test("coop upgrade spends only gold and grows costs", function()
	local p = Schema.fromStored({ Gold = 100, Wins = 50 })
	eq(Rules.upgrade(p, "pumpkin"), true)
	eq(p.Gold, 80)
	eq(p.PumpkinRank, 1)
	eq(p.Wins, 50)
	eq(Rules.upgrade(p, "pumpkin"), true)
	eq(p.Gold, 0)
	eq(Rules.upgrade(p, "launcher"), false)
	eq(p.LauncherRank, 0)
	eq(Rules.upgrade(p, "invalid"), false)
end)
test("coop bounded ranks and finite currency", function()
	local p = Schema.fromStored({ Gold = 0 / 0, PumpkinRank = 999, LauncherRank = -5 })
	eq(p.Gold, 0)
	eq(p.PumpkinRank, 8)
	eq(p.LauncherRank, 0)
	eq(Rules.upgrade(p, "pumpkin"), false)
end)
test("coop duplicate ghost hit pays once", function()
	local w = Rules.newWave(3)
	eq(Rules.hit(w, 1, 42), true)
	eq(Rules.hit(w, 1, 7), false)
	eq(w.remaining, 2)
	eq(Rules.hit(w, 0, 42), false)
	eq(Rules.hit(w, 4, 42), false)
	eq(Rules.hit(w, 1.2, 42), false)
end)
test("coop contribution bonuses settle at most once", function()
	local w = Rules.newWave(3)
	Rules.hit(w, 1, 42)
	eq(next(Rules.bonus(w)), nil)
	Rules.hit(w, 2, 42)
	Rules.hit(w, 3, 7)
	local bonus = Rules.bonus(w)
	eq(bonus[42], 15)
	eq(bonus[7], 15)
	eq(next(Rules.bonus(w)), nil)
	eq(Rules.hit(w, 2, 42), false)
end)
test("coop departure removes bonus eligibility and reset clears ledger", function()
	local w = Rules.newWave(2)
	Rules.hit(w, 1, 42)
	Rules.depart(w, 42)
	Rules.hit(w, 2, 7)
	local bonus = Rules.bonus(w)
	eq(bonus[42], nil)
	eq(bonus[7], 15)
	local nextWave = Rules.newWave(2, w.number + 1)
	eq(nextWave.number, 2)
	eq(nextWave.remaining, 2)
	eq(Rules.hit(nextWave, 1, 42), true)
	eq(next(Rules.bonus(nextWave)), nil)
end)
test("coop swept collision catches fast shot and degenerate segments", function()
	eq(Rules.segmentDistance(5, 0, 0, 0, 0, 0, 10, 0, 0), 0)
	eq(Rules.segmentDistance(5, 3, 0, 0, 0, 0, 10, 0, 0), 3)
	eq(Rules.segmentDistance(0, 3, 4, 0, 0, 0, 0, 0, 0), 5)
end)
test("coop base launcher reaches every authored ghost above the valley floor", function()
	for row, z in { -60, -90, -120, -145 } do
		local lanes = if row == 4 then { -22, 0, 22 } else { -27, -9, 9, 27 }
		for _, x in lanes do
			local distance = math.sqrt(x * x + (z + 14) ^ 2)
			assert(math.abs(math.deg(math.atan2(x, -z - 14))) <= 40)
			local targetY = 57 + math.min(0, (z + 18) * 0.065)
			local reachable = false
			for angle = 15, 70 do
				for powerIndex = 55, 125 do
					local radians = math.rad(angle)
					local speed = 75 * powerIndex / 100
					local t = distance / (speed * math.cos(radians))
					local y = 59 + speed * math.sin(radians) * t - 0.5 * Rules.Gravity * t * t
					if math.abs(y - targetY) < 2 then
						local clear = true
						for step = 0, 20 do
							local sample = t * step / 20
							local progress = step / 20
							local floor = 50 + math.min(0, (-14 + (z + 14) * progress + 18) * 0.065)
							local height = 59
								+ speed * math.sin(radians) * sample
								- 0.5 * Rules.Gravity * sample * sample
							if height < floor + 1.25 then
								clear = false
							end
						end
						if clear then
							reachable = true
							break
						end
					end
				end
				if reachable then
					break
				end
			end
			assert(reachable, "Ghost unreachable at " .. x .. "," .. z)
		end
	end
end)
test("coop untouched default shot hits a ghost from each rank0 launcher", function()
	local control = Rules.controls(Rules.DefaultControls)
	eq(control.yaw, 5)
	eq(control.angle, 35)
	eq(control.power, 1)
	local yaw, angle = math.rad(control.yaw), math.rad(control.angle)
	local speed = 75 * control.power
	local vx = -math.sin(yaw) * math.cos(angle) * speed
	local vz = -math.cos(yaw) * math.cos(angle) * speed
	local vy = math.sin(angle) * speed
	for _, launcherX in { -18, 0, 18 } do
		local originX, originZ = launcherX - math.sin(yaw) * 4, -10 - math.cos(yaw) * 4
		local lastX, lastY, lastZ = originX, 59, originZ
		local hits = 0
		for step = 1, 180 do
			local t = step / 30
			local x, y, z =
				originX + vx * t, 59 + vy * t - 0.5 * Rules.Gravity * t * t, originZ + vz * t
			local floor = 50 + math.min(0, (z + 18) * 0.065)
			if y < floor then
				break
			end
			for row, targetZ in { -60, -90, -120, -145 } do
				local lanes = if row == 4 then { -22, 0, 22 } else { -27, -9, 9, 27 }
				local targetY = 57 + math.min(0, (targetZ + 18) * 0.065)
				local targetRadius = (6.5 + row * 0.5) / 2 + Rules.diameter(0) / 2 + 1.5
				for _, targetX in lanes do
					if
						Rules.segmentDistance(
							targetX,
							targetY,
							targetZ,
							lastX,
							lastY,
							lastZ,
							x,
							y,
							z
						) <= targetRadius
					then
						hits += 1
					end
				end
			end
			if hits > 0 then
				break
			end
			lastX, lastY, lastZ = x, y, z
		end
		assert(hits > 0, "Default first shot missed from launcher " .. launcherX)
	end
end)
