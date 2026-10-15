"""Reuse inspected native-part renderer. All visual geometry is shipped;
only coloured top-plan lines are review overlays. Not a Studio screenshot."""
from pathlib import Path
source=Path(__file__).parents[1]/'meadow-v4/render.py'
text=source.read_text(encoding='utf8')
text=text[:text.index('CONCEPT_EYE=')]
text=text.replace("OUT=HERE.parents[1]/'treasure/map-v4'",'OUT=HERE')
text=text.replace('scene.cycles.samples=16','scene.cycles.samples=12')
text=text.replace('scene.render.resolution_x=1536;scene.render.resolution_y=1024','scene.render.resolution_x=1200;scene.render.resolution_y=800')
text=text.replace("ambient.inputs[0].default_value=(.55,.68,.88,1);ambient.inputs[1].default_value=.55", "ambient.inputs[0].default_value=(.48,.56,.73,1);ambient.inputs[1].default_value=.8")
text=text.replace("sky.inputs[0].default_value=(.17,.57,.95,1)","sky.inputs[0].default_value=(.08,.13,.24,1)")
text=text.replace('light.data.color=(1,.91,.72)','light.data.color=(.73,.83,1)')
text=text.replace("light.data.energy=140000;light.data.size=230;light.data.color=(1,.94,.8)","light.data.energy=75000;light.data.size=230;light.data.color=(.71,.81,1)")
text=text.replace("bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam",'''for item in data.get('lights',[]):
    p=item['position'];bpy.ops.object.light_add(type='POINT',location=(p[0],-p[2],p[1]))
    ob=bpy.context.object;ob.data.energy=item['brightness']*item['range']**2*7
    ob.data.color=tuple(v/255 for v in item['color']);ob.data.shadow_soft_size=1
scene.view_settings.exposure=.25
scene.use_nodes=True;nt=scene.node_tree;nt.nodes.clear()
layers=nt.nodes.new('CompositorNodeRLayers');glare=nt.nodes.new('CompositorNodeGlare')
glare.glare_type='FOG_GLOW';glare.threshold=1.2;glare.mix=-.8
output=nt.nodes.new('CompositorNodeComposite');nt.links.new(layers.outputs['Image'],glare.inputs['Image']);nt.links.new(glare.outputs['Image'],output.inputs['Image'])
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam''')
text=text[:text.index('def render(')]
exec(compile(text,str(source),'exec'))
# Approximate native SurfaceGui text from the shipped label and panel frame.
for label in data.get('labels',[]):
    p=data['parts'][label['partIndex']-1];r=p['rotation'];R=Matrix((r[0:3],r[3:6],r[6:9]))
    transform=R.to_4x4();transform.translation=Vector(p['position'])
    if label['face']=='Front':
        transform=transform@Matrix.Rotation(math.pi,4,'Y')
    transform.translation+=transform.to_3x3()@Vector((0,0,p['size'][2]/2+.06))
    bpy.ops.object.text_add();o=bpy.context.object;o.data.body=label['text'];o.data.align_x='CENTER';o.data.align_y='CENTER'
    o.data.size=min(2.1,p['size'][0]/max(1,len(label['text']))*1.5)
    o.matrix_world=B@transform;o.data.materials.append(material(label['color'],False))
cameras={}
def render(name,eye,target,lens=24,ortho=None):
    if requested_views and name not in requested_views:return
    cam.location=eye;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO' if ortho else 'PERSP';cam.data.lens=lens;cam.data.sensor_width=36;cam.data.clip_end=3000
    if ortho:cam.data.ortho_scale=ortho
    cameras[name]={'eye':eye,'target':target,'lens_mm':lens,'ortho_scale':ortho,'coordinates':'Blender x, authored z, elevation'}
    scene.render.filepath=str(OUT/f'readable-{round_id}-{name}.png');bpy.ops.render.render(write_still=True)
render('portal',(-144,-171,18),(-90,-54,32),18)
render('main-eye',(-150,-103,5.5),(-150,-60,9),22)
render('cart-eye',(-126,-99,5.5),(-85,-71,16),22)
render('cave-eye',(-121,-120,5.5),(-80,-110,6),22)
render('far',(-620,-750,350),(0,0,-35),46)
render('top',(0,0,800),(0,0,0),ortho=640)
if not requested_views or 'top-routes' in requested_views:
    def trace(name,pts,col):
        cu=bpy.data.curves.new(name,'CURVE');cu.dimensions='3D';cu.bevel_depth=1.2;cu.bevel_resolution=1
        sp=cu.splines.new('POLY');sp.points.add(len(pts)-1)
        for p,q in zip(sp.points,pts):p.co=(q[0],q[1],240,1)
        ob=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(ob);ob.data.materials.append(material(col,True))
    for name,col in [('main',(68,230,99)),('cartRail',(255,210,45)),('cave',(45,220,245))]:trace(name,data['routes'][name]['points'],col)
    render('top-routes',(0,0,800),(0,0,0),ortho=640)
(OUT/f'readable-{round_id}-cameras.json').write_text(json.dumps({'manifest_sha256':hashlib.sha256(manifest_bytes).hexdigest(),'views':cameras,'source':'Native-part offline Cycles proof; lighting approximate; top-routes lines review-only'},indent=2))
