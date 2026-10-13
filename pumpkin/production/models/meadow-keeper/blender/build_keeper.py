import bpy,sys,math,json,shutil
from pathlib import Path
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).resolve().parent))
import artlib as a
IT=int(sys.argv[-1]) if sys.argv[-1].isdigit() else 1
R=a.ROOT; (R/'renders').mkdir(exist_ok=True)
a.init({'Skin':'E8BB75','Shirt':'75472F','Overalls':'477A45','Pocket':'5E9155','Straw':'E7B74F','HatBand':'436D3B','Boots':'483423','Eyes':'FFF3D7','Ink':'292B24','Buttons':'F2D071'})
groups={}
def group(name,start,pivot):
    obs=a.objects[start:]
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs: o.select_set(True)
    bpy.context.view_layer.objects.active=obs[0]; bpy.ops.object.join()
    o=obs[0]; o.name=name
    bpy.context.scene.cursor.location=pivot; bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    groups[name]=o
    a.objects[start:]=[o]
    o.select_set(False)
    return o
# A broad clean farmer silhouette, anatomically grouped, with flat geometric details.
for side in [-1,1]:
    s=len(a.objects); x=side*.97
    a.box('Trouser',(x,0,2.13),(1.60,1.90,2.96),'Overalls',.14)
    a.box('Boot',(x,-.29,.55),(1.78,2.45,1.10),'Boots',.17)
    group('Leg.L' if side<0 else 'Leg.R',s,(x,0,3.45))
s=len(a.objects)
a.box('Shirt body',(0,0,5.20),(3.70,2.12,3.45),'Shirt',.22)
a.box('Overall waist',(0,-.03,3.87),(3.75,2.20,1.10),'Overalls',.15)
a.plate('Bib',[(-1.48,3.89),(1.48,3.89),(1.48,5.80),(1.05,6.06),(-1.05,6.06),(-1.48,5.80)],-1.19,.16,'Overalls',.07)
for side in [-1,1]:
    a.box('Strap',(side*1.19,-1.12,6.10),(.46,.21,1.53),'Overalls',.045)
    a.box('Brass button',(side*1.19,-1.29,5.84),(.26,.12,.27),'Buttons',.045)
a.plate('Pocket',[(-.69,4.67),(0,4.39),(.69,4.67),(.69,5.31),(-.69,5.31)],-1.40,.12,'Pocket',.04)
group('Torso',s,(0,0,3.47))
for side in [-1,1]:
    s=len(a.objects); x=side*2.55
    a.box('Sleeve',(x,0,5.39),(1.49,1.89,2.58),'Shirt',.19,rot=(0,side*.10,0))
    a.box('Rolled cuff',(side*2.65,-.03,4.29),(1.51,1.96,.53),'Straw',.07,rot=(0,side*.10,0))
    a.box('Mitten',(side*2.71,-.02,3.81),(1.36,1.63,1.01),'Skin',.15)
    group('Arm.L' if side<0 else 'Arm.R',s,(side*1.93,0,6.42))
s=len(a.objects)
headw=4.16 if IT==1 else 4.52
a.box('Head block',(0,-.08,8.42),(headw,2.76,3.12),'Skin',.24 if IT==1 else .31)
# White/pupil/glint plates echo the approved Crow's enormous readable eyes.
ex=.93 if IT==1 else 1.04
for side in [-1,1]:
    x=side*ex
    a.eye('Eye white',x,-1.49,8.53,.64 if IT==1 else (.75 if IT==2 else .83),.80 if IT<3 else .88,'Eyes',16)
    a.eye('Pupil',x-side*.06,-1.55,8.48,.31 if IT==1 else .38,.49,'Ink',12)
    a.eye('Glint',x-.12,-1.60,8.69,.115,.14,'Eyes',10)
    a.box('Eyebrow',(x,-1.64,9.19 if IT<3 else 9.29),(1.19,.10,.20),'Shirt',.035,rot=(0,side*.16 if IT<3 else -side*.12,0))
a.box('Nose',(0,-1.61,8.05),(.57,.43,.40),'Skin',.08)
# A slight upturned mouth balances the down-angled brows.
a.plate('Smile',[(-.56,7.64),(-.48,7.52),(0,7.39),(.48,7.52),(.56,7.64),(.40,7.60),(0,7.49),(-.40,7.60)],-1.51,.04,'Ink')
if IT>=2:
    for side in [-1,1]:
        a.box('Straw hair',(side*2.13,-.12,9.02),(.45,2.05,.66),'Straw',.07)
group('Head',s,(0,0,6.80))
s=len(a.objects)
# Single wide chamfered brim and tapered square crown; no stacked sphere hat.
brimw=5.52 if IT==1 else 5.96
a.box('Hat brim',(0,-.02,9.91),(brimw,3.91,.32),'Straw',.14)
if IT<3:
    a.box('Hat crown',(0,.12,10.44),(3.12,2.65,1.12),'Straw',.22)
else:
    verts=[(x,y+.12,z) for rx,ry,z in [(1.56,1.325,9.88),(1.30,1.04,11.0)] for x,y in [(-rx,-ry),(rx,-ry),(rx,ry),(-rx,ry)]]
    a.mesh('Tapered hat crown',verts,[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'Straw',.11)
a.box('Hat band',(0,.12,10.16),(3.17,2.70,.34),'HatBand',.085)
group('Hat',s,(0,0,9.83))
bpy.context.view_layer.update()
# Preserve an exact 11-stud height and meaningful rig pivots.
obs=list(groups.values()); pts=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
fac=11/(max(p.z for p in pts)-min(p.z for p in pts))
for o in obs: o.location*=fac; o.scale*=fac
bpy.context.view_layer.update()
c=a.stage(11)
for tag,front in [('front',True),('34',False)]: a.render(R/'renders'/f'iter{IT}-{tag}.png',c,11,front,scale=14.2)
bpy.ops.wm.save_as_mainfile(filepath=str(R/f'iter{IT}.blend'))
(R/'renders'/f'iter{IT}-stats.json').write_text(json.dumps(a.stats(obs),indent=2))
if IT>=3:
    a.export('meadow-keeper',obs)
    bpy.ops.wm.save_as_mainfile(filepath=str(R/'meadow-keeper.blend'))
    for tag in ['front','34']: shutil.copyfile(R/'renders'/f'iter{IT}-{tag}.png',R/f'final-{tag}.png')
    rest={o.name:o.matrix_world.copy() for o in obs}
    # Wind-up: raised throwing hand above shoulder, opposite arm forward.
    for name,axis,angle in [('Arm.R','Y',-2.18),('Arm.L','X',-.50),('Head','Z',-.10),('Hat','Z',-.10)]:
        o=groups[name]; p=o.location.copy()
        o.matrix_world=Matrix.Translation(p)@Matrix.Rotation(angle,4,axis)@Matrix.Translation(-p)@o.matrix_world
    waist=Vector((0,0,3.47))
    windup=Matrix.Translation(waist)@Matrix.Rotation(-.20,4,'Z')@Matrix.Rotation(.14,4,'X')@Matrix.Translation(-waist)
    for name in ['Torso','Head','Hat','Arm.L','Arm.R']: groups[name].matrix_world=windup@groups[name].matrix_world
    groups['Leg.L'].location.y-=.45; groups['Leg.R'].location.y+=.25
    bpy.context.view_layer.update()
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.58,location=windup@Vector((3.91,-.03,9.29)))
    rock=bpy.context.object; rock.name='REVIEW ONLY - wind-up stone, excluded from exports'
    rockmat=bpy.data.materials.new('STUDIO stone'); rockmat.diffuse_color=(.22,.25,.29,1)
    rock.data.materials.append(rockmat)
    a.render(R/'final-throw.png',c,11,False,scale=15.8,target=(0,0,5.8))
    bpy.ops.wm.save_as_mainfile(filepath=str(R/'meadow-keeper-throw.blend'))
    for o in obs: o.matrix_world=rest[o.name]
    bpy.context.view_layer.update()
print('KEEPER ROUND',IT,a.stats(obs),flush=True)
