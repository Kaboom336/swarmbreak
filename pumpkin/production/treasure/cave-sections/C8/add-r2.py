"""Only R1's three recorded gaps; R1 plan remains an immutable prefix."""
from pathlib import Path
H=Path(__file__).resolve().parent
scope={'__file__':str(H/'select-shell.py')}
exec((H/'select-shell.py').read_text().split('palette=')[0],scope)
json,math,np,hits=[scope[k]for k in ['json','math','np','hits']]
plan=json.loads((H/'r1-plan.json').read_text());added=[]
for layer,(y,n,w,h,d) in enumerate([(-80,31,70,33,42),(-111,25,65,34,38),(-141,19,61,33,36),(-171,13,55,32,32),(-197,8,44,30,28)]):
 for j in range(n):
  a=2*math.pi*(j+.33+.37*(layer%2))/n
  g=dict(name=f'C8_Join_{layer}_{j}',c=[0,y,0],s=[w,h,d],yaw=90-math.degrees(a),color=[[74,63,59],[94,78,66],[58,52,53]][(j//3+layer)%3],shape='Wedge',kit=True,kitName='kenney_nature-kit__rock_largeC',role='bridge visible R1 belt seams with broad facets')
  last=None
  for radius in np.arange(320,0,-1):
   g['c']=[float(math.cos(a)*radius+4),y,float(math.sin(a)*radius)]
   if hits(g):break
   last=g['c'][:]
  if last is not None:g['c']=last;added.append(g)
g=dict(name='C8_Keel_Point',c=[4,-238,0],s=[23,27,23],yaw=0,color=[66,56,53],shape='Wedge',kit=True,kitName='kenney_nature-kit__rock_tallA',flip=True,role='one inverted faceted terminal point')
if not hits(g):added.append(g)
# Thin vertical crystal seams: top remains inside an audited shell envelope,
# the descending line has no standable-looking horizontal surface.
for j,index in enumerate([5,18,31]):
 anchor=plan[index];x,y,z=anchor['c'];a=math.radians(anchor['yaw']);dx,dz=math.sin(a),math.cos(a)
 c=[x+dx*(anchor['s'][2]/2-2),y-13,z+dz*(anchor['s'][2]/2-2)]
 for k in range(2):
  g=dict(name=f'C8_Cascade_{j}_{k}',c=[c[0],c[1]-k*18,c[2]],s=[1.4 if k==0 else .6,23,1.4 if k==0 else .6],yaw=45,flip=True,color=[65,162,185],shape='Wedge',material='Neon',role='thin hanging crystal waterfall',sparkle=k==1)
  if not hits(g):added.append(g)
for j,g0 in enumerate(plan):
 if not g0['name'].startswith('C8_Backdrop_')or not g0['name'].endswith('_1'):continue
 x,y,z=g0['c'];h=g0['s'][1]
 g=dict(name=f'C8_BackAnchor_{j}',c=[x,y-h/2-7,z],s=[2.4,18,2.4],yaw=45,flip=True,color=[72,144,168],shape='Wedge',material='Neon',role='pointed distant hanging crystal anchor')
 if not hits(g):added.append(g)
(H/'R2-ADDITIONS.json').write_text(json.dumps(added,indent=2));print('R2 additions',len(added))
