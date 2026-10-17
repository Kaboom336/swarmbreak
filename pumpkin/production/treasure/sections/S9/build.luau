local fs,rb,luau,serde,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde'),require('@lune/process')
local H='treasure/sections/S9/'
local tag=process.args[1] or 'before'
local original=fs.readFile('slice-v2/prototype/guardian-greybox.pre-s9.rbxl')
local p=rb.deserializePlace(original)
local originalHomeArt=p.StarterPlayer.StarterPlayerScripts.HomeArt.Source
if tag~='before' then
 local s=rb.Instance.new('ModuleScript');s.Name='Section9';s.Source=fs.readFile('prototype/meadow-v4/Section9.luau');s.Parent=p.ReplicatedStorage.MeadowV4
 fs.writeFile(H..tag..'-Section9.luau',s.Source)
end
if tag=='r2'then
 local homeSource=fs.readFile('slice-v2/prototype/HomeArt.client.luau')
 local hook='\t-- S9 decor finish only; pet/loot presentation and authoritative state are unchanged.\n\tlocal finishOK, finishError = pcall(function() require(RS.MeadowV4.Section9).finishDecor(decor) end)\n\tif not finishOK then warn("[HomeArt] S9 decor finish skipped: " .. tostring(finishError)) end\n'
 local a,b=homeSource:find(hook,1,true);assert(a,'missing cosmetic hook')
 assert(homeSource:sub(1,a-1)..homeSource:sub(b+1)==originalHomeArt,'HomeArt delta beyond exact cosmetic hook')
 p.StarterPlayer.StarterPlayerScripts.HomeArt.Source=homeSource
 fs.writeFile(H..'r2-HomeArt.luau',homeSource)
end
local count=0
for _,s in p:GetDescendants() do if s:IsA('LuaSourceContainer') then for opt=0,2 do luau.compile(s.Source,{optimizationLevel=opt}) end;count+=1 end end
local bytes=rb.serializePlace(p)
local neutral=rb.deserializePlace(bytes)
if tag~='before' then neutral.ReplicatedStorage.MeadowV4.Section9:Destroy() end
neutral.StarterPlayer.StarterPlayerScripts.HomeArt.Source=originalHomeArt
assert(rb.serializePlace(neutral)==rb.serializePlace(rb.deserializePlace(original)),'unrelated place mutation')
local warnings,cache={},{}
local function load(node)
 if cache[node] then return cache[node] end
 local env={script=node,require=load,warn=function(...)table.insert(warnings,{...})end,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,
 game={GetService=function(_,n)if n=='ReplicatedStorage' then return p.ReplicatedStorage elseif n=='Workspace' then return p.Workspace elseif n=='RunService' then return {} end;assert(n=='HttpService',n);return {JSONDecode=function(_,s)return serde.decode('json',s)end} end}}
 local source=node.Source:gsub(':WaitForChild%(',':FindFirstChild(')
 cache[node]=luau.load(source,{environment=env})();return cache[node]
end
local world=rb.Instance.new('Folder');world.Name='GREYBOX';world.Parent=p.Workspace
local function make(parent,name,size,pos,color)
 local q=rb.Instance.new('Part');q.Name=name;q.Size=size;q.CFrame=rb.CFrame.new(pos);q.Color=color;q.Anchored=true;q.Parent=parent;return q
end
local Scene=load(p.ReplicatedStorage.GreyboxScene)
local Placement=load(p.ReplicatedStorage.GreyboxPlacement)
Scene.home(world,make,function()end)
local bounds={}
for i=1,8 do
 local x,z=Placement.center(i);local y=Placement.height(i)
 local plot=rb.Instance.new('Model');plot.Name='HomePlot'..i;plot.Parent=world
 local function raised(parent,name,size,pos,color)return make(parent,name,size,pos+rb.Vector3.new(0,y,0),color) end
 local base=raised(plot,'Pen'..i,rb.Vector3.new(64,.2,48),rb.Vector3.new(x,.1,z),rb.Color3.fromRGB(100,115,100));base:SetAttribute('SurfaceRole','Floor')
 Scene.pen(plot,x,z,raised)
 local marker=raised(plot,'PenMarker'..i,rb.Vector3.new(2,3,2),rb.Vector3.new(x+(x<0 and 32 or -32),1.5,z+8),rb.Color3.fromRGB(255,160,40));marker.CanCollide=false
 for step=1,math.ceil(y/.5) do local h=math.min(step*.5,y);local q=make(world,'HomePlotStep',rb.Vector3.new(.9,h,12),rb.Vector3.new((x<0 and -1 or 1)*(1.4+step*.9),h/2,z),rb.Color3.fromRGB(180,173,157));q:SetAttribute('SurfaceRole','Floor') end
 table.insert(bounds,{slot=i,center={x,y,z},x={x-32,x+32},z={z-24,z+24},gate_width=12})
end
if tag~='before' then
 -- Exercise the exact production guard, with home already built as in Greybox.
 load(p.ReplicatedStorage.MeadowV4.Builder).build(p.Workspace,rb.Vector3.new(0,76,-360))
 assert(#warnings==0,serde.encode('json',warnings))
end
local function record(q)
 local c={q.CFrame:GetComponents()};local r={};for i=4,12 do table.insert(r,c[i])end
 return {name=q.Name,position={c[1],c[2],c[3]},rotation=r,size={q.Size.X,q.Size.Y,q.Size.Z},color={q.Color.R*255,q.Color.G*255,q.Color.B*255},material=q.Material.Name,shape=q:IsA('Part') and q.Shape.Name or 'Wedge',transparency=q.Transparency,collidable=q.CanCollide,query=q.CanQuery,touch=q.CanTouch,tags=q:GetTags(),attributes=q:GetAttributes(),section=q:GetAttribute('Section'),label=q:GetAttribute('RouteLabel'),labelFace=q:GetAttribute('LabelFace'),labelSize=q:GetAttribute('LabelSize')}
end
local parts,lights={},{}
for _,q in world:GetDescendants()do if q:IsA('BasePart')then table.insert(parts,record(q)) elseif q:IsA('PointLight')then local c=q.Parent.CFrame.Position;table.insert(lights,{position={c.X,c.Y,c.Z},color={q.Color.R,q.Color.G,q.Color.B},brightness=q.Brightness,range=q.Range,shadows=q.Shadows})end end
fs.writeFile(H..tag..'.json',serde.encode('json',{parts=parts,lights=lights,kits={},bounds=bounds}))
local visual={};for _,q in parts do
 -- Exact HomeArt client visibility exclusions, not hidden gameplay geometry.
 local n=q.name
 local hidden=(n:match('^Pen') and (n:find('Rail') or n=='PenPost' or n=='PenAccessPath')) or n=='TreeTrunk' or n:find('BlockCanopy') or table.find({'CentralStonePath','CyanPortalDisc','LockedPortalDisc','PortalFoot','LockedPortalTerrace','TerraceLanding','LanternPost','LanternCap','LanternLight'},n) or n:match('^PortalArchStone') or n:match('^TerraceStep')
 if not hidden then table.insert(visual,q)end
end
local data=load(p.ReplicatedStorage.HomeArtGeometry);local blocks=load(p.ReplicatedStorage.NativeBlocks)
local decor=rb.Instance.new('Model')
for _,s in data.Decor do
 local section=table.clone(s);local n=section.name:lower();local neon=table.find({'PortalLight','PortalGreen','Cyan','LampLight'},section.name)~=nil
 local material=(n:find('wood')or n:find('brown'))and rb.Enum.Material.WoodPlanks or(n:find('grass')or n:find('leaf')or n:find('green'))and rb.Enum.Material.Grass or n:find('path')and rb.Enum.Material.Cobblestone or rb.Enum.Material.Slate
 if section.name=='Lava' then section.color={143,105,69} end
 blocks.section(section,decor,rb.CFrame.new(),neon and rb.Enum.Material.Neon or material)
end
if tag=='r2'then print('client platforms finished',load(p.ReplicatedStorage.MeadowV4.Section9).finishDecor(decor))end
for _,q in decor:GetChildren()do local v=record(q);v.name='ClientDecor_'..v.name;v.section='ClientDecorProxy';v.collidable=false;v.query=false;v.touch=false;table.insert(visual,v)end
fs.writeFile(H..tag..'-visual.json',serde.encode('json',{parts=visual,lights=lights,kits={}}))
fs.writeFile(H..'BOUNDS.json',serde.encode('json',{home_world_offset={0,0,0},source='canonical GreyboxPlacement + Greybox server + GreyboxScene',plots=bounds,section={x={-176,176},y={-30,65},z={-110,135}},north_plot_out_of_section='preserve exact; no new art north of -110'},true))
if tag~='before'then fs.writeFile(H..string.upper(tag)..'-review.rbxl',bytes);fs.writeFile('slice-v2/prototype/guardian-greybox.rbxl',bytes)end
fs.writeFile(H..'MOUNT-'..tag..'.json',serde.encode('json',{compiled_O0_O1_O2=count,all_unrelated_sources_and_serialized_place_exact=true,changed_sources=tag=='r2'and{'Section9','HomeArt: isolated decor finish hook'}or tag=='r1'and{'Section9'}or{},canonical_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',original)},true))
print('PASS',tag,'compile',count,'exact unrelated place; home export',#parts,'client visual',#visual)
