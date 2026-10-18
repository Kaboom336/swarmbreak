-- Fresh greybox. Build-time/runtime compatible, like the local heists Scene pattern.
return function(parent,C)
	local function node(class,name,under)
		local p=Instance.new(class); p.Name=name; p.Parent=under; return p
	end
	local world=node("Folder","TreasureBase",parent)
	local function part(name,size,pos,color,under)
		local p=node("Part",name,under or world)
		p.Size,p.CFrame,p.Color=size,CFrame.new(pos),color
		p.Anchored=true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
		return p
	end
	local grey=Color3.fromRGB(150,150,150)
	local function sign(p,text)
		local g=node("BillboardGui","Sign",p)
		g.Size=UDim2.fromOffset(230,65); g.StudsOffset=Vector3.new(0,3,0)
		g.AlwaysOnTop=true; g.MaxDistance=110
		local t=node("TextLabel","Text",g); t.Size=UDim2.fromScale(1,1)
		t.BackgroundTransparency=1; t.Text=text; t.TextScaled=true
		t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=0
		return t
	end
	local function prompt(p,name,action,hold)
		local q=node("ProximityPrompt",name,p)
		q.ActionText=action; q.ObjectText=p.Name; q.HoldDuration=hold or 0
		q.KeyboardKeyCode=Enum.KeyCode.E; q.MaxActivationDistance=C.InteractionDistance
		q.RequiresLineOfSight=false; q:SetAttribute("ServerOwned",true)
		return q
	end
	part("Ground",Vector3.new(220,2,280),Vector3.new(0,-1,0),Color3.fromRGB(100,135,90))
	part("Carpet",Vector3.new(18,0.2,244),Vector3.new(0,0.1,0),Color3.fromRGB(165,65,65))
	local start=part("LaneStart",Vector3.new(2,0.2,2),Vector3.new(0,0.2,C.LaneStart),grey)
	sign(start,"TREASURES / 3s\nLegendary every 5 minutes")
	part("LaneEnd",Vector3.new(2,0.2,2),Vector3.new(0,0.2,C.LaneEnd),grey)
	local spawn=node("SpawnLocation","CentreSpawn",world)
	spawn.Size=Vector3.new(6,0.3,6); spawn.CFrame=CFrame.new(0,0.3,0)
	spawn.Anchored=true; spawn.Neutral=true; spawn.Duration=0
	local plots=node("Folder","Plots",world)
	for i=1,C.PlotCount do
		local side=i<=4 and -1 or 1
		local z=((i-1)%4)*60-90
		local x=side*48
		local plot=node("Folder","Plot"..i,plots); plot:SetAttribute("OwnerId",0)
		local floor=part("Floor",Vector3.new(56,0.3,48),Vector3.new(x,0.15,z),grey,plot)
		sign(floor,"Unclaimed base")
		local entry=part("Entry",Vector3.new(2,0.3,40),Vector3.new(side*20,0.3,z),grey,plot)
		entry.CanCollide=false
		local barrier=part("Barrier",Vector3.new(2,16,48),Vector3.new(side*20,8,z),Color3.fromRGB(210,65,65),plot)
		barrier.CanCollide=false; barrier.Transparency=1
		local home=part("Home",Vector3.new(3,0.2,3),Vector3.new(side*29,0.3,z),grey,plot)
		home.CanCollide=false
		for _,wall in {{"Back",Vector3.new(2,16,50),Vector3.new(side*77,8,z)},
			{"North",Vector3.new(58,16,2),Vector3.new(x,8,z-25)},
			{"South",Vector3.new(58,16,2),Vector3.new(x,8,z+25)}} do
			part(wall[1],wall[2],wall[3],grey,plot)
		end
		local pedestals=node("Folder","Pedestals",plot)
		for n=1,C.PedestalCount do
			local ped=part("Pedestal"..n,Vector3.new(5,1,5),Vector3.new(side*(39+((n-1)%5)*7),0.7,z+(n<=5 and -12 or 12)),grey,pedestals)
			ped:SetAttribute("Slot",n); ped:SetAttribute("Unlocked",n<=C.StartUnlocked)
			if n>C.StartUnlocked then
				local cost=C.UnlockCosts[n-C.StartUnlocked]
				sign(ped,"Locked pedestal\n$"..cost)
			end
		end
		local collect=part("Collect",Vector3.new(6,0.3,7),Vector3.new(side*30,0.4,z-8),Color3.fromRGB(75,170,80),plot)
		sign(collect,"Collect $0")
		local unlock=part("Unlock",Vector3.new(6,0.3,7),Vector3.new(side*30,0.4,z+8),Color3.fromRGB(180,170,70),plot)
		sign(unlock,"Unlock pedestal\n$100")
		local upgrade=part("Upgrade",Vector3.new(6,0.3,7),Vector3.new(side*68,0.4,z),Color3.fromRGB(75,145,175),plot)
		sign(upgrade,"Speed +2\n$100")
		local lock=part("Lock",Vector3.new(5,1,5),Vector3.new(side*57,0.7,z),grey,plot)
		sign(lock,"Lock / steal after 3 buys"); prompt(lock,"LockPrompt","Lock").Enabled=false
	end
	node("Folder","Earners",world)
	return world
end
