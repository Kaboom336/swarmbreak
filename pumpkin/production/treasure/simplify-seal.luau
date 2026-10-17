local fs, serde = require('@lune/fs'), require('@lune/serde')
local function read(path)return fs.readFile(path)end
local function report(path)
	local r=serde.decode('json',read(path))
	assert(r.status=='PASS' or r.state=='PASS',path..' failed');return r
end
local builds={}
for _,biome in {'meadow','cave'}do
	local r=report('treasure/SIMPLIFY-BUILD-'..biome..'.json')
	assert(r.place_sha256==serde.hash('sha256',read(r.place)),biome..' stale mount')
	assert(r.backup_sha256==serde.hash('sha256',read(r.backup)),biome..' backup drift')
	assert(r.complete_allowlist_undo_exact and r.server_tree_exact and r.workspace_exact)
	table.insert(builds,r)
end
local hash=builds[1].place_sha256
local drops=report('treasure/simplify-evidence/treasure_RAID-DROPS.json')
assert(drops.input_sha256==hash and drops.samples==31824 and #drops.failures==0)
assert(#drops.all_routes_executed_exactly_once==20)
for _,name in {'RAID-CONTRACTS','RAID-CLIENT','RAID-VAULT'}do
	assert(report('treasure/simplify-evidence/treasure_'..name..'.json').artifact_sha256==hash,'stale '..name)
end
local cavePath='treasure/simplify-evidence/treasure_sound-evidence_cave-treasure_cave-sections_C8_STUDIO-OFFLINE.json'
local cave=serde.decode('json',read(cavePath))
assert(cave.N==8 and cave.samples==3024 and #cave.failures==0 and next(cave.reasons)==nil,'Cave N8 incomplete/failing')
local caveInput=serde.decode('json',read('treasure/simplify-evidence/treasure_sound-evidence_cave-treasure_cave-sections_C8_OFFLINE-INPUT-8.json'))
assert(caveInput.place_sha256==builds[2].place_sha256,'stale Cave input')
local evidence={}
for _,path in {'treasure/SIMPLIFY-CONTRACT.json','treasure/SIMPLIFY-UI-CLIENT.json','treasure/SIMPLIFY-CUTSCENES.json',
	'treasure/simplify-evidence/treasure_UI-PASS-CHECKS.json','treasure/simplify-evidence/treasure_SOUND-CONTRACT.json',
	'treasure/simplify-evidence/treasure_SOUND-MOVEMENT.json'}do
	report(path);evidence[path]=serde.hash('sha256',read(path))
end
local logAssertions={
	{'contract','PASS simplify presentation/authority/input contracts'},
	{'ui-client','PASS actual objective/world UI clients'},
	{'ui','PASS UI presentation/contract assertions'},
	{'cutscenes','PASS current simplified cutscenes'},
	{'sound','PASS sound'},
	{'movement','30/60/144fps policy'},
	{'contracts','PASS nonzero origin'},
	{'behavior','PASS production Arena.reset and overlapping path completion epochs'},
	{'50-seed','PASS 50-seed actual 3D walking-floor'},
	{'raid','PASS raid lifecycle'},
	{'raid-client','PASS actual raid client'},
	{'raid-vault','PASS actual server vault'},
	{'core','acorn handoff -> secure -> Open -> Pup -> Coins'},
	{'cart-drive','PASS production drive mock'},
	{'cart-board','PASS production boarding/departure'},
	{'drop-merge','PASS 31824 samples; 20 routes; zero failures'},
	{'cave','PASS scene preservation, O0/O1/O2'},
	{'legacy','CHECKED three unchanged archival failures'},
	{'lint','0 errors'},
}
for _,entry in logAssertions do
	local path='treasure/simplify-'..entry[1]..'.log'
	local bytes=read(path)
	local text=bytes:gsub('\0','') -- ASCII markers in UTF-8 or PowerShell UTF-16LE logs.
	assert(text:find(entry[2],1,true),'missing completion '..path)
	assert(not text:find('[Stack Begin]',1,true),'failed check '..path)
	evidence[path]=serde.hash('sha256',bytes)
end
local legacy=serde.decode('json',read('treasure/simplify-evidence/LEGACY-FAILURES.json'))
assert(#legacy.checks==3 and legacy.core_alias_equality_failed_before_and_after)
for _,r in legacy.checks do assert(r.unchanged and r.baseline_failure==r.final_failure) end
local sources={}
for _,path in {'prototype/core/UIPresentation.luau','prototype/core/Objective.client.luau','prototype/core/UIWorld.client.luau',
	'prototype/core/Cutscenes.luau','slice-v2/prototype/Greybox.client.luau','prototype/cave-v2/build.luau',
	'treasure/simplify-build.luau','treasure/simplify-meadow-build.luau','treasure/simplify-check.luau',
	'treasure/simplify-ui-client-check.luau','treasure/simplify-cutscenes-check.luau',
	'treasure/simplify-existing-checks.luau','treasure/simplify-legacy-check.luau','treasure/simplify-seal.luau',
	'treasure/SIMPLIFY.md','treasure/SIMPLIFY-SUMMARY.md'}do sources[path]=serde.hash('sha256',read(path))end
local summary=read('treasure/SIMPLIFY-SUMMARY.md')
local _,lines=summary:gsub('\n','')
if summary:sub(-1)~='\n' then lines+=1 end
assert(lines<=20,'summary exceeds twenty lines')
fs.writeFile('treasure/SIMPLIFY-FINAL.json',serde.encode('json',{
	status='PASS CURRENT OFFLINE CHECKS; FOUR ARCHIVAL FAILURES UNCHANGED',
	builds=builds,source_sha256=sources,evidence_sha256=evidence,
	Meadow_N8={samples=drops.samples,routes=20,failures=0,exact_once=true,input_sha256=hash},
	Cave_N8={samples=cave.samples,failures=0,input_sha256=builds[2].place_sha256},
	archival_failures=legacy,Studio='NOT RUN',commit='NONE',
	visual_engine_hit_testing_device_audio_fairness_fun='UNKNOWN; Claude review pending',
},true))
print('PASS final seal: current offline checks; Meadow 31824/20 routes + Cave 3024 samples; four archival failures unchanged; no Studio/commit')
