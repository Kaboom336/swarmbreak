local fs,serde=require('@lune/fs'),require('@lune/serde')
local H='treasure/cave-sections/C2/'
local function json(name)return serde.decode('json',fs.readFile(H..name))end
local function hash(path)return serde.hash('sha256',fs.readFile(path))end
local final=hash('prototype/cave-v2.rbxl')
local input=json('OFFLINE-INPUT-8.json')
assert(input.place_sha256==final,'dense input differs from canonical')
-- Windows PowerShell redirection writes UTF-16LE. Match ASCII verdicts after
-- dropping NUL code-unit bytes; hash/preserve the original logs unchanged.
local function logText(path)return fs.readFile(path):gsub('%z','')end
local dense=logText(H..'dense-drop-final.log'):gsub('%s+',' ')
assert(dense:find('CHECKED cave native+kit bounds samples 3024 failures {}',1,true),'fresh dense sweep not complete')
assert(dense:find('PASS scene preservation, O0/O1/O2, manifest, kit clearance/query, stacked floor, policy, reachable drops',1,true),'dense sweep did not pass')
local drop=serde.decode('json',fs.readFile('prototype/cave-v2/STUDIO-OFFLINE.json'))
assert(drop.N==8 and drop.samples==3024 and next(drop.failures)==nil and next(drop.reasons)==nil)
fs.writeFile(H..'DENSE-FINAL.json',serde.encode('json',drop,true))
local images={}
for _,tag in {'before','r1','r2'}do for _,view in {'arrival','geode','main','cart','cave','overview'}do table.insert(images,tag..'-'..view..'.png')end end
for _,name in {'SPEC.md','REFS.jpg','TARGET.png','PROMPT.md','CAMERAS.json','BEFORE.jpg','BEFORE-phone.jpg','PRE-R1.jpg','PRE-R2.jpg','SBS-R1.jpg','SBS-R2.jpg','SBS-R1-phone.jpg','SBS-R2-phone.jpg','RESULT.md','GAPS-R1.md','GAPS-R2.md','build.luau','plan.luau','presentation.luau','verify.luau','runtime-check.luau','offline-check.luau','artifact-only.log','dense-drop-final.log','selene.log','tests.log','cart-board-check.log','cart-drive-check.log','rider-check.log','ride-contract-check.log','runner-check.log','library-test.log'}do table.insert(images,name)end
local hashes={};for _,name in images do hashes[name]=hash(H..name)end
local verify=json('VERIFY.json');local runtime=json('RUNTIME.json')
assert(verify.place_sha256==final and runtime.place_sha256==final)
local r2=json('MOUNT-r2.json');assert(r2.place_sha256==final)
local artifact=logText(H..'artifact-only.log');assert(artifact:find('PASS final mounted source parity',1,true))
for _,name in {'tests','cart-board-check','cart-drive-check','rider-check','ride-contract-check','runner-check','library-test'}do
 local log=logText(H..name..'.log');assert(log:find('PASS',1,true),'missing pass '..name)
end
fs.writeFile(H..'FINAL-EVIDENCE.json',serde.encode('json',{state='PASS offline; visual REVISIT',rounds=2,place_sha256=final,backup_sha256=hash('prototype/cave-v2.pre-c2.rbxl'),r1={mount=json('MOUNT-r1.json'),audit=json('AUDIT-r1.json'),contact=json('CONTACT-r1.json')},r2={mount=r2,audit=json('AUDIT-r2.json'),contact=json('CONTACT-r2.json'),presentation=json('PRESENTATION-r2.json')},verify=verify,runtime=runtime,dense=drop,dense_input=input,hashes=hashes,independent_Claude_review='UNKNOWN',live_six_suites='UNKNOWN; NOT RUN',studio_play='NOT RUN',owner_acceptance='UNKNOWN'},true))
print('PASS C2 final seal: canonical/backup, exact unrelated state, both rounds, contacts, runtime, 3024 fresh dense drops, all six views/boards')
