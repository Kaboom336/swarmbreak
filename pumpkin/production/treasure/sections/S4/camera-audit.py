"""Static eye containment and source-authored warning board clearance."""
import json,numpy as np,sys
from pathlib import Path
H=Path(__file__).resolve().parent;tag=sys.argv[1]
d=json.loads((H/(tag+'.json')).read_text());views=json.loads((H/'CAMERAS.json').read_text())
issues=[]
for v in views:
 for p in d['parts']:
  if not (p['collidable'] or p['query']):continue
  r=np.array(p['rotation']).reshape(3,3);q=r.T@(np.array(v['eye'])-p['position'])
  if np.all(np.abs(q)<np.array(p['size'])/2-.035):issues.append(dict(camera=v['name'],solid=p['name']))
assert not issues,issues
board=next(p for p in d['parts'] if p['name']=='S4_WarningBoard')
assert board['label']=='BRIDGE\nWATCH STEP' and board['labelFace']=='Back'
out=dict(status='PASS',camera_eyes_outside_query_and_physical_solids=True,warning_full_source_text=board['label'],warning_face='Back / south toward approach',live_font_occlusion_and_avatar_motion='UNKNOWN')
(H/'CAMERA-CLEARANCE.json').write_text(json.dumps(out,indent=2));print('PASS static camera containment and full warning source text')
