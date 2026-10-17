-- Exercise actual mounted sources with textured MeshParts, plus the existing
-- deterministic KitLibrary service/scale fixture (no InsertService/network).
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local baseline=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-rockcolor.rbxl'))
local manifest=serde.decode('json',p.ServerScriptService.KitLibrary.Manifest.Value)
local harness=fs.readFile('prototype/kits/library-test.luau')
local prefix=harness:sub(1,assert(harness:find('kit.init();kit.init()',1,true))-1)
prefix=prefix:gsub('local catalog={{.-\nlocal calls,','local catalog=fixtureCatalog\nlocal calls,')
prefix=prefix:gsub("fs.readFile%('prototype/kits/KitLibrary.luau'%)",'librarySource')
prefix=prefix:gsub('p:SetAttribute%(\'WalkableLaneFloor\',true%)',[[p.TextureID='rbxassetid://123';local surface=new('SurfaceAppearance');surface.Parent=p
 p:SetAttribute('WalkableLaneFloor',true)]])
prefix=prefix:gsub('function methods:GetDescendants%(%)',[[function methods:GetChildren()local out={};for _,c in self.children do if not c.dead then table.insert(out,c)end end;return out end
function methods:GetDescendants()]])
local fixtures={}
for i,e in manifest do local f=table.clone(e);f.id=100+i;f.meshParts=1;table.insert(fixtures,f)end
local function library(source)
 local env=table.clone(getfenv());env.fixtureCatalog=fixtures;env.librarySource=source
 return luau.load(prefix..'\nkit.init();return kit',{environment=env,injectGlobals=true})()
end
local oldKit,newKit=library(baseline.ServerScriptService.KitLibrary.Source),library(p.ServerScriptService.KitLibrary.Source)
local warm,controls=0,0
for i,e in fixtures do
 local frame=rb.CFrame.new(i,2,i*3);local a=assert(oldKit.spawn(e.name,e.island,frame,1));local b=assert(newKit.spawn(e.name,e.island,frame,1))
 local n=e.name:lower();local target=e.island=='meadow'and(n:find('rock',1,true)or n:find('cliff',1,true)or n:find('stone_large',1,true)or n:find('pebble',1,true))
 local aa,bb=a:GetDescendants(),b:GetDescendants()
 local ap,bp={},{ };for _,v in aa do if v:IsA('BasePart')then table.insert(ap,v)end end;for _,v in bb do if v:IsA('BasePart')then table.insert(bp,v)end end
 assert(#ap==#bp)
 for j,q in bp do
  local r=ap[j];assert(q.Size==r.Size and q.CFrame==r.CFrame and q.CanCollide==r.CanCollide and q.CanQuery==r.CanQuery and q.CanTouch==r.CanTouch,'spawn geometry/flags changed')
  if target then
   assert(q.TextureID=='' and q.Material==rb.Enum.Material.Slate and q.Color.R>q.Color.G and q.Color.G>q.Color.B,'atlas/stone regression')
   for _,c in q:GetChildren()do assert(not c:IsA('SurfaceAppearance'))end
  else assert(q.TextureID==r.TextureID and q.Material==r.Material and q.Color==r.Color,'non-rock changed')end
 end
 if target then warm+=1 else controls+=1 end
end
local cache={}
local function load(n)
 if cache[n]then return cache[n]end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,Instance=rb.Instance,Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum}})();return cache[n]
end
local kit={}
function kit.spawn(_,_,frame,size)
 local m=rb.Instance.new('Model');local q=rb.Instance.new('MeshPart');q.TextureID='rbxassetid://123';q.Size=size;q.CFrame=frame*rb.CFrame.new(0,size.Y/2,0);q.Parent=m
 local surface=rb.Instance.new('SurfaceAppearance');surface.Parent=q;return m
end
function kit.fit()return true end
local root=rb.Instance.new('Model');root:SetAttribute('MeadowOrigin',rb.Vector3.new(300,7,-200))
local shells=load(p.ReplicatedStorage.MeadowV4.ZRockShells);shells.spawnKits(root,kit)
local oldRoot=rb.Instance.new('Model');oldRoot:SetAttribute('MeadowOrigin',root:GetAttribute('MeadowOrigin'))
load(baseline.ReplicatedStorage.MeadowV4.ZRockShells).spawnKits(oldRoot,kit)
local oldShells=oldRoot.MeadowRockShells:GetChildren()
local count=0;local colors={}
for _,m in root.MeadowRockShells:GetChildren()do
 count+=1;local g=shells.plan[count];local q=m:FindFirstChildWhichIsA('MeshPart')
 assert(q.TextureID=='' and q.Material==rb.Enum.Material.Slate and q.Color==rb.Color3.fromRGB(unpack(g.color)))
 assert(not q:FindFirstChildWhichIsA('SurfaceAppearance')and not q.CanCollide and not q.CanQuery and not q.CanTouch)
  local original=oldShells[count]:FindFirstChildWhichIsA('MeshPart')
  assert(q.Size==original.Size and q.CFrame==original.CFrame,'shell geometry changed from baseline')
  assert((q.Size-rb.Vector3.new(unpack(g.s))).Magnitude<.0001,'shell fixture fit drift')
 local expected=rb.CFrame.new(root:GetAttribute('MeadowOrigin')+rb.Vector3.new(unpack(g.c)))*rb.CFrame.new(0,0,0,unpack(g.r))
 assert((q.CFrame.Position-expected.Position).Magnitude<.001
  and (q.CFrame.RightVector-expected.RightVector).Magnitude<.0001
  and (q.CFrame.UpVector-expected.UpVector).Magnitude<.0001,'shell fixture transform drift')
 colors[tostring(q.Color)]=true
end
assert(count==#shells.plan and count==500);shells.spawnKits(root,kit);assert(#root.MeadowRockShells:GetChildren()==count)
local tones=0;for _ in colors do tones+=1 end;assert(tones>1)
local report={state='PASS',canonical_sha256=serde.hash('sha256',fs.readFile('slice-v2/prototype/guardian-greybox.rbxl')),rock_catalog_entries=warm,unchanged_catalog_controls=controls,shells=count,planned_tones=tones,textured_MeshPart_and_SurfaceAppearance_fixture=true,nonzero_origin_and_idempotence=true,geometry_flags_preserved=true,limitations='Synthetic service/mesh fixtures; actual Studio appearance remains unverified.'}
fs.writeFile('treasure/rockcolor/TEXTURES.json',serde.encode('json',report,true));print('PASS',warm,'rock kit entries;',controls,'unchanged controls;',count,'textured shells;',tones,'planned tones; geometry exact')
