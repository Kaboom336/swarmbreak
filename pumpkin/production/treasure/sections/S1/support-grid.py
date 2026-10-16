import json, math
from pathlib import Path
root=Path(__file__).resolve().parents[3]
parts=json.loads((root/'prototype/studio-pass-1/polish-after.json').read_text())['parts']
floors=[p for p in parts if p['collidable'] and abs(p['rotation'][4])>.9999 and -3<=p['position'][1]+p['size'][1]/2<=1]
heights={}
for x in range(-58,59):
 for z in range(98,157):
  h=[p['position'][1]+p['size'][1]/2 for p in floors if abs(x-p['position'][0])<=p['size'][0]/2+.001 and abs(z-p['position'][2])<=p['size'][2]/2+.001]
  if h:heights[x,z]=max(h)
for side in [-1,1]:
 candidates=[]
 for x in range(30*side,51*side,side):
  for z in range(125,150):
   samples=[heights.get((x+dx,z+dz)) for dx in range(-8,9) for dz in range(-4,5)]
   if None not in samples and max(samples)-min(samples)<=.15:candidates.append((x,z,round(max(samples),2)))
 print(side,candidates[:50])
