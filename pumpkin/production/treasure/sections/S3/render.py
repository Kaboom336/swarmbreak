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
scope={'__file__':str(source),'__name__':'s3_geometry'}
code=source.read_text().split('scene=bpy.context.scene;')[0]
# Split ceiling batches so only the explicitly labelled overview can hide them.
code=code.replace("key=tuple(color)+(neon,1-p.get('transparency',0))", "cut=p.get('section')!='S3' and p['position'][1]>18 and -110<p['position'][0]<-40 and -40<p['position'][2]<105\n    key=tuple(color)+(neon,1-p.get('transparency',0),cut)")
code=code.replace("obj.data.materials.append(material(key[:3],key[3],key[4]))", "obj.data.materials.append(material(key[:3],key[3],key[4]));obj['cutawayRoof']=key[5]")
exec(compile(code,str(source),'exec'),scope)
data=json.loads((H/(tag+'.json')).read_text())
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=True
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
# Existing SurfaceGui route labels, also present before S3. Local font is an explicit proxy.
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
views=[]
def trailing(name,p,d):
 length=math.hypot(d[0],d[1]);dx,dz=d[0]/length,d[1]/length
 eye=[p[0]-18*dx,7,p[1]-18*dz];target=[p[0]+6*dx,5,p[1]+6*dz]
 views.append(dict(name=name,walking_player=[p[0],3,p[1]],eye=eye,target=target,trail_horizontal_studs=18,lens=24))
trailing('surface-entry',(-90.375,-10.5625),(-9.625,18.5625))
trailing('surface-bend',(-95,46),(8.5625,16.625))
trailing('surface-exit',(-66.8125,92.125),(4.9453125,6.828125))
trailing('entry',(-76,0),(0,1))
trailing('middle',(-76,49),(0,1))
trailing('far',(-61,87),(1,1))
trailing('reverse',(-76,42),(0,-1))
trailing('junction',(-71,72),(.4,1))
views.append(dict(name='overview-cutaway',eye=[-135,116,135],target=[-74,4,36],lens=34,cutaway=True))
(H/'CAMERAS.json').write_text(json.dumps(views,indent=2))
for v in sorted(views,key=lambda v:v['name'].startswith('surface-')):
 if selected and v['name'] not in selected:continue
 for o in bpy.data.objects:
  if o.get('cutawayRoof'):o.hide_render=bool(v.get('cutaway'))
 eye=v['eye'];target=v['target'];cam.location=(eye[0],-eye[2],eye[1]);dest=Vector((target[0],-target[2],target[1]));cam.rotation_euler=(dest-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=v['lens']
 scene.render.filepath=str(H/(tag+'-'+v['name']+'.png'));bpy.ops.render.render(write_still=True)
(H/('RENDER-'+tag+'.json')).write_text(json.dumps(dict(source='Actual native manifest; older kits remain native proxies; offline light approximation; no Studio claim',manifest_parts=len(data['parts']),cutaway='Roof visibility removed ONLY in overview, not gameplay or player views',views=views),indent=2))
