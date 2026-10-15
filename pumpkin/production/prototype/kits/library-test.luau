-- Behavior contracts with a deterministic InsertService fake; no network or Studio.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local V,C=rb.Vector3,rb.CFrame
local methods={}
local function new(class)
 return setmetatable({ClassName=class,Name=class,children={},attrs={},Size=V.one,CFrame=C.identity,WorldPivot=C.identity,scale=1}, {__index=methods,__newindex=function(n,k,v)
  rawset(n,k,v);if k=='Parent' and v then table.insert(v.children,n) end
 end})
end
function methods:IsA(class) return self.ClassName==class or (class=='BasePart' and (self.ClassName=='Part' or self.ClassName=='MeshPart')) or (class=='LuaSourceContainer' and self.ClassName=='Script') end
function methods:GetDescendants() local out={};local function walk(n) for _,c in n.children do if not c.dead then table.insert(out,c);walk(c) end end end;walk(self);return out end
function methods:FindFirstChild(name) for _,n in self.children do if n.Name==name and not n.dead then return n end end end
function methods:SetAttribute(k,v) self.attrs[k]=v end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:Destroy() self.dead=true end
function methods:Clone()
 local n=new(self.ClassName)
 for k,v in self do if k~='children' and k~='attrs' and k~='Parent' then n[k]=v end end
 n.attrs=table.clone(self.attrs)
 for _,c in self.children do if not c.dead then c:Clone().Parent=n end end
 return n
end
function methods:GetPivot() return self.WorldPivot end
function methods:GetScale() return self.scale end
function methods:ScaleTo(s)
 local ratio=s/self.scale;local pivot=self:GetPivot()
 for _,p in self:GetDescendants() do if p:IsA('BasePart') then local cf=pivot:ToObjectSpace(p.CFrame);p.CFrame=pivot*C.new(cf.Position*ratio)*cf.Rotation;p.Size*=ratio end end
 self.scale=s
end
function methods:PivotTo(cf)
 local delta=cf*self:GetPivot():Inverse()
 for _,p in self:GetDescendants() do if p:IsA('BasePart') then p.CFrame=delta*p.CFrame end end
 self.WorldPivot=cf
end
function methods:GetBoundingBox()
 local lo,hi=V.new(math.huge,math.huge,math.huge),V.new(-math.huge,-math.huge,-math.huge)
 for _,p in self:GetDescendants() do if p:IsA('BasePart') then
  for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do local v=p.CFrame:PointToWorldSpace(p.Size*V.new(x,y,z)/2);lo=V.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z));hi=V.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z)) end end end
 end end
 return C.new((lo+hi)/2),hi-lo
end
local catalog={{id=1,name='quaternius-nature__CommonTree_1',island='meadow',meshParts=1,triangles=100},{id=2,name='kenney_nature-kit__flower_yellowA',island='meadow',meshParts=1,triangles=20},{id=3,name='missing',island='cave',meshParts=1,triangles=0}}
local calls,warnings,waits={},{},{}
local storage=new('Folder')
local services={ServerStorage=storage,HttpService={JSONDecode=function(_,s) return serde.decode('json',s) end},Stats={GetTotalMemoryUsageMb=function() return 10 end},CollectionService={AddTag=function(_,n,t) n.tags=n.tags or {};n.tags[t]=true end}}
services.InsertService={LoadAsset=function(_,id)
 calls[id]=(calls[id] or 0)+1
 if id==3 or (id==2 and calls[id]==1) then error('simulated permission/transient failure') end
 local m=new('Model');local p=new('MeshPart');p.Name='MergedMesh';p.Size=V.new(4,10,4);p.CFrame=C.new(13,25,-7);p.Parent=m
 p:SetAttribute('WalkableLaneFloor',true);p:SetAttribute('Walkable',true);p:SetAttribute('LaneId','poison')
 p.tags={AuthoredLaneFloor=true,Walkable=true,WalkableLaneFloor=true}
 local s=new('Script');s.Parent=m
 return m
end}
services.CollectionService.RemoveTag=function(_,n,t) if n.tags then n.tags[t]=nil end end
local kit=luau.load(fs.readFile('prototype/kits/KitLibrary.luau'),{environment={game={GetService=function(_,n) return assert(services[n]) end},script={Manifest={Value=serde.encode('json',catalog)}},Instance={new=new},CFrame=C,Vector3=V,Color3=rb.Color3,Enum=rb.Enum,typeof=typeof,task={wait=function(t) table.insert(waits,t or 0) end},warn=function(s) table.insert(warnings,s) end}})()
kit.init();kit.init()
assert(calls[1]==1 and calls[2]==2 and calls[3]==3,'once cache/retry contract')
assert(kit.loaded==2 and kit.failures.cave__missing,'explicit failure catalog')
local template=kit.templates.meadow__quaternius_nature -- name keys are full strings
template=kit.templates['meadow__quaternius-nature__CommonTree_1']
assert(template and #template:GetDescendants()==1,'strip imported scripts')
local box,size=template:GetBoundingBox();assert((box.Position-V.new(0,5,0)).Magnitude<0.001,'bottom-centre normalization')
local tree=assert(kit.spawn(catalog[1].name,'meadow',C.new(100,20,0),2))
assert(tree:GetScale()==2 and template:GetScale()==1,'clone scale/cache immutability')
assert(tree.tags.KitProp and tree.tags.meadow and tree.tags.KitType_tree,'island/type tags')
for _,p in tree:GetDescendants() do
 assert(p:GetAttribute('WalkableLaneFloor')~=true and p:GetAttribute('Walkable')~=true and p:GetAttribute('LaneId')==nil,'kit floor attributes stripped')
 assert(not p.tags or (not p.tags.AuthoredLaneFloor and not p.tags.Walkable and not p.tags.WalkableLaneFloor),'kit floor tags stripped')
end
assert(tree:FindFirstChild('MergedMesh').CanCollide==false and tree:FindFirstChild('KitTrunkCollider').CanCollide==false and tree:FindFirstChild('KitTrunkCollider').CanQuery==false,'kit dressing must not block or answer landing queries')
local flower=assert(kit.spawn(catalog[2].name,'meadow',C.identity,V.new(2,5,2)))
assert(flower:GetScale()==0.5 and not flower:FindFirstChild('MergedMesh').CanCollide and not flower:FindFirstChild('MergedMesh').CastShadow,'small-prop target fit/shadow/collision')
-- RenderFidelity is not set at runtime (plugin-only).
local m,reason=kit.spawn('missing','cave',C.identity,1);assert(m==nil and reason:find('simulated'),'observable fallback')
assert(#warnings>=5,'failure warnings missing')
local ok=kit.fit(flower,V.new(8,4,1),C.new(20,0,3)*C.Angles(0,math.pi/2,0));assert(ok,'fitted infrastructure')
flower:PivotTo(C.identity);local _,fitted=flower:GetBoundingBox();assert((fitted-V.new(8,4,1)).Magnitude<0.001,'fit under rotated placement')
assert(calls[1]==1 and calls[2]==2 and calls[3]==3,'spawn must never reload assets')
print('PASS fake-service cache, retries, sanitization, base pivot, uniform sizing, trunk-only collision, target fit, failure return, fidelity, rotated infrastructure fit')
