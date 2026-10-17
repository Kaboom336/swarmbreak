local fs,serde=require('@lune/fs'),require('@lune/serde')
local H='treasure/cave-sections/C3/'
local hash=serde.hash('sha256',fs.readFile('prototype/cave-v2.rbxl'))
local input=serde.decode('json',fs.readFile(H..'OFFLINE-INPUT-8.json'))
assert(input.place_sha256==hash,'dense input not final build')
assert(input.checker_sha256==serde.hash('sha256',fs.readFile('prototype/cave-v2/studio-check.luau')),'checker changed')
-- Windows PowerShell redirection uses UTF-16LE; sampler log verdict is ASCII.
local log=fs.readFile(H..'dense-final.log'):gsub('%z','')
assert(log:find('PASS scene preservation, O0/O1/O2, manifest, kit clearance/query, stacked floor, policy, reachable drops',1,true),'dense run incomplete')
local drops=serde.decode('json',fs.readFile('prototype/cave-v2/STUDIO-OFFLINE.json'))
assert(drops.N==8 and drops.samples==3024 and next(drops.failures)==nil and next(drops.reasons)==nil,'drop failures')
fs.writeFile(H..'DENSE-FINAL.json',serde.encode('json',{place_sha256=hash,report=drops,checker_sha256=input.checker_sha256},true))
local files={}
for _,name in fs.readDir(H)do
 if name:match('%.md$')or name:match('%.luau$')or name:match('%.py$')or name:match('%.ps1$')or name:match('%.jpg$')or name:match('%.png$')or name:match('^AUDIT')or name:match('^CONTACT')or name:match('^VERIFY')or name:match('^RUNTIME')or name=='SUPPORT.json'or name=='DENSE-FINAL.json'or name=='CAMERAS.json'then
  files[name]=serde.hash('sha256',fs.readFile(H..name))
 end
end
fs.writeFile(H..'FINAL-EVIDENCE.json',serde.encode('json',{verdict='REVISIT',place_sha256=hash,rounds=4,contact=0,cosmetic_parts=68,original_sources_exact=34,compiled_O0_O1_O2=35,dense_samples=drops.samples,dense_failures=0,full_bearing='FAIL: 22/150 envelope probes miss; all centers bear',live_suites='UNKNOWN; Studio not launched',independent_Claude_review='UNKNOWN',files=files},true))
print('SEALED final artifact N8',drops.samples,'zero failures; visual REVISIT')
