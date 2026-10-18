-- Pure, shared authority rules. Inject Config in Lune and Roblox alike.
return function(C)
	local R = {}
	function R.finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
	function R.integer(n, lo, hi) return R.finite(n) and n%1==0 and n>=lo and n<=hi end
	function R.roll(rows, u)
		assert(R.finite(u) and u>=0 and u<1, "roll requires [0,1)")
		local total, cursor = 0, 0
		for _, row in rows do total += row.weight end
		for i, row in rows do
			cursor += row.weight
			if u*total < cursor then return i end
		end
		return #rows
	end
	function R.income(id, mutation)
		if not R.integer(id,1,#C.Earners) or not R.integer(mutation,1,#C.Mutations) then return nil end
		return C.Earners[id].rate*C.Mutations[mutation].multiplier
	end
	function R.price(id, mutation)
		local rate = R.income(id,mutation)
		return rate and math.ceil(rate*C.Earners[id].payback) or nil
	end
	function R.unlockCost(unlocked) return C.UnlockCosts[unlocked-C.StartUnlocked+1] end
	function R.upgradeCost(level)
		return R.integer(level,0,C.MaxUpgrade-1) and math.ceil(C.UpgradeBaseCost*2.5^level) or nil
	end
	function R.walkSpeed(level) return C.WalkSpeed+C.SpeedPerLevel*level end
	function R.firstFree(data, reserved)
		for slot=1,data.unlocked do
			if not data.owned[tostring(slot)] and not (reserved and reserved[slot]) then return slot end
		end
		return nil
	end
	function R.near(distance)
		return R.finite(distance) and distance>=0 and distance<=C.InteractionDistance
	end
	function R.canBuy(data, item, distance)
		return item~=nil and item.state=="Carpet" and R.near(distance)
			and R.firstFree(data)~=nil and R.price(item.def,item.mutation)~=nil
			and data.cash>=R.price(item.def,item.mutation)
	end
	function R.lockState(now, untilTime, readyAt)
		if now<untilTime then return "Locked", math.ceil(untilTime-now) end
		if now<readyAt then return "Cooldown", math.ceil(readyAt-now) end
		return "Ready", 0
	end
	function R.canLock(data, now, untilTime, readyAt, distance)
		return data.purchases>=C.PvPPurchases and R.near(distance)
			and R.lockState(now,untilTime,readyAt)=="Ready"
	end
	function R.canSteal(a)
		return a.thief~=a.owner and a.thiefPurchases>=C.PvPPurchases
			and a.ownerPurchases>=C.PvPPurchases and not a.locked and not a.carrying
			and a.freeSlot and a.state=="Placed" and R.near(a.distance)
			and R.finite(a.held) and a.held>=C.StealHold
	end
	function R.totalRate(data)
		local rate=0
		for _, item in data.owned do rate += R.income(item.def,item.mutation) or 0 end
		return rate
	end
	function R.offline(data, now)
		return R.totalRate(data)*math.clamp(now-data.lastSeen,0,C.OfflineCap)
	end
	function R.tick(data, seconds)
		assert(R.finite(seconds) and seconds>=0)
		for _, item in data.owned do item.pile += R.income(item.def,item.mutation)*seconds end
	end
	function R.collect(data)
		local sum=0
		for _, item in data.owned do sum+=item.pile; item.pile=0 end
		data.cash+=sum
		return sum
	end
	return R
end
