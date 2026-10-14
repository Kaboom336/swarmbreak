"""Final generated evidence: artifact linkage, isolation and measured hat reserve."""
import hashlib,json,math,sys
from pathlib import Path
here=Path(__file__).resolve().parent;root=here.parents[1];out=root/'treasure/map-v4'
r=sys.argv[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
baseline=json.loads((out/'REDO-PROTECTED-HASHES.json').read_text())
changed=[p['Path'] for p in baseline if sha(Path(p['Path'])).upper()!=p['Hash']]
scene=json.loads((here/'scene.json').read_text())
audit=json.loads((out/'collision-audit.json').read_text())
render=json.loads((out/f'render-r{r}-metadata.json').read_text())
manifest_sha=sha(here/'scene.json')
assert manifest_sha==audit['manifest_sha256']==render['manifest_sha256']
assert audit['state']=='PASS'
assert render['part_count']==len(scene['parts'])
keeper=json.loads((root/'models/meadow-keeper/blender/meadow-keeper_parts.json').read_text())
hat=[v for section in keeper if section['rig_part']=='Hat' for v in section['vertices']]
bounds=[[min(v[i] for v in hat),max(v[i] for v in hat)] for i in range(3)]
diameter=math.hypot(bounds[0][1]-bounds[0][0],bounds[2][1]-bounds[2][0])
min_width=min(route['width'] for route in scene['routes'].values())
assert diameter+4<min_width
report={'round':r,'manifest_sha256':manifest_sha,'place_sha256':sha(root/'prototype/meadow-v4.rbxl'),
        'part_count':len(scene['parts']),'whole_lane_audit':audit['state'],'sample_count':audit['sample_count'],
        'flags':audit['violation_count_recorded'],'ramp_max_degrees':audit['max_ramp_degrees'],
        'min_lane_width':min_width,'hat_source_sha256':sha(root/'models/meadow-keeper/blender/meadow-keeper_parts.json'),
        'rest_hat_xyz_bounds':bounds,'conservative_horizontal_hat_diagonal':diameter,
        'hat_diagonal_plus_4_margin':diameter+4,'vertical_reservation':20,
        'protected_files_checked':len(baseline),'protected_files_changed_during_task':changed,
        'protected_scope':'No tool mutation in this task targeted these files. Concurrent workspace edits inferred from hash differences; author UNKNOWN. Changes preserved, not restored.',
        'proof':'Offline native-part/WedgePart manifest proxy; approximate concept camera. No Studio capture.',
        'UNKNOWN':['animated Keeper swept clearance','Studio traversal and jump recovery','runtime rendering and performance','actual escape timings'],
        'no_commit':True}
(out/'REDO-EVIDENCE.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
