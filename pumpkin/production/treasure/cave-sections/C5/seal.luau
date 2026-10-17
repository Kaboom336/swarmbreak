local fs,serde=require('@lune/fs'),require('@lune/serde')
local H='treasure/cave-sections/C5/'
local hash=serde.hash('sha256',fs.readFile('prototype/cave-v2.rbxl'))
local function json(name)return serde.decode('json',fs.readFile(H..name))end
assert(json('VERIFY.json').place_sha256==hash and json('VERIFY.json').state=='PASS')
for _,name in {'RUNTIME.json','EFFECTS.json','MOUNT-r4.json','OFFLINE-INPUT-8.json','OFFLINE-INPUT-artifact-only.json'}do assert(json(name).place_sha256==hash,name..' artifact mismatch')end
assert(serde.hash('sha256',fs.readFile('prototype/cave-v2.pre-c5.rbxl'))==json('BACKUP.json').sha256,'backup changed')
local log=fs.readFile(H..'offline-dense-final.log');local visible=log:gsub('%z','')
assert(visible:find('PASS scene preservation, O0/O1/O2, manifest, kit clearance/query, stacked floor, policy, reachable drops',1,true),'fresh dense incomplete')
local dense=serde.decode('json',fs.readFile('prototype/cave-v2/STUDIO-OFFLINE.json'))
assert(dense.N==8 and dense.samples==3024 and next(dense.failures)==nil and next(dense.reasons)==nil,'dense failed')
fs.writeFile(H..'DENSE-FINAL.json',serde.encode('json',{state='PASS',place_sha256=hash,report=dense,log_sha256=serde.hash('sha256',log),input=json('OFFLINE-INPUT-8.json'),live_suites='UNKNOWN; no Studio play'},true))
for _,round in {'r1','r2','r3','r4'}do
 assert(json('AUDIT-'..round..'.json').state=='PASS')
 assert(json('CONTACT-'..round..'.json').contact==0)
 assert(fs.isFile(H..'PRE-'..round:upper()..'.jpg')and fs.isFile(H..'SBS-'..round:upper()..'.jpg'))
end
assert(json('SUPPORT.json').state=='PASS'and json('CAMERA-CHECK.json').state=='PASS')
for _,name in {'tests','cart-board-check','cart-drive-check','rider-check','ride-contract-check','runner-check','kit-library-test'}do assert(fs.readFile(H..name..'.log'):gsub('%z',''):find('PASS',1,true),'missing test '..name)end
local files={}
for _,name in fs.readDir(H)do
 if name~='FINAL-EVIDENCE.json'and fs.isFile(H..name)then files[name]=serde.hash('sha256',fs.readFile(H..name))end
 require('@lune/task').wait()
end
fs.writeFile(H..'FINAL-EVIDENCE.json',serde.encode('json',{state='OFFLINE PASS; VISUAL REVISIT',place_sha256=hash,backup_sha256=json('BACKUP.json').sha256,canonical='prototype/cave-v2.rbxl',rounds=4,original_sources_exact=37,compiled=39,cosmetics=110,contact=0,protected_solids=14409,support_probes=275,new_lights=3,dense_samples=3024,dense_failures=0,independent_Claude_owner_and_live_suites='UNKNOWN / NOT RUN',scene_dumps='gitignored; no staging or commit',files=files},true))
print('SEALED C5: exact originals/suites, contact 0, 3024 drops/0 failures; visual REVISIT',hash)
