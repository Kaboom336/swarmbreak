-- EDIT mode only: require(game.ServerScriptService.BaseTest)()
-- No Play, no DataStore, no game scripts started by this module.
return function(place)
	place=place or game
	local count=0
	local function check(ok,why) assert(ok,why); count+=1 end
	local shared=place.ReplicatedStorage.TreasureBase
	local C=require(shared.Config); local R=require(shared.Rules)(C)
	local world=place.Workspace.TreasureBase
	check(#C.Earners==25,"earner definitions")
	check(R.price(1,1)==600,"starter price")
	check(#world.Plots:GetChildren()==8,"eight plots")
	check(world.CentreSpawn:IsA("SpawnLocation"),"spawn location")
	check(math.abs(world.CentreSpawn.CFrame.Position.X)<1 and math.abs(world.CentreSpawn.CFrame.Position.Z)<1,"central spawn")
	check(world.LaneStart.CFrame.Position.Z<world.LaneEnd.CFrame.Position.Z,"lane endpoints")
	check(world.Carpet.Anchored,"anchored carpet")
	for _,plot in world.Plots:GetChildren() do
		check(#plot.Pedestals:GetChildren()==10,"ten pedestals per plot")
		for _,ped in plot.Pedestals:GetChildren() do
			check(ped:IsA("Part") and ped.Anchored,"anchored pedestal")
			check(ped:GetAttribute("Unlocked")== (ped:GetAttribute("Slot")<=4),"four unlocked")
		end
		for _,name in {"Collect","Unlock","Upgrade","Lock","Entry","Home","Barrier"} do
			check(plot[name]:IsA("BasePart") and plot[name].Anchored,name.." exists and is anchored")
		end
		check(plot.Entry.CFrame.Position.X*plot.Floor.CFrame.Position.X>0,"entry correct side")
		check(plot.Lock.LockPrompt:GetAttribute("ServerOwned")==true,"lock server ownership contract")
		check(not plot.Lock.LockPrompt.Enabled,"lock initially gated")
	end
	check(#world.Earners:GetChildren()>=1,"initial carpet earner")
	for _,part in world.Earners:GetChildren() do
		check(part.Anchored and part:GetAttribute("ServerOwned")==true,"anchored earner: no client physics owner")
		check(part.BuyPrompt.ActionText=="Buy" and part.BuyPrompt.KeyboardKeyCode==Enum.KeyCode.E,"buy prompt")
		check(part.StealPrompt.HoldDuration==2,"two second steal prompt")
		check(part.BuyPrompt:GetAttribute("ServerOwned") and part.StealPrompt:GetAttribute("ServerOwned"),"prompt authority markers")
		check(part.Label.Line2.Text~="","rarity label")
	end
	for _,name in {"Action","State","Toast","Pop"} do check(shared[name]:IsA("RemoteEvent"),"remote "..name) end
	check(place.ServerScriptService.BaseServer:IsA("Script"),"server controller")
	print("PASS "..count.." BaseTest EDIT structure assertions (runtime NOT RUN)")
	return count
end
