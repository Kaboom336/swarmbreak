"""Canonical native geometry and actual licensed rock FBX, matched player cameras.
Offline lighting/kit proxy only. Does not open Studio or change the place.
"""
import bpy,json,os,sys,math
from pathlib import Path
from mathutils import Matrix,Vector
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
tag=sys.argv[sys.argv.index('--')+1]
source=ROOT/'prototype/meadow-v4/render.py'
os.environ['LOOK_MANIFEST']=str(H/(tag+'.json'))
scope={'__file__':str(source),'__name__':'c5_geometry'}
exec(compile(source.read_text().split('scene=bpy.context.scene;')[0],str(source),'exec'),scope)
data=json.loads((H/(tag+'.json')).read_text())
if tag!='before':
 # Hide wedge fallback proxies and render the actual source FBX in the same
 # envelope used by Kit.fit. No invented rock triangles.
 filtered=dict(data);filtered['parts']=[p for p in data['parts']if not p.get('c5fallback')]
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 scope['data']=filtered
 geometry=source.read_text();start=geometry.index('groups={}')
 end=geometry.index('scene=bpy.context.scene;')
 exec(compile(geometry[start:end],str(source),'exec'),scope)
 before=set(bpy.data.objects)
 bpy.ops.import_scene.fbx(filepath=str(ROOT/'assets/kits2/cave/quaternius-nature__Rock_Medium_1__cave.fbx'))
 objects=[o for o in bpy.data.objects if o not in before];mesh=[o for o in objects if o.type=='MESH'][0]
 pts=[mesh.matrix_world@v.co for v in mesh.data.vertices]
 lo=Vector(tuple(min(v[i]for v in pts)for i in range(3)));hi=Vector(tuple(max(v[i]for v in pts)for i in range(3)))
 normalized=[Vector(((v.x-lo.x)/(hi.x-lo.x)-.5,(v.z-lo.z)/(hi.z-lo.z)-.5,-(v.y-lo.y)/(hi.y-lo.y)+.5))for v in pts]
 faces=[tuple(f.vertices)for f in mesh.data.polygons]
 for o in objects:bpy.data.objects.remove(o,do_unlink=True)
 for g in json.loads((H/(tag+'-plan.json')).read_text()):
  if not g.get('kit'):continue
  r=Matrix.Rotation(math.radians(g.get('yaw',0)),3,'Y');vs=[]
  for v in normalized:
   q=r@Vector(tuple(v[i]*g['s'][i]for i in range(3)))+Vector(g['c']);vs.append((q.x,-q.z,q.y))
  m=bpy.data.meshes.new(g['name']);m.from_pydata(vs,[],faces);m.update();o=bpy.data.objects.new(g['name'],m);bpy.context.collection.objects.link(o);m.materials.append(scope['material'](g['color'],False))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=True
# Existing saved text faces in every state; reverse faces only after actual C5
# module installs them. Fredoka rasterization is an explicit offline font proxy.
axis=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
for p in data['parts']:
 for face in p.get('textFaces',[]):
  if face['face'] not in ('Front','Back'):continue
  r=Matrix([p['rotation'][i:i+3]for i in (0,3,6)])
  normal=r@Vector((0,0,-1 if face['face']=='Front'else 1));up=r@Vector((0,1,0));right=up.cross(normal)
  pos=Vector(p['position'])+normal*(p['size'][2]/2+.035)
  bpy.ops.object.text_add(location=axis@pos);o=bpy.context.object;o.name='ACTUAL TEXT FACE PROXY'
  o.data.body=face['text'];o.data.align_x='CENTER';o.data.align_y='CENTER'
  o.data.size=min(p['size'][1]*.65,p['size'][0]/max(len(face['text'])*.6,1))
  o.rotation_euler=(axis@Matrix((right,up,normal)).transposed()).to_euler();o.data.materials.append(scope['material']([255,235,177],False))
if tag!='before':
 for g in json.loads((H/(tag+'-plan.json')).read_text()):
  if not g.get('text'):continue
  # Explicit lettering proxy; the place uses shared FredokaOne SurfaceGui.
  x,y,z=g['c'];yaw=math.radians(g.get('yaw',0))
  for side in (-1,1):
   bpy.ops.object.text_add(location=(x+side*math.sin(yaw)*.56,-z-side*math.cos(yaw)*.56,y))
   o=bpy.context.object;o.name='SIGN LETTERING PROXY';o.data.body=g['text'];o.data.align_x='CENTER';o.data.align_y='CENTER';o.data.size=g['s'][0]*.28
   o.rotation_euler=(math.pi/2,0,yaw+(math.pi if side==-1 else 0));o.data.extrude=.015;o.data.materials.append(scope['material']([255,236,180],False))
scene.render.resolution_x=960;scene.render.resolution_y=540;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard'
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.35,.43,.65,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
bpy.ops.object.light_add(type='SUN');sun=bpy.context.object;sun.rotation_euler=(.35,-.5,-.35);sun.data.energy=1.5;sun.data.color=(.73,.83,1)
for light in data['lights']:
 x,y,z=light['position'];bpy.ops.object.light_add(type='POINT',location=(x,-z,y));o=bpy.context.object;o.data.energy=light['brightness']*90;o.data.color=light['color'];o.data.shadow_soft_size=.6
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam;cam.data.type='PERSP';cam.data.clip_end=2000;cam.data.lens=24
views=json.loads((H/'CAMERAS.json').read_text())['views']
for v in views:
 if len(sys.argv[sys.argv.index('--')+2:]) and v['name'] not in sys.argv[sys.argv.index('--')+2:]:continue
 eye=v['eye'];t=v['target'];cam.location=(eye[0],-eye[2],eye[1]);cam.rotation_euler=(Vector((t[0],-t[2],t[1]))-cam.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(H/(tag+'-'+v['name']+'.png'));bpy.ops.render.render(write_still=True)
