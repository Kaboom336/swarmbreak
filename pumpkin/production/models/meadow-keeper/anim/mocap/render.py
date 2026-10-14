"""Reuse the inspected Keeper renderer; matched views and props for blind pairs."""
import bpy, json, sys, math
from pathlib import Path
from mathutils import Matrix, Vector
R=Path(__file__).resolve().parent; A=R.parent
source=(A/'render.py').read_text().split('times={')[0]
# __file__ belongs to the reused renderer so its model/geometry paths stay correct.
scope={'__file__':str(A/'render.py'),'__name__':'keeper_preview'}
exec(compile(source,str(A/'render.py'),'exec'),scope)
globals().update({k:v for k,v in scope.items() if k not in ('__file__','__name__')})
OUT=A/'preview'/'mocap';OUT.mkdir(parents=True,exist_ok=True)
scene.render.resolution_x=360;scene.render.resolution_y=360
scene.render.resolution_percentage=100;scene.eevee.taa_render_samples=8
camera.location=(18,-29,16);camera.rotation_euler=(Vector((0,0,7))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=24
for o in stones+caps:o.hide_render=True
alert.hide_render=True
def mat(name,color):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);return m
bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=3,depth=8)
log=bpy.context.object;log.data.materials.append(mat('bark',(.24,.12,.045)))
log.rotation_euler.y=math.pi/2
acorn=bpy.data.objects.new('Readable acorn',None);scene.collection.objects.link(acorn)
acornpieces=[]
for section in json.loads((A.parents[2]/'slice-v2/home-art/assets.json').read_text())['Acorn']:
    mesh=bpy.data.meshes.new(section['name'])
    mesh.from_pydata([tuple(BI@((Vector(v)-Vector((0,2.28,0)))*.5)) for v in section['vertices']],[],section['triangles']);mesh.update()
    obj=bpy.data.objects.new(section['name'],mesh);scene.collection.objects.link(obj);obj.parent=acorn
    obj.data.materials.append(mat(section['name'],tuple(c/255 for c in section['color'])))
    acornpieces.append(obj)
trailmat=mat('Acorn spin trail',(1,.72,.15));trailpieces=[]
for i in range(10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.08)
    obj=bpy.context.object;obj.data.materials.append(trailmat);trailpieces.append(obj)
def logsock(w):
    right,left=hand(w,'R'),hand(w,'L');middle=(right+left)/2
    blend=max(0,min(1,(middle.y-7)/2.6))
    direction=Vector((0,.2+.8*blend,1-.95*blend)).normalized()
    # Cylinder axis X: contacts can slide along its length; radial support is YZ.
    half=(right-left)/2;cross=Vector((0,half.y,half.z))
    if cross.length>.001:direction-=cross.normalized()*direction.dot(cross.normalized())
    return middle+direction.normalized()*math.sqrt(max(0,3**2-cross.length_squared))
def show(kind,t,w,release):
    log.hide_render=kind!='lob' or t<.2 or t>.62
    log.rotation_euler=(0,math.pi/2,0)
    acorn.hide_render=kind!='fan' or t>.62
    for obj in trailpieces:obj.hide_render=True
    if kind=='lob' and not log.hide_render:log.location=BI@logsock(w)
    if kind=='fan' and not acorn.hide_render:acorn.location=BI@hand(w,'R')
    if kind in ('lob','fan') and t>=.62:
        o=log if kind=='lob' else acorn;o.hide_render=False
        u=min(1,(t-.62)/(.9 if kind=='lob' else .7));o.location=BI@(release.lerp(Vector((0,2,24)),u)+Vector((0,(36 if kind=='lob' else 3)*u*(1-u),0)))
        o.rotation_euler.x=(t-.62)*18
        if kind=='fan':
            for i,obj in enumerate(trailpieces):
                past=t-.62-i*.015
                obj.hide_render=past<0
                v=max(0,min(1,past/.7));center=release.lerp(Vector((0,2,24)),v)+Vector((0,3*v*(1-v),0))
                obj.location=BI@(center+Vector((.45*math.cos(past*18),.45*math.sin(past*18),0)))
    for obj in acornpieces:obj.hide_render=acorn.hide_render
    bpy.context.view_layer.update()
old=json.loads((R/'hand-keyed.json').read_text());new=json.loads((R/'candidates.json').read_text())
if '--selected' in sys.argv:new=json.loads((R/'selected.json').read_text())
# The mapping lives in a separate file, withheld from critics.
ids={'lob':('B','A'),'fan':('C','D'),'slam':('F','E'),'chase':('G','H')}
mapping={}
selection=['lob','fan','slam','chase']
if '--extras' in sys.argv:
    selection=['idle','patrol','return','stun','celebrate','warn','dash']
    ids.update({n:(None,n if '--selected' in sys.argv else n+'-candidate') for n in selection})
for kind in selection:
    if '--only' in sys.argv and kind!=sys.argv[sys.argv.index('--only')+1]:continue
    for variant,data in enumerate([old,new]):
        id=ids[kind][variant];mapping[id]={'clip':kind,'recipe':'hand-keyed' if variant==0 else 'library-derived'}
        if kind=='chase' and variant==0 and '--selected' in sys.argv:data=new
        if kind=='chase' and variant==1:data=json.loads((R/'pre-review-candidates.json').read_text())
        if kind=='fan' and variant==1:data=json.loads((R/'pre-review-candidates.json').read_text())
        if id is None:continue
        clip=data['clips'][kind];duration=clip['duration']
        release=logsock(apply(sample(clip,.62))) if kind=='lob' else socket(apply(sample(clip,.62)),kind) if kind=='fan' else None
        times=([0,.2,.46,.55,.62,.71,duration] if kind=='lob' else [0,.2,.46,.55,.62,.71,duration] if kind=='fan' else [0,.18,.38,.64,.8,.89,duration] if kind=='slam' else [duration*i/6 for i in range(7)])
        for i,t in enumerate(times):
            w=apply(sample(clip,t));show(kind,t,w,release)
            scene.render.filepath=str(OUT/f'{id}-pose-{i:02d}.png');bpy.ops.render.render(write_still=True)
        if '--motion' in sys.argv:
            count=max(20,math.ceil(duration*24))
            for i in range(count):
                t=duration*i/(count if clip['loop'] else count-1)
                w=apply(sample(clip,t));show(kind,t,w,release)
                scene.render.filepath=str(OUT/f'{id}-{i:03d}.png');bpy.ops.render.render(write_still=True)
        print('RENDERED',id,flush=True)
    # Reset props before the next category.
    log.hide_render=acorn.hide_render=True
if '--extras' not in sys.argv:(OUT/'blind-map.json').write_text(json.dumps(mapping,indent=2))
