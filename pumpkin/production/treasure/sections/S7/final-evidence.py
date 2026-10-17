"""Seal exact mounted slice and fresh offline evidence without visual acceptance."""
import json,hashlib
from pathlib import Path
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
read=lambda n:json.loads((H/n).read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
canonical=ROOT/'slice-v2/prototype/guardian-greybox.rbxl'
backup=ROOT/'slice-v2/prototype/guardian-greybox.pre-s7.rbxl'
source=ROOT/'prototype/meadow-v4/Section7.luau'
assert sha(backup)==read('BACKUP.json')['backup_sha256']
assert canonical.read_bytes()==(H/'R2-review.rbxl').read_bytes()
assert source.read_bytes()==(H/'r2-Section7.luau').read_bytes()
assert sha(canonical)==read('TEST-INPUT.json')['canonical_sha256']
assert sha(source)==read('TEST-INPUT.json')['source_sha256']
for stage,count,probes in [('r1',19,200),('r2',34,300)]:
 a=read('AUDIT-'+stage+'.json');s=read('SIGNATURES-'+stage+'.json')
 assert a['compiled_O0_O1_O2']==77 and a['unrelated_sources_preserved']==76 and a['workspace_exact'] and a['all_protected_signatures_exact']
 assert s['existing_part_signatures_preserved']==33742 and s['added_native_cosmetics']==count and s['bearing_footprint_probes']==probes and s['contact_errors']==0
 c=read(stage+'-physical-contact.json')
 for k in ('physical_penetrations','kit_physical_penetrations','kit_support_errors','floating_assemblies','lane_buffer_errors'):assert not c[k]
 assert read('RENDER-'+stage+'.json')['views']==read('CAMERAS.json')
 for v in read('CAMERAS.json'):assert (H/(stage+'-'+v['name']+'.png')).stat().st_mtime>backup.stat().st_mtime
assert read('SIGNATURES-r2.json')['frozen_R1_fence']
def log(n):
 b=(H/n).read_bytes();return b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
for n,phrase in [('contracts.log','PASS nonzero origin'),('behavior.log','PASS production Arena.reset and overlapping path completion epochs'),('50-seed.log','PASS 50-seed actual 3D walking-floor')]:
 s=log(n);assert phrase in s and '[Stack Begin]' not in s,(n,s[-400:])
d=read('final-DROPS.json')
assert d['state']=='PASS' and d['samples']==31824 and len(d['all_routes_executed_exactly_once'])==20 and not d['failures']
assert all(w['input_sha256']==sha(canonical) for w in d['workers'])
files=[canonical,backup,source,H.parent/'LESSONS.md',H.parent/'SECTION-CHECKLIST.md',H.parent/'SECTIONS.md']
for p in H.iterdir():
 if p.is_file() and p.name!='FINAL-EVIDENCE.json':files.append(p)
out=dict(technical_state='PASS offline',visual_state='REVISIT; stop for Claude live check',rounds_completed=[1,2],compiled_sources_O0_O1_O2=77,unrelated_sources_preserved=76,serialized_place_exact_after_removing_Section7=True,original_native_parts_exact=33742,original_Keeper_treasure_court_bait_bell_sight_blockers_exact=True,original_paving_edges_lane_geometry_physics_tags_attributes_exact=True,new_cosmetic_parts=34,frozen_R1_fence_parts=12,R1_tent_rotated_for_R2_gap2=True,contact_errors=0,R2_full_bearing_probes=300,all_height_lane_margin_studs=1,new_PointLights=[dict(brightness=1.5,range=18,shadows=False)]*2,DropSample_cases=d['samples'],DropSample_routes=len(d['all_routes_executed_exactly_once']),DropSample_failures=0,independent_technical_critic='PASS offline',independent_Claude_live_review='PENDING',live_Studio_suites='UNKNOWN',live_carry_PvP='UNKNOWN',owner_acceptance='UNKNOWN',limits='Native offline render/physics/kit proxies; static kit list inherited, preserved source/serialized state is authority; see RENDER-LIMITS.md',corrected_failures=['Unsupported Ceramic material before mount; changed to SmoothPlastic','Nested offline harness require; reused flattened existing harness, production assertions unchanged'],commit='NONE',publish='NONE',hashes={str(p.relative_to(ROOT)):sha(p) for p in files})
(H/'FINAL-EVIDENCE.json').write_text(json.dumps(out,indent=2));print('PASS S7 R1/R2 evidence sealed; visual REVISIT; stop before R3/R4')
