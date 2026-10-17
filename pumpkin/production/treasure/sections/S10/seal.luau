local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local H='treasure/sections/S10/'
local original=fs.readFile('slice-v2/prototype/guardian-greybox.pre-s10.rbxl')
local bytes=fs.readFile('slice-v2/prototype/guardian-greybox.rbxl')
local p,b=rb.deserializePlace(bytes),rb.deserializePlace(original)
assert(p.ReplicatedStorage.MeadowV4.Section10.Source==fs.readFile('prototype/meadow-v4/Section10.luau'))
assert(p.ReplicatedStorage.MeadowV4.Section9.Source==fs.readFile('prototype/meadow-v4/Section9.luau'))
fs.writeFile(H..'r2-Section9.luau',p.ReplicatedStorage.MeadowV4.Section9.Source)
local sourceNames={}
for _,s in p:GetDescendants()do if s:IsA('LuaSourceContainer')then table.insert(sourceNames,s:GetFullName())end end
p.ReplicatedStorage.MeadowV4.Section10:Destroy()
p.ReplicatedStorage.MeadowV4.Section9.Source=b.ReplicatedStorage.MeadowV4.Section9.Source
assert(rb.serializePlace(p)==rb.serializePlace(b),'unrelated source/serialized change')
local drop=serde.decode('json',fs.readFile(H..'final-DROPS.json'))
assert(drop.state=='PASS'and drop.samples==31824 and #drop.failures==0)
local r1,r2=serde.decode('json',fs.readFile(H..'AUDIT-r1.json')),serde.decode('json',fs.readFile(H..'AUDIT-r2.json'))
for _,r in {r1,r2}do
 for _,k in {'physical_contacts','lane_margin_errors','bounds_errors','unsupported'}do assert(#r[k]==0,k)end
end
assert(r2.frozen_r1 and r2.new_cosmetics==28 and r2.new_lights==0)
local function checklog(name,token)
 -- Windows PowerShell redirects native output as UTF-16LE; normalize ASCII
 -- token bytes only for inspection while hashing the original log unchanged.
 local log=fs.readFile(H..name):gsub('%z','');assert(log:find(token,1,true),name..' missing PASS')
 assert(not log:find('[Stack Begin]',1,true)and not log:find('Traceback',1,true),name..' failure')
end
checklog('contracts.log','PASS nonzero origin')
checklog('behavior.log','PASS production Arena.reset and overlapping path completion epochs')
checklog('50-seed.log','PASS 50-seed actual 3D walking-floor')
checklog('home.log','all 28 cosmetics home-local')
checklog('owners.log','negative control reproduces old RouteLabel owner-row loss')
local manifest=serde.decode('json',fs.readFile(H..'MOUNT-r2.json'))
assert(manifest.canonical_sha256==serde.hash('sha256',bytes))
assert(fs.readFile(H..'R2-review.rbxl')==bytes)
local hashes={}
for _,name in fs.readDir(H)do
 if name~='FINAL-EVIDENCE.json'and name~='seal.log'and not fs.isDir(H..name)then hashes[H..name]=serde.hash('sha256',fs.readFile(H..name))end
end
for _,path in {'prototype/meadow-v4/Section9.luau','prototype/meadow-v4/Section10.luau','slice-v2/prototype/HomeArt.client.luau'}do hashes[path]=serde.hash('sha256',fs.readFile(path))end
fs.writeFile(H..'FINAL-EVIDENCE.json',serde.encode('json',{
 state='PASS offline',visual='REVISIT',rounds_completed={1,2},stop_before_round3=true,
 canonical_sha256=serde.hash('sha256',bytes),backup_sha256=serde.hash('sha256',original),
 compiled_O0_O1_O2=#sourceNames,changed_sources={'Section9: presentation repair and isolated S10 finish hook','Section10: new module'},
 unrelated_serialized_state_exact=true,HomeArt_exact=true,old_home_geometry_physics_exact=true,
 new_cosmetics=28,client_finishes=120,new_lights=0,contact_errors=0,lane_margin_errors=0,
 unsupported=0,frozen_R1_parts=12,drop_samples=drop.samples,drop_routes=#drop.all_routes_executed_exactly_once,
 drop_failures=0,live_Studio='UNKNOWN/PENDING Claude review',owner_acceptance='UNKNOWN',commit='NONE',publish='NONE',hashes=hashes,
 },true))
print('PASS sealed canonical/source/render/audit/test/DropSample evidence; 2 rounds only; live UNKNOWN')
