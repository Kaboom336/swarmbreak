"""Matched production native-block proxy. Never claims to reproduce Studio effects/kits."""
import bpy, json, os, sys, math
from pathlib import Path
from mathutils import Vector
H=Path(__file__).resolve().parent
ROOT=H.parents[1]
tag=sys.argv[sys.argv.index('--')+1]
# Reuse the existing exact part renderer; stop before its scene/output code.
source=ROOT/'prototype/meadow-v4/render.py'
os.environ['LOOK_MANIFEST']=str(H/f'polish-{tag}.json')
scope={'__file__':str(source),'__name__':'polish_geometry'}
exec(compile(source.read_text().split('scene=bpy.context.scene;')[0],str(source),'exec'),scope)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=True
scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard'
scene.world.use_nodes=True
nodes=scene.world.node_tree.nodes;links=scene.world.node_tree.links
ambient=nodes.get('Background');ambient.inputs[0].default_value=(.55,.68,.88,1);ambient.inputs[1].default_value=.55
sky=nodes.new('ShaderNodeBackground');sky.inputs[0].default_value=(.25,.68,1,1) if tag=='after' else (.17,.57,.95,1)
ray=nodes.new('ShaderNodeLightPath');mix=nodes.new('ShaderNodeMixShader')
links.new(ray.outputs['Is Camera Ray'],mix.inputs[0]);links.new(ambient.outputs[0],mix.inputs[1]);links.new(sky.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],nodes['World Output'].inputs[0])
# Identical offline lighting in both columns: palette/scale/space can be judged fairly.
# Roblox ColorCorrection/Atmosphere/Highlight/particles are deliberately not simulated.
bpy.ops.object.light_add(type='SUN',location=(-100,-160,260));sun=bpy.context.object
sun.rotation_euler=(.35,-.5,-.35);sun.data.energy=1.8;sun.data.color=(1,.93,.8);sun.data.angle=.12
bpy.ops.object.camera_add();cam=bpy.context.object;scene.camera=cam
cam.data.type='PERSP';cam.data.lens=24;cam.data.sensor_width=36;cam.data.clip_end=2000
if tag=='after':
    # Crossed billboard-free proxy of the shipped FaceCamera beam's endpoint/widths.
    # Coordinate conversion Roblox (x,y,z) -> Blender (x,-z,y).
    material=bpy.data.materials.new('Beacon proxy');material.use_nodes=True
    n=material.node_tree.nodes;n.clear();out=n.new('ShaderNodeOutputMaterial')
    # Tonemapped proxy only: two crossed planes share the single Roblox beam's opacity.
    emission=n.new('ShaderNodeEmission');emission.inputs[0].default_value=(1,.67,.18,1);emission.inputs[1].default_value=1.2
    transparent=n.new('ShaderNodeBsdfTransparent');blend=n.new('ShaderNodeMixShader');blend.inputs[0].default_value=.34
    material.node_tree.links.new(transparent.outputs[0],blend.inputs[1]);material.node_tree.links.new(emission.outputs[0],blend.inputs[2]);material.node_tree.links.new(blend.outputs[0],out.inputs[0])
    for axis in (0,1):
        verts=[]
        for y,w in [(53.3,4.4*1.8),(146.9,3.48),(170.3,0)]:
            for sign in [-1,1]:verts.append((sign*w/2 if axis==0 else 0,96+(sign*w/2 if axis==1 else 0),y))
        mesh=bpy.data.meshes.new('Beam proxy');mesh.from_pydata(verts,[],[(0,1,3,2),(2,3,5,4)]);mesh.materials.append(material)
        obj=bpy.data.objects.new('Beam proxy',mesh);scene.collection.objects.link(obj)
for name,eye,target in [('portal',(0,-116,5.5),(0,96,64)),('camp',(19,70,62),(-2,99,53))]:
    cam.location=eye;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.lens=24 if name=='portal' else 32
    scene.render.filepath=str(H/f'polish-{tag}-{name}.png');bpy.ops.render.render(write_still=True)

