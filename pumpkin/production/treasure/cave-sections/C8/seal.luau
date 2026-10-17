local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local H='treasure/cave-sections/C8/'
local function read(name)return serde.decode('json',fs.readFile(H..name..'.json'))end
local bytes=fs.readFile('prototype/cave-v2.rbxl');local sha=serde.hash('sha256',bytes)
local mount,verify,runtime=read('MOUNT-r4'),read('VERIFY'),read('RUNTIME')
assert(mount.place_sha256==sha and verify.place_sha256==sha and runtime.place_sha256==sha)
assert(fs.readFile(H..'r4-review.rbxl')==bytes,'final review drift')
local backup=fs.readFile('prototype/cave-v2.pre-c8.rbxl')
assert(serde.hash('sha256',backup)==read('BACKUP').sha256,'backup drift')
local dense,input=read('STUDIO-OFFLINE'),read('OFFLINE-INPUT-8')
assert(input.place_sha256==sha and dense.N==8 and dense.samples>0 and next(dense.failures)==nil)
assert(read('OFFLINE-INPUT-artifact-only').place_sha256==sha)
-- Windows PowerShell redirection writes UTF-16LE logs. These PASS markers
-- are ASCII; strip its NUL bytes for marker search, retain raw bytes in hashes.
local function log(name)return (fs.readFile(H..name):gsub('%z',''))end
assert(log('offline-dense.log'):find('PASS scene preservation',1,true))
assert(log('offline-artifact.log'):find('PASS final mounted source parity',1,true))
for _,name in {'VERIFY','RUNTIME','AUDIT-r4','CONTACT-r4','CAMERA-CHECK','SUPPORT-r4'}do assert(read(name).state=='PASS',name)end
local evidence={place_sha256=sha,backup_sha256=serde.hash('sha256',backup),visual_verdict='REVISIT',rounds=4,
 r1_frozen=197,new_native_cosmetics=329,fitted_rocks=303,new_lights=0,falling_emitters=3,
 original_transparency_only_changes=2124,old_cubes=74,distant_crystal_details=2050,
 complete_unrelated_serialization_exact_after_explicit_restoration=true,all_original_sources_and_six_suite_bodies_exact=true,
 studio_play=false,live_six_suites='UNKNOWN',owner_claude_acceptance='UNKNOWN',contact=read('CONTACT-r4'),
 support_proxy=read('SUPPORT-r4'),runtime=runtime,stock_N8=dense,hashes={}}
local files={'TARGET.png','TARGET-PROMPT.txt','CAMERAS.json','SPEC.md','README.md','RESULT.md','retire.luau','ROCK-PLAN.json','R2-ADDITIONS.json','R3-ADDITIONS.json','R4-ADDITIONS.json','build.luau','plan.luau','render.py','verify.luau','audit.luau','runtime-check.luau','offline-check.luau','camera-check.luau','contact.py','contact-fast.py','GAPS-R1.md','GAPS-R2.md','GAPS-R3.md','GAPS-R4.md','SBS-FINAL.jpg','SBS-FINAL-phone.jpg','VERIFY.json','RUNTIME.json','AUDIT-r4.json','CONTACT-r4.json','SUPPORT-r4.json','CAMERA-CHECK.json','OFFLINE-INPUT-8.json','OFFLINE-INPUT-artifact-only.json','offline-artifact.log','offline-dense.log','tests.log','cart-board-check.log','cart-drive-check.log','rider-check.log','ride-contract-check.log','runner-check.log','kit-library-test.log'}
for _,name in files do evidence.hashes[name]=serde.hash('sha256',fs.readFile(H..name))end
for _,name in {'prototype/cave-v2/build.luau','prototype/cave-v2/EscapeC8.server.luau','prototype/cave-v2/studio-check.luau','assets/kits2/ROBLOX-ASSETS.json'}do evidence.hashes[name]=serde.hash('sha256',fs.readFile(name))end
local p,b=rb.deserializePlace(bytes),rb.deserializePlace(backup)
local retire=require('./retire');local original=b.Workspace.CaveV2:GetDescendants();local final=p.Workspace.CaveV2:GetDescendants()
local retired={}
for i,q in original do if retire(q,'r4')then
 assert(not q.CanCollide and final[i].CanCollide==q.CanCollide and final[i].CanQuery==q.CanQuery and final[i].CanTouch==q.CanTouch)
 table.insert(retired,{native_index=i,name=q.Name,before=q.Transparency,after=final[i].Transparency})
end end
assert(#retired==2124)
fs.writeFile(H..'RETIREMENTS.json',serde.encode('json',{only='Transparency',count=#retired,indices=retired},true))
evidence.hashes['RETIREMENTS.json']=serde.hash('sha256',fs.readFile(H..'RETIREMENTS.json'))
fs.writeFile(H..'FINAL-EVIDENCE.json',serde.encode('json',evidence,true))
print('SEALED C8 REVISIT',sha,'N8',dense.samples,'failures 0; rounds 4; no Studio Play')
