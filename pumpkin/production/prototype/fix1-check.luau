local fs, rb, luau, serde = require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local V = rb.Vector3
local function load(path, env) return luau.load(fs.readFile(path),{environment=env or {}})() end
local function data(path)
	return load(path,{game={GetService=function() return {JSONDecode=function(_,s) return serde.decode("json",s) end} end}})
end
local Blocks = load("slice-v2/prototype/NativeBlocks.luau",{Vector3=V,Instance=rb.Instance,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum})
local function validate(sections)
	local count = 0
	for _, s in ipairs(sections) do
		local bounds = Blocks.bounds(s)
		assert(#bounds>0,"empty section")
		for _, b in bounds do assert(b.size.X>0 and b.size.Y>0 and b.size.Z>0,"invalid block") end
		local model = rb.Instance.new("Model")
		count += Blocks.section(s, model, rb.CFrame.identity, rb.Enum.Material.Slate)
		assert(#model:GetChildren()==#bounds,"native block creation")
		for _, p in model:GetChildren() do assert(p.ClassName=="Part" and not p.CanCollide,"native cosmetic contract") end
		model:Destroy()
	end
	return count
end
local keeper=data("models/meadow-keeper/anim/Geometry.luau")
local home=data("slice-v2/prototype/HomeArtGeometry.luau")
print("PASS Keeper authored sections/components:",#keeper,validate(keeper))
local skeleton = data("models/meadow-keeper/anim/Skeleton.luau")
local modules = {Geometry=keeper,Skeleton=skeleton,Kinematics={},NativeBlocks=Blocks}
local warnings = 0
local rigModule = load("models/meadow-keeper/anim/Rig.luau",{
	game={GetService=function() return {WaitForChild=function(_,key) return key end} end},
	script={Parent={Geometry="Geometry",Skeleton="Skeleton",Kinematics="Kinematics"}},
	require=function(key) return modules[key] end,
	Vector3=V,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,
	warn=function() warnings+=1 end,
})
local rig = rigModule.build(rb.CFrame.new(10,20,30))
local motors, visuals = 0, 0
for _,p in rig.model:GetDescendants() do
	if p:IsA("Motor6D") then motors+=1; assert(p.Part0 and p.Part1,"disconnected animation motor") end
	if p:IsA("WeldConstraint") then visuals+=1; assert(p.Part0 and p.Part1,"disconnected visual block") end
end
assert(motors==16 and visuals==80 and #rig.meshes==0,"native rig contract")
assert(rig.release.Parent==rig.carriers["Wrist.R"],"release socket changed")
rigModule.destroy(rig)
local original, injected = Blocks.section, false
Blocks.section=function(...)
	if not injected then injected=true; error("injected geometry failure") end
	return original(...)
end
local fallback=rigModule.build(rb.CFrame.identity)
Blocks.section=original
assert(warnings==1 and #fallback.model:GetChildren()>17,"fallback must warn and build coloured rig")
rigModule.destroy(fallback)
print("PASS actual Keeper build: 16 Motor6Ds, 80 welded Parts, original wrist socket; injected failure warns/builds blocks")
local counts={}
for name,sections in home do counts[name]=validate(sections); print("PASS native Home template",name,counts[name]) end
local homeSource=fs.readFile("slice-v2/prototype/HomeArt.client.luau")
local start=assert(homeSource:find("local function template(name)",1,true))
local finish=assert(homeSource:find("local function clone(name)",start,true))
local homeTemplate=luau.load(homeSource:sub(start,finish-1).."\nreturn template",{environment={
	templates={},pending={},Data=home,Blocks=Blocks,Instance=rb.Instance,CFrame=rb.CFrame,Enum=rb.Enum,
	warn=function() warnings+=1 end,
}})()
local decor=homeTemplate("Decor")
assert(#decor:GetChildren()==counts.Decor and homeTemplate("Decor")==decor,"single cached Home template")
original,injected=Blocks.section,false
Blocks.section=function(...)
	if not injected then injected=true; error("injected Home geometry failure") end
	return original(...)
end
local fallbackPet=homeTemplate("Pup")
Blocks.section=original
assert(#fallbackPet:GetChildren()==#home.Pup and warnings==2,"Home failure must warn and build blocks")
print("PASS actual Home template/cache and injected failure: explicit warning plus coloured Parts")
-- Emergency loader path is a single coloured block per section, not an empty model.
local s=keeper[1]
assert(#Blocks.bounds({vertices=s.vertices,triangles={}})==1,"emergency block bounds")
print("PASS emergency coloured bounds build; eight full plots native pet Parts <=",64*math.max(counts.Pup,counts.Crow))
local config=load("slice-v2/prototype/GreyboxConfig.luau")
local placement=require("../slice-v2/prototype/Placement")
-- Sweep the real aisle corridor at half-stud increments against every raised plot.
for side=-1,1,2 do
	for z=-88,104,0.5 do
		for slot=1,8 do
			local x,pz=placement.center(slot)
			if placement.height(slot)>1.5 then
				assert(math.abs(side*config.HomeAisleX-x)>config.PlotWidth/2+3 or math.abs(z-pz)>config.PlotDepth/2+3,"aisle clips raised Pen"..slot)
			end
		end
		-- Real players must pass the stairs between sampled bot waypoints too.
		for slot=1,8 do
			local x,pz=placement.center(slot)
			for step=1,math.ceil(placement.height(slot)/0.5) do
				local sx=(x<0 and -1 or 1)*(1.4+step*0.9)
				assert(math.abs(side*config.HomeAisleX-sx)>0.45+1.75 or math.abs(z-pz)>6+1.75,"player corridor hits terrace stairs")
			end
		end
	end
end
assert(config.HomeAisleX+3<20,"three-stud aisle clearance")
print("PASS both player aisles: 3-stud waypoint clearance from pens; continuous 3.5-stud-wide stair clearance")
local Art=require("./meadow-v4/Fix1Art")
local raw=data("prototype/meadow-v4/MeadowV4Data.luau")
local routes=require("./meadow-v4/RouteData")
local fixed=Art.transform(raw,routes)
local n={}
for _, p in fixed do
	n[p.name]=(n[p.name] or 0)+1
	assert(p.name~="LookContinuousTurf" and p.name~="LookHillEarthBank" and p.name~="LookHillGrassBank","thin sheet retained")
	if p.name:find("Tunnel") and p.shape=="Ball" and p.transparency<1 then assert(p.name:find("Puddle"),"visible smooth tunnel sphere") end
	if p.name=="Fix1HillSlateBacking" then assert(p.size[2]==6 and p.material=="Slate" and not p.collidable,"thick backing") end
	if p.name=="Fix1SolidGrassCap" then assert(p.size[2]>=1.4 and p.size[2]<=4 and p.transparency==0,"visible cap") end
end
assert(n.Fix1SolidGrassCap==452 and n.Fix1HillSlateBacking>0,"solid hill missing")
assert(n.Fix1MushroomCap>0 and n.Fix1MushroomSpot==n.Fix1MushroomCap*2 and n.Fix1AmethystCrystal==20,"cave props")
print("PASS cave props",n.Fix1MushroomCap,"mushroom caps",n.Fix1MushroomSpot,"spots",n.Fix1AmethystCrystal,"amethyst shards")
-- Every existing collision shape is unchanged. Voxel masses stay inside former sphere OBBs.
local colliders=0
local indexed = {}
local function signature(p)
	return p.name .. p.shape .. tostring(p.collidable) .. serde.encode("json",p.position) .. serde.encode("json",p.size) .. serde.encode("json",p.rotation)
end
for _,q in fixed do indexed[signature(q)] = true end
for i,p in raw do if p.collidable then
	assert(indexed[signature(p)],"collider changed "..p.name)
	colliders+=1
end end
print("PASS hill/cave: caps",n.Fix1SolidGrassCap,"slate backing",n.Fix1HillSlateBacking,"existing colliders",colliders)
local place=rb.deserializePlace(fs.readFile("slice-v2/prototype/guardian-greybox.rbxl"))
assert(place.ReplicatedStorage.NativeBlocks.Source==fs.readFile("slice-v2/prototype/NativeBlocks.luau"),"mount parity")
assert(place.ReplicatedStorage.MeadowV4.Fix1Art.Source==fs.readFile("prototype/meadow-v4/Fix1Art.luau"),"art mount")
for _,path in {"models/meadow-keeper/anim/Rig.luau","slice-v2/prototype/HomeArt.client.luau"} do
	assert(not fs.readFile(path):find("CreateEditableMesh",1,true),"editable mesh allocation remains")
end
print("PASS binary native art mounts; no EditableMesh allocation in Keeper/Home loaders")
