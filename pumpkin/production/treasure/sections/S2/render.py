"""Actual exported native scene + S1's original kits2 FBX. No invented dressing."""
import bpy, json, os, sys, math
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix
H=Path(__file__).resolve().parent
ROOT=H.parents[2]
tag=sys.argv[sys.argv.index('--')+1]
source=ROOT/'prototype/meadow-v4/render.py'
os.environ['LOOK_MANIFEST']=str(H/(tag+'.json'))
scope={'__file__':str(source),'__name__':'s2_geometry'}
native_source=source.read_text().split('scene=bpy.context.scene;')[0]
if tag.startswith('r3-'):
    # Preserve per-lantern identity and wall albedo, including their true occlusion by kit FBX.
    source_data=json.loads((H/(tag+'.json')).read_text())
    lamp_ids={tuple(p['position']):100+i for i,p in enumerate(p for p in source_data['parts'] if p['name']=='S2_LampGlass')}
    scope['lamp_ids']=lamp_ids
    scope['wall_colors']=[(112,105,94),(137,125,107),(95,91,83)]
# Keep material batches separate by shipped part tag for visible-pixel masks.
native_source=native_source.replace("key=tuple(color)+(neon,1-p.get('transparency',0))", "coverage=3 if p.get('section')=='S2' and ('Mine' in p['name'] or 'Lamp' in p['name']) else 1 if p.get('section')=='S2' else 2 if p['name'] in ('PortalStone','CyanPortalField','ContinuousCyanRim','PortalSpiral') else 4 if max(color)>=120 and (max(color)-min(color))/max(color)<=.20 and p['material'] in ('Rock','Slate','Concrete','SmoothPlastic') else 0\n    key=tuple(color)+(neon,1-p.get('transparency',0),coverage)")
native_source=native_source.replace("o.data.materials.append(material(color,neon,1-p.get('transparency',0)))", "o.pass_index=coverage\n        o.data.materials.append(material(color,neon,1-p.get('transparency',0)))")
if tag.startswith('r3-'):
    native_source=native_source.replace('    key=tuple(color)', "    if p['name']=='S2_LampGlass':coverage=lamp_ids[tuple(p['position'])]\n    elif p['name'] in ('TunnelHillEarth','TunnelRockCourse','TunnelInnerRockFacet','SolidMountainStone','R5BoulderFoot') and tuple(round(v) for v in color) in wall_colors:coverage=5+wall_colors.index(tuple(round(v) for v in color))\n    key=tuple(color)")
native_source=native_source.replace("obj.data.materials.append(material(key[:3],key[3],key[4]))", "obj.pass_index=key[5]\n    obj.data.materials.append(material(key[:3],key[3],key[4]))")
exec(compile(native_source,str(source),'exec'),scope)
data=json.loads((H/(tag+'.json')).read_text())
manifest=json.loads((ROOT/'assets/kits2/manifest.json').read_text())
contact=[]
for g in data['kits']:
    entry=next(e for e in manifest['exports'] if e['island']==g.get('island','meadow') and e['pack']+'__'+e['name']==g['name'])
    before=set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(ROOT/entry['output']))
    objects=[o for o in bpy.data.objects if o not in before and o.type=='MESH']
    coords=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)))
    hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
    native=hi-lo
    # Blender Z up; KitLibrary native Roblox Y up. Both normalize bbox base.
    scale=min(g['size'][0]/native.x,g['size'][1]/native.z,g['size'][2]/native.y)
    factors=(g['size'][0]/native.x,g['size'][2]/native.y,g['size'][1]/native.z) if g.get('fit') else (scale,scale,scale)
    base=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    destination=Vector((g['x'],-g['z'],g['y']))
    r=g.get('rotation',[1,0,0,0,1,0,0,0,1]);rotation=Matrix((r[0:3],r[3:6],r[6:9]))
    for o in objects:
        o.pass_index=1
        world=o.matrix_world.copy()
        for v in o.data.vertices:
            relative=world@v.co-base
            fitted=Vector(tuple(relative[i]*factors[i] for i in range(3)))
            roblox=rotation@Vector((fitted.x,fitted.z,-fitted.y))
            v.co=Vector((roblox.x,-roblox.z,roblox.y))+destination
        o.matrix_world.identity()
        # Same authored flat palette texture colours; no Blender import fallback greys.
        record=next((m for m in entry['meshes'] if o.name.startswith(m['mesh'])),None)
        if record:
            o.data.materials.clear();o.data.materials.append(scope['material'](g.get('color',record['colour']),False))
    actual=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    low=min(v.z for v in actual)
    assert abs(low-g['y'])<.002,(g['id'],low,g['y'])
    contact.append({'id':g['id'],'base_error':low-g['y'],'uniform_scale':None if g.get('fit') else scale,'fitted':bool(g.get('fit')),'actual_size_studs':[max(v.x for v in actual)-min(v.x for v in actual),max(v.z for v in actual)-min(v.z for v in actual),max(v.y for v in actual)-min(v.y for v in actual)]})
(H/(tag+'-mesh-contact.json')).write_text(json.dumps(contact,indent=2))
# Real sign metadata, rendered on the +Z face as the shipped SurfaceGui.
for p in data['parts']:
    if p.get('label'):
        rr=Matrix((p['rotation'][0:3],p['rotation'][3:6],p['rotation'][6:9]));basis=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
        center=Vector(p['position'])+rr@Vector((0,0,p['size'][2]/2+.02))
        bpy.ops.object.text_add(location=basis@center)
        o=bpy.context.object;o.data.body=p['label'];o.data.align_x='CENTER';o.data.align_y='CENTER';o.data.size=.8
        o.rotation_euler=(basis@rr).to_euler();o.data.materials.append(scope['material']([255,239,185],False))
        font=Path('C:/Windows/Fonts/comicbd.ttf')
        if font.exists():o.data.font=bpy.data.fonts.load(str(font))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
# PointLight parent parts must not trap their own offline light inside opaque glass.
# Shadow-ray transparency is limited to the lamp cores and destination glow; walls still cast shadows.
for key,mat in scope['mats'].items():
    if tuple(round(v) for v in key[:3]) not in ((255,193,91),(255,221,142)):continue
    nt=mat.node_tree;output=nt.nodes.get('Material Output');surface=output.inputs['Surface'].links[0].from_socket
    path=nt.nodes.new('ShaderNodeLightPath');transparent=nt.nodes.new('ShaderNodeBsdfTransparent');mix=nt.nodes.new('ShaderNodeMixShader')
    nt.links.new(path.outputs['Is Shadow Ray'],mix.inputs[0]);nt.links.new(surface,mix.inputs[1]);nt.links.new(transparent.outputs[0],mix.inputs[2]);nt.links.new(mix.outputs[0],output.inputs['Surface'])
for light in data.get('lights',[]):
    x,y,z=light['position'];bpy.ops.object.light_add(type='POINT',location=(x,-z,y))
    o=bpy.context.object;o.data.color=light['color'];o.data.energy=light['brightness']*120;o.data.shadow_soft_size=.6
# Labelled offline proxy for the two shipped Beam attachment spans. Not baked terrain.
for p in data['parts']:
    if p['name']!='S2_ShaftAnchor':continue
    start=Vector((p['position'][0],-p['position'][2],p['position'][1]));end=start+Vector((2,-4,-3))
    side=Vector((.9,0,0));mesh=bpy.data.meshes.new('S2_BeamEffectProxy')
    mesh.from_pydata([start-side*.05,start+side*.05,end+side,end-side],[],[(0,1,2,3)])
    mat=bpy.data.materials.get('ShaftProxyTransparent')
    if not mat:
        mat=bpy.data.materials.new('ShaftProxyTransparent');mat.use_nodes=True;nt=mat.node_tree;nt.nodes.clear()
        output=nt.nodes.new('ShaderNodeOutputMaterial');mix=nt.nodes.new('ShaderNodeMixShader');mix.inputs[0].default_value=.08
        transparent=nt.nodes.new('ShaderNodeBsdfTransparent');emission=nt.nodes.new('ShaderNodeEmission');emission.inputs[0].default_value=(1,.94,.7,1);emission.inputs[1].default_value=.25
        nt.links.new(transparent.outputs[0],mix.inputs[1]);nt.links.new(emission.outputs[0],mix.inputs[2]);nt.links.new(mix.outputs[0],output.inputs[0])
    mesh.materials.append(mat);o=bpy.data.objects.new('S2_BeamEffectProxy',mesh);scene.collection.objects.link(o)
scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard'
scene.world.use_nodes=True
nodes=scene.world.node_tree.nodes;links=scene.world.node_tree.links
ambient=nodes.get('Background');ambient.inputs[0].default_value=(.55,.68,.88,1);ambient.inputs[1].default_value=.55
sky=nodes.new('ShaderNodeBackground');sky.inputs[0].default_value=(.25,.68,1,1)
ray=nodes.new('ShaderNodeLightPath');mix=nodes.new('ShaderNodeMixShader')
links.new(ray.outputs['Is Camera Ray'],mix.inputs[0]);links.new(ambient.outputs[0],mix.inputs[1]);links.new(sky.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],nodes['World Output'].inputs[0])
bpy.ops.object.light_add(type='SUN',location=(-100,-160,260));sun=bpy.context.object
sun.rotation_euler=(.35,-.5,-.35);sun.data.energy=1.8;sun.data.color=(1,.93,.8);sun.data.angle=.12
# Same labelled existing summit beam proxy in every comparison frame.
for axis in (0,1):
    verts=[]
    for y,w in [(53.3,7.92),(146.9,3.48),(170.3,0)]:
        for sign in [-1,1]:verts.append((sign*w/2 if axis==0 else 0,96+(sign*w/2 if axis==1 else 0),y))
    mesh=bpy.data.meshes.new('ExistingBeamProxy');mesh.from_pydata(verts,[],[(0,1,3,2),(2,3,5,4)])
    mesh.materials.append(scope['material']([255,190,60],True,.34));o=bpy.data.objects.new('ExistingBeamProxy',mesh);scene.collection.objects.link(o)
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam
cam.data.type='PERSP';cam.data.sensor_width=36;cam.data.clip_end=2000
scene.view_layers[0].use_pass_object_index=True
scene.use_nodes=True
tree=scene.node_tree;tree.nodes.clear()
layers=tree.nodes.new('CompositorNodeRLayers')
composite=tree.nodes.new('CompositorNodeComposite');tree.links.new(layers.outputs['Image'],composite.inputs[0])
combine=tree.nodes.new('CompositorNodeCombRGBA')
for idx,channel in [(1,'R'),(2,'G'),(3,'B')]:
    mask=tree.nodes.new('CompositorNodeIDMask');mask.index=idx;mask.use_antialiasing=False
    tree.links.new(layers.outputs['IndexOB'],mask.inputs[0]);tree.links.new(mask.outputs[0],combine.inputs[channel])
out=tree.nodes.new('CompositorNodeOutputFile');out.base_path=str(H);out.format.file_format='PNG';out.format.color_mode='RGBA'
tree.links.new(combine.outputs[0],out.inputs[0])
grey=tree.nodes.new('CompositorNodeIDMask');grey.index=4;grey.use_antialiasing=False
tree.links.new(layers.outputs['IndexOB'],grey.inputs[0])
greyout=tree.nodes.new('CompositorNodeOutputFile');greyout.base_path=str(H);greyout.format.file_format='PNG'
tree.links.new(grey.outputs[0],greyout.inputs[0])
extra_outputs=[]
if tag.startswith('r3-'):
    # Source-colour connected wall masks, and independently visible lantern cores.
    for idx in [5,6,7,*lamp_ids.values()]:
        mask=tree.nodes.new('CompositorNodeIDMask');mask.index=idx
        tree.links.new(layers.outputs['IndexOB'],mask.inputs[0])
        output=tree.nodes.new('CompositorNodeOutputFile');output.base_path=str(H);output.format.file_format='PNG'
        tree.links.new(mask.outputs[0],output.inputs[0]);extra_outputs.append((idx,output))
    # Core pixels still belong to S2 coverage; a maximum combines their masks with the blue frame mask.
    frame_socket=combine.inputs['B'].links[0].from_socket
    for idx,output in extra_outputs:
        if idx<100:continue
        maximum=tree.nodes.new('CompositorNodeMath');maximum.operation='MAXIMUM'
        tree.links.new(frame_socket,maximum.inputs[0]);tree.links.new(output.inputs[0].links[0].from_socket,maximum.inputs[1]);frame_socket=maximum.outputs[0]
    tree.links.new(frame_socket,combine.inputs['B'])
coverage_path=H/(tag+'-coverage.json')
coverage=json.loads(coverage_path.read_text()) if coverage_path.exists() else {}
selected=set(sys.argv[sys.argv.index('--')+2:])
for name,eye,target,lens in [('walk',(-35,-130,7),(-68,-92,5),24),('mouth',(-53,-115,6),(-69,-86,6),24),('overview',(-5,-170,90),(-70,-90,10),28)]:
    if selected and name not in selected:continue
    cam.location=eye;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens
    out.file_slots[0].path=tag+'-'+name+'-mask-'
    greyout.file_slots[0].path=tag+'-'+name+'-grey-'
    for idx,output in extra_outputs:output.file_slots[0].path=tag+'-'+name+'-id'+str(idx)+'-'
    scene.render.filepath=str(H/(tag+'-'+name+'.png'));bpy.ops.render.render(write_still=True)
    im=bpy.data.images.load(str(H/(tag+'-'+name+'-mask-0001.png')),check_existing=False)
    px=np.array(im.pixels[:]).reshape(720,1280,4);props=(px[:,:,0]>.5)|(px[:,:,2]>.5);frame=px[:,:,2]>.5
    columns=np.where(frame.any(axis=0))[0]
    coverage[name]={'S2_visible_percent':float(props.mean()*100),'timber_lantern_percent':float(frame.mean()*100),'timber_lantern_horizontal_span_percent':float((columns[-1]-columns[0]+1)/1280*100) if len(columns) else 0}
    greyim=bpy.data.images.load(str(H/(tag+'-'+name+'-grey-0001.png')),check_existing=False)
    greypx=np.array(greyim.pixels[:]).reshape(720,1280,4)
    coverage[name]['pale_grey_albedo_visible_percent']=float((greypx[:,:,0]>.5).mean()*100)
    (H/(tag+'-coverage.json')).write_text(json.dumps(coverage,indent=2))

