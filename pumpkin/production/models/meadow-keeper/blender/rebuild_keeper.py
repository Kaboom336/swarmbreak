"""Original reference-driven Keeper. Blender -b -P rebuild_keeper.py -- 1..4.
Reuses local artlib, no external models or textures. Front is -Y, height 11.
"""
import bpy, sys, math, json, shutil
from pathlib import Path
from mathutils import Vector, Matrix
sys.path.insert(0,str(Path(__file__).resolve().parent))
import artlib as a
IT=int(sys.argv[-1]) if sys.argv[-1].isdigit() else 4
R=a.ROOT; (R/'renders').mkdir(exist_ok=True)
a.init({'Skin':'F4DCA3','Shirt':'805033','ShirtLight':'94603D','Seam':'68402B',
 'Overalls':'4D783D','Pocket':'577F43','Straw':'E7AF4D','StrawLight':'F6C768',
 'StrawEdge':'BD8336','HatBand':'476B35','Boots':'553A2B','BootEdge':'684731',
 'Gloves':'DFA63D','Cuff':'F8E5B5','Ink':'24241F','Buttons':'F2C763'})
if IT>=3:
 # Refine the palette only after the first two reference comparisons.
 for name,h in {'Skin':'FFE8B8','Shirt':'875234','Overalls':'568342',
                'Pocket':'5D894A','Gloves':'E7AB40',
                **({'Straw':'E2A142','StrawLight':'F2BD58','Overalls':'527E3D'} if IT>=4 else {})}.items():
  a.COLORS[name]=h
  rgb=[int(h[i:i+2],16)/255 for i in (0,2,4)]
  linear=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
  a.M[name].diffuse_color=(*linear,1)
  a.M[name].node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(*linear,1)
groups={}
def group(name,start,pivot):
 obs=a.objects[start:]; bpy.ops.object.select_all(action='DESELECT')
 for o in obs: o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0]; bpy.ops.object.join()
 o=obs[0]; o.name=name
 bpy.context.scene.cursor.location=pivot; bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 groups[name]=o; a.objects[start:]=[o]; o.select_set(False)
 return o

for side in [-1,1]:
 s=len(a.objects); x=side*(1.08 if IT<4 else 1.19)
 a.box('Brown trouser',(x,.08,1.94),(1.83,2.13,2.13),'Shirt',.12)
 a.box('Boot',(x,-.28,.61),(1.99,2.60,1.22),'Boots',.13)
 a.box('Boot top lip',(x,-.18,1.13),(1.98,2.35,.18),'BootEdge',.035)
 a.box('Cream ankle cuff',(x,-.03,1.55),(1.90,2.21,.47),'Cuff',.055)
 group('Leg.L' if side<0 else 'Leg.R',s,(x,0,2.85))
s=len(a.objects); tw=3.85 if IT==1 else (4.10 if IT<4 else 4.44)
a.box('Shirt body',(0,.03,4.74),(tw,2.32,4.10),'Shirt',.15)
if IT>=2:
 for z in [3.55,4.60,5.60,6.55]+([6.13] if IT>=4 else []):
  a.box('Shirt seam',(0,-1.155,z),(tw-.25,.03,.035),'Seam',.006)
 for side in [-1,1]:
  a.box('Side shirt placket',(side*1.91,-1.17,5.35),(.20,.08,2.58),'ShirtLight',.025)
a.box('Overall apron hem',(0,-.27,3.09),(4.04 if IT<4 else 4.30,2.00,1.22),'Overalls',.09)
a.box('Overall bib',(0,-1.25,4.55),(3.38 if IT<4 else 3.78,.29,2.72),'Overalls',.07)
for side in [-1,1]:
 x=side*(1.33 if IT<4 else 1.47); sw=.53 if IT<4 else .64
 a.box('Front strap',(x,-1.20,6.12),(sw,.27,1.85),'Overalls',.04)
 a.box('Shoulder strap',(x,.02,6.75),(sw,2.35,.22),'Overalls',.04)
 a.box('Back strap',(x,1.19,5.52),(sw,.24,2.40),'Overalls',.04)
 a.box('Square brass button',(x,-1.43,5.46),(.45,.13,.44),'Buttons',.045)
 if IT>=2:
  a.box('Hip utility pocket',(side*1.80,-.39,3.22),(.51,1.46,.86),'Pocket',.06)
  a.box('Hip pocket lip',(side*1.82,-.39,3.65),(.57,1.52,.14),'Overalls',.025)
a.box('Chest patch pocket',(0,-1.45,4.32),(2.08,.19,1.78),'Pocket',.045)
if IT>=2:
 a.box('Pocket top seam',(0,-1.56,5.16),(2.01,.055,.12),'Overalls',.015)
 for side in [-1,1]:
  a.box('Pocket side seam',(side*.96,-1.56,4.30),(.045,.03,1.52),'Overalls',.005)
 a.box('Pocket bottom seam',(0,-1.56,3.49),(1.96,.03,.045),'Overalls',.005)
a.box('Rear overall panel',(0,1.25,4.32),(3.50,.25,2.53),'Overalls',.07)
group('Torso',s,(0,0,2.84))
for side in [-1,1]:
 s=len(a.objects); aw=1.69 if IT==1 else (1.91 if IT<4 else 2.00); x=side*(tw/2+aw/2-.08)
 a.box('Broad shoulder sleeve',(x,0,5.42),(aw,2.27,2.84),'Shirt',.16)
 if IT>=2:
  a.box('Shoulder cap',(x,-.015,6.62),(aw-.10,2.19,.39),'ShirtLight',.10)
  for z in [5.04,5.73]:
   a.box('Sleeve seam',(x,-1.14,z),(aw-.12,.035,.033 if IT<4 else .05),'Seam',.006)
  if IT>=4:
   a.box('Sleeve seam notch',(x+side*.30,-1.165,5.07),(.075,.033,.10),'Seam',.01)
 a.box('Cream rolled cuff',(x,-.015,3.98),(aw+.13,2.42,.65),'Cuff',.075)
 a.box('Gold work mitten',(x,-.065,3.09),(aw-.08,2.03,1.28),'Gloves',.14)
 if IT>=3:
  a.box('Mitten thumb',(x-side*.72,-.42,3.26),(.43,1.15,.79),'Gloves',.095)
 group('Arm.L' if side<0 else 'Arm.R',s,(side*(tw/2+.02),0,6.58))
s=len(a.objects); hw=3.82 if IT==1 else 4.12
hh=2.40 if IT<3 else (2.56 if IT<4 else 2.35); hz=7.96 if IT<3 else (7.92 if IT<4 else 8.00)
a.box('Big square head',(0,-.07,hz),(hw,2.89,hh),'Skin',.13 if IT<3 else .18)
for side in [-1,1]:
 x=side*(.68 if IT<3 else .77)
 a.box('Simple dark eye',(x,-1.547,8.05),(.45 if IT<3 else .57,.065,.68 if IT<3 else .80),'Ink',.025)
 a.box('Stern brow',(x,-1.59,8.53),(.91,.09,.15),'Seam',.026,rot=(0,-side*(.12 if IT==1 else .20),0))
if IT>=3: a.box('Firm mouth',(0,-1.555,7.36),(.59,.045,.055),'Seam',.012)
group('Head',s,(0,0,6.70))
s=len(a.objects); bw=3.31 if IT==1 else (3.58 if IT<4 else 3.77); bd=2.08 if IT<3 else 2.25; cut=.43
outline=[(-bw+cut,-bd),(bw-cut,-bd),(bw,-bd+cut),(bw,bd-cut),(bw-cut,bd),(-bw+cut,bd),(-bw,bd-cut),(-bw,-bd+cut)]
verts=[]
profile=([(.97,9.12),(1,9.24),(1,9.45),(.96,9.51)] if IT<4 else
         [(.56,9.14),(1,9.03),(1,9.37),(.56,9.52)] if IT==4 else
         [(.56,9.22),(1,8.93),(1,9.35),(.56,9.56)])
for scale,z in profile:
 verts.extend((x*scale,y*scale,z) for x,y in outline)
faces=[tuple(range(7,-1,-1)),tuple(range(24,32))]
for k in range(3):
 for j in range(8): faces.append((k*8+j,k*8+(j+1)%8,(k+1)*8+(j+1)%8,(k+1)*8+j))
brim=a.mesh('Cut corner straw brim',verts,faces,'Straw')
brim.data.materials.append(a.M['StrawLight']); brim.data.materials.append(a.M['StrawEdge'])
for p in brim.data.polygons:
 if p.index==1 or p.index>=18: p.material_index=1
 elif p.index<10: p.material_index=2
a.box('Lower straw crown',(0,.09,9.80),(3.13,2.73,.79),'Straw',.11)
a.box('Wide green hat band',(0,.09,9.68),(3.24,2.83,.50),'HatBand',.06)
a.box('Upper straw crown',(0,.09,10.30),(2.60,2.28,.64),'StrawLight',.08)
a.box('Crown cap',(0,.09,10.79),(1.93,1.78,.40),'Straw',.06)
if IT>=2:
 for side in [-1,1]:
  for x in [1.65,2.64]:
   a.box('Front brim crease',(side*x,-bd*.985 if IT<4 else -bd-.012,9.355 if IT<4 else 9.21),(.035 if IT<4 else .065,.035,.18 if IT<4 else .27),'StrawEdge',.003)
  a.box('Band join',(side*1.08,-1.335,9.70),(.045,.035,.41),'Seam',.004)
if IT>=3:
 for z,w,d in [(10.12,2.60,2.28),(10.44,2.60,2.28),(10.72,1.93,1.78)]:
  a.box('Crown straw course',(0,.09-d/2-.009,z),(w-.20,.024,.027),'Straw',.003)
group('Hat',s,(0,0,9.18))
bpy.context.view_layer.update(); obs=list(groups.values())
pts=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
fac=11/(max(p.z for p in pts)-min(p.z for p in pts))
for o in obs: o.location*=fac; o.scale*=fac
bpy.context.view_layer.update()
for o in obs:
 for p in o.data.polygons: p.use_smooth=True
 bpy.context.view_layer.objects.active=o
 mod=o.modifiers.new('Weighted broad faces','WEIGHTED_NORMAL'); mod.keep_sharp=True; mod.weight=40
 bpy.ops.object.modifier_apply(modifier=mod.name)
for m in a.M.values():
 p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Roughness'].default_value=.57; p.inputs['Coat Weight'].default_value=.06
c=a.stage(11); scene=bpy.context.scene; scene.eevee.taa_render_samples=48
scene.render.resolution_x=1000; scene.render.resolution_y=1000; scene.view_settings.exposure=-.65 if IT<3 else -.45
for tag,front in [('front',True),('34',False)]: a.render(R/'renders'/f'redo{IT}-{tag}.png',c,11,front,scale=14.1)
bpy.ops.wm.save_as_mainfile(filepath=str(R/f'redo{IT}.blend'))
(R/'renders'/f'redo{IT}-stats.json').write_text(json.dumps(a.stats(obs),indent=2))
if IT>=4:
 a.export('meadow-keeper',obs)
 bpy.ops.wm.save_as_mainfile(filepath=str(R/'meadow-keeper.blend'))
 for tag in ['front','34']: shutil.copyfile(R/'renders'/f'redo{IT}-{tag}.png',R/f'final-{tag}.png')
 rest={o.name:o.matrix_world.copy() for o in obs}
 for name,axis,angle in [('Arm.R','Y',-2.02 if IT==4 else -1.75),('Arm.L','X',-.40 if IT==4 else -.55),('Head','Z',-.08),('Hat','Z',-.08)]:
  o=groups[name]; p=o.location.copy()
  o.matrix_world=Matrix.Translation(p)@Matrix.Rotation(angle,4,axis)@Matrix.Translation(-p)@o.matrix_world
 waist=groups['Torso'].location.copy()
 windup=Matrix.Translation(waist)@Matrix.Rotation(-.14,4,'Z')@Matrix.Rotation(.10 if IT==4 else .20,4,'X')@Matrix.Translation(-waist)
 for name in ['Torso','Head','Hat','Arm.L','Arm.R']: groups[name].matrix_world=windup@groups[name].matrix_world
 groups['Leg.L'].location.y-=.32; groups['Leg.R'].location.y+=.22
 if IT>=5:
  for name,angle,dx in [('Leg.L',-.16,-.18),('Leg.R',.12,.18)]:
   o=groups[name]; p=o.location.copy()
   o.matrix_world=Matrix.Translation(p)@Matrix.Rotation(angle,4,'X')@Matrix.Translation(-p)@o.matrix_world
   o.location.x+=dx
   bpy.context.view_layer.update()
   o.location.z-=min((o.matrix_world@v.co).z for v in o.data.vertices)
 bpy.context.view_layer.update()
 hand=rest['Arm.R'].inverted()@Vector(((tw/2+aw/2-.08)*fac,-1.62*fac,2.65*fac)); pos=groups['Arm.R'].matrix_world@hand
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.70,location=pos)
 rock=bpy.context.object; rock.name='STUDIO throwing stone - excluded from export'
 rockmat=bpy.data.materials.new('STUDIO stone'); rockmat.diffuse_color=(.23,.25,.29,1); rock.data.materials.append(rockmat)
 a.render(R/'final-throw.png',c,11,False,scale=15.7,target=(0,0,5.9))
 bpy.ops.wm.save_as_mainfile(filepath=str(R/'meadow-keeper-throw.blend'))
 for o in obs: o.matrix_world=rest[o.name]
 bpy.context.view_layer.update()
print('KEEPER REDO ROUND',IT,a.stats(obs),flush=True)
