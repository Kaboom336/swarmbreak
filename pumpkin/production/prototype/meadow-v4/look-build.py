"""Deterministic native look pass over the merged manifest; run in Blender Python.
Keeps every existing collision OBB, route, gameplay source and test unchanged.
"""
import copy, json, math, random, hashlib, sys, importlib.util
from pathlib import Path
from mathutils import Vector
H = Path(__file__).resolve().parent
sys.path.insert(0,str(H))
import geometry as g
O = H.parents[1] / 'treasure/map-v4'
baseline = json.loads((H / 'look-baseline-scene.json').read_bytes())
spec=importlib.util.spec_from_file_location('placement',H/'placement-audit.py')
placement=importlib.util.module_from_spec(spec);spec.loader.exec_module(placement)
terrain=placement.Terrain(baseline['parts'])
g.PARTS[:] = copy.deepcopy(baseline['parts'])
g.ROUTES.clear(); g.ROUTES.update(copy.deepcopy(baseline['routes']))
r = random.Random(131027)
I = [1,0,0,0,1,0,0,0,1]
def height(x,z):
    center=-76+max(0,-z-55)*.25+3*math.sin((z+35)*.03)
    radius=61+4*math.sin(z*.045)
    cross=max(0,1-((x-center)/radius)**2)
    end=1 if -99<=z<=23 else max(0,1-((z-23)/32 if z>23 else (-99-z)/30)**2)
    return 52*cross*end*(1-.17*((z+35)/75)**2)
def ground(x,z): return Vector((x,height(x,z)+.08,-z))
def triangle(a,b,c,name='LookContinuousTurf',color=(88,154,40),material='Grass'):
    # Split at the altitude to the longest side into exact native right prisms.
    sides=[(a,b,c),(b,c,a),(c,a,b)]
    a,b,c=max(sides,key=lambda t:(t[1]-t[0]).length_squared)
    axis=(b-a).normalized();foot=a+axis*(c-a).dot(axis)
    for endpoint in (a,b):
        base=(foot-endpoint).length;altitude=(c-foot).length
        if min(base,altitude)<.001:continue
        ez=(foot-endpoint).normalized();ey=(c-foot).normalized();ex=ey.cross(ez).normalized()
        center=(endpoint+c)/2
        # Both thickness faces share the same triangle; bury half thickness.
        center-=Vector((0,.02,0))
        rot=[ex.x,ey.x,ez.x,ex.y,ey.y,ez.y,ex.z,ey.z,ez.z]
        g.part(name,'tunnel_detail',center,[.2,altitude,base],color,material=material,shape='Wedge',rotation=rot)
# Existing turf OBBs remain invisible collision supports. Shared height vertices
# replace their panel skin with a watertight triangulated surface, without ribs.
tiles=[p for p in g.PARTS if p['name']=='TunnelHillTurf']
centers=set()
for p in tiles:
    rot=p['rotation'];top=[p['position'][i]+rot[i*3+1]*.7 for i in range(3)]
    x,z=round(top[0],4),round(-top[2],4)
    p['transparency']=1
    # The previous skin extended beyond the island's actual footprint. Clip
    # unsupported low tiles rather than leaving grass fins over empty sky.
    if height(x,z)<12 and terrain.top(x,-z) is None:continue
    centers.add((x,z))
    for dx in (-3,):
        for dz in (-3,):
            a,b,c,d=[ground(xx,zz) for xx,zz in [(x+dx,z+dz),(x+dx+6,z+dz),(x+dx+6,z+dz+6),(x+dx,z+dz+6)]]
            triangle(a,b,c);triangle(a,c,d)
# Thick perimeter banks join the skin to the landform; route headroom stays open.
for x,z in sorted(centers):
    for dx,dz,ends in [(-6,0,[(x-3,z-3),(x-3,z+3)]),(6,0,[(x+3,z+3),(x+3,z-3)]),(0,-6,[(x+3,z-3),(x-3,z-3)]),(0,6,[(x-3,z+3),(x+3,z+3)])]:
        if (round(x+dx,4),round(z+dz,4)) in centers:continue
        if any(all(abs(xx+76)<8 and abs(zz-hz)<8 for xx,zz in ends) for hz in (-18,-46)):continue
        a,b=[ground(xx,zz) for xx,zz in ends]
        mx,mz=sum(v[0] for v in ends)/2,sum(v[1] for v in ends)/2
        if any(math.hypot(mx-hx,mz-hz)<32 for hx,hz in [(-76,27),(-76,-78),(-61.867,-98.953)]):continue
        bottom=-1.2
        for route in baseline['routes'].values():
            for start,end in zip(route['points'],route['points'][1:]):
                if g.dist_segment(mx,mz,start,end)<route['width']/2+.25:
                    vx,vz=end[0]-start[0],end[1]-start[1]
                    t=max(0,min(1,((mx-start[0])*vx+(mz-start[1])*vz)/max(.001,vx*vx+vz*vz)))
                    bottom=max(bottom,start[2]+(end[2]-start[2])*t+20.1)
        if min(a.y,b.y)<bottom+.3:continue
        aa,bb=Vector((a.x,bottom,a.z)),Vector((b.x,bottom,b.z))
        triangle(a,aa,bb,'LookHillEarthBank',(83,105,58),'Rock')
        triangle(a,bb,b,'LookHillEarthBank',(83,105,58),'Rock')
        bank_a,bank_b=Vector((a.x,max(bottom,a.y-1.6),a.z)),Vector((b.x,max(bottom,b.y-1.6),b.z))
        triangle(a,bank_a,bank_b,'LookHillGrassBank')
        triangle(a,bank_b,b,'LookHillGrassBank')
        # Inset rounded rock/grass rolls hide the staircase tips of outer cells.
        # Their lower faces stay above the same preserved headroom envelope.
        top=(a.y+b.y)/2
        h=min(7,top-bottom)
        if h>2:
            rx,rz=mx-dx*.45,mz-dz*.45
            g.specpart('LookHillBankRock','tunnel_detail',rx,rz,top-h*.55,7.5,7.5,h,(101,110,89),material='Rock',shape='Ball')
            g.specpart('LookHillBankGrass','tunnel_detail',rx,rz,top-1.1,7.2,7.2,3.0,(88,154,40),material='Grass',shape='Ball')
tones=[(108,104,128),(124,119,109),(88,103,91),(97,107,119),(143,135,121)]
materials=['Slate','Rock','Basalt']
rocks=[]
for index,p in enumerate(list(g.PARTS)):
    if p['material'] not in {'Slate','Rock','Basalt'} or p['category'] in {'lane','tunnel_floor','paving'} or p['name']=='TunnelHillEarth':continue
    x,y,z=p['position'];key=int(math.floor(x/18)*17+math.floor(z/18)*31+math.floor(y/12)*7)
    p['color']=list(tones[key%5]);p['material']=materials[key%3];rocks.append(p)
    if p['shape']!='Block' or p['size'][1]<2 or p['size'][0]<2 or index%4:continue
    rot=p['rotation'];normal=[rot[i*3+1] for i in range(3)]
    if normal[1]<.7:continue
    top=[p['position'][i]+normal[i]*(p['size'][1]/2+.018) for i in range(3)]
    cap=g.part('LookLightRockTop','rock_detail',top,[p['size'][0]*.94,.03,p['size'][2]*.94],tuple(min(255,v+20) for v in p['color']),material=p['material'],rotation=rot)
    if key%4==0:
        moss=[top[i]+normal[i]*.08 for i in range(3)]
        g.part('LookRockMoss','rock_detail',moss,[p['size'][0]*.45,.16,p['size'][2]*.55],(76,119,54),material='Grass',shape='Ball',rotation=rot)
    # Nested smaller fragments on the upper outside shoulder; no collision edit.
    if key%7==0 and p['size'][0]>6:
        q=[top[0]+p['size'][0]*.25,top[1]+.45,top[2]]
        g.part('LookRockFragment','rock_detail',q,[p['size'][0]*.22,1.0,p['size'][2]*.3],p['color'],material=p['material'],shape='Ball')
# Hill scenery uses the analytic shared turf heights, with real root contact.
for x,z,s in [(-120,-12,.75),(-101,-69,.8),(-55,8,.7)]:
    y=height(x,z)
    g.specpart('LookHillTreeTrunk','tunnel_detail',x,z,y+5*s,1.8*s,1.8*s,10*s,(112,78,43),material='Wood')
    for dx,dz,dy,w in [(0,0,11,10),(-3,0,12,7),(3,1,12,7),(0,-1,16,7)]:
        g.specpart('LookHillTreeCrown','tunnel_detail',x+dx*s,z+dz*s,y+dy*s,w*s,w*s,6*s,(64,132,43),material='Grass',shape='Ball')
for x,z in [(-117,-34),(-105,-81),(-55,-55),(-49,-10),(-121,9),(-87,-9)]:
    y=height(x,z)
    for dx,dz in [(-1.6,0),(1.6,.5),(0,-1.4)]:
        g.specpart('LookHillBush','tunnel_detail',x+dx,z+dz,height(x+dx,z+dz)+1.1,4,3.5,2.8,(61,123,39),material='Grass',shape='Ball')
    g.specpart('LookHillBoulder','tunnel_detail',x+4,z-2,height(x+4,z-2)+1.1,4.8,3.7,3.2,tones[r.randrange(5)],material=materials[r.randrange(3)],shape='Ball')
for hx,hz in [(-76,-18),(-76,-46)]:
    # Apertures remain clear: attached outcrops outside the 12x8 shafts.
    for dx,dz,s in [(-8,-2,1.2),(8,2,.9),(-3,-6,.8),(4,6,1)]:
        x,z=hx+dx,hz+dz
        g.specpart('LookSkylightOutcrop','tunnel_detail',x,z,height(x,z)+1.5*s,4.5*s,3.5*s,4*s,tones[r.randrange(5)],material=materials[r.randrange(3)],shape='Ball')
for j in range(90):
    x,z=r.uniform(-121,-36),r.uniform(-94,20);y=height(x,z)
    if y<26 or any(abs(x+76)<9 and abs(z-hz)<7 for hz in (-18,-46)):continue
    g.specpart('LookHillFlowerStem','tunnel_detail',x,z,y+.55,.14,.14,1.1,(68,126,40),material='Grass')
    color=r.choice([(255,221,91),(247,166,197),(192,172,245),(255,246,219)])
    for dx,dz in [(-.3,0),(.3,0),(0,-.3),(0,.3)]:
        g.specpart('LookHillFlowerPetal','tunnel_detail',x+dx,z+dz,y+1.1,.6,.6,.25,color,shape='Ball')
# Keep every new cosmetic out of the retained skylight shafts, including caps
# attached to old rim rocks. Collision geometry remains unchanged.
def shaft_overlap(p):
    if not p['name'].startswith('Look') or p['name']=='LookContinuousTurf':return False
    x,y,z=p['position'];sx,sy,sz=p['size']
    return y>=29 and any(abs(x+76)<sx/2+5.9 and abs(-z-hz)<sz/2+3.8 for hz in (-18,-46))
g.PARTS[:]=[p for p in g.PARTS if not shaft_overlap(p)]
# Serialization reused from the inspected native emitter; supports new materials.
g.emit()
scene=json.loads((H/'scene.json').read_bytes())
for k,v in baseline.items():
    if k not in {'parts','routes'}:scene[k]=v
(H/'scene.json').write_text(json.dumps(scene,separators=(',',':')),encoding='utf8')
collision=lambda s:[{k:p[k] for k in ('name','category','position','size','rotation','shape','collidable')} for p in s['parts'] if p['collidable']]
assert collision(scene)==collision(baseline)
assert scene['routes']==baseline['routes']
report={'state':'PASS','collision_geometry_byte_data_equal':True,'routes_equal':True,'baseline_parts':len(baseline['parts']),'parts':len(g.PARTS),'visible_turf_triangular_prisms':sum(p['name']=='LookContinuousTurf' for p in g.PARTS),'rock_tones':tones,'rock_materials':materials,'scene_sha256':hashlib.sha256((H/'scene.json').read_bytes()).hexdigest(),'runtime':'UNKNOWN'}
(O/'LOOK-GEOMETRY.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
