"""Deterministic tunnel slice; reuse inspected native emitter, retain current R5.
Authored source edits via apply_patch; scene/model/data are generated artifacts.
"""
import json, math, hashlib, shutil, importlib.util, copy
from pathlib import Path
import geometry as g
H=Path(__file__).parent; O=H.parents[1]/'treasure/map-v4'
baseline=H/'tunnel-baseline-scene.json'
if not baseline.exists():
 shutil.copyfile(H/'scene.json',baseline)
 shutil.copyfile(H.parent/'meadow-v4.rbxl',H/'tunnel-baseline.rbxl')
S=json.loads(baseline.read_text());g.PARTS[:]=S['parts'];g.ROUTES.clear();g.ROUTES.update(S['routes'])
entrance=[-76,27,0];near=[-76,-78,0];south=[-61.8671875,-98.953125,0]
trunk=[entrance,[-76,-54,0],near]
branch=[[-76,-54,0],[-60,-82,0],south]
west=S['routes']['west']['points'];ni=west.index(near);si=west.index(south)
old_cross=S['routes']['south_crosslink']['points'];retained=old_cross[12:]
# Reuse physical west paving, then leave from the actual south mouth. No extra
# mid-branch crossing or coplanar duplicate near-to-south slab is introduced.
g.ROUTES['south_crosslink']={'points':west[ni:si+1]+[[-22,-100,0]]+retained,'width':18,'category':'lane'}
old_edges=list(zip(old_cross[:12],old_cross[1:12]))
other_edges=[(a,b,r['width']/2) for name,r in g.ROUTES.items() for a,b in zip(r['points'],r['points'][1:])]
def orphaned_old_finish(p):
 if p['name'] not in {'WindingCobble','StonePathEdge'}:return False
 x,z=p['position'][0],-p['position'][2]
 return min(g.dist_segment(x,z,a,b) for a,b in old_edges)<12 and all(g.dist_segment(x,z,a,b)>half+3 for a,b,half in other_edges)
g.PARTS[:]=[p for p in g.PARTS if p['name'] not in {f'south_crosslink{i}' for i in range(11)} and not orphaned_old_finish(p)]
g.segment('TunnelValleyJoin',south,[-22,-100,0],18,'lane',True)
g.segment('TunnelValleyRetainedJoin',[-22,-100,0],retained[0],18,'lane',True)
start=len(g.PARTS)
g.route('tunnel_trunk',trunk,14,'tunnel_floor');g.route('tunnel_south',branch,14,'tunnel_floor')
for p in g.PARTS[start:]:
 prefix='tunnel_south' if p['name'].startswith('tunnel_south') else 'tunnel_trunk'
 index=int(p['name'][len(prefix):].split('_')[0])
 p['position'][1]+=(.17 if prefix=='tunnel_south' else .14)+index*.003
# Buried rock supports the new route through the west ravine shoulder.
g.specpart('TunnelFoundation','tunnel_rock',-76,-7,-19.075,29,78,37.85,(81,85,104),material='Slate',collide=True)
# Foundation top is exactly floor0 and does not obstruct lower ravine loop (x>=-31).
all_edges=[(a,b,r['width']/2) for r in g.ROUTES.values() for a,b in zip(r['points'],r['points'][1:])]
new_edges=[(a,b) for pts in [trunk,branch] for a,b in zip(pts,pts[1:])]
def cave_dist(x,z):return min(g.dist_segment(x,z,a,b) for a,b in new_edges)
def safe_box(x,z,w,d):
 return all(all(g.dist_segment(xx,zz,a,b)>half+.06 for a,b,half in all_edges) for xx in [x-w/2,x,x+w/2] for zz in [z-d/2,z,z+d/2])
# Whole-assembly relocation of the existing tree newly covered by this route.
# Reuse R5 grounding/OBB checks, rather than deleting it or moving only its trunk.
spec=importlib.util.spec_from_file_location('tunnel_pa',H/'placement-audit.py');pa=importlib.util.module_from_spec(spec);spec.loader.exec_module(pa)
tree=[p for p in g.PARTS if p.get('assembly')=='R5-tree-88']
root=next(p for p in tree if p.get('root'));oldbottom=pa.bounds(root)[1]
other=[p for p in g.PARTS if p not in tree];terrain=pa.Terrain(other);construction=pa.Construction(other)
props=[p for p in other if p.get('assembly')]
relocation=None
for x,z in sorted([(x,z) for x in range(-145,-34,5) for z in range(40,116,5)],key=lambda q:math.hypot(q[0]-root['position'][0],q[1]-root['position'][2])):
 y=terrain.top(x,z)
 if y is None:continue
 candidate=copy.deepcopy(tree);dx=x-root['position'][0];dz=z-root['position'][2];dy=y-oldbottom
 for p in candidate:p['position']=[p['position'][0]+dx,p['position'][1]+dy,p['position'][2]+dz]
 if any(not safe_box(p['position'][0],-p['position'][2],pa.bounds(p)[3]-pa.bounds(p)[0],pa.bounds(p)[5]-pa.bounds(p)[2]) for p in candidate):continue
 cr=next(p for p in candidate if p.get('root'));b=pa.bounds(cr)
 if any((h:=terrain.top(xx,zz)) is None or abs(h-b[1])>.2 for xx in [b[0],b[3]] for zz in [b[2],b[5]]):continue
 if any(construction.clips(p) or any(pa.boxes_overlap(p,q) for q in props) for p in candidate):continue
 g.PARTS[:]=other+candidate;relocation={'assembly':'R5-tree-88','from':root['position'],'to':[x,y+(root['position'][1]-oldbottom),z],'whole_assembly':True,'ground_tolerance':.2,'obb_prop_and_route_clear':True};break
assert relocation,'No grounded route-clear relocation for tunnel tree'
count=0
# Interlocking rock courses: no floor-to-ceiling posts. Each mass has its own
# shoulder depth, height and seam offset, within the unchanged reserved lanes.
for zi,z in enumerate(range(-102,26,6)):
 for xi,x in enumerate(range(-98,-39,5)):
  if 7.3<cave_dist(x,z)<18 and safe_box(x,z,5.3,6.3):
   bottom=-.2
   for layer in range(4):
    seed=xi*17+zi*11+layer*7;h=6+(seed%4)
    w=4.5+(seed%3)*.4;d=5.6+(seed%3)*.35
    xx=x+((seed%3)-1)*.23;zz=z+(((seed//3)%3)-1)*.25
    if not safe_box(xx,zz,w,d):xx,zz,w,d=x,z,5.3,6.3
    shade=seed%19
    g.specpart('TunnelRockCourse','tunnel_rock',xx,zz,bottom+h/2,w,d,h+.3,(71+shade,77+shade,94+shade),material='Slate',collide=True);count+=1
    bottom+=h-.18
# Staggered inner rock facets close the shoulder, but retain irregular horizontal
# ledges instead of narrow vertical stripes. All facets remain outside lane union.
for zi,z in enumerate(range(-102,23,5)):
 for xi,x in enumerate(range(-94,-43,3)):
  if 7.9<cave_dist(x,z)<11 and safe_box(x,z,3.25,5.65):
   bottom=-.15
   for layer in range(4):
    seed=zi*13+xi*7+layer*5;h=6.2+(seed%4)*.7
    xx=x+((seed%3)-1)*.28;zz=z+(((seed//3)%3)-1)*.4
    w=3.25;d=5.65+(seed%2)*.6
    if not safe_box(xx,zz,w,d):xx,zz,w,d=x,z,3.25,5.65
    shade=seed%17
    g.specpart('TunnelInnerRockFacet','tunnel_rock',xx,zz,bottom+h/2,w,d,h+.25,(76+shade,84+shade,101+shade),material='Slate',collide=True);count+=1
    bottom+=h-.15
# The ceiling is a broken rock spine. Three offset masses replace every broad
# slab; underside >=24 throughout. Both real skylight slots stay wholly open.
def skylight_overlap(z,d):
 return any(z-d/2<hi and z+d/2>lo for lo,hi in [(-24,-12),(-54,-42)])
for i,z in enumerate(range(-72,22,6)):
 if skylight_overlap(z,6.3):continue
 for j,x in enumerate([-86,-76,-66]):
  depth=6.3;bottom=24+((i+j)%3)*.55;h=7+((i*3+j)%4)
  zz=z+(.15 if j%2 else -.15);w=11.4+((i+j)%2)*1.2
  g.specpart('TunnelVaultRock','tunnel_roof',x+((i+j)%3-1)*.4,zz,bottom+h/2,w,depth,h,(88+(i+j)%4*5,98+(i+j)%3*4,115+(i+j)%3*4),material='Slate',collide=True)
  # Moss grows on each top surface and hangs down its outside edge.
  if (i+j)%3!=1:
   g.specpart('TunnelRoofMoss','tunnel_detail',x+1,zz,bottom+h+.15,w*.78,depth*.89,.3,(72+(i%3)*9,132+(i%3)*8,48),material='Grass')
   if j!=1:g.specpart('TunnelHangingMoss','tunnel_detail',x+(-w/2 if j==0 else w/2),zz+1,bottom+h-1,1.1,2.7,2.4,(74,137,47),material='Grass')
for i,(a,b) in enumerate(zip(branch,branch[1:])):
 length=math.dist(a,b);steps=max(1,math.ceil(length/6));dx=b[0]-a[0];dz=b[1]-a[1]
 for step in range(steps):
  for j,off in enumerate([-8.1,0,8.1]):
   h=6+((i+step+j)%3);bottom=24+((step+j)%2)*.6+.03+(i*10+step)*.003+j*.001
   aa=[a[0]+dx*step/steps-dz/length*off,a[1]+dz*step/steps+dx/length*off,bottom+h]
   bb=[a[0]+dx*(step+1)/steps-dz/length*off,a[1]+dz*(step+1)/steps+dx/length*off,bottom+h]
   g.segment('TunnelSouthVaultRock',aa,bb,11,'tunnel_roof',False,h)
   g.PARTS[-1]['color']=[87+(step%3)*7,96+(j%2)*7,115+(step%2)*6];g.PARTS[-1]['material']='Slate'
# An asymmetric split-rock mouth, not two posts under a beam. The stepped brow
# is entirely above the jump envelope; shoulder rocks reserve every old lane.
for side in [-1,1]:
 for layer,(bottom,h) in enumerate([(-.2,7.8),(7.1,8.7),(15.3,8.9)]):
  x=-76+side*(12.1+(.8 if layer%2 else 0));z=21.5-layer*.9
  w=7.5+(layer%2);d=8.2-layer*.7
  if safe_box(x,z,w,d):
   g.specpart('TunnelMouthShoulder','tunnel_rock',x,z,bottom+h/2,w,d,h,(83+layer*7,92+layer*6,107+layer*6),material='Slate',collide=True)
for i,(x,z,w,d,bottom,h) in enumerate([(-87,23,11.8,8.3,24,8),(-77,21.4,11.3,9.7,25.1,10),(-66.8,22.5,12,8.8,24.4,7.6)]):
 g.specpart('TunnelMouthBrokenBrow','tunnel_roof',x,z,bottom+h/2,w,d,h,(95+i*7,105+i*6,121+i*4),material='Slate',collide=True)
 g.specpart('TunnelMouthMoss','tunnel_detail',x-1,z,bottom+h+.18,w*.88,d*.83,.36,(85,148,48),material='Grass')
# One continuous slow crossing; server region matches this visible puddle.
g.specpart('TunnelMud','tunnel_detail',-76,-5,.14,13.7,24,.15,(65,107,117),material='SmoothPlastic',transparency=.25)
for z in [11,-31,-61]:
 for x in [-84,-68]:
  for j in range(3):
   xx=x+(j-1)*.9;zz=z+j*1.2
   g.specpart('TunnelMushroomStem','tunnel_detail',xx,zz,1+j*.3,.4,.4,2+j*.6,(160,175,166))
   g.specpart('TunnelMushroomGlow','light',xx,zz,2.1+j*.6,1.5,1.5,.6,(66,234,209),material='Neon')
for x,z in [(-87,-38),(-65,-66),(-52,-87),(-87,15)]:
 for j in range(3):
  g.specpart('TunnelCrystal','tunnel_detail',x+j*.7,z+j*.6,2+j*.7,1.3,1.1,4+j*1.4,(163,107,238),material='Neon',shape='Wedge')
for z in [-18,-48]:
 g.specpart('TunnelSkylightGlow','light',-84,z,23,.35,.35,.35,(242,228,157),material='Neon')
 # Thin translucent shafts are shipped geometry, never collision blockers.
 g.specpart('TunnelShaftOfLight','tunnel_detail',-76,z,13,.8,1.6,23,(243,225,162),material='Neon',transparency=.985)
# Stalactites live above24, away from the jump clearance envelope.
for z in [14,-28,-62]:g.specpart('TunnelStalactite','tunnel_detail',-80,z,25.5,2,2,3,(97,108,130),shape='Wedge')
from tunnel_look import refine
refine(g, new_edges, safe_box)
g.emit();out=json.loads((H/'scene.json').read_text())
for k,v in S.items():
 if k not in {'parts','routes'}:out[k]=v
out['tunnel']={'entrance':entrance,'exits':[near,south],'trunk':trunk,'branch':branch,'width':14,'ceiling_minimum':24,'mud':{'x':-76,'z':-5,'length':24,'speed':8},'wall_voxels':count,'tree_relocation':relocation}
(H/'scene.json').write_text(json.dumps(out,separators=(',',':')))
west=S['routes']['west']['points'];i=west.index(entrance);j=west.index(near)
distance=sum(math.dist(a,b) for a,b in zip(west[i:j],west[i+1:j+1]))
guardian=H.parents[1]/'slice-v2/prototype/guardian-greybox.rbxl'
report={'scene_sha256':hashlib.sha256((H/'scene.json').read_bytes()).hexdigest(),'baseline_sha256':hashlib.sha256(baseline.read_bytes()).hexdigest(),'guardian_sha256':hashlib.sha256(guardian.read_bytes()).hexdigest() if guardian.exists() else 'UNKNOWN','parts':len(g.PARTS),'wall_voxels':count,'west_reference_studs':distance,'west_reference_seconds_ESTIMATED':distance/16,'near_tunnel_studs':105,'near_tunnel_seconds_ESTIMATED':105/16+1.5,'near_time_saving_seconds_ESTIMATED':distance/16-105/16-1.5,'rate_status':'UNKNOWN measured hit/escape rates; targets only'}
(O/'TUNNEL-GEOMETRY.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
