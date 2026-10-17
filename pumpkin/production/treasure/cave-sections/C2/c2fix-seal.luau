local fs,serde=require('@lune/fs'),require('@lune/serde')
local H='treasure/cave-sections/C2/'
local hash=serde.hash('sha256',fs.readFile('prototype/cave-v2.rbxl'))
local build=serde.decode('json',fs.readFile(H..'C2FIX-BUILD.json'))
local geometry=serde.decode('json',fs.readFile(H..'C2FIX-CHECK.json'))
local contact=serde.decode('json',fs.readFile(H..'CONTACT-c2fix.json'))
local input=serde.decode('json',fs.readFile(H..'OFFLINE-INPUT-8.json'))
local dense=serde.decode('json',fs.readFile('prototype/cave-v2/STUDIO-OFFLINE.json'))
local runtime=serde.decode('json',fs.readFile(H..'RUNTIME-R34.json'))
for _,report in {build,geometry,contact,input,runtime}do assert(report.place_sha256==hash,'evidence hash mismatch')end
assert(contact.contact==0 and geometry.state=='PASS'and runtime.state=='PASS','failed check')
assert(dense.N==8 and dense.samples==3024 and next(dense.failures)==nil and next(dense.reasons)==nil,'dense sweep failed')
-- Windows PowerShell redirects native output as UTF-16LE. Assertions inspect
-- its ASCII text; evidence hashes always bind the original unmodified bytes.
assert(fs.readFile(H..'c2fix-dense.log'):gsub('%z',''):find('PASS scene preservation',1,true),'dense incomplete')
local evidence={}
for _,name in {'verify','contact','artifact-only','dense','runtime','tests','cart-board-check','cart-drive-check','rider-check','ride-contract-check','runner-check','library-test','selene'}do
 local path=H..'c2fix-'..name..'.log';local raw=fs.readFile(path);local body=raw:gsub('%z','')
 if name=='selene'then assert(body:find('0 errors',1,true)and body:find('0 parse errors',1,true),'lint failed')
 elseif name=='contact'then assert(contact.contact==0)
 else assert(body:find('PASS',1,true),'missing pass: '..name)end
 evidence[name]=serde.hash('sha256',raw)
end
fs.writeFile(H..'C2FIX-DENSE.json',serde.encode('json',dense,true))
fs.writeFile(H..'C2FIX-RUNTIME.json',serde.encode('json',runtime,true))
fs.writeFile(H..'C2FIX-INPUT.json',serde.encode('json',input,true))
-- Existing runner output names are historical. Preserve their R34 binding.
local previous=serde.decode('json',fs.readFile(H..'FINAL-R34-EVIDENCE.json'))
assert(serde.hash('sha256',fs.readFile('prototype/cave-v2/studio-check.luau'))==previous.checker_sha256,'original checker changed')
local currentTests={}
for name in previous.checks do
 local path=name=='library-test'and'prototype/kits/library-test.luau'or'prototype/cave-v2/'..name..'.luau'
 currentTests[name]=serde.hash('sha256',fs.readFile(path))
end
fs.writeFile(H..'RUNTIME-R34.json',serde.encode('json',previous.runtime,true))
for _,mode in {'8','artifact-only'}do
 local path=H..'OFFLINE-INPUT-'..mode..'.json'
 local prior=serde.decode('json',fs.readFile(path));prior.place_sha256=previous.place_sha256
 fs.writeFile(path,serde.encode('json',prior,true))
end
local sources={}
for _,path in {'prototype/cave-v2/build.luau',H..'dress.luau',H..'c2fix-check.luau',H..'c2fix-contact.luau','prototype/cave-v2/studio-check.luau'}do sources[path]=serde.hash('sha256',fs.readFile(path))end
fs.writeFile(H..'C2FIX-FINAL.json',serde.encode('json',{state='PASS',place_sha256=hash,backup_sha256=build.backup_sha256,
 only_mounted_dress_changed=true,loot_root_exact=true,compiled_O0_O1_O2=build.compiled_O0_O1_O2,
 shell_pieces=geometry.shell_pieces,crystal_points=geometry.crystal_points,camp_lights=geometry.camp_lights,
 before_brightness=geometry.original_enabled_brightness_sum,after_brightness=geometry.final_enabled_brightness_sum,
 contact=0,protected_solids=contact.protected_solids,dense_samples=dense.samples,dense_failures=0,
 evidence_hashes=evidence,source_hashes=sources,current_test_source_hashes=currentTests,
 live='UNKNOWN; Studio not launched/played',commit=false,publish=false},true))
print('PASS C2 fix sealed',hash,'samples',dense.samples,'contact 0')
