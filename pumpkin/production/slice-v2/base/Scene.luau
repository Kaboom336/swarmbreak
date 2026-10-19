-- Fresh greybox. Build-time/runtime compatible, like the local heists Scene pattern.
return function(parent,C)
	local function node(class,name,under)
		local p=Instance.new(class); p.Name=name; p.Parent=under; return p
	end
	local world=node("Folder","TreasureBase",parent)
	local function part(name,size,pos,color,under)
		local p=node("Part",name,under or world)
		p.Size,p.CFrame,p.Color=size,CFrame.new(pos),color
		p.Anchored=true; p.Material=Enum.Material.SmoothPlastic
		p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
		return p
	end
	local grey=Color3.fromRGB(60,65,75)
	local white=Color3.fromRGB(245,245,245)
	local green=Color3.fromRGB(75,200,60)
	local red=Color3.fromRGB(200,30,30)
	local function decor(name,size,pos,color,under)
		local p=part(name,size,pos,color,under)
		p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
		return p
	end
	local function sign(p,text)
		local g=node("BillboardGui","Sign",p)
		g.Size=UDim2.fromOffset(100,28); g.StudsOffset=Vector3.new(0,1.5,0)
		g.AlwaysOnTop=false; g.MaxDistance=30; g.LightInfluence=0
		local t=node("TextLabel","Text",g); t.Size=UDim2.fromScale(1,1)
		t.BackgroundTransparency=1; t.Text=text; t.TextScaled=true
		t.FontFace=Font.fromEnum(Enum.Font.GothamBlack)
		t.TextColor3=white; t.TextStrokeTransparency=0
		return t
	end
	local function prompt(p,name,action,hold)
		local q=node("ProximityPrompt",name,p)
		q.ActionText=action; q.ObjectText=p.Name; q.HoldDuration=hold or 0
		q.KeyboardKeyCode=Enum.KeyCode.E; q.MaxActivationDistance=C.InteractionDistance
		q.RequiresLineOfSight=false; q:SetAttribute("ServerOwned",true)
		return q
	end
	local ground=part("Ground",Vector3.new(220,2,280),Vector3.new(0,-1,0),green)
	ground.Material=Enum.Material.Plastic; ground.TopSurface=Enum.SurfaceType.Studs
	part("Carpet",Vector3.new(15,0.2,244),Vector3.new(0,0.1,0),red)
	for _,side in {-1,1} do
		decor("CarpetEdge",Vector3.new(0.3,0.22,244),Vector3.new(side*7.65,0.11,0),white)
		part("BorderSide",Vector3.new(2,12,280),Vector3.new(side*109,6,0),grey)
		part("BorderEnd",Vector3.new(216,12,2),Vector3.new(0,6,side*139),grey)
	end
	local start=part("LaneStart",Vector3.new(2,0.2,2),Vector3.new(0,0.2,C.LaneStart),grey)
	sign(start,"TREASURES / 3s\nLegendary every 5 minutes")
	part("LaneEnd",Vector3.new(2,0.2,2),Vector3.new(0,0.2,C.LaneEnd),grey)
	local spawn=node("SpawnLocation","CentreSpawn",world)
	spawn.Size=Vector3.new(6,0.3,6); spawn.CFrame=CFrame.new(0,0.3,0)
	spawn.Anchored=true; spawn.Neutral=true; spawn.Duration=0
	spawn.Transparency=1
	local plots=node("Folder","Plots",world)
	for i=1,C.PlotCount do
		local side=i<=4 and -1 or 1
		local z=((i-1)%4)*60-90
		local x=side*48
		local plot=node("Folder","Plot"..i,plots); plot:SetAttribute("OwnerId",0)
		local floor=part("Floor",Vector3.new(56,0.3,48),Vector3.new(x,0.15,z),grey,plot)
		-- Keep Floor.Sign.Text for the existing ownership text hook; Adornee moves it to wood.
		local board=decor("NameBoard",Vector3.new(1,5,36),Vector3.new(side*20,19,z),Color3.fromRGB(130,85,45),plot)
		local boardGui=node("SurfaceGui","Sign",floor)
		boardGui.Adornee=board; boardGui.Face=side<0 and Enum.NormalId.Right or Enum.NormalId.Left
		boardGui.CanvasSize=Vector2.new(1000,140); boardGui.LightInfluence=0
		boardGui.AlwaysOnTop=false; boardGui.MaxDistance=80
		local title=node("TextLabel","Text",boardGui); title.Size=UDim2.fromScale(1,1)
		title.BackgroundTransparency=1; title.Text="Unclaimed Base"; title.FontFace=Font.fromEnum(Enum.Font.GothamBlack)
		title.TextScaled=true; title.TextColor3=white
		for _,dz in {-18.4,18.4} do
			decor("SignFrame",Vector3.new(1.1,5.8,0.8),Vector3.new(side*20,19,z+dz),Color3.fromRGB(90,56,30),plot)
		end
		for _,dy in {-2.9,2.9} do
			decor("SignFrame",Vector3.new(1.1,0.8,37.6),Vector3.new(side*20,19+dy,z),Color3.fromRGB(90,56,30),plot)
		end
		decor("InteriorCarpet",Vector3.new(54,0.08,44),Vector3.new(x,0.34,z),red,plot)
		decor("EntryCarpet",Vector3.new(15,0.08,13),Vector3.new(side*13.5,0.24,z),red,plot)
		for _,dz in {-6.65,6.65} do
			decor("EntryEdge",Vector3.new(15,0.06,0.3),Vector3.new(side*13.5,0.29,z+dz),white,plot)
		end
		local entry=part("Entry",Vector3.new(2,0.3,40),Vector3.new(side*20,0.3,z),grey,plot)
		entry.CanCollide=false; entry.Transparency=1
		local barrier=part("Barrier",Vector3.new(2,16,48),Vector3.new(side*20,8,z),Color3.fromRGB(210,65,65),plot)
		barrier.CanCollide=false; barrier.Transparency=1
		for bar=0,23 do
			local laser=decor("Laser"..bar,Vector3.new(0.35,15.5,0.35),Vector3.new(side*20,8,z-23+bar*2),red,barrier)
			laser.Material=Enum.Material.Neon; laser.Transparency=1; laser.CastShadow=false
		end
		for _,dz in {-24,24} do
			part("EntrancePost",Vector3.new(2.4,17,2.4),Vector3.new(side*20,8.5,z+dz),grey,plot)
		end
		part("EntranceHeader",Vector3.new(2.4,1,50),Vector3.new(side*20,16.5,z),grey,plot)
		local home=part("Home",Vector3.new(3,0.2,3),Vector3.new(side*29,0.3,z),grey,plot)
		home.CanCollide=false; home.Transparency=1
		for _,wall in {{"Back",Vector3.new(2,16,50),Vector3.new(side*77,8,z)},
			{"North",Vector3.new(58,16,2),Vector3.new(x,8,z-25)},
			{"South",Vector3.new(58,16,2),Vector3.new(x,8,z+25)}} do
			local wallPart=part(wall[1],wall[2],wall[3],grey,plot)
			-- Preserve each wall's collision envelope; render a window band in that envelope.
			wallPart.Transparency=1
			local size,pos=wall[2],wall[3]
			for _,band in {{2,4,grey},{8,8,Color3.fromRGB(157,210,224)},{14,4,grey}} do
				local panel=decor(wall[1].."Band",Vector3.new(size.X,band[2],size.Z),Vector3.new(pos.X,band[1],pos.Z),band[3],wallPart)
				if band[1]==8 then panel.Transparency=0.65 end
			end
			for _,height in {4,12,15.8} do
				decor("WindowTrim",Vector3.new(size.X+0.1,0.35,size.Z+0.1),Vector3.new(pos.X,height,pos.Z),white,wallPart)
			end
			for _,offset in {-0.45,0,0.45} do
				local back=wall[1]=="Back"
				decor("WindowMullion",Vector3.new(back and 2.1 or 0.4,8,back and 0.4 or 2.1),
					Vector3.new(pos.X+(back and 0 or size.X*offset),8,pos.Z+(back and size.Z*offset or 0)),white,wallPart)
			end
		end
		part("Roof",Vector3.new(29,1,50),Vector3.new(side*62.5,16.5,z),grey,plot)
		decor("RoofTrim",Vector3.new(29.4,0.3,50.4),Vector3.new(side*62.5,17.05,z),white,plot)
		local pedestals=node("Folder","Pedestals",plot)
		for n=1,C.PedestalCount do
			local ped=part("Pedestal"..n,Vector3.new(5,1,5),Vector3.new(side*(39+((n-1)%5)*7),0.7,z+(n<=5 and -12 or 12)),grey,pedestals)
			ped:SetAttribute("Slot",n); ped:SetAttribute("Unlocked",n<=C.StartUnlocked)
			-- Invisible authority root retains its name, attributes, size and placement height.
			ped.Transparency=1
			local active=n<=C.StartUnlocked
			decor("Block",Vector3.new(5.04,1.04,5.04),ped.CFrame.Position,active and grey or Color3.fromRGB(100,100,100),ped)
			local pad=decor("CollectPad",Vector3.new(5.8,0.16,3),ped.CFrame.Position+Vector3.new(0,-0.25,n<=5 and 4.1 or -4.1),active and green or Color3.fromRGB(100,100,100),ped)
			local label=sign(pad,"Collect $0"); label.Parent.Name="PadLabel"
			label.Parent.Size=UDim2.fromOffset(80,28); label.Parent.StudsOffset=Vector3.new(0,1.3,0)
			label.TextScaled=false; label.TextSize=14; label.Parent.Enabled=false
			if n>C.StartUnlocked then
				local cost=C.UnlockCosts[n-C.StartUnlocked]
				local label=sign(ped,"Unlock $"..cost)
				label.Parent.Enabled=n==C.StartUnlocked+1
			end
		end
		local collect=part("Collect",Vector3.new(6,0.3,7),Vector3.new(side*30,0.4,z-8),green,plot)
		sign(collect,"Collect $0")
		local unlock=part("Unlock",Vector3.new(6,0.3,7),Vector3.new(side*30,0.4,z+8),Color3.fromRGB(255,210,35),plot)
		sign(unlock,"Unlock $100")
		local upgrade=part("Upgrade",Vector3.new(6,0.3,7),Vector3.new(side*68,0.4,z),Color3.fromRGB(35,175,255),plot)
		sign(upgrade,"Speed +2\n$100")
		local lock=part("Lock",Vector3.new(5,1,5),Vector3.new(side*57,0.7,z),red,plot)
		sign(lock,"Lock / steal after 3 buys"); prompt(lock,"LockPrompt","Lock").Enabled=false
	end
	-- This adapter only presents existing gameplay state; BaseServer owns all collision/money.
	local visuals=node("Script","LookVisuals",world)
	visuals.Source=[=[
local world=script.Parent
for _,plot in world.Plots:GetChildren() do
	local barrier=plot.Barrier
	local function lockVisuals()
		for _,laser in barrier:GetChildren() do
			if laser:IsA("BasePart") then laser.Transparency=barrier.CanCollide and 0 or 1 end
		end
		-- Hide the old solid sheet without changing BaseServer's collision state.
		if barrier.Transparency~=1 then barrier.Transparency=1 end
	end
	barrier:GetPropertyChangedSignal("CanCollide"):Connect(lockVisuals)
	barrier:GetPropertyChangedSignal("Transparency"):Connect(lockVisuals)
	lockVisuals()
	local title=plot.Floor.Sign.Text
	local function nameVisuals()
		local text=title.Text:gsub(" base$"," Base")
		if title.Text~=text then title.Text=text end
	end
	title:GetPropertyChangedSignal("Text"):Connect(nameVisuals); nameVisuals()
	for _,ped in plot.Pedestals:GetChildren() do
		local function pedestalVisuals()
			local unlocked=ped:GetAttribute("Unlocked")
			ped.Block.Color=unlocked and Color3.fromRGB(60,65,75) or Color3.fromRGB(100,100,100)
			ped.CollectPad.Color=unlocked and Color3.fromRGB(75,200,60) or Color3.fromRGB(100,100,100)
		end
		ped:GetAttributeChangedSignal("Unlocked"):Connect(pedestalVisuals); pedestalVisuals()
	end
	-- BaseServer presents each placed record's pile; collection remains pooled at plot.Collect.
end
]=]
	node("Folder","Earners",world)
	return world
end
