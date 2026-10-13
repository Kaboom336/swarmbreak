import sys,math,shutil,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import artlib as a
import bpy
from mathutils import Matrix,Vector
IT=int(sys.argv[-1]) if sys.argv[-1].isdigit() else 1
ROUND=IT; IT=min(IT,3)
R=a.ROOT; (R/'renders').mkdir(exist_ok=True)
a.init({'GoldenShell':'F5BA35','CapBrown':'85512E','StemBrown':'59351F'})
# One low-sided tapered nut silhouette; no piled spheres. Broad shoulder beneath a flared cap.
width=[.92,1.08,1.05][IT-1]
profile=[(.30,.0),(.56,.15),(.91,.56),(width,1.35),(width,1.94)]
if IT>=2: profile=[(.27,0),(.54,.18),(.90,.62),(width,1.36),(width*.95,1.94)]
nut=a.rings('Shell • closed',profile,'GoldenShell',12)
capprofile=[(width+.14,1.91),(width+.17,2.19),(width+.03,2.46),(.68,2.62),(.34,2.68)]
if IT==3: capprofile=[(width+.09,1.91),(width+.16,1.98),(width+.16,2.17),(width+.01,2.43),(.67,2.60),(.34,2.68)]
cap=a.rings('Cap • popped lid',capprofile,'CapBrown',12)
stem=a.box('Stem • short angled brick',(.04,0,2.815),(.28,.29,.37),'StemBrown',.035,rot=(0,-.13,0))
# Exact 3-stud closed height, including the tilted stem.
bpy.context.view_layer.update(); zs=[(o.matrix_world@v.co).z for o in a.objects for v in o.data.vertices]
factor=3/max(zs)
for o in a.objects: o.location*=factor; o.scale*=factor
bpy.context.view_layer.update()
closed=list(a.objects)
c=a.stage(3)
for tag,front in [('front',True),('34',False)]: a.render(R/'renders'/f'iter{ROUND}-{tag}.png',c,3,front)
bpy.ops.wm.save_as_mainfile(filepath=str(R/f'iter{ROUND}.blend'))
if IT==3:
    a.export('golden-acorn',closed); bpy.ops.wm.save_as_mainfile(filepath=str(R/'golden-acorn.blend'))
    for tag in ['front','34']: shutil.copyfile(R/'renders'/f'iter{ROUND}-{tag}.png',R/f'final-{tag}.png')
closedstats=a.stats(closed)
# Reveal meshes have real inner walls and solid rims; both halves are individually closed surfaces.
nut.hide_render=True; nut.hide_set(True)
halves=[]
for side in [-1,1]:
    n=7; angles=[-math.pi/2+j*math.pi/(n-1) for j in range(n)]
    outer=profile; inner=[(max(.12,r-.105),z+.10 if k==0 else z) for k,(r,z) in enumerate(profile)]
    v=[]
    for prof in [outer,inner]:
        for r,z in prof:
            for ang in angles: v.append((side*r*math.cos(ang)*factor,r*math.sin(ang)*factor,z*factor))
    K=len(profile); off=K*n; f=[]
    for k in range(K-1):
        for j in range(n-1):
            q=(k*n+j,k*n+j+1,(k+1)*n+j+1,(k+1)*n+j); f+=[q,tuple(off+i for i in reversed(q))]
    for k in [0,K-1]:
        for j in range(n-1): f.append((k*n+j,k*n+j+1,off+k*n+j+1,off+k*n+j))
    for j in [0,n-1]:
        for k in range(K-1): f.append((k*n+j,(k+1)*n+j,off+(k+1)*n+j,off+k*n+j))
    o=a.mesh(('Left' if side<0 else 'Right')+' shell half • hollow',v,f,'GoldenShell')
    o.rotation_euler.y=side*([.35,.55,.70][IT-1]); o.location.x=side*[.65,.85,1.0][IT-1]; o.location.y=-.30
    if ROUND>=4: o.rotation_euler.z=side*.52
    bpy.context.view_layer.update(); bottom=min((o.matrix_world@vert.co).z for vert in o.data.vertices); o.location.z-=bottom
    halves.append(o)
for o in [cap,stem]: o.location.z+=.78; o.location.y+=.26
bpy.context.view_layer.update()
opened=halves+[cap,stem]
for tag,front in [('front',True),('34',False)]: a.render(R/'renders'/f'iter{ROUND}-open-{tag}.png',c,3,front,scale=6.4,target=(0,0,1.8))
openstats=a.stats(opened)
if IT==3:
    # Remove the closed shell from the open .blend while retaining named component meshes.
    bpy.data.objects.remove(nut,do_unlink=True)
    a.export('golden-acorn-open',opened); bpy.ops.wm.save_as_mainfile(filepath=str(R/'golden-acorn-open.blend'))
    for tag in ['front','34']: shutil.copyfile(R/'renders'/f'iter{ROUND}-open-{tag}.png',R/f'final-open-{tag}.png')
(R/'renders'/f'iter{ROUND}-stats.json').write_text(json.dumps({'closed':closedstats,'open':openstats},indent=2))
print('ACORN ROUND',ROUND,'CLOSED',closedstats,'OPEN',openstats,flush=True)
