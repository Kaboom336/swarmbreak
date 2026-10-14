"""Link final native map, audited routes, proof images, script checks and protected files."""
import json,hashlib,sys
from pathlib import Path
H=Path(__file__).resolve().parent;R=H.parents[1];O=R/'treasure/map-v4'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
d=json.loads((H/'scene.json').read_text())
a=json.loads((O/'collision-audit.json').read_text())
g=json.loads((O/'routes-graph.json').read_text())
round_id=sys.argv[1] if len(sys.argv)>1 else 'rr3final'
m=json.loads((O/f'render-r{round_id}-metadata.json').read_text())
assert a['state']==g['state']=='PASS'
assert a['violation_count_recorded']==g['dead_end_count']==0
assert a['manifest_sha256']==g['scene_sha256']==m['manifest_sha256']==sha(H/'scene.json')
baseline=json.loads((O/'ROUND3-PROTECTED-HASHES.json').read_text())
changes=[p['Path'] for p in baseline if sha(Path(p['Path'])).upper()!=p['Hash']]
protected_deltas=[{'path':p['Path'],'baseline_sha256':p['Hash'].lower(),'current_sha256':sha(Path(p['Path'])),'author':'UNKNOWN; concurrent change preserved'} for p in baseline if p['Path'] in changes]
stats=a['routes'];common=sum(stats[k]['length_studs'] for k in ['summit_radial','spiral','fork_link'])
routes={'west':common+stats['west']['length_studs'],'bridge':common+sum(stats[k]['length_studs'] for k in ['bridge','bridge_south']),
        'east':common+sum(stats[k]['length_studs'] for k in ['east','east_climb','east_descent']),
        'ravine_exit':stats['ravine_ramp']['length_studs']}
files=[R/'prototype/meadow-v4.rbxl',R/'prototype/meadow-v4.project.json',H/'scene.json',H/'round3.py',H/'Links.server.luau',H/'RavinePolicy.luau',H/'routes-check.py',H/'render.py',H/'compare.py',O/'build-sbs.jpg',O/'build-top.jpg',O/'collision-audit.json',O/'routes-graph.json',O/'ROUND3-ARTIFACT-CHECK.log',O/'ROUND3-POLICY-CHECK.log']
files += [O/f'build-r{round_id}-{n}.png' for n in ['concept','side','top','top-routes','portal','summit','portal-west','portal-east','summit-east']]
files += [O/f'render-r{round_id}-metadata.json',O/'ROUTES-CHECK.md',O/'ROUND3-CRITIC.md']
report={'scene_sha256':sha(H/'scene.json'),'place_sha256':sha(R/'prototype/meadow-v4.rbxl'),'part_count':len(d['parts']),
        'clearance_flags':a['violation_count_recorded'],'full_width_samples':a['sample_count'],'headroom_studs':20,
        'max_grade_degrees':a['max_ramp_degrees'],'graph_nodes':g['node_count'],'graph_edges':g['edge_count'],'dead_ends':g['dead_end_count'],
        'unreachable_nodes':g['unreachable_nodes'],'routes_ESTIMATED':{k:{'studs':round(v,1),'seconds_at_16':round(v/16,1)} for k,v in routes.items()},
        'protected_files_checked':len(baseline),'protected_hash_changes_preserved_author_UNKNOWN':changes,
        'protected_deltas':protected_deltas,
        'blind_reviews':{'rounds':3,'static_flow':'PASS','look':'FAIL: east jump gaps weak at decision points; major rock forms too uniform','runtime':'PENDING'},
        'proof':'Offline Blender render of exported native parts; approximate reconstructed concept camera, not Studio.',
        'static_behavior_tests':'14 executed Lune policy assertions; final place six Luau containers compile; runtime behavior not executed.',
        'UNKNOWN':['Studio walking/jumps/fall survival','real rim retrieval by competing players','actual traversal times','Keeper animation/guardian merge','multiplayer','device performance'],
        'hashes':{str(p.relative_to(R)):sha(p) for p in files}}
(O/'ROUND3-EVIDENCE.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k!='hashes'},indent=2))
