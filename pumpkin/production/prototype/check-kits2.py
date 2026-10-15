"""Round-trip every kits2 FBX; verify material boundaries, textures, units and pivots."""
import bpy, json, re, hashlib
from pathlib import Path
from mathutils import Vector
from io_scene_fbx import parse_fbx
root = Path.cwd()
manifest = json.loads((root/'assets/kits2/manifest.json').read_text())
original = json.loads((root/'assets/kits/manifest.json').read_text())
results = []
for e, old in zip(manifest['exports'], original['exports']):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    path = root/e['output']
    tree, version = parse_fbx.parse(str(path))
    def walk(node):
        yield node
        for child in node.elems: yield from walk(child)
    embedded = [p for n in walk(tree) if n.id == b'Content' for p in n.props if isinstance(p, bytes) and p.startswith(b'\x89PNG')]
    textures = { (root/'assets/kits2'/m['texture']).read_bytes() for m in e['meshes'] }
    assert textures <= set(embedded), (path, 'missing embedded palette')
    bpy.ops.import_scene.fbx(filepath=str(path))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    assert len(meshes) == e['meshParts'] == len(e['meshes'])
    assert {o.name for o in meshes} == {m['mesh'] for m in e['meshes']}, (path, 'mesh names')
    points = [o.matrix_world@v.co for o in meshes for v in o.data.vertices]
    lo = Vector(tuple(min(v[i] for v in points) for i in range(3)))
    hi = Vector(tuple(max(v[i] for v in points) for i in range(3)))
    span = [hi.x-lo.x, hi.z-lo.z, hi.y-lo.y]
    assert abs(lo.z)<.002 and abs(hi.x+lo.x)<.002 and abs(hi.y+lo.y)<.002
    assert all(abs(got-want)<.002 for got,want in zip(span,old['sizeStuds'])), (path,'old scale',span,old['sizeStuds'])
    for o in meshes:
        want = next(m for m in e['meshes'] if m['mesh']==o.name)
        assert len(o.data.materials)==1
        assert all(len(p.vertices)==3 and p.material_index==0 for p in o.data.polygons)
        assert len(o.data.polygons)==want['triangles']<10000
        assert o.location.length<.002 and all(abs(s-1)<.00001 for s in o.scale)
        mat = o.data.materials[0]
        assert all(abs(v-w/255)<.003 for v,w in zip(mat.diffuse_color[:3],want['colour'])), (o.name,'palette',list(mat.diffuse_color),want['colour'])
        shader = next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        assert shader.inputs['Base Color'].is_linked, (o.name,'albedo not linked')
        assert shader.inputs['Base Color'].links[0].from_node.type=='TEX_IMAGE'
        assert o.data.uv_layers.active and all(abs(v-.5)<.001 for uv in o.data.uv_layers.active.data for v in uv.uv)
        # TextureID protects exact baked palette from the interim runtime recolour.
        # If Studio drops textures, the existing loader still recognizes leaf/wood/stone.
    results.append(dict(file=e['output'],meshes=len(meshes),triangles=e['triangles'],embeddedPalettes=len(textures)))
assert len(results)==len(original['exports'])==74
pine = next(e for e in manifest['exports'] if e['name']=='Pine_1')
assert {m['sourceMaterial'] for m in pine['meshes']}=={'Bark_NormalTree','Leaves_Pine'}
assert any('trunk_wood' in m['mesh'] for m in pine['meshes'])
(root/'assets/kits2/CHECKS.json').write_text(json.dumps(dict(status='PASS',exports=len(results),
    meshes=sum(e['meshes'] for e in results),studioImport='UNKNOWN: pending Zion bulk import',
    checks=['FBX reimport','exact mesh names and counts','source material partitions','embedded PNG albedo',
    'linked albedo UVs','original scale extents','shared base pivot','triangles under 10k','palette colours','applied transforms'],models=results),indent=2)+'\n')
print('PASS kits2 reimport',len(results),'FBXs',sum(e['meshes'] for e in results),'meshes')
