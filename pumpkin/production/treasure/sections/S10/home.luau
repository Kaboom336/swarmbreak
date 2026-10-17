local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local cache={}
local function load(n)
 if cache[n]then return cache[n]end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Instance=rb.Instance,Enum=rb.Enum,UDim2=rb.UDim2,
 game={GetService=function(_,name)if name=='Workspace'then return p.Workspace end;assert(name=='ReplicatedStorage');return p.ReplicatedStorage end}}})();return cache[n]
end
local section=load(p.ReplicatedStorage.MeadowV4.Section10)
section.build(nil,rb.Vector3.new(513,77,-912));assert(not p.Workspace:FindFirstChild('HomePortalsS10'),'standalone builds home')
local world=rb.Instance.new('Folder');world.Name='GREYBOX';world.Parent=p.Workspace
for i=1,8 do local q=rb.Instance.new('Model');q.Name='HomePlot'..i;q.Parent=world end
section.build(nil,rb.Vector3.new(513,77,-912))
local group=world.HomePortalsS10;local manifest=serde.decode('json',fs.readFile('treasure/sections/S10/r2.json'))
local expected={};for _,q in manifest.parts do if q.section=='S10'then table.insert(expected,q)end end
local count=0
for _,q in group:GetDescendants()do if q:IsA('BasePart')then
 count+=1;local found
 for i,e in expected do if e.name==q.Name and (q.CFrame.Position-rb.Vector3.new(unpack(e.position))).Magnitude<.002 then found=i;break end end
 assert(found,'home origin leaked into '..q.Name);table.remove(expected,found)
 assert(not q.CanCollide and not q.CanQuery and not q.CanTouch)
end end
assert(count==28 and #expected==0)
local descendants=group:GetDescendants();section.build(nil,rb.Vector3.zero);assert(#group:GetDescendants()==#descendants,'duplicates home')
print('PASS standalone no-op; all 28 cosmetics home-local despite nonzero Meadow origin; idempotent; physics false')
