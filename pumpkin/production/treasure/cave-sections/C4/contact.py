"""Conservative OBB SAT against every protected solid; .035 penetration tolerance.
Wedge solid boxes overbound their true shape, so a pass is conservative.
"""
import json,sys,itertools
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent;tag=sys.argv[1]
d=json.loads((H/(tag+'.json')).read_text());old=[p for p in d['parts']if p['collidable']]
new=[p for p in d['parts']if p['name'].startswith('C4_')]
def obb(p):return np.array(p['position'],float),np.array(p['size'],float)/2,np.array(p['rotation'],float).reshape(3,3)
def penetration(a,b):
 ca,ha,ra=obb(a);cb,hb,rb=obb(b);delta=cb-ca
 if np.any(np.abs(delta)>np.abs(ra)@ha+np.abs(rb)@hb-.035):return False
 for axis in [*ra.T,*rb.T,*[np.cross(x,y)for x in ra.T for y in rb.T]]:
  norm=np.linalg.norm(axis)
  if norm<1e-7:continue
  axis=axis/norm
  if abs(delta@axis)>=sum(abs(ra.T@axis)*ha)+sum(abs(rb.T@axis)*hb)-.035:return False
 return True
errors=[dict(new=a['name'],old=b['name'],at=b['position'])for a in new for b in old if penetration(a,b)]
report=dict(state='PASS'if not errors else'FAIL',tolerance=.035,cosmetic_envelopes=len(new),protected_solids=len(old),contact=len(errors),errors=errors[:30],method='OBB SAT, conservative wedge boxes; intentional cosmetic-cluster overlap is nonphysical')
(H/('CONTACT-'+tag+'.json')).write_text(json.dumps(report,indent=2));print(report)
assert not errors


