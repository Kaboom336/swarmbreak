"""Audit source and exported connected islands; retain baseline mesh fingerprints."""
import bpy, bmesh, json, hashlib, sys
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'crow.blend'))
pet = next(c for c in bpy.data.collections if c.name.startswith('CROW'))
baseline = '--baseline' in sys.argv
def bounds(points):
    return [[round(min(p[i] for p in points),7) for i in range(3)],
            [round(max(p[i] for p in points),7) for i in range(3)]]
objects = {}
for o in pet.objects:
    bm=bmesh.new(); bm.from_mesh(o.data)
    payload = [list(v.co) for v in o.data.vertices], [list(p.vertices) for p in o.data.polygons]
    objects[o.name]={'material':o.data.materials[0].name,
        'hash':hashlib.sha256(json.dumps(payload).encode()).hexdigest(),
        'bounds_blender':bounds([o.matrix_world@v.co for v in o.data.vertices]),
        'closed':all(e.is_manifold and e.is_contiguous for e in bm.edges),
        'volume':bm.calc_volume(signed=True)}
    bm.free()
parts=json.loads((ROOT/'crow_parts.json').read_text())
islands={}
for part in parts:
    verts=part['vertices']; faces=part['triangles']; adjacency=[set() for v in verts]
    edges={}
    for a,b,c in faces:
        for u,v in ((a,b),(b,c),(c,a)):
            adjacency[u].add(v); adjacency[v].add(u)
            edges.setdefault(tuple(sorted((u,v))),[]).append((u,v))
    assert all(len(e)==2 and e[0]==e[1][::-1] for e in edges.values()),part['name']
    unseen=set(range(len(verts))); components=[]
    while unseen:
        start=unseen.pop(); group={start}; todo=[start]
        while todo:
            for neighbor in adjacency[todo.pop()]:
                if neighbor in unseen: unseen.remove(neighbor); group.add(neighbor); todo.append(neighbor)
        fs=[f for f in faces if f[0] in group]
        assert fs, ('unused vertex',part['name'])
        volume=sum(Vector(verts[a]).dot(Vector(verts[b]).cross(Vector(verts[c])))/6 for a,b,c in fs)
        assert volume>0, ('inside-out island',part['name'],volume)
        components.append({'vertices':len(group),'triangles':len(fs),'bounds_y_up':bounds([verts[i] for i in group]),'signed_volume':volume})
    islands[part['name']]=components
assert len(islands['BillFeet'])==3, 'Expected exactly two feet and one beak'
assert len(islands['Pumpkin'])==3, 'Expected cap and two top studs'
assert all(x['bounds_y_up'][0][1]>2.7 for x in islands['Pumpkin'])
assert sum(x['bounds_y_up'][0][1]>1 for x in islands['BillFeet'])==1
report={'objects':objects,'export_islands':islands,
        'orange_result':'BillFeet: exactly two feet and one beak. Pumpkin: cap and two top studs. All islands closed, CCW, positive volume; no unused vertices.'}
if not baseline:
    before=json.loads((ROOT/'fix-baseline.json').read_text())
    changed=[]
    for name,data in before['objects'].items():
        if objects[name]['hash']!=data['hash']: changed.append(name)
    expected={name for name in objects if name.startswith(('White eye','Big pupil','Eye sparkle'))}
    assert set(changed)==expected, changed
    assert all(objects[name]['material']==data['material'] for name,data in before['objects'].items() if not name.startswith('Big pupil'))
    report['changed_meshes']=changed
    report['preserved_meshes']=len(objects)-len(changed)
    assert all(data['closed'] and data['volume']>0 for data in objects.values())
    assert len(islands['Pupil'])==2
    report['studio_duplicate_cause']='UNKNOWN: extra orange piece in supplied capture is absent from both original and fixed Blender/JSON geometry; likely existing Studio geometry (inference).'
(ROOT/('fix-baseline.json' if baseline else 'fix-audit.json')).write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k not in ('objects','export_islands')},indent=2))
print(json.dumps({k:v for k,v in islands.items() if k in ('BillFeet','Pumpkin')},indent=2))
