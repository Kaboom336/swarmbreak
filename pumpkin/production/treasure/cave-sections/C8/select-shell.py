"""Fit only exterior, nonphysical C8 envelopes against protected native solids.
Uses the same conservative SAT as contact.py, never edits old geometry.
"""
import json,math,sys
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent
scope={'__file__':str(H/'contact.py')}
# Load SAT helpers without its report/mutation tail.
argv=sys.argv;sys.argv=['contact.py','before']
exec((H/'contact.py').read_text().split('errors=[dict')[0],scope)
sys.argv=argv
old=scope['old'];obb=scope['obb'];sat=scope['penetration']
centers=np.array([p['position'] for p in old]);extents=np.array([abs(obb(p)[2])@obb(p)[1] for p in old])
def native(g):
 a=math.radians(g.get('yaw',0));c,s=math.cos(a),math.sin(a)
 return dict(name=g['name'],position=g['c'],size=g['s'],rotation=[c,0,s,0,1,0,-s,0,c])
def hits(g):
 p=native(g);c,h,r=obb(p)
 ids=np.flatnonzero(np.all(abs(centers-c)<extents+abs(r)@h-.035,axis=1))
 return any(sat(p,old[i])for i in ids)
palette=[[84,72,69],[101,85,77],[69,62,64],[114,96,84]]
plan=[];fit=[]
# Overlapping broad strata, broad shoulders narrowing into one keel.
for layer,(y,n,w,h,d) in enumerate([(-65,38,56,42,32),(-96,34,54,44,32),(-127,28,52,44,30),(-157,22,48,42,28),(-185,16,42,40,25),(-211,10,34,36,22),(-234,5,22,31,18)]):
 for j in range(n):
  a=2*math.pi*(j+.47*(layer%2))/n
  g=dict(name=f'C8_Stratum_{layer:02}_{j:02}',c=[0,y,0],s=[w,h,d],yaw=90-math.degrees(a),color=palette[(j//3+layer)%4],shape='Wedge',kit=True,role='continuous exterior stratum')
  # Search outside inward: stop at first obstructed radius, retain last safe.
  last=None
  for radius in np.arange(320,0,-1):
   g['c']=[float(math.cos(a)*radius+4),y,float(math.sin(a)*radius)]
   if hits(g):break
   last=g['c'][:]
  if last is None:raise RuntimeError('no legal shell')
  g['c']=last;plan.append(g);fit.append(dict(name=g['name'],radial_clearance_step=1))
# Old nonphysical distant islands: connected broad boulders replace their box read
# visually; originals remain exact and are recorded as residual visual risk.
parts=json.loads((H/'before.json').read_text())['parts']
backs=[p for p in parts if p['name']=='R3DistantIsland']
for k in range(0,len(backs),5):
 group=backs[k:k+5];top=group[-1];x,y,z=top['position']
 # Stay within native extrema and use steep, compact shapes, never flat platforms.
 for j,(dy,scale) in enumerate([(-13,1),(-36,.66)]):
  g=dict(name=f'C8_Backdrop_{k//5}_{j}',c=[x,y+dy,z],s=[min(58,top['size'][0]+4)*scale,41*scale,min(43.5,top['size'][2]+4)*scale],yaw=0,color=palette[(k//5+j)%4],shape='Wedge',kit=True,role='deliberate distant rock cluster')
  if not hits(g):plan.append(g)
for j,p in enumerate(parts):
 if p['name']!='FloatingRock':continue
 g=dict(name=f'C8_Satellite_{j}',c=p['position'],s=p['size'],yaw=0,color=palette[j%4],shape='Wedge',kit=True,role='faceted replacement of inherited loose cosmetic cube')
 if not hits(g):plan.append(g)
(H/'ROCK-PLAN.json').write_text(json.dumps(plan,indent=2))
(H/'SELECTION.json').write_text(json.dumps(dict(shells=len(fit),backdrops=len(plan)-len(fit),collision_checked=True,step=1,method='Conservative native OBB SAT; downward exterior only; no original changes'),indent=2))
print('Selected',len(plan),'exterior boulders')
