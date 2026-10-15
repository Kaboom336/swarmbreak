import json,math,hashlib,sys
from pathlib import Path
H=Path(__file__).parent
s=json.loads((H/'scene.json').read_text());b=json.loads((H/'balance-before-scene.json').read_text())
keys=['name','category','position','size','rotation','collidable']
assert [{k:p[k] for k in keys} for p in s['parts'] if p['collidable']]==[{k:p[k] for k in keys} for p in b['parts'] if p['collidable']]
assert s['routes']==b['routes']
assert [p for p in s['parts'] if p['category']=='hook']==[p for p in b['parts'] if p['category']=='hook']
def distance(x,z,pts):
 best=1e9;yy=0
 for a,c in zip(pts,pts[1:]):
  dx,dz=c[0]-a[0],c[1]-a[1];t=max(0,min(1,((x-a[0])*dx+(z-a[1])*dz)/(dx*dx+dz*dz)))
  d=math.hypot(x-a[0]-dx*t,z-a[1]-dz*t)
  if d<best:best,yy=d,a[2]+(c[2]-a[2])*t
 return best,yy
hits=[];margin=[]
old=len(b['parts'])-sum(p['category']=='landmark' for p in b['parts'])
for i,p in enumerate(s['parts']):
 if i<old and '--all' not in sys.argv:continue
 r=p['rotation'];half=[x/2 for x in p['size']]
 bounds=[sum(abs(r[k*3+j])*half[j] for j in range(3)) for k in range(3)]
 if p['category']=='crystal':
  radius=math.hypot(bounds[0],bounds[2])
  for name,route in s['routes'].items():
   d,y=distance(p['position'][0],-p['position'][2],route['points'])
   if p['position'][1]+bounds[1]>y and d-radius<13:
    hits.append({'part':p['name'],'route':name,'margin':d-radius-9,'position':p['position']})
   elif p['position'][1]+bounds[1]>y:margin.append(d-radius-9)
bodyhits=[]
props=[p for p in s['parts'][old:] if p['category']=='landmark']
for name,route in s['routes'].items():
 if name=='cartRail':continue
 for aa,bb in zip(route['points'],route['points'][1:]):
  n=max(1,math.ceil(math.dist(aa,bb)/2));dx,dz=bb[0]-aa[0],bb[1]-aa[1];run=math.hypot(dx,dz)
  for j in range(n+1):
   t=j/n;c=[aa[k]+(bb[k]-aa[k])*t for k in range(3)]
   for off in [-7,0,7]:
    q=[c[0]-dz/run*off,c[2]+3.5,-c[1]-dx/run*off]
    for p in props:
     r=p['rotation'];d=[q[k]-p['position'][k] for k in range(3)]
     local=[sum(r[k*3+axis]*d[k] for k in range(3)) for axis in range(3)]
     pad=[sum(abs(r[k*3+axis])*[2,3.3,2][k] for k in range(3)) for axis in range(3)]
     if all(abs(local[k])<p['size'][k]/2+pad[k] for k in range(3)):bodyhits.append({'route':name,'part':p['name'],'position':p['position']})
report={'collision_geometry_equal':True,'routes_equal':True,'hooks_equal':True,'new_crystal_margin_hits':hits,'minimum_conservative_new_crystal_path_margin':min(margin),'new_landmark_walkway_body_hits':bodyhits,'new_part_start':old}
(H/('BALANCE-ALL-CRYSTAL-AUDIT.json' if '--all' in sys.argv else 'BALANCE-ART-AUDIT.json')).write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2)[:5000])
