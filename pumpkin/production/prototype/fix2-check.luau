-- Execute actual mounted map Builder; audit engine-independent resolve against its Parts.
local fs,rb,luau,serde,process=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde"),require("@lune/process")
local Ray=require("./meadow-v4/OfflineRay")
assert(require("./meadow-v4/clearance-fixtures"))
local V=rb.Vector3
local path=process.args[1] or "slice-v2/prototype/guardian-greybox.rbxl"
local place=rb.deserializePlace(fs.readFile(path))
local folder=place.ReplicatedStorage.MeadowV4
local cache={}
local function load(node)
	if cache[node] then return cache[node] end
	local env={script=node,require=load,Vector3=V,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance}
	cache[node]=luau.load(node.Source,{environment=env})()
	return cache[node]
end
local builder,routes,gameplay=load(folder.Builder),load(folder.RouteData),load(folder.Gameplay)
local clearance=if folder:FindFirstChild("Clearance") then load(folder.Clearance) else require("./meadow-v4/Clearance")
local config=luau.load(place.ReplicatedStorage.GreyboxConfig.Source,{environment={workspace=place.Workspace}})()
local model=builder.build(rb.Instance.new("Folder"),V.zero)
for _,p in model:GetChildren() do
	local cat=p:GetAttribute("MeadowV4Category")
	if cat=="keeper" or p.Name=="GoldenAcorn" or p.Name=="AcornCap" or p.Name=="AcornStem" then p:Destroy()
	elseif cat=="cover" or cat=="boulder" or cat=="tunnel_rock" or cat=="tunnel_roof" or cat=="tunnel_hill" then p:SetAttribute("SurfaceRole","Cover") end
end
local ray=Ray.new(model)
local columns,wedges,lanes=0,0,0
for _,p in model:GetChildren() do
	if p.Name=="SolidMountainStone" then columns+=1 end
	if p.Name:match("^Fix2") then
		lanes+=1
		assert(p.Size.X>=12 and p.Size.Y>=0.05 and p.Size.Z>=0.05,"native lane size "..p.Name.." "..tostring(p.Size))
		if p:IsA("WedgePart") then wedges+=1 end
	end
end
local rows,bad,total={},0,0
local function check(p,label,offset)
	local position=V.new(p.x+(offset or 0),p.y+3,-p.z)
	local ok,reason=pcall(clearance.resolve,position,false,3,ray,true,V)
	total+=1
	if not ok then
		bad+=1
		local sx,sz=tostring(reason):match("at ([%d%.%-]+),([%d%.%-]+)")
		local h=ray(V.new(tonumber(sx) or position.X,position.Y+9,tonumber(sz) or position.Z),V.new(0,-70,0))
		table.insert(rows,{name=label,point={p.x,p.y,p.z},runtime_root={position.X+config.MeadowX,position.Y+config.MeadowHeight,position.Z+config.MeadowZ},hit=if h then {name=h.Instance.Name,y=h.Position.Y,ny=h.Normal.Y} else nil,reason=tostring(reason),decision=if tostring(reason):find("authored Y",1,true) then "STALE_HEIGHT" else "MAP"})
	end
end
for i,p in gameplay.approach() do check(p,"approach "..i.." "..(p.name or p.kind)) end
for i,p in gameplay.carry() do check(p,"carry "..i.." "..(p.name or p.kind)) end
for i,p in gameplay.carry() do check(p,"empty expiry exit "..i) end
local layout={}
gameplay.install(layout)
for i,p in layout.dodgePoints() do check(p,"disc dodge option "..i) end
for i,p in layout.referencePoints() do check(p,"loop raised reference "..i) end
local loopBad=bad
for i,p in layout.referencePoints() do check(p,"pvp raised reference "..i) end
for name,route in gameplay.pvpRoutes() do for i,p in route do check(p,"pvp "..name.." "..i) end end
local preflightBad=bad
if process.args[2]=="baseline" then
	assert(loopBad==75 and preflightBad-loopBad==18,"Studio pass 2 baseline reproduction drift")
	for _,row in rows do assert(row.decision=="MAP","baseline stale waypoint classification") end
end
print(string.format("Preflight loop=%d PvP=%d checks=%d",loopBad,preflightBad-loopBad,total))
-- Half-stud station spacing catches gaps between authored vertices. Three-stud
-- disc at +/-3 normal offset covers a full twelve-stud corridor, with the
-- runner's exact slope/body rules. No radius/tolerance weakening.
if not process.args[2] then
	for name,route in routes do
		if name:match("^tunnel") or name:match("^ravine") or name:match("^jump") then continue end
		for i=2,#route do
			local a,b=route[i-1],route[i]
			local dx,dz=b.x-a.x,b.z-a.z
			local run=math.sqrt(dx*dx+dz*dz)
			if run<0.001 then continue end
			local steps=math.max(1,math.ceil(run/0.5))
			for j=0,steps do
				local t=j/steps
				for _,side in {-3,0,3} do
					check({x=a.x+dx*t+dz/run*side,y=a.y+(b.y-a.y)*t,z=a.z+dz*t-dx/run*side},name.." segment "..i.." t "..t.." side "..side)
				end
			end
		end
	end
end
local report={state=if bad==0 then "PASS" else "FAIL",artifact=path,checks=total,columns=columns,ramp_wedges=wedges,lane_parts=lanes,loop_bad=loopBad,pvp_bad=preflightBad-loopBad,preflight_bad=preflightBad,bad=bad,failures=rows,Studio="UNKNOWN"}
fs.writeFile(if process.args[2]=="baseline" then "prototype/FIX2-BASELINE.json" elseif process.args[2] then "prototype/FIX2-PREFLIGHT.json" else "prototype/FIX2-CLEARANCE.json",serde.encode("json",report,true))
for i=1,math.min(12,#rows) do print(serde.encode("json",rows[i])) end
print(string.format("%s %d resolve checks; preflight bad=%d; total bad=%d",report.state,total,preflightBad,bad))
assert(bad==0 or process.args[2]=="baseline","clearance regression")
