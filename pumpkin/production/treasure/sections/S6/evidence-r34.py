"""Seal current final hashes and fresh checks; offline evidence is not acceptance."""
import json,hashlib
from pathlib import Path
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda n:json.loads((H/n).read_text(encoding='utf-8-sig'))
canonical=ROOT/'slice-v2/prototype/guardian-greybox.rbxl';backup=ROOT/'slice-v2/prototype/guardian-greybox.pre-s6r3.rbxl'
assert sha(backup)=='7dddaa90353efcb060943c480485dbdcab05a59b3cadc4de75856e900f2eb4dc'
assert canonical.read_bytes()==(H/'R4-review.rbxl').read_bytes()
assert sha(canonical)==read('R34-TEST-INPUT.json')['canonical_sha256']
assert sha(ROOT/'prototype/meadow-v4/Section6.luau')==read('R34-TEST-INPUT.json')['section6_source_sha256']
assert (ROOT/'prototype/meadow-v4/Section6.luau').read_bytes()==(H/'r4-Section6.luau').read_bytes()
for stage in ('r3','r4'):
 assert read('SIGNATURES-'+stage+'.json')['contact_errors']==0
 assert read('AUDIT-'+stage+'.json')['unrelated_sources_preserved']==75
 for view in ('entry','mid-up','shelf-down','overview'):
  p=H/f'{stage}-{view}.png';assert p.stat().st_mtime>backup.stat().st_mtime
 assert read('RENDER-'+stage+'.json')['views']==read('CAMERAS.json')
def log(n):
 b=(H/n).read_bytes();return b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
for n,phrase in [('r34-contracts.log','PASS nonzero origin'),('r34-behavior.log','PASS production Arena.reset and overlapping path completion epochs'),('r34-50-seed.log','PASS 50-seed actual 3D walking-floor'),('r34-late-kits.log','PASS S6 late kits')]:
 text=log(n);assert phrase in text and '[Stack Begin]' not in text,(n,text[-700:])
drop=read('final-DROPS.json');assert drop['state']=='PASS' and drop['samples']==31824 and len(drop['all_routes_executed_exactly_once'])==20 and not drop['failures']
assert all(w['input_sha256']==sha(canonical) for w in drop['workers'])
paths=[canonical,backup,ROOT/'prototype/meadow-v4/Section6.luau',H.parent/'LESSONS.md']
for n in ('RESULT.md','GAPS-R3.md','GAPS-R4.md','TARGET.png','SBS-R3.jpg','SBS-R4.jpg','SBS-R3-phone.jpg','SBS-R4-phone.jpg','R3-review.rbxl','R4-review.rbxl','SIGNATURES-r3.json','SIGNATURES-r4.json','r3-physical-contact.json','r4-physical-contact.json','r34-contracts.log','r34-behavior.log','r34-50-seed.log','r34-late-kits.log','final-DROPS.json','build-r34.luau','plan-r34.py','plan-r4.py','verify-r34.py','contact-r34.py','geometry-r34.py','drop-r34.luau','evidence-r34.py'):
 paths.append(H/n)
for stage in ('r3','r4'):
 for view in ('entry','mid-up','shelf-down','overview'):paths.append(H/f'{stage}-{view}.png')
for n in ('STUDIO-CHECKS.md','R34-TEST-INPUT.json','r34-drop-1.log','r34-drop-2.log','r34-drop-3.log','final-DROPS-1.json','final-DROPS-2.json','final-DROPS-3.json'):
 paths.append(H/n)
out=dict(technical_state='PASS offline',visual_state='REVISIT',rounds_completed=[3,4],compiled_sources_O0_O1_O2=76,unrelated_sources_preserved=75,serialized_place_exact_except_Section6_Source=True,all_lane_geometry_and_signatures_exact=True,solid_edits='colour/material only on explicit owned cliff bodies',contact_errors=0,contact_method='actual convex native boxes/wedges at unchanged .035-stud tolerance; original conservative contact.py retained',kerb_and_warning_posts='nonphysical surface trim in existing edging footprint; exempt only from prop setback',new_fitted_kit_envelopes=len(read('r4-kits.json')),new_native_cosmetics=read('SIGNATURES-r4.json')['new_native_cosmetics'],DropSample_cases=31824,DropSample_routes=20,DropSample_failures=0,live_Studio='UNKNOWN',independent_Claude_final_review='PENDING',owner_acceptance='UNKNOWN',R3_late_kit_failure='retained in r3-late-kits.log; corrected and rerun on final R4',commit='NONE',publish='NONE',hashes={str(p.relative_to(ROOT)):sha(p) for p in paths})
(H/'FINAL-R34-EVIDENCE.json').write_text(json.dumps(out,indent=2));print('PASS final R3/R4 evidence; visual REVISIT')
