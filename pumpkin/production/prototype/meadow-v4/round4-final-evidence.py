"""Final scene/place checks and review images bound by SHA256."""
from pathlib import Path
import json,hashlib
H=Path(__file__).resolve().parent;R=H.parents[1];O=R/'treasure/map-v4'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
s=json.loads((H/'scene.json').read_text());b=json.loads((H/'round4-baseline-scene.json').read_text())
a=json.loads((O/'collision-audit.json').read_text());g=json.loads((O/'routes-graph.json').read_text())
m=json.loads((O/'render-rrr4b-metadata.json').read_text());p=json.loads((O/'ROUND4-PRESERVATION.json').read_text())
assert a['state']==g['state']=='PASS'
assert a['violation_count_recorded']==g['dead_end_count']==len(g['unreachable_nodes'])==0
assert a['manifest_sha256']==g['scene_sha256']==m['manifest_sha256']==p['scene_sha256']==sha(H/'scene.json')
assert p['place_sha256']==sha(R/'prototype/meadow-v4.rbxl')
assert s['routes']==b['routes'] and p['ravine_original_parts_changed_or_missing']==0
protected=json.loads((O/'ROUND4-PROTECTED-HASHES.json').read_text(encoding='utf-8-sig'))
deltas=[{'path':x['Path'],'baseline_sha256':x['Hash'].lower(),'current_sha256':sha(Path(x['Path'])),'author':'UNKNOWN; concurrent delta preserved'} for x in protected if sha(Path(x['Path'])).lower()!=x['Hash'].lower()]
files=[R/'prototype/meadow-v4.rbxl',H/'scene.json',H/'round4.py',H/'round4-fix.py',H/'round4-check.luau',H/'render.py',H/'compare.py',O/'build-sbs.jpg',O/'build-top.jpg',O/'collision-audit.json',O/'routes-graph.json',O/'ROUND4-CRITIC.md',O/'ROUND4-PRESERVATION.json',O/'ROUND4-SCRIPT-PRESERVATION.json',O/'ROUND4-PROTECTED-HASHES.json',O/'render-rrr4b-metadata.json']
files += [O/f'build-rrr4b-{n}.png' for n in ['concept','side','top','top-routes','ridge-jumps']]
report={'scene_sha256':sha(H/'scene.json'),'place_sha256':sha(R/'prototype/meadow-v4.rbxl'),'parts':len(s['parts']),'lanterns_before':sum(x['category']=='light' for x in b['parts']),'lanterns_after':sum(x['category']=='light' for x in s['parts']),'clearance_flags':a['violation_count_recorded'],'samples':a['sample_count'],'dead_ends':g['dead_end_count'],'unreachable_nodes':g['unreachable_nodes'],'route_metadata_unchanged':True,'original_ravine_parts_preserved':p['ravine_baseline_geometry_parts'],'protected_files_checked':len(protected),'concurrent_protected_deltas':deltas,'review_rounds':2,'critic':'ROUND4-CRITIC.md','proof':'Offline Blender native-part render; approximately reconstructed concept camera, not Studio.','runtime':'UNKNOWN','hashes':{str(f.relative_to(R)):sha(f) for f in files}}
(O/'ROUND4-EVIDENCE.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k!='hashes'},indent=2))
