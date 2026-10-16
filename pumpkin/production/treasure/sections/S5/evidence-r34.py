"""Seal fresh R3/R4 evidence without inheriting earlier test results."""
import json,hashlib
from pathlib import Path
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
read=lambda n:json.loads((H/n).read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
canonical=ROOT/'slice-v2/prototype/guardian-greybox.rbxl';backup=ROOT/'slice-v2/prototype/guardian-greybox.pre-s5r3.rbxl'
assert sha(backup)=='5886b84a71ed3d32e02954b64489b1702fc55bccb1378fb6f64dbcf3a122d398'
assert canonical.read_bytes()==(H/'R4-review.rbxl').read_bytes()
assert (ROOT/'prototype/meadow-v4/Section5.luau').read_bytes()==(H/'r4-Section5.luau').read_bytes()
for stage in ('r3','r4'):
 a=read('AUDIT-'+stage+'.json');s=read('SIGNATURES-'+stage+'.json')
 assert a['compiled_O0_O1_O2']==75 and a['unrelated_sources_preserved']==74 and a['workspace_exact'] and a['all_protected_signatures_exact']
 assert s['contact_errors']==0
 for view in ('base','jump','mid-bypass','overview'):
  p=H/(stage+'-'+view+'.png');assert p.stat().st_mtime>backup.stat().st_mtime
for n,phrase in [('r4-contracts.log','PASS nonzero origin'),('r34-late-kits.log','PASS S5 late kits'),('r34-50-seed-final.log','PASS 50-seed actual 3D walking-floor'),('r34-behavior.log','PASS actual production reset')]:
 raw=(H/n).read_bytes();s=raw.decode('utf-16' if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
 assert phrase in s and '[Stack Begin]' not in s,(n,s[-500:])
drop=read('final-DROPS.json');assert drop['state']=='PASS' and drop['samples']==31824 and not drop['failures'] and len(drop['all_routes_executed_exactly_once'])==20
assert all(w['input_sha256']==sha(canonical) for w in drop['workers'])
files=[canonical,backup,ROOT/'prototype/meadow-v4/Section5.luau',H.parent/'LESSONS.md']
for n in ('TARGET.png','TARGET-PROMPT.md','SBS-R3.jpg','SBS-R4.jpg','PRE-R3.jpg','PRE-R4.jpg','GAPS-R3.md','GAPS-R4.md','RESULT.md','r3.json','r4.json','r3-kits.json','r4-kits.json','SIGNATURES-r3.json','SIGNATURES-r4.json','r3-physical-contact.json','r4-physical-contact.json','r4-contracts.log','r34-late-kits.log','r34-50-seed-final.log','r34-behavior.log','final-DROPS.json'):
 files.append(H/n)
for stage in ('r3','r4'):
 for view in ('base','jump','mid-bypass','overview'):files.append(H/(stage+'-'+view+'.png'))
out=dict(technical_state='PASS offline',visual_state='REVISIT',rounds_completed=[3,4],compiled_sources_O0_O1_O2=75,unrelated_sources_preserved=74,serialized_place_exact_except_Section5_Source=True,collider_lane_geometry_tags_attributes_exact=True,solid_edits='authorized colour/material only',native_contact_errors=0,new_fitted_kit_envelopes_audited=True,DropSample_cases=31824,DropSample_routes=20,DropSample_failures=0,target='built-in imagegen from both supplied live cameras',live_Studio='UNKNOWN',live_vs_offline_jump_wall_parity='UNRESOLVED',commit='NONE',publish='NONE',hashes={str(p.relative_to(ROOT)):sha(p) for p in files})
(H/'FINAL-R34-EVIDENCE.json').write_text(json.dumps(out,indent=2));print('PASS fresh S5 R3/R4 evidence; 31824 drops / 20 routes / 0 failures; visual REVISIT')
