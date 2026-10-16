"""Conservative oriented-box penetration test against unchanged physical world.
Actual imported mesh bases are checked separately by render.py.
Touching joints and botanical overlaps are not unintended clipping.
"""
import json, math, sys
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent
tag=sys.argv[1] if len(sys.argv)>1 else 'r2'
data=json.loads((H/(tag+'.json')).read_text())
def box(p):
 r=np.array(p['rotation']).reshape(3,3)
 c=np.array(p['position']);h=np.array(p['size'])/2
 ext=np.abs(r)@h
 return c,r,h,c-ext,c+ext
def penetrates(a,b,tol=.035):
 ca,ra,ha,_,_=a;cb,rb,hb,_,_=b
 delta=cb-ca
 axes=[*ra.T,*rb.T]+[np.cross(x,y) for x in ra.T for y in rb.T]
 for axis in axes:
  n=np.linalg.norm(axis)
  if n<1e-6:continue
  axis=axis/n
  overlap=sum(abs(axis@ra[:,i])*ha[i] for i in range(3))+sum(abs(axis@rb[:,i])*hb[i] for i in range(3))-abs(axis@delta)
  if overlap<=tol:return False
 return True
physical=[(p,box(p)) for p in data['parts'] if p['collidable']]
lo=np.array([b[3] for p,b in physical]);hi=np.array([b[4] for p,b in physical])
errors=[];tested=0
for p in data['parts']:
 if p.get('section')!='S1':continue
 a=box(p);tested+=1
 candidates=np.where(np.all(np.minimum(a[4],hi)-np.maximum(a[3],lo)>.035,axis=1))[0]
 for i in candidates:
  q,b=physical[i]
  if penetrates(a,b):errors.append({'native':p['name'],'at':p['position'],'physical':q['name'],'physical_at':q['position']})
assert tested>0,'S1 metadata missing from export'
# Contact graph: every elevated assembly must connect back to a physical floor.
native=[(p,box(p)) for p in data['parts'] if p.get('section')=='S1']
kit_errors=[];kit_floating=[]
for g in data['kits']:
 p={'position':[g['x'],g['y']+g['size'][1]/2,g['z']],'size':g['size'],'rotation':g.get('rotation',[1,0,0,0,1,0,0,0,1])}
 a=box(p)
 for i in np.where(np.all(np.minimum(a[4],hi)-np.maximum(a[3],lo)>.035,axis=1))[0]:
  if penetrates(a,physical[i][1]):kit_errors.append({'kit':g['id'],'physical':physical[i][0]['name']})
 attached=any(q['name']==g.get('attachment') and np.max(np.abs(a[0]-b[0]))<.002 and np.max(np.abs(a[2]-b[2]))<.002 for q,b in native)
 if not attached and not any(contact_box[3][1]-.035<=g['y']<=contact_box[4][1]+.035 and
            abs(contact_box[4][1]-g['y'])<=.035 and
            penetrates(a,contact_box,tol=-.002)
            for _,contact_box in physical+native):kit_floating.append(g['id'])
supported=set();links={i:[] for i in range(len(native))}
def contact(a,b):
 gap=np.maximum(a[3]-b[4],b[3]-a[4])
 return np.max(gap)<=.035
for i,(p,a) in enumerate(native):
 for q,b in physical:
  if contact(a,b):supported.add(i);break
 for j in range(i):
  if contact(a,native[j][1]):links[i].append(j);links[j].append(i)
queue=list(supported)
while queue:
 i=queue.pop()
 for j in links[i]:
  if j not in supported:supported.add(j);queue.append(j)
floating=[{'name':p['name'],'at':p['position']} for i,(p,a) in enumerate(native) if i not in supported]
out={'native_parts_checked':tested,'kits_checked':len(data['kits']),'physical_penetrations':errors,'kit_physical_penetrations':kit_errors,'kit_support_errors':kit_floating,'floating_assemblies':floating,'tolerance_studs':.035,'method':'Conservative OBB/SAT physical penetration; assembly contact graph to physical world; botanical/assembly joints separate from unintended clipping.'}
(H/(tag+'-physical-contact.json')).write_text(json.dumps(out,indent=2))
print(json.dumps(out,indent=2))
assert not errors,'new art intersects retained physical geometry'
assert not floating,'unsupported assembly'
assert not kit_errors and not kit_floating,'kit physical contact failed'
