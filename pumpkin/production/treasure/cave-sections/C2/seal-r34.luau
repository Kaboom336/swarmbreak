local fs,serde=require('@lune/fs'),require('@lune/serde')
local H='treasure/cave-sections/C2/'
local hash=serde.hash('sha256',fs.readFile('prototype/cave-v2.rbxl'))
local verify=serde.decode('json',fs.readFile(H..'VERIFY-R34.json'))
local runtime=serde.decode('json',fs.readFile(H..'RUNTIME-R34.json'))
local input=serde.decode('json',fs.readFile(H..'OFFLINE-INPUT-8.json'))
for _,r in {verify,runtime,input}do assert(r.place_sha256==hash,'stale input/check')end
local dense=serde.decode('json',fs.readFile('prototype/cave-v2/STUDIO-OFFLINE.json'))
-- Windows PowerShell redirects native stdout as UTF-16LE. Match the ASCII
-- completion records after stripping its NUL bytes; hash raw logs unchanged.
local log=fs.readFile(H..'r34-dense-final.log'):gsub('%z','')
assert(log:find('PASS scene preservation, O0/O1/O2, manifest, kit clearance/query, stacked floor, policy, reachable drops',1,true),'dense checker incomplete')
assert(dense.N==8 and dense.samples==3024 and #dense.failures==0 and next(dense.reasons)==nil,'dense failures')
local contact=serde.decode('json',fs.readFile(H..'CONTACT-r4.json'))
local audit=serde.decode('json',fs.readFile(H..'AUDIT-r4.json'))
assert(contact.contact==0 and #audit.lane_errors==0 and #audit.support_errors==0)
local checks={}
local visuals={}
for _,name in {'SBS-R3.jpg','SBS-R4.jpg','SBS-R4-phone.jpg','TARGET.png','r4.json'}do
 visuals[name]=serde.hash('sha256',fs.readFile(H..name))
end
for _,name in {'tests','library-test','cart-board-check','cart-drive-check','rider-check','ride-contract-check','runner-check'}do
 local data=fs.readFile(H..'r34-'..name..'.log');assert(data:gsub('%z',''):find('PASS',1,true),'check incomplete '..name)
 checks[name]=serde.hash('sha256',data)
end
fs.writeFile(H..'DENSE-R34.json',serde.encode('json',dense,true))
fs.writeFile(H..'FINAL-R34-EVIDENCE.json',serde.encode('json',{state='PASS',place_sha256=hash,backup_sha256=serde.hash('sha256',fs.readFile('prototype/cave-v2.pre-c2r3.rbxl')),checker_sha256=input.checker_sha256,contact=contact.contact,cosmetic_envelopes=contact.cosmetic_envelopes,lanes=audit.lanes,dense_samples=dense.samples,dense_failures=0,original_serialization_exact=verify.original_serialization_exact,loot_root_exact=verify.loot_root_exact,compiled_O0_O1_O2=verify.compiled_O0_O1_O2,runtime=runtime,checks=checks,visual_hashes=visuals,visual='REVISIT; author review only',studio='NOT LAUNCHED; live suites UNKNOWN',commit=false},true))
print('PASS sealed final R34 hash, contact 0, 3024 dense samples, unchanged offline checks')
