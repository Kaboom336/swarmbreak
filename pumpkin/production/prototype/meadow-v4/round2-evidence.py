"""Link the final place, proof, full-width audit, routes and protected baseline."""
import json,hashlib,math
from pathlib import Path
H=Path(__file__).resolve().parent;R=H.parents[1];O=R/'treasure/map-v4'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
d=json.loads((H/'scene.json').read_text());a=json.loads((O/'collision-audit.json').read_text());m=json.loads((O/'render-rr2final-metadata.json').read_text())
assert a['state']=='PASS' and a['violation_count_recorded']==0
assert a['manifest_sha256']==m['manifest_sha256']==sha(H/'scene.json')
stats=a['routes']
common=sum(stats[k]['length_studs'] for k in ['summit_radial','spiral','fork_link'])
routes={
 'West main':common+stats['west']['length_studs'],
 'Centre bridge':common+sum(stats[k]['length_studs'] for k in ['bridge','bridge_south']),
 'East walking':common+sum(stats[k]['length_studs'] for k in ['east','east_climb','east_descent']),
 'Shelf walking + west':sum(stats[k]['length_studs'] for k in ['summit_radial','shelf','shelf_link','west']),
 'Shelf walking + bridge':sum(stats[k]['length_studs'] for k in ['summit_radial','shelf','shelf_link','bridge','bridge_south'])}
assert 25<=routes['West main']/16<=35
# Ray against oriented visible boxes, including noncolliding scenery. A visibility
# test for the hat and flags, not a rendered player-camera or animation claim.
eye=(0,5,128)
def ray_box(p,target):
    r=p['rotation'];c=p['position'];s=p['size'];lo=0;hi=1
    for j in range(3):
        origin=sum(r[i*3+j]*(eye[i]-c[i]) for i in range(3));delta=sum(r[i*3+j]*(target[i]-eye[i]) for i in range(3))
        if abs(delta)<1e-10:
            if abs(origin)>s[j]/2:return False
        else:
            u=(-s[j]/2-origin)/delta;v=(s[j]/2-origin)/delta;lo=max(lo,min(u,v));hi=min(hi,max(u,v))
            if lo>hi:return False
    return hi>.002 and lo<.995
targets={'Keeper hat':(-7,61,-114),'Camp banner left':(-12,60,-126),'Camp banner right':(16,60,-126)}
sight={}
for name,target in targets.items():
    blocked=[p['name'] for p in d['parts'] if p['category'] not in {'keeper','banner','portal_glow','portal_arch','background','paving','edging','grass','terrain_cap','path_rock'} and not p['transparency'] and ray_box(p,target)]
    sight[name]={'eye_XYZ':eye,'target_XYZ':target,'blocking_boxes':blocked,'state':'CLEAR' if not blocked else 'BLOCKED'}
baseline=json.loads((O/'ROUND2-PROTECTED-HASHES.json').read_text())
changes=[p['Path'] for p in baseline if sha(Path(p['Path'])).upper()!=p['Hash']]
report={'manifest_sha256':sha(H/'scene.json'),'place_sha256':sha(R/'prototype/meadow-v4.rbxl'),'comparison_sha256':sha(O/'build-sbs.jpg'),
 'part_count':len(d['parts']),'audit':a['state'],'flags':a['violation_count_recorded'],'samples':a['sample_count'],'ramp_max_degrees':a['max_ramp_degrees'],
 'min_clear_lane_width':min(p['width'] for p in d['routes'].values()),'headroom_studs':20,'route_estimates':{k:{'studs_ESTIMATED':round(v,1),'seconds_at_16_ESTIMATED':round(v/16,1)} for k,v in routes.items()},
 'portal_visibility_static_OBB':sight,'protected_checked':len(baseline),'protected_hash_changes':changes,
 'protected_mutation_scope':'Only prototype/meadow-v4, prototype/meadow-v4.rbxl and treasure/map-v4 were written. Concurrent changes, if any, preserved; author UNKNOWN.',
 'proof':'Offline Blender render of the exported native-part manifest. Approximate reconstructed concept camera; not Studio.',
 'UNKNOWN':['Studio traversal and actual timing','animated Keeper clearance','cargo camera','multiplayer','device performance'],'lessons':['When doubling heights, lengthen ramps before dressing because lane intersections otherwise obstruct headroom.','When a camera reference has no metadata, compare whole-object framing because matching one landmark can crop the rest.']}
(O/'ROUND2-EVIDENCE.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
