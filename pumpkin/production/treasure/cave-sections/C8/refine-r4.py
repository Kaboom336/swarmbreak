import json
from pathlib import Path
H=Path(__file__).resolve().parent
a=json.loads((H/'R3-ADDITIONS.json').read_text())
for g in a:
 if '_Join_' in g['name']:g['kitName']='quaternius-nature__Rock_Medium_1'
 if 'Keel_Facet' in g['name']:
  g['s'][0]=6;g['material']='Neon';g['color']=[65,134,157]
 if 'Cascade' in g['name']:g['s'][0]=2;g['s'][2]=3.6
 if 'BackAnchor' in g['name']:g['s']=[8,32,8]
(H/'R4-ADDITIONS.json').write_text(json.dumps(a,indent=2));print('R4 refinements',len(a))
