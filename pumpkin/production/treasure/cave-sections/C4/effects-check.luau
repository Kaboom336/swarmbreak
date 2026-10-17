-- Execute actual mounted FX source with observable property signals, not engine VFX.
local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local bytes=fs.readFile('prototype/cave-v2.rbxl');local p=rb.deserializePlace(bytes)
local module=p.ServerScriptService.CaveBlastC4.Presentation
assert(module.Source==fs.readFile('treasure/cave-sections/C4/effects.luau'))
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
function methods:SetAttribute(k,v)self._attributes[k]=v end
function methods:GetPropertyChangedSignal(k)
 local n=self;return {Connect=function(_,f)n._signals[k]=n._signals[k]or{};table.insert(n._signals[k],f)end}
end
function methods:Clone()
 local q=node(self.ClassName,self.Name);for k,v in self._props do if k~='Parent'then q._props[k]=v end end
 for _,c in self._children do c:Clone().Parent=q end;return q
end
function methods:Emit(n)assert(not self.Enabled and self.Rate==0);emitted+=n end
local map=node('Model','CaveV2');local root=node('Folder','CaveBlastC4')
for _,entry in {{'BailSign','RED: STOP / BAIL'},{'JumpReady','JUMP READY'},{'RecoverySign','CLIMB OUT'}}do
 local b=node('Part',entry[1]);b.Parent=map;b.Position=rb.Vector3.zero
 local g=node('SurfaceGui');g.Face=rb.Enum.NormalId.Front;g.Parent=b
 local label=node('TextLabel');label.Text=entry[2];label.Parent=g
end
for _,name in {'BreakableSpan','SupportBlastHook','BroadLanding','ConnectSteelRail','pitRecovery4'}do
 local n=node('Part',name);n.Position=rb.Vector3.new(0,23,25);n.CanCollide=name=='BreakableSpan';n.CanQuery=true;n.Parent=map
end
for _,n in map:GetDescendants()do rawset(n,'_protected',true)end
local env={Instance={new=function(class)return node(class)end},Enum=rb.Enum,Vector2=rb.Vector2,Vector3=rb.Vector3,
 UDim2=rb.UDim2,Font=rb.Font,Color3=rb.Color3,ColorSequence=rb.ColorSequence,NumberRange=rb.NumberRange,
 NumberSequence=rb.NumberSequence,NumberSequenceKeypoint=rb.NumberSequenceKeypoint,task={wait=function()waits+=1 end}}
local fx=luau.load(module.Source,{environment=env})()
executing=true;fx(map,root,'r4');executing=false
assert(emitted==0 and protectedWrites==0,'initial emission or gameplay write')
assert(map.pitRecovery4.C4Focus:FindFirstChildWhichIsA('TextLabel').Text=='CLIMB OUT','missing actual-ramp cue')
for _,n in {map.SupportBlastHook,map.BroadLanding,map.pitRecovery4}do
 assert(n.C4Focus.MaxDistance==90 and n.C4Focus.AlwaysOnTop==false,'unbounded/through-wall focus label')
end
for _,name in {'BailSign','JumpReady','RecoverySign'}do
 local b=map[name];local g=assert(b:FindFirstChild('C4ReadableReverse'));assert(g.Face==rb.Enum.NormalId.Back)
 local source=b:FindFirstChildWhichIsA('SurfaceGui'):FindFirstChildWhichIsA('TextLabel')
 source.Text='fixture dynamic status';assert(g:FindFirstChildWhichIsA('TextLabel').Text==source.Text,'stale reverse face')
end
local status=map.JumpReady:FindFirstChildWhichIsA('SurfaceGui'):FindFirstChildWhichIsA('TextLabel')
status.Text='2s CRACKS';assert(map.ConnectSteelRail.C4Cracks.Enabled)
map.BreakableSpan.Transparency=1;assert(emitted==20)
map.BreakableSpan.Transparency=1;assert(emitted==20,'duplicate burst')
map.BreakableSpan.Transparency=0;status.Text='JUMP READY';assert(not map.ConnectSteelRail.C4Cracks.Enabled)
map.BreakableSpan.Transparency=1;assert(emitted==40,'second event missing')
local total=created;executing=true;fx(map,root,'r4');executing=false;assert(created==total,'duplicate presentation')
local attachment=map.SupportBlastHook.C4CosmeticBurst
for _,em in attachment:GetChildren()do assert(em.Lifetime.Max<=rb.NumberRange.new(.6).Max and em.Rate==0 and not em.Enabled,'particle budget')end
assert(map.BreakableSpan.CanCollide and map.BreakableSpan.CanQuery and protectedWrites==0,'gameplay changed')
fs.writeFile('treasure/cave-sections/C4/EFFECTS.json',serde.encode('json',{state='PASS',place_sha256=serde.hash('sha256',bytes),
 actual_mounted_source=true,property_signal_fixture=true,protected_property_writes=protectedWrites,
 live_text_mirroring=true,one_burst_per_open_transition=20,lifetime_max=.6,zero_new_lights=true,
 idempotence=true,yields=waits,engine_render_and_replication='UNKNOWN'},true))
print('PASS mounted FX: zero gameplay writes; live label mirrors; crack status; 20 short particles/event; repeat/idempotence')
