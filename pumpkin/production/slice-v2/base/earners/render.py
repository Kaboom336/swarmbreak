"""Offline proof from parts.json exported by the actual Luau factory. No authored duplicate model."""
import bpy, json, math, sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
TAG=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'final'
parts=json.loads((ROOT/'parts.json').read_text())
def linear(c): return c/12.92 if c<0.04045 else ((c+0.055)/1.055)**2.4
def material(name,color,neon=False):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*map(linear,color),1)
    p.inputs['Roughness'].default_value=0.85
    if neon:
        p.inputs['Emission Color'].default_value=(*map(linear,color),1); p.inputs['Emission Strength'].default_value=1.5
    return m
def cube(name,position,size,mat):
    bpy.ops.mesh.primitive_cube_add(size=1,location=position); o=bpy.context.object; o.name=name
    o.dimensions=size; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(mat); return o
for variant,rows in zip(('normal','gold','diamond'),parts):
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    mats={}; objects=[]; vertices=[]; faces=[]; objlines=[]; mtllines=[]
    for i,p in enumerate(rows):
        key=tuple(p['color'])+(p['neon'],)
        if key not in mats:
            name='palette'+str(len(mats)); mats[key]=material(name,p['color'],p['neon'])
            mtllines.extend(['newmtl '+name,'Kd '+' '.join(map(str,p['color']))])
        x,y,z=p['position']; sx,sy,sz=p['size']; mat=mats[key]
        o=cube('Voxel'+str(i),(x,-z,y),(sx,sz,sy),mat); objects.append(o)
        objlines.extend(['o Voxel'+str(i),'usemtl '+mat.name])
        start=len(vertices)
        for v in o.data.vertices:
            w=o.matrix_world@v.co; vertices.append(w); objlines.append('v %.5f %.5f %.5f'%tuple(w))
        for poly in o.data.polygons: objlines.append('f '+' '.join(str(start+j+1) for j in poly.vertices))
    # OBJ contains precisely the merged grid boxes; studs are engine SurfaceType, approximated below.
    (ROOT/(variant+'.obj')).write_text('mtllib '+variant+'.mtl\n'+'\n'.join(objlines)+'\n')
    (ROOT/(variant+'.mtl')).write_text('\n'.join(mtllines)+'\n')
    # Exposed cell tops only. These are preview-only SurfaceType approximations, not extra runtime Parts.
    occupied={}
    for p in rows:
        x,y,z=p['position']; sx,sy,sz=p['size']
        for ix in range(round(sx/.5)):
            for iy in range(round(sy/.5)):
                for iz in range(round(sz/.5)):
                    occupied[(round((x-sx/2+.25+ix*.5)*2),round((y-sy/2+iy*.5)*2),round((z-sz/2+.25+iz*.5)*2))]=p
    for (x,y,z),p in occupied.items():
        if (x,y+1,z) in occupied: continue
        key=tuple(p['color'])+(p['neon'],)
        bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=.12,depth=.07,location=(x/2,-z/2,y/2+.535))
        bpy.context.object.data.materials.append(mats[key])
    floor=material('pedestal',(.31,.33,.36)); carpet=material('carpet',(.69,.10,.10))
    cube('Pedestal',(0,0,-.15),(7,4,.3),floor)
    cube('Carpet',(0,-5,-.33),(200,200,.1),carpet)
    scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=8; scene.cycles.use_denoising=True
    scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.6,.65,.7,1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.8
    bpy.ops.object.light_add(type='AREA',location=(-8,-10,16)); bpy.context.object.data.energy=2200; bpy.context.object.data.shape='DISK'; bpy.context.object.data.size=10
    bpy.ops.object.camera_add(location=(9,-28,13))
    camera=bpy.context.object; target=Vector((0,0,2.7)); camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.type='PERSP'; camera.data.lens=60; scene.camera=camera
    scene.render.resolution_x=720; scene.render.resolution_y=720; scene.render.resolution_percentage=100
    scene.view_settings.view_transform='Standard'; scene.render.image_settings.file_format='PNG'
    scene.render.filepath=str(ROOT/(TAG+'-'+variant+'.png')); bpy.ops.render.render(write_still=True)
    if variant=='normal':
        # 40-stud proof: 70 degree vertical FOV equivalent, 720px viewport height.
        direction=(camera.location-target).normalized(); camera.location=target+direction*40
        camera.data.lens=720/(2*math.tan(math.radians(70)/2))/720*36
        scene.render.filepath=str(ROOT/(TAG+'-40stud.png')); bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/(variant+'.blend')))
print('PASS offline renders and grid OBJ exports',TAG)
