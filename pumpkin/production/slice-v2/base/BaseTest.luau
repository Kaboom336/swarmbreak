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
	local factory=require(shared.EarnerModel)(C,R)
	local expected
	for mutation=1,3 do
		local root=factory.create(world.Earners,"MutationCheck",1,mutation,Vector3.new(0,2,-8),"Carpet")
		check(root.Transparency==1 and root.Visual:IsA("Model"),"def 1 voxel hook")
		local n=1
		check(root.Anchored and not root.CanCollide,"authority root anchored/non-colliding")
		for _,part in root:GetDescendants() do
			if part:IsA("BasePart") then
				n+=1; check(part.Anchored and not part.CanCollide,"voxel anchored/non-colliding after serialization")
			end
		end
		check(n<250,"whole earner including both roots below 250")
		expected=expected or n; check(n==expected,"factory mutation count unchanged")
		root:Destroy()
	end
	local placeholder=factory.create(world.Earners,"PlaceholderCheck",2,1,Vector3.new(0,2,-8),"Carpet")
	check(placeholder.Transparency==0 and not placeholder:FindFirstChild("Visual"),"other defs keep placeholders")
	placeholder:Destroy()
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
