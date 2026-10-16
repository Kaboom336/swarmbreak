local fs,rb,luau,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local V,C=rb.Vector3,rb.CFrame
local function build(path)
	local place=rb.deserializePlace(fs.readFile(path));local cache={}
	local function load(node)
		if cache[node] then return cache[node] end
		cache[node]=luau.load(node.Source,{environment={script=node,require=load,
			Vector3=V,Vector2=rb.Vector2,CFrame=C,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,
			game={GetService=function(_,s) return s=="HttpService" and {JSONDecode=function(_,str) return serde.decode("json",str) end} or {} end}}})()
		return cache[node]
	end
	local model=load(place.ReplicatedStorage.MeadowV4.Builder).build(place.Workspace,V.zero)
	local signature,cues={},0
	for _,p in model:GetDescendants() do if p:IsA("BasePart") then
		if p:GetAttribute("OutsmartCue") then
			cues+=1;assert(not p.CanCollide and not p.CanTouch and not p.CanQuery,"cue blocks route")
			assert(not p:GetAttribute("WalkableLaneFloor"),"cue became a drop floor")
		end
		if p.CanCollide or p:GetAttribute("WalkableLaneFloor") then
			table.insert(signature,serde.encode("json",{p.Name,{p.CFrame:GetComponents()},{p.Size.X,p.Size.Y,p.Size.Z},p.CanCollide,p.CanQuery,p:GetAttribute("SurfaceRole"),p:GetAttribute("WalkableLaneFloor"),p:GetAttribute("LaneId"),p:GetTags()}))
		end
	end end
	table.sort(signature)
	return table.concat(signature,"\n"),cues,model
end
local before=build("slice-v2/prototype/guardian-greybox.pre-outsmart.rbxl")
local after,cues,model=build("slice-v2/prototype/guardian-greybox.rbxl")
assert(before==after,"rebuilt collisions/floors/lanes/tags changed")
assert(cues==9,"expected seven signs and two landing strips")
local cover
for _,p in model:GetDescendants() do if p:IsA("BasePart") and p.Name=="R5BoulderFoot" and (p.CFrame.Position-V.new(-73,4.305,113)).Magnitude<0.01 then cover=p end end
assert(cover and cover.CanCollide and cover.Size.X>=8,"existing broad corner retained")
print("PASS rebuilt physical geometry/floor/lane/tag parity; nine neutral cues; existing broad cover retained")
-- Mocked Blockcast results exercise the actual authoritative dash branch.
-- This proves policy, not Roblox collision accuracy (live OutsmartTest does that).
local wall={Instance=cover,Position=V.new(-73,4,109),Normal=-V.zAxis}
cover:SetAttribute("SurfaceRole","Cover")
local hit=wall
local Kit=luau.load(fs.readFile("slice-v2/prototype/KeeperAttacks.luau"),{environment={
	Instance=rb.Instance,Vector3=V,CFrame=C,Color3=rb.Color3,Enum=rb.Enum,
	workspace={Blockcast=function() return hit end}}})()
local a={guardian=rb.Instance.new("Part"),model=rb.Instance.new("Model"),warning={},throws=0}
a.guardian.Size=V.new(4,11,4)
local starEvents=0
local api={floor=function(_,p) return V.new(p.X,0,p.Z) end,safe=function() return false end,
	fx=function(_,name) if name=="WallStun" then starEvents+=1 end end}
local function dash(now)
	a.guardian.CFrame=C.lookAt(V.new(-73,5.5,88),V.new(-73,5.5,104))
	a.guardian.Position=V.new(-73,5.5,88)
	assert(Kit.begin(a,{},V.new(-73,3,104),now,"dash",api,{}))
	Kit.step(a,now+0.55,{},function() end,function() error("unexpected hit") end,api,{})
end
dash(10)
assert(starEvents==1 and math.abs(a.keeperStunUntil-12.10)<0.001,"first corner cap/stars")
local stun=a.keeperStunUntil
dash(30)
assert(starEvents==1 and a.keeperStunUntil==stun,"same corner refresh")
local carrier={};a.guardian.CFrame=C.new(-73,5.5,100);a.throws=1;a.kitCooldowns={}
a.guardian.Position=V.new(-73,5.5,100)
assert(Kit.choose(a,carrier,60,{},function() return {Position=V.new(-73,3,80)} end)=="fan","corner dash loop")
a.wallBaitCorner=nil;hit=nil
api.floor=function() return nil end
-- A no-floor stop must not add a stun (begin requires a legal target floor).
api.floor=function(_,p) return V.new(p.X,0,p.Z) end
a.guardian.CFrame=C.new(-73,5.5,88)
a.guardian.Position=V.new(-73,5.5,88)
assert(Kit.begin(a,{},V.new(-73,3,104),60,"dash",api,{}))
api.floor=function() return nil end
Kit.step(a,60.55,{},function() end,function() end,api,{})
assert(starEvents==1 and a.keeperStunUntil==stun and not a.attack,"edge granted wall stun")
api.floor=function(_,p) return V.new(p.X,0,p.Z) end
hit={Instance=cover,Position=wall.Position,Normal=V.yAxis};dash(80)
assert(starEvents==1 and a.keeperStunUntil==stun,"floor contact granted wall stun")
print("PASS production dash policy: capped stun/star event, same-corner refusal, non-dash recovery, edge/floor stops without stun")
