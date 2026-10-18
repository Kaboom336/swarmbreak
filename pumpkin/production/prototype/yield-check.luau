-- Canonical-place source mount, offline call/allocation profile and exact parity.
local fs,rb,luau,serde,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde'),require('@lune/process')
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-yield.rbxl'
local out='prototype/yield-evidence/'
local mode=process.args[1] or 'profile'
fs.writeDir(out)
local mounts={Builder='prototype/meadow-v4/MeadowV4.luau',Loader='prototype/meadow-v4/Loader.luau',Section1='prototype/meadow-v4/Section1.luau',Section2='prototype/meadow-v4/Section2.luau',Section3='prototype/meadow-v4/Section3.luau',Section4='prototype/meadow-v4/Section4.luau'}
if mode=='inventory' then
 local p=rb.deserializePlace(fs.readFile(backup))
 fs.writeFile(out..'pre-KitLibrary.luau',p.ServerScriptService.KitLibrary.Source)
 local nodes={};for _,n in p:GetDescendants() do if n.Name:find('Kit') then table.insert(nodes,{path=n:GetFullName(),class=n.ClassName,descendants=#n:GetDescendants()}) end end
 fs.writeFile(out..'kit-inventory.json',serde.encode('json',nodes,true));print(p.ServerScriptService.KitLibrary.Source);return
end
local function profile(place,enabled)
 local cache,stats,stack,warnings={},{},{},{}
 local baseStart,baseCount,baseParts
 local total,parts=0,0
 local function metric(name) if not stats[name] then stats[name]={calls=0,seconds=0,max_seconds=0,created=0,parts=0} end;return stats[name] end
 local function timed(name,fn)
  return function(...)
   local s=metric(name);local start=os.clock();s.calls+=1;table.insert(stack,name)
   local result=table.pack(fn(...));table.remove(stack)
   local elapsed=os.clock()-start;s.seconds+=elapsed;s.max_seconds=math.max(s.max_seconds,elapsed)
   return table.unpack(result,1,result.n)
  end
 end
 local instances={new=function(class)
  local n=rb.Instance.new(class);total+=1;if n:IsA('BasePart') then parts+=1 end
  for _,name in stack do local s=metric(name);s.created+=1;if n:IsA('BasePart') then s.parts+=1 end end
  return n
 end}
 local yields=0
 local function load(node)
  if cache[node] then return cache[node] end
  local env={script=node,require=load,workspace=place.Workspace,warn=function(...) table.insert(warnings,{...}) end,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,Enum=rb.Enum,Instance=instances,UDim2=rb.UDim2,
   task=if enabled then {wait=function() yields+=1 end} else nil,
   profileBase=function(start)
    if start then baseStart,baseCount,baseParts=os.clock(),total,parts else
     stats.BaseLoop={calls=1,seconds=os.clock()-baseStart,max_seconds=os.clock()-baseStart,created=total-baseCount,parts=parts-baseParts}
    end
   end,
   profileCall=timed,
   game={GetService=function(_,name) if name=='ReplicatedStorage' then return place.ReplicatedStorage elseif name=='RunService' then return {} end;assert(name=='HttpService',name);return {JSONDecode=function(_,s)return serde.decode('json',s)end} end}}
  local source=node.Source
  if node.Name=='Builder' then
   source=source:gsub('(\n\tfor _, item in polish)', '\n\tprofileBase(true)%1')
   source=source:gsub('(\n\t%-%- Build every section)', '\n\tprofileBase(false)%1')
  elseif node.Name=='Section2' then source=source:gsub('pcall%(fn%)',"pcall(profileCall('Section2.local.'..name,fn))") end
  local start=os.clock();local value=luau.load(source,{environment=env})();metric(node.Name..'.require').max_seconds=os.clock()-start
  cache[node]=value
  if type(value)=='table' then
   for key,fn in table.clone(value) do if type(fn)=='function' then value[key]=timed(node.Name..'.'..key,fn) end end
  end
  return value
 end
 local model
 if mode=='profile-loader' then
  place.Workspace:SetAttribute('UseMeadowV4',true)
  local parent=rb.Instance.new('Model');parent.Parent=place.Workspace
  model=timed('Loader.wrapped',load(place.ReplicatedStorage.MeadowV4.Loader).wrap(function() error('legacy path') end))(parent,rb.Vector3.zero)
 else model=load(place.ReplicatedStorage.MeadowV4.Builder).build(place.Workspace,rb.Vector3.zero) end
 assert(#warnings==0,serde.encode('json',warnings));assert(not model:GetAttribute('PvpMapClearanceFailure'),'clearance failed')
 -- Lune's Enum.Font setter stores an unserializable FontFace proxy. Compare
 -- every text instance/property separately, then serialize the remaining tree.
 local clone=model:Clone();local text={}
 for _,n in clone:GetDescendants() do if n:IsA('TextLabel') then
  local values={n:GetFullName()}
  for _,key in {'Name','Text','Size','Position','BackgroundTransparency','TextScaled','TextSize','TextColor3','TextTransparency','TextStrokeColor3','TextStrokeTransparency','FontFace','TextWrapped','TextXAlignment','TextYAlignment'} do table.insert(values,{key,tostring(n[key])}) end
  for k,v in n:GetAttributes() do table.insert(values,{'attribute:'..k,tostring(v)}) end
  table.insert(text,serde.encode('json',values));n:Destroy()
 end end
 table.sort(text)
 local full=rb.serializeModel({clone})..table.concat(text,'\n')
 local physical,lanes={},{}
 for _,p in model:GetDescendants() do if p:IsA('BasePart') then
  local tags=p:GetTags();table.sort(tags)
  local attrs={};for k,v in p:GetAttributes() do table.insert(attrs,{k,tostring(v)}) end;table.sort(attrs,function(a,b)return a[1]<b[1]end)
  local q=serde.encode('json',{p.Name,p.ClassName,{p.CFrame:GetComponents()},tostring(p.Size),tostring(p.Color),p.Material.Name,p.Transparency,p.CanCollide,p.CanQuery,p.CanTouch,attrs,tags})
  if p.CanCollide or p.CanQuery or p.CanTouch or #tags>0 or p:GetAttribute('WalkableLaneFloor') then table.insert(physical,q) end
  if p:GetAttribute('WalkableLaneFloor') or p:HasTag('AuthoredLaneFloor') then table.insert(lanes,q) end
 end end
 table.sort(physical);table.sort(lanes)
 local result={calls=stats,created=total,parts=parts,final_instances=#model:GetDescendants()+1,yield_calls=yields,live_Studio='UNKNOWN'}
 return {full=full,physical=table.concat(physical,'\n'),lanes=table.concat(lanes,'\n')},result
end
if mode=='profile' or mode=='profile-loader' then
 local place=rb.deserializePlace(fs.readFile(main))
 -- Include Claude's already-authorized source edit in the pre-fix profile.
 for name,path in mounts do place.ReplicatedStorage.MeadowV4[name].Source=fs.readFile(path) end
 local _,result=profile(place,false)
 fs.writeFile(out..(if mode=='profile' then 'before-profile.json' else 'loader-profile.json'),serde.encode('json',result,true));print(serde.encode('json',result,true));return
end
assert(mode=='mount' or mode=='remount','expected profile or mount')
local original=fs.readFile(if mode=='remount' then backup else main);rb.deserializePlace(original)
if mode~='remount' and fs.isFile(backup) and fs.readFile(backup)~=original then
 local historical=fs.readFile(backup);local archive=out..'historical-pre-yield.rbxl'
 assert(not fs.isFile(archive) or fs.readFile(archive)==historical,'preserve historical backup')
 fs.writeFile(archive,historical);assert(fs.readFile(archive)==historical,'archive bytes')
end
fs.writeFile(backup,original);assert(fs.readFile(backup)==original,'backup bytes')
local old,place=rb.deserializePlace(original),rb.deserializePlace(original)
for name,path in mounts do place.ReplicatedStorage.MeadowV4[name].Source=fs.readFile(path) end
place.ServerScriptService.KitLibrary.Source=fs.readFile('prototype/kits/KitLibrary.luau')
local compiled,preserved=0,0
for _,p in place:GetDescendants() do if p:IsA('LuaSourceContainer') then
 for opt=0,2 do luau.compile(p.Source,{optimizationLevel=opt}) end;compiled+=1
 local q=old;for _,name in string.split(p:GetFullName(),'.') do q=assert(q:FindFirstChild(name),name) end
 if not (p.Parent==place.ReplicatedStorage.MeadowV4 and mounts[p.Name]) and p~=place.ServerScriptService.KitLibrary then assert(q.Source==p.Source,p:GetFullName());preserved+=1 end
end end
assert(rb.serializeModel({old.Workspace})==rb.serializeModel({place.Workspace}),'serialized Workspace changed')
local oldStorage,newStorage=old:FindFirstChild('ServerStorage'),place:FindFirstChild('ServerStorage')
assert((oldStorage==nil)==(newStorage==nil),'kit storage presence changed')
if oldStorage then assert(rb.serializeModel({oldStorage})==rb.serializeModel({newStorage}),'kit storage changed') end
local bytes=rb.serializePlace(place)
local before,beforeStats=profile(old,false)
local after,afterStats=profile(place,true)
for _,key in {'full','physical','lanes'} do assert(before[key]==after[key],key..' signature changed');fs.writeFile(out..key..'.sha256',serde.hash('sha256',after[key])) end
-- task absent is the production offline contract; task present executes all yield guards.
local withoutTask=profile(rb.deserializePlace(bytes),false)
assert(withoutTask.full==before.full,'task absent signature changed')
fs.writeFile(main,bytes)
local delivered=rb.deserializePlace(fs.readFile(main))
assert(rb.serializeModel({delivered.Workspace})==rb.serializeModel({rb.deserializePlace(original).Workspace}),'delivered Workspace changed')
for name,path in mounts do assert(delivered.ReplicatedStorage.MeadowV4[name].Source==fs.readFile(path),'mount '..name) end
assert(delivered.ServerScriptService.KitLibrary.Source==fs.readFile('prototype/kits/KitLibrary.luau'),'kit mount')
fs.writeFile(out..'mounted-profile.json',serde.encode('json',afterStats,true))
fs.writeFile(out..'PARITY.json',serde.encode('json',{compiled_O0_O1_O2=compiled,unrelated_sources_preserved=preserved,backup_sha256=serde.hash('sha256',original),place_sha256=serde.hash('sha256',bytes),workspace_exact=true,server_storage_exact=true,all_built_instances_exact=true,physical_exact=true,lanes_exact=true,task_absent_exact=true,yield_calls=afterStats.yield_calls,live_Studio='UNKNOWN'},true))
print('PASS backup, seven mounted sources, O0/O1/O2 compile, Workspace/kit storage/full instance/physical/lane parity; yields',afterStats.yield_calls)
