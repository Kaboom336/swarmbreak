import json,hashlib,math
from pathlib import Path
H=Path(__file__).resolve().parent;R=H.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
s=json.loads((H/'scene.json').read_text());b=json.loads((H/'readability-baseline-scene.json').read_text())
def geometry(data,categories=None):
    return [{k:p[k] for k in ['name','category','position','size','rotation','collidable']} for p in data['parts'] if p['collidable'] and (categories is None or p['category'] in categories)]
assert geometry(s)==geometry(b) and s['routes']==b['routes']
assert [p for p in s['parts'] if p['category']=='hook']==[p for p in b['parts'] if p['category']=='hook']
a=json.loads((H/'AUDIT.json').read_text());st=json.loads((H/'STRUCTURAL-AUDIT.json').read_text())
zero={'clearance_hits':a['clearance_hits'],'unreachable_route_nodes':a['unreachable_route_nodes']}
for k in ['floating_collider_parts','cave_24_headroom_hits','green_flight_envelope_hits','red_fall_envelope_hits','track_cart_envelope_hits','floor_ray_missing_hits']:zero[k]=st[k]
assert all(v==0 for v in zero.values())
# New landmark bodies must also sit outside the sampled walkable body corridor,
# even though the inherited audits intentionally exclude noncollidable art.
landmarks=[p for p in s['parts'] if p['category']=='landmark'];hits=[]
for name,route in s['routes'].items():
    if name=='cartRail':continue
    for aa,bb in zip(route['points'],route['points'][1:]):
        n=max(1,math.ceil(math.dist(aa,bb)/2));dx,dz=bb[0]-aa[0],bb[1]-aa[1];run=math.hypot(dx,dz)
        for j in range(n+1):
            t=j/n;c=[aa[k]+(bb[k]-aa[k])*t for k in range(3)]
            for off in [-7,0,7]:
                q=[c[0]-dz/run*off,c[2]+3.5,-c[1]-dx/run*off]
                for p in landmarks:
                    if all(abs(q[k]-p['position'][k])<p['size'][k]/2+[2,3.3,2][k] for k in range(3)):hits.append({'route':name,'part':p['name'],'point':q})
assert not hits,hits[:5]
meta=json.loads((H/'readable-r3-final-cameras.json').read_text());assert meta['manifest_sha256']==sha(H/'scene.json')
assert set(meta['views'])=={'portal','main-eye','cart-eye','cave-eye','far','top-routes'}
report={'routes_equal':True,'hooks_equal':True,'all_collision_geometry_equal':True,'terrain_height_mass_equal':geometry(s,['mass','underside'])==geometry(b,['mass','underside']),'zero_checks':zero,'landmark_walkway_body_hits':len(hits),'mountain_components':st['mountain_connected_components'],'native_check':json.loads((H/'READABILITY-NATIVE-CHECK.json').read_text()),'before_parts':len(b['parts']),'after_parts':len(s['parts']),'before_point_lights':len(b['lights']),'after_point_lights':len(s['lights']),'camera_metadata':meta,'runtime':'UNKNOWN; offline render and sampled static/native audits, not Studio play or actual three-second user test'}
files=[R/'prototype/cave-v2.rbxl',H/'scene.json',H/'build.luau',H/'readability-art.luau',H/'readability-render.py',H/'READABLE-SHEET.jpg',H/'READABILITY-BEFORE-AFTER.jpg',H/'AUDIT.json',H/'STRUCTURAL-AUDIT.json',H/'READABILITY-NATIVE-CHECK.json']
files += [H/f'readable-r3-final-{v}.png' for v in meta['views']]
reviews=[H/f'READABILITY-CRITIC-R{i}.md' for i in [1,2,3]]
report['blind_reviews']={p.name:p.read_text(encoding='utf8') for p in reviews}
files += reviews+[H/'READABILITY.md',H/'readability-check.luau',H/'readability-sheet.ps1',H/'readability-evidence.py']
report['hashes']={str(p.relative_to(R)):sha(p) for p in files}
(H/'READABILITY-EVIDENCE.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k not in ['hashes','camera_metadata','blind_reviews']},indent=2))
