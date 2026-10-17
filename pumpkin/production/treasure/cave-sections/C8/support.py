"""Envelope connectivity audit; conservative support proxy, not real mesh contact.
Native convex/source-mesh appearance is judged in matched render boards.
"""
import json,sys
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent;tag=sys.argv[1]
plan=json.loads((H/(tag+'-plan.json')).read_text())
shell=[g for g in plan if 'Stratum' in g['name'] or 'Join' in g['name'] or 'Keel' in g['name']]
def bounds(g):
 a=np.radians(g.get('yaw',0));r=np.array([[np.cos(a),0,np.sin(a)],[0,1,0],[-np.sin(a),0,np.cos(a)]])
 e=abs(r)@np.array(g['s'])/2;c=np.array(g['c']);return c-e,c+e
bs=[bounds(g) for g in shell];seen={0};pending=[0]
while pending:
 i=pending.pop();a,b=bs[i]
 for j,(c,d) in enumerate(bs):
  if j not in seen and np.all(np.minimum(b,d)-np.maximum(a,c)>=-.01):seen.add(j);pending.append(j)
report=dict(state='PASS'if len(seen)==len(shell)else'REVISIT',shell_envelopes=len(shell),connected_component=len(seen),unconnected=[g['name']for i,g in enumerate(shell)if i not in seen],method='AABB connectivity proxy only, not actual rock mesh bearing; intentional cosmetic overlap',actual_mesh_continuity='UNKNOWN; visual gaps judged separately')
(H/('SUPPORT-'+tag+'.json')).write_text(json.dumps(report,indent=2));print(report)
