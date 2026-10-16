local fs,rb,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local base='slice-v2/prototype/guardian-greybox'
assert(fs.readFile(base..'.pre-s4r3-lightmount.rbxl')==fs.readFile(base..'.pre-claude-s3light.rbxl'),'initial canonical differs from owner-restored R2')
local pre=rb.deserializePlace(fs.readFile(base..'.pre-s4r3-lightmount.rbxl'))
local start=rb.deserializePlace(fs.readFile(base..'.pre-s4r3.rbxl'))
local current=rb.deserializePlace(fs.readFile(base..'.rbxl'))
local dropInput=rb.deserializePlace(fs.readFile('treasure/sections/S4/R4-drop-input.rbxl'))
assert(fs.readFile(base..'.rbxl')==fs.readFile('treasure/sections/S4/R4-drop-input.rbxl'),'DropSample input must be byte-identical final place')
local function exactExcept(a,b,names)
 local neutral=rb.deserializePlace(rb.serializePlace(b));local changed={}
 for _,name in names do
  if a.ReplicatedStorage.MeadowV4[name].Source~=b.ReplicatedStorage.MeadowV4[name].Source then table.insert(changed,name) end
  neutral.ReplicatedStorage.MeadowV4[name].Source=a.ReplicatedStorage.MeadowV4[name].Source
 end
 assert(rb.serializePlace(a)==rb.serializePlace(neutral),'unrelated serialized state changed')
 return changed
end
local changed=exactExcept(pre,start,{'Section2','Section3'})
assert(#changed==2,'expected exactly S2 and S3 light sources')
for _,name in {'Section2','Section3','Section4'} do
 assert(current.ReplicatedStorage.MeadowV4[name].Source==fs.readFile('prototype/meadow-v4/'..name..'.luau'),'mounted source '..name)
end
assert(#exactExcept(start,current,{'Section4'})==1)
assert(#exactExcept(dropInput,current,{'Section4'})==0)
local count=0
for _,p in current:GetDescendants() do if p:IsA('LuaSourceContainer') then for opt=0,2 do luau.compile(p.Source,{optimizationLevel=opt}) end;count+=1 end end
fs.writeFile('treasure/sections/S4/MOUNT-R3.json',serde.encode('json',{changed_sources=changed,complete_place_exact_except_two_source_properties=true,workspace_exact=true,backup=base..'.pre-s4r3.rbxl'},true))
fs.writeFile('treasure/sections/S4/MOUNT-FINAL.json',serde.encode('json',{round3_to_final_only_source_changed='Section4',complete_place_exact_except_Section4_Source=true,DropSample_input_byte_identical_final_place=true,compiled_sources_O0_O1_O2=count,live_Studio='UNKNOWN'},true))
print('PASS exact full-place source-only parity: S2/S3 initial mount, Section4 final; all sources compiled O0/O1/O2')
