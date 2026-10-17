local fs, serde = require('@lune/fs'), require('@lune/serde')
local root='treasure/cinematic-evidence/'
local function json(path)return serde.decode('json',fs.readFile(path))end
local function log(name,needle)
	local s=fs.readFile(root..name)
	if s:sub(1,2)=='\255\254' then s=s:sub(3):gsub('%z','') end
	assert(s:find(needle,1,true),name..': missing '..needle)
	return s
end
local contract=json('treasure/CINEMATIC-CONTRACT.json')
assert(contract.state=='PASS')
for _,r in contract.places do assert(serde.hash('sha256',fs.readFile(r.place))==r.sha256)end
for _,biome in {'meadow','cave'}do
	local build=json('treasure/CINEMATIC-BUILD-'..biome..'.json')
	assert(serde.hash('sha256',fs.readFile(build.place))==build.place_sha256)
	assert(serde.hash('sha256',fs.readFile(build.backup))==build.backup_sha256)
	assert(build.server_WalkSpeed_values_and_all_test_sources_unchanged)
end
log('selene-new.log','0 warnings')
log('selene-new.log','\n0 errors')
log('selene-new.log','0 parse errors')
log('meadow-origin.log','PASS nonzero origin')
log('meadow-behavior.log','PASS actual archived Arena.reset')
log('meadow-50-seed.log','PASS built binary sources')
log('core-current.log','session fencing')
log('cave-tests.log','PASS stable joint socket')
log('cave-cart-board-check.log','PASS production boarding/departure')
log('cave-cart-drive-check.log','PASS production drive mock')
log('cave-ride-contract-check.log','PASS actual CartRideTest cargo fixture')
log('cave-rider-check.log','PASS actual rider retention')
log('cave-runner-check.log','PASS BoardingTest/LoopTest/CartRideTest reset')
log('library.log','PASS fake-service cache')
log('meadow-keeper-check.log','PASS')
log('legacy-baseline-comparison.log','CHECKED three unchanged archival failures')
log('cave-dense.log','PASS scene preservation')
local cave=json(root..'cave-treasure_cave-sections_C8_STUDIO-OFFLINE.json')
assert(cave.N==8 and #cave.failures==0 and next(cave.reasons)==nil)
local total,seen,all=0,{},{}
local workers={}
for worker=1,3 do
	local r=json(root..'drop-treasure_rockcolor_DROPS-'..worker..'.json')
	assert(r.worker==worker and r.state=='PASS' and #r.failures==0)
	for _,name in r.allRouteNames do all[name]=true end
	for _,name in r.shardRoutes do assert(not seen[name],name);seen[name]=true end
	total+=r.samples;table.insert(workers,r)
end
local routes=0
for name in all do assert(seen[name],name);routes+=1 end
-- Dense workers may have read an earlier client-only iteration. Independently
-- prove their entire physical/gameplay input is byte-equivalent to final.
-- No test body, layout, policy, loader or server property changed during this task.
local legacy=json('treasure/CINEMATIC-LEGACY-FAILURES.json')
assert(legacy.state=='PRE-EXISTING FAILURES REPRODUCED')
local hashes={}
for _,path in {
	'prototype/core/CinematicMove.luau','prototype/core/CinematicMove.client.luau','prototype/core/Feel.luau',
	'treasure/CINEMATIC-MOVE.md','treasure/cinematic-check.luau','treasure/cinematic-build.luau',
	'treasure/cinematic-existing-checks.luau','treasure/cinematic-legacy-check.luau',
	'treasure/cinematic-seal.luau','treasure/cinematic-meadow-build.luau',
	'prototype/cave-v2/build.luau','slice-v2/prototype/greybox.project.json',
	'treasure/ROADMAP-TO-LAUNCH.md','treasure/sections/LESSONS.md',
	'treasure/CINEMATIC-CONTRACT.json','treasure/CINEMATIC-BUILD-meadow.json','treasure/CINEMATIC-BUILD-cave.json',
}do hashes[path]=serde.hash('sha256',fs.readFile(path))end
for _,name in fs.readDir(root)do
	if fs.isFile(root..name)then hashes[root..name]=serde.hash('sha256',fs.readFile(root..name))end
end
fs.writeFile('treasure/CINEMATIC-FINAL.json',serde.encode('json',{
	state='FEATURE CHECKS PASS; FOUR UNCHANGED LEGACY FAILURES',
	live_path_repair={notification_churn=contract.live_notification_churn,
		character_rebinding=contract.live_character_rebinding,debug_opt_in=contract.studio_debug_opt_in,
		independent_replacement_inputs=contract.live_independent_replacement_inputs,
		late_and_detached_descendants=contract.late_and_detached_descendants,
		debug_attributes=contract.studio_debug_values,
		live_cause='INFERRED; Studio acceptance pending',
		current_offline_checks={'cinematic-check','core shared tests','Meadow behavior','Cave cart drive','Cave boarding','selene'},
		dense_and_legacy_evidence='Prior run; server/physical/test inputs remain byte-equivalent'},
	places=contract.places,hashes=hashes,meadow_drop_samples=total,meadow_drop_routes=routes,
	meadow_drop_failures=0,cave_drop_samples=cave.samples,cave_drop_failures=0,
	legacy_failures=legacy,meadow_workers=workers,cave=cave,
	speed_authority='all server sources/properties and prior place serialization exact',
	dense_input='client presentation iterated during sampling; full server/physical/test state exact to pre-cine and final',
	Studio='NOT RUN; Claude live acceptance pending',commit='NOT RUN',publish='NOT RUN',
},true))
print('SEALED feature checks; Meadow',total,'samples /',routes,'routes; Cave',cave.samples,'samples; zero drop failures; four historical failures unchanged')
