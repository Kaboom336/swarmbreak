"""Original HOME-only mesh skins; reuse approved local artlib, Crow and acorn.
Outputs are generated assets, never source edits. Run with Blender background.
"""
import sys, json, math
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'models/golden-acorn/blender'))
import artlib as a
import bpy
import bmesh
OUT = Path(__file__).resolve().parent
PALETTE = dict(PortalGreen='38EF92', Orange='EF791D', DarkOrange='C44B15', Cream='FFF1CE', Ink='151321',
              Tongue='EC739A', Green='429C24', Leaf='66B62E', Lime='80C63A',
              Wood='B67438', Stone='B4ADA0', Path='CBB49D', Slate='677782', Grass='76BA3F', GrassLight='84C64C', PortalLight='B0FFFF', Cyan='26E9FF', Snow='F3FAFF', Sand='F5D68A', DarkWood='854319', DarkRock='494350', Crystal='AC4DE9', Lava='FF6515', LampLight='FFE77D', PinkStone='D7B9AE')
a.init(PALETTE)
def box(n, xyz, size, mat, bevel=.06):
    # Author in Roblox Y-up/+Z-front coordinates; artlib expects Blender basis.
    x,y,z=xyz; w,h,d=size
    return a.box(n,(x,-z,y),(w,d,h),mat,bevel)
def export(obs):
    sections=[]
    for mat,h in PALETTE.items():
        vs=[]; ts=[]
        for o in obs:
            if o.data.materials[0] != a.M[mat]: continue
            off=len(vs)
            for v in o.data.vertices:
                p=o.matrix_world@v.co; vs.append([round(p.x,6),round(p.z,6),round(-p.y,6)])
            o.data.calc_loop_triangles()
            ts.extend([[off+i for i in t.vertices] for t in o.data.loop_triangles])
        if vs: sections.append(dict(name=mat,color=[int(h[i:i+2],16) for i in (0,2,4)],vertices=vs,triangles=ts))
    return sections
# Pup A image is a reference only: new original bevelled mesh, not owner-approved.
box('PupBody',(0,1.25,0),(1.85,1.65,1.45),'Orange',.18)
box('PupHead',(0,2.25,.1),(2.25,1.6,1.65),'Orange',.22)
for x in [-1.12,1.12]:
    box('FloppyEar',(x,1.95,.15),(.45,1.3,.75),'DarkOrange',.15)
for x in [-.58,.58]:
    for z in [-.38,.48]: box('CreamPaw',(x,.24,z),(.5,.48,.65),'Cream',.09)
box('Blaze',(0,2.27,.94),(.44,1.25,.15),'Cream',.05)
for x in [-.38,.38]: box('Muzzle',(x,1.83,1.01),(.76,.48,.4),'Cream',.1)
box('Nose',(0,2.05,1.27),(.43,.27,.2),'Ink',.065)
box('Tongue',(0,1.53,1.12),(.3,.32,.12),'Tongue',.04)
for x in [-.68,.68]:
    box('Eye',(x,2.42,.95),(.43,.45,.14),'Ink',.08)
    box('EyeGlint',(x-.07,2.52,1.03),(.12,.12,.04),'Cream',.025)
box('PumpkinStem',(0,3.18,.05),(.26,.38,.28),'Green',.04)
pup=export(list(a.objects))
for o in list(a.objects): bpy.data.objects.remove(o,do_unlink=True)
a.objects.clear()
# Reuse original local artlib; all new scenery is HOME-only.
sys.path.insert(0,str(OUT))
import decor_builder
def fast_box(n,xyz,size,mat,bevel=0):
    x,y,z=xyz;w,h,d=size
    verts=[(sx*w/2,sz*d/2,sy*h/2) for sx,sz,sy in
           [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    me=bpy.data.meshes.new(n);me.from_pydata(verts,[],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    if bevel:
        bm=bmesh.new();bm.from_mesh(me)
        bmesh.ops.bevel(bm,geom=list(bm.edges),offset=min(bevel,min(size)*.4),segments=1,affect='EDGES')
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    o=bpy.data.objects.new(n,me);bpy.context.collection.objects.link(o)
    o.location=(x,-z,y);me.materials.append(a.M[mat]);a.objects.append(o)
    return o
decor_builder.populate(fast_box)
bpy.context.view_layer.update()
decor=export(list(a.objects))
data=dict(Pup=pup,Decor=decor,
          Crow=json.loads((ROOT/'models/crow/blender/crow_parts.json').read_text()),
          Acorn=json.loads((ROOT/'models/golden-acorn/blender/golden-acorn_parts.json').read_text()),
          OpenAcorn=json.loads((ROOT/'models/golden-acorn/blender/golden-acorn-open_parts.json').read_text()))
(OUT/'assets.json').write_text(json.dumps(data,separators=(',',':')))
print('HOME ASSETS', {k:sum(len(s['triangles']) for s in v) for k,v in data.items()})
