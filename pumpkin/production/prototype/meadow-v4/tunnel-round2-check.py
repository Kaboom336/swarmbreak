"""Bind preservation and roof/skylight geometry to this hill revision."""
import json,hashlib,math,xml.etree.ElementTree as ET
from pathlib import Path
H=Path(__file__).parent;O=H.parents[1]/'treasure/map-v4'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
raw=(H/'scene.json').read_bytes();s=json.loads(raw)
b=json.loads((H/'tunnel-round2-baseline-scene.json').read_text())
assert s['routes']==b['routes'],'route contacts/widths/waypoints changed'
protected=json.loads((O/'TUNNEL-ROUND2-PROTECTED.json').read_text(encoding='utf-16'))
for row in protected:assert sha(Path(row['Path']))==row['Hash'].lower(),row['Path']
def ray(p,x,z):
 r=p['rotation'];o=p['position'];size=p['size'];lo=-1000;hi=1000
 for j in range(3):
  v=r[j]*(x-o[0])+r[3+j]*(-o[1])+r[6+j]*(-z-o[2]);d=r[3+j]
  if abs(d)<1e-9:
   if abs(v)>size[j]/2+.001:return None
  else:
   a=(-size[j]/2-v)/d;c=(size[j]/2-v)/d
   lo=max(lo,min(a,c));hi=min(hi,max(a,c))
   if hi<lo:return None
 return lo,hi
roof=[p for p in s['parts'] if p['collidable'] and p['category'] in {'tunnel_roof','tunnel_hill'}]
holes=[(-76,-18),(-76,-46)]
for x,z in holes:assert not any((h:=ray(p,x,z)) and h[1]>24 for p in roof),'blocked skylight'
gaps=[];samples=0
for name in ['tunnel_trunk','tunnel_south']:
 for a,c in zip(s['routes'][name]['points'],s['routes'][name]['points'][1:]):
  length=math.dist(a,c)
  for i in range(1,int(length)):
   t=i/length;x=a[0]+(c[0]-a[0])*t;z=a[1]+(c[1]-a[1])*t
   if any(abs(x-hx)<6.1 and abs(z-hz)<4.1 for hx,hz in holes):continue
   samples+=1
   if not any((h:=ray(p,x,z)) and h[0]>=24-.01 and h[1]>24 for p in roof):gaps.append([x,z])
assert not gaps,gaps
native=ET.parse(H/'meadow-v4.rbxmx').getroot().find('Item').findall('Item')
assert len(native)==len(s['parts'])
light_checks=0
for p,item in zip(s['parts'],native):
 if p.get('point_light') or p['name']=='TunnelSkylightGlow':
  lamp=item.find("Item[@class='PointLight']")
  assert lamp is not None,p['name']
  value=float(lamp.find("Properties/float[@name='Brightness']").text)
  assert abs(value-p.get('light_brightness',1.5))<1e-6
  light_checks+=1
report={'state':'PASS','scene_sha256':hashlib.sha256(raw).hexdigest(),'routes_byte_data_equal':True,'protected_sources_and_guardian_equal':True,'ceiling_centerline_samples':samples,'unplanned_ceiling_gaps':len(gaps),'open_skylights':holes,'scope':'Native collidable roof/hill OBB rays; visible decoration and continuous Studio physics require separate review.'}
report['native_tunnel_lights_checked']=light_checks
(O/'TUNNEL-ROUND2-CHECK.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
