import bpy,json,sys,os,math
from pathlib import Path
from mathutils import Vector,Matrix
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
tag=sys.argv[sys.argv.index('--')+1]
os.environ['LOOK_MANIFEST']=str(H/(tag+'-visual.json'))
source=ROOT/'prototype/meadow-v4/render.py';scope={'__file__':str(source),'__name__':'s9_geometry'}
exec(compile(source.read_text().split('scene=bpy.context.scene;')[0],str(source),'exec'),scope)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=True
scene.render.resolution_x=960;scene.render.resolution_y=540;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard'
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.68,.88,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
bpy.ops.object.light_add(type='SUN',location=(-100,-160,260));sun=bpy.context.object;sun.rotation_euler=(.35,-.5,-.35);sun.data.energy=1.8;sun.data.color=(1,.91,.72);sun.data.angle=.12
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam;cam.data.type='PERSP';cam.data.clip_end=2000
views=[dict(name='spawn',eye=[0,6,16],target=[-48,3,32],lens=22),dict(name='pen',eye=[-25,9,46],target=[-61,5,32],lens=24),dict(name='path',eye=[0,6,68],target=[0,9,-95],lens=19),dict(name='overview',eye=[175,180,205],target=[0,0,5],lens=24)]
(H/'CAMERAS.json').write_text(json.dumps(dict(home_world_offset=[0,0,0],coordinate_system='home-local equals world; no Meadow offset',views=views),indent=2))
data=json.loads((H/(tag+'-visual.json')).read_text())
for p in data['parts']:
 if not p.get('label'):continue
 front=p.get('labelFace')!='Back'
 r=Matrix((p['rotation'][0:3],p['rotation'][3:6],p['rotation'][6:9]));v=Vector(p['position'])+r@Vector((0,0,(-1 if front else 1)*(p['size'][2]/2+.025)))
 bpy.ops.object.text_add(location=(v.x,-v.z,v.y));o=bpy.context.object;o.data.body='>  '+p['label'];o.data.align_x='CENTER';o.data.align_y='CENTER';o.data.size=64/48
 font=Path('C:/Windows/Fonts/comicbd.ttf')
 if font.exists():o.data.font=bpy.data.fonts.load(str(font))
 basis=Matrix(((1,0,0),(0,0,-1),(0,1,0)));flip=Matrix(((-1,0,0),(0,1,0),(0,0,-1)))if front else Matrix.Identity(3)
 o.rotation_euler=(basis@r@flip).to_euler();o.data.materials.append(scope['material']([255,239,185],False))
for v in views:
 eye=v['eye'];t=v['target'];cam.location=(eye[0],-eye[2],eye[1]);dest=Vector((t[0],-t[2],t[1]));cam.rotation_euler=(dest-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=v['lens']
 scene.render.filepath=str(H/(tag+'-'+v['name']+'.png'));bpy.ops.render.render(write_still=True)
