"""Matched offline native scene proofs. Cutaway changes visibility only in that view."""
import bpy,json,os,sys,math
from pathlib import Path
from mathutils import Vector,Matrix
H=Path(__file__).resolve().parent
ROOT=H.parents[2]
tag=sys.argv[sys.argv.index('--')+1]
selected=set(sys.argv[sys.argv.index('--')+2:])
source=ROOT/'prototype/meadow-v4/render.py'
os.environ['LOOK_MANIFEST']=str(H/(tag+'.json'))
scope={'__file__':str(source),'__name__':'s6_geometry'}
code=source.read_text().split('scene=bpy.context.scene;')[0]
# Split ceiling batches so only the explicitly labelled overview can hide them.
code=code.replace("key=tuple(color)+(neon,1-p.get('transparency',0))", "cut=False\n    key=tuple(color)+(neon,1-p.get('transparency',0),cut)")
code=code.replace("obj.data.materials.append(material(key[:3],key[3],key[4]))", "obj.data.materials.append(material(key[:3],key[3],key[4]));obj['cutawayRoof']=key[5]")
exec(compile(code,str(source),'exec'),scope)
data=json.loads((H/(tag+'.json')).read_text())
if (H/(tag+'-kits.json')).exists():
 import importlib.util
 spec=importlib.util.spec_from_file_location('s6_kit_render',H/'kit-render.py');kit_render=importlib.util.module_from_spec(spec);spec.loader.exec_module(kit_render);kit_render.add_kits(tag)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8;scene.cycles.use_denoising=True
scene.render.resolution_x=960;scene.render.resolution_y=540;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard'
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.68,.88,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.55
bpy.ops.object.light_add(type='SUN',location=(-100,-160,260));sun=bpy.context.object;sun.rotation_euler=(.35,-.5,-.35);sun.data.energy=1.8;sun.data.color=(1,.91,.72);sun.data.angle=.12
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam;cam.data.type='PERSP';cam.data.lens=24;cam.data.clip_end=2000
# Same emitter approximation for every revision. Lamps emit without trapping light in their glass.
for key,mat in scope['mats'].items():
 if not key[3]:continue
 nt=mat.node_tree;output=nt.nodes.get('Material Output');surface=output.inputs['Surface'].links[0].from_socket
 path=nt.nodes.new('ShaderNodeLightPath');transparent=nt.nodes.new('ShaderNodeBsdfTransparent');mix=nt.nodes.new('ShaderNodeMixShader')
 nt.links.new(path.outputs['Is Shadow Ray'],mix.inputs[0]);nt.links.new(surface,mix.inputs[1]);nt.links.new(transparent.outputs[0],mix.inputs[2]);nt.links.new(mix.outputs[0],output.inputs['Surface'])
for light in data['lights']:
 spot=light.get('kind')=='SpotLight'
 x,y,z=light['position'];bpy.ops.object.light_add(type='SPOT' if spot else 'POINT',location=(x,-z,y));o=bpy.context.object
 o.data.color=light['color'];o.data.energy=light['brightness']*120;o.data.shadow_soft_size=.6
 if spot:
  d=light['direction'];o.rotation_euler=Vector((d[0],-d[2],d[1])).to_track_quat('-Z','Y').to_euler();o.data.spot_size=math.radians(light['angle']);o.data.spot_blend=.45;o.data.use_custom_distance=True;o.data.cutoff_distance=light['range']
# Existing SurfaceGui route labels, also present before S6. Local font is an explicit proxy.
for p in data['parts']:
 if not p.get('label'):continue
 r=Matrix((p['rotation'][0:3],p['rotation'][3:6],p['rotation'][6:9]));front=p.get('labelFace')=='Front'
 shift=Vector((0,p.get('labelY',0),(-1 if front else 1)*(p['size'][2]/2+.025)))
 center=Vector(p['position'])+r@shift
 bpy.ops.object.text_add(location=(center.x,-center.z,center.y));o=bpy.context.object
 o.data.body=p['label'];o.data.align_x='CENTER';o.data.align_y='CENTER';o.data.size=p.get('labelSize',.8)
 basis=Matrix(((1,0,0),(0,0,-1),(0,1,0)));flip=Matrix(((-1,0,0),(0,1,0),(0,0,-1))) if front else Matrix.Identity(3)
 o.rotation_euler=(basis@r@flip).to_euler();o.data.materials.append(scope['material']([255,239,185],False))
 font=Path('C:/Windows/Fonts/comicbd.ttf')
 if font.exists():o.data.font=bpy.data.fonts.load(str(font))
views=[
 dict(name='entry',eye=[-17.4,5,-62.8],target=[-40,18,-112],lens=24),
 dict(name='mid-up',eye=[-27.5,29,-136.9],target=[23,47,-125],lens=24),
 dict(name='shelf-down',eye=[96,41,-108],target=[121,23,-91],lens=24),
 dict(name='overview',eye=[-155,155,-245],target=[28,24,-105],lens=30)]
(H/'CAMERAS.json').write_text(json.dumps(views,indent=2))
for v in views:
 if selected and v['name'] not in selected:continue
 eye=v['eye'];target=v['target'];cam.location=(eye[0],-eye[2],eye[1]);dest=Vector((target[0],-target[2],target[1]));cam.rotation_euler=(dest-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=v['lens']
 scene.render.filepath=str(H/(tag+'-'+v['name']+'.png'));bpy.ops.render.render(write_still=True)
(H/('RENDER-'+tag+'.json')).write_text(json.dumps(dict(source='Native parts, offline lighting/font proxies; no Studio claim',views=views),indent=2))
