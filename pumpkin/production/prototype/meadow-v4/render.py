"""Offline proof of the actual Roblox parts manifest. No invented scene assets."""
import bpy, json, math, sys, hashlib, os
from pathlib import Path
from mathutils import Matrix, Vector
HERE=Path(__file__).resolve().parent
OUT=HERE.parents[1]/'treasure/map-v4'
round_id=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else '0'
requested_views=set(sys.argv[sys.argv.index('--')+2:]) if '--' in sys.argv else set()
manifest_bytes=(HERE/os.environ.get('LOOK_MANIFEST', 'round5-baseline-scene.json' if round_id.startswith('r5before') else 'scene.json')).read_bytes()
data=json.loads(manifest_bytes)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
B=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
mats={}
def material(rgb,neon,alpha=1):
    key=tuple(rgb)+(neon,alpha)
    if key not in mats:
        m=bpy.data.materials.new(str(key));m.use_nodes=True
        n=m.node_tree.nodes.get('Principled BSDF')
        srgb=tuple(x/255 if max(rgb)>1 else x for x in rgb)
        c=tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in srgb)
        n.inputs['Base Color'].default_value=(*c,1);n.inputs['Roughness'].default_value=.8
        n.inputs['Alpha'].default_value=alpha
        if neon:
            n.inputs['Emission Color'].default_value=(*c,1);n.inputs['Emission Strength'].default_value=1.2
        mats[key]=m
    return mats[key]
# Batch cubes by material; tiny paving bevels stay in the source geometry shape.
groups={}
# Reuse the same native Ball proxy mesh, batching transformed vertices rather
# than invoking Blender's operator/dependency update once per decorative sphere.
bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=1)
ball_template=bpy.context.object
ball_vertices=[v.co.copy() for v in ball_template.data.vertices]
ball_faces=[tuple(f.vertices) for f in ball_template.data.polygons]
bpy.data.objects.remove(ball_template,do_unlink=True)
for p in data['parts']:
    if p.get('transparency',0)>=.99: continue
    color=p['color']; neon=p['material']=='Neon'
    key=tuple(color)+(neon,1-p.get('transparency',0))
    g=groups.setdefault(key,[[],[]])
    pos=p['position'];size=p['size']; r=p.get('rotation',[1,0,0,0,1,0,0,0,1])
    if isinstance(r[0],list):r=sum(r,[])
    R=Matrix((r[0:3],r[3:6],r[6:9])); base=len(g[0])
    if p.get('shape')=='Wedge':
        for x,y,z in [(-1,-1,-1),(1,-1,-1),(-1,-1,1),(1,-1,1),(-1,1,1),(1,1,1)]:
            q=R@Vector((x*size[0]/2,y*size[1]/2,z*size[2]/2))+Vector(pos)
            g[0].append((q.x,-q.z,q.y))
        for f in [(0,2,3,1),(2,4,5,3),(0,1,5,4),(0,4,2),(1,3,5)]:g[1].append(tuple(base+i for i in f))
        continue
    if p.get('shape','Block')!='Block':
        if p['shape']=='Ball':
            for vertex in ball_vertices:
                q=R@Vector(tuple(vertex[i]*size[i]/2 for i in range(3)))+Vector(pos)
                g[0].append((q.x,-q.z,q.y))
            for face in ball_faces:g[1].append(tuple(base+i for i in face))
            continue
        else:
            bpy.ops.mesh.primitive_cylinder_add(vertices=48,radius=1,depth=2)
            o=bpy.context.object;o.rotation_euler=(0,math.pi/2,0)
            bpy.ops.object.transform_apply(rotation=True)
            o.scale=tuple(x/2 for x in size)
        bpy.ops.object.transform_apply(scale=True)
        transform=R.to_4x4();transform.translation=Vector(pos)
        o.matrix_world=B@transform
        o.data.materials.append(material(color,neon,1-p.get('transparency',0)))
        continue
    # Renderer uses the same box shape and rotation, including all ramp tilts.
    for x,y,z in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]:
        q=R@Vector((x*size[0]/2,y*size[1]/2,z*size[2]/2))+Vector(pos)
        g[0].append((q.x,-q.z,q.y))
    for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]:g[1].append(tuple(base+i for i in f))
for key,(v,f) in groups.items():
    mesh=bpy.data.meshes.new('ShippedParts');mesh.from_pydata(v,[],f);mesh.update()
    obj=bpy.data.objects.new('ShippedParts',mesh);bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material(key[:3],key[3],key[4]))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
scene.render.resolution_x=1536;scene.render.resolution_y=1024;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard'
scene.world.use_nodes=True
nodes=scene.world.node_tree.nodes;links=scene.world.node_tree.links
ambient=nodes.get('Background');ambient.inputs[0].default_value=(.55,.68,.88,1);ambient.inputs[1].default_value=.55
sky=nodes.new('ShaderNodeBackground');sky.inputs[0].default_value=(.17,.57,.95,1)
ray=nodes.new('ShaderNodeLightPath');mix=nodes.new('ShaderNodeMixShader')
links.new(ray.outputs['Is Camera Ray'],mix.inputs[0]);links.new(ambient.outputs[0],mix.inputs[1]);links.new(sky.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],nodes['World Output'].inputs[0])
bpy.ops.object.light_add(type='SUN',location=(-100,-160,260));light=bpy.context.object
light.rotation_euler=(.35,-.5,-.35);light.data.energy=1.8;light.data.color=(1,.91,.72);light.data.angle=.12
bpy.ops.object.light_add(type='AREA',location=(0,-120,220));light=bpy.context.object
light.data.energy=140000;light.data.size=230;light.data.color=(1,.94,.8)
light.rotation_euler=(Vector((0,0,0))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam
def render(name,eye,target,scale):
    if requested_views and 'all-views' not in requested_views and name not in requested_views and not ('route-eyes' in requested_views and name.startswith('eye-route-')):return
    cam.location=eye;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=scale;cam.data.clip_end=3000
    if name=='concept' or name.startswith('portal') or name.startswith('summit') or name.startswith('eye-'):
        cam.data.type='PERSP';cam.data.lens=46;cam.data.sensor_width=36
        if name!='concept':cam.data.lens=24 if name.startswith('eye-') else 14
    scene.render.filepath=str(OUT/f'build-r{round_id}-{name}.png');bpy.ops.render.render(write_still=True)
CONCEPT_EYE=(0,-460,220);CONCEPT_TARGET=(0,10,-30)
render('concept',CONCEPT_EYE,CONCEPT_TARGET,535)
render('side',(-390,-245,72),(0,35,-14),490)
if round_id.startswith(('r5','r6')):
    render('under-south',(0,-480,-38),(0,0,-108),540)
    render('under-west',(-490,0,-40),(0,0,-108),540)
    render('under-north',(0,490,-38),(0,0,-108),540)
    render('under-east',(490,0,-40),(0,0,-108),540)
    render('under',(320,-360,-245),(0,0,-105),550)
    # Authored spec coordinates; every camera stands 5.5 studs above its route.
    cameras=[('portal-west',(0,-116,0),(-82,-70,5)),
             ('portal-bridge',(0,-116,0),(0,95,36)),
             ('portal-east',(0,-116,0),(148,-53,24)),
             ('west',(-100,-24,0),(-76,30,5)),
             ('bridge',(0,-48,0),(0,65,10)),
             ('east',(110,-60,20),(110,18,5)),
             ('summit',(8,108,48),(0,-116,11)),
             ('shelf',(104,128,36),(74,128,29)),
             ('recovery',(-22,0,-32),(0,-80,-3))]
    eye_cameras={}
    for name,e,t in cameras:
        eye=(e[0],e[1],e[2]+5.5)
        render('eye-'+name,eye,t,400)
        eye_cameras[name]={'blender_eye':eye,'blender_target':t,'eye_height_studs':5.5,'lens_mm':24}
    if 'route-eyes' in requested_views:
        for name,route in data['routes'].items():
            pts=route['points'];i=min(len(pts)-2,max(0,int((len(pts)-1)*.35)))
            e=pts[i];t=pts[min(len(pts)-1,i+max(1,len(pts)//8))]
            eye=(e[0],e[1],e[2]+5.5);target=(t[0],t[1],t[2]+5.5)
            render('eye-route-'+name,eye,target,400)
            eye_cameras['route-'+name]={'blender_eye':eye,'blender_target':target,'eye_height_studs':5.5,'lens_mm':24}
    (OUT/f'r5-{round_id}-cameras.json').write_text(json.dumps(eye_cameras,indent=2))
if round_id.startswith('rr3'):
    render('portal',(28,-150,18),(0,0,10),410)
    render('summit',(8,99,60),(38,-50,-6),410)
    if round_id in {'rr3d','rr3final','rr4a','rr4b'}:
        render('portal-west',(0,-130,8),(-95,-35,9),410)
        render('portal-east',(0,-130,8),(130,-65,22),410)
        render('summit-east',(8,99,60),(137,-57,22),410)
if round_id.startswith('rr4'):
    render('ridge-jumps',(215,-90,76),(148,-40,20),110)
render('top',(0,0,600),(0,0,0),555)
if round_id.startswith(('rr3','rr4')):
    # Review-only overlay, kept out of every concept/player render and shipped map.
    def trace(name,points,color):
        cu=bpy.data.curves.new(name,'CURVE');cu.dimensions='3D';cu.bevel_depth=.85;cu.bevel_resolution=1
        sp=cu.splines.new('POLY');sp.points.add(len(points)-1)
        for p,q in zip(sp.points,points):p.co=(q[0],q[1],110,1)
        ob=bpy.data.objects.new(name,cu);bpy.context.collection.objects.link(ob);ob.data.materials.append(material(color,True))
    colors={'west':(40,191,255),'bridge':(255,169,25),'east':(255,81,143),'recovery':(197,134,255)}
    groups={'west':['west'],'bridge':['bridge','bridge_south','portal_north'],'east':['east','east_climb','east_descent','jump_access','jump_recovery'],'recovery':[n for n in data['routes'] if 'recovery' in n or 'ravine' in n or 'exit' in n]}
    for kind,names in groups.items():
        for n in names:
            if n in data['routes']:trace(n,data['routes'][n]['points'],colors[kind])
    for n in ['spiral','shelf','shelf_link','fork_link','summit_radial','north_crosslink','south_crosslink']:
        if n in data['routes']:trace(n,data['routes'][n]['points'],(239,239,230))
    def label(text,x,y,color=(250,250,250),size=7):
        bpy.ops.object.text_add(location=(x,y,115));o=bpy.context.object;o.data.body=text;o.data.size=size;o.data.align_x='CENTER';o.data.materials.append(material(color,True))
    label('SUMMIT / ACORN',0,150)
    label('PORTAL',0,-168)
    label('WEST: COVERED',-208,40,colors['west'])
    label('BRIDGE: EXPOSED',0,-55,colors['bridge'],6)
    label('EAST: HIGH RIDGE',206,40,colors['east'])
    label('LONG CLIMB OUT',-205,-45,colors['recovery'],6)
    label('N',0,184,size=9)
    render('top-routes',(0,0,600),(0,0,0),555)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'meadow-v4-proof.blend'))
(OUT/f'render-r{round_id}-metadata.json').write_text(json.dumps({'manifest_sha256':hashlib.sha256(manifest_bytes).hexdigest(),'part_count':len(data['parts']),'source':'Exact native parts manifest including WedgePart supports; sRGB converted to linear. Offline Cycles proxy, not Studio. Generated concept camera has no metadata: reconstruction is approximate.','concept_camera':{'eye':CONCEPT_EYE,'target':CONCEPT_TARGET,'projection':'perspective','lens_mm':46,'sensor_width_mm':36},'side_camera':{'eye':[-390,-245,72],'target':[0,35,-14],'projection':'orthographic','scale':490},'top_camera':{'eye':[0,0,600],'target':[0,0,0],'projection':'orthographic','scale':555}},indent=2))
