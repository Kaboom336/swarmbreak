"""Blender preview of the SAME CFrame hierarchy and quaternion interpolation as Roblox.
Run blender -b -t 6 -P models/meadow-keeper/anim/render.py
Only writes animation previews; never saves over the approved Blender model.
"""
import bpy, json, math, sys
from pathlib import Path
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parent
DATA = json.loads((ROOT/('previous-clips.json' if '--previous' in sys.argv else 'clips.json')).read_text())
if '--variants' in sys.argv: DATA = json.loads((ROOT/'variants-v3.json').read_text())
if '--throw-variants' in sys.argv: DATA = json.loads((ROOT/'variants-throw.json').read_text())
OUT = ROOT/'preview'
if '--before' in sys.argv: OUT = OUT/'before'
if '--previous' in sys.argv: OUT = OUT/'previous'
if '--variants' in sys.argv: OUT = OUT/'variants-v3'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT.parent/'blender/meadow-keeper.blend'))
scene = bpy.context.scene
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.engine='BLENDER_EEVEE_NEXT'
scene.render.image_settings.file_format = 'PNG'
names = DATA['jointOrder']
SK=json.loads((ROOT/'skeleton.json').read_text())
parents={n:None if p=='Root' else p for n,p in SK['parents'].items()}
# Blender -> Roblox: (x,y,z) -> (x,z,-y), proper rotation determinant +1.
B = Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))
BI = B.inverted()
pivots={n:Vector(SK['pivots'][n]) for n in names}
# Reuse approved geometry, split into closed articulated sections; never save the .blend.
for n in ['Torso','Leg.L','Leg.R','Arm.L','Arm.R','Head','Hat']:
    bpy.data.objects.remove(bpy.data.objects[n],do_unlink=True)
objects={};rest={}
for n in names:
    o=bpy.data.objects.new(n,None);scene.collection.objects.link(o)
    o.matrix_world=Matrix.Translation(BI@pivots[n]);objects[n]=o;rest[n]=o.matrix_world.copy()
for section in json.loads((ROOT/'throw-geometry.json').read_text()):
    n=section['rig_part'];mesh=bpy.data.meshes.new(section['name'])
    mesh.from_pydata([tuple(BI@(Vector(v)-pivots[n])) for v in section['vertices']],[],section['triangles']);mesh.update()
    o=bpy.data.objects.new(section['name'],mesh);scene.collection.objects.link(o);o.parent=objects[n]
    mat=bpy.data.materials.new(section['name']);mat.diffuse_color=tuple(c/255 for c in section['color'])+(1,);o.data.materials.append(mat)
local = {}
for n in names:
    parent = parents[n]
    local[n] = Matrix.Translation(pivots[n]-(pivots[parent] if parent else Vector((0,0,0))))

def cf(v):
    return Matrix.Translation(Vector(v[:3])) @ Matrix.Rotation(math.radians(v[3]),4,'X') @ Matrix.Rotation(math.radians(v[4]),4,'Y') @ Matrix.Rotation(math.radians(v[5]),4,'Z')

def ease(a, style):
    if style=='sine': return (1-math.cos(math.pi*a))/2
    if style=='in': return a*a
    if style=='out': return 1-(1-a)**2
    return a

def sample(clip,t):
    fs=clip['frames']
    left,right=fs[0],fs[-1]
    for i in range(1,len(fs)):
        if t<=fs[i]['t']: left,right=fs[i-1],fs[i]; break
    a=ease((t-left['t'])/(right['t']-left['t']),right['ease'])
    pose={}
    for n in names:
        l,r=cf(left['pose'][n]),cf(right['pose'][n])
        m=l.to_quaternion().slerp(r.to_quaternion(),a).to_matrix().to_4x4()
        m.translation=l.translation.lerp(r.translation,a)
        pose[n]=m
    return pose

def apply(pose):
    world={}
    for n in names:
        world[n]=(world[parents[n]] if parents[n] else Matrix.Identity(4)) @ local[n] @ pose[n]
        delta=world[n]@Matrix.Translation(-pivots[n])
        objects[n].matrix_world=BI@delta@B@rest[n]
    bpy.context.view_layer.update()
    return world

def hand(w,side):return w['Wrist.'+side]@Vector(SK['hand'])
def socket(w,kind):
    if kind in ('lob','K','R'):
        right,left=hand(w,'R'),hand(w,'L');half=(right-left)/2;direction=Vector((0,.2,1))
        if half.length>.001:direction-=half.normalized()*direction.dot(half.normalized())
        return (right+left)/2+direction.normalized()*math.sqrt(max(0,SK['lobRadius']**2-half.length**2))
    return hand(w,'R')

camera=scene.camera
camera.location=(18,-29,16)
camera.rotation_euler=(Vector((0,0,5.6))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.ortho_scale=17.5
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.7)
stone=bpy.context.object
stone.name='ANIM PREVIEW rock'
mat=bpy.data.materials.new('ANIM stone'); mat.diffuse_color=(.23,.25,.29,1)
stone.data.materials.append(mat)
stones=[stone]
for i in range(2):
    extra=stone.copy();extra.data=stone.data.copy();scene.collection.objects.link(extra);stones.append(extra)
caps=[]
capmat=bpy.data.materials.new('ANIM acorn cap');capmat.diffuse_color=(.16,.08,.025,1)
for i in range(3):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1)
    cap=bpy.context.object;cap.scale=(1.26,1.26,.54);cap.data.materials.append(capmat);caps.append(cap)
def props(name,t,w,release_pos):
    projectile=name in ('throw','lob','fan','D','X','H','B')
    fan=name in ('fan','H','B');lob=name in ('lob','D','X')
    for i,obj in enumerate(stones):
        obj.hide_render=not projectile or (i>0 and (not fan or t<.62))
        obj.scale=(2.85,)*3 if lob else (1.71,)*3
        caps[i].hide_render=not fan or obj.hide_render
        if obj.hide_render: continue
        p=w['Arm.R']@Vector((.89,-3.55,1.5))
        if t>=.62:
            seconds=.9 if lob else .7
            alpha=min(1,(t-.62)/seconds)
            destination=Vector((0,2 if lob else 3,24))
            if fan: destination=release_pos+Matrix.Rotation(math.radians((-16,0,16)[i]),3,'Y')@(destination-release_pos)
            p=release_pos.lerp(destination,alpha)+Vector((0,(36 if lob else 3)*alpha*(1-alpha),0))
            obj.hide_render=t-.62>seconds
            caps[i].hide_render=not fan or obj.hide_render
        obj.location=BI@p
        caps[i].location=BI@(p+Vector((0,.912,0)))
bpy.ops.object.text_add(location=(-.35,-.1,12))
alert=bpy.context.object
alert.data.body='!';alert.data.size=2
alert.rotation_euler=(math.pi/2,0,0)
am=bpy.data.materials.new('ANIM warning'); am.diffuse_color=(1,.32,.015,1)
alert.data.materials.append(am)
times={
 'idle':[0,.8,1.4,2.1,2.7,3.7,4.8],
 'patrol':[0,.14,.28,.42,.56,.84,1.12],
 'warn':[0,.12,.26,.5,.84,1.10,1.65],
 'chase':[0,.08,.16,.24,.32,.48,.64],
 'throw':[0,.12,.32,.48,.62,.72,1.4],
 'stun':[0,.06,.2,.4,.68,.94,1.55],
 'celebrate':[0,.18,.32,.48,.65,1.28,1.9],
 'return':[0,.15625,.3125,.46875,.625,.9375,1.25],
}
manifest=dict(times)
for name,clip in DATA['clips'].items():
    if '--clip' in sys.argv and name != sys.argv[sys.argv.index('--clip')+1]: continue
    if '--throw-only' in sys.argv and name!='throw': continue
    if '--previous' in sys.argv and name not in ('throw','chase'): continue
    if name not in times: times[name]=[round(clip['duration']*i/6,4) for i in range(7)]
    if name in ('lob','fan'): times[name]=[0,.16,.34,.50,.62,.71,clip['duration']]
    if name=='slam': times[name]=[0,.18,.38,.64,.80,.89,clip['duration']]
    manifest[name]=times[name]
    projectile = name in ('throw','lob','fan','D','X','H','B')
    release=sample(clip,.62) if projectile else None
    release_world=apply(release) if release else None
    release_pos=(release_world['Arm.R']@Vector((.89,-3.55,1.5))) if release else None
    for i,t in enumerate(times[name]):
        w=apply(sample(clip,t))
        props(name,t,w,release_pos)
        alert.hide_render=name!='warn' or t<.12 or t>1.3
        scene.render.filepath=str(OUT/f'{name}-{i:02d}.png')
        bpy.ops.render.render(write_still=True)
    print('PREVIEW FINISHED',name,flush=True)
    if '--motion' in sys.argv:
        count=max(16,round(clip['duration']*16))
        for i in range(count):
            t=clip['duration']*i/(count if clip['loop'] else count-1)
            w=apply(sample(clip,t))
            alert.hide_render=True
            props(name,t,w,release_pos)
            scene.render.filepath=str(OUT/f'{name}-motion-{i:02d}.png')
            bpy.ops.render.render(write_still=True)
(OUT/'times.json').write_text(json.dumps(manifest,indent=2))
