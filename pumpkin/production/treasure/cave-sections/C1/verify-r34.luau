-- Read-only verification of the final mounted presentation and conservation.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local H='treasure/cave-sections/C1/'
local bytes=fs.readFile('prototype/cave-v2.rbxl');local p=rb.deserializePlace(bytes)
local S=p.ServerScriptService;local node=S.CaveArrivalC1;local map=p.Workspace.CaveV2
local original=rb.deserializePlace(fs.readFile('prototype/cave-v2.pre-c1r3.rbxl'))
original.Workspace.CaveArrivalC1:Destroy();original.ServerScriptService.CaveArrivalC1:Destroy()
local neutral=rb.deserializePlace(bytes);neutral.Workspace.CaveArrivalC1:Destroy();neutral.ServerScriptService.CaveArrivalC1:Destroy()
assert(rb.serializePlace(original)==rb.serializePlace(neutral),'pre-R3 unrelated state changed')
local saved={}
for i,n in map:GetDescendants()do
 if n:IsA('BasePart')then
  n.Color,n.Material,n.Transparency=n.Color,n.Material,n.Transparency
  table.insert(saved,{n,n.Color,n.Material,n.Transparency})
 elseif n:IsA('Light')then n.Enabled=n.Enabled;table.insert(saved,{n,n.Enabled})end
 if i%200==0 then require('@lune/task').wait()end
end
local before=rb.serializeModel({map})
local waits=0
local env={Color3=rb.Color3,Enum=rb.Enum,task={wait=function()waits+=1 end}}
local apply=luau.load(node.Presentation.Source,{environment=env})()
local report=apply(map,'r4');local once=rb.serializeModel({map})
apply(map,'r4');assert(once==rb.serializeModel({map}),'presentation not idempotent')
for _,entry in saved do
 local n=entry[1]
 if n:IsA('BasePart')then
  local changed=n.Color~=entry[2]or n.Material~=entry[3]or n.Transparency~=entry[4]
  if changed then
   assert(not n.CanCollide,'changed a physical solid')
   assert(n.Name=='MainGatewayFabric'or n.Name=='MainGatewayPennant'or n.Name:match('^Crystal')or n.Name=='R3CliffVoxelSkin'or n.Name=='CliffInsetBlock'or n.Name=='CliffSteppedLedge','visual whitelist')
  end
  n.Color,n.Material,n.Transparency=entry[2],entry[3],entry[4]
 else n.Enabled=entry[2]end
end
assert(before==rb.serializeModel({map}),'presentation changed nonvisual state')
local Lane=luau.load(S.KitPlan.Source,{environment={Vector3=rb.Vector3,CFrame=rb.CFrame}})()
local fail=false;local kit={}
function kit.spawn(_,_,base,size)
 local m=rb.Instance.new('Model');local q=rb.Instance.new('MeshPart');q.Size=size;q.CFrame=base*rb.CFrame.new(0,size.Y/2,0);q.TextureID='rbxassetid://123';q.Parent=m
 local a=rb.Instance.new('SurfaceAppearance');a.Parent=q;return m
end
function kit.fit()return not fail end
local runtime={script=node,workspace={WaitForChild=function(_,name)return assert(p.Workspace:FindFirstChild(name))end},Instance=rb.Instance,Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,task=env.task,warn=function()end,
 game={GetService=function(_,name)
  if name=='HttpService'then return {JSONDecode=function(_,s)return serde.decode('json',s)end}end
  return {WaitForChild=function(_,key)return assert(S:FindFirstChild(key))end}
 end},require=function(n)if n==node.Presentation then return apply elseif n==S.KitLibrary then return kit elseif n==S.KitPlan then return Lane end;error('unexpected module')end}
local function run()luau.load(node.Source,{environment=runtime})()end
run();local root=p.Workspace.CaveArrivalC1;assert(root.Rocks:GetAttribute('Complete'))
local count=0
for _,n in root.Rocks:GetDescendants()do if n:IsA('BasePart')then
 count+=1;assert(n.TextureID==''and not n:FindFirstChildWhichIsA('SurfaceAppearance'),'texture survived')
 assert(n.Anchored and not n.CanCollide and not n.CanQuery and not n.CanTouch,'flags')
end end
local onceRuntime=rb.serializeModel({root});run();assert(onceRuntime==rb.serializeModel({root}),'duplicate assembly')
root.Rocks:Destroy();for _,n in root:GetChildren()do if n:IsA('BasePart')then n.Transparency=0 end end
fail=true;run();assert(not root:FindFirstChild('Rocks'),'incomplete staging published')
for _,n in root:GetChildren()do if n:IsA('BasePart')then assert(n.Transparency==0,'failure hid fallback')end end
fail=false;run();assert(root.Rocks:GetAttribute('Complete'),'retry failed')
fs.writeFile(H..'VERIFY-R34.json',serde.encode('json',{state='PASS',place_sha256=serde.hash('sha256',bytes),pre_r3_sha256=serde.hash('sha256',fs.readFile('prototype/cave-v2.pre-c1r3.rbxl')),original_serialization_exact=true,presentation_only_whitelisted_visuals=true,presentation=report,runtime_rocks=count,texture_clear=true,idempotence=true,failed_fit_cleanup_retry=true,yields=waits,studio_play='NOT RUN'},true))
print('PASS R34 conservation, cosmetic whitelist, actual mounted runtime, textures, lanes, flags, staging/retry, idempotence')
