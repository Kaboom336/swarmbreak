from pathlib import Path
import json,bpy,numpy as np
H=Path(__file__).resolve().parent
src=(H/'r3-measure.py').read_text().replace("'r3-after'","'r4-after'").replace("'METRICS-R3.json'","'METRICS-R4.json'")
exec(compile(src,str(H/'r3-measure.py'),'exec'))
p=H/'METRICS-R4.json';out=json.loads(p.read_text())
sky=mask(H/(tag+'-walk-sky-0001.png'))
out['walk_sky_percent']=float(sky.mean()*100)
out['sky_definition']='Full-frame primary-camera background pixels, measured from render Depth >2000 studs; geometry occlusion includes original FBX. Locked WALK camera.'
out['goals']['walk_sky_ge8']=out['walk_sky_percent']>=8
bevels=[p for p in data['parts'] if p['name']=='S2_MineArchBevel']
out['arch_bevels']=bevels
out['goals']['arched_beveled_opening']=len(bevels)==2 and all(p['shape']=='Wedge' for p in bevels)
p.write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
