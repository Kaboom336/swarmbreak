"""Height-first rebuild. Existing authored native parts reused; no imported assets.
Source edits use apply_patch; generated manifests/models/proofs are build outputs.
Stages: height, shape, dressing. Coordinates are the MAP-V4 X,Z,Y convention.
"""
import math, sys, json, hashlib
import geometry as g
OUT=g.ROOT.parents[1]/'treasure/map-v4'
stage=sys.argv[1] if len(sys.argv)>1 else 'height'
g.ROCK=(113,109,132)
g.GREEN=(91,166,39)
g.WOOD=(143,90,45)
g.build()
kept={'lane','bridge','jump_access','court','jump','portal','protected'}
if stage=='dressing': kept|={'portal_arch','portal_glow','treasure','keeper'}
g.PARTS[:]=[p for p in g.PARTS if p['category'] in kept and not p['name'].startswith('shelf')]
# Relocate the shelf dogleg outside the spiral instead of retaining 37 collisions.
# Thirteen-stud runs remain distinct from nine-stud tangent pads at corners.
g.route('shelf',[(30,108,24),(55,108,24),(68,108,18),(90,108,18),
                 (90,99,18),(90,86,12),(90,77,12),(81,77,12),
                 (68,77,6),(59,77,6),(46,77,0),(37,77,0),
                 (37,54,0),(0,54,0)])
g.PARTS[:]=[p for p in g.PARTS if p['category']!='paving']
# Add supported massif under every lane, including precise tilted ramp supports.
lanes=[p for p in g.PARTS if p['category'] in kept and p['collidable']]
# Every flat intersecting lane gets a distinct tiny lift. Duplicate elevations
# caused the black triangles in the prior proof despite supported solid ground.
for i,p in enumerate(lanes):
    if p['category'] in ['lane','bridge','jump_access']:p['position'][1]+=(i+1)*.0015
lane_lifts={p['name']:(i+1)*.0015 for i,p in enumerate(lanes) if p['category'] in ['lane','bridge','jump_access']}
edges=[(a,b,r['width']/2) for r in g.ROUTES.values() for a,b in zip(r['points'],r['points'][1:])]
def near(x,z,margin=0):
    return [(a,b,w) for a,b,w in edges if g.dist_segment(x,z,a,b)<=w+margin]
def lane_height(x,z,a,b):
    dx=b[0]-a[0];dz=b[1]-a[1];n=dx*dx+dz*dz
    t=max(0,min(1,((x-a[0])*dx+(z-a[1])*dz)/n)) if n else 0
    return a[2]+(b[2]-a[2])*t
def outline(x,z):
    if stage=='height':return abs(x)<=176 and abs(z)<=176
    a=math.atan2(z,x)
    radius=169+6*math.sin(3*a+.5)+4*math.sin(7*a)+2*math.sin(11*a)+27*math.exp(-((a+.62)/.24)**2)
    return math.hypot(x,z)<=radius
def wanted(x,z):
    # Large stepped northern massif; the spiral is a cut through solid shelves.
    rr=math.hypot(x/1.2,(z-112))
    h=24 if rr<30 else 18 if rr<60 else 12 if rr<82 else 6 if rr<100 else 0
    if z<38:h=0
    # Raised east spine with walking bypass and separate optional jump lane.
    if ((x-105)/38)**4+((z+34)/70)**4<1:h=max(h,10)
    # Rock shoulders flank the west cut and both valley banks. The causeway
    # remains at zero; full lane envelopes are carved down separately below.
    if -148<x<-113 and -89<z<62:h=max(h,6)
    if -80<x<-61 and -49<z<24:h=max(h,6)
    bank_edge=21+3*math.sin(x/12)
    if abs(x)<90 and bank_edge<abs(z)<48+3*math.sin(x/17):h=max(h,6)
    # Broad rock banks on both sides of a clearly excavated valley.
    if abs(x)<84 and abs(z)<bank_edge:h=-4
    return h
tops={}
for x in range(-174,176,4):
    for z in range(-174,176,4):
        if not outline(x,z):continue
        h=wanted(x,z)
        neighbours=near(x,z,3.1)
        # Carve the whole box footprint below actual lanes. No grass slopes.
        if neighbours:
            lim=min(lane_height(x+dx,z+dz,a,b) for a,b,w in neighbours for dx,dz in [(-2,-2),(-2,2),(2,-2),(2,2)])-.95
            h=min(h,math.floor(lim/2)*2)
        # Reserve the camp's full central court and ridge turning court.
        for cx,cz,cy,sx,sz in [(0,108,24,32,32),(96,-24,10,24,24),(0,54,0,32,32),(0,-136,0,48,40)]:
            if abs(x-cx)<sx/2+2 and abs(z-cz)<sz/2+2:h=min(h,cy-1)
        tops[x,z]=h
        bottom=-43
        shade=g.R.randint(-9,9)
        g.specpart('TerraceBedrock','terrace',x,z,(bottom+h)/2,4,4,h-bottom,tuple(v+shade for v in g.ROCK),material='Slate',collide=True)
        g.specpart('MossyTerraceTop','terrain_grass',x,z,h-.30,4,4,.7,tuple(v+g.R.randint(-5,5) for v in g.GREEN),material='Grass')
        # Each exposed step is stone courses rather than a smooth grassy slope.
for (x,z),h in tops.items():
    for dx,dz in [(4,0),(-4,0),(0,4),(0,-4)]:
        low=tops.get((x+dx,z+dz),-43)
        if low>=h-1:continue
        for y in range(int(low)+2,int(h)+1,4):
            shade=g.R.randint(-16,16)
            g.specpart('VoxelCliffCourse','cliff',x+dx*.47,z+dz*.47,y-1.7,
                       3.85 if dz else .55,3.85 if dx else .55,3.85,
                       tuple(v+shade for v in g.ROCK),material='Slate')
        if not near(x+dx*.45,z+dz*.45,2):
            g.specpart('CliffMossLip','grass',x+dx*.43,z+dz*.43,h+.1,2.7 if dz else 1.2,2.7 if dx else 1.2,.8,(129,191,49))
# Exact vertical rock extrusion beneath each collider. Ramp wedges join their
# underside plane and continue into a full stone block down to bedrock.
for p in lanes:
    if p['category'] in ['jump','protected','portal']:continue
    if p['category']=='bridge' and abs(p['position'][2])<1:continue
    s=p['size'];r=p['rotation'];pos=p['position']
    mid=[pos[j]-r[j*3+1]*s[1]/2 for j in range(3)]
    run=s[2]*math.hypot(r[2],r[8]);rise=s[2]*abs(r[5])
    sign=1 if r[5]>=0 else -1
    zx=r[2]*s[2]/run*sign;zz=r[8]*s[2]/run*sign
    yaw=[zz,0,zx,0,1,0,-zx,0,zz]
    low=mid[1]-rise/2
    if rise>.001:
        g.part('FullRampRockWedge','path_rock',(mid[0],mid[1]+.01,mid[2]),(s[0],rise+.02,run),g.ROCK,'Slate',False,yaw,shape='Wedge')
    depth=low+24
    g.part('FullPathRockBody','path_rock',(mid[0],low-depth/2+.01,mid[2]),(s[0],depth+.02,run),g.ROCK,'Slate',False,yaw)
# Stone-sided collision slabs with thin caps. The old two-stud green side faces
# looked like black overhanging turf bands despite the flush solid extrusion.
for p in lanes:
    if p['category'] in ['jump','protected','portal']:continue
    s=p['size'];r=p['rotation'];pos=p['position']
    p['color']=list(g.ROCK);p['material']='Slate'
    capcolor=g.GREEN
    g.part('ThinTerrainCap','terrain_cap',tuple(pos[j]+r[j*3+1]*(s[1]/2+.05) for j in range(3)),(s[0],.12,s[2]),capcolor,'Grass' if capcolor==g.GREEN else 'Cobblestone',False,r)
if stage!='height':
    # Organic shrinking voxel strata; no rectangular underside slabs.
    for scale,top,bottom in [(.93,-24,-39),(.79,-39,-53),(.61,-53,-67),(.37,-67,-82)]:
        for x in range(-168,169,8):
            for z in range(-168,169,8):
                if not outline(x/scale,z/scale):continue
                shade=g.R.randint(-14,8)
                g.specpart('TaperedVoxelUnderside','underside',x,z,(top+bottom)/2,8,8,top-bottom,tuple(v+shade for v in g.ROCK),material='Slate')
if stage=='dressing':
    # Recreate paving using the same route slab transforms and elevations.
    for name,r in g.ROUTES.items():
        before=len(g.PARTS)
        for i,(a,b) in enumerate(zip(r['points'],r['points'][1:])):g.segment(name+str(i),a,b,r['width'],r['category'])
        g.PARTS[before:]=[p for p in g.PARTS[before:] if p['category']=='paving']
        for p in g.PARTS[before:]:p['position'][1]+=lane_lifts.get(p['name'].removesuffix('_Cobble'),0)+.06
    g.PARTS[:]=[p for p in g.PARTS if not(p['category']=='paving' and p['name'].startswith('bridge') and abs(p['position'][2])<16)]
    for p in g.PARTS:
        if p['category']=='paving':
            p['size'][0]=g.R.uniform(2.65,2.95);p['size'][2]*=g.R.uniform(1.0,1.10)
            r=p['rotation'];theta=g.R.uniform(-.12,.12);c=math.cos(theta);s=math.sin(theta)
            p['rotation']=[r[j*3]*c-r[j*3+2]*s if k==0 else r[j*3+1] if k==1 else r[j*3]*s+r[j*3+2]*c for j in range(3) for k in range(3)]
            lateral=g.R.uniform(-.12,.12);along=g.R.uniform(-.12,.12)
            for j in range(3):p['position'][j]+=r[j*3]*lateral+r[j*3+2]*along
            p['color']=list(g.R.choice([(218,197,150),(201,177,128),(228,208,166),(192,161,117)]))
    for i,p in enumerate(p for p in g.PARTS if p['category']=='paving'):
        p['position'][1]+=(i%180)*.0008
    # Keep grass shoulders on the full-width collider instead of broad cream
    # rectangular borders; the narrower irregular stones define the visible road.
    for p in g.PARTS:
        if p['category']=='edging':
            p['position'][0]+=g.R.uniform(-.3,.3);p['position'][2]+=g.R.uniform(-.3,.3)
    def clear(x,z,margin=9):
        return outline(x,z) and not near(x,z,margin) and not(abs(x)<28 and -164<z<-108) and not(abs(x)<24 and 85<z<133)
    def ground(x,z):
        return tops.get((round((x+174)/4)*4-174,round((z+174)/4)*4-174),0)
    for x in range(-158,159,12):
        for z in range(-158,159,12):
            if not clear(x,z,11):continue
            y=ground(x,z)
            if g.R.random()<.28:g.tree(x,z,y,g.R.uniform(.65,1.05))
            else:
                for dx,dz,h,w in [(0,0,3.6,5),(-3,1,2.5,3),(2,-2,2.8,4)]:
                    g.specpart('DenseVoxelBush','bush',x+dx,z+dz,y+h/2,w,w,h,(g.R.randint(36,62),g.R.randint(128,168),28))
            if g.R.random()<.25:
                h=g.R.uniform(4,8);g.specpart('BigGreyBoulder','boulder',x+3,z-3,y+h/2,6,6,h,g.ROCK,material='Slate',collide=True)
    for x in range(-166,167,6):
        for z in range(-166,167,6):
            if not clear(x,z,2):continue
            y=ground(x,z)
            for k in range(2):
                h=g.R.uniform(.5,1.2)
                g.specpart('DenseCliffTurf','grass',x+g.R.uniform(-2,2),z+g.R.uniform(-2,2),y+h/2,1.2,1.2,h,(g.R.randint(101,137),g.R.randint(172,200),35))
            if g.R.random()<.12:g.specpart('MeadowFlower','flower',x,z,y+1.3,.6,.6,.5,(255,237,139))
    # Frequent warm lamps and stone edging follow all lanes, outside their sweep.
    for name,r in g.ROUTES.items():
        if name in ['summit_radial','shelf','spiral','west','east','bridge','portal_north']:
            distance=0
            for a,b in zip(r['points'],r['points'][1:]):
                dx=b[0]-a[0];dz=b[1]-a[1];run=math.hypot(dx,dz)
                for i in range(max(1,int(run/4))):
                    t=(i+.5)/max(1,int(run/4));x=a[0]+dx*t;z=a[1]+dz*t;y=a[2]+(b[2]-a[2])*t
                    for sign in [-1,1]:
                        off=7.7*sign
                        g.specpart('CobbleLaneEdging','edging',x-dz/run*off,z+dx/run*off,y+.25,1.4,1.4,.6,(184,159,115))
                    distance+=run/max(1,int(run/4))
                    if distance>24:
                        off=11.5;lx=x-dz/run*off;lz=z+dx/run*off
                        if not near(lx,lz,1):
                            base=y if name=='bridge' and abs(lz)<16 else ground(lx,lz)
                            g.lantern(lx,lz,base)
                        distance=0
    # Fences on long readable cliff rims, preserving all full-width travel lanes.
    for a,b,y in [((-128,-102),(-100,-130),0),((85,-133),(118,-108),0),
                    ((-128,55),(-136,15),0),((136,8),(136,-58),10),
                    ((-66,137),(-36,151),6),((39,151),(64,135),12),
                    ((-13,125),(13,125),24)]:
        steps=max(1,math.ceil(math.hypot(b[0]-a[0],b[1]-a[1])/8))
        for i in range(steps):
            aa=tuple(a[j]+(b[j]-a[j])*i/steps for j in range(2));bb=tuple(a[j]+(b[j]-a[j])*(i+1)/steps for j in range(2))
            g.fence(aa,bb,ground((aa[0]+bb[0])/2,(aa[1]+bb[1])/2))
    for x in [-10.5,10.5]:g.fence((x,-15),(x,15),6)
    for x in [-10,10]:
        g.specpart('CampBannerPole','banner',x,123,33,.9,.9,18,g.WOOD,material='Wood')
        g.specpart('CampLeafBanner','banner',x+2,123,37,6,.4,9,(26,113,43))
        g.specpart('CampLeafEmblem','banner',x+2,122.7,37,2,.3,3,(170,228,78))
        g.lantern(x,122,24)
    # Causeway rock cover has open sides; overhead reservation exceeds 20 studs.
    for x,z,roofx in [(-114,5,-99),(-70,-10,-82),(-120,-40,-105)]:
        g.specpart('CausewayOverhangPillar','cover',x,z,11.5,8,10,23,g.ROCK,material='Slate',collide=True)
        g.specpart('CausewayRockOverhang','cover',roofx,z,23,30,10,4,g.ROCK,material='Slate',collide=True)
        g.PARTS[-1]['transparency']=1
        for dx in [-11,-5,1,7,12]:
            for dz in [-2.5,2.5]:
                h=g.R.uniform(3.5,5.5)
                g.specpart('ClusteredOverhangRock','cover',roofx+dx,z+dz,21+h/2,6.4,5.7,h,tuple(v+g.R.randint(-9,9) for v in g.ROCK),material='Slate',collide=True)
        for y in range(2,24,4):
            for dx in [-2.5,2.5]:
                g.specpart('OverhangPillarStone','cliff',x+dx,z-4.9,y,4,1.3,3.8,tuple(v+g.R.randint(-10,10) for v in g.ROCK),material='Slate')
    for z in range(-15,16,2):g.specpart('BridgeTimberPlank','paving',0,z,6.3,17.4,1.8,.18,(143,91,44),material='Wood')
    for p in lanes:
        if p['category']=='bridge' and abs(p['position'][2])<1:p['color']=[143,91,44];p['material']='Wood'
    for x in [-11.5,11.5]:
        for z in [-16,16]:g.specpart('BridgeRockAbutment','bridge_support',x,z,1,4,4,10,g.ROCK,material='Slate',collide=True)
    for z0 in [-7,7]:
        for i in range(36):
            a=i/36*math.tau;g.specpart('RedBridgeThrowRing','tell',4*math.cos(a),z0+4*math.sin(a),6.42,.7,.7,.12,(255,39,25),material='Neon')
    g.specpart('AcornPedestal','treasure',0,108,25,5,5,2,g.ROCK,material='Slate')
    for p in g.PARTS:
        if p['name'] in ['GoldenAcorn','AcornCap','AcornStem']:p['position'][1]+=1.25
    for x in [-18,18]:g.lantern(x,-146,0);g.lantern(x,-126,0)
    # Thicker irregular stone surround, continuous inner cyan rim, one spiral.
    g.PARTS[:]=[p for p in g.PARTS if p['name'] not in ['PortalStone','CyanArchRune','PortalSpiral']]
    for i in range(18):
        a=i/18*math.tau;c=math.cos(a);s=math.sin(a);rot=[c,-s,0,s,c,0,0,0,1]
        g.part('PortalStone','portal_arch',(11.5*c,11+11.5*s,136),(4.8,4.1,5),tuple(v+g.R.randint(-10,10) for v in g.ROCK),'Slate',False,rot)
        g.part('CyanPortalRim','portal_glow',(9.2*c,11+9.2*s,139),(.65,3.3,.25),g.CYAN,'Neon',False,rot)
    for i in range(100):
        t=i/99;a=t*math.tau*2;r=7.5*(1-t)
        g.part('CalmPortalSpiral','portal_glow',(r*math.cos(a),11+r*math.sin(a),139.3),(.65,.65,.2),(126,255,246),'Neon')
    for x,z,y,s in [(-245,170,30,40),(245,160,40,43),(-220,-80,4,24),(230,-65,12,25)]:
        g.specpart('RemoteIslandGrass','background',x,z,y,s,s,2,g.GREEN)
        for k in range(4):g.specpart('RemoteIslandRock','background',x,z,y-6-k*8,s*(1-k*.21),s*(1-k*.21),10,g.ROCK)
        g.tree(x,z,y,.65)
g.emit()
(OUT/f'redo-{stage}-structure.json').write_text(json.dumps({'stage':stage,'terrain_cells':len(tops),'heights':sorted(set(tops.values())),'shelf_relocated':'X up to 90, Z55..117: authorised collision repair; original footprint contradicted spiral clearance','manifest_sha256':hashlib.sha256((g.ROOT/'scene.json').read_bytes()).hexdigest()},indent=2))
