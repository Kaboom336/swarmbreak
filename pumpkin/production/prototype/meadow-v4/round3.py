"""Round 3: reuse the local native part exporter, with new winding solid terrain.
No external art/code imports; does not read or mutate guardian or animation code.
"""
import math,json
import geometry as g
g.ROCK=(137,126,148);g.GREEN=(100,177,44)
g.build()
g.PARTS[:]=[p for p in g.PARTS if p['category'] in {'keeper','treasure','portal_arch','portal_glow'}]
for p in g.PARTS:
    if p['category'] in {'keeper','treasure'}:p['position'][1]+=24
g.ROUTES.clear()

def curve(points,steps=8):
    # Catmull-Rom in the horizontal plane; flat waypoints stay flat.
    out=[]
    for i in range(len(points)-1):
        a=points[max(0,i-1)];b=points[i];c=points[i+1];d=points[min(len(points)-1,i+2)]
        for j in range(steps):
            t=j/steps
            out.append(tuple(.5*((2*b[k])+(-a[k]+c[k])*t+(2*a[k]-5*b[k]+4*c[k]-d[k])*t*t+(-a[k]+3*b[k]-3*c[k]+d[k])*t**3) for k in range(2))+(b[2]+(c[2]-b[2])*t,))
    return out+[points[-1]]

def round_flat(points):
    out=[points[0]]
    for a,b,c in zip(points,points[1:],points[2:]):
        if a[2]==b[2]==c[2]:
            u=(a[0]-b[0],a[1]-b[1]);v=(c[0]-b[0],c[1]-b[1]);lu=math.hypot(*u);lv=math.hypot(*v)
            if lu and lv and abs((u[0]*v[0]+u[1]*v[1])/(lu*lv))<.9:
                cut=min(6,lu/2,lv/2);p=(b[0]+u[0]/lu*cut,b[1]+u[1]/lu*cut,b[2]);q=(b[0]+v[0]/lv*cut,b[1]+v[1]/lv*cut,b[2])
                out.append(p)
                for j in range(1,7):
                    t=j/6;out.append(tuple((1-t)**2*p[k]+2*t*(1-t)*b[k]+t*t*q[k] for k in range(3)))
                continue
        out.append(b)
    return out+[points[-1]]

g.surface('SummitCampNS',0,108,48,24,32,'court')
g.surface('SummitCampEW',0,108,48.003,32,24,'court')
g.route('summit_radial',[(0,108,48),(30,108,48)])
spiral=[]
for i in range(97):
    t=i/96;a=t*math.pi*1.5;r=30+20*t
    h=48*max(0,min(1,(1-t-.09)/.82))
    spiral.append((r*math.cos(a),108+r*math.sin(a),h))
g.route('spiral',spiral)
g.route('fork_link',curve([(0,58,0),(-2,52,0),(0,42,0)],4))
g.surface('ForkCourt',0,42,0,28,28,'court')
# Full 28-stud inclined runs, separated by flat turning pads.
g.route('shelf',round_flat([(30,108,48),(57,108,48),(85,108,36),(104,108,36),
                 (104,128,36),(124,128,36),(124,112,36),(124,84,24),(124,72,24),(113,72,24),
                 (85,72,12),(74,72,12),(46,72,0),(37,72,0)]))
g.route('shelf_link',curve([(37,72,0),(28,53,0),(16,42,0),(0,42,0)],5))
g.route('west',curve([(0,42,0),(-43,48,0),(-76,27,0),(-100,-8,0),
                      (-95,-46,0),(-76,-78,0),(-56,-106,0),(-24,-136,0)]))
g.route('bridge',[(0,42,0),(0,30,0),(0,18,4),(0,-18,4),(0,-30,0),(0,-42,0)],cat='bridge')
g.route('bridge_south',curve([(0,-42,0),(7,-65,0),(0,-90,0),(0,-116,0)]),cat='bridge')
g.route('east',curve([(0,42,0),(43,47,0),(69,28,0),(91,18,0),(110,18,0)]))
g.route('east_climb',[(110,18,0),(110,9,0),(110,-15,10),(110,-39,20),(110,-60,20)])
g.surface('RidgeThrowCourt',110,-60,20,24,24,'court')
descent=curve([(110,-60,20),(112,-80,20),(90,-108,10),(62,-135,0),(24,-136,0)],12)
# Ease the continuous downhill height against arc distance, with flat tangents.
dist=[0]
for a,b in zip(descent,descent[1:]):dist.append(dist[-1]+math.hypot(b[0]-a[0],b[1]-a[1]))
descent=[(p[0],p[1],20*(1-(max(0,min(1,(d-20)/(dist[-1]-46))))**2*(3-2*max(0,min(1,(d-20)/(dist[-1]-46)))))) for p,d in zip(descent,dist)]
g.route('east_descent',descent)
g.route('north_crosslink',curve([(-76,27,0),(-65,43,0),(-32,48,0),(0,42,0),(35,46,0),(69,28,0)]))
g.route('south_crosslink',curve([(-76,-78,0),(-38,-99,0),(0,-100,0),(24,-129,0),(24,-136,0)]))
g.route('portal_north',curve([(0,-78,0),(4,-96,0),(0,-116,0),(0,-136,0)]))
# One long walkout, connected at the west route; bottom loop has no hanging ends.
g.route('ravine_ramp',[(-22,0,-32),(-22,-18,-32),(-22,-88,0),(-22,-102,0),(0,-100,0)])
g.route('ravine_floor_loop',[(-22,0,-32),(-22,4,-32),(61,4,-32),(61,-4,-32),(-22,-4,-32),(-22,0,-32)])
# Optional parkour remains independent; a missed gap has reachable ridge ground.
for i in range(3):g.surface('OptionalJumpLanding'+str(i),148,-24-i*16,20+i*2,12,12,'jump')
g.route('jump_access',[(110,-60,20),(128.8,-60,20),(128.8,0,20),(148,0,20),(148,-24,20)],cat='jump_access')
g.route('jump_recovery',[(148,-56,24),(148,-65,24),(148,-75,20),(148,-84,20),(125,-84,20),(125,-72,20),(110,-72,20),(110,-60,20)],cat='jump_access')
g.surface('PortalPad',0,-136,0,32,24,'portal')
g.surface('ProtectedPortalApron',0,-136,0,48,40,'protected')
edges=[(a,b,r['width']/2) for r in g.ROUTES.values() for a,b in zip(r['points'],r['points'][1:])]
def near(x,z,margin=0):return [(a,b,w) for a,b,w in edges if g.dist_segment(x,z,a,b)<=w+margin]
def height(x,z,a,b):
    dx=b[0]-a[0];dz=b[1]-a[1];n=dx*dx+dz*dz
    t=max(0,min(1,((x-a[0])*dx+(z-a[1])*dz)/n)) if n else 0
    return a[2]+(b[2]-a[2])*t
def outline(x,z):
    a=math.atan2(z,x);r=164+7*math.sin(3*a+.5)+5*math.sin(7*a)+3*math.sin(11*a)
    return math.hypot(x,z)<r
def wanted(x,z):
    rr=math.hypot(x/1.18,z-108)
    h=48 if rr<25 else 36 if rr<49 else 24 if rr<74 else 12 if rr<97 else 0
    if z<36:h=0
    if ((x-112)/33)**4+((z+36)/64)**4<1:h=max(h,20)
    if abs(x)<79 and abs(z)<16:h=-32
    if -137<x<-118 and -66<z<57:h=max(h,12)
    return h
g.PARTS[:]=[p for p in g.PARTS if p['category']!='paving']
lanes=[p for p in g.PARTS if p['category'] in {'lane','bridge','court','portal','protected','jump_access','jump'}]
for i,p in enumerate(lanes):
    if p['category'] in {'lane','bridge','jump_access'}:p['position'][1]+=i*.0008
tops={}
for x in range(-174,176,4):
    for z in range(-174,176,4):
        if not outline(x,z):continue
        h=wanted(x,z);nb=near(x,z,3.5)
        if nb:h=min(h,math.floor((min(height(x+dx,z+dz,a,b) for a,b,w in nb for dx,dz in [(-2,-2),(-2,2),(2,-2),(2,2)])-1.2)/2)*2)
        for cx,cz,cy,sx,sz in [(0,108,48,32,32),(110,-60,20,24,24),(0,42,0,28,28),(0,-136,0,48,40)]:
            if abs(x-cx)<sx/2+3 and abs(z-cz)<sz/2+3:h=min(h,cy-1.4)
        tops[x,z]=h
        bottom=-54-3*math.sin(x/18)*math.cos(z/21)
        shade=g.R.randint(-6,6)
        g.specpart('SolidMountainStone','terrace',x,z,(bottom+h)/2,4,4,h-bottom,tuple(v+shade for v in g.ROCK),material='Slate',collide=True)
        g.specpart('MountainMossTop','terrain_grass',x,z,h-.15,4,4,.4,tuple(v+g.R.randint(-6,6) for v in g.GREEN),material='Grass')
def ground(x,z):return tops.get((round((x+174)/4)*4-174,round((z+174)/4)*4-174),0)
def clear(x,z,margin=0):
    return outline(x,z) and not (abs(x)<90 and abs(z)<35) and not near(x,z,margin) and not(abs(x)<28 and -165<z<-105) and not(abs(x)<26 and 84<z<132)
# Flush solid ramp supports, copied from the tested local rebuild.
for p in lanes:
    if p['category'] in {'jump','portal','protected'}:continue
    s=p['size'];r=p['rotation'];pos=p['position']
    if p['category']=='bridge' and abs(pos[2])<19:continue
    mid=[pos[j]-r[j*3+1]*s[1]/2 for j in range(3)]
    run=s[2]*math.hypot(r[2],r[8]);rise=s[2]*abs(r[5]);sign=1 if r[5]>=0 else -1
    zx=r[2]*s[2]/run*sign;zz=r[8]*s[2]/run*sign;yaw=[zz,0,zx,0,1,0,-zx,0,zz]
    low=mid[1]-rise/2;depth=low+54
    if rise>.001:g.part('SolidRampWedge','path_rock',(mid[0],mid[1]+.01,mid[2]),(s[0],rise+.02,run),g.ROCK,'Slate',False,yaw,shape='Wedge')
    g.part('SolidRampBody','path_rock',(mid[0],low-depth/2,mid[2]),(s[0],depth,run),g.ROCK,'Slate',False,yaw)
    p['color']=list(g.ROCK);p['material']='Slate'
    g.part('GrassShoulder','terrain_cap',tuple(pos[j]+r[j*3+1]*(s[1]/2+.03) for j in range(3)),(s[0],.1,s[2]),g.GREEN,'Grass',False,r)
# Bigger stone faces, broken courses, mossy lips on every height transition.
for (x,z),h in tops.items():
    for dx,dz in [(4,0),(0,4),(-4,0),(0,-4)]:
        low=tops.get((x+dx,z+dz),-35)
        if low>=h-3:continue
        if (x+z)%8:continue
        for y in range(int(low)+3,int(h),7):
            shade=g.R.randint(-13,13)
            g.specpart('GreyCliffBlock','cliff',x+dx*.46,z+dz*.46,y-1,7.6 if dz else 1.3,7.6 if dx else 1.3,6.8,tuple(v+shade for v in g.ROCK),material='Slate')
        if not near(x+dx*.5,z+dz*.5,2):g.specpart('ThickMossLip','grass',x+dx*.4,z+dz*.4,h+.05,5 if dz else 1.8,5 if dx else 1.8,1.1,(130,194,43))
# Strongly tapered underside with hanging rock teeth instead of a uniform drum.
for scale,top,bottom in [(.90,-27,-44),(.68,-43,-60),(.42,-59,-78),(.20,-77,-93)]:
    for x in range(-168,169,8):
        for z in range(-168,169,8):
            if not outline(x/scale,z/scale):continue
            if top>-40 and abs(x)<84 and abs(z)<24:continue
            shade=g.R.randint(-10,8);depth=top-bottom+g.R.randrange(0,9)
            g.specpart('TaperedIslandStone','underside',x,z,top-depth/2,8,8,depth,tuple(v+shade for v in g.ROCK),material='Slate')
# Winding paving with width bulges; stone steps on sloping runs are decorative.
for name,r in g.ROUTES.items():
    travel=0
    for i,(a,b) in enumerate(zip(r['points'],r['points'][1:])):
        dx=b[0]-a[0];dz=b[1]-a[1];run=math.hypot(dx,dz)
        if run<.01:continue
        travel+=run
        count=max(1,round(run/3))
        for j in range(count):
            t=(j+.5)/count;x=a[0]+dx*t;z=a[1]+dz*t;y=a[2]+(b[2]-a[2])*t
            bend=.7*math.sin((x+z)/14)
            x-=dz/run*bend;z+=dx/run*bend
            span=12.8+1.8*math.sin(travel/17)+2*math.exp(-((x/20)**2+((z-42)/20)**2))
            if name.startswith('recovery'):span=4.2+1.2*math.sin(z/8)
            if name=='bridge' and abs(z)<19:
                g.specpart('BridgeTimberPlank','paving',x,z,y+.25,17.5,2.9,.18,(145,91,44),material='Wood');continue
            for side in range(-2,3):
                off=side*span/5;xx=x-dz/run*off;zz=z+dx/run*off
                length=math.hypot(run,b[2]-a[2]);ux=dx/run;uz=-dz/run;c=run/length;sn=(b[2]-a[2])/length
                rot=[uz,-ux*sn,ux*c,0,c,sn,-ux,-uz*sn,uz*c]
                lift=.39+len(g.PARTS)*.000005
                g.part('WindingCobble','paving',(xx,y+lift,-zz),(span/5+.1,.18,max(3.1,length/count+.15)),g.R.choice([(215,193,147),(226,205,162),(202,179,130)]),'Cobblestone',False,rot)
            for sign in [-1,1]:
                if name.startswith('recovery'):continue
                off=(span/2+1)*sign
                g.specpart('StonePathEdge','edging',x-dz/run*off,z+dx/run*off,y+.44+len(g.PARTS)*.00001,1.6,2.4,.7,(167,154,125))
        if travel>24:
            travel=0;x,z,y=b;off=12
            lx=x-dz/run*off;lz=z+dx/run*off
            if clear(lx,lz,1):g.lantern(lx,lz,max(y,ground(lx,lz)))
for x in range(-158,159,11):
    for z in range(-158,159,11):
        if not clear(x,z,9):continue
        y=ground(x,z)
        if g.R.random()<(.16 if z>60 else .30) and abs(z)>33 and not(abs(x)<85 and abs(z)<70) and not(abs(x)<27 and z>55):g.tree(x,z,y,g.R.uniform(.65,1.1))
        elif g.R.random()<.60:
            for dx,dz,w,h in [(-2,1,8,12),(4,0,6,8),(1,-4,5,5)]:
                if abs(x)<85 and abs(z)<70:h*=.45
                if not clear(x+dx,z+dz,w/2+1):continue
                g.specpart('LargeGreyBoulder','boulder',x+dx,z+dz,y+h/2,w,w,h,tuple(v+g.R.randint(-12,12) for v in g.ROCK),material='Slate',collide=True)
                g.specpart('BoulderMossLip','grass',x+dx,z+dz,y+h+.1,w,w,.5,g.GREEN)
        else:
            g.specpart('ChunkyBush','bush',x,z,y+2,6,6,4,(53,143,30))
# Focal summit faces receive a few large irregular rock shoulders.
for x,z in [(-19,80),(16,79),(-40,90),(43,87),(-55,108),(57,110)]:
    if not clear(x,z,5):continue
    y=ground(x,z)
    for dx,dz,w,h in [(0,0,9,7),(-5,2,6,4),(4,-2,5,5)]:
        if not clear(x+dx,z+dz,w/2):continue
        g.specpart('SummitRockShoulder','boulder',x+dx,z+dz,y+h/2,w,w,h,g.ROCK,material='Slate',collide=True)
        g.specpart('SummitRockMoss','grass',x+dx,z+dz,y+h,w,w,.5,(134,195,48))
for x in range(-166,167,6):
    for z in range(-166,167,6):
        if not clear(x,z,2):continue
        y=ground(x,z)
        for k in range(2):
            h=g.R.uniform(.5,1.3);g.specpart('MossTuft','grass',x+g.R.uniform(-2,2),z+g.R.uniform(-2,2),y+h/2,1.4,1.4,h,(g.R.randint(103,139),g.R.randint(177,207),35))
for x in [-14,14]:
    g.specpart('CampBannerPole','banner',x,126,57,1,1,18,g.WOOD,material='Wood')
    g.specpart('CampLeafBanner','banner',x+2,126,60,6,.5,9,(25,111,48))
    g.specpart('BannerEmblem','banner',x+2,125.65,60,2,.3,3,(192,232,94))
    g.lantern(x,125,48)
# Fences only border actual cliffs or ravine; no decorative barriers across lanes.
for x in [-10.5,10.5]:g.fence((x,-24),(x,24),4)
for z in [-23,23]:
    for a,b in [(-76,-73),(-49,-13),(13,74)]:
        if not near((a+b)/2,z,1):g.fence((a,z),(b,z),ground((a+b)/2,z))
# Outer cliff fence omitted where sampled endpoints cannot guarantee continuous support.
for z0 in [-6,6]:
    for i in range(32):
        a=i/32*math.tau;g.specpart('BridgeThrowTell','tell',4*math.cos(a),z0+4*math.sin(a),4.5,.7,.7,.12,(255,45,25),material='Neon')
for x in [-20,20]:
    for z in [-148,-126]:g.lantern(x,z,0)
# Distant floating landmarks, built from the same owned voxel vocabulary.
for kind,x,z,y,s in [('windmill',-280,400,-20,50),('castle',280,425,-40,62),('waterfall',190,560,-35,48),('trees',-145,520,-35,36)]:
    for k in range(5):g.specpart('RemoteIslandStone','background',x,z,y-5-k*9,s*(1-k*.17),s*(1-k*.17),10,g.ROCK,material='Slate')
    g.specpart('RemoteIslandMoss','background',x,z,y,s,s,2,g.GREEN)
    if kind=='windmill':
        g.specpart('WindmillTower','background',x,z,y+14,10,10,28,(208,191,160))
        g.specpart('WindmillRoof','background',x,z,y+30,14,14,5,(132,78,52))
        for a in [math.pi/4,math.pi*3/4]:
            c=math.cos(a);sn=math.sin(a);rot=[c,-sn,0,sn,c,0,0,0,1]
            g.part('WindmillSail','background',(x,y+24,-z+7),(3,34,1),(224,204,165),'Wood',False,rot)
    elif kind=='castle':
        g.specpart('CastleKeep','background',x,z,y+12,25,20,24,(153,158,172),material='Slate')
        for dx,dz in [(-17,-14),(17,-14),(-17,14),(17,14)]:
            g.specpart('CastleTower','background',x+dx,z+dz,y+16,10,10,32,(170,173,184),material='Slate')
            for ox in [-3,3]:g.specpart('CastleBattlement','background',x+dx+ox,z+dz,y+34,3,10,4,(150,155,170))
    if kind in {'castle','waterfall'}:
        g.specpart('FarWaterfall','background',x+s*.22,z-s*.5,y-36,5,1.4,74,(124,225,246),material='Neon')
        for k in range(8):g.specpart('WaterfallFoam','background',x+s*.22+g.R.uniform(-4,4),z-s*.5,y-72+k,3,3,2,(229,251,251))
    for dx,dz in [(-s*.3,0),(s*.3,s*.25)]:g.tree(x+dx,z+dz,y,.55)
# A calmer stone arch and continuous cyan rim replaces the gear-like seed.
g.PARTS[:]=[p for p in g.PARTS if p['category'] not in {'portal_arch','portal_glow'}]
for i in range(64):
    a=i/64*math.tau;c=math.cos(a);sn=math.sin(a);rot=[c,-sn,0,sn,c,0,0,0,1]
    g.part('PortalStone','portal_arch',(11.5*c,11+11.5*sn,136),(4.8,1.3,4.8),tuple(v+g.R.randint(-9,9) for v in g.ROCK),'Slate',False,rot)
g.part('CyanPortalField','portal_glow',(0,11,138.8),(.25,18,18),(12,163,218),'Neon',False,[0,0,1,0,1,0,-1,0,0],shape='Cylinder')
for i in range(64):
    a=i/64*math.tau;c=math.cos(a);sn=math.sin(a);rot=[c,-sn,0,sn,c,0,0,0,1]
    g.part('ContinuousCyanRim','portal_glow',(9.2*c,11+9.2*sn,139),(.7,1.05,.25),g.CYAN,'Neon',False,rot)
for i in range(110):
    t=i/109;a=t*math.tau*2;r=7.5*(1-t)
    g.part('PortalSpiral','portal_glow',(r*math.cos(a),11+r*math.sin(a),139.3),(.65,.65,.2),(118,255,243),'Neon')
# Route landmarks deliberately distinct at portal and summit.
for x,z in [(-104,-58),(-114,-21),(-108,17),(-77,-101),(-40,-135)]:
    if clear(x,z,6):g.tree(x,z,ground(x,z),1.45)
# Overhanging canopy above west travel; trunks outside audited lane.
for x,z in [(-99,-15),(-83,-67)]:
    g.specpart('WestCanopyOverhang','west_landmark',x,z,27,35,27,5,(69,139,46))
g.specpart('WestHollowOakSign','west_landmark',-107,-66,17,11,11,22,(133,94,64))
g.specpart('WestHollowOakMoss','west_landmark',-107,-66,29,16,16,3,(112,175,65))
for x,z,w,h in [(119,-103,10,43),(110,-112,8,34),(107,-115,6,20)]:
    if clear(x,z,w/2+1):
        y=ground(x,z);g.specpart('EastSplitSpire','east_landmark',x,z,y+h/2,w,w,h,(155,141,168))
        g.specpart('EastSpirePaleTop','east_landmark',x,z,y+h+4,w,w,8,(204,190,210),shape='Wedge')
# Two warm arch lamps outside the exposed bridge deck mark its silhouette.
for x in [-14,14]:
    g.specpart('BridgeBeaconStone','bridge_landmark',x,29,5,4,4,10,(177,153,160))
    g.lantern(x,29,10)
# Thin non-colliding stream is a visual cue; the floor remains walkable.
g.specpart('RavineThinStream','ravine_stream',0,0,-31.65,134,2,.12,(72,118,125),material='SmoothPlastic')
# Colour hierarchy: purple-grey faces, pale upper facets, moss selectively on rocks.
for p in g.PARTS:
    if p['category']=='terrain_cap' and p['position'][1]<-8:
        p['color']=[85,84,96];p['material']='Slate'
    if p['category']=='paving' and p['position'][1]<-8:
        p['color']=[110,103,119];p['material']='Slate'
    if p['category']=='terrain_grass' and abs(p['position'][0])<80 and abs(p['position'][2])<20:
        p['color']=[67,69,83];p['material']='Slate'
    if p['category'] in {'boulder','cliff','terrace','path_rock'}:
        shade=(sum(ord(c) for c in p['name'])+int(p['position'][0]*3+p['position'][2]*5))%19-9
        p['color']=[v+shade for v in g.ROCK]
# Broad boulder clusters outside lanes, with light caps rather than uniform moss blocks.
for x,z in [(-138,-80),(-128,70),(83,112),(68,-120),(144,47),(-116,-124)]:
    for dx,dz,w,h in [(0,0,14,13),(10,4,10,8),(-9,-4,9,6)]:
        xx,zz=x+dx,z+dz
        if clear(xx,zz,w/2+2):
            y=ground(xx,zz)
            g.specpart('Round3BoulderCluster','boulder',xx,zz,y+h/2,w,w,h,(145,130,151),material='Slate',collide=True)
            g.specpart('BoulderLightFacet','rock_cap',xx,zz,y+h,w,w,.6,(190,178,196),material='Slate')
            g.specpart('BoulderMossPatch','grass',xx-w*.22,zz+w*.2,y+h+.4,w*.42,w*.38,.45,(118,176,71))
for x in range(-153,154,9):
    for z in range(-153,154,9):
        if clear(x,z,3) and g.R.random()<.32:
            y=ground(x,z)
            g.specpart('WildflowerStem','flower',x,z,y+.8,.3,.3,1.5,(86,137,46))
            g.specpart('WarmWildflower','flower',x,z,y+1.7,2,2,.8,g.R.choice([(247,195,86),(213,145,182),(235,224,168)]))
# Lantern spacing along every named route including the long penalty walkout.
for name,r in g.ROUTES.items():
    total=0;next_at=0
    for a,b in zip(r['points'],r['points'][1:]):
        dx,dz=b[0]-a[0],b[1]-a[1];run=math.hypot(dx,dz)
        if run<.01:continue
        while next_at<=total+run:
            t=max(0,(next_at-total)/run);x,z,y=a[0]+dx*t,a[1]+dz*t,a[2]+(b[2]-a[2])*t
            for sign in [-1,1]:
                off=r['width']/2+3;xx=x-dz/run*off*sign;zz=z+dx/run*off*sign
                if not near(xx,zz,1) and outline(xx,zz):
                    g.lantern(xx,zz,y);break
            next_at+=22
        total+=run
# Critic correction: gorge walls and floor are subordinate to the exposed bridge.
g.PARTS[:]=[p for p in g.PARTS if not(p['category'] in {'paving','edging'} and p['position'][1]<-8)]
for p in g.PARTS:
    x,y,z=p['position']
    if p['category'] in {'cliff','terrace','path_rock'} and abs(x)<84 and abs(z)<25 and y<0:
        p['color']=[79+(int(x)%7),72+(int(z)%9),88+(int(x+z)%8)]
    if p['category']=='terrain_cap' and y<-8:p['color']=[62,59,68]
    if p['category'] in {'boulder','rock_cap'}:
        # Rotate selected owned scenery stones, breaking the same-size upright grid.
        a=((int(x*3+z*2)%19)-9)*.015;c=math.cos(a);sn=math.sin(a)
        if not p['collidable']:p['rotation']=[c,-sn,0,sn,c,0,0,0,1]
# Final blind-look corrections: protect the east route decision sightlines.
def east_sight_blocker(p):
    x,y,wz=p['position'];z=-wz
    return 35<x<175 and -145<z<45 and (p['category'] in {'tree','boulder','bush','rock_cap'} or p['name'] in {'BoulderMossLip','BoulderMossPatch','SummitRockMoss'})
# Remove complete oversized trees, bushes and box boulders from the east decision wedge.
g.PARTS[:]=[p for p in g.PARTS if not east_sight_blocker(p)]
# Real high jump pads now have a readable three-step silhouette from both decision points.
for i,z in enumerate([-24,-40,-56]):
    x=160;y=20+i*2
    g.specpart('RidgeJumpAmberStandard','jump_landmark',x,z,y+8,2.6,2.6,16,(148,103,53),material='Wood')
    g.specpart('RidgeJumpGoldenCrown','jump_landmark',x,z,y+17,5,5,2,(255,193,58),material='Neon')
    g.specpart('RidgeJumpPennant','jump_landmark',x+3,z,y+13,5,.5,6,(237,174,59),shape='Wedge')
# Irregular rock wall-toes and mouths preserve the audited open bottom lanes.
for x,z,w,h in [(-69,17,15,21),(-42,-17,14,18),(34,17,17,24),(64,-17,12,19),(-81,0,9,27),(81,1,10,23)]:
    if near(x,z,w/2 if abs(x)>75 else 1):continue
    a=(.17 if x<0 else -.21);c=math.cos(a);sn=math.sin(a)
    rot=[c,0,sn,0,1,0,-sn,0,c]
    g.part('RavineAngledButtress','ravine_rock',(x,-32+h/2,-z),(w,h,3.5 if abs(x)<75 else 15),(86,76,98),'Slate',False,rot,shape='Wedge')
    g.specpart('RavinePaleStoneFacet','ravine_rock',x,z,-32+h,w*.58,2.2,2.7,(124,110,135),shape='Wedge')
g.PARTS[:]=[p for p in g.PARTS if p['name']!='RavineThinStream']
for i in range(24):
    x=-74+i*6;xx=x+6;z=2.2*math.sin(x/19);zz=2.2*math.sin(xx/19)
    start=len(g.PARTS);g.segment('WindingRavineStream',(x,z,-31.6),(xx,zz,-31.6),1.6,'ravine_stream',False,.08)
    for part in g.PARTS[start:]:part['color']=[58,92,103];part['material']='SmoothPlastic';part['collidable']=False
# Large owned rock shoulders use sloping wedge facets rather than upright boxes.
for x,z in [(-132,-96),(-126,72),(-111,-123),(-64,123),(67,122),(145,73)]:
    for dx,dz,w,h in [(0,0,17,12),(-11,6,11,8),(9,-5,9,7)]:
        xx,zz=x+dx,z+dz
        if not clear(xx,zz,w*.75+2):continue
        y=ground(xx,zz);a=.22 if dx<=0 else -.28;c=math.cos(a);sn=math.sin(a)
        g.specpart('FacetedBoulderBody','boulder',xx,zz,y+h*.35,w*.82,w*.82,h*.7,(145,124,142),material='Slate',collide=True)
        g.part('BoulderSlopedCrown','rock_cap',(xx,y+h*.72,-zz),(w,h*.65,w),(200,177,193),'Slate',False,[c,0,sn,0,1,0,-sn,0,c],shape='Wedge')
        g.specpart('BoulderMossIsland','grass',xx-w*.22,zz+w*.16,y+h*.82,w*.33,w*.4,.65,(127,172,71))
# Coordinated flower patches register at the concept camera without covering paths.
for x,z in [(-111,-101),(-121,54),(-84,129),(79,113),(50,-131),(140,57)]:
    for dx,dz in [(-3,-2),(0,0),(3,2),(-2,3),(2,-3)]:
        xx,zz=x+dx,z+dz
        if not clear(xx,zz,3):continue
        y=ground(xx,zz)
        g.specpart('FlowerPatchLeaf','flower',xx,zz,y+.9,2,2,1.4,(89,141,48))
        g.specpart('FlowerPatchGold','flower',xx,zz,y+2,3.2,3.2,.75,(245,190,82))
        g.specpart('FlowerPatchCentre','flower',xx,zz,y+2.45,1.2,1.2,.3,(244,230,151))

# Route metadata feeds machine route audit and isolated fall logic.
g.emit()

