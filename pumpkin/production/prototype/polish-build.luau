-- Source edits: apply_patch. Binary backups/builds and evidence are generated outputs.
local fs,rb,luau,serde = require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local Vector2=rb.Vector2
local main = "slice-v2/prototype/guardian-greybox.rbxl"
local backup = "slice-v2/prototype/guardian-greybox.pre-polish2.rbxl"
if require("@lune/process").args[1] == "backup" then
	assert(not fs.isFile(backup),"pre-polish already exists; preserve it")
	local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes)
	assert(fs.readFile(backup)==bytes);print("PASS byte-verified pre-polish backup");return
end
assert(fs.isFile(backup),"backup required before Rojo")
local old=rb.deserializePlace(fs.readFile(backup))
local place=rb.deserializePlace(fs.readFile(backup))
local built=rb.deserializePlace(fs.readFile("prototype/polish-rojo.rbxl"))
local paths={
	{"ReplicatedStorage","MeadowV4","Polish"},{"ReplicatedStorage","MeadowV4","Builder"},
	{"ReplicatedStorage","LightingPresets"},{"ServerScriptService","LightingPresets"},
	{"ServerScriptService","KitPlan"},
	{"StarterPlayer","StarterPlayerScripts","HomeArt"},
	{"StarterPlayer","StarterPlayerScripts","MeadowKeeper"},
	{"ReplicatedStorage","GreyboxConfig"},{"ReplicatedStorage","MeadowV4","Gameplay"},
}
local function at(root,path,n)
	for i=1,n or #path do root=assert(root:FindFirstChild(path[i]),path[i]) end
	return root
end
local allowed={}
for _,path in paths do
	local parent=at(place,path,#path-1);local existing=parent:FindFirstChild(path[#path])
	if existing then existing:Destroy() end
	at(built,path):Clone().Parent=parent;allowed[table.concat(path,".")]=true
end
assert(rb.serializeModel({old.Workspace})==rb.serializeModel({place.Workspace}),"serialized world changed")
local preserved,compiled=0,0
for _,node in place:GetDescendants() do if node:IsA("LuaSourceContainer") then
	for level=0,2 do luau.compile(node.Source,{optimizationLevel=level}) end;compiled+=1
	if not allowed[node:GetFullName()] then
		assert(at(old,string.split(node:GetFullName(),".")).Source==node.Source,"unrelated source changed: "..node:GetFullName())
		preserved+=1
	end
end end
local env={Color3=rb.Color3,Instance=rb.Instance}
luau.load(place.ReplicatedStorage.LightingPresets.Source,{environment=env})().apply(place.Lighting,"GardenWarm")
local bytes=rb.serializePlace(place);rb.deserializePlace(bytes)
-- Rebuild actual production geometry from both artifacts, not a redesigned scene.
local manifests={}
for _,pair in {{"before",old},{"after",place}} do
	local tag,root=pair[1],pair[2];local cache={}
	local function load(node)
		if cache[node] then return cache[node] end
		local e={script=node,require=load,Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,
			game={GetService=function(_,name) if name=="RunService" then return {} end;assert(name=="HttpService");return {JSONDecode=function(_,s) return serde.decode("json",s) end} end}}
		cache[node]=luau.load(node.Source,{environment=e})();return cache[node]
	end
	local rs=root.ReplicatedStorage
	local model=load(rs.MeadowV4.Builder).build(root.Workspace,rb.Vector3.zero)
	for _,p in model:GetChildren() do
		if p:GetAttribute("MeadowV4Category")=="keeper" or p.Name=="GoldenAcorn" or p.Name=="AcornCap" or p.Name=="AcornStem" then p:Destroy() end
	end
local objective=rb.Instance.new("Part");objective.CFrame=rb.CFrame.new(0,49.4,-96);objective.CanCollide=false
	load(rs.MeadowV4.Gameplay).decorate(objective)
	objective.Parent=model
	if true then -- Both polish2 artifacts already use the approved 1.8x acorn.
		objective:Destroy()
		local blocks=load(rs.NativeBlocks)
		for _,section in load(rs.HomeArtGeometry).Acorn do
			for _,b in blocks.bounds(section) do
				local p=rb.Instance.new("Part");p.Name="HeroAcorn_"..section.name
				p.Size=b.size*1.8;p.CFrame=rb.CFrame.new(rb.Vector3.new(0,47.9,-96)+b.center*1.8)
				p.Color=rb.Color3.fromRGB(unpack(section.color));p.CanCollide=false;p.Parent=model
			end
		end
	end
	-- The real articulated native-block Keeper, idle pose at camp, same scale.
	local blocks=load(rs.NativeBlocks);local sk=load(rs.MeadowKeeper.Skeleton)
	local pose=load(rs.MeadowKeeper.Animator).sample("idle",0)
	local camp=load(rs.MeadowV4.Gameplay).Camp
	local world=load(rs.MeadowKeeper.Kinematics).world(pose,rb.CFrame.new(camp.x,camp.y,-camp.z))
	for _,section in load(rs.MeadowKeeper.Geometry) do
		for _,b in blocks.bounds(section) do
			local p=rb.Instance.new("Part");p.Name="Keeper_"..section.name;p.Size=b.size
			p.CFrame=world[section.rig_part]*rb.CFrame.new(b.center-rb.Vector3.new(unpack(sk.pivots[section.rig_part])))
			p.Color=rb.Color3.fromRGB(unpack(section.color));p.CanCollide=false;p.Parent=model
		end
	end
	local parts={}
	for _,p in model:GetDescendants() do if p:IsA("BasePart") then
		local cf={p.CFrame:GetComponents()};local rotation={};for i=4,12 do table.insert(rotation,cf[i]) end
		table.insert(parts,{name=p.Name,position={cf[1],cf[2],cf[3]},rotation=rotation,size={p.Size.X,p.Size.Y,p.Size.Z},
			color={p.Color.R*255,p.Color.G*255,p.Color.B*255},material=p.Material.Name,shape=p:IsA("Part") and p.Shape.Name or "Wedge",
			transparency=p.Transparency,collidable=p.CanCollide,query=p.CanQuery,touch=p.CanTouch,lane=p:GetAttribute("WalkableLaneFloor"),laneId=p:GetAttribute("LaneId"),
			role=p:GetAttribute("SurfaceRole"),tags=p:GetTags()})
	end end
	manifests[tag]=parts
	-- Retain the original matched BEFORE column and camera framing.
	if tag=="after" then
		fs.writeFile("prototype/studio-pass-1/polish-after.json",serde.encode("json",{parts=parts,routes={},native_proxy=true},false))
		local config=luau.load(rs.GreyboxConfig.Source,{environment={workspace={GetAttribute=function() return true end}}})()
		assert(config.GuardianGuardOffset.x==camp.x and config.GuardianGuardOffset.z==camp.z,"guard anchor drift")
		assert(config.Nest.x==0 and config.Nest.z==96,"steal target moved")
		assert((rb.Vector3.new(camp.x,camp.y+5.5,-camp.z)-rb.Vector3.new(0,51,-96)).Magnitude<config.GuardianDetectRange,"guard cannot detect nest approach")
		assert(place.ServerScriptService.Greybox.Source:find('q.MaxActivationDistance, q.RequiresLineOfSight = 9, false',1,true),"steal prompt range changed")
		local acornRadius,keeperRadius=0,0
		local blocks=load(rs.NativeBlocks)
		for _,section in load(rs.HomeArtGeometry).Acorn do for _,b in blocks.bounds(section) do
			acornRadius=math.max(acornRadius,Vector2.new(b.center.X,b.center.Z).Magnitude*1.8+Vector2.new(b.size.X,b.size.Z).Magnitude*0.9)
		end end
		local animator=load(rs.MeadowKeeper.Animator)
		for _,clip in {"idle","patrol"} do for frame=0,120 do
			local posed=load(rs.MeadowKeeper.Kinematics).world(animator.sample(clip,animator.Clips[clip].duration*frame/120),rb.CFrame.identity)
			for _,section in load(rs.MeadowKeeper.Geometry) do for _,b in blocks.bounds(section) do
				local cf=posed[section.rig_part]*rb.CFrame.new(b.center-rb.Vector3.new(unpack(sk.pivots[section.rig_part])))
				for _,x in {-0.5,0.5} do for _,y in {-0.5,0.5} do for _,z in {-0.5,0.5} do
					local v=cf*rb.Vector3.new(b.size.X*x,b.size.Y*y,b.size.Z*z)
					keeperRadius=math.max(keeperRadius,Vector2.new(v.X,v.Z).Magnitude)
				end end end
			end end
		end end
		local gap=Vector2.new(camp.x,camp.z-96).Magnitude-acornRadius-keeperRadius-config.GuardianGuardArrival
		assert(gap>=3,"idle/patrol conservative clearance <3: "..gap)
		-- A 4x4 guard footprint plus arrival tolerance must remain on summit floor.
		local floorFound=false
		for _,p in parts do if p.collidable and math.abs(p.position[2]+p.size[2]/2-48)<0.1 then
			if math.abs(camp.x-p.position[1])+5<=p.size[1]/2 and math.abs(-camp.z-p.position[3])+5<=p.size[3]/2 then floorFound=true end
		end end
		assert(floorFound,"guard anchor/arrival footprint lacks summit floor")
		fs.writeFile("prototype/studio-pass-1/POLISH2-CLEARANCE.json",serde.encode("json",{status="PASS",minimum_conservative_gap=gap,acorn_radius=acornRadius,keeper_radius=keeperRadius,arrival_allowance=config.GuardianGuardArrival,pose_samples=242,all_yaws=true,anchor_floor=true,steal_target_unchanged=true},true))
		print("PASS idle/patrol all-yaw conservative gap",gap)
	end
end
local function physics(parts)
	local out={}
	for _,p in parts do if p.collidable or p.lane then
		local q=table.clone(p);q.color=nil;q.material=nil;table.insert(out,serde.encode("json",q))
	end end
	table.sort(out);return table.concat(out,"\n")
end
assert(physics(manifests.before)==physics(manifests.after),"runtime geometry/floor/tag contract changed")
fs.writeFile(main,bytes)
local cleared=0
for i,p in manifests.after do if p.transparency==1 and manifests.before[i] and manifests.before[i].transparency~=1 then cleared+=1 end end
fs.writeFile("prototype/studio-pass-1/POLISH-OFFLINE.json",serde.encode("json",{
	status="PASS",compiled_O0_O1_O2=compiled,unrelated_sources_preserved=preserved,physics_floor_tags_equal=true,
	workspace_byte_equal=true,small_scenery_hidden=cleared,StudioPassAll="NOT RUN after polish",
	legacy_offline_check="PASS check.luau; mocked physics/navigation, not Studio",
	keeper_clearance="PASS existing sampled held/flight clearance; scale unchanged; articulated glove overbounds are diagnostic only",
	render_limits="Native-block geometry proxy; imported kits2 meshes, Roblox post effects, particles and Highlight require Studio.",
},true))
print("PASS polish: compiled",compiled,"unrelated sources preserved",preserved,"physics/floor/tag parity; hidden scenery",cleared)
