"""Generate explicit, reviewable hill edits and cosmetic cleanup from the R3 export."""
import json,math
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'r3-after.json').read_text())
edits=[];removed=[]
def key(p):return p['name']+'@'+','.join(f'{v:.2f}' for v in p['position'])
# Face follows the existing diagonal mouth; the interior side of every original
# wall/course/vault stays authoritative. Only front hill voxels/caps are reshaped.
for p in d['parts']:
 x,y,z=p['position'];sx,sy,sz=p['size']
 if p['name'] not in ('TunnelHillEarth','TunnelHillTurf') or p.get('lane'):continue
 if not (-116<x<-28 and z>=75):continue
 if p['name']=='TunnelHillTurf':removed.append(key(p));continue
 bottom=y-sy/2
 # Final blind-critic correction: two steep exterior shoulders. Inner wall/facet
 # blockers and the bait cover remain exact; a 56.3-degree slope has no ledges.
 if (x,z) in ((-79,117),(-49,87)):
  edits.append({'key':key(p),'position':[x,9,117 if x==-79 else 87],
   'size':[sx,18,12 if x==-79 else 6],'shape':'Wedge','rotation':[-1,0,0,0,1,0,0,0,-1]})
  continue
 # Preserve the full original volume through Y24 inside the tunnel; only sculpt
 # upper hill mass. Outside corridor walls remain at least 18 studs high.
 top=min(y+sy/2,max(bottom+.25,24.25 if bottom>=23.9 else 18))
 if top<y+sy/2-.01:
  newz,newsz=z,sz
  facez=93.5-(x+63.95)*11/22.5
  if bottom>=23.9 and z+sz/2>facez:
   front=facez;back=z-sz/2
   if front<=back+.1:removed.append(key(p));continue
   newz,newsz=(front+back)/2,front-back
  edits.append({'key':key(p),'position':[x,(bottom+top)/2,newz],'size':[sx,top-bottom,newsz]})
lines=['local r4HillEdits={']
for e in edits:
 fields=','.join('{'+','.join(f'{v:.5f}' for v in e[f])+'}' for f in ('position','size'))
 if e.get('shape'):fields+=',true,{'+','.join(str(v) for v in e['rotation'])+'}'
 lines.append(' ['+json.dumps(e['key'])+']={'+fields+'},')
lines+=['}','local r4HillRemove={']+[f' [{json.dumps(k)}]=true,' for k in removed]+['}']
text='\n'.join(lines)+'\n'
(H/'r4-hill-plan.json').write_text(json.dumps({'edits':edits,'removed':removed},indent=2))
print('*** Begin Patch\n*** Update File: prototype/meadow-v4/Section2.luau\n@@\n-local groundModule=require(script.Parent.Section1)\n+'+text.rstrip().replace('\n','\n+')+'\n+local groundModule=require(script.Parent.Section1)\n*** End Patch')
