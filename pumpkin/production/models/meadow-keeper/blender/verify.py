import bpy,bmesh,json,sys,math
from pathlib import Path
from mathutils import Vector,kdtree
R=Path(__file__).resolve().parent
names=['golden-acorn','golden-acorn-open'] if R.parent.name=='golden-acorn' else ['meadow-keeper']
report={}
for name in names:
    parts=json.loads((R/(name+'_parts.json')).read_text()); assert len({p['name'] for p in parts})==len(parts)
    assert {p['rig_part'] for p in parts}=={'Leg.L','Leg.R','Torso','Arm.L','Arm.R','Head','Hat'}
    tris=0; maxerr=0; positive_volume=0; points=[]
    for part in parts:
        verts=[Vector(v) for v in part['vertices']]; points+=verts
        assert len(part['color'])==3 and all(isinstance(c,int) and 0<=c<=255 for c in part['color'])
        for tri in part['triangles']:
            assert len(tri)==3 and min(tri)>=0 and max(tri)<len(verts)
            a,b,c=[verts[i] for i in tri]; assert (b-a).cross(c-a).length>1e-9
            positive_volume+=a.dot(b.cross(c))/6; tris+=1
    assert positive_volume>0
    limit=1500 if name.startswith('golden') else 5000; assert tris<=limit
    bpy.ops.wm.open_mainfile(filepath=str(R/(name+'.blend')))
    model=[o for o in bpy.data.objects if o.type=='MESH' and o.name in {p['rig_part'] for p in parts}]
    assert len(model)==7
    for part in parts:
        p=bpy.data.objects[part['rig_part']].location
        assert (Vector(part['pivot'])-Vector((p.x,p.z,-p.y))).length<1e-5
    meshchecks=[]
    rigcounts={}; rigpivots={}
    for o in model:
        o.data.calc_loop_triangles(); rigcounts[o.name]=len(o.data.loop_triangles)
        rigpivots[o.name]=o.location.copy()
        bm=bmesh.new(); bm.from_mesh(o.data)
        assert all(e.is_manifold for e in bm.edges),o.name
        assert bm.calc_volume(signed=True)>0,o.name
        assert not o.modifiers,o.name
        meshchecks.append({'name':o.name,'closed':True,'positive_volume':True}); bm.free()
        rigparts=[part for part in parts if part['rig_part']==o.name]
        assert sum(len(part['triangles']) for part in rigparts)==rigcounts[o.name]
        localtree=kdtree.KDTree(sum(len(part['vertices']) for part in rigparts))
        idx=0
        for part in rigparts:
            for v in part['vertices']: localtree.insert(Vector(v),idx); idx+=1
        localtree.balance()
        for v in o.data.vertices:
            p=o.matrix_world@v.co
            assert localtree.find(Vector((p.x,p.z,-p.y)))[2]<1e-5,o.name
    source=[o.matrix_world@v.co for o in model for v in o.data.vertices]
    tree=kdtree.KDTree(len(points))
    for i,p in enumerate(points): tree.insert(p,i)
    tree.balance()
    for p in source:
        q=Vector((p.x,p.z,-p.y)); assert tree.find(q)[2]<1e-5
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.fbx(filepath=str(R/(name+'.fbx')))
    imported=[o for o in bpy.context.scene.objects if o.type=='MESH']; assert len(imported)==len(model)
    assert {o.name for o in imported}==set(rigcounts)
    importedtri=0
    for o in imported:
        o.data.calc_loop_triangles(); importedtri+=len(o.data.loop_triangles)
        assert len(o.data.loop_triangles)==rigcounts[o.name]
        assert (o.location-rigpivots[o.name]).length<1e-4,o.name
        for v in o.data.vertices:
            p=o.matrix_world@v.co; err=tree.find(Vector((p.x,p.z,-p.y)))[2]; maxerr=max(maxerr,err)
    assert importedtri==tris,(importedtri,tris); assert maxerr<1e-4,maxerr
    height=max(p.y for p in points)-min(p.y for p in points)
    if name in ['golden-acorn','meadow-keeper']: assert abs(height-(3 if name=='golden-acorn' else 11))<1e-5
    report[name]={'triangles':tris,'limit':limit,'height_studs':height,'rig_material_parts':len(parts),'rig_triangles':rigcounts,'fbx_meshes':len(imported),'rig_pivots_roundtrip':'PASS','fbx_max_position_error_studs':maxerr,'json_basis':'x,z,-y (Y-up, front +Z, determinant +1 preserves CCW)','closed_outward_meshes':meshchecks,'studio_import':'UNTESTED'}
(R/'validation.json').write_text(json.dumps(report,indent=2)); print(json.dumps(report,indent=2),flush=True)
