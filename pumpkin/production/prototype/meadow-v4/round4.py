"""Round4 visual-only refinement of the saved Round3 scene; no gameplay imports."""
import json,math,random,hashlib
from pathlib import Path
import geometry as g
P=Path(__file__).parent
S=json.loads((P/'round4-baseline-scene.json').read_text())
g.PARTS[:]=S['parts'];g.ROUTES.update(S['routes']);g.R=random.Random(41014)
g.GREEN=(100,177,44);g.ROCK=(137,126,148)
palette=[(99,88,116),(125,111,139),(147,131,158),(169,153,177)]
tops={(round(p['position'][0]),round(-p['position'][2])):p['position'][1]+p['size'][1]/2 for p in g.PARTS if p['name']=='SolidMountainStone'}
edges=[(a,b,r['width']/2) for r in g.ROUTES.values() for a,b in zip(r['points'],r['points'][1:])]
def ravine(x,z):return abs(x)<90 and abs(z)<35
def near(x,z,margin=0):return any(g.dist_segment(x,z,a,b)<w+margin for a,b,w in edges)
def outline(x,z):
 a=math.atan2(z,x);r=164+7*math.sin(3*a+.5)+5*math.sin(7*a)+3*math.sin(11*a)
 return math.hypot(x,z)<r
def ground(x,z):return tops.get((round((x+174)/4)*4-174,round((z+174)/4)*4-174),0)
def clear(x,z,r=0):return outline(x,z) and not ravine(x,z) and not near(x,z,r+3) and not(abs(x)<29 and -165<z<-105) and not(abs(x)<27 and 84<z<132)
def gap(x,z):return 141<x<155 and (-35<z<-29 or -51<z<-45)
# All old lanterns are replaced by isolated pairs. Terrain and lane solids remain.
g.PARTS[:]=[p for p in g.PARTS if p['category'] not in {'lantern','light'} and not(p['category']=='underside' and not ravine(p['position'][0],-p['position'][2])) and not(p['category']=='cliff' and not ravine(p['position'][0],-p['position'][2])) and not(gap(p['position'][0],-p['position'][2]) and p['category'] in {'terrace','terrain_grass','cliff','grass','terrain_cap'})]
# Shorten only bottoms: original support/top faces are preserved exactly.
for p in g.PARTS:
 x,y,wz=p['position'];z=-wz
 if p['name']=='SolidMountainStone' and not ravine(x,z):
  top=y+p['size'][1]/2;r=math.hypot(x,z)
  bottom=-24 if r>139 else -37 if r>113 else -51
  if top-bottom>0:p['size'][1]=top-bottom;p['position'][1]=(top+bottom)/2
 if p['name']=='SolidRampBody' and not ravine(x,z):
  top=y+p['size'][1]/2;bottom=-25 if math.hypot(x,z)>139 else -38
  p['size'][1]=top-bottom;p['position'][1]=(top+bottom)/2
 if p['category'] in {'terrace','path_rock'} and not ravine(x,z):p['color']=list(palette[(int(x/4)+int(z/4))%4])
# Exposed terrace faces: deep protruding blocks, staggered ledges and small moss islands.
for (x,z),h in tops.items():
 if ravine(x,z) or gap(x,z):continue
 for dx,dz in [(4,0),(0,4),(-4,0),(0,-4)]:
  low=tops.get((x+dx,z+dz),-24)
  if low>=h-3 or (int(x+z)//4)%3:continue
  low=max(low,-25)
  y=low+3;row=0
  while y<h-1:
   sy=g.R.choice([4.5,6,8]);along=g.R.choice([6,8,10]);depth=g.R.choice([3,4.5,6]);off=g.R.uniform(-1.2,1.2)
   xx=x+dx*.48+(off if dz else 0);zz=z+dz*.48+(off if dx else 0)
   if not ravine(xx,zz) and not gap(xx,zz):
    sx=along if dz else depth;sz=along if dx else depth
    g.specpart('Round4StackedRock','cliff',xx,zz,min(y,h-sy/2),sx,sz,sy,palette[(row+int(x/4))%4],material='Slate')
    if row%2==0:
     g.specpart('Round4PaleRockTop','rock_cap',xx,zz,min(y,h-sy/2)+sy/2,sx*.9,sz*.9,.5,(191,176,199),material='Slate')
     g.specpart('Round4RockMoss','grass',xx-sx*.2,zz+sz*.16,min(y,h-sy/2)+sy/2+.3,sx*.4,sz*.4,.65,(112,158,65))
   y+=sy*.9;row+=1
  xx=x+dx*.5;zz=z+dz*.5
  if not near(xx,zz,4) and not ravine(xx,zz):
   g.specpart('Round4OverhangLip','grass',xx,zz,h+.05,6 if dz else 3,6 if dx else 3,1.1,(122,181,53))
   g.specpart('Round4HangingLipMoss','grass',xx+dx*.2,zz+dz*.2,h-1.3,2.3,2.3,3.5,(79,126,51))
# Taper shell is stepped in large irregular chunks; no outer full-depth drum.
for scale,top,bottom in [(1,-23,-37),(.81,-36,-52),(.63,-51,-68),(.43,-67,-82),(.22,-81,-96)]:
 for x in range(-170,171,10):
  for z in range(-170,171,10):
   if not outline(x/scale,z/scale) or (top>-40 and ravine(x,z)):continue
   dep=top-bottom+g.R.choice([0,2,5]);w=g.R.choice([10,12,14]);hcol=palette[(int(x/10)+int(z/10))%4]
   g.specpart('Round4TaperChunk','underside',x,z,top-dep/2,w,w,dep,hcol,material='Slate')
   if not outline((x+10)/scale,z/scale) and g.R.random()<.45:
    g.specpart('Round4UndersideMoss','grass',x+w*.4,z,top-3,3,5,7,(75,119,57))
# Twenty light pairs: only courts/junctions, bridge ends, portal, summit.
sites=[(-18,-149,0),(18,-149,0),(-20,-119,0),(20,-119,0),(-15,31,0),(15,31,0),(-15,-31,0),(15,-31,0),(-17,44,0),(17,44,0),(-15,112,48),(15,112,48),
(-64,32,0),(-86,32,0),(-64,-81,0),(-86,-81,0),(-30,-101,0),(-14,-101,0),(-12,-77,0),(12,-77,0),
(57,29,0),(77,29,0),(98,18,0),(122,18,0),(98,-59,20),(122,-59,20),(31,83,0),(43,61,0),(47,120,48),(62,97,48),
(92,116,36),(116,116,36),(112,140,36),(136,140,36),(112,79,24),(136,79,24),(137,-1,20),(160,-1,20),(136,-86,20),(155,-86,20)]
for x,z,y in sites:
 actual=ground(x,z)
 # Lanterns rest on terrain, never on an assumed nearby route elevation.
 g.specpart('Round4LanternFooting','lantern',x,z,actual+.3,3.2,3.2,.6,(169,153,177),material='Slate')
 g.lantern(x,z,actual+.6)
# A woodland mosaic fills previously bare interior areas. Radius checks include crowns.
clusters=[(-139,-41),(-121,-66),(-119,-95),(-70,-43),(-57,-66),(-57,10),(-121,16),(-125,84),(-94,96),(-59,135),(43,-46),(66,-55),(55,-83),(83,-78),(48,-116),(80,-123),(77,4),(138,46),(80,91),(72,125)]
for index,(cx,cz) in enumerate(clusters):
 for dx,dz,scale in [(0,0,.85),(-9,8,.66),(9,5,.60)]:
  x,z=cx+dx,cz+dz
  if clear(x,z,11*scale):g.tree(x,z,ground(x,z),scale)
 for j in range(10):
  x=cx+g.R.uniform(-16,16);z=cz+g.R.uniform(-14,14);w=g.R.uniform(3,6)
  if not clear(x,z,w):continue
  y=ground(x,z);kind=j%4
  if kind==0:
   g.specpart('Round4SmallHeightStep','ground_detail',x,z,y+.6,w+3,w+3,1.2,(105,166,53))
   g.specpart('Round4StepMoss','grass',x,z,y+1.3,w+3,w+3,.25,(127,187,61))
  elif kind==1:
   g.specpart('Round4Bush','bush',x,z,y+2,w,w,4,(61,138,48));g.specpart('Round4BushTop','bush',x-1,z+1,y+4,w*.7,w*.7,2,(101,170,53))
  elif kind==2:
   for q in range(3):
    xx=x+q*2;zz=z+q*1.5;h=3.5+q
    g.specpart('Round4BoulderGroup','boulder',xx,zz,y+h/2,w-q*.5,w-q*.5,h,palette[(j+q)%4],material='Slate')
    g.specpart('Round4BoulderFacet','rock_cap',xx,zz,y+h,w-q*.5,w-q*.5,.6,(188,174,195),material='Slate')
  else:
   for q in range(5):
    xx=x+g.R.uniform(-2,2);zz=z+g.R.uniform(-2,2)
    g.specpart('Round4FlowerPatch','flower',xx,zz,y+1.2,2.4,2.4,1.2,[(240,184,74),(214,144,176),(231,220,157)][index%3])
# High contrast pad tops and edge bands; the four-stud voids remain real.
for p in g.PARTS:
 if p['category']=='jump':
  p['color']=[195,180,210];p['material']='Slate'
  x,y,wz=p['position'];sx,sy,sz=p['size'];top=y+sy/2
  g.specpart('Round4JumpPalePad','jump_read',x,-wz,top+.09,11.8,11.8,.16,(220,211,229),material='Slate')
  for dz in [-5.3,5.3]:g.specpart('Round4JumpAmberEdge','jump_read',x,-wz+dz,top+.22,10,.8,.22,(255,192,73))
g.emit()
# Exporter preserves baseline metadata explicitly.
out=json.loads((P/'scene.json').read_text())
for key,value in S.items():
 if key not in {'parts','routes'}:out[key]=value
(P/'scene.json').write_text(json.dumps(out,separators=(',',':')))
report={'lights_before':sum(p['category']=='light' for p in S['parts']),'lights_after':len(sites),'routes_equal':out['routes']==S['routes'],'baseline_scene_sha256':hashlib.sha256((P/'round4-baseline-scene.json').read_bytes()).hexdigest(),'parts_after':len(g.PARTS),'optional_gap_spec_z':[[-35,-29],[-51,-45]],'gap_width_x':[141,155]}
(P.parents[1]/'treasure/map-v4/ROUND4-GEOMETRY.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))

