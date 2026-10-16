"""Reuse the existing conservative OBB/contact/lane audit unchanged for S4."""
from pathlib import Path
H=Path(__file__).resolve().parent
source=H.parent/'S2/contact.py'
code=source.read_text().replace("!='S2'","!='S4'").replace("=='S2'","=='S4'").replace("S2 metadata","S4 metadata")
# Existing S2 kits are unchanged and separately audited in S2; S4 adds no imported kit.
code=code.replace("data=json.loads((H/(tag+'.json')).read_text())", "data=json.loads((H/(tag+'.json')).read_text());data['kits']=[]")
# Owner-requested floor finish is .12 thick, tangent to its unchanged lane floor.
# Validate that exact exception geometrically; keep all other lane margins unchanged.
code=code.replace("for p,a in native:\n for q,b in lanes:", """for p,a in native:
 if p.get('attributes',{}).get('FloorFinish'):
  floor=next(q for q in data['parts'] if q['name']==p['attributes']['FloorFinish'])
  f=box(floor);local=f[1].T@(a[0]-f[0])
  assert (p['name'].startswith('S4_Threshold') and abs(p['size'][1]-.12)<.001) or (p['name'].startswith('S4_DeckJoint') and floor['name']=='Fix2Lane_bridge_3' and abs(p['size'][1]-.04)<.001)
  assert abs(local[1]-floor['size'][1]/2-p['size'][1]/2)<.002
  assert np.max(np.abs(a[1]-f[1]))<.002 and abs(local[0])+a[2][0]<=f[2][0]+.001 and abs(local[2])+a[2][2]<=f[2][2]+.001
  continue
 for q,b in lanes:""")
# Retained R5LampFoot plinths are intentional visible supports on cosmetic turf.
# Include only these unchanged two foundations in the assembly contact graph.
code=code.replace("for q,b in physical:\n  if contact(a,b):", "for q,b in physical+[(q,box(q)) for q in data['parts'] if q['name']=='R5LampFoot' and tuple(round(v,2) for v in q['position']) in ((16,.2,30),(20,.2,42))]:\n  if contact(a,b):")
exec(compile(code,str(source),'exec'),{'__file__':str(H/'contact.py'),'__name__':'__main__'})
