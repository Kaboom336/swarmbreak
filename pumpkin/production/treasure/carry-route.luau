local fs,rb,luau,s=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-carryfix.rbxl'
local bytes=fs.readFile(main);local p=rb.deserializePlace(bytes)
assert(not fs.isFile(backup) or fs.readFile(backup)==bytes,'preserve existing pre-carryfix backup')
fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
local pre=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s3.rbxl'))
local cache={};local function load(n)
 if cache[n] then return cache[n] end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,Vector3=rb.Vector3,CFrame=rb.CFrame}})();return cache[n]
end
local compiled=0
for _,n in p:GetDescendants() do if n:IsA('LuaSourceContainer') then for opt=0,2 do luau.compile(n.Source,{optimizationLevel=opt}) end compiled+=1 end end
local cfg=load(p.ReplicatedStorage.GreyboxConfig)
local gameplay=load(p.ReplicatedStorage.MeadowV4.Gameplay)
local points=gameplay.carry();local length,segments=0,{}
for i=2,#points do
 local a,b=points[i-1],points[i];local horizontal=math.sqrt((b.x-a.x)^2+(b.z-a.z)^2);local rise=b.y-a.y;local d=math.sqrt(horizontal^2+rise^2);length+=d
 table.insert(segments,{name=b.name,length=d,rise=rise,slope_degrees=math.deg(math.atan2(rise,horizontal)),ideal_seconds=d/cfg.CarrySpeed})
end
local names={'GreyboxConfig','GreyboxLayout'}
for _,name in names do assert(p.ReplicatedStorage[name].Source==pre.ReplicatedStorage[name].Source,name) end
for _,name in {'Gameplay','RouteData','Fix2Routes','ReachableDrops','TunnelPolicy','RavinePolicy'} do assert(p.ReplicatedStorage.MeadowV4[name].Source==pre.ReplicatedStorage.MeadowV4[name].Source,name) end
for _,name in {'Greybox','GreyboxArena','GreyboxLoopTestRunner','StudioPass'} do assert(p.ServerScriptService[name].Source==pre.ServerScriptService[name].Source,name) end
assert(not p.ReplicatedStorage.MeadowV4:FindFirstChild('Section5'),'S5 must remain unmounted')
local report={backup_sha256=s.hash('sha256',bytes),canonical_sha256=s.hash('sha256',fs.readFile(main)),compiled_O0_O1_O2=compiled,route_length=length,carry_speed=cfg.CarrySpeed,ideal_seconds=length/cfg.CarrySpeed,segments=segments,before_after_equal=true,timing_limit='Authored polyline / CarrySpeed only; excludes physics, navmesh, pauses, Guardian hits and recovery. Not live route time.',s5_unmounted=true,live_cause='UNKNOWN',fix_mounted=false}
fs.writeFile('treasure/carry-route.json',s.encode('json',report,true));print(s.encode('json',{length=length,ideal_seconds=length/cfg.CarrySpeed,compiled=compiled}))
