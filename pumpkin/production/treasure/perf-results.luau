local fs,serde=require('@lune/fs'),require('@lune/serde')
local function read(path) return serde.decode('json',fs.readFile(path)) end
local function log(path)
 local raw=fs.readFile(path)
 if raw:sub(1,2)=='\255\254' then raw=raw:sub(3):gsub('%z','') end
 return raw
end
local build=read('treasure/PERF-BUILD.json')
assert(serde.hash('sha256',fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))==build.canonical_sha256)
assert(serde.hash('sha256',fs.readFile('slice-v2/prototype/guardian-greybox.pre-perf.rbxl'))==build.backup_sha256)
assert(log('treasure/perf-contracts.log'):find('PASS nonzero origin',1,true))
assert(log('treasure/perf-behavior.log'):find('PASS actual production reset:',1,true))
assert(log('treasure/perf-50-seed.log'):find('PASS built binary sources',1,true))
assert(log('treasure/perf-conservation.log'):find('12 old/new equivalence cases',1,true))
local expected={};for name in read('treasure/carry-state.json').routes do expected[name]=true end
local seen,total,workers={},0,{}
fs.writeDir('treasure/perf-evidence')
for i=1,3 do
 local path='treasure/carry-evidence/final-DROPS-'..i..'.json'
 local r=read(path)
 assert(log('treasure/perf-drop-'..i..'.log'):find('0 failures; dropped kit placements',1,true),'worker log incomplete '..i)
 assert(r.worker==i and r.state=='PASS' and #r.failures==0)
 for _,name in r.shardRoutes do assert(expected[name] and not seen[name],name);seen[name]=true end
 total+=r.samples;table.insert(workers,r)
 fs.writeFile('treasure/perf-evidence/DROPS-'..i..'.json',fs.readFile(path))
end
local routes=0;for name in expected do assert(seen[name],name);routes+=1 end
assert(total==31824 and routes==20)
fs.writeFile('treasure/perf-evidence/FINAL.json',serde.encode('json',{
 build=build,contracts='PASS',behavior='PASS',fifty_seed='PASS (legacy numeric fixture)',
 drop_samples=total,drop_routes=routes,drop_failures=0,drop_workers=workers,
 live_heartbeat='UNKNOWN; not rerun',conservation='12 old/new cases PASS; native Clone; CollectionService shim'
},true))
print('PASS perf verification:',total,'DropSample cases /',routes,'routes / zero failures; mounted/backup hashes stable')
