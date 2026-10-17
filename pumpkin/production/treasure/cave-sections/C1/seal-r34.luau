local fs,serde=require('@lune/fs'),require('@lune/serde')
local H='treasure/cave-sections/C1/'
local function read(name)return serde.decode('json',fs.readFile(H..name..'.json'))end
local hash=serde.hash('sha256',fs.readFile('prototype/cave-v2.rbxl'))
local runtime=read('VERIFY-R34')
assert(runtime.state=='PASS'and runtime.place_sha256==hash,'runtime evidence drift')
local artifact=read('OFFLINE-INPUT-artifact-only')
assert(artifact.place_sha256==hash,'artifact input drift')
assert(fs.readFile(H..'r34-artifact-final.log'):gsub('%z',''):find('PASS final mounted source parity',1,true),'artifact checker incomplete')
local evidence={state='PASS offline; visual REVISIT',rounds=4,place_sha256=hash,backup_sha256=runtime.pre_r3_sha256,runtime=runtime,artifact=artifact,studio_play='NOT RUN',independent_claude_review='UNKNOWN',owner_acceptance='UNKNOWN',hashes={}}
for _,tag in {'r3','r4'}do
 local audit,contact=read('AUDIT-'..tag),read('CONTACT-'..tag)
 assert(#audit.lane_errors==0 and #audit.support_errors==0 and contact.contact==0,'unsafe round')
 evidence[tag]={audit=audit,contact=contact,mount=read('MOUNT-'..tag),presentation=read('PRESENTATION-'..tag)}
end
for _,name in {'tests','cart-board-check','cart-drive-check','rider-check','ride-contract-check','runner-check','library-test'}do
 local log=fs.readFile(H..'r34-'..name..'.log'):gsub('%z','')
 assert(log:find('PASS',1,true),'missing suite pass: '..name)
end
local lint=fs.readFile(H..'r34-selene.log'):gsub('%z','')
assert(lint:find('0 errors',1,true)and lint:find('0 warnings',1,true)and lint:find('0 parse errors',1,true),'lint incomplete')
for _,name in {'r3.json','r4.json','r3-plan.json','r4-plan.json','r3-arrival.png','r3-outgoing.png','r4-arrival.png','r4-outgoing.png','SBS-R3.jpg','SBS-R4.jpg','SBS-R4-phone.jpg','GAPS-R4.md','RESULT.md','presentation.luau','verify-r34.luau','r34-artifact-final.log','r34-selene.log','CAMERAS.json','TARGET.png'}do
 evidence.hashes[name]=serde.hash('sha256',fs.readFile(H..name))
end
evidence.dense_sweep={state='HISTORICAL PASS',fresh_r4_run=false,samples=3024,failures=0,physical_query_state_preserved=true,source='R1/R2 FINAL-EVIDENCE.json and DENSE-FINAL.json'}
fs.writeFile(H..'FINAL-R34-EVIDENCE.json',serde.encode('json',evidence,true))
print('PASS R34 sealed; contact 0, all lanes, exact original state, runtime and artifact checks; visual REVISIT')
