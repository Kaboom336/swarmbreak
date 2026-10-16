local fs,rb,luau,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/luau'),require('@lune/serde')
local p=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))
local old=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-s2r4.rbxl'))
local compiled,preserved=0,0
for _,n in p:GetDescendants() do if n:IsA('LuaSourceContainer') then
 for opt=0,2 do luau.compile(n.Source,{optimizationLevel=opt}) end;compiled+=1
 if n:GetFullName()~='ReplicatedStorage.MeadowV4.Section2' and n:GetFullName()~='ReplicatedStorage.MeadowV4.Outsmart' then
  local q=old;for _,name in string.split(n:GetFullName(),'.') do q=assert(q:FindFirstChild(name)) end
  assert(q.Source==n.Source,n:GetFullName());preserved+=1
 end
end end
assert(rb.serializeModel({old.Workspace})==rb.serializeModel({p.Workspace}))
local signatures=serde.decode('json',fs.readFile('treasure/sections/S2/CLOSE-SIGNATURES.json'))
assert(signatures.protected_physical_query_touch_floor_lane_tags_exact)
assert(compiled==72 and preserved==70)
fs.writeFile('treasure/sections/S2/close-AUDIT.json',serde.encode('json',{compiled_O0_O1_O2=compiled,unrelated_sources_preserved=preserved,workspace_equal=true,physics_floor_tags_equal=true,StudioPassAll='UNKNOWN; nine live suites not run'},true))
print('PASS 72 sources O0/O1/O2; 70 preserved; Workspace exact')
