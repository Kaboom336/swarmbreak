-- Reuse home coordinate/idempotence contract with the new cosmetic manifest.
-- Original home-contracts.luau and all gameplay/placement tests remain exact.
local fs,luau,rb,serde=require('@lune/fs'),require('@lune/luau'),require('@lune/roblox'),require('@lune/serde')
local tag=require('@lune/process').args[1]or'r4'
local home=serde.decode('json',fs.readFile('treasure/sections/S9/'..tag..'.json'))
local count=0;for _,q in home.parts do if q.section=='S9'then count+=1 end end
local source=fs.readFile('treasure/sections/S9/home-contracts.luau'):gsub('r2.json',tag..'.json'):gsub('220',tostring(count))
luau.load(source,{environment=getfenv(),injectGlobals=true})()
local before=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s9r3.rbxl'))
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
assert(p.StarterPlayer.StarterPlayerScripts.HomeArt.Source==before.StarterPlayer.StarterPlayerScripts.HomeArt.Source,'HomeArt changed')
p.ReplicatedStorage.MeadowV4.Section9.Source=before.ReplicatedStorage.MeadowV4.Section9.Source
assert(rb.serializePlace(p)==rb.serializePlace(before),'change beyond Section9 source')
print('PASS immediate R2 backup parity: only Section9 Source changed; HomeArt/gameplay/tests/serialized state exact')
-- Exercise the actual owner-binding function with replicated-label signal mocks.
local world=rb.Instance.new('Folder');world.Name='GREYBOX';world.Parent=p.Workspace
for i=1,8 do local plot=rb.Instance.new('Model');plot.Name='HomePlot'..i;plot.Parent=world end
local fakeWorkspace=p.Workspace;local cache={}
local function load(n)
 if cache[n]then return cache[n]end
 local env={script=n,require=load,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Instance=rb.Instance,Enum=rb.Enum,UDim2=rb.UDim2,
 game={GetService=function(_,name)if name=='Workspace'then return fakeWorkspace end;assert(name=='ReplicatedStorage');return p.ReplicatedStorage end}}
 cache[n]=luau.load(n.Source,{environment=env})();return cache[n]
end
-- Use final source again, after the preservation neutralizer above.
p.ReplicatedStorage.MeadowV4.Section9.Source=fs.readFile('prototype/meadow-v4/Section9.luau')
local section=load(p.ReplicatedStorage.MeadowV4.Section9);section.build(nil,rb.Vector3.zero)
local group=world.HomeYardsS9;local sources,callbacks,guis={},{},{}
local fakeWorld={FindFirstChild=function(_,name)
 if name=='HomeYardsS9'then return group end
 local slot=tonumber(name:match('^HomePlot(%d+)$'));if not slot then return end
 return {FindFirstChild=function()return {FindFirstChildOfClass=function()return guis[slot]end}end}
end}
fakeWorkspace={FindFirstChild=function()return fakeWorld end}
for i=1,8 do
 local slot=i
 sources[i]={Text='> Pen '..i..' / vacant',GetPropertyChangedSignal=function(_,field)
  assert(field=='Text');return {Connect=function(_,callback)assert(not callbacks[slot]);callbacks[slot]=callback end}
 end}
 guis[i]={Enabled=true,FindFirstChildWhichIsA=function()return sources[slot]end}
end
local delayed=guis[8];guis[8]=nil
assert(section.bindOwners()==7,'late owner source should remain unbound')
guis[8]=delayed
assert(section.bindOwners()==8);assert(section.bindOwners()==8)
for i=1,8 do
 assert(not guis[i].Enabled and callbacks[i])
 local function check(expected)
  local n=0
  for _,gui in group:FindFirstChild('S9_PlotBoard'..i):GetChildren()do if gui:IsA('SurfaceGui')then
   assert(gui.LiveOwner.Text==expected);n+=1
  end end
  assert(n==2)
 end
 check('vacant');sources[i].Text='> Pen '..i..' / Zion';callbacks[i]();check('Zion')
 sources[i].Text='> Pen '..i..' / vacant';callbacks[i]();check('vacant')
end
print('PASS original owner TextLabel -> two wooden board faces: vacant/name/vacant; single binding; late replication; no ownership writes')
local baseline=serde.decode('json',fs.readFile('treasure/sections/S9/r2-visual.json'))
local decor=rb.Instance.new('Model');local originals={}
for _,r in baseline.parts do if r.section=='ClientDecorProxy'then
 local q=rb.Instance.new('Part');q.Name=r.name:sub(#'ClientDecor_'+1);q.Size=rb.Vector3.new(unpack(r.size))
 q.CFrame=rb.CFrame.new(r.position[1],r.position[2],r.position[3],unpack(r.rotation))
 q.Color=rb.Color3.fromRGB(unpack(r.color));q.Material=rb.Enum.Material[r.material];q.Transparency=r.transparency
 q.Anchored=true;q.CanCollide=false;q.CanQuery=false;q.CanTouch=false;q.Parent=decor
 for k,v in r.attributes do q:SetAttribute(k,v)end
 originals[q]={size=q.Size,frame=q.CFrame,attributes=serde.encode('json',q:GetAttributes())}
end end
section.finishDecor(decor);local descendants=decor:GetDescendants()
for _,q in descendants do if q:IsA('BasePart')then
 assert(q.Anchored and not q.CanCollide and not q.CanQuery and not q.CanTouch,'client cosmetic flags')
 local old=originals[q]
 if old then assert(q.Size==old.size and q.CFrame==old.frame and serde.encode('json',q:GetAttributes())==old.attributes,'client geometry/attributes changed')end
end end
assert(section.finishDecor(decor)==0 and #decor:GetDescendants()==#descendants,'client finish duplicated art')
print('PASS actual finishDecor: original pad/decor transforms, sizes, attributes exact; every client cosmetic physics false; idempotence')
