"""Reuse existing 50-seed convex enclosure comparison, plus explicit exit rays."""
import json,sys
from pathlib import Path
H=Path(__file__).resolve().parent
tag=sys.argv[1] if len(sys.argv)>1 else 'deliver'
source=H.parent/'S2/r4-enclosure.py'
code=source.read_text().replace("'r4-before.json'","'before.json'").replace("'r4-after.json'",repr(tag+'.json')).replace("'r4-ENCLOSURE.json'",repr(tag+'-ENCLOSURE.json'))
scope={'__file__':str(H/'enclosure.py')};exec(compile(code,str(source),'exec'),scope)
geometry,hit=scope['geometry'],scope['hit'];g=geometry(tag+'.json')
camera=json.loads((H/'CAMERAS.json').read_text())
results=[]
for v in camera:
 if v.get('cutaway'):continue
 row={'camera':v['name'],'exit_aperture_rays':[]}
 for i,(x,z) in enumerate(((-76,78),(-61.8671875,98.953125)),1):
  tests=[(x+dx,y,z) for dx in (-3,0,3) for y in (3,6,9)]
  clear=[q for q in tests if not hit(g,v['eye'],q)]
  row['exit_aperture_rays'].append({'exit':i,'clear':len(clear),'total':len(tests),'clear_points':clear})
 results.append(row)
(H/(tag+'-EXIT-RAYS.json')).write_text(json.dumps({'method':'Physical/query convex box/wedge rays from locked camera eyes to 9 points around each policy exit; rays alone do not establish visible pixels, screen framing, or rendered cosmetic occlusion.','results':results},indent=2))
print('Exit ray counts',[(v['camera'],[r['clear'] for r in v['exit_aperture_rays']]) for v in results])
