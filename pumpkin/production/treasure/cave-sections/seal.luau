local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local id=require('@lune/process').args[1];local H='treasure/cave-sections/'..id..'/'
local tag=fs.isFile(H..'r4-review.rbxl')and'r4'or(fs.isFile(H..'r3-review.rbxl')and'r3'or'r2')
local bytes=fs.readFile(H..tag..'-review.rbxl');local hash=serde.hash('sha256',bytes)
if id=='C7'then assert(fs.readFile('prototype/cave-v2.rbxl')==bytes,'current canonical differs from final C7 review')end
assert(serde.hash('sha256',fs.readFile('prototype/cave-v2.pre-'..id:lower()..'.rbxl'))==serde.decode('json',fs.readFile(H..'BACKUP.json')).sha256,'backup changed')
local function json(n)return serde.decode('json',fs.readFile(H..n))end
local node=rb.deserializePlace(bytes).ServerScriptService['CaveEscape'..id];local final=node.Round.Value
assert(json('VERIFY.json').place_sha256==hash and json('VERIFY.json').state=='PASS')
for _,n in {'RUNTIME.json','MOUNT-'..final..'.json','OFFLINE-INPUT-8.json','OFFLINE-INPUT-artifact-only.json'}do assert(json(n).place_sha256==hash,n..' mismatch')end
if id=='C7'and tonumber(final:sub(2))>=3 then assert(json('LABELS.json').state=='PASS'and json('LABELS.json').place_sha256==hash)end
assert(json('SUPPORT.json').state=='PASS'and json('CAMERA-CHECK.json').state=='PASS')
for i=1,tonumber(final:sub(2))do
 local tag='r'..i
 assert(json('AUDIT-'..tag..'.json').state=='PASS'and json('CONTACT-'..tag..'.json').contact==0)
 assert(fs.isFile(H..'PRE-'..tag:upper()..'.jpg')and fs.isFile(H..'SBS-'..tag:upper()..'.jpg'))
end
for _,n in {'tests','cart-board-check','cart-drive-check','rider-check','ride-contract-check','runner-check','kit-library-test'}do assert(fs.readFile(H..n..'.log'):gsub('%z',''):find('PASS',1,true),'missing '..n)end
local dense=json('DENSE-FINAL.json');assert(dense.place_sha256==hash and dense.report.N==8 and dense.report.samples==3024 and next(dense.report.failures)==nil)
local files={}
for _,n in fs.readDir(H)do if n~='FINAL-EVIDENCE.json'and fs.isFile(H..n)then files[n]=serde.hash('sha256',fs.readFile(H..n))end;require('@lune/task').wait()end
fs.writeFile(H..'FINAL-EVIDENCE.json',serde.encode('json',{state='OFFLINE PASS; VISUAL REVISIT',section=id,final_round=final,canonical='prototype/cave-v2.rbxl',place_sha256=hash,backup_sha256=json('BACKUP.json').sha256,verify=json('VERIFY.json'),contact=0,lights='bounded warm shadowless; AUDIT',live_six_suites_and_independent_Claude_owner_acceptance='UNKNOWN; no Studio play',target='built-in image_gen aspiration; PROMPT.md',files=files},true))
print('SEALED',id,final,hash)
