local fs,rb,luau,serde,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde'),require('@lune/process')
local H='treasure/rockcolor/'
local main='slice-v2/prototype/guardian-greybox.rbxl'
local backup='slice-v2/prototype/guardian-greybox.pre-rockcolor.rbxl'
local mode=process.args[1] or 'check'
if not fs.isDir(H)then fs.writeDir(H)end
if mode=='backup'then
 assert(not fs.isFile(backup),'backup already exists')
 local bytes=fs.readFile(main);rb.deserializePlace(bytes);fs.writeFile(backup,bytes);assert(fs.readFile(backup)==bytes)
 fs.writeFile(H..'BACKUP.json',serde.encode('json',{sha256=serde.hash('sha256',bytes),byte_verified=true},true));print('PASS byte-verified pre-rockcolor backup');return
end
local baseline=fs.readFile(backup)
local p=rb.deserializePlace(baseline)
local paths={['ReplicatedStorage.MeadowV4.ZRockShells']='prototype/meadow-v4/ZRockShells.luau',['ServerScriptService.KitLibrary']='prototype/kits/KitLibrary.luau'}
local function node(root,path)local n=root;for key in path:gmatch('[^.]+')do n=n[key]end;return n end
for path,file in paths do node(p,path).Source=fs.readFile(file)end
local m=rb.Instance.new('ModuleScript');m.Name='ZRockColor';m.Source=fs.readFile('prototype/meadow-v4/ZRockColor.luau');m:SetAttribute('MeadowDressing',true);m.Parent=p.ReplicatedStorage.MeadowV4
local compiled=0
for _,s in p:GetDescendants()do if s:IsA('LuaSourceContainer')then for o=0,2 do luau.compile(s.Source,{optimizationLevel=o})end;compiled+=1 end end
local bytes=rb.serializePlace(p)
local neutral=rb.deserializePlace(bytes);local old=rb.deserializePlace(baseline)
neutral.ReplicatedStorage.MeadowV4.ZRockColor:Destroy()
for path in paths do node(neutral,path).Source=node(old,path).Source end
assert(rb.serializePlace(neutral)==rb.serializePlace(old),'unrelated serialized place mutation')
local function build(place)
 local cache,warnings={},{}
 local function load(n)
  if cache[n]then return cache[n]end
  cache[n]=luau.load(n.Source,{environment={script=n,require=load,Instance=rb.Instance,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,UDim2=rb.UDim2,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,
   warn=function(...)table.insert(warnings,{...})end,game={GetService=function(_,name)
    if name=='ReplicatedStorage'then return place.ReplicatedStorage elseif name=='ServerStorage'then return place.ServerStorage elseif name=='Workspace'then return place.Workspace elseif name=='RunService'then return {} end
    assert(name=='HttpService',name);return {JSONDecode=function(_,s)return serde.decode('json',s)end}
   end}}})();return cache[n]
 end
 local root=load(place.ReplicatedStorage.MeadowV4.Builder).build(place.Workspace,rb.Vector3.zero)
 assert(#warnings==0,serde.encode('json',warnings))
 -- Lune represents Builder's generated FontFace aliases as EnumItem. Normalize
 -- identically on audit-only trees; canonical bytes above are never rewritten.
 for _,n in root:GetDescendants()do if n:IsA('TextLabel')or n:IsA('TextButton')or n:IsA('TextBox')then
  n.FontFace=rb.Font.new('rbxasset://fonts/families/Arial.json')
 end end
 return root
end
local a,b=build(old),build(neutral)
-- Neutral sources provide an exact determinism control before the real build.
assert(rb.serializePlace(old)==rb.serializePlace(neutral),'baseline Builder nondeterminism')
local final=rb.deserializePlace(bytes);local root=build(final)
local before,after=a:GetDescendants(),root:GetDescendants();assert(#before==#after,'instance count changed')
local recolored,parts,colliders,lights=0,0,0,0
for i,q in after do
 local original=before[i];assert(q.ClassName==original.ClassName and q.Name==original.Name,'tree order changed')
 if q:IsA('BasePart')then
  parts+=1;if q.CanCollide then colliders+=1 end
  if q.Color~=original.Color or q.Material~=original.Material then
   assert((q.Name=='LookLightRockTop'or q.Name=='Round4PaleRockTop')and not q.CanCollide and not q.CanQuery and not q.CanTouch,'unexpected appearance change')
   assert(q.Color.R>q.Color.G and q.Color.G>q.Color.B and q.Material==rb.Enum.Material.Slate,'shelf not warm stone')
   recolored+=1;q.Color=original.Color;q.Material=original.Material
  end
 elseif q:IsA('Light')then lights+=1 end
end
assert(recolored>0,'no S6 cap recolors')
final.ReplicatedStorage.MeadowV4.ZRockColor:Destroy()
for path in paths do node(final,path).Source=node(old,path).Source end
assert(rb.serializePlace(final)==rb.serializePlace(old),'runtime geometry/metadata/light preservation failed')
local report={state='PASS',canonical_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',baseline),compiled_O0_O1_O2=compiled,shelf_recolors=recolored,native_parts=parts,colliders=colliders,lights=lights,complete_serialized_preservation_except_named_sources=true,runtime_complete_preservation_except_shelf_appearance=true}
if mode=='deliver'then
 assert(fs.readFile(main)==baseline,'canonical changed after backup');fs.writeFile(main,bytes);assert(fs.readFile(main)==bytes)
else fs.writeFile(H..'candidate.rbxl',bytes)end
fs.writeFile(H..'MOUNT-'..mode..'.json',serde.encode('json',report,true))
print('PASS',mode,compiled,'compiled sources;',recolored,'S6 cosmetic caps;',parts,'parts;',colliders,'colliders exact; full serialized/runtime conservation')
