"""Second blind-review pass. Prepared independently; run only after review approval."""
import json,math,random
from pathlib import Path
import geometry as g
P=Path(__file__).parent;S=json.loads((P/'scene.json').read_text())
owned={'Round4ShelfRockRelief','Round4ShelfLightFacet','Round4ShelfMossLedge','Round4ShelfMossDrop','Round4HangingMossCluster','Round4HangingMossLight','Round4HangingMossTip'}
S['parts']=[p for p in S['parts'] if p['name'] not in owned]
g.PARTS[:]=S['parts'];g.ROUTES.update(S['routes']);r=random.Random(4142)
palette=[(101,87,115),(124,107,138),(148,129,161),(168,151,182)]
def ground(x,z):
 candidates=[p for p in S['parts'] if p['name']=='SolidMountainStone' and abs(p['position'][0]-x)<=2.01 and abs(-p['position'][2]-z)<=2.01]
 return max((p['position'][1]+p['size'][1]/2 for p in candidates),default=0)
# Deep relief runs along both faces of the shelf's solid supports. Broad flat
# backing stays intact; the visible facade becomes staggered irregular rock.
for i,p in enumerate(S['parts']):
 if p['name']!='SolidRampBody':continue
 x,y,wz=p['position'];z=-wz
 shelf=25<x<142 and 60<z<145
 ridge=118<x<165 and -90<z<20
 if not(shelf or ridge):continue
 sx,sy,sz=p['size'];rot=p['rotation'];top=y+sy/2
 for side in [-1,1]:
  for row in range(max(1,math.ceil((top+5)/6))):
   yy=-3+row*6.1
   if yy>top-2:continue
   along=-sz/2+2+r.uniform(-1,1)
   while along<sz/2:
    length=r.choice([4.5,6.5,8]);depth=r.choice([3,4.5,6]);h=r.choice([5,6.5,8])
    normal=side*(sx/2+depth/2-.8)
    xx=x+rot[0]*normal+rot[2]*along;zz=wz+rot[6]*normal+rot[8]*along
    # Keep the entire projected block out of both visible optional jump gaps.
    reach=abs(rot[6])*depth/2+abs(rot[8])*length/2
    if ridge and xx>135 and any(-zz-reach<b and -zz+reach>a for a,b in [(-34,-30),(-50,-46)]):
     along+=length*.9
     continue
    crown=min(yy+h/2,top-1.7)
    g.part('Round4ShelfRockRelief','cliff',(xx,crown-h/2,zz),(depth,h,length),palette[(i+row+int(along))%4],'Slate',False,rot)
    g.part('Round4ShelfLightFacet','rock_cap',(xx,crown+.1,zz),(depth*.86,.45,length*.9),(190,175,204),'Slate',False,rot)
    if (row+int(along))%3==0:
     g.part('Round4ShelfMossLedge','grass',(xx+rot[0]*side*.4,crown+.5,zz+rot[6]*side*.4),(depth*.8,.65,length*.6),(106,162,54),'Grass',False,rot)
     g.part('Round4ShelfMossDrop','grass',(xx+rot[0]*side*depth*.5,crown-1.7,zz+rot[6]*side*depth*.5),(1.8,4.2,length*.4),(76,128,53),'Grass',False,rot)
    along+=length*.9
# Drooping asymmetric moss islands break the rim in readable groups, not rows.
for x,z in [(-79,-145),(-119,-112),(-148,-66),(-158,-19),(-148,51),(62,-151),(100,-129),(147,-64)]:
 a=math.atan2(z,x);rim=164+7*math.sin(3*a+.5)+5*math.sin(7*a)+3*math.sin(11*a)
 yy=ground((rim-4)*math.cos(a),(rim-4)*math.sin(a))
 x=(rim+1.5)*math.cos(a);z=(rim+1.5)*math.sin(a)
 for dx,dz,drop,w in [(-3,0,9,6),(2,1,13,4),(5,-2,6,5)]:
  xx=x+dx;zz=z+dz
  g.specpart('Round4HangingMossCluster','grass',xx,zz,yy-drop/2,w,4,drop,(69,123,51),material='Grass')
  g.specpart('Round4HangingMossLight','grass',xx-w*.2,zz-.8,yy-drop*.3,w*.55,3,drop*.55,(102,155,57),material='Grass')
  g.specpart('Round4HangingMossTip','grass',xx+.6,zz,yy-drop-1,w*.45,2,3,(74,133,49),material='Grass')
g.emit()
out=json.loads((P/'scene.json').read_text())
for k,v in S.items():
 if k not in {'parts','routes'}:out[k]=v
(P/'scene.json').write_text(json.dumps(out,separators=(',',':')))
print('Second visual pass parts:',len(g.PARTS))
