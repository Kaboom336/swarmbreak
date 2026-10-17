import json,math
from pathlib import Path
H=Path(__file__).resolve().parent
scope={'__file__':str(H/'select-shell.py')}
exec((H/'select-shell.py').read_text().split('palette=')[0],scope)
hits=scope['hits'];a=json.loads((H/'R2-ADDITIONS.json').read_text());out=[]
for g in a:
 if '_Join_' in g['name']:
  g['kitName']='kenney_nature-kit__rock_largeA'
  g['flip']=int(g['name'].split('_')[-1])%2==0
 if g['name']=='C8_Keel_Point':continue
 if 'Cascade' in g['name']:
  g['s'][0]=.8;g['s'][2]=2
  out.append(g)
  q=dict(g);q['name']+='_cross';q['yaw']=g['yaw']+90;q['sparkle']=False;out.append(q);continue
 if 'BackAnchor' in g['name']:
  # Keep a thin but readable connected crystal silhouette at backdrop scale.
  g['s']=[4,28,4];g['c'][1]+=4
 out.append(g)
# Four downward triangular fins share a single tiny terminal line. Their tops
# are buried in frozen R1 keel mass; no flat landing surface is introduced.
for j in range(4):
 angle=j*90;rad=math.radians(angle)
 g=dict(name=f'C8_Keel_Facet_{j}',c=[4+math.sin(rad)*8,-238,math.cos(rad)*8],s=[.8,27,16],yaw=angle,flip=True,color=[68+j*3,57+j*2,54+j*2],shape='Wedge',role='single terminal taper, crossed native facets')
 if not hits(g):out.append(g)
for g0 in json.loads((H/'r1-plan.json').read_text()):
 if not g0['name'].startswith('C8_Backdrop_')or not g0['name'].endswith('_1'):continue
 x,y,z=g0['c'];g=dict(name=g0['name']+'_Tail',c=[x,y-15,z],s=[g0['s'][0]*.6,30,g0['s'][2]*.6],yaw=0,flip=True,color=[75,64,62],shape='Wedge',kit=True,kitName='kenney_nature-kit__rock_largeA',role='connected descending backdrop rock tail')
 if not hits(g):out.append(g)
assert all(not hits(g) for g in out)
(H/'R3-ADDITIONS.json').write_text(json.dumps(out,indent=2));print('R3 additions',len(out))
