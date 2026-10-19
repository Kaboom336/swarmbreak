local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local player=Players.LocalPlayer
local shared=RS:WaitForChild("TreasureBase")
local C=require(shared:WaitForChild("Config"))
for _,name in {"Action","State","Toast","Pop"} do shared:WaitForChild(name) end
local gui=Instance.new("ScreenGui"); gui.Name="TreasureHUD"; gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local function label(name,text,pos,size)
	local t=Instance.new("TextLabel"); t.Name=name; t.Text=text
	t.Position=pos; t.Size=size; t.BackgroundTransparency=1
	t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.TextColor3=Color3.new(1,1,1)
	t.TextStrokeTransparency=0; t.Parent=gui; return t
end
local function button(name,pos,callback)
	local b=Instance.new("TextButton"); b.Name=name; b.Text=name
	b.Position=pos; b.Size=UDim2.fromScale(0.1,0.065); b.TextScaled=true
	b.Font=Enum.Font.GothamBold; b.BackgroundColor3=Color3.fromRGB(55,135,140)
	b.TextColor3=Color3.new(1,1,1); b.Parent=gui; b.Activated:Connect(callback); return b
end
local cash=label("Cash","$600",UDim2.fromScale(0.35,0.005),UDim2.fromScale(0.3,0.05))
cash.TextColor3=Color3.fromRGB(58,255,33)
local banner=label("Goal","Buy a treasure!",UDim2.fromScale(0.25,0.07),UDim2.fromScale(0.5,0.05))
local run=label("Carry","RUN!!",UDim2.fromScale(0.39,0.14),UDim2.fromScale(0.22,0.06)); run.Visible=false
local offline=label("Offline","",UDim2.fromScale(0.01,0.94),UDim2.fromScale(0.4,0.03))
local clock=label("Clock","Legendary in 5:00",UDim2.fromScale(0.7,0.94),UDim2.fromScale(0.29,0.035))
local notice=label("Toast","",UDim2.fromScale(0.2,0.86),UDim2.fromScale(0.6,0.045))
local revision=0
local function toast(text)
	revision+=1; local own=revision; notice.Text=text
	task.delay(3,function() if revision==own then notice.Text="" end end)
end
button("Shop",UDim2.fromScale(0.01,0.38),function() toast("Shop placeholder / no purchases in this greybox") end)
local panel=Instance.new("Frame"); panel.Name="IndexPanel"; panel.Position=UDim2.fromScale(0.28,0.2)
panel.Size=UDim2.fromScale(0.44,0.6); panel.BackgroundColor3=Color3.fromRGB(45,50,60); panel.Visible=false; panel.Parent=gui
local scroll=Instance.new("ScrollingFrame"); scroll.Size=UDim2.fromScale(1,0.9); scroll.Position=UDim2.fromScale(0,0.1)
scroll.CanvasSize=UDim2.fromOffset(0,25*36); scroll.ScrollBarThickness=8; scroll.BackgroundTransparency=1; scroll.Parent=panel
local rows={}
for id=1,#C.Earners do
	local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,-12,0,34); t.Position=UDim2.fromOffset(0,(id-1)*36)
	t.Text="???"; t.TextSize=20; t.BackgroundTransparency=1; t.TextColor3=Color3.new(1,1,1); t.Parent=scroll; rows[id]=t
end
local close=Instance.new("TextButton"); close.Size=UDim2.fromScale(0.13,0.1); close.Position=UDim2.fromScale(0.87,0)
close.Text="X"; close.TextScaled=true; close.BackgroundColor3=Color3.fromRGB(210,40,40); close.Parent=panel
close.Activated:Connect(function() panel.Visible=false end)
button("Index",UDim2.fromScale(0.01,0.46),function() panel.Visible=not panel.Visible end)
local drop=button("Drop",UDim2.fromScale(0.45,0.79),function() shared.Action:FireServer("Drop") end)
drop.BackgroundColor3=Color3.fromRGB(210,40,40); drop.Visible=false
local arrow=Instance.new("BillboardGui"); arrow.Name="GoalArrow"; arrow.Size=UDim2.fromOffset(80,75)
arrow.StudsOffset=Vector3.new(0,7,0); arrow.AlwaysOnTop=false; arrow.MaxDistance=45; arrow.Parent=gui
local glyph=Instance.new("TextLabel"); glyph.Size=UDim2.fromScale(1,1); glyph.BackgroundTransparency=1
glyph.Text="▼"; glyph.TextScaled=true; glyph.TextColor3=Color3.fromRGB(240,50,50); glyph.Parent=arrow
local last
local function updatePrompts()
	local world=workspace:FindFirstChild("TreasureBase")
	if not world or not last or not world:FindFirstChild("Plots") or not world:FindFirstChild("Earners") then return end
	local protected={}
	for _,plot in world.Plots:GetChildren() do
		protected[plot:GetAttribute("OwnerId") or 0]=not plot:GetAttribute("PvPEnabled")
		plot.Lock.LockPrompt.Enabled=last.pvp and plot:GetAttribute("OwnerId")==player.UserId and last.lock=="Ready"
	end
	for _,part in world.Earners:GetChildren() do
		local owner=part:GetAttribute("OwnerId") or 0
		part.StealPrompt.Enabled=last.pvp and part:GetAttribute("State")=="Placed"
			and owner~=player.UserId and not protected[owner]
	end
end
shared.State.OnClientEvent:Connect(function(s)
	last=s; cash.Text=string.format("$%.1f  |  $%.1f/s",s.cash,s.rate)
	banner.Text=({"Buy a treasure!","Collect your cash!","Unlock a pedestal!","Buy more treasures!"})[s.stage]
	run.Visible=s.carrying; drop.Visible=s.carrying; arrow.Adornee=s.target
	if s.carrying then banner.Text="Carry it home!" end
	offline.Text=string.format("Offline: $%.0f / 1h cap",s.offlineRate)
	for id,t in rows do
		local d=C.Earners[id]; local found=s.discovered[tostring(id)]
		t.Text=found and (d.name.." / "..C.Rarities[d.rarity].name) or "???"
		local color=C.Rarities[d.rarity].color
		t.TextColor3=found and Color3.fromRGB(color[1],color[2],color[3]) or Color3.fromRGB(150,150,150)
	end
	updatePrompts()
end)
shared.Toast.OnClientEvent:Connect(toast)
shared.Pop.OnClientEvent:Connect(function(pos,amount)
	local anchor=Instance.new("Part"); anchor.Anchored=true; anchor.CanCollide=false; anchor.CanTouch=false
	anchor.Transparency=1; anchor.Position=pos; anchor.Size=Vector3.new(0.1,0.1,0.1); anchor.Parent=workspace
	local g=Instance.new("BillboardGui"); g.Size=UDim2.fromOffset(60,20); g.AlwaysOnTop=false; g.MaxDistance=30; g.Parent=anchor
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1
	t.Text=string.format("+$%.1f",amount); t.TextScaled=true; t.TextColor3=Color3.fromRGB(58,255,33)
	t.TextStrokeTransparency=0; t.Parent=g
	Tween:Create(anchor,TweenInfo.new(0.9),{Position=pos+Vector3.new(0,4,0)}):Play()
	Tween:Create(t,TweenInfo.new(0.9),{TextTransparency=1,TextStrokeTransparency=1}):Play()
	task.delay(1,function() anchor:Destroy() end)
end)
shared:GetAttributeChangedSignal("LegendaryIn"):Connect(function()
	local seconds=shared:GetAttribute("LegendaryIn") or 300
	clock.Text=string.format("Legendary in %d:%02d",math.floor(seconds/60),seconds%60)
	clock.TextColor3=seconds<=10 and Color3.fromRGB(255,60,60) or Color3.new(1,1,1)
end)
shared.Action:FireServer("Ready")
