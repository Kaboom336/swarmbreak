local fs,serde,rb=require('@lune/fs'),require('@lune/serde'),require('@lune/roblox')
local function read(path) return serde.decode('json',fs.readFile(path)) end
local function log(path)
 local s=fs.readFile(path)
 if s:sub(1,2)=='\255\254' then s=s:sub(3):gsub('%z','') end
 return s
end
local build=read('treasure/PVPFLAKE-BUILD.json')
local main='slice-v2/prototype/guardian-greybox.rbxl'
assert(serde.hash('sha256',fs.readFile(main))==build.canonical_sha256)
assert(serde.hash('sha256',fs.readFile('slice-v2/prototype/guardian-greybox.pre-pvpflake.rbxl'))==build.backup_sha256)
local old=rb.deserializePlace(fs.readFile('slice-v2/prototype/guardian-greybox.pre-pvpflake.rbxl'))
local current=rb.deserializePlace(fs.readFile(main))
current.ServerScriptService.Greybox.Source=old.ServerScriptService.Greybox.Source
current.ServerScriptService.GreyboxArena.Source=old.ServerScriptService.GreyboxArena.Source
assert(rb.serializePlace(current)==rb.serializePlace(old),'unrelated serialized state changed since backup')
for _,pair in {
 {'before','PASS negative control'}, {'behavior','PASS production Arena.reset and overlapping path completion epochs'},
 {'contracts','PASS nonzero origin'}, {'50-seed','PASS built binary sources'},
} do assert(log('treasure/pvpflake-'..pair[1]..'.log'):find(pair[2],1,true),pair[1]) end
local expected,seen,workers,total={},{},{},0
for i=1,3 do
 assert(log('treasure/pvpflake-drop-'..i..'.log'):find('0 failures; dropped kit placements',1,true),'unfinished worker '..i)
 local path='treasure/sections/S5/final-DROPS-'..i..'.json'
 local r=read(path)
 assert(r.worker==i and r.state=='PASS' and #r.failures==0)
 assert(r.input_sha256==build.canonical_sha256,'DropSample report mount hash')
 for _,name in r.allRouteNames do expected[name]=true end
 for _,name in r.shardRoutes do assert(not seen[name],'duplicate route '..name);seen[name]=true end
 workers[i]=r;total+=r.samples
 fs.writeFile('treasure/pvpflake-evidence/DROPS-'..i..'.json',fs.readFile(path))
end
local routes=0
for name in expected do assert(seen[name],'missing route '..name);routes+=1 end
assert(total==31824 and routes==20,'full N8 lattice coverage')
-- The reused S5 runner writes historical paths. Preserve this task's reports,
-- then put the prior section evidence back byte-for-byte.
for i=1,3 do
 fs.writeFile('treasure/sections/S5/final-DROPS-'..i..'.json',fs.readFile('treasure/pvpflake-evidence/prior-S5-DROPS-'..i..'.json'))
end
fs.writeFile('treasure/pvpflake-evidence/FINAL.json',serde.encode('json',{
 build=build,geometry=read('treasure/PVPFLAKE-GEOMETRY.json'),
 archived_reset_negative_control='PASS',dirty_reset_and_async_contracts='PASS',contracts='PASS',
 fifty_seed='PASS (legacy numeric fixtures; mocked navigation)',
 drop_samples=total,drop_routes=routes,drop_failures=0,drop_workers=workers,
 independent_review='No remaining concrete defect found after path invalidation fix',
 live_Loop_then_PvP='UNKNOWN; Claude must rerun',live_cause_attribution='INFERRED from verified reset leakage'
},true))
print('PASS backup/mount parity; contracts; 50 seeds;',total,'N8 drops /',routes,'routes / zero failures; live UNKNOWN')
