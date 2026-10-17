-- Execute actual mounted FX source with observable property signals, not engine VFX.
local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local bytes=fs.readFile('prototype/cave-v2.rbxl');local p=rb.deserializePlace(bytes)
local module=p.ServerScriptService.CaveTunnelC5.Presentation
assert(module.Source==fs.readFile('treasure/cave-sections/C5/effects.luau'))
local methods,meta={},{};local created,emitted,waits,protectedWrites=0,0,0,0;local executing=false
meta.__index=function(n,k)
 if methods[k]then return methods[k]end
 if n._props[k]~=nil then return n._props[k]end
 for _,c in n._children do if c.Name==k then return c end end
end
meta.__newindex=function(n,k,v)
 if executing and n._protected then protectedWrites+=1 end
 n._props[k]=v
 if k=='Parent'and v then table.insert(v._children,n)end
 for _,f in n._signals[k]or{}do f()end
end
local function node(class,name)
 created+=1;return setmetatable({_props={ClassName=class,Name=name or class,Transparency=0},_children={},_signals={},_attributes={}},meta)
end
function methods:IsA(c)return self.ClassName==c or c=='BasePart'and self.ClassName=='Part'end
function methods:GetChildren()return table.clone(self._children)end
function methods:GetDescendants()local a={};local function scan(n)for _,c in n._children do table.insert(a,c);scan(c)end end;scan(self);return a end
function methods:FindFirstChild(name)for _,c in self._children do if c.Name==name then return c end end end
function methods:WaitForChild(name)return assert(self:FindFirstChild(name),name)end
function methods:FindFirstChildWhichIsA(class)for _,c in self._children do if c:IsA(class)then return c end end end
function methods:GetAttribute(k)return self._attributes[k]end
function methods:SetAttribute(k,v)if executing and self._protected then protectedWrites+=1 end;self._attributes[k]=v end
function methods:GetAttributeChangedSignal(k)return self:GetPropertyChangedSignal('attribute:'..k)end
function methods:GetPropertyChangedSignal(k)
 local n=self;return {Connect=function(_,f)n._signals[k]=n._signals[k]or{};table.insert(n._signals[k],f)end}
end
function methods:Clone()
 local q=node(self.ClassName,self.Name);for k,v in self._props do if k~='Parent'then q._props[k]=v end end
 for _,c in self._children do c:Clone().Parent=q end;return q
end
function methods:Emit(n)assert(not self.Enabled and self.Rate==0);emitted+=n end
local map=node('Model','CaveV2');local root=node('Folder','CaveTunnelC5')
local hook=node('Part','ShatterCavernHook');hook.Parent=map;hook.CanCollide=false;hook.CanQuery=true;rawset(hook,'_protected',true)
for i=1,3 do local q=node('Part','C5_Crystal3Shaft'..i);q.Color=rb.Color3.fromRGB(129,76,202);q.Parent=root end
local env={Instance={new=function(class)return node(class)end},Enum=rb.Enum,Vector2=rb.Vector2,Vector3=rb.Vector3,Color3=rb.Color3,ColorSequence=rb.ColorSequence,NumberRange=rb.NumberRange,NumberSequence=rb.NumberSequence,NumberSequenceKeypoint=rb.NumberSequenceKeypoint,task={wait=function()waits+=1 end}}
local apply=luau.load(module.Source,{environment=env})()
executing=true;apply(map,root,'r4');executing=false
assert(emitted==0 and protectedWrites==0,'initial emission or protected write')
local function signal(k,v)
 hook._attributes[k]=v;executing=true
 for _,f in hook._signals['attribute:'..k]or{}do f()end
 executing=false
end
for i=1,3 do
 local q=root['C5_Crystal3Shaft'..i];local base=q.Color
 signal('Cluster'..i..'Cracking',true);assert(q.Color==rb.Color3.fromRGB(225,221,255),'crack missing')
 signal('Cluster'..i..'Cracking',false);assert(q.Color==base,'crack tint retained')
 local before=emitted
 signal('Cluster'..i..'Burst',true);assert(emitted==before+12,'burst missing')
 signal('Cluster'..i..'Burst',true);assert(emitted==before+12,'duplicate burst')
 signal('Cluster'..i..'Burst',false);signal('Cluster'..i..'Burst',true);assert(emitted==before+24,'repeat missing')
 local em=q.C5Shards;assert(em.Lifetime.Max<=.451 and em.Rate==0 and not em.Enabled,'particle budget')
end
local n=created;executing=true;apply(map,root,'r4');executing=false;assert(n==created,'duplicate effect mounts')
assert(protectedWrites==0 and hook.CanQuery,'gameplay changed')
fs.writeFile('treasure/cave-sections/C5/EFFECTS.json',serde.encode('json',{state='PASS',place_sha256=serde.hash('sha256',bytes),actual_mounted_source=true,attribute_signal_fixture=true,protected_writes=protectedWrites,particles_per_burst=12,lifetime_max=.45,idempotence=true,yields=waits,engine_render_replication='UNKNOWN'},true))
print('PASS mounted C5 effects: read-only preview signals, crack/reset, bounded bursts, repeat/idempotence')
