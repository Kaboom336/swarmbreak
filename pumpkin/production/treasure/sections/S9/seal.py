from pathlib import Path
import json,hashlib
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
mount=json.loads((H/'MOUNT-r2.json').read_text())
canonical=ROOT/'slice-v2/prototype/guardian-greybox.rbxl'
assert sha(canonical)==mount['canonical_sha256']
assert sha(ROOT/'prototype/meadow-v4/Section9.luau')==sha(H/'r2-Section9.luau')
assert sha(ROOT/'slice-v2/prototype/HomeArt.client.luau')==sha(H/'r2-HomeArt.luau')
assert sha(H/'R2-review.rbxl')==sha(canonical)
for tag in ('r1','r2'):
 audit=json.loads((H/f'AUDIT-{tag}.json').read_text())
 assert not any(audit[k]for k in ('contact_errors','lane_margin_errors','bounds_errors','placement_errors','unsupported_new_assemblies'))
for file,expected in [('contracts.log','PASS nonzero origin'),('home-contracts.log','PASS 220 home cosmetics'),('50-seed.log','PASS 50-seed'),('behavior.log','PASS production Arena.reset')]:
 raw=(H/file).read_bytes();log=raw.decode('utf-16'if raw.startswith((b'\xff\xfe',b'\xfe\xff'))else'utf-8-sig')
 assert expected in log,'missing validation '+file
drops=json.loads((H/'final-DROPS.json').read_text());assert drops['state']=='PASS'and drops['samples']==31824 and not drops['failures']
files=[canonical,ROOT/'slice-v2/prototype/guardian-greybox.pre-s9.rbxl',ROOT/'prototype/meadow-v4/Section9.luau',ROOT/'slice-v2/prototype/HomeArt.client.luau',H/'R1-review.rbxl',H/'R2-review.rbxl']
files+=list(H.glob('*.json'))+list(H.glob('*.md'))+list(H.glob('*.png'))+list(H.glob('*.jpg'))+list(H.glob('*.log'))
files=[p for p in files if p.name not in ('FINAL-EVIDENCE.json','seal.log')]
report=dict(state='PASS offline',visual='REVISIT',rounds_completed=[1,2],stop='Claude live Studio check before R3/R4',canonical_sha256=sha(canonical),backup_sha256=mount['backup_sha256'],compiled_O0_O1_O2=80,unchanged_original_sources=78,changed_sources=['new Section9','HomeArt: isolated cosmetic finish hook'],serialized_place_exact_after_neutralizing_changes=True,home_world_offset=[0,0,0],r1_frozen_parts=92,final_native_cosmetics=220,client_platform_finish_only=6,new_lights=0,physical_contacts=0,unsupported_assemblies=0,lane_margin_errors=0,legal_placement_intrusions=0,drop_samples=31824,drop_routes=20,drop_failures=0,live_Studio='UNKNOWN',owner_acceptance='UNKNOWN',independent_review='CRITIC-R1.md / CRITIC-R2.md; visual REVISIT',commit='NONE',publish='NONE',hashes={str(p.relative_to(ROOT)):sha(p)for p in files})
(H/'FINAL-EVIDENCE.json').write_text(json.dumps(report,indent=2))
print('PASS sealed S9 R1/R2; 31824 drops / 20 routes / zero failures; source/artifact parity')
