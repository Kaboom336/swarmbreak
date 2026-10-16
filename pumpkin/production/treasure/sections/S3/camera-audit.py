"""No camera or walking marker point may hide inside a retained gameplay solid."""
import json,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
data=json.loads((H/'r4.json').read_text());cameras=json.loads((H/'CAMERAS.json').read_text())
parts=[p for p in data['parts'] if p['collidable'] and p['query']]
c=np.array([p['position'] for p in parts]);r=np.array([p['rotation'] for p in parts]).reshape(-1,3,3);h=np.array([p['size'] for p in parts])/2;w=np.array([p['shape']=='Wedge' for p in parts])
def blockers(point):
 o=np.einsum('nji,nj->ni',r,np.array(point)-c)
 inside=np.all(np.abs(o)<h-.01,axis=1)&(~w|(o[:,1]/h[:,1]-o[:,2]/h[:,2]<=0))
 return [parts[i]['name'] for i in np.where(inside)[0]]
rows=[]
for v in cameras:
 if v.get('cutaway'):continue
 row={'name':v['name'],'camera_blockers':blockers(v['eye']),'walking_root_blockers':blockers(v['walking_player']),'trail_horizontal_studs':float(np.linalg.norm(np.array(v['eye'])[::2]-np.array(v['walking_player'])[::2]))}
 assert abs(row['trail_horizontal_studs']-18)<1e-5
 if not v['name'].startswith('surface-'):assert not row['camera_blockers'] and not row['walking_root_blockers'],row
 rows.append(row)
(H/'CAMERA-CLEARANCE.json').write_text(json.dumps({'method':'Exact retained query/collider box/wedge point containment at eye and nominal walking-root positions; does not simulate avatar, camera controller or swept movement. Surface cameras record literal exterior-policy evidence and are not interior acceptance cameras.','results':rows},indent=2))
print(json.dumps(rows,indent=2))
