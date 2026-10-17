-- Additional cosmetic regression contract; existing gameplay tests stay exact.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local before=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s10r3.rbxl'))
for _,n in p:GetDescendants()do if n:IsA('LuaSourceContainer')and n.Name~='Section9'and n.Name~='Section10'then
 local path={};local q=n;while q.Parent do table.insert(path,1,q.Name);q=q.Parent end
 local old=before;for _,key in path do old=assert(old:FindFirstChild(key),key)end
 assert(n.Source==old.Source,'protected source changed '..n.Name)
end end
local world=rb.Instance.new('Folder');world.Name='GREYBOX';world.Parent=p.Workspace
for i=1,8 do local m=rb.Instance.new('Model');m.Name='HomePlot'..i;m.Parent=world end
local cache,workers={},{}
local main=coroutine.running()
local scheduler={wait=function(delay)if coroutine.running()~=main then coroutine.yield(delay)end end,spawn=function(fn)table.insert(workers,coroutine.create(fn))end}
local warnings={}
local function load(n)
 if cache[n]then return cache[n]end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,task=scheduler,warn=function(s)table.insert(warnings,s)end,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Instance=rb.Instance,Enum=rb.Enum,UDim2=rb.UDim2,
 game={GetService=function(_,name)if name=='Workspace'then return p.Workspace end;assert(name=='ReplicatedStorage');return p.ReplicatedStorage end}}})();return cache[n]
end
local section=load(p.ReplicatedStorage.MeadowV4.Section9)
local manifest=serde.decode('json',fs.readFile('treasure/sections/S9/r4.json'))
local expected={};for _,r in manifest.parts do if r.section=='S9' then table.insert(expected,r)end end
local expectedCount=#expected;assert(expectedCount==1720)
local function check(group)
 local remaining=table.clone(expected);local counts={}
 for _,q in group:GetDescendants()do if q:IsA('BasePart')then
  assert(not q.CanCollide and not q.CanQuery and not q.CanTouch)
  local found
  for i,e in remaining do if e.name==q.Name and (q.CFrame.Position-rb.Vector3.new(unpack(e.position))).Magnitude<.002 and (q.Size-rb.Vector3.new(unpack(e.size))).Magnitude<.002 then found=i;break end end
  assert(found,'unexpected/repositioned S9 dressing '..q.Name);table.remove(remaining,found)
  local category=q.Name:match('^S9_([%a]+)');counts[category]=(counts[category]or 0)+1
 end end
 assert(#remaining==0,'S9 dressing count dropped by '..#remaining)
 assert(counts.BorderPlanter==70 and counts.CornerLampGlow==28 and counts.PlotBoard==8)
 return counts
end
-- Actual finish worker must recover a missing server assembly.
local decor=rb.Instance.new('Model');section.finishDecor(decor)
assert(#workers==1)
for _=1,100 do local ok,err=coroutine.resume(workers[1]);assert(ok,err);if world:FindFirstChild('HomeYardsS9Fallback')then break end end
local fallback=assert(world:FindFirstChild('HomeYardsS9Fallback'),'client recovery never built dressing');check(fallback)
-- Late server build replaces fallback; partial old model is repaired atomically.
local partial=rb.Instance.new('Model');partial.Name='HomeYardsS9';partial.Parent=world
section.build(nil,rb.Vector3.new(513,77,-912));local group=world.HomeYardsS9
assert(group~=partial and group:GetAttribute('S9Complete'));local counts=check(group)
for _=1,15 do if not world:FindFirstChild('HomeYardsS9Fallback')then break end;local ok,err=coroutine.resume(workers[1]);assert(ok,err)end
assert(not world:FindFirstChild('HomeYardsS9Fallback'),'duplicate client dressing survived server arrival')
local n=#group:GetDescendants();section.build(nil,rb.Vector3.zero);assert(#group:GetDescendants()==n)
local home=serde.decode('json',fs.readFile('treasure/sections/S10/r2.json'))
for _,e in home.parts do if e.name=='HomePlotStep'then
 local q=rb.Instance.new('Part');q.Name=e.name;q.Size=rb.Vector3.new(unpack(e.size));q.CFrame=rb.CFrame.new(unpack(e.position));q.Parent=world
end end
local portals=load(p.ReplicatedStorage.MeadowV4.Section10)
portals.build(nil,rb.Vector3.new(513,77,-912))
local expectedPortals={}
local final=serde.decode('json',fs.readFile('treasure/sections/S10/r4.json'))
for _,e in final.parts do if e.section=='S10' then table.insert(expectedPortals,e)end end
local portalCount=#expectedPortals
for _,q in world.HomePortalsS10:GetDescendants()do if q:IsA('BasePart')then
 local found;for i,e in expectedPortals do if e.name==q.Name and (q.CFrame.Position-rb.Vector3.new(unpack(e.position))).Magnitude<.002 then found=i;break end end
 assert(found,'portal home origin leaked '..q.Name);table.remove(expectedPortals,found)
 assert(not q.CanCollide and not q.CanQuery and not q.CanTouch)
end end
assert(#expectedPortals==0 and portalCount==104)
local portalNodes=#world.HomePortalsS10:GetDescendants();portals.build(nil,rb.Vector3.zero);assert(#world.HomePortalsS10:GetDescendants()==portalNodes)
-- Negative control: this contract must fail when even one planter is removed.
group.S9_BorderPlanter1:Destroy();assert(not pcall(check,group),'count-drop negative control did not fail')
world:Destroy();section.build(nil,rb.Vector3.zero);portals.build(nil,rb.Vector3.zero)
assert(not p.Workspace:FindFirstChild('HomeYardsS9')and not p.Workspace:FindFirstChild('HomePortalsS10'))
local report={s9_parts=expectedCount,s10_parts=portalCount,categories=counts,home_local_origin=true,standalone_noop=true,missing_server_recovery=true,late_server_retires_fallback=true,partial_model_repaired=true,count_drop_negative_control=true,protected_sources_exact=true,live_Studio='UNKNOWN'}
fs.writeFile('treasure/sections/S10/HOME-R34.json',serde.encode('json',report,true))
print('PASS S9 R4 1720-part manifest/count contract; missing/partial/late assembly recovery; idempotence; count-drop negative control; protected sources exact')
print('PASS 104 S10 cosmetics at home-local origin; nonzero Meadow origin; idempotence; standalone no-op; physics false')
