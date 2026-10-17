-- Aggregate the existing disjoint production DropSample workers and pin evidence.
local fs,serde,rb,luau=require('@lune/fs'),require('@lune/serde'),require('@lune/roblox'),require('@lune/luau')
local H='prototype/yield-evidence/'
local function readLog(name)
 local raw=fs.readFile(H..name)
 -- Windows PowerShell redirection writes UTF-16LE. Assertions below match
 -- ASCII test tokens only; keep the original bytes as the audit evidence.
 if raw:sub(1,2)=='\255\254' then return (raw:sub(3):gsub('%z','')) end
 return raw
end
if fs.isFile(H..'final-DROPS.json') then
 local raw=fs.readFile(H..'final-DROPS.json');local value=serde.decode('json',raw)
 fs.writeFile(H..'raw-DROPS-'..value.worker..'.json',raw)
end
local main='slice-v2/prototype/guardian-greybox.rbxl'
local p=rb.deserializePlace(fs.readFile(main))
local routes=luau.load(p.ReplicatedStorage.MeadowV4.RouteData.Source,{environment={}})()
local universe={};for name in routes do table.insert(universe,name)end;table.sort(universe)
local workers,seen,expected={}, {},table.concat(universe,'\n')
local total=0
for i=1,3 do
 -- Original wrapper replaced the basename before the shard filename rewrite,
 -- so workers overwrote one shared JSON. Their separate complete stdout logs
 -- remain the primary evidence. Reconstruct only fields actually printed.
 local log=readLog('drop-'..i..'.log')
 local samples,failures=log:match('PASS (%d+) samples (%d+) failures;')
 assert(samples and tonumber(failures)==0,'worker '..i..' incomplete or failed')
 for value in log:gmatch('failures (%d+)') do assert(tonumber(value)==0,'sample failure in worker '..i)end
 local shard,last={},0
 for name,count,nfail in log:gmatch('sampled ([%w_]+) (%d+) failures (%d+)') do
  assert(routes[name] and tonumber(nfail)==0,'unknown/failed route')
  local partition=0;for k=1,#name do partition+=string.byte(name,k)end
  assert(partition%3+1==i,'wrong route worker')
  local routeSamples=(#routes[name]-1)*8*3*3
  assert(tonumber(count)==last+routeSamples,'incomplete route lattice '..name)
  last=tonumber(count);table.insert(shard,name)
 end
 assert(last==tonumber(samples),'worker final count differs from routes')
 local r={worker=i,state='PASS',samples=tonumber(samples),failures={},shardRoutes=shard,allRouteNames=universe,evidence='complete separate stdout log; only printed fields recovered after shared JSON filename collision',stdout_sha256=serde.hash('sha256',fs.readFile(H..'drop-'..i..'.log'))}
 fs.writeFile(H..'final-DROPS-'..i..'.json',serde.encode('json',r,true))
 for _,name in r.shardRoutes do assert(not seen[name],'overlapping route '..name);seen[name]=true end
 total+=r.samples;table.insert(workers,r)
end
local names={};for name in seen do table.insert(names,name)end;table.sort(names)
assert(table.concat(names,'\n')==expected and #names==20,'missing route')
assert(total==31824,'incomplete lattice')
local parity=serde.decode('json',fs.readFile(H..'PARITY.json'))
assert(serde.hash('sha256',fs.readFile(main))==parity.place_sha256,'place changed after checks')
local sources={Builder='prototype/meadow-v4/MeadowV4.luau',Loader='prototype/meadow-v4/Loader.luau',Section1='prototype/meadow-v4/Section1.luau',Section2='prototype/meadow-v4/Section2.luau',Section3='prototype/meadow-v4/Section3.luau',Section4='prototype/meadow-v4/Section4.luau'}
for name,path in sources do assert(p.ReplicatedStorage.MeadowV4[name].Source==fs.readFile(path),'unmounted source '..name)end
assert(p.ServerScriptService.KitLibrary.Source==fs.readFile('prototype/kits/KitLibrary.luau'),'unmounted KitLibrary')
local contracts=readLog('contracts.log');assert(contracts:find('PASS nonzero origin',1,true),'contracts incomplete')
local seeds=readLog('50-seed.log');assert(seeds:find('PASS 50-seed actual 3D walking-floor',1,true) and seeds:find('PASS built binary sources',1,true),'50 seeds incomplete')
local behavior=readLog('behavior.log');assert(behavior:find('PASS actual production reset',1,true),'behavior incomplete')
local kit=serde.decode('json',fs.readFile(H..'KIT.json'));assert(kit.template_signature_exact,'KitLibrary contract')
fs.writeFile(H..'DROPS.json',serde.encode('json',{state='PASS',samples=total,failures={},routes_exactly_once=names,workers=workers,place_sha256=parity.place_sha256,live_Studio='UNKNOWN'},true))
fs.writeFile(H..'FINAL.json',serde.encode('json',{place_sha256=parity.place_sha256,contracts='PASS',policy_core_coordinator_reset='PASS',fifty_seed='PASS',drop_samples=total,drop_routes=#names,drop_failures=0,kit_proxy_signature_exact=true,signature_parity=parity,live_Studio='UNKNOWN',commit='NONE',publish='NONE'},true))
print('PASS final mounted-source hashes, contracts, behavior, 50 seeds, KitLibrary proxy parity;',total,'DropSample cases /',#names,'routes / zero failures; Studio UNKNOWN')
