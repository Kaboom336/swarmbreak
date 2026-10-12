"""Original low-poly Crow authoring. Run Blender 4.5: -b -P build_crow.py -- --iteration 1.
All output is beside this script. No external assets or image textures used.
"""
import bpy, bmesh, math, json, argparse, sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parent
args = argparse.ArgumentParser()
args.add_argument('--iteration', type=int, default=3)
args.add_argument('--export', action='store_true')
args.add_argument('--fix-round', action='store_true', help='Update final outputs without replacing iteration archives')
opt = args.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
IT = opt.iteration
COLORS = {'Feathers':'1C1A24','Chest':'4B2C7A','Pumpkin':'FF8A1F',
          'BillFeet':'FFA032','EyeWhite':'FFFFFF','Stem':'3FAE49','Pupil':'111018'}
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for d in list(bpy.data.materials): bpy.data.materials.remove(d)
pet = bpy.data.collections.new('CROW • 3.2 studs • front -Y')
bpy.context.scene.collection.children.link(pet)
stage = bpy.data.collections.new('STUDIO • excluded from export')
bpy.context.scene.collection.children.link(stage)
M = {}
def linear(v):
    v=v/255; return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
for name,h in COLORS.items():
    m=bpy.data.materials.new(name); m.use_nodes=True
    rgb=[int(h[i:i+2],16) for i in (0,2,4)]
    m.diffuse_color=(*[linear(v) for v in rgb],1)
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=m.diffuse_color
    p.inputs['Roughness'].default_value=(.38 if IT==3 else .27) if name=='Feathers' else (.46 if IT==3 else .38)
    p.inputs['Coat Weight'].default_value=(.16 if IT==3 else .28) if name=='Feathers' else .1
    M[name]=m

def finish(o,name,mat,bevel=0,segments=1,smooth=False):
    o.name=name
    for c in list(o.users_collection): c.objects.unlink(o)
    pet.objects.link(o); o.data.materials.append(M[mat])
    bpy.context.view_layer.objects.active=o; o.select_set(True)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Soft brick edges','BEVEL'); mod.width=bevel; mod.segments=segments
        bpy.ops.object.modifier_apply(modifier=mod.name)
    # Clamped bevels on a thin plate can leave coincident edge vertices.
    # Weld these before triangulation so Studio receives no zero-area faces.
    bm=bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=1e-7)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(o.data); bm.free(); o.data.update()
    if smooth:
        for p in o.data.polygons: p.use_smooth=True
        mod=o.modifiers.new('Weighted face normals','WEIGHTED_NORMAL'); mod.keep_sharp=True; mod.weight=40
        bpy.ops.object.modifier_apply(modifier=mod.name)
    o.select_set(False); return o

def box(name,loc,size,mat,bevel=.05,segments=1,rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o=bpy.context.object; o.dimensions=size
    if rot: o.rotation_euler=rot
    return finish(o,name,mat,bevel,segments,True)

def mesh(name,verts,faces,mat,bevel=0,segments=1,smooth=False):
    me=bpy.data.meshes.new(name); me.from_pydata(verts,[],faces); me.update()
    bm=bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm,faces=bm.faces); bm.to_mesh(me); bm.free()
    o=bpy.data.objects.new(name,me); pet.objects.link(o)
    return finish(o,name,mat,bevel,segments,smooth)

def disc(name,x,y,z,rx,rz,depth,mat,n=20,face_scale=.45):
    # Domed oval with a broad flat face: 3 rings, no UV/image dependency.
    verts=[]
    for scale,dy in [(1,0),(max(.88,face_scale),-depth*.8),(face_scale,-depth)]:
        for j in range(n):
            a=2*math.pi*j/n; verts.append((x+rx*scale*math.cos(a),y+dy,z+rz*scale*math.sin(a)))
    faces=[tuple(range(n-1,-1,-1)),tuple(range(2*n,3*n))]
    for k in range(2):
        for j in range(n): faces.append((k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j))
    return mesh(name,verts,faces,mat,smooth=True)

def wing(side):
    # One contiguous extruded stepped feather silhouette, rather than overlapping blocks.
    if IT==1:
        outline=[(.67,.81),(1.30,.84),(1.62,1.19),(1.72,1.52),(1.42,1.57),(1.02,1.20),(.72,1.17)]
    else:
        outline=[(.67,.86),(1.15,.88),(1.38,1.02),(1.38,1.13),(1.59,1.13),(1.59,1.30),
                 (1.78,1.30),(1.84,1.70),(1.58,1.76),(1.39,1.55),(1.16,1.42),(.76,1.30)]
        if side==1:
            outline=[(x,z+(.17*(x-.67))) for x,z in outline]
    verts=[(side*x,y,z) for y in (-.08,.24) for x,z in outline]; n=len(outline)
    faces=[tuple(range(n)),tuple(range(n,2*n))]
    faces += [(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    mesh(('Right' if side==1 else 'Left')+' waving stepped wing',verts,faces,'Feathers',.045,1,True)
    if IT>=2:
        box('Wing top brick', (side*1.52,.065,1.71+(.14 if side==1 else 0)),(.20,.20,.09),'Feathers',.015)

# Core silhouette: head occupies 1.76 / 3.2 studs, body is tucked beneath.
headwidth = 1.91 if IT==1 else 2.12
box('Rounded brick head',(0,0,1.97),(headwidth,1.64,1.76),'Feathers',.25 if IT==1 else .28,3)
bodywidth = 1.32 if IT==1 else 1.25
box('Tucked short body',(0,.10,.76),(bodywidth,1.15,1.10),'Feathers',.22,2)
# Purple feather bib follows the body and has a tapered lower edge.
poly=[(-.48,1.16),(.48,1.16),(.50,.66),(.30,.43),(0,.36),(-.30,.43),(-.50,.66)]
if IT==3: poly=[(-.44,1.14),(.44,1.14),(.46,.68),(.27,.48),(0,.42),(-.27,.48),(-.46,.68)]
verts=[(x,y,z) for y in (-.515,-.44) for x,z in poly]; n=len(poly)
mesh('Purple chest feather bib',verts,[tuple(range(n)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],'Chest',.065,2,True)
for s in (-1,1):
    box('Orange stub foot '+str(s),(s*.39,-.24,.12),(.46,.61,.24),'BillFeet',.065,2)
    wing(s)
# A compact rear tail reads from profile, hidden behind the belly from the front.
box('Small tail',(0,.74,.57),(.63,.52,.25),'Feathers',.07,1,rot=(math.radians(-20),0,0))

eye_r = .36 if IT==1 else (.435 if IT==2 else .445)
eye_z = 2.05 if IT<3 else 2.08
for s in (-1,1):
    x=s*(.48 if IT==1 else .50)
    disc('White eye '+str(s),x,-.822,eye_z,eye_r,eye_r*1.06,.022 if IT==3 else .075,'EyeWhite',24 if IT==3 else 20,face_scale=.98 if IT==3 else .45)
    pupilx=x-s*(.015 if IT<3 else .045)
    pupilz=eye_z+(.007 if IT<3 else -.05)
    disc('Big pupil '+str(s),pupilx,-.847 if IT==3 else -.902,pupilz,eye_r*(.55 if IT==3 else .70),eye_r*(1.06*.55 if IT==3 else .78),.016 if IT==3 else .055,'Pupil',24 if IT==3 else 20)
    hy=-.866 if IT==3 else -.960
    disc('Eye sparkle large '+str(s),pupilx-.065,hy,pupilz+.08 if IT==3 else eye_z+.115,.058 if IT==3 else .083,.065 if IT==3 else .09,.007 if IT==3 else .012,'EyeWhite',12)
    disc('Eye sparkle tiny '+str(s),pupilx+.08,hy,pupilz-.065 if IT==3 else eye_z-.09,.026 if IT==3 else .036,.029 if IT==3 else .04,.007 if IT==3 else .012,'EyeWhite',10)

# Sculpted six-sided wedge bill: broad cheek root and blunt cute tip.
beakw = .67 if IT==1 else (.59 if IT==2 else .55)
backy=-.80; tipy=-1.30 if IT<3 else -1.25
tipwidth=beakw*(.23 if IT==3 else .30)
tiptop=1.64 if IT==3 else 1.65
verts=[(-beakw/2,backy,1.75),(beakw/2,backy,1.75),(-tipwidth,tipy,tiptop),(tipwidth,tipy,tiptop),
       (-beakw/2,backy,1.49),(beakw/2,backy,1.49),(-tipwidth,tipy,1.51),(tipwidth,tipy,1.51)]
mesh('Short chunky orange bill',verts,[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)],'BillFeet',.045,2,True)
if IT==3:
    box('Tiny bill smile seam',(0,tipy-.003,1.565),(tipwidth*1.35,.012,.015),'Feathers',.004,1)

# Pumpkin cap is one gently lobed rounded block, rather than a pile of spheres.
verts=[]; N=24
for z,r in [(2.78,.78),(2.83,1),(3.035,.89),(3.075,.62)]:
    for j in range(N):
        a=2*math.pi*j/N
        # Superellipse gives the same chunky brick language as the head.
        c=math.cos(a); s=math.sin(a); lobe=1+(.04 if IT==1 else .09)*math.cos(8*a)
        verts.append((.61*r*math.copysign(abs(c)**.60,c)*lobe,.48*r*math.copysign(abs(s)**.60,s)*lobe,z))
faces=[tuple(range(N-1,-1,-1)),tuple(range(3*N,4*N))]
for k in range(3):
    for j in range(N): faces.append((k*N+j,k*N+(j+1)%N,(k+1)*N+(j+1)%N,(k+1)*N+j))
mesh('Lobed pumpkin brick cap',verts,faces,'Pumpkin',smooth=False)
box('Green stem base',(0,0,3.075),(.30,.25,.09),'Stem',.025)
box('Bent green stem',(0,.01,3.14),(.14,.15,.12),'Stem',.018,1,rot=(0,.20 if IT==1 else .35,0))
if IT>=2:
    for x in (-.29,.29):
        box('Pumpkin top stud',(x,0,3.075),(.13,.13,.06),'Pumpkin',.015)

# Normalize exactly to 3.2 studs, keeping the bottom center at the shared origin.
bpy.context.view_layer.update()
coords=[o.matrix_world@v.co for o in pet.objects for v in o.data.vertices]
lo=min(v.z for v in coords); hi=max(v.z for v in coords); factor=3.2/(hi-lo)
for o in pet.objects:
    o.location.z-=lo; o.location*=factor
    for v in o.data.vertices: v.co*=factor
bpy.context.view_layer.update()
for o in pet.objects:
    bpy.context.view_layer.objects.active=o; o.select_set(True)
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    o.select_set(False)

def triangles():
    total=0
    for o in pet.objects: o.data.calc_loop_triangles(); total+=len(o.data.loop_triangles)
    return total
total=triangles(); assert total<2500, f'Triangle budget exceeded: {total}'
print(f'ITERATION {IT}: {total} triangles, 3.200 studs tall',flush=True)

# Light-grey studio, with an untextured plane and broad softbox reflections.
scene=bpy.context.scene; scene.render.engine='BLENDER_EEVEE_NEXT'
scene.eevee.taa_render_samples=64
scene.render.resolution_x=1024; scene.render.resolution_y=1024; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'; scene.render.film_transparent=False
scene.world.color=(.32,.32,.32)
scene.world.use_nodes=True; scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.63,.66,.72,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.45
scene.view_settings.view_transform='AgX' if IT==1 else 'Standard'
scene.view_settings.exposure=0 if IT==1 else (-.35 if IT==3 else -.55)
def stage_link(o):
    for c in list(o.users_collection): c.objects.unlink(o)
    stage.objects.link(o)
ground=bpy.data.materials.new('Studio grey'); ground.diffuse_color=(.72,.74,.78,1)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.018)); stage_link(bpy.context.object)
bpy.context.object.name='Studio floor'; bpy.context.object.data.materials.append(ground)
def aim(o,target): o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
for name,loc,power,size,col in [('Softbox key',(-3,-4,7),650,5,(1,.87,.76)),('Softbox fill',(4,-3,4),450,4,(.76,.84,1)),('Purple rim',(1,4,5),850,3,(.76,.67,1))]:
    bpy.ops.object.light_add(type='AREA',location=loc); o=bpy.context.object; stage_link(o)
    o.name=name; o.data.energy=power*(.60 if IT==3 else 1); o.data.shape='DISK'; o.data.size=size; o.data.color=col; aim(o,(0,0,1.5))
bpy.ops.object.camera_add(); camera=bpy.context.object; stage_link(camera); scene.camera=camera
camera.data.type='ORTHO'; camera.data.lens=60
def render(tag,loc,target=(0,0,1.55),scale=4.6):
    camera.location=loc; aim(camera,target); camera.data.ortho_scale=scale
    scene.render.filepath=str(ROOT/f'final-{tag}.png') if opt.fix_round else str(ROOT/'renders'/f'iter{IT}-{tag}.png')
    bpy.ops.render.render(write_still=True)
render('front',(0,-9,3.35))
render('34',(6,-9,5.0))
if not opt.fix_round:
    render('side',(9,0,3.3))
# Real 5.5-stud dark box, grounded next to the crow, only in scale render.
bpy.ops.mesh.primitive_cube_add(size=1,location=(-2.9,.6,2.75)); scale_box=bpy.context.object
scale_box.name='5.5 stud scale box'; scale_box.dimensions=(1.05,1.05,5.5); stage_link(scale_box); scale_box.data.materials.append(M['Feathers'])
if not opt.fix_round:
    render('scale',(6,-12,6.6),(-1.05,0,2.6),7.1)
scale_box.hide_render=True; scale_box.hide_set(True)
camera.location=(6,-9,5); aim(camera,(0,0,1.55)); camera.data.ortho_scale=4.6
if not opt.fix_round:
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/f'iter{IT}.blend'))
stats={'iteration':IT,'triangles':total,'height_studs':3.2,'objects':len(pet.objects),'materials':COLORS}
if not opt.fix_round:
    (ROOT/'renders'/f'iter{IT}-stats.json').write_text(json.dumps(stats,indent=2))
if opt.export:
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'crow.blend'))
    bpy.ops.object.select_all(action='DESELECT')
    for o in pet.objects: o.hide_set(False); o.select_set(True)
    bpy.context.view_layer.objects.active=next(iter(pet.objects))
    bpy.ops.export_scene.fbx(filepath=str(ROOT/'crow.fbx'),use_selection=True,object_types={'MESH'},
        global_scale=1.0,apply_unit_scale=True,axis_forward='-Z',axis_up='Y',use_mesh_modifiers=True,
        mesh_smooth_type='FACE',add_leaf_bones=False,bake_anim=False)
    # Right-handed change of basis: (x,y,z) -> (x,z,-y). Front becomes +Z.
    # Determinant +1 retains the outside counter-clockwise triangle winding.
    parts=[]
    for mat,h in COLORS.items():
        vertices=[]; tris=[]
        for o in pet.objects:
            if o.data.materials[0].name!=mat: continue
            offset=len(vertices)
            for v in o.data.vertices:
                p=o.matrix_world@v.co; vertices.append([round(p.x,7),round(p.z,7),round(-p.y,7)])
            o.data.calc_loop_triangles()
            tris.extend([[offset+i for i in t.vertices] for t in o.data.loop_triangles])
        parts.append({'name':mat,'color':[int(h[i:i+2],16) for i in (0,2,4)],'vertices':vertices,'triangles':tris})
    (ROOT/'crow_parts.json').write_text(json.dumps(parts,separators=(',',':')))
    import shutil
    if not opt.fix_round:
        for tag,dest in [('front','final-front.png'),('34','final-34.png')]: shutil.copyfile(ROOT/'renders'/f'iter{IT}-{tag}.png',ROOT/dest)
    (ROOT/'final-stats.json').write_text(json.dumps(stats,indent=2))
    print('FINAL EXPORTED',flush=True)
