-- Live server integration. Uses actual production holds, hit/drop, vault and map queries.
local Test = {}
function Test.run(api, log)
	local RS = game:GetService("ReplicatedStorage")
	local R = require(RS.MeadowV4.RaidSlice)
	local Arena = require(game:GetService("ServerScriptService").GreyboxArena)
	local Config = require(RS.GreyboxConfig)
	local a = api.arena()
	local actors = api.rules.actors
	api.pvpCourt(true)
	local nest = assert(api.rules.active, "fresh nest missing")
	local dummy = api.dummy(nest.position + Vector3.new(0, 3, 0))
	local root, hum = api.root(dummy)
	local state = actors[dummy]
	root.Anchored = true
	local began = os.clock()
	local rows, seen = {}, {}
	local function check(ok, message)
		assert(ok, message)
		if not seen[message] then
			seen[message] = true
			table.insert(rows, message)
			log(message)
		end
	end
	local function floor(p)
		return assert(Arena.floor(a, a.origin + p + Vector3.new(0, 3, 0)), "live fork floor")
	end
	local function put(p)
		root.CFrame = CFrame.new(floor(p) + Vector3.new(0, 3, 0))
	end
	local function tick()
		local busy = api.raidStep(0.03, os.clock(), actors, api.root, api.hit, api.rules.active)
		check(not (a.attack and a.raidBusy), "one damaging commitment at once")
		return busy
	end
	local ok, why = pcall(function()
		check(api.holdAction(dummy, "Steal", "begin"), "production Steal begins")
		task.wait(Config.HoldSeconds.Steal + 0.05)
		check(api.holdAction(dummy, "Steal", "finish"), "production Steal completes")
		local item = assert(state.item, "completed steal must carry cargo")
		local deadline = item.escapeDeadline
		local id = item.id
		task.wait(Config.MercySeconds + 0.55)
		put(Vector3.new(-94, 0, 40))
		a.raidItem = nil
		tick()
		check(a.raid and #a.raid.units == 2, "exactly two surface Sprout Runners spawned")
		local first = a.raid.commit
		R.ready(a, dummy, first.serial, os.clock())
		put(Vector3.new(-94, 0, 58)) -- Other lane while lane 1 is committed.
		while a.raid and a.raid.index == 1 do
			local c = a.raid.commit
			if c and os.clock() - c.start < R.Tuning.Warning then
				check(not a.raid.model:GetAttribute("Charging"), "no charge before 1.2s")
			end
			tick()
			task.wait(0.03)
		end
		check(state.item == item and (state.catches or 0) == 0, "other lane carrier is not hit")
		local c = assert(a.raid.commit, "second commitment missing")
		check(c.lane == 2, "second runner locks second authored lane")
		R.ready(a, dummy, c.serial, os.clock())
		local tellStart = c.start
		put(Vector3.new(-94, 0, 58))
		local hitStart = root.Position
		while a.raid and state.item do
			tick()
			task.wait(0.03)
		end
		check(os.clock() - tellStart >= 1.2, "full tell before committed hit")
		check(
			item.state == "Dropped" and state.catches == 1 and state.mercy > os.clock(),
			"committed lane uses production knock-drop and mercy"
		)
		check((root.Position - hitStart).Magnitude > 0.1, "existing knockback moves the carrier")
		check(
			Arena.floor(a, item.position + Vector3.new(0, 3, 0)) ~= nil,
			"drop has reachable production floor"
		)
		check(item.id == id and item.escapeDeadline == deadline, "same cargo identity and deadline")
		check(not api.hit(dummy, root.Position - Vector3.xAxis, "Guardian"), "shared mercy rejects next hit")
		check(not api.hit(dummy, root.Position - Vector3.xAxis, "Pvp"), "PvP shares mercy")
		while a.raid do
			tick()
			task.wait(0.03)
		end
		check(not a.model:FindFirstChild("RaidSquad"), "minions despawn cleanly")
		-- A real Jump request is the only entry into authoritative vault interpolation.
		put(Vector3.new(-98, 0, 49))
		local start = root.Position
		check(not api.requestVault(dummy, false, Vector3.zAxis), "walking alone never vaults")
		put(Vector3.new(-92, 0, 49))
		check(not api.requestVault(dummy, true, Vector3.zAxis), "Jump outside marked wall never vaults")
		local bypassParams = RaycastParams.new()
		bypassParams.FilterType = Enum.RaycastFilterType.Include
		bypassParams.FilterDescendantsInstances = { a.v4 }
		for i = 1, #R.Bypass - 1 do
			local p, q = R.Bypass[i], R.Bypass[i + 1]
			for j = 0, 20 do
				local sample = floor(p:Lerp(q, j / 20))
				check(
					not workspace:Blockcast(
						CFrame.new(sample + Vector3.new(0, 3, 0)),
						Vector3.new(2, 4, 2),
						Vector3.new(0, 0.01, 0),
						bypassParams
					),
					"walking bypass body clearance"
				)
			end
		end
		put(Vector3.new(-98, 0, 49))
		root.Anchored = false
		check(api.requestVault(dummy, true, Vector3.zAxis), "Jump at marked wall starts vault")
		local untilTime = os.clock() + R.Tuning.VaultSeconds + 0.3
		repeat
			api.stepVaults(os.clock())
			task.wait(0.02)
		until os.clock() > untilTime
		root.Anchored = true
		check(
			root.Position.Z > start.Z + 6 and math.abs(root.Position.X - start.X) < 0.5,
			"production vault reaches opposite floor"
		)
		local walk = 0
		for i = 1, #R.Bypass - 1 do
			walk += (R.Bypass[i + 1] - R.Bypass[i]).Magnitude
		end
		check(R.Tuning.VaultSeconds < walk / Config.CarrySpeed, "vault faster than walking bypass")
		-- Reclaim the same real cargo; unlock state is per player, never a timer.
		root.CFrame=CFrame.new(item.position+Vector3.new(0,3,0))
		task.wait(math.max(0,(item.settle or 0)-os.clock())+0.1)
		check(api.holdAction(dummy,'Grab','begin'),'production recovery begins for east encounter')
		task.wait(Config.HoldSeconds.Grab+0.05)
		check(api.holdAction(dummy,'Grab','finish'),'production recovery completes for east encounter')
		task.wait(math.max(0,(state.mercy or 0)-os.clock())+0.55)
		local east=R.Encounters[2]
		state.meadowEscapes=0
		put(east.approach-Vector3.new(0,3,0));a.raidItem=nil
		check(not tick() and not a.raid,'east stays unarmed before first successful escape')
		state.meadowEscapes=1
		tick()
		check(a.raid and a.raid.encounter==east and #a.raid.units==2,'east arms after first successful escape')
		local eastCommit=a.raid.commit
		R.ready(a,dummy,eastCommit.serial,os.clock())
		put((east.lanes[2][1]+east.lanes[2][2])/2)
		while a.raid do tick();task.wait(0.03) end
		check(state.item==item and item.id==id and item.escapeDeadline==deadline,'east keeps cargo identity deadline and full client-warning protection')
		check(not tick(),'east retires once per cargo')
		for _,e in R.Encounters do
		 for i=1,#e.bypass-1 do
		  for j=0,20 do
		   local sample=floor(e.bypass[i]:Lerp(e.bypass[i+1],j/20))
		   check(not workspace:Blockcast(CFrame.new(sample+Vector3.new(0,3,0)),Vector3.new(2,4,2),Vector3.new(0,.01,0),bypassParams),e.name..' walking bypass body clearance')
		  end
		 end
		end
		put(Vector3.new(east.wall.X,east.wall.Y-1.12,east.wall.Z-4))
		local eastStart=root.Position
		root.Anchored=false
		check(api.requestVault(dummy,true,Vector3.zAxis),'east production Jump starts vault')
		local eastUntil=os.clock()+R.Tuning.VaultSeconds+0.3
		repeat api.stepVaults(os.clock());task.wait(.02) until os.clock()>eastUntil
		root.Anchored=true
		check(root.Position.Z>eastStart.Z+6 and math.abs(root.Position.X-eastStart.X)<.5,'east production vault reaches opposite floor')
	end)
	api.stopVault(dummy)
	R.clear(a)
	api.removeDummy(dummy)
	api.pvpCourt(false)
	assert(ok, why)
	return tostring(#rows) .. " live raid assertions; " .. string.format("%.1fs", os.clock() - began)
end
return Test
