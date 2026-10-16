"""Plan actual kit envelopes tangent to preserved wall solids; strict horizontal lane margin."""
import json,sys
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent
sys.argv=['contact.py','r2-after'];scope={'__file__':str(H/'contact.py')}
exec((H/'contact.py').read_text().split('physical=')[0],scope)
box,penetrates=scope['box'],scope['penetrates']
d=json.loads((H/'r2-after.json').read_text())
solids=[(p,box(p)) for p in d['parts'] if p['collidable']]
lo=np.array([b[3] for _,b in solids]);hi=np.array([b[4] for _,b in solids])
lanes=[]
for p in d['parts']:
 if p.get('lane'):
  q=dict(p);q['size']=[p['size'][0]+2,500,p['size'][2]+2];q['position']=[p['position'][0],0,p['position'][2]];lanes.append(box(q))
visible=json.loads((H/'r2-visible.json').read_text())
keys={a['key'] for a in visible}
groups=[]
for p,b in solids:
 if p['name'] not in ('TunnelHillEarth','TunnelRockCourse','R5BoulderFoot'):continue
 if p['name']+'@'+','.join(f'{v:.3f}' for v in p['position']) not in keys:continue
 c,R,h,low,high=b
 if c[2]<54 or c[2]>120 or c[0]<-95 or c[0]>-45:continue
 for axis,sign in [(0,1),(0,-1),(2,1),(2,-1)]:
  if not any((np.array(eye)-c)[axis]*sign>0 for eye in [(-35,7,130),(-53,6,115)]):continue
  tangent=2 if axis==0 else 0
  candidates=[]
  # Two staggered bands of faceted boulders: a large base, medium shoulders, small crowns.
  for y,t in [(2,0),(5,-1.4),(8,1.3),(11,-1),(14,1),(17,-1.3),(20,1.2)]:
   for thickness,width in [(1.8,4.6),(1.2,3.2),(.65,2.0)]:
    size=np.array([width,3.2 if width<4 else 4.2,width]);size[axis]=thickness
    size[tangent]=min(width,h[tangent]*1.7)
    size*=1 if y%2 else .91
    center=c.copy();center[1]=y+size[1]/2;center[tangent]+=t
    center[axis]+=sign*(h[axis]+size[axis]/2-.001)
    if center[1]-size[1]/2>high[1] or center[1]+size[1]/2<low[1]:continue
    q={'position':center.tolist(),'rotation':[1,0,0,0,1,0,0,0,1],'size':size.tolist()};a=box(q)
    if any(np.all(np.minimum(a[4],l[4])-np.maximum(a[3],l[3])>.035) and penetrates(a,l) for l in lanes):continue
    cand=np.where(np.all(np.minimum(a[4],hi)-np.maximum(a[3],lo)>.035,axis=1))[0]
    if any(penetrates(a,solids[i][1]) for i in cand):continue
    candidates.append(dict(x=float(center[0]),y=float(center[1]-size[1]/2),z=float(center[2]),size=size.tolist(),axis=axis,sign=sign));break
  if len(candidates)>=3:groups.append(candidates[:7])
lines=['-- R3: tangent kits2 rock clusters, each 3-7 varied rocks; generated from unchanged solid faces.']
for group,rocks in enumerate(groups,1):
 for i,g in enumerate(rocks,1):
  rgb=[(112,105,94),(137,125,107),(95,91,83)][(group+i)%3]
  lines.append("table.insert(S.kits,{id='RockCluster%d_%d',name='quaternius-nature__Rock_Medium_1',x=%.4f,y=%.4f,z=%.4f,size=V(%.4f,%.4f,%.4f),fit=true,attachment='S2_RockAnchor%d_%d',color={%d,%d,%d}})"%(group,i,g['x'],g['y'],g['z'],*g['size'],group,i,*rgb))
(H/'r3-rock-plan.json').write_text(json.dumps(groups,indent=2))
# Emit an apply_patch input; edits are always applied with apply_patch.
source=Path('prototype/meadow-v4/Section2.luau').read_text()
start=source.index('-- Three supported five-rock clusters.')
end=source.index('S.ground=function',start)
old=source[start:end]
patch='*** Begin Patch\n*** Update File: prototype/meadow-v4/Section2.luau\n@@\n'+''.join('-'+x+'\n' for x in old.splitlines())+''.join('+'+x+'\n' for x in lines)+'*** End Patch\n'
(H/'r3-rocks.patch').write_text(patch)
print('planned',len(groups),'clusters',sum(map(len,groups)),'rocks; patch ready')
