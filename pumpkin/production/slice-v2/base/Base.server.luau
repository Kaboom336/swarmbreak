local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Physics=game:GetService("PhysicsService")
local SSS=game:GetService("ServerScriptService")
local shared=RS:WaitForChild("TreasureBase")
local C=require(shared.Config)
local R=require(shared.Rules)(C)
local D=require(shared.SaveDomain)(C,R)
local F=require(shared.EarnerModel)(C,R)
local action,state,toast,pop=shared.Action,shared.State,shared.Toast,shared.Pop
local world=workspace:WaitForChild("TreasureBase")
local sessions,items,claims,holds={}, {}, {}, {}
local rng=Random.new()
local uid=0
local store
if Run:IsStudio() and not SSS:GetAttribute("BaseUseDataStoreInStudio") then
	store=require(script.Parent.MockStore)(D)
else
	store=require(script.Parent.Profiles)(C,D,game:GetService("DataStoreService"):GetDataStore("TreasureBase_v1"),
		game.JobId..Http:GenerateGUID(false),os.time)
end
-- Characters cannot push each other to manufacture hits; damage is the hit hook.
pcall(function() Physics:RegisterCollisionGroup("BaseCharacters") end)
Physics:CollisionGroupSetCollidable("BaseCharacters","BaseCharacters",false)
local function root(player)
	local char=player.Character
	local h=char and char:FindFirstChildOfClass("Humanoid")
	local r=char and char:FindFirstChild("HumanoidRootPart")
	if h and h.Health>0 then return r,h end
	return nil
end
local function distance(player,part)
	local r=root(player)
	return r and (r.Position-part.Position).Magnitude or math.huge
end
local function inside(plot,pos)
	local delta=pos-plot.Floor.Position
	return math.abs(delta.X)<=28 and math.abs(delta.Z)<=24 and pos.Y>=-3 and pos.Y<=18
end
local function active(player)
	local s=sessions[player]
	return s and not s.leaving and s.profile:IsActive() and s or nil
end
local function speed(player)
	local s=sessions[player]; local _,h=root(player)
	if s and h then h.WalkSpeed=s.carry and C.CarrySpeed or R.walkSpeed(s.data.upgrades) end
end
local function setState(item,value)
	item.state=value; item.part:SetAttribute("State",value)
	item.part:SetAttribute("OwnerId",item.owner and item.owner.UserId or 0)
	item.part.BuyPrompt.Enabled=value=="Carpet"
	item.part.StealPrompt.Enabled=value=="Placed"
end
local function pedestal(s,slot) return s.plot.Pedestals["Pedestal"..slot] end
local function snapshot(player)
	local s=sessions[player]; if not s then return end
	local target
	if s.carry then target=s.plot.Home
	elseif s.data.tutorial==1 then
		local best=math.huge
		for _,item in items do
			if item.state=="Carpet" and R.price(item.def,item.mutation)<=s.data.cash then
				local d=distance(player,item.part)
				if d<best then best=d; target=item.part end
			end
		end
	elseif s.data.tutorial==2 then target=s.plot.Collect
	elseif s.data.tutorial==3 then target=s.plot.Unlock end
	local status,seconds=R.lockState(os.clock(),s.lockUntil,s.readyAt)
	state:FireClient(player,{cash=s.data.cash,rate=R.totalRate(s.data),stage=s.data.tutorial,
		plot=s.plot.Name,discovered=s.data.discovered,carrying=s.carry~=nil,target=target,
		lock=status,lockSeconds=seconds,pvp=s.data.purchases>=C.PvPPurchases,
		offlineRate=R.totalRate(s.data)*C.OfflineCap})
end
local function refresh(s)
	s.plot:SetAttribute("PvPEnabled",s.data.purchases>=C.PvPPurchases)
	s.plot.Floor.Sign.Text.Text=s.player.DisplayName.."'s base"
	local pile=0
	for _,v in s.data.owned do pile+=v.pile end
	s.plot.Collect.Sign.Text.Text=string.format("Collect $%.1f",pile)
	local cost=R.unlockCost(s.data.unlocked)
	s.plot.Unlock.Sign.Text.Text=cost and ("Unlock pedestal\n$"..cost) or "All pedestals unlocked"
	local upgrade=R.upgradeCost(s.data.upgrades)
	s.plot.Upgrade.Sign.Text.Text=upgrade and ("Speed +2\n$"..upgrade) or "Speed MAX"
	for n=1,C.PedestalCount do
		local p=pedestal(s,n); p:SetAttribute("Unlocked",n<=s.data.unlocked)
		p.Color=n<=s.data.unlocked and Color3.fromRGB(170,170,170) or Color3.fromRGB(90,90,90)
		if p:FindFirstChild("Sign") then p.Sign.Enabled=n>s.data.unlocked end
	end
end
local function save(s,ending)
	if s.saving then return false end
	s.saving=true; s.data.lastSeen=os.time()
	local ok
	if ending then ok=s.profile:EndSession() else ok=s.profile:Save() end
	s.saving=false
	if not ok then warn("Base save failed: "..s.player.Name) end
	return ok
end
local function dirty(s)
	refresh(s); snapshot(s.player)
	-- Mutations finish without yielding; persistence runs afterward.
	task.defer(function() if not s.leaving then save(s,false) end end)
end
local function ownerSession(item) return item.owner and sessions[item.owner] end
local function restore(item)
	local owner=ownerSession(item)
	if owner then
		setState(item,"Placed"); item.part.Position=pedestal(owner,item.slot).Position+Vector3.new(0,2.2,0)
	else
		items[item.uid]=nil; item.part:Destroy()
	end
end
local function drop(player)
	local s=sessions[player]; if not s or not s.carry then return end
	local item=s.carry; s.carry=nil; s.reserved[item.destSlot]=nil
	item.carrier=nil; item.destSlot=nil
	-- Greybox recovery: dropped loot immediately returns to the original pedestal.
	restore(item); speed(player); snapshot(player)
end
local function grantSlap(player)
	local s=sessions[player]
	local bag=player:FindFirstChild("Backpack")
	if not s or s.data.purchases<C.PvPPurchases or not bag then return end
	if bag:FindFirstChild("Slap") or (player.Character and player.Character:FindFirstChild("Slap")) then return end
	local tool=Instance.new("Tool"); tool.Name="Slap"; tool.RequiresHandle=false; tool.CanBeDropped=false
	tool.ToolTip="Hit a nearby thief to return your treasure"
	tool.Activated:Connect(function()
		local actor=active(player); local r=root(player)
		if not actor or not r or tool.Parent~=player.Character or actor.data.purchases<C.PvPPurchases then return end
		if os.clock()-(actor.lastHit or -10)<1.2 then return end
		actor.lastHit=os.clock()
		for thief,s in sessions do
			local target=root(thief)
			if thief~=player and s.carry and target and (target.Position-r.Position).Magnitude<=7 then
				-- Only the treasure's owner can recover it; no damage or client-supplied hit result.
				if s.carry.owner==player then drop(thief); toast:FireClient(thief,"Hit! Treasure returned."); break end
			end
		end
	end)
	tool.Parent=bag
end
local function buy(player,item)
	local s=active(player)
	if not s or s.carry or not item or not R.canBuy(s.data,item,distance(player,item.part)) then return false end
	local slot=R.firstFree(s.data,s.reserved); if not slot then return false end
	local data={def=item.def,mutation=item.mutation,pile=0}
	s.data.cash-=R.price(item.def,item.mutation); s.data.purchases+=1
	s.data.owned[tostring(slot)]=data; s.data.discovered[tostring(item.def)]=true
	if s.data.tutorial==1 then s.data.tutorial=2 end
	item.owner=player; item.slot=slot; item.record=data; setState(item,"Delivering")
	if s.data.purchases==C.PvPPurchases then
		grantSlap(player); toast:FireClient(player,"Stealing, lock and slap unlocked!")
	end
	dirty(s); return true
end
local function validSteal(player,item,held)
	local s=active(player); local owner=item and ownerSession(item)
	if not s or not owner or not active(owner.player) then return false end
	return R.canSteal({thief=player,owner=item.owner,thiefPurchases=s.data.purchases,
		ownerPurchases=owner.data.purchases,locked=os.clock()<owner.lockUntil,carrying=s.carry~=nil,
		freeSlot=R.firstFree(s.data,s.reserved)~=nil,state=item.state,distance=distance(player,item.part),held=held})
end
local function steal(player,item)
	local h=holds[player]; holds[player]=nil
	if not h or not item or h.uid~=item.uid or not validSteal(player,item,os.clock()-h.started) then return false end
	local s=sessions[player]; local slot=R.firstFree(s.data,s.reserved)
	s.reserved[slot]=true; s.carry=item; item.carrier=player; item.destSlot=slot
	setState(item,"Carried"); speed(player)
	toast:FireClient(item.owner,player.DisplayName.." is stealing your "..C.Earners[item.def].name.."!")
	snapshot(player); return true
end
local function lock(player)
	local s=active(player); if not s then return false end
	local now=os.clock()
	if not R.canLock(s.data,now,s.lockUntil,s.readyAt,distance(player,s.plot.Lock)) then return false end
	s.lockUntil=now+C.LockDuration; s.readyAt=s.lockUntil+C.LockCooldown
	s.plot.Barrier.CanCollide=true; s.plot.Barrier.Transparency=0.5
	toast:FireClient(player,"Base locked for 60s"); snapshot(player); return true
end
local function collect(player)
	local s=active(player)
	if not s or not R.near(distance(player,s.plot.Collect)) then return false end
	local amount=R.collect(s.data)
	if amount<=0 then return false end
	pop:FireClient(player,s.plot.Collect.Position,amount)
	if s.data.tutorial==2 then s.data.tutorial=3 end
	dirty(s); return true
end
local function pad(player,which)
	local s=active(player); if not s or s.carry or not R.near(distance(player,s.plot[which])) then return end
	if which=="Unlock" then
		local cost=R.unlockCost(s.data.unlocked)
		if not cost or s.data.cash<cost then return end
		s.data.cash-=cost; s.data.unlocked+=1
		if s.data.tutorial==3 then s.data.tutorial=4 end
	elseif which=="Upgrade" then
		local cost=R.upgradeCost(s.data.upgrades)
		if not cost or s.data.cash<cost then return end
		s.data.cash-=cost; s.data.upgrades+=1; speed(player)
	end
	dirty(s)
end
local function register(part)
	local item={uid=part.Name,part=part,def=part:GetAttribute("Def"),mutation=part:GetAttribute("Mutation"),state=part:GetAttribute("State")}
	items[item.uid]=item
	part.BuyPrompt.Triggered:Connect(function(player) buy(player,item) end)
	part.StealPrompt.PromptButtonHoldBegan:Connect(function(player)
		if validSteal(player,item,C.StealHold) then holds[player]={uid=item.uid,started=os.clock()} end
	end)
	part.StealPrompt.PromptButtonHoldEnded:Connect(function(player)
		local h=holds[player]
		task.delay(0.1,function() if holds[player]==h then holds[player]=nil end end)
	end)
	part.StealPrompt.Triggered:Connect(function(player) steal(player,item) end)
	return item
end
local function spawnEarner(def,mutation,pos)
	uid+=1
	return register(F.create(world.Earners,"E"..uid,def,mutation,pos,"Carpet"))
end
for _,part in world.Earners:GetChildren() do register(part) end
for _,plot in world.Plots:GetChildren() do
	plot.Lock.LockPrompt.Triggered:Connect(function(player)
		local s=active(player); if s and s.plot==plot then lock(player) end
	end)
	for _,which in {"Collect","Unlock","Upgrade"} do
		local touchTimes={}
		plot[which].Touched:Connect(function(hit)
			local player=Players:GetPlayerFromCharacter(hit.Parent)
			local s=player and active(player)
			if not s or s.plot~=plot or os.clock()-(touchTimes[player.UserId] or -10)<1 then return end
			touchTimes[player.UserId]=os.clock()
			if which=="Collect" then collect(player) else pad(player,which) end
		end)
	end
end
local function character(player,char)
	local s=sessions[player]; if not s then return end
	drop(player); holds[player]=nil
	local humanoid=char:WaitForChild("Humanoid",10); local r=char:WaitForChild("HumanoidRootPart",10)
	if not humanoid or not r or not sessions[player] then return end
	local function configure(p)
		if p:IsA("BasePart") then
			p.CollisionGroup="BaseCharacters"
			local no=Instance.new("NoCollisionConstraint"); no.Part0=p; no.Part1=s.plot.Barrier; no.Parent=p
		end
	end
	for _,p in char:GetDescendants() do configure(p) end
	char.DescendantAdded:Connect(configure)
	local health=humanoid.Health
	humanoid.HealthChanged:Connect(function(value) if value<health then drop(player) end; health=value end)
	humanoid.Died:Connect(function() drop(player); holds[player]=nil end)
	s.lastPos=r.Position; s.lastMotion=os.clock(); speed(player); grantSlap(player)
end
local closing=false
local function join(player)
	if closing then player:Kick("Server closing; please rejoin."); return end
	local plot
	for _,p in world.Plots:GetChildren() do if not claims[p] then plot=p; claims[p]=player; break end end
	if not plot then player:Kick("All eight plots are occupied."); return end
	local profile=store:StartSessionAsync("u"..player.UserId,os.time())
	if not profile then claims[plot]=nil; player:Kick("Save unavailable or already open. Please rejoin."); return end
	if player.Parent~=Players or closing then profile:EndSession(); claims[plot]=nil; return end
	local d=profile.Data
	d.cash+=R.offline(d,os.time()); d.lastSeen=os.time()
	local s={player=player,plot=plot,profile=profile,data=d,reserved={},lockUntil=0,readyAt=0,
		lastAction=-10,lastSave=os.clock(),lastPos=nil,lastMotion=os.clock()}
	sessions[player]=s; plot:SetAttribute("OwnerId",player.UserId)
	for slot,record in d.owned do
		local item=spawnEarner(record.def,record.mutation,pedestal(s,tonumber(slot)).Position+Vector3.new(0,2.2,0))
		item.owner=player; item.slot=tonumber(slot); item.record=record; setState(item,"Placed")
	end
	-- Guaranteed first affordable target for each newcomer, not a free purchase.
	if d.purchases==0 then spawnEarner(1,1,Vector3.new(0,2,-8)) end
	player.CharacterAdded:Connect(function(char) character(player,char) end)
	if player.Character then task.spawn(character,player,player.Character) end
	refresh(s); snapshot(player)
end
local function leave(player)
	local s=sessions[player]; holds[player]=nil; if not s or s.leaving then return end
	s.leaving=true; drop(player)
	for other,o in sessions do if o.carry and o.carry.owner==player then drop(other) end end
	-- Leave no owned item behind in a plot allocated to a new player.
	for id,item in items do if item.owner==player then item.part:Destroy(); items[id]=nil end end
	local deadline=os.clock()+12
	while s.saving and os.clock()<deadline do task.wait(0.1) end
	local saved=false
	for _=1,3 do if save(s,true) then saved=true; break end; task.wait(0.5) end
	if not saved then warn("UNSAVED profile on leave: "..player.UserId) end
	sessions[player]=nil; claims[s.plot]=nil; s.plot:SetAttribute("OwnerId",0)
	s.plot.Barrier.CanCollide=false; s.plot.Barrier.Transparency=1
	s.plot.Floor.Sign.Text.Text="Unclaimed base"
	s.plot:SetAttribute("PvPEnabled",false)
end
Players.PlayerAdded:Connect(join); Players.PlayerRemoving:Connect(leave)
for _,p in Players:GetPlayers() do task.spawn(join,p) end
action.OnServerEvent:Connect(function(player,verb,id)
	local s=active(player)
	if not s or type(verb)~="string" or (id~=nil and (type(id)~="string" or #id>40)) then return end
	if os.clock()-s.lastAction<0.15 then return end
	s.lastAction=os.clock()
	if verb=="Ready" then snapshot(player)
	elseif verb=="Buy" then buy(player,items[id])
	elseif verb=="Steal" then steal(player,items[id])
	elseif verb=="Lock" then lock(player)
	elseif verb=="Collect" then collect(player)
	elseif verb=="Drop" then drop(player) end
end)
local spawnClock,tickClock,legendClock=0,0,0
local lastLegend=300
Run.Heartbeat:Connect(function(dt)
	local now=os.clock()
	spawnClock+=dt; tickClock+=dt; legendClock+=dt
	if spawnClock>=C.SpawnInterval then
		spawnClock%=C.SpawnInterval
		local tier=R.roll(C.Rarities,rng:NextNumber())
		if legendClock>=300 then tier=4; legendClock=0; lastLegend=300 end
		spawnEarner((tier-1)*5+rng:NextInteger(1,5),R.roll(C.Mutations,rng:NextNumber()),Vector3.new(0,2,C.LaneStart))
	end
	for player,h in holds do
		local item=items[h.uid]
		if not item or not validSteal(player,item,C.StealHold) then holds[player]=nil end
	end
	for _,item in items do
		if item.state=="Carpet" then
			item.part.Position+=Vector3.new(0,0,C.LaneSpeed*dt)
			if item.part.Position.Z>C.LaneEnd then items[item.uid]=nil; item.part:Destroy() end
		elseif item.state=="Delivering" then
			local s=ownerSession(item)
			if s then
				local target=pedestal(s,item.slot).Position+Vector3.new(0,2.2,0)
				local delta=target-item.part.Position
				if delta.Magnitude<=C.DeliverySpeed*dt then
					item.part.Position=target; setState(item,"Placed"); toast:FireClient(item.owner,"Treasure placed!")
				else item.part.Position+=delta.Unit*C.DeliverySpeed*dt end
			end
		elseif item.state=="Carried" then
			local r=root(item.carrier)
			if r then item.part.CFrame=r.CFrame*CFrame.new(0,0,-3) else drop(item.carrier) end
		end
	end
	for player,s in sessions do
		local r=root(player)
		if not s.profile:IsActive() and not s.leaving then player:Kick("Save lease expired. Rejoin safely.") end
		if r then
			if s.carry and s.lastPos then
				local delta=r.Position-s.lastPos
				if Vector3.new(delta.X,0,delta.Z).Magnitude>C.CarrySpeed*(now-s.lastMotion)+5 then drop(player) end
			end
			-- Validate carry travel; a teleport never completes a theft.
			if now-s.lastMotion>=0.2 then
				local elapsed=now-s.lastMotion
				if s.carry and s.lastPos then
					local delta=r.Position-s.lastPos
					if Vector3.new(delta.X,0,delta.Z).Magnitude>C.CarrySpeed*elapsed+5 then drop(player) end
				end
				s.lastPos=r.Position; s.lastMotion=now
			end
			-- Server ejection also covers teleporting through a lock barrier.
			for _,owner in sessions do
				if owner~=s and now<owner.lockUntil and inside(owner.plot,r.Position) then
					drop(player); r.CFrame=CFrame.new(owner.plot.Entry.Position+Vector3.new(owner.plot.Entry.Position.X<0 and 5 or -5,3,0))
				end
			end
			if s.carry and inside(s.plot,r.Position) then
				local item=s.carry; local owner=ownerSession(item)
				if owner and active(owner.player) then
					-- The victim keeps cash already earned; the thief starts from an empty pile.
					owner.data.cash+=item.record.pile; item.record.pile=0
					owner.data.owned[tostring(item.slot)]=nil
					s.data.owned[tostring(item.destSlot)]=item.record
					s.data.discovered[tostring(item.def)]=true
					item.owner=player; item.slot=item.destSlot
					s.reserved[item.destSlot]=nil; s.carry=nil; item.carrier=nil; item.destSlot=nil
					restore(item); speed(player); dirty(owner); dirty(s)
					toast:FireClient(owner.player,"Your treasure was stolen!"); toast:FireClient(player,"Treasure stolen!")
				else drop(player) end
			end
		end
		local status,seconds=R.lockState(now,s.lockUntil,s.readyAt)
		s.plot.Barrier.CanCollide=status=="Locked"; s.plot.Barrier.Transparency=status=="Locked" and 0.5 or 1
		s.plot.Lock.LockPrompt.Enabled=s.data.purchases>=C.PvPPurchases and status=="Ready"
		s.plot.Lock.Sign.Text.Text=s.data.purchases<C.PvPPurchases and "Lock / steal after 3 buys" or (status.." "..seconds.."s")
		if now-s.lastSave>=C.SaveInterval and not s.leaving then
			s.lastSave=now; task.spawn(save,s,false)
		end
	end
	if tickClock>=1 then
		local seconds=math.floor(tickClock); tickClock-=seconds
		for player,s in sessions do
			if not s.leaving then
				-- Only physically placed treasures earn, not delivery or carry reservations.
				for _,item in items do
					if item.owner==player and item.state=="Placed" then
						local gain=R.income(item.def,item.mutation)*seconds; item.record.pile+=gain
						pop:FireAllClients(item.part.Position,gain)
					end
				end
				refresh(s); snapshot(player)
			end
		end
		local countdown=math.ceil(300-legendClock)
		if countdown~=lastLegend then shared:SetAttribute("LegendaryIn",countdown); lastLegend=countdown end
	end
end)
game:BindToClose(function()
	closing=true
	for player in sessions do task.spawn(leave,player) end
	local deadline=os.clock()+25
	while next(sessions) and os.clock()<deadline do task.wait(0.1) end
end)
