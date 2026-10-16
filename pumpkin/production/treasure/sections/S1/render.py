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
scope={'__file__':str(source),'__name__':'s1_geometry'}
native_source=source.read_text().split('scene=bpy.context.scene;')[0]
# Keep material batches separate by shipped part tag for visible-pixel masks.
native_source=native_source.replace("key=tuple(color)+(neon,1-p.get('transparency',0))", "coverage=1 if (p.get('coverage')=='Props' or p.get('section')=='S1') and 'Sign' not in p['name'] else 2 if p.get('coverage')=='Portal' or p['name'] in ('PortalStone','CyanPortalField','ContinuousCyanRim','PortalSpiral') else 0\n    key=tuple(color)+(neon,1-p.get('transparency',0),coverage)")
native_source=native_source.replace("o.data.materials.append(material(color,neon,1-p.get('transparency',0)))", "o.pass_index=coverage\n        o.data.materials.append(material(color,neon,1-p.get('transparency',0)))")
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
            o.data.materials.clear();o.data.materials.append(scope['material'](record['colour'],False))
    actual=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
    low=min(v.z for v in actual)
    assert abs(low-g['y'])<.002,(g['id'],low,g['y'])
    contact.append({'id':g['id'],'base_error':low-g['y'],'uniform_scale':None if g.get('fit') else scale,'fitted':bool(g.get('fit')),'actual_size_studs':[max(v.x for v in actual)-min(v.x for v in actual),max(v.z for v in actual)-min(v.z for v in actual),max(v.y for v in actual)-min(v.y for v in actual)]})
(H/(tag+'-mesh-contact.json')).write_text(json.dumps(contact,indent=2))
# Real sign metadata, rendered on the +Z face as the shipped SurfaceGui.
for p in data['parts']:
    if p.get('label'):
        bpy.ops.object.text_add(location=(p['position'][0],-p['position'][2]-.23,p['position'][1]))
        o=bpy.context.object;o.data.body=p['label'];o.data.align_x='CENTER';o.data.align_y='CENTER';o.data.size=.8
        o.rotation_euler=(math.pi/2,0,0);o.data.materials.append(scope['material']([255,239,185],False))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
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
for idx,channel in [(1,'R'),(2,'G')]:
    mask=tree.nodes.new('CompositorNodeIDMask');mask.index=idx;mask.use_antialiasing=False
    tree.links.new(layers.outputs['IndexOB'],mask.inputs[0]);tree.links.new(mask.outputs[0],combine.inputs[channel])
out=tree.nodes.new('CompositorNodeOutputFile');out.base_path=str(H);out.format.file_format='PNG';out.format.color_mode='RGBA'
tree.links.new(combine.outputs[0],out.inputs[0])
for name,eye,target,lens in [('arrival',(0,-154,5.5),(0,96,24),24),('overview',(92,-205,88),(0,-122,4),35)]:
    cam.location=eye;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=lens
    out.file_slots[0].path=tag+'-'+name+'-mask-'
    scene.render.filepath=str(H/(tag+'-'+name+'.png'));bpy.ops.render.render(write_still=True)
    if name=='arrival':
        mask_path=H/(tag+'-'+name+'-mask-0001.png')
        mask_image=bpy.data.images.load(str(mask_path),check_existing=False)
        pixels=np.array(mask_image.pixels[:]).reshape(720,1280,4)
        props=pixels[:,:,0]>.5;portal=pixels[:,:,1]>.5
        ll=float(props[:240,:426].mean()*100);rr=float(props[:240,854:].mean()*100)
        result={'lower_left_pct':ll,'lower_right_pct':rr,'portal_frame_pct':float(portal.mean()*100),
                'roi':'bottom third of image height, outer thirds of width; visible first-hit object-index mask',
                'goal_each_pct':25,'passed':ll>=25 and rr>=25,'camera_roblox':[0,5.5,154],'lens_mm':24,
                'evidence':'offline native geometry + source FBX; live Studio appearance UNKNOWN'}
        (H/(tag+'-coverage.json')).write_text(json.dumps(result,indent=2))
        print('COVERAGE lower-left: %.2f%% / 25%%'%ll,flush=True)
        print('COVERAGE lower-right: %.2f%% / 25%%'%rr,flush=True)
        print('COVERAGE portal: %.2f%% of frame'%result['portal_frame_pct'],flush=True)
