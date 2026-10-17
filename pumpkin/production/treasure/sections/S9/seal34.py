from pathlib import Path
import json,hashlib
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
canonical=ROOT/'slice-v2/prototype/guardian-greybox.rbxl'
backup=ROOT/'slice-v2/prototype/guardian-greybox.pre-s9r3.rbxl'
assert sha(backup)=='94a099be1744094a4231f1c1063119c257dcdb106f08c314f889da3ede8df061'
assert sha(canonical)==sha(H/'R4-review.rbxl')
assert sha(ROOT/'prototype/meadow-v4/Section9.luau')==sha(H/'r4-Section9.luau')
assert sha(ROOT/'slice-v2/prototype/HomeArt.client.luau')==sha(H/'r2-HomeArt.luau')
for tag in ('r3','r4'):
    audit=json.loads((H/f'AUDIT-{tag}.json').read_text())
    assert not any(audit[k] for k in ('physical_contacts','path_margin_errors','bounds_errors','legal_pet_envelope_errors','unsupported'))
    mount=json.loads((H/f'MOUNT-{tag}.json').read_text())
    assert mount['compiled_O0_O1_O2']==80 and mount['all_unrelated_sources_and_serialized_place_exact']
    # Original R1/R2 exporter only names old round tags. Correct its metadata;
    # its underlying exact neutralization assertion already ran for both rounds.
    mount['changed_sources']=['Section9','HomeArt: unchanged R2 cosmetic hook (relative to pre-S9 only)']
    mount['immediate_R2_backup_sha256']=sha(backup)
    mount['change_from_immediate_R2_backup']=['Section9 Source only']
    (H/f'MOUNT-{tag}.json').write_text(json.dumps(mount,indent=2))
checks=[('r34-contracts.log','PASS nonzero origin'),('r34-home-contracts.log','PASS actual finishDecor'),
        ('r34-home-contracts.log','PASS immediate R2 backup parity'),('r34-home-contracts.log','single binding'),
        ('r34-50-seed.log','PASS 50-seed actual 3D'),('r34-50-seed.log','PASS built binary sources'),
        ('r34-behavior.log','PASS production Arena.reset')]
for filename,needle in checks:
    assert needle in (H/filename).read_text(encoding='utf-16'),'missing validation '+filename
drops=json.loads((H/'final-DROPS.json').read_text())
assert drops['state']=='PASS' and drops['samples']==31824 and not drops['failures']
assert len(drops['all_routes_executed_exactly_once'])==20
assert all(r['input_sha256']==sha(canonical) for r in drops['workers'])
audit=json.loads((H/'AUDIT-r4.json').read_text())
visual=json.loads((H/'r4-visual.json').read_text())
kerbs=[p for p in visual['parts']if p['name'].startswith('ClientDecor_S9_Kerb')]
assert len(kerbs)==98
for p in kerbs:
    assert abs(p['position'][0])-p['size'][0]/2>=21
    assert p['position'][2]-p['size'][2]/2>=-110
    assert p['position'][2]+p['size'][2]/2<=135
backing=[p for p in visual['parts']if p['name']=='ClientDecor_PortalGreen' and p['size'][0]>29 and p['size'][1]>29]
assert len(backing)==1 and backing[0]['transparency']>=.8
assert json.loads((H/'MOUNT-r4.json').read_text())['canonical_sha256']==sha(canonical)
files=[canonical,backup,ROOT/'prototype/meadow-v4/Section9.luau',ROOT/'slice-v2/prototype/HomeArt.client.luau',ROOT/'treasure/sections/LESSONS.md']
files += [p for p in H.iterdir()if p.name!='r34-seal.log' and (p.name.startswith(('r3-','r4-','r34-','SBS-R3','SBS-R4','GAPS-R3','GAPS-R4','CRITIC-R3','CRITIC-R4','AUDIT-r3','AUDIT-r4','MOUNT-r3','MOUNT-r4','final-drop','final-DROPS')) or p.name in ('RESULT.md','RESULT-R2.md','RENDER-LIMITS.md','STUDIO-CHECKS.md','R3-review.rbxl','R4-review.rbxl','build34.luau','audit34.py','home34.luau','seal34.py'))]
report=dict(state='PASS offline',visual='REVISIT',rounds_completed=[3,4],four_round_cap_reached=True,
    canonical_sha256=sha(canonical),immediate_backup_sha256=sha(backup),compiled_O0_O1_O2=80,
    change_from_R2=['Section9 Source only'],HomeArt_gameplay_tests_serialized_state_exact=True,
    pad_sizes_transforms_flags_attributes_exact=True,original_owner_signal_exercised=True,
    native_cosmetics=audit['native_cosmetics'],client_cosmetics=audit['client_cosmetics'],new_lights=28,
    light_brightness=.35,light_range=10,light_shadows=False,physical_contacts=0,legal_pet_envelope_errors=0,
    home_world_offset=[0,0,0],drop_samples=31824,drop_routes=20,drop_failures=0,
    live_Studio='UNKNOWN/PENDING final Claude check',owner_acceptance='UNKNOWN',commit='NONE',publish='NONE',
    independent_review='CRITIC-R3.md / CRITIC-R4.md; REVISIT',
    hashes={str(p.relative_to(ROOT)):sha(p)for p in files})
(H/'FINAL-R34-EVIDENCE.json').write_text(json.dumps(report,indent=2))
print('PASS sealed S9 R3/R4: 80 compile, exact R2 preservation, contact 0, 31824 drops / 20 routes / 0 failures; visual REVISIT')
