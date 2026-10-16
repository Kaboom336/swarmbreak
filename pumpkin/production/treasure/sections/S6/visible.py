"""Identify real foreground producers in the locked player frames."""
from pathlib import Path
import json,numpy as np
H=Path(__file__).resolve().parent
code=(H/'mount-plan.py').read_text().split('out=[]')[0]
code=code.replace("if p['collidable']", "if p['transparency']<.99")
exec(compile(code,str(H/'mount-plan.py'),'exec'))
for v in views[:3]:
 eye=np.array(v['eye'],dtype=float);f=np.array(v['target'],dtype=float)-eye;f/=np.linalg.norm(f);right=np.cross(f,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,f)
 print(v['name'])
 for sx,sy in [(-.7,.4),(-.4,0),(.8,.4),(.6,0),(.4,-.3)]:
  direction=f+right*sx*.75+up*sy*.75*540/960;direction/=np.linalg.norm(direction)
  hit=ray(eye,direction)
  if hit:print(sx,sy,hit[0]['name'],hit[0]['position'],hit[1].tolist())
