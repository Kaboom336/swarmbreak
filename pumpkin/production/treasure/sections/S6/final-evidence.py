"""Seal fresh artifacts and checks; never turn offline proxies into acceptance."""
import json,hashlib
from pathlib import Path
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
read=lambda n:json.loads((H/n).read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
canonical=ROOT/'slice-v2/prototype/guardian-greybox.rbxl'
backup=ROOT/'slice-v2/prototype/guardian-greybox.pre-s6.rbxl'
assert sha(backup)==read('BACKUP.json')['backup'].lower()
assert canonical.read_bytes()==(H/'R2-review.rbxl').read_bytes()
assert sha(canonical)==read('TEST-INPUT.json')['canonical_sha256'].lower()
assert (ROOT/'prototype/meadow-v4/Section6.luau').read_bytes()==(H/'r2-Section6.luau').read_bytes()
for stage in ('r1','r2'):
 a=read('AUDIT-'+stage+'.json');s=read('SIGNATURES-'+stage+'.json')
 assert a['compiled_O0_O1_O2']==76 and a['unrelated_sources_preserved']==75 and a['workspace_exact']
 assert s['contact_errors']==0 and s['mustkeep_paving_edges_exact'] and s['summit_court_exact']
 for view in ('entry','mid-up','shelf-down','overview'):
  image=H/(stage+'-'+view+'.png');assert image.stat().st_mtime>backup.stat().st_mtime
 assert read('RENDER-'+stage+'.json')['views']==read('CAMERAS.json')
assert read('SIGNATURES-r2.json')['r1_frozen']
def log(n):
 b=(H/n).read_bytes();return b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
for n,phrase in [('contracts.log','PASS nonzero origin'),('behavior.log','PASS production Arena.reset and overlapping path completion epochs'),('50-seed.log','PASS 50-seed actual 3D walking-floor'),('late-kits.log','PASS S5 late kits')]:
 text=log(n);assert phrase in text and '[Stack Begin]' not in text,(n,text[-500:])
drop=read('final-DROPS.json')
assert drop['state']=='PASS' and drop['samples']==31824 and len(drop['all_routes_executed_exactly_once'])==20 and not drop['failures']
assert all(w['input_sha256']==sha(canonical) for w in drop['workers'])
old,new=read('before.json')['parts'],read('r2.json')['parts']
assert len(new)-len(old)==34
existing=[p for p in new if p.get('section')!='S6'];assert len(existing)==len(old)
solid_edits=sum(a!=b and a['name']=='SolidMountainStone' for a,b in zip(old,existing))
cosmetic_edits=sum(a!=b and a['name']!='SolidMountainStone' for a,b in zip(old,existing))
paths=[canonical,backup,ROOT/'prototype/meadow-v4/Section6.luau',H.parent/'LESSONS.md',H.parent/'SECTION-CHECKLIST.md',H.parent/'SECTIONS.md']
for n in ('TARGET.png','TARGET-PROMPT.md','SPEC.md','GAPS-R1.md','GAPS-R2.md','PRE-R1.jpg','PRE-R2.jpg','SBS-R1.jpg','SBS-R2.jpg','SBS-R1-phone.jpg','SBS-R2-phone.jpg','R1-review.rbxl','R2-review.rbxl','before.json','r1.json','r2.json','SIGNATURES-r1.json','SIGNATURES-r2.json','r1-physical-contact.json','r2-physical-contact.json','contracts.log','behavior.log','50-seed.log','late-kits.log','final-DROPS.json','RESULT.md','RENDER-LIMITS.md','TEST-INPUT.json','STUDIO-CHECKS.md','build.luau','audit.py','drop.luau','final-evidence.py'):
 paths.append(H/n)
for stage in ('before','r1','r2'):
 for view in ('entry','mid-up','shelf-down','overview'):paths.append(H/(stage+'-'+view+'.png'))
for worker in (1,2,3):
 paths.extend([H/f'final-drop-{worker}.log',H/f'final-DROPS-{worker}.json'])
out=dict(technical_state='PASS offline',visual_state='REVISIT; stop for Claude live review',rounds_completed=[1,2],sources_compiled_O0_O1_O2=76,unrelated_sources_preserved=75,serialized_place_exact_after_removing_only_Section6=True,solid_geometry_flags_tags_attributes_exact=True,mustkeep_warm_paving_edge_stones_exact=True,summit_court_exact=True,existing_native_kit_manifest_exact=True,solid_colour_material_edits=solid_edits,nonphysical_cladding_colour_material_edits=cosmetic_edits,new_native_cosmetics=34,frozen_R1_parts=15,contact_errors=0,strict_horizontal_lane_margin_studs=1,new_point_lights=4,DropSample_cases=31824,DropSample_routes=20,DropSample_failures=0,live_Studio='UNKNOWN',live_carry_PvP_recovery='UNKNOWN',independent_Claude_review='PENDING',owner_acceptance='UNKNOWN',process_deviation='PRE-R1 composition completed during compilation after local library failures; see RENDER-LIMITS.md',commit='NONE',publish='NONE',hashes={str(p.relative_to(ROOT)):sha(p) for p in paths})
(H/'FINAL-EVIDENCE.json').write_text(json.dumps(out,indent=2));print('PASS S6 R1/R2 evidence sealed; visual REVISIT; no R3/R4')
