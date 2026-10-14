"""Authored R6 grove anchors, deterministic fit corrections; no random scatter."""
import json, math, random, importlib.util, hashlib, collections
from pathlib import Path
import geometry as g
H=Path(__file__).parent; O=H.parents[1]/'treasure/map-v4'
spec=importlib.util.spec_from_file_location('pa',H/'placement-audit.py');pa=importlib.util.module_from_spec(spec);spec.loader.exec_module(pa)
baseline=H/'round6-baseline-scene.json'
if not baseline.exists():baseline.write_bytes((H/'scene.json').read_bytes())
S=json.loads(baseline.read_text());g.PARTS[:]=S['parts'];g.ROUTES.update(S['routes'])
r=random.Random(61013);serial=0;clusters={};placed=[a['parts'] for a in pa.groups(g.PARTS)]
terrain=pa.Terrain(g.PARTS);construction=pa.Construction(g.PARTS)
edges=[(a,b,rr['width']/2) for rr in S['routes'].values() for a,b in zip(rr['points'],rr['points'][1:])]
routegrid={}
for a,b,w in edges:
 for xx in range(math.floor((min(a[0],b[0])-w-17)/16),math.floor((max(a[0],b[0])+w+17)/16)+1):
  for zz in range(math.floor((min(a[1],b[1])-w-17)/16),math.floor((max(a[1],b[1])+w+17)/16)+1):routegrid.setdefault((xx,zz),[]).append((a,b,w))
def yaw(a):c=math.cos(a);s=math.sin(a);return [c,0,s,0,1,0,-s,0,c]
def block(n,cat,x,z,y,sx,sz,sy,color,**kw):return g.specpart(n,cat,x,z,y,sx,sz,sy,color,**kw)
def clear_path(x,z,radius):
 assert radius<=16,'route broad phase radius contract'
 return all(g.dist_segment(x,z,a,b)>=w+radius+.35 for a,b,w in routegrid.get((math.floor(x/16),math.floor(z/16)),[]))
# Reuse inspected native oak/rock/bush/flower recipes and their whole-prop checks.
src=(H/'round5.py').read_text();recipes=src[src.index('def asm('):src.index('# Route landmarks')]
recipes=recipes.replace("if not .3<=distance<=6:return False", "if not grove_mode and not .3<=distance<=6:return False")
grove_mode=False
exec(recipes)
# Spatial broad phase only; the exact original OBB narrow-phase is unchanged.
original_valid=valid;original_accept=accept;propgrid={}
def index_parts(ps):
 bs=[pa.bounds(p) for p in ps]
 for xx in range(math.floor(min(b[0] for b in bs)/16),math.floor(max(b[3] for b in bs)/16)+1):
  for zz in range(math.floor(min(b[2] for b in bs)/16),math.floor(max(b[5] for b in bs)/16)+1):propgrid.setdefault((xx,zz),[]).append(ps)
for ps in placed:index_parts(ps)
def valid(ps,check_sight=True):
 global placed
 if not ps:return False
 bs=[pa.bounds(p) for p in ps];near={id(a):a for xx in range(math.floor(min(b[0] for b in bs)/16),math.floor(max(b[3] for b in bs)/16)+1) for zz in range(math.floor(min(b[2] for b in bs)/16),math.floor(max(b[5] for b in bs)/16)+1) for a in propgrid.get((xx,zz),[])}
 all_placed=placed;placed=list(near.values())
 try:return original_valid(ps,check_sight)
 finally:placed=all_placed
def accept(ps,cluster=None):
 if not original_accept(ps,cluster):return False
 index_parts(ps);return True
old_candidate=candidate
def candidate(kind,x,z,scale=1):
 if kind not in {'tuft','grassbank'}:
  ps=old_candidate(kind,x,z,scale)
  for p in ps:p['assembly']=p['assembly'].replace('R5-','R6-');p['name']=p['name'].replace('R5','R6')
  return ps
 y=terrain.top(x,-z)
 if y is None:return []
 ident='R6-'+asm(kind);start=len(g.PARTS)
 w=3.4 if kind=='grassbank' else 1.1
 root=block('R6GrassFoot','ground_detail',x,z,y+.18,w,w,.36,(103,167,49))
 blades=[(-.35,0,1.5),(.25,.25,2.1),(0,-.3,1.2)] if kind=='tuft' else [(-1,-1,1.4),(-1,1,1.8),(1,-1,1.8),(1,1,1.3),(0,0,2.2),(-1,0,1.6),(1,0,1.7),(0,1,1.5),(0,-1,1.9)]
 for dx,dz,h in blades:block('R6GrassBlade','ground_detail',x+dx,z+dz,y+h/2,.55 if kind=='grassbank' else .3,.55 if kind=='grassbank' else .3,h,(135,187,61))
 ps=g.PARTS[start:];del g.PARTS[start:];return mark(ps,ident,'ground_detail',[root])
# Explicit regional compositions, west biased; each anchor has its own local grove.
anchors=[(-147,-110),(-124,-126),(-91,-143),(-53,-143),(-24,-152),(28,-150),
 (-146,-75),(-129,-66),(-67,-88),(-45,-74),(-25,-58),(28,-58),(54,-79),(78,-94),(121,-128),(146,-103),
 (-152,-38),(-134,-24),(-76,-21),(-63,-3),(-136,4),(-151,39),(-129,56),(-109,68),
 (-86,50),(-63,58),(-38,69),(-29,88),(-56,108),(-85,110),(-110,109),(-130,110),
 (-103,140),(-73,145),(-47,143),(-13,139),(23,140),(47,140),(69,140),(93,145),(123,143),
 (145,103),(133,79),(147,51),(125,28),(94,24),(69,18),(61,-9),(49,45),(79,66),(96,88),
 (24,92),(34,112),(-8,76),(135,-59),(134,-18)]
nudges=[(0,0)]+[(dx,dz) for rad in [2,4,6,8] for dx,dz in [(rad,0),(-rad,0),(0,rad),(0,-rad),(rad,rad),(-rad,rad),(rad,-rad),(-rad,-rad)]]
def fit(kind,x,z,scale=1,label=None):
 for dx,dz in nudges:
  if accept(candidate(kind,x+dx,z+dz,scale),label):return True
 return False
grove_mode=True
for i,(cx,cz) in enumerate(anchors):
 label=f'grove-{i+1:02d}';angle=[0,.65,-.7,1.2,-1.1,.3][i%6];c=math.cos(angle);s=math.sin(angle)
 # Compact touching-looking silhouettes, independently separated solid envelopes.
 recipe=[(0,0,'tree',.72),(-8,4,'tree',.46),(6,-6,'tree',.31),(7,5,'boulder',.66),(-4,-6,'bush',.62),(1,9,'bush',.5),(-9,-4,'bush',.42)]
 for dx,dz,kind,size in recipe:fit(kind,cx+dx*c-dz*s,cz+dx*s+dz*c,size,label)
 # Interior blossoms must be members of these actual local mixed groves.
 for dx,dz in [(0,-10),(10,0),(-10,0),(0,10),(7,-7),(-7,7)]:
  if fit('flower',cx+dx,cz+dz,.55,label):break
 ids=clusters.get(label,[])
 kinds=[a[0]['prop_kind'] for a in placed if a[0].get('assembly') in ids]
 # Fill required members locally; never turn a distant prop into a fake cluster.
 for kind,size,required in [('tree',.38,2),('boulder',.48,1),('bush',.44,1),('flower',.5,1)]:
  for dx,dz in [(-10,-8),(10,8),(-10,8),(10,-8),(0,12),(0,-12),(12,0),(-12,0),(5,11),(-5,-11)]:
   ids=clusters.get(label,[]);kinds=[a[0]['prop_kind'] for a in placed if a[0].get('assembly') in ids]
   if kinds.count(kind)>=required:break
   fit(kind,cx+dx,cz+dz,size,label)
 ids=clusters.get(label,[]);kinds=[a[0]['prop_kind'] for a in placed if a[0].get('assembly') in ids]
 tree_sizes={a[0]['size'][1] for a in placed if a[0].get('assembly') in ids and a[0]['prop_kind']=='tree'}
 if kinds.count('tree')<2 or len(tree_sizes)<2 or not {'tree','bush','boulder','flower'}<=set(kinds):
  bad=set(clusters.pop(label,[]));g.PARTS[:]=[p for p in g.PARTS if p.get('assembly') not in bad];placed[:]=[a for a in placed if a[0].get('assembly') not in bad]
  propgrid.clear()
  for ps in placed:index_parts(ps)
 print(label,len(clusters.get(label,[])),flush=True)
for label,ids in S['r5']['clusters'].items():
 if not label.startswith('pocket'):continue
 roots=[p for p in g.PARTS if p.get('assembly') in ids and p.get('root')]
 cx=sum(p['position'][0] for p in roots)/len(roots);cz=-sum(p['position'][2] for p in roots)/len(roots)
 clusters['retained-'+label]=list(ids)
 for kind,size,required in [('tree',.38,2),('boulder',.48,1),('bush',.44,1),('flower',.5,1)]:
  for dx,dz in [(0,0),(-6,-6),(6,6),(-10,8),(10,-8),(0,12),(12,0),(-12,0),(0,-12)]:
   kinds=[a[0].get('prop_kind') for a in placed if a[0].get('assembly') in clusters['retained-'+label]]
   if kinds.count(kind)>=required:break
   fit(kind,cx+dx,cz+dz,size,'retained-'+label)
 for dx,dz in [(-8,8),(8,-8),(-12,0),(12,0),(0,-12),(0,12)]:
  ids=clusters['retained-'+label]
  heights={a[0]['size'][1] for a in placed if a[0].get('assembly') in ids and a[0]['prop_kind']=='tree'}
  if len(heights)>=2:break
  fit('tree',cx+dx,cz+dz,.5,'retained-'+label)
grove_mode=False
# Grounded low hedges follow both sides of route segments. Junctions have extra
# restraint: the union of all full-width route reserves always wins.
hedges=collections.Counter();tufts=0
for name,rr in S['routes'].items():
 if name.startswith('tunnel') or name in {'bridge','ravine_floor_loop','ravine_ramp'}:continue
 pts=rr['points'];travel=0;next_site=0
 for a,b in zip(pts,pts[1:]):
  dx,dz=b[0]-a[0],b[1]-a[1];run=math.hypot(dx,dz)
  if run<.01:continue
  while next_site<=travel+run:
   t=max(0,(next_site-travel)/run)
   for side in [-1,1]:
    offset=rr['width']/2+3.4;x=a[0]+dx*t-dz/run*side*offset;z=a[1]+dz*t+dx/run*side*offset
    if accept(candidate('bush',x,z,.46)):hedges[name]+=1
    if accept(candidate('flower',x-dx/run*2.8,z-dz/run*2.8,.48)):hedges[name+'-flowers']+=1
    for extra in [0,3.5]:
     if accept(candidate('tuft',x-dx/run*extra-dz/run*side*2,z-dz/run*extra+dx/run*side*2)):tufts+=1
   next_site+=6.5
  travel+=run
# Ravine rim must read as a low planted edge with an open bridge/throw corridor.
rim=0
for x in range(-84,85,6):
 if abs(x)<22:continue
 for z in [-37,37]:
  if fit('bush',x,z,.38):rim+=1
# Interior tuft accents are attached to accepted grove feet, never global scatter.
for label,ids in clusters.items():
 root=next(p for p in g.PARTS if p.get('assembly')==ids[0] and p.get('root'))
 x,z=root['position'][0],-root['position'][2]
 for dx,dz in [(-5,0),(5,0),(0,-5),(0,5),(-4,4),(4,-4)]:
  if fit('tuft',x+dx,z+dz):tufts+=1
# R6b: thicken each authored composition in layers. These banks remain within
# its local planting footprint; exact pairwise OBB tests reject every collision.
grove_mode=True;dense_banks=0
for label,ids in list(clusters.items()):
 roots=[p for p in g.PARTS if p.get('assembly') in ids and p.get('root')]
 cx=sum(p['position'][0] for p in roots)/len(roots);cz=-sum(p['position'][2] for p in roots)/len(roots)
 for dx,dz in [(-8,0),(8,0),(0,-8),(0,8),(-7,-7),(7,7),(-7,7),(7,-7),(-12,4),(12,-4),(4,12),(-4,-12)]:
  fit('bush',cx+dx,cz+dz,.52,label)
 for dx,dz in [(-10,-10),(-10,0),(-10,10),(0,-10),(0,10),(10,-10),(10,0),(10,10),(-5,-5),(-5,5),(5,-5),(5,5),(-14,0),(14,0),(0,-14),(0,14)]:
  if fit('grassbank',cx+dx,cz+dz,1,label):dense_banks+=1
 for dx,dz in [(-9,-3),(9,3),(-3,9),(3,-9),(-12,-7),(12,7)]:fit('flower',cx+dx,cz+dz,.6,label)
grove_mode=False
# Low irregular planting pockets frame shoulder turns in three depths rather
# than the former single bead row. Surface unions and sight reservations win.
turn_banks=0
for name,rr in S['routes'].items():
 if name.startswith('tunnel') or name in {'bridge','ravine_floor_loop','ravine_ramp'}:continue
 pts=rr['points']
 for i in sorted(set(min(len(pts)-2,j) for j in [0,len(pts)//4,len(pts)//2,3*len(pts)//4,len(pts)-2])):
  a,b=pts[i:i+2];dx,dz=b[0]-a[0],b[1]-a[1];run=math.hypot(dx,dz)
  if run<.01:continue
  for side in [-1,1]:
   for along,out,kind,size in [(-4,5.5,'bush',.62),(0,6.8,'bush',.7),(4,5.5,'bush',.55),(-6,4.7,'grassbank',1),(6,4.7,'grassbank',1),(0,10.5,'grassbank',1)]:
    d=rr['width']/2+out;x=a[0]+dx/run*along-dz/run*side*d;z=a[1]+dz/run*along+dx/run*side*d
    if fit(kind,x,z,size):turn_banks+=1
g.emit();out=json.loads((H/'scene.json').read_text())
for k,v in S.items():
 if k not in {'parts','routes'}:out[k]=v
out['r6']={'anchors':anchors,'clusters':clusters,'hedges':dict(hedges),'rim_bushes':rim,'tufts':tufts,'dense_grass_banks':dense_banks,'turn_planting_parts':turn_banks,'placement':'Explicit grove anchors; ordered local fit corrections; sampled support, construction OBB, prop OBB, lane union and selected sight rays; no random positions.'}
(H/'scene.json').write_text(json.dumps(out,separators=(',',':')))
report=pa.audit(out);report['scene_sha256']=hashlib.sha256((H/'scene.json').read_bytes()).hexdigest()
(O/'ROUND6-PLACEMENT.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if not k.endswith('details')},indent=2))
(O/'ROUND6-GEOMETRY.json').write_text(json.dumps(out['r6'],indent=2))
