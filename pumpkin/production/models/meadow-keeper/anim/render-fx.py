"""Offline approximation: SAME rig/poses/acorn geometry, schematic native VFX.
No Studio/audio/shake claim. Generated PNG/GIF artifacts only, no model saves.
"""
import bpy, json, math, sys, random
from pathlib import Path
from mathutils import Vector, Matrix
R=Path(__file__).resolve().parent
# Reuse inspected pose hierarchy and approved scene; skip its old rendering loop.
source=(R/'render.py').read_text().split('times={')[0]
source=source.replace("scene.eevee.taa_render_samples = 12", "scene.render.engine='BLENDER_EEVEE_NEXT'")
exec(compile(source,str(R/'render.py'),'exec'),globals())
OUT=R/'preview'/'fx';OUT.mkdir(parents=True,exist_ok=True)
if '--throw-variants' in sys.argv:OUT=R/'preview'/'throw-blind';OUT.mkdir(parents=True,exist_ok=True)
scene.render.resolution_x=480;scene.render.resolution_y=360
scene.render.resolution_percentage=100
camera.location=(30,-40,28);camera.rotation_euler=(Vector((0,-10,4))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.ortho_scale=43
for o in stones+caps: o.hide_render=True
alert.hide_render=True
def material(name,color,glow=False):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1)
    if glow:
        m.use_nodes=True;n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*color,1)
        n.inputs['Emission Color'].default_value=(*color,1);n.inputs['Emission Strength'].default_value=1.4
    return m
brown=material('FX bark',(.24,.12,.045));cut=material('FX cut',(.7,.45,.18))
dustmat=material('FX dust',(.62,.43,.22));redmat=material('FX tell',(.9,.045,.025),True)
goldmat=material('FX wave',(1,.62,.035),True);green=material('FX acorn trail',(.42,.68,.10),True)
cream=material('FX speed',(1,.87,.53),True)
def sphere(name,r,mat):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=r)
    o=bpy.context.object;o.name=name;o.data.materials.append(mat);return o
def cylinder(name,r,depth,mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=depth,location=(0,0,0))
    o=bpy.context.object;o.name=name;o.data.materials.append(mat);o.rotation_euler.y=math.pi/2;return o
log=[cylinder('8 STUD ROLLING LOG',3,8,brown)]
for x in [-4.02,4.02]:
    log.append(cylinder('Cut end',2.88,.06,cut));log[-1].location.x=x
    for r in [.7,1.4,2.1]:
        bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=4,major_radius=r,minor_radius=.06,location=(0,0,0))
        o=bpy.context.object;o.rotation_euler.y=math.pi/2;o.location.x=x*1.004;o.data.materials.append(brown);log.append(o)
for o in log:bpy.data.objects.remove(o,do_unlink=True)
log=[sphere('Heavy boulder',2.7,material('Boulder stone',(.29,.32,.27)))]
log[0].location=(0,0,0)
bpy.context.view_layer.update()
logRest=[o.matrix_world.copy() for o in log]
acorns=[]
data=json.loads((R.parent.parent/'golden-acorn/blender/golden-acorn_parts.json').read_text())
for i in range(3):
    group=[]
    for section in data:
        verts=[tuple(BI@((Vector(v)-Vector((0,1.5,0)))*.72)) for v in section['vertices']]
        mesh=bpy.data.meshes.new('Approved acorn');mesh.from_pydata(verts,[],section['triangles']);mesh.update()
        obj=bpy.data.objects.new(section['name'],mesh);scene.collection.objects.link(obj)
        name=section['name'].lower();obj.data.materials.append(material('Brown green acorn',(.21,.32,.065) if 'cap' in name else (.36,.21,.08) if 'stem' in name else (.53,.26,.095)))
        group.append(obj)
    acorns.append(group)
fx=[]
random.seed(16)
particles=[sphere('Dust puff',1,dustmat) for _ in range(45)]
chunks=[sphere('Debris',.35+(i%3)*.15,brown) for i in range(10)]
directions=[Vector((math.cos(i*2.4),math.sin(i*2.4),0)) for i in range(45)]
def ring(name,mat):
    bpy.ops.mesh.primitive_torus_add(major_segments=64,minor_segments=4,major_radius=1,minor_radius=.035)
    o=bpy.context.object;o.name=name;o.data.materials.append(mat);return o
tell=ring('Damage radius tell',redmat);wave=ring('Moving shockwave rim',goldmat)
def line(mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=6,radius=.045,depth=1)
    o=bpy.context.object;o.data.materials.append(mat);return o
trails=[line(green) for _ in range(15)]
lanes=[line(redmat) for _ in range(3)]
speedlines=[line(cream) for _ in range(6)]
starobjs=[]
for i in range(6):
    verts=[(0,0,0)]+[(math.sin(j*math.pi/5)*(.6 if j%2==0 else .25),0,math.cos(j*math.pi/5)*(.6 if j%2==0 else .25)) for j in range(10)]
    me=bpy.data.meshes.new('Five point star');me.from_pydata(verts,[],[(0,j+1,(j+1)%10+1) for j in range(10)])
    ob=bpy.data.objects.new('Hit star',me);scene.collection.objects.link(ob);ob.data.materials.append(goldmat);starobjs.append(ob)
allfx=particles+chunks+[tell,wave]+trails+lanes+speedlines+starobjs+log+[o for g in acorns for o in g]
alert.data.size=4.5
alert.location=(-.6,-.1,12)
dummy=sphere('Player hit fixture torso',1,material('Player blue',(.06,.35,.64)))
dummy.scale=(.7,.45,1.5);dummy.location=(0,-8,2)
dummyhead=sphere('Player hit fixture head',.6,cut);dummyhead.location=(0,-8,4)
dummy.hide_render=dummyhead.hide_render=True
bpy.ops.mesh.primitive_cube_add(size=1,location=(0,-27,3.5))
wallfixture=bpy.context.object;wallfixture.name='Dash wall hit fixture'
wallfixture.scale=(12,.5,7);wallfixture.data.materials.append(brown);wallfixture.hide_render=True
def segment(o,a,b):
    delta=b-a;o.location=(a+b)/2;o.rotation_euler=delta.to_track_quat('Z','Y').to_euler();o.scale=(1,1,delta.length);o.hide_render=False
def burst(pos,age,heavy):
    if age<0 or age>.8:return
    for i,o in enumerate(particles[:45 if heavy else 14]):
        o.hide_render=False;o.location=pos+directions[i]*(age*(9 if heavy else 4))+Vector((0,0,.3+math.sin(age*math.pi)*2))
        o.scale=(max(.05,(.3+age*2)*(1-age/.9)),)*3
    if heavy:
        for i,o in enumerate(chunks):
            o.hide_render=False;o.location=pos+directions[i]*(age*8)+Vector((0,0,.4+12*age-18*age*age));o.rotation_euler=(age*4,i,age*7)
def propsfx(kind,t,w,release_pos):
    for o in allfx:o.hide_render=True
    alert.hide_render=True
    dummy.hide_render=dummyhead.hide_render=True
    wallfixture.hide_render=kind!='dash'
    if kind in ['lob','fan']:
        tell.hide_render=kind!='lob';tell.location=(0,-24,.07);tell.scale=(8,8,1)
        for i in range(3 if kind=='fan' else 1):
            p=socket(w,kind);alpha=max(0,min(1,(t-.62)/(.9 if kind=='lob' else .7)))
            dest=Vector((0,2 if kind=='lob' else 3,24))
            if kind=='fan':dest=release_pos+Matrix.Rotation(math.radians([-16,0,16][i]),3,'Y')@(dest-release_pos)
            if t>=.62:p=release_pos.lerp(dest,alpha)+Vector((0,(36 if kind=='lob' else 3)*alpha*(1-alpha),0))
            if kind=='lob':
                for ob,m in zip(log,logRest):
                    ob.hide_render=t<.20 or t>1.52;ob.matrix_world=Matrix.Translation(BI@p)@Matrix.Rotation(alpha*9,4,'X')@m
            else:
                for ob in acorns[i]:ob.hide_render=t>1.32;ob.matrix_world=Matrix.Translation(BI@p)@Matrix.Rotation(alpha*12,4,'X')
                segment(lanes[i],Vector((0,0,.07)),Vector((dest.x,-dest.z,.07)))
            if .62<=t<=1.52:
                for j in range(5):
                    earlier=max(0,alpha-(j+1)*.025);q=release_pos.lerp(dest,earlier)+Vector((0,(36 if kind=='lob' else 3)*earlier*(1-earlier),0))
                    segment(trails[i*5+j],BI@p,BI@q)
        burst(Vector((0,0,.15)),t-.12,False)
        burst(Vector((0,-24,.1)),t-(1.52 if kind=='lob' else 1.32),kind=='lob')
    elif kind=='slam':
        tell.hide_render=False;tell.data.materials[0]=goldmat;tell.location=(0,0,.06);tell.scale=(22,22,1)
        burst(Vector((0,0,.1)),t-.12,False)
        burst(Vector((0,0,.1)),t-.8,True)
        if t>=.8:
            wave.hide_render=False;r=min(22,(t-.8)*24);wave.scale=(r,r,2);wave.location=(0,0,.18)
    elif kind=='dash':
        shift=max(0,min(24,(t-.5)*48));
        for n,o in objects.items():o.location.y-=shift
        burst(Vector((0,-shift,.12)),t-.1 if t<.5 else .2,False)
        segment(lanes[0],Vector((0,0,.1)),Vector((0,-24,.1)))
        if .5<=t<=1:
            for i,o in enumerate(speedlines):segment(o,Vector(((i-3)*1.5,-shift+3,3+i%2)),Vector(((i-3)*1.5,-shift+8,3+i%2)))
        if t>=1:
            for i,o in enumerate(starobjs):
                o.hide_render=False;o.location=(math.cos(i)*3,-21,11+math.sin(i)*2)
                o.rotation_euler.z=t*5;o.scale=(1.7,)*3
    else:
        alert.hide_render=t<.1 or t>.95
        bounce=1.25 if .24<t<.36 else 1.0
        alert.scale=(bounce*min(1.2,max(.1,(t-.1)*7)),)*3
        if t>=1:
            dummy.hide_render=dummyhead.hide_render=False
            burst(Vector((0,-8,3)),t-1,False)
            for i,o in enumerate(starobjs):
                o.hide_render=False;o.location=(math.cos(i)*(2+(t-1)*2),-8,3+math.sin(i)*(2+(t-1)*2))
                o.rotation_euler.z=t*5;o.scale=(1.9,)*3
    bpy.context.view_layer.update()
selection=['lob','fan','slam','dash','warn']
if '--only' in sys.argv:selection=[sys.argv[sys.argv.index('--only')+1]]
for kind in selection:
    key=kind
    if '--candidate' in sys.argv:key=sys.argv[sys.argv.index('--candidate')+1]
    clip=DATA['clips'][key]
    length={'lob':2.25,'fan':1.9,'slam':1.9,'dash':2,'warn':1.7}[kind]
    release_pos=None
    if kind in ['lob','fan']:release_pos=socket(apply(sample(clip,.62)),kind)
    count=round(length*30)
    for i in range(count):
        t=length*i/(count-1)
        w=apply(sample(DATA['clips']['stun'],t-1) if kind=='dash' and t>1 else sample(clip,min(t,clip['duration'])))
        propsfx(kind,t,w,release_pos)
        scene.render.filepath=str(OUT/f'{key}-{i:03d}.png');bpy.ops.render.render(write_still=True)
    if kind in ['lob','fan']:
        camera.location=(18,-29,16);camera.rotation_euler=(Vector((0,-1,6))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=21
        for i,t in enumerate([.20,.495,.575,.62,.74,1.10]):
            w=apply(sample(clip,t));propsfx(kind,t,w,release_pos)
            scene.render.filepath=str(OUT/f'{key}-pose-{i:02d}.png');bpy.ops.render.render(write_still=True)
    print('FX FINISHED',kind,flush=True)
