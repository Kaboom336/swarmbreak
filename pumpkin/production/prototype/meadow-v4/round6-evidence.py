"""Bind actual evidence; assertions do not establish engine playability."""
import json,hashlib,collections,importlib.util
from pathlib import Path
H=Path(__file__).parent;R=H.parents[1];O=R/'treasure/map-v4'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
s=read(H/'scene.json');b=read(H/'round6-baseline-scene.json');digest=sha(H/'scene.json')
def sig(p):return json.dumps(p,sort_keys=True,separators=(',',':'))
assert not collections.Counter(map(sig,b['parts']))-collections.Counter(map(sig,s['parts'])),'baseline part modified/removed'
assert s['routes']==b['routes'] and s['r5']==b['r5'] and s['tunnel']==b['tunnel']
p=read(O/'ROUND6-PLACEMENT.json');a=read(O/'collision-audit.json');graph=read(O/'routes-graph.json');render=read(O/'render-rr6b-metadata.json')
legacy_before=read(O/'ROUND6-LEGACY-BEFORE.json');legacy_after=read(O/'ROUND6-LEGACY-AFTER.json')
assert all(legacy_before[k]==legacy_after[k] for k in ['floating','path_intrusions','main_width_errors'])
assert p['scene_sha256']==a['manifest_sha256']==graph['scene_sha256']==render['manifest_sha256']==digest
defects=['unclassified_prop_parts','overlap_pairs','floating','sunk','unsupported','path_intrusions','flowers_off_path_edge','construction_clipping_parts','disconnected_assemblies','fence_gaps_or_stubs','main_width_errors','jump_pad_errors']
assert all(p[k]==0 for k in defects)
assert a['violation_count_recorded']==a['nominal_surface_difference_count']==graph['dead_end_count']==len(graph['unreachable_nodes'])==0
assert read(O/'render-rr6route-metadata.json')['manifest_sha256']==digest
checks=[]
for row in read(O/'ROUND6-PROTECTED-HASHES.json'):
 now=sha(Path(row['Path']));checks.append({'path':row['Path'],'unchanged':now==row['Hash'].lower(),'before':row['Hash'].lower(),'after':now})
assert all(x['unchanged'] for x in checks),'protected hashes changed externally or in task; investigate'
spec=importlib.util.spec_from_file_location('pa',H/'placement-audit.py');pa=importlib.util.module_from_spec(spec);spec.loader.exec_module(pa)
groups={x['id']:x for x in pa.groups(s['parts'])};inventory={}
for name,ids in s['r6']['clusters'].items():
 kinds=collections.Counter(groups[x]['kind'] for x in ids)
 sizes=sorted(set(round(next(p for p in groups[x]['parts'] if p.get('root'))['size'][1],3) for x in ids if groups[x]['kind']=='tree'))
 inventory[name]={'members':len(ids),'kinds':dict(kinds),'tree_heights':sizes,'complete':kinds['tree']>=2 and len(sizes)>=2 and kinds['bush']>=1 and kinds['boulder']>=1 and kinds['flower']>=1}
files=[H.parent/'meadow-v4.rbxl',H/'scene.json',H/'round6.py',H/'placement-audit.py',H/'render.py',O/'build-sbs.jpg',O/'build-ground.jpg',O/'build-route-ground.jpg',O/'ROUND6-CRITIC.md']
files+=[H/'round6-audit.py',H/'round6-check.luau',H/'round6-sheets.ps1',H/'round6-evidence.py',O/'ROUND6.md',O/'ROUND6-PLACEMENT.json',O/'ROUND6-LEGACY-BEFORE.json',O/'ROUND6-LEGACY-AFTER.json',O/'collision-audit.json',O/'routes-graph.json',O/'TUNNEL-CONTACTS.json',O/'ROUND6-ARTIFACT.json',O/'TUNNEL-TEST.json',O/'render-rr6b-metadata.json',O/'render-rr6route-metadata.json']
files+=list(O.glob('build-rr6b-*.png'))+list(O.glob('build-rr6route-*.png'))
report={'state':'STATIC_PASS','runtime':'UNKNOWN in Studio','scene_sha256':digest,'place_sha256':sha(H.parent/'meadow-v4.rbxl'),'baseline_parts_byte_equal_in_manifest':len(b['parts']),'routes_underside_tunnel_preserved':True,'prop_defects':{k:p[k] for k in defects},'clearance':0,'dead_ends':0,'lane_samples':a['sample_count'],'artifact':read(O/'ROUND6-ARTIFACT.json'),'cluster_count':len(inventory),'complete_cluster_count':sum(c['complete'] for c in inventory.values()),'clusters':inventory,'hedges':s['r6']['hedges'],'ravine_rim_bushes':s['r6']['rim_bushes'],'grass_tufts':s['r6']['tufts'],'protected':checks,'render_source':'Offline exact-native-manifest Cycles; nominal route eye height5.5; not engine screenshots','hashes':{str(f.relative_to(R)):sha(f) for f in files}}
assert 40<=len(inventory)<=60 and all(c['complete'] for c in inventory.values())
report['audit_scope']=p['scope']
report['blind_visual_review']={'placement_score':7.3,'out_of':10,'rounds':2,'target':7,'verdict':'PASS_OFFLINE_PLACEMENT','scope':'Four supplied references, concept/top and nine principal eye views. Twenty route-eye views supplementary; Studio UNKNOWN.'}
report['inherited_raw_legacy_flags_unchanged']={k:legacy_after[k] for k in ['floating','path_intrusions','main_width_errors']}
report['legacy_note']='20 attached tunnel-light meshes misclassified as standalone props, 6 of their envelopes project across surface-lane reserves, and 2 tunnel widths14 flagged by old surface-only18 rule. These are retained and disclosed, not moved or silently cleared. Tunnel decorative stem-ground contact remains outside the surface planting audit.'
(O/'ROUND6-EVIDENCE.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k not in {'clusters','protected','hashes'}},indent=2))
