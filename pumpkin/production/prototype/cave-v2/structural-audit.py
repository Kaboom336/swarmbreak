"""Independent static OBB contact graph and sampled cave/cart envelope checks.
Connected-to-bedrock is geometric contact, not finite-element load capacity.
"""
import json,math,itertools
from pathlib import Path
ROOT=Path(__file__).parent
scene=json.loads((ROOT/'scene.json').read_text());parts=[p for p in scene['parts'] if p['collidable']]
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def cross(a,b):return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
for p in parts:
 r=p['rotation'];p['axes']=[[r[i],r[i+3],r[i+6]] for i in range(3)];p['half']=[v/2 for v in p['size']]
 p['bounds']=[sum(abs(r[i*3+j])*p['half'][j] for j in range(3)) for i in range(3)]
def touches(a,b):
 d=[b['position'][i]-a['position'][i] for i in range(3)]
 if any(abs(d[i])>a['bounds'][i]+b['bounds'][i]+.06 for i in range(3)):return False
 for axis in a['axes']+b['axes']+[cross(x,y) for x in a['axes'] for y in b['axes']]:
  if dot(axis,axis)<1e-10:continue
  radius=sum(abs(dot(axis,x))*h for x,h in zip(a['axes'],a['half']))+sum(abs(dot(axis,x))*h for x,h in zip(b['axes'],b['half']))
  if abs(dot(d,axis))>radius+.06:return False
 return True
def envelope(pos,size):return {'position':pos,'size':size,'axes':[[1,0,0],[0,1,0],[0,0,1]],'half':[v/2 for v in size],'bounds':[v/2 for v in size]}
parent=list(range(len(parts)))
def find(i):
 while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
 return i
cells={}
for i,p in enumerate(parts):
 limits=[range(math.floor((p['position'][j]-p['bounds'][j])/32),math.floor((p['position'][j]+p['bounds'][j])/32)+1) for j in range(3)]
 for key in itertools.product(*limits):cells.setdefault(key,[]).append(i)
tested=set()
for ids in cells.values():
 for i,j in itertools.combinations(ids,2):
  if find(i)==find(j) or (i,j) in tested:continue
  tested.add((i,j))
  if touches(parts[i],parts[j]):parent[find(j)]=find(i)
mountain_components={find(i) for i,p in enumerate(parts) if p['category'] in ('mass','underside')}
root_index=min((i for i,p in enumerate(parts) if p['category']=='underside'),key=lambda i:parts[i]['position'][1])
bedrock={find(root_index)}
floats=[p['name'] for i,p in enumerate(parts) if find(i) not in bedrock]
def xyz(a):return [a[0],a[2],-a[1]]
cave_hits=[];cave_samples=0
for index,(a,b) in enumerate(zip(scene['routes']['cave']['points'],scene['routes']['cave']['points'][1:])):
 n=math.ceil(math.dist(a,b)/2);dx,dz=b[0]-a[0],b[1]-a[1];run=math.hypot(dx,dz)
 for j in range(n+1):
  t=j/n;q=xyz([a[k]+(b[k]-a[k])*t for k in range(3)])
  for offset in (-7,0,7):
   center=[q[0]-dz/run*offset,q[1]+15,q[2]-dx/run*offset];e=envelope(center,[4,17.8,4]);cave_samples+=1
   hit=next((p['name'] for p in parts if touches(p,e)),None)
   if hit:cave_hits.append({'segment':index,'t':t,'offset':offset,'part':hit})
rail=scene['routes']['cartRail']['points'];lengths=[math.dist(a,b) for a,b in zip(rail,rail[1:])];gap_start=sum(lengths[:3])+lengths[3]/2-8;gap_end=gap_start+16
def at(distance):
 for a,b,length in zip(rail,rail[1:],lengths):
  if distance<=length:return xyz([a[k]+(b[k]-a[k])*distance/length for k in range(3)])
  distance-=length
 return xyz(rail[-1])
def track_envelope(distance):
 remaining=distance
 for a,b,length in zip(rail,rail[1:],lengths):
  if remaining<=length:
   aa,bb=xyz(a),xyz(b);forward=[(bb[i]-aa[i])/length for i in range(3)];back=[-v for v in forward];right=cross([0,1,0],back);norm=math.sqrt(dot(right,right));right=[v/norm for v in right];up=cross(back,right);q=at(distance);center=[q[i]+up[i]*4+(2 if i==1 else 0) for i in range(3)];e=envelope(center,[8,7.8,10]);e['axes']=[right,up,back];e['bounds']=[sum(abs(axis[j])*half for axis,half in zip(e['axes'],e['half'])) for j in range(3)];return e
  remaining-=length
 return envelope([v+(6 if i==1 else 0) for i,v in enumerate(at(distance))],[8,7.8,10])
flight_hits=[]
for i in range(65):
 t=i/64;a,b=at(gap_start),at(gap_end);q=[a[k]+(b[k]-a[k])*t for k in range(3)];q[1]+=12*4*t*(1-t)+6;e=track_envelope(gap_start);e['position']=q
 hits=[p['name'] for p in parts if p['category']!='span' and touches(p,e)]
 if hits:flight_hits.append({'t':t,'parts':hits})
fall_hits=[]
for i in range(65):
 t=i/64;a=at(gap_start);b=[0,-14,25];q=[a[k]+(b[k]-a[k])*t for k in range(3)];q[1]+=6;e=track_envelope(gap_start);e['position']=q
 hits=[p['name'] for p in parts if p['category']!='span' and touches(p,e)]
 if hits:fall_hits.append({'t':t,'parts':hits})
cart_hits=[];cart_samples=math.ceil(sum(lengths)/2)+1
for i in range(cart_samples):
 distance=min(sum(lengths),i*2)
 if gap_start<=distance<=gap_end:continue
 e=track_envelope(distance);hits=[p['name'] for p in parts if touches(p,e)]
 if hits:cart_hits.append({'distance':distance,'parts':hits})
def vertical_interval(p,q):
 delta=[q[i]-p['position'][i] for i in range(3)];low,high=-1e9,1e9
 for axis,half in zip(p['axes'],p['half']):
  position=dot(delta,axis);velocity=axis[1]
  if abs(velocity)<1e-9:
   if abs(position)>half+.001:return None
  else:
   aa,bb=(-half-position)/velocity,(half-position)/velocity;low=max(low,min(aa,bb));high=min(high,max(aa,bb))
 if low>high:return None
 return q[1]+low,q[1]+high
floor_gaps=[];max_snap=0;floor_samples=0
for name,route in scene['routes'].items():
 if name=='cartRail':continue
 for index,(a,b) in enumerate(zip(route['points'],route['points'][1:])):
  n=math.ceil(math.dist(a,b)/2);dx,dz=b[0]-a[0],b[1]-a[1];run=math.hypot(dx,dz)
  for j in range(n+1):
   t=j/n;center=xyz([a[k]+(b[k]-a[k])*t for k in range(3)])
   for lateral in (-7,0,7):
    q=[center[0]-dz/run*lateral,center[1],center[2]-dx/run*lateral];floor_samples+=1
    tops=[]
    for p in parts:
     if p['category']!='lane':continue
     interval=vertical_interval(p,q)
     if interval and abs(interval[1]-q[1])<3:tops.append(interval[1])
    if not tops:floor_gaps.append({'route':name,'segment':index,'t':t,'offset':lateral})
    else:max_snap=max(max_snap,abs(max(tops)-q[1]))
report={'method':'OBB SAT contact graph tolerance0.06stud rooted ONLY in deepest underside collider component; checks every mass/support/roof/floor collider. Contact proves geometric attachment, not load-bearing strength. Cave upper envelope bottom6.1 top23.9 sampled <=2stud lateral -7/0/7,4stud width. Flight and red-fall65 samples ORIENTED8x7.8x10 envelopes; broken span+beam excluded. Track cart <=2stud samples ORIENTED to exact track dir; center=pivot(worldY+2)+normal*4, wheels ground contact excluded. Floor rays <=2stud lateral -7/0/7 accept floor within3stud predicted centerline; report max snap. Runtime, continuous sweep and dismount UNKNOWN.','mountain_connected_components':len(mountain_components),'floating_collider_parts':len(floats),'floating_parts':floats,'cave_24_headroom_hits':len(cave_hits),'cave_samples':cave_samples,'headroom_violations':cave_hits[:30],'green_flight_envelope_hits':len(flight_hits),'flight_violations':flight_hits[:15],'red_fall_envelope_hits':len(fall_hits),'fall_violations':fall_hits[:15],'track_cart_envelope_hits':len(cart_hits),'cart_violations':cart_hits[:15],'floor_ray_missing_hits':len(floor_gaps),'floor_samples':floor_samples,'max_floor_snap_studs':round(max_snap,4),'floor_gaps':floor_gaps[:15]}
(ROOT/'STRUCTURAL-AUDIT.json').write_text(json.dumps(report,indent=2));print(json.dumps({k:v for k,v in report.items() if k not in ('floating_parts','headroom_violations','flight_violations')},indent=2))
