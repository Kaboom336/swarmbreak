-- Execute the production swap with native Lune instances and fake imported visuals.
-- This tests preservation/fallback, not Roblox mesh appearance or physics.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local V,C=rb.Vector3,rb.CFrame
local Plan=luau.load(fs.readFile('prototype/kits/Plan.luau'),{environment={Vector3=V,CFrame=C}})()
local place=rb.deserializePlace(fs.readFile('prototype/cave-v2.rbxl'))
local root=place.Workspace.CaveV2
local saved={}
for _,p in root:GetDescendants() do if p:IsA('BasePart') then saved[p]={p.CFrame,p.Size,p.CanCollide,p.CanTouch,p.CanQuery,p.Name,p.Transparency} end end
local fallbackParts={}
for _,g in Plan.groups(root,'cave') do if g.name=='kenney_survival-kit__box' then for _,p in g.parts do fallbackParts[p]=true end end end
local entries=serde.decode('json',place.ServerScriptService.KitLibrary.Manifest.Value)
local kit={templates={},init=function() end}
for _,e in entries do
 local t=rb.Instance.new('Model');t:SetAttribute('KitNativeSize',V.new(unpack(e.size)));kit.templates[e.island..'__'..e.name]=t
end
local spawned=0
function kit.spawn(name,island,base,scale)
 -- Force the first missing-asset path: originals must stay visible.
 if name=='kenney_survival-kit__box' then return nil,'forced missing asset' end
 local m=rb.Instance.new('Model');m.Name=name;m:SetAttribute('KitTriangles',10)
 local p=rb.Instance.new('MeshPart');p.Size=if typeof(scale)=='Vector3' then scale else V.one*scale
 p.CFrame=base*C.new(0,p.Size.Y/2,0);p.CanCollide=true;p.CanQuery=true;p.Parent=m
 spawned+=1;return m
end
function kit.fit() return true end
local scriptObject={Parent={KitLibrary={},KitPlan={}}}
local source=fs.readFile('prototype/kits/Swap.server.luau')
source=source:sub(1,assert(source:find('local function watch',1,true))-1)..'\nreturn apply'
local apply=luau.load(source,{environment={script=scriptObject,require=function(n) return if n==scriptObject.Parent.KitLibrary then kit else Plan end,
 game={GetService=function() return {GetTotalMemoryUsageMb=function() return 10 end} end},workspace=place.Workspace,
 Instance=rb.Instance,Vector3=V,CFrame=C,Enum=rb.Enum,warn=function() end}})()
apply(root,'cave')
assert(spawned>0 and root:GetAttribute('KitFallbacks')>0,'swap/fallback paths not exercised')
for p,values in saved do
 assert(p.CFrame==values[1] and p.Size==values[2] and p.CanCollide==values[3] and p.CanTouch==values[4] and p.CanQuery==values[5] and p.Name==values[6],'original collision or named reference changed')
 if fallbackParts[p] then assert(p.Transparency==values[7],'failed load hid original') end
end
for _,p in root.KitDressing:GetDescendants() do if p:IsA('BasePart') then assert(not p.CanCollide and not p.CanQuery,'import changed collision/drop ray') end end
local n=#root:GetDescendants();apply(root,'cave');assert(#root:GetDescendants()==n,'rerun duplicates kits')
print('PASS production swap with forced failures: preserved every original collider/reference, visible fallback, noncolliding/nonquery kit meshes, idempotence')
