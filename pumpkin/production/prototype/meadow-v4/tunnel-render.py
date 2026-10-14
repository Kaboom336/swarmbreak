"""Use existing inspected scene renderer; no fabricated geometry in proof shots."""
import sys,runpy,json,hashlib
from pathlib import Path
H=Path(__file__).parent
wanted=set(sys.argv[sys.argv.index('--')+1:]) if '--' in sys.argv else set()
sys.argv=[str(H/'render.py'),'--','tunnel','SKIP']
R=runpy.run_path(str(H/'render.py'))
R['requested_views'].clear()
R['requested_views'].update(wanted)
bpy=R['bpy'];scene=R['scene'];cam=R['cam'];render=R['render']
scene.render.resolution_x=1400;scene.render.resolution_y=950;scene.cycles.samples=20
# Point lights reproduce real authored tunnel lights (emitter exports PointLight children).
for p in R['data']['parts']:
 if (p['category']=='light' or p.get('point_light')) and p['name'].startswith('Tunnel'):
  x,y,z=p['position'];bpy.ops.object.light_add(type='POINT',location=(x,-z,y))
  lamp=bpy.context.object;lamp.data.energy=65*p.get('light_brightness',1.5)/1.5;lamp.data.shadow_soft_size=1.5
  lamp.data.color=tuple(v/255 for v in p['color'])
def proof(name,eye,target,scale):
 world=(eye[0],eye[2],-eye[1]);blockers=[]
 for p in R['data']['parts']:
  if not p['collidable']:continue
  r=p['rotation'];delta=[world[i]-p['position'][i] for i in range(3)]
  local=[sum(r[i*3+j]*delta[i] for i in range(3)) for j in range(3)]
  if all(abs(local[j])<p['size'][j]/2-.01 for j in range(3)):
   if p['shape']!='Wedge' or local[1]/p['size'][1]<=local[2]/p['size'][2]:blockers.append(p['name'])
 assert not blockers,f'{name} camera inside actual solids: {blockers}'
 render(name,eye,target,scale)
proof('eye-tunnel-entrance',(-70,37,7),(-76,2,11),80)
proof('eye-tunnel-inside',(-76,5,7),(-76,-40,8),80)
proof('eye-tunnel-near-exit',(-76,-85,7),(-76,-57,9),80)
proof('eye-tunnel-south-exit',(-56,-106,7),(-60,-82,9),80)
proof('eye-tunnel-from-summit',(-15,95,54),(-76,23,10),120)
render('tunnel-overview',(-215,150,175),(-76,-30,15),225)
scene.render.resolution_x=1400;scene.render.resolution_y=1400
render('tunnel-top',(0,0,500),(0,0,0),390)
(R['OUT']/'TUNNEL-RENDER-METADATA.json').write_text(json.dumps({'manifest_sha256':hashlib.sha256(R['manifest_bytes']).hexdigest(),'part_count':len(R['data']['parts']),'source':'Actual shipped manifest; offline Cycles, source transparency honored; no Studio claim','top_scale':390,'eye_coordinates':'Source X,Z,Y; RGB from native parts','proof_images':['entrance','inside','near-exit','south-exit','from-summit']},indent=2))
print('Tunnel actual manifest renders complete')
