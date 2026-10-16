-- Execute offset, late kits and failure-isolation contracts on delivered mounted source.
local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local cache,warnings={},{}
local function load(n)
 if cache[n] then return cache[n] end
 local env={script=n,require=load,warn=function(...) table.insert(warnings,{...}) end,Vector3=rb.Vector3,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,
 game={GetService=function(_,name) if name=='ReplicatedStorage' then return p.ReplicatedStorage elseif name=='RunService' then return {} end;assert(name=='HttpService');return {JSONDecode=function(_,s)return serde.decode('json',s) end} end}}
 cache[n]=luau.load(n.Source,{environment=env})();return cache[n]
end
local rs=p.ReplicatedStorage;local builder=load(rs.MeadowV4.Builder)
local a=builder.build(p.Workspace,rb.Vector3.zero)
assert(#warnings==0,'unexpected section warning')
local origin=rb.Vector3.new(513,77,-912)
local b=builder.build(p.Workspace,origin)
local function parts(m) local out={};for _,q in m:GetDescendants() do if q:IsA('BasePart') then table.insert(out,q) end end;return out end
local aa,bb=parts(a),parts(b);assert(#aa==#bb,'offset changes part count')
for i,q in aa do
 assert(q.Name==bb[i].Name,'offset identity')
 assert((q.CFrame.Position+origin-bb[i].CFrame.Position).Magnitude<.002,'offset applied wrong '..q.Name)
end
local section=load(rs.MeadowV4.Section2);local kitCount=0
section.spawnKits(b,{
 spawn=function(name,island,frame,size)
  kitCount+=1;local g=section.kits[kitCount]
  local y=assert(section.ground(b,g.x,g.z,g.size.X,g.size.Z))
  assert((frame.Position-origin-rb.Vector3.new(g.x,y,g.z)).Magnitude<.002,'late kit origin/support')
  local m=rb.Instance.new('Model');local q=rb.Instance.new('Part');q.Size=size;q.CFrame=frame*rb.CFrame.new(0,size.Y/2,0);q.Parent=m;return m
 end,
 fit=function()return true end,
})
assert(kitCount==#section.kits,'late kits incomplete')
for _,q in b:GetDescendants() do if q:IsA('BasePart') and q:GetAttribute('Section')=='S2' then assert(not q.CanCollide and not q.CanQuery and not q.CanTouch,'late kit collision/query') end end
local bad=rb.Instance.new('ModuleScript');bad.Name='Section999';bad.Source='return {build=function() error("intentional dressing fault") end}';bad.Parent=rs.MeadowV4
local c=builder.build(p.Workspace,origin)
assert(#parts(c)==#aa,'failed section aborted island')
assert(#warnings==1 and tostring(warnings[1][1]):find('Section999 dressing skipped'),'failure must warn')
local names={'GreyboxSelfTest','DropSampleTest','GreyboxLoopTest','GreyboxPvpTest','GreyboxTrapTest','CoreLoopTest','RavineTest','TunnelTest','OutsmartTest'}
for _,name in names do assert(p.ServerScriptService.StudioPass.Source:find('"'..name..'"',1,true),'missing suite '..name) end
fs.writeFile('treasure/sections/S2/CONTRACTS.json',serde.encode('json',{offset_origin_once=true,late_kits_origin_once=true,cosmetic_query_false=true,failed_section_warns_and_keeps_island=true,StudioPassAll_suite_names=names,live_results='UNKNOWN'},true))
print('PASS nonzero origin; late KitLibrary origin; cosmetics; failed section warns without abort; nine suite coordinator names')
