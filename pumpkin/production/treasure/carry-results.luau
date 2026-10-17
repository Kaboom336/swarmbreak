local fs,s=require('@lune/fs'),require('@lune/serde')
local function read(path)return s.decode('json',fs.readFile(path))end
local route=read('treasure/carry-route.json')
assert(s.hash('sha256',fs.readFile('slice-v2/prototype/guardian-greybox.rbxl'))==route.canonical_sha256,'canonical changed during tests')
assert(s.hash('sha256',fs.readFile('slice-v2/prototype/guardian-greybox.pre-carryfix.rbxl'))==route.backup_sha256,'backup changed')
local function log(path)
 local raw=fs.readFile(path)
 if raw:sub(1,2)=='\255\254' then raw=raw:sub(3):gsub('%z','') end
 return raw
end
assert(log('treasure/carry-contracts.log'):find('PASS nonzero origin',1,true))
assert(log('treasure/carry-behavior.log'):find('PASS actual production reset:',1,true))
assert(log('treasure/carry-50-seed.log'):find('PASS built binary sources',1,true))
for _,m in {'false','true'} do local d=read('treasure/carry-physical-'..m..'.json');assert(#d.added==0 and #d.removed==0) end
local expected={};for name in read('treasure/carry-state.json').routes do expected[name]=true end
local seen,workers,total={},{},0
for i=1,3 do
 local r=read('treasure/carry-evidence/final-DROPS-'..i..'.json')
 assert(r.worker==i and r.state=='PASS' and #r.failures==0)
 for _,name in r.shardRoutes do assert(expected[name] and not seen[name],name);seen[name]=true end
 total+=r.samples;table.insert(workers,r)
end
local routes=0;for name in expected do assert(seen[name],name);routes+=1 end
assert(total==31824 and routes==20)
local result={investigation='UNRESOLVED',cause='UNKNOWN',fix_mounted=false,canonical_unchanged=true,canonical_sha256=route.canonical_sha256,pre_carryfix_backup_byte_identical=true,compiled_O0_O1_O2=route.compiled_O0_O1_O2,physical_changes=0,contracts='PASS',behavior='PASS',fifty_seed='PASS',drop_samples=total,drop_routes=routes,drop_failures=0,drop_workers=workers,s5_unmounted=true,live_Studio='NOT RUN',commit='NONE',publish='NONE'}
fs.writeFile('treasure/carry-evidence/FINAL.json',s.encode('json',result,true))
print('PASS offline verification:',total,'DropSample cases /',routes,'routes / zero failures; live cause UNKNOWN, no fix mounted')
