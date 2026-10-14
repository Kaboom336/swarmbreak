"""Compose diagnostic renders with Blender; no package install or policy change."""
import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.render.engine='BLENDER_EEVEE_NEXT'
scene.eevee.taa_render_samples=1
scene.render.resolution_x=1600; scene.render.resolution_y=1670; scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(0.85,0.89,0.87,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=1
def emission(name,color=None,image=None):
    mat=bpy.data.materials.new(name); mat.use_nodes=True
    nodes=mat.node_tree.nodes; nodes.clear()
    out=nodes.new('ShaderNodeOutputMaterial'); emit=nodes.new('ShaderNodeEmission')
    if image:
        tex=nodes.new('ShaderNodeTexImage'); tex.image=image
        mat.node_tree.links.new(tex.outputs['Color'],emit.inputs['Color'])
    else: emit.inputs['Color'].default_value=color
    mat.node_tree.links.new(emit.outputs[0],out.inputs['Surface'])
    return mat
black=emission('Text',(0.015,0.025,0.02,1))
def label(text,x,y,size=22):
    bpy.ops.object.text_add(location=(x,1670-y-size,2))
    ob=bpy.context.object; ob.data.body=text; ob.data.size=size; ob.data.materials.append(black)
def tile(path,x,y,w,h):
    im=bpy.data.images.load(str(path)); iw,ih=im.size
    scale=min(w/iw,h/ih); dw,dh=iw*scale,ih*scale
    bpy.ops.mesh.primitive_plane_add(size=1,location=(x+w/2,1670-y-h/2,1))
    ob=bpy.context.object; ob.scale=(dw,dh,1); ob.data.materials.append(emission(path.name,image=im))
label('OFFLINE GEOMETRY PREVIEW - NOT STUDIO SCREENSHOTS',20,12,30)
label('Saved place Parts rendered in Blender. Roblox materials, sky and playability are unverified.',20,60,22)
names=['A / Orchard Ring','B / Corkscrew Summit','C / Split Valley']
escapes=['Escape: descend camp, cut across the south court; ring and hill routes offer flanks.',
         'Escape: descend +18/+12/+6 shelves; spiral and east switchback offer reversals.',
         'Escape: dog-leg off camp to optional bridge; west causeway and east ridge bypass it.']
for i,letter in enumerate('ABC'):
    y=110+515*i
    label(names[i],20,y,30)
    label('Top / offline',20,y+42); label('3/4 / offline',640,y+42); label('v2 reference',1260,y+42)
    tile(ROOT/f'{letter}-top-offline.png',10,y+70,620,390)
    tile(ROOT/f'{letter}-34-offline.png',630,y+70,620,390)
    tile(ROOT/'../../v2/meadow-island.png',1250,y+70,340,390)
    label(escapes[i],20,y+470,22)
bpy.ops.object.camera_add(location=(800,835,1000))
camera=bpy.context.object; camera.data.type='ORTHO'; camera.data.ortho_scale=1670; scene.camera=camera
scene.render.image_settings.file_format='JPEG'; scene.render.image_settings.color_mode='RGB'
scene.render.image_settings.quality=94
scene.render.filepath=str(ROOT/'_sheet-OFFLINE.jpg')
bpy.ops.render.render(write_still=True)
