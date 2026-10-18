-- Deterministic, time-stepped player model, not evidence of Studio play or human pacing.
-- Uses the actual Config, price/income/collect/unlock rules and greybox distances.
return function(C,R,D,seed,plotIndex)
	local cashAt={}
	local d=D.default(0)
	local side=plotIndex<=4 and -1 or 1
	local z=((plotIndex-1)%4)*60-90
	local collect={x=side*30,z=z-8}
	local unlock={x=side*30,z=z+8}
	local player={x=0,z=0}
	local lane={{def=1,mutation=1,x=0,z=-8,state="Carpet"}}
	local owned={}
	local now,firstBuy,firstPlaced,firstCollect,firstUnlock=0,nil,nil,nil,nil
	local nextSpawn=3
	local mode="Buy"
	local step=0.25
	local function random()
		seed=(seed*48271)%2147483647
		return seed/2147483647
	end
	local function dist(a,b) return math.sqrt((a.x-b.x)^2+(a.z-b.z)^2) end
	local function walk(target)
		local distance=dist(player,target)
		if distance<=C.WalkSpeed*step then player.x=target.x; player.z=target.z; return true end
		local fraction=C.WalkSpeed*step/distance
		player.x+=(target.x-player.x)*fraction; player.z+=(target.z-player.z)*fraction
		return false
	end
	while now<600 do
		now+=step
		if now>=nextSpawn then
			nextSpawn+=3
			local tier=R.roll(C.Rarities,random())
			local def=(tier-1)*5+math.floor(random()*5)+1
			table.insert(lane,{def=def,mutation=R.roll(C.Mutations,random()),x=0,z=C.LaneStart,state="Carpet"})
		end
		for _,item in lane do if item.state=="Carpet" then
			item.z+=C.LaneSpeed*step
			if item.z>C.LaneEnd then item.state="Expired" end
		end end
		for slot,item in owned do
			if item.placeAt<=now then
				if not item.placed then item.placed=true; firstPlaced=firstPlaced or now end
				item.record.pile+=R.income(item.def,item.mutation)*step
			end
		end
		if mode=="Buy" then
			local target,nearest=nil,math.huge
			for _,item in lane do
				if item.state=="Carpet" and R.price(item.def,item.mutation)<=d.cash then
					local distance=dist(player,item)
					if distance<nearest then target=item; nearest=distance end
				end
			end
			if target and R.firstFree(d) then
				walk(target)
				if now>=2 and R.canBuy(d,target,dist(player,target)) then
					local slot=R.firstFree(d)
					d.cash-=R.price(target.def,target.mutation); d.purchases+=1; target.state="Delivering"
					local record={def=target.def,mutation=target.mutation,pile=0}
					d.owned[tostring(slot)]=record
					local ped={x=side*(39+((slot-1)%5)*7),z=z+(slot<=5 and -12 or 12)}
					owned[slot]={def=target.def,mutation=target.mutation,record=record,placeAt=now+dist(target,ped)/C.DeliverySpeed}
					firstBuy=firstBuy or now; mode="Collect"
				end
			else mode="Collect" end
		elseif mode=="Collect" then
			if walk(collect) then
				local amount=R.collect(d); if amount>0 then firstCollect=firstCollect or now end
				if not firstUnlock and d.cash>=R.unlockCost(d.unlocked) then mode="Unlock"
				else mode="Return" end
			end
		elseif mode=="Unlock" then
			if walk(unlock) then
				local cost=R.unlockCost(d.unlocked)
				assert(d.cash>=cost)
				d.cash-=cost; d.unlocked+=1; firstUnlock=firstUnlock or now; mode="Buy"
			end
		elseif mode=="Return" then
			-- Walk away and back, giving a real Touched edge on the collect pad.
			if walk({x=0,z=z}) then mode="Buy" end
		end
		if now==120 or now==300 or now==600 then cashAt[tostring(now)]=d.cash end
	end
	return {firstBuy=firstBuy,firstPlaced=firstPlaced,firstCollect=firstCollect,firstUnlock=firstUnlock,
		cash=cashAt,rate=R.totalRate(d),purchases=d.purchases,plot=plotIndex}
end
