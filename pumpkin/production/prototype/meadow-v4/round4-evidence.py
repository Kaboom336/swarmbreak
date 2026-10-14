import json,hashlib,collections
from pathlib import Path
P=Path(__file__).parent;O=P.parents[1]/'treasure/map-v4'
a=json.loads((P/'round4-baseline-scene.json').read_text());b=json.loads((P/'scene.json').read_text())
def sig(p):return json.dumps(p,sort_keys=True,separators=(',',':'))
def in_ravine(p):return abs(p['position'][0])<90 and abs(p['position'][2])<35 and p['category'] not in {'lantern','light'}
old=collections.Counter(sig(p) for p in a['parts'] if in_ravine(p));new=collections.Counter(sig(p) for p in b['parts'] if in_ravine(p))
missing=old-new
assert not missing,'original ravine geometry changed'
assert a['routes']==b['routes'],'route metadata changed'
protected=json.loads((O/'ROUND4-PROTECTED-HASHES.json').read_text(encoding='utf-8-sig'))
checks=[]
for p in protected:
 now=hashlib.sha256(Path(p['Path']).read_bytes()).hexdigest().upper()
 checks.append({'path':p['Path'],'unchanged':now==p['Hash'],'sha256':now})
unexpected=[p for p in checks if not p['unchanged'] and not p['path'].endswith('guardian-greybox.rbxl')]
assert not unexpected,'unexpected protected source file delta'
concurrent=[{**p,'author':'UNKNOWN','note':'Concurrent guardian-greybox delta reported by coordinator; this task did not write or restore it.'} for p in checks if not p['unchanged']]
audit=json.loads((O/'collision-audit.json').read_text());graph=json.loads((O/'routes-graph.json').read_text())
assert audit['violation_count_recorded']==0 and graph['dead_end_count']==0 and not graph['unreachable_nodes']
report={'state':'PASS','scene_sha256':hashlib.sha256((P/'scene.json').read_bytes()).hexdigest(),'place_sha256':hashlib.sha256((P.parent/'meadow-v4.rbxl').read_bytes()).hexdigest(),'routes_byte_equivalent':True,'ravine_baseline_geometry_parts':sum(old.values()),'ravine_original_parts_changed_or_missing':len(missing),'ravine_selection':'original parts centred abs(X)<90 abs(specZ)<35 excluding lantern/light decorations; all retained byte-equivalent','clearance':audit['violation_count_recorded'],'dead_ends':graph['dead_end_count'],'unreachable':len(graph['unreachable_nodes']),'protected_files':checks,'Studio_runtime':'UNKNOWN'}
report['concurrent_protected_deltas']=concurrent
(O/'ROUND4-PRESERVATION.json').write_text(json.dumps(report,indent=2))
print('PASS protected files',len(checks),'ravine parts',sum(old.values()),'routes',len(a['routes']))
