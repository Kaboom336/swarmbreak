"""Run existing full collision, graph, placement audits under Blender Python."""
import sys,runpy,json,hashlib,importlib.util
from pathlib import Path
H=Path(__file__).parent;O=H.parents[1]/'treasure/map-v4'
sys.path.insert(0,str(H))
runpy.run_path(str(H/'audit.py'),run_name='__main__')
runpy.run_path(str(H/'routes-check.py'),run_name='__main__')
spec=importlib.util.spec_from_file_location('placement',H/'placement-audit.py')
placement=importlib.util.module_from_spec(spec);spec.loader.exec_module(placement)
raw=(H/'scene.json').read_bytes();scene=json.loads(raw)
report=placement.audit(scene)
report['scene_sha256']=hashlib.sha256(raw).hexdigest()
(O/'LOOK-PLACEMENT.json').write_text(json.dumps(report,indent=2))
errors={k:v for k,v in report.items() if isinstance(v,int) and k not in {'assemblies','parts_in_prop_audit','preserved_tunnel_lighting_parts'}}
assert not any(errors.values()),errors
collision=json.loads((O/'collision-audit.json').read_bytes())
assert not collision['violations']
print('PASS placement counters',errors,flush=True)
# Authored hill additions: root contacts and shaft clearance are checked here,
# because the existing audit explicitly covers surface props only.
def height(x,z):
 import math
 center=-76+max(0,-z-55)*.25+3*math.sin((z+35)*.03)
 radius=61+4*math.sin(z*.045)
 cross=max(0,1-((x-center)/radius)**2)
 end=1 if -99<=z<=23 else max(0,1-((z-23)/32 if z>23 else (-99-z)/30)**2)
 return 52*cross*end*(1-.17*((z+35)/75)**2)
roots=[p for p in scene['parts'] if p['name'] in {'LookHillTreeTrunk','LookHillFlowerStem','LookHillBush','LookHillBoulder'}]
skin=[p for p in scene['parts'] if p['name']=='LookContinuousTurf']
def skin_ray(p,x,z):
 hit=placement.vertical(p,x,z)
 if hit is None:return None
 lo,hi=hit;r=p['rotation'];o=p['position'];s=p['size']
 # Exact native Wedge half-space, in addition to its oriented box slabs.
 a=(r[1]*(x-o[0])-r[4]*o[1]+r[7]*(z-o[2]))/s[1]-(r[2]*(x-o[0])-r[5]*o[1]+r[8]*(z-o[2]))/s[2]
 d=r[4]/s[1]-r[5]/s[2]
 if abs(d)<1e-9:
  if a>1e-5:return None
 elif d>0:hi=min(hi,-a/d)
 else:lo=max(lo,-a/d)
 return hi if hi>=lo-.00001 else None
root_errors=0
analytic_errors=0
for p in roots:
 x,y,z=p['position'];base=y-p['size'][1]/2
 hits=[h for q in skin if (h:=skin_ray(q,x,z)) is not None]
 root_errors+=not hits or abs(base-max(hits))>.75
 if p['name'] in {'LookHillTreeTrunk','LookHillFlowerStem'}:analytic_errors+=abs(base-height(x,-z))>.001
shaft_errors=0
for p in scene['parts']:
 if not p['name'].startswith('Look') or p['name']=='LookContinuousTurf':continue
 x,y,z=p['position'];sx,sy,sz=p['size']
 if y<29:continue
 for hz in (-18,-46):
  if abs(x+76)<sx/2+5.9 and abs(-z-hz)<sz/2+3.8:shaft_errors+=1
assert root_errors==0 and shaft_errors==0 and analytic_errors==0,(root_errors,shaft_errors,analytic_errors)
(O/'LOOK-HILL-AUDIT.json').write_text(json.dumps({'state':'PASS','new_root_samples':len(roots),'floating_root_errors':root_errors,'analytic_trunk_stem_errors':analytic_errors,'skylight_intrusions':shaft_errors,'scope':'New hill tree/stem/bush/boulder roots against exact native turf Wedge rays, 0.75-stud support/inset tolerance; existing shaft footprint; surface prop and full collision audits remain separate'},indent=2))
