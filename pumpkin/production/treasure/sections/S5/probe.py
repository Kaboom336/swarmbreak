import json,collections,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'before.json').read_text())
print('S5 solids:',collections.Counter(p['name'] for p in d['parts'] if 58<p['position'][0]<176 and -145<p['position'][2]<155 and p['collidable']))
for x,z in [(98,0),(98,20),(98,40),(98,60),(141,10),(141,40),(160,40),(160,70),(118,100)]:
 hits=[]
 for p in d['parts']:
  r=np.array(p['rotation']).reshape(3,3);e=np.abs(r)@np.array(p['size'])/2;c=p['position']
  if p['collidable'] and abs(x-c[0])<=e[0] and abs(z-c[2])<=e[2]:hits.append((round(c[1]+e[1],3),p['name'],p.get('lane')))
 print(x,z,sorted(hits,reverse=True)[:5])
