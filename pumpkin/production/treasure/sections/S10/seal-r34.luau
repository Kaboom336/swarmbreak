local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local H='treasure/sections/S10/'
local bytes=fs.readFile('slice-v2/prototype/guardian-greybox.rbxl')
local original=fs.readFile('slice-v2/prototype/guardian-greybox.pre-s10r3.rbxl')
local p,b=rb.deserializePlace(bytes),rb.deserializePlace(original)
for _,name in {'Section9','Section10'}do
 assert(p.ReplicatedStorage.MeadowV4[name].Source==fs.readFile('prototype/meadow-v4/'..name..'.luau'),'mounted source drift '..name)
 fs.writeFile(H..'r4-'..name..'.luau',p.ReplicatedStorage.MeadowV4[name].Source)
 p.ReplicatedStorage.MeadowV4[name].Source=b.ReplicatedStorage.MeadowV4[name].Source
end
assert(rb.serializePlace(p)==rb.serializePlace(b),'unrelated serialized state changed')
assert(fs.readFile(H..'R4-review.rbxl')==bytes,'review artifact drift')
local drops=serde.decode('json',fs.readFile(H..'r34-DROPS.json'))
assert(drops.state=='PASS'and drops.samples==31824 and #drops.failures==0)
local hash=serde.hash('sha256',bytes)
for _,r in drops.workers do assert(r.input_sha256==hash,'drop input drift')end
for _,tag in {'r3','r4'}do
 local audit=serde.decode('json',fs.readFile(H..'AUDIT-'..tag..'.json'))
 for _,key in {'physical_contacts','bounds_errors','unsupported','lane_margin_errors','camera_inside_visible_parts'}do assert(#audit[key]==0,key)end
 assert(audit.S9_parts==1720 and audit.S9_lights_exact)
end
local records={}
for _,name in {'GAPS-R3.md','GAPS-R4.md','RESULT.md','../LESSONS.md','HOME-R34.json','AUDIT-r3.json','AUDIT-r4.json','MOUNT-r3.json','MOUNT-r4.json','r3-visual.json','r4-visual.json','SBS-R3.jpg','SBS-R4.jpg','SBS-R3-phone.jpg','SBS-R4-phone.jpg','PRE-R3.jpg','PRE-R4.jpg','CRITIC-R34.md','r34-home.log','r34-owners.log','r34-contracts.log','r34-behavior.log','r34-50-seed.log','r34-DROPS.json','r34-drop-1.log','r34-drop-2.log','r34-drop-3.log','r3-walk.png','r3-pen.png','r4-walk.png','r4-open.png','r4-locked.png','r4-overview.png','r4-pen.png','build.luau','audit-r34.py','home-r34.luau','drop-r34.luau','merge-drops-r34.py','owners.luau','r4-Section9.luau','r4-Section10.luau'}do
 records[name]=serde.hash('sha256',fs.readFile(H..name))
end
local home=serde.decode('json',fs.readFile(H..'HOME-R34.json'))
assert(home.s9_parts==1720 and home.s10_parts==104 and home.count_drop_negative_control)
fs.writeFile(H..'FINAL-R34-EVIDENCE.json',serde.encode('json',{canonical_sha256=hash,backup_sha256=serde.hash('sha256',original),changed_sources={'Section9','Section10'},all_other_serialized_state_exact=true,HomeArt_gameplay_saving_prompts_travel_unlocks_tests_exact=true,offline_drops=31824,physical_contacts=0,verdict='REVISIT',root_of_first_live_failure='UNKNOWN; source geometry retained; partial-assembly guard/recovery flaw repaired',live_Studio_and_owner_acceptance='UNKNOWN',records=records},true))
print('PASS final source/artifact/drop hash parity; only Section9/Section10 source changed; all unrelated serialized state exact; REVISIT',hash)
