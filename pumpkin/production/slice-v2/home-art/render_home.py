"""Render the same native scene and mesh payload shipped to the client.
Camera uses Scene.captureCams HomeReferenceCamera. Reward pets are staged.
"""
import bpy, json, math, sys
from pathlib import Path
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[2]; HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'models/golden-acorn/blender'))
import artlib as a
assets=json.loads((HERE/'assets.json').read_text())
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def material(rgb,neon=False):
    m=bpy.data.materials.new('HomePalette'); m.use_nodes=True
    rgb=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*rgb,1)
    p.inputs['Roughness'].default_value=.7
    if neon: p.inputs['Emission Color'].default_value=(*rgb,1);p.inputs['Emission Strength'].default_value=2
    return m
def basis(v): return (v[0],-v[2],v[1])
# Roblox -> Blender proper rotation, preserving triangle winding.
B=Matrix(((1,0,0,0),(0,0,-1,0),(0,1,0,0),(0,0,0,1)))
for part in json.loads((HERE/'native-home.json').read_text()):
    if part['name'].startswith('Pen') and ('Rail' in part['name'] or part['name']=='PenPost'): continue
    if part['name'] in ['CentralStonePath','CyanPortalDisc','LockedPortalDisc','PortalFoot','LockedPortalTerrace','TerraceLanding','LanternPost','LanternCap','LanternLight','PenAccessPath']: continue
    if part['name'].startswith(('PortalArchStone','TerraceStep')): continue
    size=part['size']
    if part['shape']=='Cylinder':
        bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=1,depth=2)
        o=bpy.context.object
        # Roblox cylinder length is X, radius spans YZ.
        o.rotation_euler=(0,math.pi/2,0); bpy.ops.object.transform_apply(rotation=True)
        o.scale=(size[0]/2,size[1]/2,size[2]/2)
    else:
        bpy.ops.mesh.primitive_cube_add(size=1);o=bpy.context.object;o.scale=size
    bpy.ops.object.transform_apply(scale=True)
    cf=part['cf'];R=Matrix(((cf[3],cf[4],cf[5],cf[0]),(cf[6],cf[7],cf[8],cf[1]),(cf[9],cf[10],cf[11],cf[2]),(0,0,0,1)))
    o.matrix_world=B@R; o.name=part['name'];o.data.materials.append(material(part['color'],part['neon']))
def mesh_asset(key,position=(0,0,0),scale=1):
    for section in assets[key]:
        vs=[basis([p[i]*scale+position[i] for i in range(3)]) for p in section['vertices']]
        me=bpy.data.meshes.new(key);me.from_pydata(vs,[],section['triangles']);me.update()
        o=bpy.data.objects.new(key,me);bpy.context.collection.objects.link(o)
        o.data.materials.append(material([c/255 for c in section['color']],section['name'] in ['PortalLight','PortalGreen','LampLight','Lava','Cyan']))
mesh_asset('Decor')
# Staged legal placements; no live pet ownership or Studio results are claimed.
for slot in [2,3,4,6,7,8]:
    x=-52 if slot<=4 else 52;z=96-(slot-1)%4*64
    y=((slot-1)%4)*3.5
    mesh_asset('Pup' if slot%2 else 'Crow',(x+8,y+.45,z+10),3.4)
    bpy.ops.mesh.primitive_cube_add(size=1,location=basis((x+8,y+.35,z+10)))
    o=bpy.context.object;o.scale=(5,5,.2);o.data.materials.append(material([103/255,119/255,130/255]))
s=bpy.context.scene;s.render.engine='BLENDER_EEVEE_NEXT';s.eevee.taa_render_samples=32
s.render.resolution_x=1672;s.render.resolution_y=941;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.view_settings.view_transform='Standard'
# Separate visible sky from neutral diffuse fill, approximating Future skylight.
s.world.use_nodes=True;wn=s.world.node_tree.nodes;wl=s.world.node_tree.links
ambient=wn['Background'];ambient.inputs[0].default_value=(.65,.70,.80,1);ambient.inputs[1].default_value=.45
sky=wn.new('ShaderNodeBackground');sky.inputs[0].default_value=(.06,.45,.95,1);sky.inputs[1].default_value=1
ray=wn.new('ShaderNodeLightPath');mix=wn.new('ShaderNodeMixShader')
wl.new(ray.outputs['Is Camera Ray'],mix.inputs[0]);wl.new(ambient.outputs[0],mix.inputs[1]);wl.new(sky.outputs[0],mix.inputs[2]);wl.new(mix.outputs[0],wn['World Output'].inputs['Surface'])
bpy.ops.object.light_add(type='SUN',location=(-80,-80,150)); sun=bpy.context.object
sun.rotation_euler=(.3,-.5,-.5);sun.data.energy=3;sun.data.angle=.10
sun.data.color=(1,.94,.84)
bpy.ops.object.light_add(type='AREA',location=(0,-40,180));light=bpy.context.object
light.data.energy=140000;light.data.size=180;light.data.color=(1,.96,.89);a.aim(light,(0,0,0))
# Physical diffuse/contact shadows are an offline proxy, not a Studio parity claim.
s.render.engine='CYCLES';s.cycles.samples=32;s.cycles.use_denoising=True
s.use_nodes=True
cn=s.node_tree.nodes;cl=s.node_tree.links;cn.clear()
rl=cn.new('CompositorNodeRLayers');sat=cn.new('CompositorNodeHueSat');sat.inputs['Saturation'].default_value=1.18
out=cn.new('CompositorNodeComposite');cl.new(rl.outputs['Image'],sat.inputs['Image']);cl.new(sat.outputs['Image'],out.inputs['Image'])
bpy.ops.object.camera_add(location=basis((0,150,260)));cam=bpy.context.object
a.aim(cam,basis((0,4,0)));cam.data.type='PERSP';cam.data.sensor_fit='VERTICAL'
cam.data.sensor_height=24;cam.data.lens=24/(2*math.tan(math.radians(40)/2));s.camera=cam
def label(text,xyz,size,color=(1,1,1)):
    bpy.ops.object.text_add(location=basis(xyz));o=bpy.context.object
    o.data.body=text;o.data.align_x='CENTER';o.data.align_y='CENTER';o.data.size=size
    o.rotation_euler=cam.rotation_euler
    o.data.materials.append(material(color,True))
for i,name in enumerate(['Crystal Cave','Frost Peak','Volcano','Ocean']):
    label(name,(-66+i*44,36,-143),2.5)
for slot in [2,3,4,6,7,8]:
    x=-52 if slot<=4 else 52;z=96-(slot-1)%4*64
    kind='Pup' if slot%2 else 'Crow'
    y=((slot-1)%4)*3.5
    label(kind,(x+8,y+19,z+10),3.1)
    label('Common' if kind=='Pup' else 'Rare',(x+8,y+16,z+10),2.8,(.65,1,.40) if kind=='Pup' else (.26,.91,1))
    label('+— coins/s',(x+8,y+13,z+10),2.6,(.65,1,.4))
tag=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'final'
s.render.filepath=str(ROOT/f'slice-v2/evidence/home-art-{tag}.png')
bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(HERE/'home-art.blend'))
