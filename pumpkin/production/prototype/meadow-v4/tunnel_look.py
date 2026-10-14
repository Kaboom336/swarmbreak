"""Native cave art; unchanged routes, collision envelope and mud policy."""
import math, random

def crystal(g,name,x,z,h,w,color,r,lit=False):
 # Two opposed triangular prisms meet at a pointed ridge, with a tilted axis.
 yaw=r.uniform(-math.pi,math.pi);lean=r.uniform(-.22,.22)
 c,s=math.cos(yaw),math.sin(yaw);a,b=math.cos(lean),math.sin(lean)
 rot=[c*a,-c*b,s,b,a,0,-s*a,s*b,c]
 for side in [-1,1]:
  d=w*.85;off=side*d/4
  pos=[x+rot[2]*off,h/2+.3,-z+rot[8]*off]
  rr=rot if side<0 else [-rot[0],rot[1],-rot[2],-rot[3],rot[4],-rot[5],-rot[6],rot[7],-rot[8]]
  p=g.part(name,'tunnel_detail',pos,[w,h,d/2],color,material='Neon',shape='Wedge',rotation=rr)
  if lit and side<0:p['point_light']=True;p['light_brightness']=.7

def refine(g, edges, safe):
 r=random.Random(131026)
 def dist(x,z):return min(g.dist_segment(x,z,a,b) for a,b in edges)
 removed={'TunnelVaultRock','TunnelSouthVaultRock','TunnelRoofMoss','TunnelHangingMoss','TunnelMouthBrokenBrow','TunnelMouthMoss','TunnelStalactite','TunnelShaftOfLight','TunnelSkylightGlow','TunnelCrystal'}
 g.PARTS[:]=[p for p in g.PARTS if p['name'] not in removed and not (p['category']=='paving' and dist(p['position'][0],-p['position'][2])<10) and not (p['name']=='StonePathEdge' and dist(p['position'][0],-p['position'][2])<11)]
 tones=[(74,71,67),(90,87,81),(105,99,86),(70,80,86),(93,101,102)]
 for p in g.PARTS:
  if p['name'].startswith('tunnel_') and p['category']=='tunnel_floor':
   p['color']=[106,91,68];p['material']='Slate'
  if p['category']=='tunnel_rock':
   p['color']=list(r.choice(tones))
   if p['name'] in {'TunnelRockCourse','TunnelInnerRockFacet','TunnelMouthShoulder'}:
    p['shape']=r.choice(['Block','Wedge','Wedge'])
    # Varied angled facets stay inside the original safe envelope.
    x,y,nz=p['position'];sx,sy,sz=p['size']
    angle=r.uniform(-.22,.22);c=math.cos(angle);s=math.sin(angle)
    p['size']=[sx*.76,sy,sz*.76];p['rotation']=[c,0,s,0,1,0,-s,0,c]
    g.specpart('TunnelRoughRockCore','tunnel_rock',x,-nz,y,sx*.56,sz*.56,sy,tuple(p['color']),material='Slate',collide=True)
 # Closed tessellated vault over the complete route union. Two small real holes.
 holes=[(-75,-18),(-75,-46)]
 for x in range(-99,-39,3):
  for z in range(-102,28,4):
   if dist(x,z)>15:continue
   if any(abs(x-hx)<1 and abs(z-hz)<1 for hx,hz in holes):continue
   d=dist(x,z);bottom=30+max(0,7-d)*.67
   h=r.uniform(5,8)
   g.specpart('TunnelClosedVault','tunnel_roof',x,z,bottom+h/2,3.08,4.08,h,r.choice(tones),material='Slate',collide=True)
 # Broad irregular inclined rock ribs establish an arch beneath the sealed cap.
 for z in range(-74,28,7):
  if any(abs(z-hz)<5 for hx,hz in holes):continue
  for side in [-1,1]:
   a=[-76+side*14,z+r.uniform(-.5,.5),29+r.uniform(0,1)]
   b=[-76,z+r.uniform(-.5,.5),36+r.uniform(0,1)]
   g.segment('TunnelArchedRockRib',a,b,r.uniform(8,10),'tunnel_detail',False,4)
   p=g.PARTS[-1];p['material']='Slate';p['color']=list(r.choice(tones));p['collidable']=False
 for hx,hz in holes:
  g.specpart('TunnelSkylightGlow','light',hx,hz,30,.4,.4,.3,(255,229,157),material='Neon')
  g.specpart('TunnelShaftOfLight','tunnel_detail',hx,hz,15,2.5,3.2,29,(245,228,174),material='SmoothPlastic',shape='Wedge',transparency=.96)
 # Dirt skin and scattered flat stones: no paving rows or raised blockers.
 for a,b in edges:
  length=math.dist(a,b)
  for i in range(int(length/2)):
   t=(i+.5)/int(length/2);off=r.uniform(-6.3,6.3)
   x=a[0]+(b[0]-a[0])*t-(b[1]-a[1])/length*off
   z=a[1]+(b[1]-a[1])*t+(b[0]-a[0])/length*off
   g.specpart('TunnelDirtStone','tunnel_detail',x,z,.22+r.uniform(0,.1),r.uniform(1.4,4),r.uniform(1.3,4),r.uniform(.12,.28),r.choice([(123,108,80),(115,101,74),(139,130,107),(97,90,77)]),material='Slate',shape='Ball')
 for p in g.PARTS:
  if p['name']=='TunnelMud':p['color']=[66,68,51];p['transparency']=.12;p['position'][1]=.38
 for x,z,w,d in [(-78,-1,5,8),(-73,-8,4,6),(-78,-13,4,5)]:
  g.specpart('TunnelPuddle','tunnel_detail',x,z,.49,w,d,.08,(69,104,111),material='SmoothPlastic',shape='Ball',transparency=.2)
 # Dense blue crystal pockets and uneven mushroom colonies on route shoulders.
 for x,z in [(-84,14),(-68,-27),(-84,-39),(-68,-64),(-51,-88)]:
  for j in range(6):
   xx=x+r.uniform(-1.3,1.3);zz=z+r.uniform(-2,2);h=r.uniform(1.4,3.8)
   crystal(g,'TunnelBlueCrystal',xx,zz,h,r.uniform(1,1.7),(55,126+j*5,201),r,j==0)
  for j in range(5):
   xx=x+r.uniform(-1.5,1.5);zz=z+r.uniform(-3,3);h=r.uniform(.8,2)
   g.specpart('TunnelMushroomStem','tunnel_detail',xx,zz,h/2,.25,.25,h,(139,154,126))
   g.specpart('TunnelMushroomGlow','light',xx,zz,h,1.1,1.1,.45,(48,214,198),material='Neon',shape='Ball')
 # Moss patches and dangling roots attach to walls, outside the walking strip.
 anchors=[p for p in g.PARTS if p['name']=='TunnelInnerRockFacet' and 7<p['position'][1]<22]
 for p in anchors[::3]:
  x,y,nz=p['position'];sx,sy,sz=p['size'];z=-nz
  # Every colony starts within an authored wall mass, never at a free air slot.
  inward=1 if x<-76 else -1;face=x+inward*sx*.32
  g.specpart('TunnelWallMoss','tunnel_detail',face,z,y,.5,sz*.6,sy*.55,(55,91+r.randrange(30),48),material='Grass',shape='Wedge')
  for j in range(2):
   h=r.uniform(2,4);top=y+sy*.2
   angle=inward*r.uniform(.04,.13);c=math.cos(angle);s=math.sin(angle)
   g.specpart('TunnelWallRoot','tunnel_detail',face,z+j*.6,top-h/2,.24,.32,h,(88,66,40),material='Wood',rotation=[c,-s,0,s,c,0,0,0,1])
 # Cave mouth arch teeth remain above24; vines frame the open entrance.
 for j,x in enumerate(range(-89,-62,3)):
  bottom=24+max(0,8-abs(x+76))*.6;h=r.uniform(5,9)
  g.specpart('TunnelMouthRockTooth','tunnel_roof',x,25,bottom+h/2,4.5,7,h,r.choice(tones),material='Slate',shape='Wedge',rotation=[1,0,0,0,-1,0,0,0,-1])
  g.specpart('TunnelMouthCrown','tunnel_roof',x,24,bottom+h,5,8,5,r.choice(tones),material='Slate',collide=True,shape='Ball')
 for x in [-87,-85,-67,-65]:
  for j in range(3):
   h=r.uniform(6,12)
   g.specpart('TunnelEntranceVine','tunnel_detail',x+j*.4,28,28-h/2,.22,.3,h,(43,89,35),material='Grass')
   for y in range(17,28,2):g.specpart('TunnelVineLeaf','tunnel_detail',x+j*.4,28,y,.8,.4,.7,(67,116,42),material='Grass',shape='Wedge')
 for z in range(-70,23,9):
  for j in range(3):
   x=-76+r.uniform(-5,5);h=r.uniform(5,9);bottom=24.1
   g.specpart('TunnelStalactite','tunnel_detail',x,z+j*1.3,bottom+h/2,2.3,2.8,h,(104,103,94),material='Slate',shape='Wedge',rotation=[1,0,0,0,-1,0,0,0,-1])
 for x,z in [(-83,-75),(-57,-98)]:
  for j in range(5):
   h=r.uniform(1.2,3.4)
   crystal(g,'TunnelExitAmberCrystal',x+r.uniform(-1,1),z+r.uniform(-1,1),h,r.uniform(.8,1.4),(229,153+j*8,63),r,j==0)
 bury_in_hill(g,edges,safe,r)

def bury_in_hill(g,edges,safe,r):
 # The native grass shell is the shipped landform, not renderer-only scenery.
 greens=[(86,151,39),(88,154,40),(91,158,42)]
 holes=[(-76,-18),(-76,-46)]
 def height(x,z):
  center=-76+max(0,-z-55)*.25+3*math.sin((z+35)*.03)
  radius=61+4*math.sin(z*.045)
  cross=max(0,1-((x-center)/radius)**2)
  end=1 if -99<=z<=23 else max(0,1-((z-23)/32 if z>23 else (-99-z)/30)**2)
  return 52*cross*end*(1-.17*((z+35)/75)**2)
 # Continuous inclined turf strips, overlapping their seams by .08 studs.
 for z in range(-129,57,6):
  for x in range(-142,-22,6):
   if any(abs((x+3)-hx)<6 and abs(z-hz)<3.1 for hx,hz in holes):continue
   # Open mouth aprons: the hill face terminates at the portal, not in front.
   if z>23 and abs(x+3+76)<19:continue
   if z<-99 and abs(x+3+62)<17:continue
   ya=height(x,z);yb=height(x+6,z)
   if max(ya,yb)<.3:continue
   corners=[height(xx,zz) for xx in [x,x+6] for zz in [z-3,z+3]]
   if not safe(x+3,z,6.4,6.4) and min(corners)<25:continue
   # Tilt in BOTH terrain directions: a one-axis slope makes every row a rib.
   gx=(yb-ya)/6;gz=(height(x+3,z+3)-height(x+3,z-3))/6
   normal=[-gx,1,gz];nl=math.sqrt(sum(v*v for v in normal));normal=[v/nl for v in normal]
   u=[1,gx,0];ul=math.sqrt(1+gx*gx);u=[v/ul for v in u]
   v=[normal[1]*u[2]-normal[2]*u[1],normal[2]*u[0]-normal[0]*u[2],normal[0]*u[1]-normal[1]*u[0]]
   rot=[v[0],normal[0],u[0],v[1],normal[1],u[1],v[2],normal[2],u[2]]
   top=[x+3,height(x+3,z),-z];pos=[top[i]-normal[i]*.7 for i in range(3)]
   g.part('TunnelHillTurf','tunnel_hill',pos,[6.025/abs(v[2]),1.4,6.025/u[0]],greens[0],material='Grass',collide=True,rotation=rot)
   # A solid core fills only outside protected travel envelopes. Over routes
   # its underside stays above24, including the unchanged west surface hooks.
   bottom=-.3 if safe(x+3,z,6.12,6.12) else 24
   top=min(corners)-1.8
   if top>bottom:
    g.specpart('TunnelHillEarth','tunnel_hill',x+3,z,(top+bottom)/2,6.002,6.002,top-bottom,(74,81,64),material='Slate',collide=True)
 # Replace any old roof skin with real hill coverage; skylights remain open
 # through both vault and turf. Remove vault cells that overlap either hole.
 g.PARTS[:]=[p for p in g.PARTS if not (p['name']=='TunnelClosedVault' and any(abs(p['position'][0]-hx)<3 and abs(-p['position'][2]-hz)<4 for hx,hz in holes))]
 for hx,hz in holes:
  top=height(hx,hz)
  for dx,dz,sx,sz in [(-6,0,1.5,6),(6,0,1.5,6),(0,-3.8,10.5,1.5),(0,3.8,10.5,1.5)]:
   g.specpart('TunnelSkylightRockRim','tunnel_detail',hx+dx,hz+dz,top-1,sx,sz,3,(81,91,69),material='Slate')
 # Thick grass and irregular shrubs hide the rectilinear roof silhouette.
 for j in range(160):
  x=r.uniform(-127,-30);z=r.uniform(-103,24);y=height(x,z)
  if y<29 or any(math.hypot(x-hx,z-hz)<8 for hx,hz in holes):continue
  g.specpart('TunnelHillGrass','tunnel_detail',x,z,y+.45,r.uniform(.5,1.4),r.uniform(.6,1.5),.9,r.choice(greens),material='Grass',shape='Wedge')
 for x,z in [(-108,8),(-46,-18),(-113,-50),(-44,-69),(-85,-90),(-105,-20),(-52,12)]:
  y=height(x,z)
  for dx,dz in [(-2,0),(2,1),(0,-2)]:
   g.specpart('TunnelHillBush','tunnel_detail',x+dx,z+dz,y+1.7,5,5,4,(54,115,35),material='Grass',shape='Ball')
 for x,z,s in [(-107,2,.8),(-47,-24,.85),(-112,-57,.7),(-45,-73,.7),(-88,-89,.65)]:
  y=height(x,z)
  g.specpart('TunnelHillTreeTrunk','tunnel_detail',x,z,y+5*s,1.6*s,1.6*s,10*s,(103,71,38),material='Wood')
  for dx,dz,dy,w in [(0,0,11,9),(-3,0,10,7),(3,1,11,6),(0,-3,12,7),(0,1,15,6)]:
   g.specpart('TunnelHillTreeCrown','tunnel_detail',x+dx*s,z+dz*s,y+dy*s,w*s,w*s,5*s,(54,124,35),material='Grass',shape='Ball')
 # Rock brows and vines are inset into the grass faces at the preserved exits.
 for x,z in [(-76,25),(-76,-78),(-62,-99)]:
  for side in [-1,1]:
   for k in range(3):
    g.specpart('TunnelExitArchShoulder','tunnel_detail',x+side*(13+k*.9),z,7+k*7,7,7,9,(88+k*6,91+k*4,78+k*3),material='Slate',shape='Ball')
   g.specpart('TunnelExitMoss','tunnel_detail',x+side*10,z+3,22,3,1,9,(58,110,39),material='Grass',shape='Wedge')
   for j in range(3):
    g.specpart('TunnelExitVine','tunnel_detail',x+side*(9+j),z-3,20,.24,.3,12-j*2,(42,91,34),material='Grass')
  for off in [-7,0,7]:
   g.specpart('TunnelExitArchCrown','tunnel_detail',x+off,z,29+3*(1-abs(off)/8),10,8,8,(98,99,82),material='Slate',shape='Ball')
  for off in [-16,-10,0,10,16]:
   g.specpart('TunnelMouthCliffFace','tunnel_detail',x+off,z,38+3*(1-abs(off)/18),13,7,13,(93,98,83),material='Slate',shape='Ball')
  for side in [-1,1]:
   for k in range(6):
    g.specpart('TunnelArchMossColony','tunnel_detail',x+side*(11+k%3),z+4,25+k*2,3,1.5,3,(58,111,38),material='Grass',shape='Ball')
  if z<0:
   p=g.specpart('TunnelWarmExitLight','tunnel_detail',x,z-2,18,.3,.3,.3,(255,203,120),transparency=1)
   p['point_light']=True;p['light_brightness']=5
 for p in g.PARTS:
  if p['name']=='TunnelSkylightGlow':p['light_brightness']=7;p['position'][1]=27
 # The old straight peaked lintel is fully replaced by the inset rock arch.
 g.PARTS[:]=[p for p in g.PARTS if p['name'] not in {'TunnelMouthRockTooth','TunnelMouthCrown'}]
