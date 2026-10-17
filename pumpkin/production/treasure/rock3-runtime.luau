local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local cache={}
local function load(n)
 if cache[n]then return cache[n]end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,Instance=rb.Instance,Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum}})();return cache[n]
end
local plan=load(p.ReplicatedStorage.MeadowV4.Rock3Plan);local mod=load(p.ReplicatedStorage.MeadowV4.ZRock3)
local before=serde.decode('json',fs.readFile('treasure/rock3/before.json')).parts
local function part(g)
 local source=before[g.index+1];local q=rb.Instance.new('Part');q.Name=g.name;q.Size=rb.Vector3.new(unpack(g.size));q.CFrame=rb.CFrame.new(unpack(g.position))*rb.CFrame.new(0,0,0,unpack(g.rotation))
 q.Anchored=true;q.CanCollide=source.collidable;q.CanQuery=source.query;q.CanTouch=source.touch;q.CollisionGroup=source.collisionGroup
 for k,v in source.attributes do q:SetAttribute(k,v)end
 for _,tag in source.tags do q:AddTag(tag)end
 return q
end
local function fixture(skip)
 local root=rb.Instance.new('Model')
 for i,g in plan do if i~=skip then part(g).Parent=root end end
 return root
end
local root=fixture();mod.build(root);local group=assert(root:FindFirstChild('MeadowRock3'));assert(group:GetAttribute('Complete'))
local n=0;for _,g in plan do n+=#g.pieces end
assert(#group:GetChildren()==n)
local colliders=0;for _,q in group:GetChildren()do if q.CanCollide then colliders+=1 end end
assert(colliders>0,'no collision facets mounted')
mod.build(root);assert(#group:GetChildren()==n and root:FindFirstChild('MeadowRock3')==group,'idempotence')
local bad=fixture(#plan);local originalCount=#bad:GetChildren();local ok=pcall(mod.build,bad)
assert(not ok and not bad:FindFirstChild('MeadowRock3')and #bad:GetChildren()==originalCount,'failed build mutated original world')
part(plan[#plan]).Parent=bad;mod.build(bad);assert(bad:FindFirstChild('MeadowRock3'),'cannot retry')
local rotated=fixture();rotated:GetChildren()[1].CFrame*=rb.CFrame.Angles(0,.01,0)
assert(not pcall(mod.build,rotated)and not rotated:FindFirstChild('MeadowRock3'),'rotation drift accepted')
print('PASS actual mounted Rock3: collision facets, complete publication, idempotence, cleanup/retry, rotation drift;',n,'parts;',colliders,'colliders')
