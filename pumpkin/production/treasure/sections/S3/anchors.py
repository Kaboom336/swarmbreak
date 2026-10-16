"""Fit visible wall corbels from preserved timbers to the first retained solid."""
from pathlib import Path
import numpy as np,json
H=Path(__file__).resolve().parent
exec(compile((H/'plan.py').read_text().split('for z in range')[0],str(H/'plan.py'),'exec'))
anchors=[]
for i in range(8):
 for side in (-1,1):
  z=-11+i*11;start=-76+side*7.18;y=9.85
  def fits(length):return safe([start+side*length/2,y,z],[length,.55,.65])
  low,high=.02,3
  if not fits(low):continue
  if fits(high):continue # No proven wall attachment within this reach.
  for _ in range(24):
   m=(low+high)/2
   if fits(m):low=m
   else:high=m
  anchors.append(dict(i=i,side=side,x=start+side*low/2,y=y,z=z,length=low))
(H/'WALL-ANCHORS.json').write_text(json.dumps(anchors,indent=2))
for p in anchors:print('{%d,%d,%.6f,%.6f},'%(p['i'],p['side'],p['x'],p['length']))
print(len(anchors),'fitted wall corbels; exact conservative penetration tolerance .035; final full assembly audit required')
