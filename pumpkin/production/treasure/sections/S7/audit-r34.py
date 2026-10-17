from pathlib import Path
import json,sys
H=Path(__file__).resolve().parent
tag=sys.argv[1]
before=json.loads((H/'before-r34.json').read_text())
after=json.loads((H/(tag+'.json')).read_text())
from collections import Counter
def signature(p):return json.dumps(p,sort_keys=True)
# Exactly two appearance fields on the twenty nonphysical pedestal stones.
for p in before['parts']:
 if p['name']=='AcornNest':
  assert not(p['collidable'] or p['query'] or p['touch'])
  p['material']='Slate';p['color']=[106,115,104]
  matches=[q for q in after['parts'] if q['name']==p['name'] and q['position']==p['position']]
  assert len(matches)==1
  assert max(abs(a-b) for a,b in zip(matches[0]['color'],p['color']))<.001
  p['color']=matches[0]['color']
assert not Counter(map(signature,before['parts']))-Counter(map(signature,after['parts'])),'retained signature changed'
# Grounded camp bases: full 5x5 bearing grids, same .035 tolerance.
import numpy as np
tops=[]
for p in before['parts']:
 if p['collidable'] and np.max(np.abs(np.array(p['rotation']).reshape(3,3)-np.eye(3)))<.001:
  c=np.array(p['position']);h=np.array(p['size'])/2;tops.append((c-h,c+h))
bearing_probes=0
for p in after['parts']:
 if not p['name'].startswith(('S7_FireStone','S7_LogSeat','S7_TentPeg','S7_FlagPole','S7_TrinketCoin','S7_TrinketCharm')):continue
 c=np.array(p['position']);r=np.array(p['rotation']).reshape(3,3);h=np.array(p['size'])/2
 # Coins have a rotated cylinder axis. Probe its oriented-box bottom footprint.
 extent=np.abs(r)@h
 for x in np.linspace(-extent[0],extent[0],5):
  for z in np.linspace(-extent[2],extent[2],5):
   v=c+np.array([x,-extent[1],z]);bearing_probes+=1
   assert any(a[0]-.002<=v[0]<=b[0]+.002 and a[2]-.002<=v[2]<=b[2]+.002 and abs(b[1]-v[1])<=.035 for a,b in tops),('bearing',p['name'],v)
# Reuse existing strict geometry/contact checks without modifying their files.
code=(H/'audit.py').read_text()
code=code.replace("old,new=read('before.json'),read(tag+'.json')",'old,new=before,after')
code=code.replace('all_existing_art_exact=True','all_existing_art_except_authorized_pedestal_appearance_exact=True')
code=code.replace('bearing_footprint_probes=support_probes','bearing_footprint_probes=bearing_probes')
code=code.replace('existing_Keeper_treasure_court_bait_bell_sight_blockers_exact=True','existing_Keeper_treasure_court_bait_bell_sight_blockers_exact=True,pedestal_appearance_only=True')
exec(compile(code,__file__,'exec'))
