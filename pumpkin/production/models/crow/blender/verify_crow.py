"""Verify the delivered asset and FBX round-trip without using Studio."""
import bpy, bmesh, json, math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'crow.blend'))
pet=next(c for c in bpy.data.collections if c.name.startswith('CROW'))
report={'source':'Blender 4.5 local checks; Roblox Studio import NOT tested','meshes':[], 'checks':[]}
expected=[]; total=0
for o in pet.objects:
    assert o.type=='MESH'
    assert len(o.modifiers)==0
    assert o.location.length<1e-6, o.name
    assert all(abs(s-1)<1e-6 for s in o.scale)
    assert len(o.data.materials)==1
    assert not any(n.type=='TEX_IMAGE' for n in o.data.materials[0].node_tree.nodes)
    o.data.calc_loop_triangles(); count=len(o.data.loop_triangles); total+=count
    bm=bmesh.new(); bm.from_mesh(o.data)
    assert all(e.is_manifold for e in bm.edges), o.name
    assert all(e.is_contiguous for e in bm.edges), o.name
    volume=bm.calc_volume(signed=True); assert volume>0, (o.name,volume)
    bm.free()
    expected += [o.matrix_world@v.co for v in o.data.vertices]
    report['meshes'].append({'name':o.name,'triangles':count,'signed_volume':volume})
assert total<2500
low=min(v.z for v in expected); high=max(v.z for v in expected)
assert abs(low)<1e-6 and abs(high-3.2)<1e-5
report['blender_triangles']=total; report['height_studs']=high-low
report['head_height_fraction']=(max(v.co.z for v in pet.objects['Rounded brick head'].data.vertices)-min(v.co.z for v in pet.objects['Rounded brick head'].data.vertices))/(high-low)
parts=json.loads((ROOT/'crow_parts.json').read_text())
assert len(parts)==7 and len({tuple(p['color']) for p in parts})==7
assert next(p for p in parts if p['name']=='Pupil')['color']==[17,16,24]
for s in (-1,1):
    white=pet.objects['White eye '+str(s)]
    pupil=pet.objects['Big pupil '+str(s)]
    assert pupil.data.materials[0].name=='Pupil'
    assert abs(pupil.dimensions.x/white.dimensions.x-.55)<1e-6
    assert abs(pupil.dimensions.z/white.dimensions.z-.55)<1e-6
    def center(o):
        return Vector([(max(v.co[i] for v in o.data.vertices)+min(v.co[i] for v in o.data.vertices))/2 for i in range(3)])
    wc,pc=center(white),center(pupil)
    assert pc.z<wc.z and abs(pc.x)<abs(wc.x)
    for name in ('Eye sparkle large ','Eye sparkle tiny '):
        highlight=pet.objects[name+str(s)]; hc=center(highlight)
        assert highlight.data.materials[0].name=='EyeWhite'
        assert hc.y<min(v.co.y for v in pupil.data.vertices)
        # Entire highlight must sit within the pupil silhouette.
        for v in highlight.data.vertices:
            assert ((v.co.x-pc.x)/(pupil.dimensions.x/2))**2+((v.co.z-pc.z)/(pupil.dimensions.z/2))**2<1
json_total=0
for part in parts:
    verts=part['vertices']; triangles=part['triangles']; json_total+=len(triangles)
    edges={}; volume=0
    for a,b,c in triangles:
        assert all(isinstance(i,int) and 0<=i<len(verts) for i in (a,b,c))
        va,vb,vc=[Vector(verts[i]) for i in (a,b,c)]
        assert (vb-va).cross(vc-va).length>1e-10,(part['name'],a,b,c,verts[a],verts[b],verts[c])
        volume+=va.dot(vb.cross(vc))/6
        for u,v in ((a,b),(b,c),(c,a)):
            key=(min(u,v),max(u,v)); edges.setdefault(key,[]).append((u,v))
    assert all(len(v)==2 and v[0]==v[1][::-1] for v in edges.values()),part['name']
    assert volume>0,part['name']
    # Compare the exact material grouping and right-handed Y-up coordinates.
    expected_group=[]
    for o in pet.objects:
        if o.data.materials[0].name==part['name']:
            for v in o.data.vertices:
                p=o.matrix_world@v.co; expected_group.append(Vector((p.x,p.z,-p.y)))
    assert len(expected_group)==len(verts)
    assert max((v-Vector(w)).length for v,w in zip(expected_group,verts))<1e-6
assert json_total==total
report['json_triangles']=json_total
report['checks']+=['3.2 stud height and bottom-centred zero origin','Applied bevels; closed meshes; consistent outside winding',
                  'Seven exact palette colours, one JSON part per colour; no image textures',
                  'Separate #111018 Pupil; 55% width/height, low/inward; two white highlights per pupil',
                  'JSON coordinates match Blender with (x,y,z) -> (x,z,-y); zero-based indices']
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(ROOT/'crow.fbx'),use_anim=False)
fbx=[o for o in bpy.context.scene.objects if o.type=='MESH']
count=0; imported=[]
for o in fbx:
    o.data.calc_loop_triangles(); count+=len(o.data.loop_triangles)
    imported += [o.matrix_world@v.co for v in o.data.vertices]
assert count==total,(count,total)
assert len(imported)==len(expected)
from mathutils.kdtree import KDTree
def largest_nearest_distance(a,b):
    tree=KDTree(len(b))
    for i,v in enumerate(b): tree.insert(v,i)
    tree.balance()
    return max(tree.find(v)[2] for v in a)
error=max(largest_nearest_distance(imported,expected),largest_nearest_distance(expected,imported))
assert error<1e-5,('FBX vertex positions changed',error)
report['fbx_max_position_error_studs']=error
report['fbx_triangles']=count; report['fbx_meshes']=len(fbx)
report['checks'].append('FBX re-import: identical triangle count; vertex positions within 0.00001 studs')
for it in (1,2,3):
    for tag in ('front','34','side','scale'):
        img=bpy.data.images.load(str(ROOT/'renders'/f'iter{it}-{tag}.png'),check_existing=False)
        assert tuple(img.size)==(1024,1024)
        bpy.data.images.remove(img)
report['checks'].append('All twelve iteration renders are 1024 x 1024')
for name in ('final-front.png','final-34.png'):
    img=bpy.data.images.load(str(ROOT/name),check_existing=False)
    assert tuple(img.size)==(1024,1024)
    bpy.data.images.remove(img)
report['checks'].append('Both regenerated final renders are 1024 x 1024')
(ROOT/'validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k!='meshes'},indent=2),flush=True)
