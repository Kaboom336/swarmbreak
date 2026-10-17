"""R3/R4 art audit; original tests/audits remain untouched."""
from pathlib import Path
import json,sys,runpy,numpy as np
H=Path(__file__).resolve().parent
tag=sys.argv[-1]
scope={'__file__':str(H/'audit.py')}
src=(H/'audit.py').read_text().split('lights=[q')[0]
exec(compile(src,str(H/'audit.py'),'exec'),scope)
# All new server details stay outside the full path and pet reserves. Their
# supports may be client-rendered fence caps, absent in native-only R1 audit.
old=scope['old'];new=scope['new'];box=scope['box'];hit=scope['hit']
visual=json.loads((H/(tag+'-visual.json')).read_text())
before=json.loads((H/'r2-visual.json').read_text())
oldclient=[p for p in before['parts'] if p.get('section')=='ClientDecorProxy']
newclient=[p for p in visual['parts'] if p.get('section')=='ClientDecorProxy' and not p['name'].startswith('ClientDecor_S9_')]
assert len(oldclient)==len(newclient)
finishes=0
for a,b in zip(oldclient,newclient):
    aa=dict(a);bb=dict(b)
    for k in ('color','material','transparency'):aa.pop(k,None);bb.pop(k,None)
    assert aa==bb,'client geometry/flags/attributes changed '+a['name']
    if a!=b:finishes+=1
added=scope['added'];clientadded=[p for p in visual['parts'] if p['name'].startswith('ClientDecor_S9_')]
assert all(not(p['collidable'] or p['query'] or p['touch']) for p in clientadded)
physical=scope['physical'];contacts=list(scope['errors'])
for p in clientadded:
    a=box(p)
    for q,b in physical:
        if np.all(np.minimum(a[4],b[4])-np.maximum(a[3],b[3])>.035) and hit(a,b):contacts.append([p['name'],q['name']])
lights=new['lights'] if isinstance(new['lights'],list) else []
assert all(q['brightness']<=1.5 and q['range']<=18 and not q['shadows'] for q in lights)
existing=[box(p)for p in before['parts']if p['transparency']<.99]
alladded=added+clientadded;boxes=[box(p)for p in alladded]
def near(a,b):return np.all(np.minimum(a[4],b[4])-np.maximum(a[3],b[3])>=-.04)
attached={i for i,a in enumerate(boxes)if any(near(a,b)for b in existing)}
edges={i:set()for i in range(len(boxes))}
for i,a in enumerate(boxes):
    for j in range(i):
        if near(a,boxes[j]):edges[i].add(j);edges[j].add(i)
while True:
    grown=attached|{j for i in attached for j in edges[i]}
    if grown==attached:break
    attached=grown
# Portal VFX deliberately occupy the opening; attached to existing glass surface.
unsupported=[alladded[i]['name']for i in range(len(boxes))if i not in attached]
report=dict(original_native_home_exact=True,client_geometry_flags_attributes_exact=True,
    native_cosmetics=len(added),client_cosmetics=len(clientadded),changed_client_finishes=finishes,
    physical_contacts=contacts,path_margin_errors=scope['margins'],bounds_errors=scope['bounds'],
    legal_pet_envelope_errors=scope['placement'],unsupported=unsupported,live_safe_lights=len(lights),tolerance=.035)
(H/('AUDIT-'+tag+'.json')).write_text(json.dumps(report,indent=2))
print(json.dumps(report))
assert not any(report[k]for k in ('physical_contacts','path_margin_errors','bounds_errors','legal_pet_envelope_errors','unsupported'))
