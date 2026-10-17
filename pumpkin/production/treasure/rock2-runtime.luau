local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local cache={}
local function load(n)
 if cache[n]then return cache[n]end
 cache[n]=luau.load(n.Source,{environment={script=n,require=load,Instance=rb.Instance,Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum}})();return cache[n]
end
local plan=load(p.ReplicatedStorage.MeadowV4.Rock2Plan);local mod=load(p.ReplicatedStorage.MeadowV4.ZRock2)
local before=serde.decode('json',fs.readFile('treasure/rock2/before.json')).parts
local function fixture(skip)
 local root=rb.Instance.new('Model')
 for i,g in plan do
  if i==skip then continue end
  local source=before[g.index+1];local q=rb.Instance.new('Part');q.Name=g.name;q.Size=rb.Vector3.new(unpack(g.size));q.CFrame=rb.CFrame.new(unpack(g.position))*rb.CFrame.new(0,0,0,unpack(g.rotation))
  q.Anchored=true;q.CanCollide=source.collidable;q.CanQuery=source.query;q.CanTouch=source.touch;q.CollisionGroup=source.collisionGroup
  for k,v in source.attributes do q:SetAttribute(k,v)end
  for _,tag in source.tags do q:AddTag(tag)end
  q.Parent=root
 end
 return root
end
local root=fixture();mod.build(root);local group=assert(root:FindFirstChild('MeadowRock2'));assert(group:GetAttribute('Complete'))
local n=0;for _,g in plan do n+=#g.pieces end
assert(#group:GetChildren()==n)
for _,q in group:GetChildren()do assert(not q.CanCollide and not q.CanQuery and not q.CanTouch)end
mod.build(root);assert(#group:GetChildren()==n and root:FindFirstChild('MeadowRock2')==group,'idempotence')
local bad=fixture(#plan);local originalCount=#bad:GetChildren();local ok=pcall(mod.build,bad)
assert(not ok and not bad:FindFirstChild('MeadowRock2')and #bad:GetChildren()==originalCount,'failed build mutated original world')
local final=plan[#plan];local q=fixture():GetChildren()[#plan]:Clone();q.Parent=bad
mod.build(bad);assert(bad:FindFirstChild('MeadowRock2'),'cannot retry')
print('PASS actual mounted Rock2: flags, complete publication, idempotence, missing-last-target cleanup, retry;',n,'parts')
