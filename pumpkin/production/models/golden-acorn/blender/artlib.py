import bpy,bmesh,math,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
M={}; COLORS={}; objects=[]
def init(colors):
    global COLORS
    COLORS=colors
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for name,h in colors.items():
        rgb=[int(h[i:i+2],16)/255 for i in (0,2,4)]
        linear=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
        m=bpy.data.materials.new(name); m.diffuse_color=(*linear,1); m.use_nodes=True
        p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=m.diffuse_color
        p.inputs['Roughness'].default_value=.72
        M[name]=m
def finish(o,name,mat,bevel=0):
    o.name=name; o.data.materials.append(M[mat]); bpy.context.view_layer.objects.active=o
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Broad chamfer','BEVEL'); mod.width=bevel; mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bm=bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.0000001)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(o.data); bm.free()
    objects.append(o); o.select_set(False); return o
def box(name,loc,size,mat,bevel=.06,rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.dimensions=size
    if rot: o.rotation_euler=rot
    return finish(o,name,mat,bevel)
def mesh(name,verts,faces,mat,bevel=0):
    me=bpy.data.meshes.new(name); me.from_pydata(verts,[],faces); me.update()
    o=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(o)
    return finish(o,name,mat,bevel)
def rings(name,profile,mat,n=12,sx=1,sy=1):
    v=[(r*math.cos(2*math.pi*j/n+math.pi/n)*sx,r*math.sin(2*math.pi*j/n+math.pi/n)*sy,z) for r,z in profile for j in range(n)]
    f=[tuple(range(n-1,-1,-1)),tuple(range((len(profile)-1)*n,len(profile)*n))]
    for k in range(len(profile)-1):
        for j in range(n): f.append((k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j))
    return mesh(name,v,f,mat)
def plate(name,outline,y,depth,mat,bevel=0):
    n=len(outline); v=[(x,yy,z) for yy in (y,y+depth) for x,z in outline]
    return mesh(name,v,[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)],mat,bevel)
def eye(name,x,y,z,rx,rz,mat,n=16):
    return plate(name,[(x+rx*math.cos(j*2*math.pi/n),z+rz*math.sin(j*2*math.pi/n)) for j in range(n)],y,.035,mat)
def aim(o,p): o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
def stage(height):
    s=bpy.context.scene; s.render.engine='BLENDER_EEVEE_NEXT'; s.eevee.taa_render_samples=32
    s.render.resolution_x=900; s.render.resolution_y=900; s.render.resolution_percentage=100
    s.render.image_settings.file_format='PNG'; s.view_settings.view_transform='Standard'; s.view_settings.exposure=-.5
    s.world.use_nodes=True; s.world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.62,.7,1)
    s.world.node_tree.nodes['Background'].inputs[1].default_value=.45
    bpy.ops.mesh.primitive_plane_add(size=200); o=bpy.context.object; o.name='STUDIO floor'
    m=bpy.data.materials.new('STUDIO'); m.diffuse_color=(.67,.71,.75,1); o.data.materials.append(m)
    for loc,power,size in [((-1,-1.4,2),40,1.3),((1.4,-.5,1.2),28,1),((.4,1.3,1.7),45,1)]:
        bpy.ops.object.light_add(type='AREA',location=tuple(v*height for v in loc)); o=bpy.context.object
        o.data.energy=power*height*height; o.data.size=size*height; aim(o,(0,0,height*.5))
    bpy.ops.object.camera_add(); c=bpy.context.object; c.data.type='ORTHO'; s.camera=c
    return c
def render(path,c,h,front=False,scale=None,target=None):
    c.location=(0,-h*3,h*.9) if front else (h*1.7,-h*2.6,h*1.5)
    aim(c,target or (0,0,h*.49)); c.data.ortho_scale=scale or h*1.4
    bpy.context.scene.render.filepath=str(path); bpy.ops.render.render(write_still=True)
def export(name,obs):
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs: o.hide_set(False); o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0]
    bpy.ops.export_scene.fbx(filepath=str(ROOT/(name+'.fbx')),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',global_scale=1,apply_unit_scale=True,mesh_smooth_type='FACE',bake_anim=False,add_leaf_bones=False)
    parts=[]
    for mat,h in COLORS.items():
        v=[]; t=[]
        for o in obs:
            if o.data.materials[0]!=M[mat]: continue
            off=len(v)
            for vert in o.data.vertices:
                p=o.matrix_world@vert.co; v.append([round(p.x,7),round(p.z,7),round(-p.y,7)])
            o.data.calc_loop_triangles(); t.extend([[off+i for i in tri.vertices] for tri in o.data.loop_triangles])
        if v: parts.append(dict(name=mat,color=[int(h[i:i+2],16) for i in (0,2,4)],vertices=v,triangles=t))
    (ROOT/(name+'_parts.json')).write_text(json.dumps(parts,separators=(',',':')))
    return sum(len(p['triangles']) for p in parts)
def stats(obs):
    total=0; pts=[]
    for o in obs:
        o.data.calc_loop_triangles(); total+=len(o.data.loop_triangles)
        pts.extend(o.matrix_world@v.co for v in o.data.vertices)
    return dict(triangles=total,height_studs=round(max(p.z for p in pts)-min(p.z for p in pts),6),objects=len(obs))
