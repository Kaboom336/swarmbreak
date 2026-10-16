"""Record checked evidence without treating offline proxies as Studio acceptance."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent
ROOT=H.parents[2]
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
canonical=ROOT/'slice-v2/prototype/guardian-greybox.rbxl'
backup=ROOT/'slice-v2/prototype/guardian-greybox.pre-s5.rbxl'
assert sha(backup)==read(H/'BACKUP.json')['backup'].lower()
assert sha(backup)==read(ROOT/'treasure/PERF-BUILD.json')['canonical_sha256']
assert (ROOT/'prototype/meadow-v4/Section5.luau').read_bytes()==(H/'r2-Section5.luau').read_bytes()
assert canonical.read_bytes()==(H/'R2-review.rbxl').read_bytes()
for stage in ('r1','r2'):
 a=read(H/f'AUDIT-{stage}.json');s=read(H/f'SIGNATURES-{stage}.json')
 assert a['compiled_O0_O1_O2']==75 and a['unrelated_sources_preserved']==74
 assert a['workspace_exact'] and a['all_protected_signatures_exact'] and s['contact_errors']==0
 for view in ('base','mid-bypass','jump','overview'):assert (H/f'{stage}-{view}.png').is_file()
 for kind in ('PRE','SBS'):assert (H/f'{kind}-R{stage[-1]}.jpg').is_file()
drop=read(H/'final-DROPS.json')
assert drop['state']=='PASS' and drop['samples']==31824 and not drop['failures']
for w in drop['workers']:assert w['input_sha256']==sha(canonical)
def log(f):
 raw=(H/f).read_bytes()
 return raw.decode('utf-16' if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig')
assert 'PASS nonzero origin' in log('contracts.log')
assert 'PASS actual production reset:' in log('behavior.log')
assert 'PASS built binary sources' in log('50-seed.log')
paths=[canonical,backup,ROOT/'prototype/meadow-v4/Section5.luau',H/'R1-review.rbxl',H/'R2-review.rbxl',H/'before.json',H/'r1.json',H/'r2.json']
for stage in ('before','r1','r2'):
 for view in ('base','mid-bypass','jump','overview'):
  image=H/f'{stage}-{view}.png'
  assert image.stat().st_mtime>backup.stat().st_mtime,'stale camera evidence'
  paths.append(image)
paths.extend(H/f for f in ('PRE-R1.jpg','PRE-R2.jpg','SBS-R1.jpg','SBS-R2.jpg','SBS-R1-phone.jpg','SBS-R2-phone.jpg','contracts.log','behavior.log','50-seed.log','final-DROPS.json','SIGNATURES-r1.json','SIGNATURES-r2.json'))
out=dict(technical_state='PASS offline',visual_state='REVISIT; stop for Claude live Studio review',rounds_completed=[1,2],sources_compiled_O0_O1_O2=75,unrelated_sources_preserved=74,pre_s5_matches_perf_canonical=True,server_speed_fix_and_build_yields_preserved=True,serialized_workspace_and_kits_exact=True,protected_geometry_and_mustkeep_art_exact=True,r1_silhouette_frozen=True,contact_errors=0,DropSample_samples=drop['samples'],DropSample_routes=len(drop['all_routes_executed_exactly_once']),DropSample_failures=0,live_Studio='UNKNOWN',live_carry_recovery='UNKNOWN',owner_acceptance='UNKNOWN',commit='NONE',publish='NONE',hashes={str(p.relative_to(ROOT)):sha(p) for p in paths})
(H/'FINAL-EVIDENCE.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out,indent=2))
