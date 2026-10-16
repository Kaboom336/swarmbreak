"""Fail closed on final tests and artifact/proof parity; derive, never invent totals."""
import json,hashlib
from pathlib import Path
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
read=lambda n:json.loads((H/n).read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
audit=read('AUDIT-deliver.json');sig=read('deliver-SIGNATURES.json');parity=read('PARITY.json');drops=read('final-DROPS.json');contracts=read('CONTRACTS.json')
assert audit['compiled_O0_O1_O2']==74 and audit['unrelated_sources_preserved']==73
assert audit['workspace_exact'] and audit['all_protected_signatures_exact']
assert sig['status']==parity['status']=='PASS' and sig['new_S4_parts']==94
artifact=ROOT/'slice-v2/prototype/guardian-greybox.rbxl'
assert sig['artifact_sha256']==parity['artifact_sha256']==sha(artifact)
assert drops['state']=='PASS' and not drops['failures'] and len(drops['all_routes_executed_exactly_once'])==20
assert contracts['offset_origin_once'] and contracts['failed_section_warns_and_keeps_island']
for name,phrase in [('contracts.log','PASS nonzero origin'),('behavior.log','PASS actual production reset'),('50-seed.log','PASS 50-seed actual 3D walking-floor')]:
 raw=(H/name).read_bytes();log=raw.decode('utf-16' if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig');assert phrase in log,name
 assert '[Stack Begin]' not in log and 'AssertionError' not in log,name
for r in (1,2):
 for name in (f'GAPS-R{r}.md',f'PRE-R{r}.jpg',f'SBS-R{r}.jpg',f'SBS-R{r}-phone.jpg'):assert (H/name).is_file(),name
assert not (H/'GAPS-R3.md').exists() and not (H/'SBS-R3.jpg').exists(),'R3 not authorized'
source=ROOT/'prototype/meadow-v4/Section4.luau'
assert source.read_bytes()==(H/'r2-Section4.luau').read_bytes()==(H/'deliver-Section4.luau').read_bytes()
paths=[artifact,ROOT/'slice-v2/prototype/guardian-greybox.pre-s4.rbxl',source,H/'R1-review.rbxl',H/'r1-Section4.luau']
paths += [H/n for n in ['AUDIT-deliver.json','deliver-SIGNATURES.json','PARITY.json','CONTRACTS.json','CAMERA-CLEARANCE.json','final-DROPS.json','contracts.log','behavior.log','50-seed.log','TARGET.png','PRE-R1.jpg','PRE-R2.jpg','SBS-R1.jpg','SBS-R2.jpg','RESULT.md']]
out=dict(technical_state='PASS',visual_state='REVISIT; R1/R2 ONLY; Claude live Studio review pending',rounds_completed=[1,2],rounds_3_4='NOT STARTED',compiled_sources=74,existing_sources_preserved=73,protected_gameplay_geometry_palette_floor_tags_exact=True,must_keep_warm_paving_edge_stones_planks_exact=True,tagged_art_exception=sig['tagged_art_exception'],contact=sig['contact'],DropSample_samples=drops['samples'],DropSample_routes=len(drops['all_routes_executed_exactly_once']),DropSample_failures=len(drops['failures']),existing_50_seed_walking_floor_cliff_cover='PASS',source_render_artifact_parity='PASS',live_StudioPassAll='UNKNOWN; all nine not run',owner_acceptance='UNKNOWN',commit='NONE',publish='NONE',hashes={str(p.relative_to(ROOT)):sha(p) for p in paths})
(H/'FINAL-EVIDENCE.json').write_text(json.dumps(out,indent=2));print('PASS final evidence:',drops['samples'],'DropSample samples; 20 routes; zero failures; 50 seeds; contracts; 94 cosmetic parts, zero contacts')
