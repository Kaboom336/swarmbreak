import json,collections,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'before.json').read_text())
ps=[p for p in d['parts'] if -65<=p['position'][0]<=125 and -158<=p['position'][2]<=-35 and not(-32<=p['position'][0]<=32 and -132<=p['position'][2]<=-72 and p['position'][1]>=44)]
print('SOLIDS',collections.Counter(p['name'] for p in ps if p['collidable']))
print('LANES')
for p in ps:
 if p.get('lane') and ('spiral' in p['name'].lower() or 'shelf' in p['name'].lower()): print(p['name'],p['position'],p['size'],p['rotation'])
print('MAJOR SOLIDS')
seen=set()
for p in ps:
 if p['collidable'] and not p.get('lane'):
  key=p['name']
  if key not in seen:print(key,p['position'],p['size']);seen.add(key)
print('ROUTE KEYS')
print([p for p in d.get('routes',[])])
