-- Identical greybox silhouette per rarity; swap this factory for real models later.
return function(C,R)
	local F={}
	function F.create(parent,uid,def,mutation,pos,state)
		local d=C.Earners[def]; local rarity=C.Rarities[d.rarity]
		local p=Instance.new("Part"); p.Name=uid; p.Size=Vector3.new(3,3,3)
		p.Anchored=true; p.CanCollide=false; p.CFrame=CFrame.new(pos)
		local color=C.Mutations[mutation].color or {170,170,170}
		p.Color=Color3.fromRGB(color[1],color[2],color[3])
		p:SetAttribute("Def",def); p:SetAttribute("Mutation",mutation); p:SetAttribute("State",state)
		p:SetAttribute("ServerOwned",true)
		local g=Instance.new("BillboardGui"); g.Name="Label"; g.Size=UDim2.fromOffset(220,110)
		g.StudsOffset=Vector3.new(0,4,0); g.AlwaysOnTop=true; g.MaxDistance=110; g.Parent=p
		for i,text in {d.name,rarity.name.." / "..C.Mutations[mutation].name,"$"..R.price(def,mutation).." / $"..R.income(def,mutation).."/s"} do
			local t=Instance.new("TextLabel"); t.Name="Line"..i
			t.Size=UDim2.fromScale(1,1/3); t.Position=UDim2.fromScale(0,(i-1)/3)
			t.BackgroundTransparency=1; t.Text=text; t.TextScaled=true; t.TextStrokeTransparency=0
			t.TextColor3=i==2 and Color3.fromRGB(rarity.color[1],rarity.color[2],rarity.color[3]) or Color3.new(1,1,1)
			t.Parent=g
		end
		for _,spec in {{"Buy",0},{"Steal",C.StealHold}} do
			local q=Instance.new("ProximityPrompt"); q.Name=spec[1].."Prompt"
			q.ActionText=spec[1]; q.ObjectText=d.name; q.KeyboardKeyCode=Enum.KeyCode.E
			q.HoldDuration=spec[2]; q.MaxActivationDistance=C.InteractionDistance; q.RequiresLineOfSight=false
			q.Enabled=(state=="Carpet" and spec[1]=="Buy") or (state=="Placed" and spec[1]=="Steal")
			q:SetAttribute("ServerOwned",true); q.Parent=p
		end
		p.Parent=parent
		return p
	end
	return F
end
