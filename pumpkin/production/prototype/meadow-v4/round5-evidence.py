"""Final evidence bindings. No guardian/animation mutations; original terrain preserved."""
import json,hashlib,collections,importlib.util
from pathlib import Path
H=Path(__file__).parent;O=H.parents[1]/'treasure/map-v4';R=H.parents[1]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
scene=read(H/'scene.json');baseline=read(H/'round5-baseline-scene.json');digest=sha(H/'scene.json')
audit=read(O/'collision-audit.json');graph=read(O/'routes-graph.json');props=read(O/'ROUND5-PLACEMENT-AFTER.json');artifact=read(O/'ROUND5-ARTIFACT.json');meta=read(O/'render-rr5final-metadata.json')
assert audit['manifest_sha256']==graph['scene_sha256']==props['scene_sha256']==meta['manifest_sha256']==digest
assert audit['violation_count_recorded']==audit['nominal_surface_difference_count']==graph['dead_end_count']==len(graph['unreachable_nodes'])==0
defects=['unclassified_prop_parts','overlap_pairs','floating','sunk','unsupported','path_intrusions','flowers_off_path_edge','construction_clipping_parts','disconnected_assemblies','fence_gaps_or_stubs','main_width_errors','jump_pad_errors']
assert all(props[k]==0 for k in defects)
assert scene['routes']==baseline['routes']
def signature(p):return json.dumps(p,sort_keys=True,separators=(',',':'))
original=collections.Counter(signature(p) for p in baseline['parts'] if p['collidable'] and p['category'] in {'terrace','lane','bridge','jump_access','court','portal','protected','jump'})
current=collections.Counter(signature(p) for p in scene['parts'])
assert not original-current,'original physical terrain/lane/jump geometry changed'
protected=read(O/'ROUND5-PROTECTED-HASHES.json');checks=[]
for p in protected:
 now=sha(Path(p['Path']));checks.append({'path':p['Path'],'baseline_sha256':p['Hash'].lower(),'final_sha256':now,'unchanged':p['Hash'].lower()==now})
assert all(p['unchanged'] for p in checks),'protected raw hash delta; investigate without restoring'
sp=importlib.util.spec_from_file_location('pa',H/'placement-audit.py');pa=importlib.util.module_from_spec(sp);sp.loader.exec_module(pa)
def hit(a,b,p,pad=1.5):
 bounds=pa.bounds(p);lo=0;hi=1
 for i in range(3):
  delta=b[i]-a[i]
  if abs(delta)<1e-8:
   if not bounds[i]-pad<=a[i]<=bounds[i+3]+pad:return False
  else:
   x=(bounds[i]-pad-a[i])/delta;y=(bounds[i+3]+pad-a[i])/delta
   lo=max(lo,min(x,y));hi=min(hi,max(x,y))
   if hi<lo:return False
 return True
tree_flags=[]
for label,lines in [('portal',scene['r5']['sightlines']),('throw-chord',scene['r5']['throw_chords'])]:
 for index,(a,b) in enumerate(lines):
  for p in scene['parts']:
   if p['category']!='tree' or label=='portal' and index==0 and p.get('landmark_target'):continue
   if hit(a,b,p):tree_flags.append({'ray':label,'index':index,'assembly':p.get('assembly'),'part':p['name']})
assert not tree_flags,'selected tree sightline/chord reservation violated'
route_names=list(scene['routes']);views=['concept','side','top','under','under-south','under-west','under-north','under-east']
views+=['eye-'+n for n in ['portal-west','portal-bridge','portal-east','west','bridge','east','summit','shelf','recovery']]
views+=['eye-route-'+n for n in route_names]
files=[O/f'build-rr5final-{n}.png' for n in views]
files += [O/n for n in ['build-sbs.jpg','build-top.jpg','build-under.jpg','build-ground.jpg','build-route-ground.jpg','REVIEW-R5.md','ROUND5-CRITIC.md','ROUND5-STUDIO-CHECKS.md','ROUND5-PLACEMENT-BEFORE.json','ROUND5-PLACEMENT-AFTER.json','ROUND5-ARTIFACT.json']]
files += [O/'ROUND5.md',O/'ROUND5-GEOMETRY.json',O/'r5-r5final-cameras.json',H/'scene.json',H/'round5.py',H/'placement-audit.py',H/'render.py',H/'round5-check.luau',H/'round5-evidence.py',H.parent/'meadow-v4.rbxl']
assert all(f.exists() for f in files)
report={'state':'STATIC PASS; visual verdict in ROUND5-CRITIC.md','scene_sha256':digest,'place_sha256':sha(H.parent/'meadow-v4.rbxl'),'artifact':artifact,'parts':len(scene['parts']),'before':{k:read(O/'ROUND5-PLACEMENT-BEFORE.json')[k] for k in ['assemblies','parts_in_prop_audit']+defects},'after':{k:props[k] for k in ['assemblies','parts_in_prop_audit']+defects},'lane_samples':audit['sample_count'],'clearance_flags':0,'nominal_surface_difference_flags':0,'dead_ends':0,'unreachable':0,'original_physical_parts_preserved':sum(original.values()),'routes_equal':True,'selected_portal_tree_rays':len(scene['r5']['sightlines']),'selected_throw_tree_chords':len(scene['r5']['throw_chords']),'selected_tree_blockers':0,'tree_check_limits':'Selected straight chords with1.5-stud envelope pad, not every route sample or ballistic/animated throws; terrain occlusion and real Keeper throws require Studio.','clusters':{k:len(v) for k,v in scene['r5']['clusters'].items()},'lantern_pairs':scene['r5']['lantern_pairs'],'protected_files':checks,'protected_animation_scope':'No task command wrote Keeper animation/art files. Exact raw baseline comparison available for24 listed guardian files; animation files were not captured at task start, so whole-animation-directory byte equality is not claimed.','review_rounds':3,'image_count':len(views),'render_source':'Same exported native manifest; offline Cycles. Main and18 route cameras5.5 above authored nominal route, not engine avatar-camera captures.','runtime':'UNKNOWN','hashes':{str(f.relative_to(R)):sha(f) for f in files}}
(O/'ROUND5-EVIDENCE.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k not in {'hashes','protected_files','clusters','lantern_pairs'}},indent=2))
