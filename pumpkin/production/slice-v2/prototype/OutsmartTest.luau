-- Studio integration: live Meadow colliders + production attack/trap/guardian code.
-- Bounded accelerated clock with yields; never awards items, Coins or time.
local Test = {}
function Test.run(api, log)
	local RS, SSS = game:GetService("ReplicatedStorage"), game:GetService("ServerScriptService")
	local Http = game:GetService("HttpService")
	local Arena, Traps = require(SSS.GreyboxArena), require(RS.GreyboxTraps)
	local Kit, Pose = require(RS.MeadowKeeper.Attacks), require(RS.MeadowKeeper.Pose)
	local O, Config = require(RS.MeadowV4.Outsmart), require(RS.GreyboxConfig)
	local a, rows, stage, logged = api.arena(), {}, "setup", 0
	local seen = {}
	local saved = {cf=a.guardian.CFrame, corner=a.wallBaitCorner, immunity=a.decoyImmuneUntil}
	local fixtures = Instance.new("Folder")
	fixtures.Name, fixtures.Parent = "OutsmartFixtures", a.model
	local manager = Traps.new(Config, Arena, function(parent, ...)
		return api.traps.make(parent == a.model and fixtures or parent, ...)
	end, api.traps.label)
	manager.rattle = api.traps.rattle
	local root = Instance.new("Part")
	root.Name, root.Anchored, root.CanCollide, root.CanTouch, root.CanQuery = "OutsmartRunner", true, false, false, false
	root.Transparency, root.Parent = 1, fixtures
	local actor = {UserId=-9001, GetAttribute=function() return nil end}
	local states = {[actor]={phase="Run", run=a, meadowEscapes=3, mercy=0}}
	local state, now = states[actor], os.clock()
	local function check(value, message)
		assert(value, stage .. ": " .. message)
		if not seen[message] then
			seen[message] = true
			if #rows < 64 then table.insert(rows, message) end
			if logged < 12 then logged+=1; log(message) end
		end
	end
	local function ground(localPoint)
		return assert(Arena.floor(a, a.origin + localPoint + Vector3.new(0, 3, 0)), "missing live walking floor")
	end
	local function tick(dt)
		now += dt
		Traps.tick(manager, now, states)
		Arena.tick(a, dt, now, states, function(who) return who==actor and root or nil end,
			function() error("fixture received an attack hit") end, function() end)
		task.wait(0.03)
	end
	api.pvpCourt(true)
	local ok, why = pcall(function()
		stage = "wall bait"
		a.wallBaitCorner = nil -- Isolated fixture; restore live memory on cleanup.
		local start, bait = ground(O.Start), ground(O.Bait)
		local level, laneDetail = O.levelApproach(a, Arena.floor)
		check(level, "chosen corner has level approach: " .. laneDetail)
		a.guardian.CFrame = CFrame.lookAt(start+Vector3.new(0,5.5,0), bait+Vector3.new(0,5.5,0))
		root.Position = bait+Vector3.new(0,3,0)
		local target = root.Position
		check(Kit.begin(a, actor, target, now, "dash", Arena, Pose), "locked dash starts at marked corner")
		local locked = a.attack.direction
		local stars, impact = 0, nil
		local attackAPI = table.clone(Arena)
		attackAPI.fx = function(arena, name, p, radius)
			if name=="WallStun" then stars+=1; impact=p end
			Arena.fx(arena,name,p,radius)
		end
		for i=1,24 do
			now+=0.05
			if i==8 then root.Position=ground(Vector3.new(-58,0,100))+Vector3.new(0,3,0) end
			if a.attack then
				check(a.attack.direction==locked, "dash aim remains committed")
				Kit.step(a,now,states,function() return root end,function() error("sidestep hit") end,attackAPI,Pose)
			end
			task.wait(0.03)
			if not a.attack then break end
		end
		check(a.keeperStunUntil and stars==1 and impact~=nil, "wall impact requests stun and literal-star FX once")
		tick(0.05)
		check(a.guardian:GetAttribute("KeeperClip")=="stun", "wall impact drives live rig stun pose")
		check((a.wallBaitCorner-(a.origin+O.Corner)).Magnitude<13, "stun belongs to chosen broad cover")
		check(a.keeperStunUntil-now<=1.55+0.001, "wall stun capped at 1.55s")
		local firstEnd, corner = a.keeperStunUntil, a.wallBaitCorner
		stage = "no repeat corner"
		-- Adversarial forced second dash after cooldown must still earn no stun.
		now+=13
		a.guardian.CFrame=CFrame.lookAt(start+Vector3.new(0,5.5,0),bait+Vector3.new(0,5.5,0))
		check(Kit.begin(a,actor,target,now,"dash",Arena,Pose), "repeat collision fixture starts")
		for _=1,24 do
			now+=0.05
			if a.attack then Kit.step(a,now,{},function() end,function() error("repeat hit") end,attackAPI,Pose) end
			task.wait(0.03)
			if not a.attack then break end
		end
		check(stars==1 and a.keeperStunUntil==firstEnd and a.wallBaitCorner==corner, "same corner cannot refresh stun or stars")
		a.guardian.CFrame=CFrame.new(start+Vector3.new(0,5.5,0))
		root.Position=a.guardian.Position+Vector3.new(0,-2.5,-20)
		a.throws,a.kitCooldowns=1,{}
		check(Kit.choose(a,actor,now,states,function() return root end)=="fan", "corner recovery selects another attack")
		stage = "bell"
		Arena.reset(a)
		a.decoyImmuneUntil=0
		local point = ground(O.Bell)
		local legal, detail = Traps.spot(manager,a,point,point+Vector3.new(0,3,0))
		check(legal,"legal pre-steal bell floor with open bypass: " .. tostring(detail))
		root.Position=point+Vector3.new(0,3,0)
		Traps.entry(manager,actor,state)
		check(Traps.action(manager,actor,state,a,root.Position,"begin",point,now),"unlocked pre-steal bell begins")
		now+=1.01
		check(Traps.action(manager,actor,state,a,root.Position,"finish",nil,now),"one bell charge placed")
		local trap=manager.active[1]
		check(trap.bell and not trap.bell.CanCollide and not state.trapCharge,"visible bell spends one charge, blocks nobody")
		a.guardian.CFrame=CFrame.new(point+Vector3.new(Config.Traps.Decoy.TriggerRange-1,5.5,0))
		now=trap.armed-0.01; Traps.tick(manager,now,states)
		check(not a.decoy,"bell cannot trigger before arm")
		a.attack={fixture=true}; now+=0.02; Traps.tick(manager,now,states)
		check(not a.decoy and a.attack.fixture,"bell preserves committed attack")
		a.attack=nil
		tick(0.05)
		local rattleAt=trap.part:GetAttribute(Traps.RattleTimeSignal)
		check(a.mode=="DecoyTell" and trap.part:GetAttribute(Traps.RattleSignal)==true
			and rattleAt==a.decoy.started and rattleAt<trap.tellEnd
			and trap.part:GetAttribute("RattleSoundPlayed")==true,"rattle precedes investigation")
		check(a.guardian:GetAttribute("KeeperLookTarget")==point,"head look target is the bell")
		local began=rattleAt
		tick(0.35)
		local towards=Vector3.new(point.X,a.guardian.Position.Y,point.Z)-a.guardian.Position
		check((a.guardian.CFrame.LookVector:Dot(towards.Unit))>0.7,"Keeper turns toward bell")
		while now<trap.tellEnd+0.05 do tick(0.05) end
		check(a.mode=="Investigate" and a.warning.Text:find("?",1,true) and a.guardian:GetAttribute("KeeperAttention")=="Investigate","question-mark investigation follows 1.2s tell")
		local ends=trap.effectEnd
		check(math.abs(trap.tellEnd-began-1.2)<0.001 and math.abs(ends-trap.tellEnd-2)<0.001,"existing tell and investigation caps preserved")
		stage="route switch"
		-- Move the runner along the existing south cross-link while attention stays on bell.
		for x=-48,-32,2 do
			root.Position=ground(Vector3.new(x,0,100))+Vector3.new(0,3,0)
			tick(0.05)
			check(a.mode=="Investigate" and not a.target,"runner changes route while Keeper investigates")
		end
		check((root.Position-point).Magnitude>12 and trap.effectEnd==ends,"route switch neither cancels bell nor refreshes its timer")
		while now<ends+0.05 do tick(0.05) end
		check(not a.decoy and #manager.active==0 and a.decoyImmuneUntil>=ends+8,"one-shot bell cleanup and global immunity")
		check(a.mode~="Investigate" and a.mode~="DecoyTell","Keeper resumes after bounded investigation")
		-- A different owner's armed bell cannot chain the investigation.
		local second={UserId=-9002,GetAttribute=actor.GetAttribute}
		states[second]={phase="Run",run=a,meadowEscapes=3}
		Traps.entry(manager,second,states[second])
		check(Traps.action(manager,second,states[second],a,point+Vector3.new(0,3,0),"begin",point,now),"second-owner immunity fixture begins")
		now+=1.01
		check(Traps.action(manager,second,states[second],a,point+Vector3.new(0,3,0),"finish",nil,now),"second-owner immunity fixture placed")
		a.guardian.CFrame=CFrame.new(point+Vector3.new(5,5.5,0))
		now+=2.01;Traps.tick(manager,now,states)
		check(not a.decoy,"global immunity rejects another owner's bell")
	end)
	local bell=manager.active[1]
	local failure={stage=stage,error=ok and "" or tostring(why):sub(1,2000),checks=rows,clock=now,
		mode=a.mode,attention=a.guardian:GetAttribute("KeeperAttention"),
		rattled=bell and bell.part:GetAttribute(Traps.RattleSignal),rattleAt=bell and bell.part:GetAttribute(Traps.RattleTimeSignal),
		soundPlayed=bell and bell.part:GetAttribute("RattleSoundPlayed"),tellEnd=bell and bell.tellEnd,effectEnd=bell and bell.effectEnd,
		triggerRange=Config.Traps.Decoy.TriggerRange,
		dashStopReason=a.model:GetAttribute("DashStopReason"),dashStopCollider=a.model:GetAttribute("DashStopCollider")}
	SSS:SetAttribute("OutsmartTestFailureJSON",Http:JSONEncode(failure))
	Traps.clearIsland(manager,a)
	Arena.reset(a)
	a.guardian.CFrame,a.wallBaitCorner,a.decoyImmuneUntil=saved.cf,saved.corner,saved.immunity
	root:Destroy()
	fixtures:Destroy()
	api.pvpCourt(false)
	assert(ok,why)
	return "live collision: bait/stun/star event; no repeat corner; rattle/head/?/route switch; immunity (accelerated clock)"
end
return Test
