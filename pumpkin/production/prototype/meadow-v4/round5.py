"""R5 authored island masses and curated prop pockets. Rebuilds saved R4 once.
Never reads/writes guardian source/place or Keeper art. Source edits: apply_patch.
"""
import json,math,random,importlib.util,hashlib
from pathlib import Path
import geometry as g
H=Path(__file__).parent;O=H.parents[1]/'treasure/map-v4'
spec=importlib.util.spec_from_file_location('pa',H/'placement-audit.py');pa=importlib.util.module_from_spec(spec);spec.loader.exec_module(pa)
S=json.loads((H/'round5-baseline-scene.json').read_text());r=random.Random(51013)
remove={'tree','bush','cover','boulder','flower','fence','lantern','light','ground_detail','west_landmark','east_landmark','bridge_landmark','jump_landmark','banner'}
extra={'MossTuft','BoulderMossLip','BoulderLightFacet','BoulderMossPatch','BoulderSlopedCrown','BoulderMossIsland','SummitRockMoss','Round4BoulderFacet','Round4StepMoss','Round4UndersideMoss'}
def ravine(p):return abs(p['position'][0])<90 and abs(p['position'][2])<35
g.PARTS[:]=[p for p in S['parts'] if p['category'] not in remove and p['name'] not in extra and not(p['category']=='underside' and not ravine(p))]
g.ROUTES.update(S['routes']);g.R=random.Random(51013)
# Move only the isolated stand-in art to the front of the existing summit court
# so the objective and Keeper torso read from portal eye height. No guardian code.
for p in g.PARTS:
 if p['category']=='keeper':p['position'][2]+=15
 if p['category']=='treasure':p['position'][2]+=12
# Cosmetic coplanar lip joins caused the black square seams in player views.
# Give overlapping moss pieces distinct shallow surface levels; path solids,
# support heights and original ravine construction remain unchanged.
for i,p in enumerate(g.PARTS):
 if not ravine(p) and p['category']=='grass' and p['name'] in {'ThickMossLip','Round4OverhangLip','Round4RockMoss','Round4ShelfMossLedge'}:
  p['position'][1]+=.014+i*.000009
 if not ravine(p) and p['category']=='terrain_cap':p['position'][1]-=.035+i*.0000007
def yaw(a):c=math.cos(a);s=math.sin(a);return [c,0,s,0,1,0,-s,0,c]
def block(n,cat,x,z,y,sx,sz,sy,color,**kw):return g.specpart(n,cat,x,z,y,sx,sz,sy,color,**kw)

# Five offset, connected geological tiers. Partition widths and row depths vary;
# the shell is dense construction, not a scatter of separate repeating pillars.
tiers=[(0,0,159,-20,-68),(-19,12,113,-60,-125),(9,-17,75,-112,-178),(-24,-4,40,-165,-226),(-39,-13,12,-213,-247)]
for tier,(cx,cz,rad,top,low) in enumerate(tiers):
 z=cz-rad-7
 while z<cz+rad:
  dz=r.uniform(16,29) if tier<3 else r.uniform(10,18)
  x=cx-rad-7
  while x<cx+rad:
   dx=r.uniform(18,34) if tier<3 else r.uniform(10,22)
   xx=x+dx/2;zz=z+dz/2;a=math.atan2(zz-cz,xx-cx)
   silhouette=max(4,rad-28)*(1+.065*math.sin(3*a+tier)+.045*math.sin(7*a+.8*tier))
   if math.hypot(xx-cx,zz-cz)<silhouette:
    t=top+r.uniform(-3,3);b=low+r.uniform(-6,5)
    if tier==4:b=max(b,-239)
    if tier==0 and abs(xx)<100 and abs(zz)<47:t=min(t,-42)
    shade=r.randrange(-9,10);base=[135-tier*13,132-tier*13,146-tier*12]
    block('R5MountainTier'+str(tier+1),'underside',xx,zz,(t+b)/2,dx+3,dz+3,t-b,[v+shade for v in base],material='Slate',rotation=yaw(r.uniform(-.035,.035)))
   x+=dx
  z+=dz
 # Broken, overlapping face masses hide the buried core. Three staggered rows
 # per large tier have different setbacks; no full-height facade columns.
 for row in range(3 if tier<4 else 2):
  rows=3 if tier<4 else 2;a=row*.31+tier*.43
  while a<math.tau+row*.31+tier*.43:
   width=r.uniform(17,31) if tier<3 else r.uniform(10,18)
   radius=max(5,min(rad-13,rad-20-row*3+rad*(.13*math.sin(3*a+tier)+.065*math.sin(7*a+row))))
   xx=cx+radius*math.cos(a);zz=cz+radius*math.sin(a)
   yy=top-(top-low)*(row+.52)/rows+r.uniform(-3,3)+8*math.sin(3*a+tier)+4*math.sin(7*a+row)
   height=(top-low)/rows+r.uniform(4,10)
   if tier==4:yy=max(yy,-244+height/2)
   if tier==0 and abs(xx)<100 and abs(zz)<47:yy=min(yy,-44-height/2)
   base=[136-tier*13,132-tier*13,146-tier*12];shade=r.randrange(-10,11)
   block('R5IrregularRockFace','underside',xx,zz,yy,width,r.uniform(20,30) if tier<3 else r.uniform(9,16),height,[v+shade for v in base],material='Slate',rotation=yaw(a+math.pi/2+r.uniform(-.13,.13)),shape='Wedge' if tier>0 and r.random()<.22 else 'Block')
   a+=width*.70/max(radius,10)
# A second, shorter hanging tooth is deliberately offset from the main point.
for x,z,y,w,h in [(-39,-13,-247,10,14),(-39,-13,-256,5,10),(-39,-13,-263,2.5,7),(51,31,-224,8,14),(51,31,-234,3,8)]:
 block('R5HangingApex','underside',x,z,y,w,w,h,(70,69,83),material='Slate')
for k,(x,z,rad,t,b) in enumerate([(47,30,29,-151,-193),(51,31,16,-185,-221)]):
 for dx,dz,w,h in [(-8,-5,21,19),(8,4,18,23),(0,0,25,25)]:
  block('R5SecondaryHangingPoint','underside',x+dx*.6,z+dz*.6,(t+b)/2,w,h,t-b,(80-k*12,78-k*11,96-k*12),material='Slate',rotation=yaw(.09-k*.16))

# Surface moss stays attached to the lip. Four sparse roots emerge below it.
for x,z,turn in [(-142,-77,.18),(-157,28,-.3),(92,-135,.25),(151,40,-.2)]:
 y=pa.Terrain(g.PARTS).top(x,-z)
 if y is None:continue
 length=math.hypot(x,z);nx,nz=x/length,z/length
 for j in range(3):
  block('R5LipRoot','root',x+nx*(4+j*3),z+nz*(4+j*3),y-5-j*9,3.5-j*.7,3.1,18-j*2,(99-j*8,68-j*6,43-j*4),material='Wood',rotation=yaw(turn+j*.1))
for x,z,y,w in [(-30,-38,-256,7),(8,12,-250,5),(65,28,-233,6),(-51,3,-242,4)]:
 block('R5IntentionalFloatingRock','floating_rock',x,z,y,w,w*.8,w*1.4,(78,77,92),material='Slate',rotation=yaw(.37))

# Actual narrow bridge edge beams support all fence feet; walking deck unchanged.
for p in S['parts']:
 if p['name'] not in {'bridge1','bridge2','bridge3'}:continue
 for side in [-1,1]:
  q=dict(p);q['position']=list(p['position']);q['size']=list(p['size'])
  q['name']='R5BridgeGuardBeam';q['category']='bridge_structure';q['position'][0]=side*11.2;q['size'][0]=4.6
  q['color']=[118,77,43];q['material']='Wood';g.PARTS.append(q)
terrain=pa.Terrain(g.PARTS)
construction=pa.Construction(g.PARTS)
# Summit banners are supported within the trimmed court. The old poles sat on
# lower shoulder terrain and one cloth projected into the spiral reserve.
for index,(x,z) in enumerate([(-11,119),(7,122)]):
 y=terrain.top(x,-z);identifier=f'R5-banner-{index}'
 root=block('R5BannerPole','banner',x,z,y+6,.7,.7,12,(117,76,42),material='Wood')
 cloth=block('R5LeafBanner','banner',x+1.4,z,y+8,3.3,.45,5.5,(60,139,58))
 emblem=block('R5BannerEmblem','banner',x+1.4,z-.3,y+8,1,.2,1.8,(168,207,91))
 for p in [root,cloth,emblem]:p['assembly']=identifier;p['prop_kind']='banner';p['root']=p is root
edges=[(a,b,rr['width']/2) for rr in S['routes'].values() for a,b in zip(rr['points'],rr['points'][1:])]
def clear_path(x,z,radius):return all(g.dist_segment(x,z,a,b)>=w+radius+.55 for a,b,w in edges)
placed=[[p for p in g.PARTS if p.get('assembly')==f'R5-banner-{index}'] for index in range(2)];clusters={};serial=0
def asm(kind):
 global serial
 serial+=1;return f'R5-{kind}-{serial}'
def mark(parts,identifier,kind,roots):
 for p in parts:p['assembly']=identifier;p['prop_kind']=kind;p['root']=p in roots
 return parts
def candidate(kind,x,z,scale=1):
 y=terrain.top(x,-z)
 if y is None:return []
 start=len(g.PARTS);ident=asm(kind)
 if kind in {'tree','oak_landmark'}:
  h=13*scale
  root=block('R5OakTrunk','tree',x,z,y+h/2,2.8*scale,2.8*scale,h,(117,76,42),material='Wood')
  # A broad asymmetric crown with a visible lifted trunk; six masses per oak.
  for dx,dz,yy,w,hc in [(0,0,14,10,6),(-3.8,0,13,6.5,5),(3.2,1.4,15,6,5),(0,-3,15,6,5),(-1,2.8,18,6.5,5),(1.4,0,20,4.8,4)]:
   block('R5OakCrown','tree',x+dx*scale,z+dz*scale,y+yy*scale,w*scale,w*scale,hc*scale,(49+r.randrange(12),128+r.randrange(26),39+r.randrange(12)))
 elif kind in {'boulder','cover','spire_landmark'}:
  w=6.8*scale;h=8.2*scale
  if kind=='spire_landmark':w=5.5*scale;h=29*scale
  root=block('R5BoulderFoot','boulder',x,z,y+h*.35,w*.8,w*.8,h*.7,(124,122,136),material='Slate',collide=kind=='cover')
  block('R5BoulderShoulder','boulder',x-w*.06,z+w*.03,y+h*.64,w,w*.85,h*.6,(151,148,162),material='Slate',rotation=yaw(.11),shape='Wedge')
  block('R5BoulderFacet','rock_cap',x+w*.12,z-w*.08,y+h*.8,w*.65,w*.6,h*.36,(181,178,188),material='Slate',rotation=yaw(-.19),shape='Wedge')
  block('R5BoulderMoss','grass',x-w*.12,z+w*.1,y+h*.72,w*.28,w*.32,.4,(105,155,65))
 elif kind=='bush':
  w=6*scale;root=block('R5BushFoot','bush',x,z,y+1.5*scale,w,w,3*scale,(64,133,43))
  block('R5BushCrown','bush',x-scale,z+scale,y+3*scale,w*.7,w*.7,2*scale,(99,163,55))
  block('R5BushSide','bush',x+w*.25,z-w*.22,y+1.8*scale,w*.75,w*.72,2.8*scale,(79,146,48))
 elif kind=='flower':
  root=block('R5FlowerLeaves','flower',x,z,y+.45,1.4*scale,1.4*scale,.9,(84,141,46))
  block('R5FlowerStem','flower',x,z,y+1.2,.28,.28,2.4,(66,120,41))
  block('R5FlowerPetals','flower',x,z,y+2.15,3.6*scale,3.6*scale,.65,(240,190,88))
  block('R5FlowerCentre','flower',x,z,y+2.53,.65,.65,.3,(251,229,158))
 elif kind=='lantern':
  root=block('R5LampFoot','lantern',x,z,y+.2,2.4,2.4,.4,(139,132,150),material='Slate')
  g.lantern(x,z,y+.4)
 else:raise ValueError(kind)
 made=g.PARTS[start:];del g.PARTS[start:]
 return mark(made,ident,'tree' if kind=='oak_landmark' else 'boulder' if kind=='spire_landmark' else kind,[root])

def segment_hit(eye,target,p,pad=1.5):
 b=pa.bounds(p);d=[target[i]-eye[i] for i in range(3)];lo=0;hi=1
 for i in range(3):
  if abs(d[i])<1e-8:
   if not b[i]-pad<=eye[i]<=b[i+3]+pad:return False
  else:
   a=(b[i]-pad-eye[i])/d[i];c=(b[i+3]+pad-eye[i])/d[i]
   lo=max(lo,min(a,c));hi=min(hi,max(a,c))
   if hi<lo:return False
 return True
portal=[0,5.5,116]
sightlines=[(portal,[-114,25,84]),(portal,[110,29,114]),(portal,[0,53,-96]),(portal,[0,10,-29])]
keeper=[-7,57,-99]
throwlines=[(keeper,[x,h+5.5,-z]) for x,z,h in [(-100,-24,0),(-76,-78,0),(0,-48,0),(110,-60,20),(70,39,0)]]
def valid(parts,check_sight=True):
 if not parts:return False
 for p in parts:
  b=pa.bounds(p);x,z=p['position'][0],-p['position'][2]
  if construction.clips(p):return False
  radius=math.hypot((b[3]-b[0])/2,(b[5]-b[2])/2)
  if p['category']!='fence' and not clear_path(x,z,radius):return False
  if p.get('prop_kind')=='flower':
   distance=min(g.dist_segment(x,z,a,b)-w for a,b,w in edges)
   if not .3<=distance<=6:return False
  if p['category']=='fence':
   probe=pa.footprint(p)
   for lane in g.PARTS:
    if lane['category'] not in {'lane','bridge','jump_access'}:continue
    lb=pa.bounds(lane)
    if b[1]>lb[4]+20 or b[4]<lb[1]-.2:continue
    q=pa.footprint(lane)
    if pa.boxes_overlap(probe,q):
     print('Fence lane rejection',p['name'],p['position'],lane['name']);return False
  if p.get('root'):
   for u,v in [(0,0),(-.98,-.98),(-.98,.98),(.98,-.98),(.98,.98)]:
    xx=x+p['size'][0]*u/2;zz=-z+p['size'][2]*v/2
    top=terrain.top(xx,zz);bot=pa.vertical(p,xx,zz)
    if top is None or bot is None or abs(bot[0]-top)>.19:
     if p['category']=='fence':print('Fence ground rejection',p['position'],xx,zz,top,bot)
     return False
  if any(pa.boxes_overlap(p,q,.001) for a in placed for q in a):
   if p['category']=='fence':print('Fence prop rejection',p['position'])
   return False
  if check_sight and p['category']=='tree' and any(segment_hit(a,b,p) for a,b in (sightlines[1:] if p.get('landmark_target') else sightlines)+throwlines):return False
 return True
def accept(parts,cluster=None):
 if not valid(parts):return False
 g.PARTS.extend(parts);placed.append(parts)
 if cluster:clusters.setdefault(cluster,[]).append(parts[0]['assembly'])
 return True

# Route landmarks are deliberately composed before secondary vegetation.
# Their broad silhouettes lie outside the walking lanes and tree reservations.
for label,kind,sites in [('west-oak','oak_landmark',[(-114,-84,1.2),(-123,-98,.65),(-112,-105,.55)]),('east-spires','spire_landmark',[(110,-114,1.1),(104,-112,.5),(112,-105,.5)])]:
 for x,z,s in sites:
  parts=candidate(kind,x,z,s)
  if label=='west-oak' and x==-114:
   for p in parts:p['landmark_target']='west'
  accept(parts,label)

# Authored five-member pockets: one large and one small oak, one middle stone,
# then small bushes. The offsets are design data, not a random scatter/grid.
centres=[(-135,-48),(-137,22),(-130,82),(-93,128),(-57,138),(-60,-60),(-44,-101),(57,-111),(68,-61),(78,2),(145,43),(73,91),(70,130)]
offsets=[(0,0,'tree',.82),(-15,5,'tree',.55),(12,8,'boulder',.8),(-5,-13,'bush',.8),(11,-9,'bush',.6),(0,13,'boulder',.55),(-12,-9,'bush',.55)]
for index,(cx,cz) in enumerate(centres):
 label=f'pocket-{index+1}'
 for dx,dz,kind,s in offsets:
  if len(clusters.get(label,[]))>=5:break
  turn=[0,.65,-.4,.9,-.9,.25][index%6];c=math.cos(turn);sn=math.sin(turn)
  dx,dz=dx*c-dz*sn,dx*sn+dz*c;s*=1+[.1,-.08,.06,-.05][index%4]
  # Small deliberate placement corrections on stepped native terrain.
  for ox,oz in [(0,0),(2,0),(0,2),(-2,0),(0,-2),(3,3),(-3,-3)]:
   if accept(candidate(kind,cx+dx+ox,cz+dz+oz,s),label):break
 if 0<len(clusters.get(label,[]))<3:
  ids=set(clusters.pop(label));g.PARTS[:]=[p for p in g.PARTS if p.get('assembly') not in ids];placed[:]=[a for a in placed if a[0]['assembly'] not in ids]

# West cover is low, separated and placed against the outer lane shoulder.
for i,(x,z) in enumerate([(-120,-9),(-116,-43),(-73,-113)]):
 label=f'west-cover-{i+1}'
 for dx,dz,s in [(0,0,1.5),(-11,6,.9),(-7,-10,.55)]:accept(candidate('cover',x+dx,z+dz,s),label)

# Flowers occupy short, authored edge runs at selected turns, not field centres.
for label,name,index,side in [('flowers-west','west',35,-1),('flowers-south','west',50,1),('flowers-east','east_descent',14,-1),('flowers-fork','east',7,-1)]:
 pts=S['routes'][name]['points'];i=min(index,len(pts)-2);a,b=pts[i:i+2];dx=b[0]-a[0];dz=b[1]-a[1];run=math.hypot(dx,dz)
 if run<.01:continue
 for along,s in [(-4,.65),(-1,.9),(2,.75),(5,.55)]:
  x=(a[0]+b[0])/2+dx/run*along-dz/run*side*12.5;z=(a[1]+b[1])/2+dz/run*along+dx/run*side*12.5
  accept(candidate('flower',x,z,s),label)

# Finish incomplete edge/cover groups around their authored anchor; delete a
# pocket that cannot hold three separate grounded members instead of leaving
# isolated scatter. No fabricated grouping of distant objects.
for label,ids in list(clusters.items()):
 if len(ids)>=3:continue
 first=next(a for a in placed if a[0]['assembly']==ids[0]);root=next(p for p in first if p.get('root'))
 x,z=root['position'][0],-root['position'][2]
 if label.startswith('flowers'):
  a,b,w=min(edges,key=lambda edge:g.dist_segment(x,z,edge[0],edge[1]))
  dx,dz=b[0]-a[0],b[1]-a[1];run=math.hypot(dx,dz)
  nudges=[(dx/run*t,dz/run*t) for t in [3,-3,6,-6,9,-9]];kind='flower'
 else:nudges=[(4,5),(-4,5),(6,-4),(-6,-4),(0,8),(8,0),(-8,0)];kind='bush'
 for dx,dz in nudges:
  if len(clusters[label])>=3:break
  accept(candidate(kind,x+dx,z+dz,.45),label)
 if len(clusters[label])<3:
  bad=set(clusters.pop(label));g.PARTS[:]=[p for p in g.PARTS if p.get('assembly') not in bad];placed[:]=[a for a in placed if a[0]['assembly'] not in bad]

# Pairs only, at bridge ends, portal junction, summit and fork/shelf junctions.
light_pairs=[((-19,-147),(19,-147)),((-13,121),(13,121)),((18,62),(20,70)),((16,-30),(20,-42))]
accepted_pairs=[]
for a,b in light_pairs:
 aa=candidate('lantern',*a);bb=candidate('lantern',*b)
 if valid(aa) and valid(bb) and not any(pa.boxes_overlap(p,q) for p in aa for q in bb):
  g.PARTS.extend(aa+bb);placed.extend([aa,bb]);accepted_pairs.append([a,b])

def fence_line(x1,z1,x2,z2,label):
 start=len(g.PARTS);dist=math.hypot(x2-x1,z2-z1);n=max(1,math.ceil(dist/8));roots=[];ident=asm('fence')
 points=[]
 for i in range(n+1):
  x=x1+(x2-x1)*i/n;z=z1+(z2-z1)*i/n;y=terrain.top(x,-z)
  if y is None:del g.PARTS[start:];return
  points.append((x,z,y))
  roots.append(block('R5FencePost','fence',x,z,y+2.25,.8,.8,4.5,(118,77,43),material='Wood'))
 for a,b in zip(points,points[1:]):
  for h in [1.35,3.25]:g.segment('R5FenceRail',(a[0],a[1],a[2]+h),(b[0],b[1],b[2]+h),.5,'fence',False,.5)
 parts=g.PARTS[start:];del g.PARTS[start:];mark(parts,ident,'fence',roots)
 for p in parts:p['color']=list(g.WOOD);p['material']='Wood';p['collidable']=False
 if valid(parts):g.PARTS.extend(parts);placed.append(parts)
 else:raise AssertionError('Fence contact/placement '+label)
for side in [-1,1]:fence_line(side*11.6,-24,side*11.6,24,'bridge')
for coords in [(-142,-94,-132,-117),(138,69,145,90),(-59,146,-80,146)]:
 # Optional landscape runs are included only if every endpoint is supported.
 try:fence_line(*coords,'landscape')
 except AssertionError:pass

g.emit();out=json.loads((H/'scene.json').read_text())
for k,v in S.items():
 if k not in {'parts','routes'}:out[k]=v
out['r5']={'clusters':clusters,'lantern_pairs':accepted_pairs,'tier_data':tiers,'sightlines':sightlines,'throw_chords':throwlines,'ground_contact_tolerance':.2}
out['summit']=[0,96,48]
(H/'scene.json').write_text(json.dumps(out,separators=(',',':')))
bottom=min(pa.bounds(p)[1] for p in g.PARTS if p['category']=='underside')
stones=[pa.bounds(p) for p in g.PARTS if p['name']=='SolidMountainStone'];width=max(b[3] for b in stones)-min(b[0] for b in stones)
report={'parts':len(g.PARTS),'cluster_sizes':{k:len(v) for k,v in clusters.items()},'light_pairs':accepted_pairs,'underside_tiers':5,'hanging_points':2,'underside_bottom_studs':bottom,'terrain_width_studs':width,'depth_width_ratio':-bottom/width,'routes_equal':out['routes']==S['routes'],'source_sha256':hashlib.sha256((H/'round5.py').read_bytes()).hexdigest()}
(O/'ROUND5-GEOMETRY.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
