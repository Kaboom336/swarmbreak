local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local home=serde.decode('json',fs.readFile('treasure/sections/S9/r2.json'))
local world=rb.Instance.new('Folder');world.Name='GREYBOX';world.Parent=p.Workspace
for i=1,8 do local plot=rb.Instance.new('Model');plot.Name='HomePlot'..i;plot.Parent=world end
local cache={}
local function load(n)
 if cache[n]then return cache[n]end
 local env={script=n,require=load,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Instance=rb.Instance,Enum=rb.Enum,UDim2=rb.UDim2,game={GetService=function(_,name)if name=='Workspace'then return p.Workspace end;assert(name=='ReplicatedStorage');return p.ReplicatedStorage end}}
 cache[n]=luau.load(n.Source,{environment=env})();return cache[n]
end
local section=load(p.ReplicatedStorage.MeadowV4.Section9)
section.build(nil,rb.Vector3.new(513,77,-912))
local group=assert(world:FindFirstChild('HomeYardsS9'))
local expected={};for _,q in home.parts do if q.section=='S9' then table.insert(expected,q)end end
local count=0
for _,q in group:GetDescendants()do if q:IsA('BasePart')then
 count+=1;local found
 for i,e in expected do if e.name==q.Name and (q.CFrame.Position-rb.Vector3.new(unpack(e.position))).Magnitude<.002 then found=i;break end end
 assert(found,'Meadow offset leaked into home: '..q.Name);table.remove(expected,found)
 assert(not q.CanCollide and not q.CanQuery and not q.CanTouch)
end end
assert(count==220 and #expected==0)
-- Runtime UI uses Enum.Font; Lune cannot serialize that FontFace proxy. Compare
-- the actual node identities/count instead of serializing the exercised mock.
local before=world:GetDescendants();section.build(nil,rb.Vector3.zero);local after=world:GetDescendants();assert(#after==#before,'home build duplicated parts')
local identities={};for _,q in before do identities[q]=true end;for _,q in after do assert(identities[q],'home build replaced a node')end
world:Destroy();section.build(nil,rb.Vector3.zero);assert(not p.Workspace:FindFirstChild('HomeYardsS9'),'standalone Meadow creates home')
print('PASS 220 home cosmetics stay in home coordinates despite nonzero Meadow origin; idempotence; standalone no-op; physics false')
