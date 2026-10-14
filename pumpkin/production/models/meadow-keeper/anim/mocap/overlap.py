"""Dense non-adjacent limb/body triangle audit; report contacts, never hide failures."""
import bpy,json,math
from pathlib import Path
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parent;A=R.parent
scope={'__file__':str(A/'render.py')}
exec((A/'render.py').read_text().split('times={')[0],scope)
G=json.loads((A/'throw-geometry.json').read_text());S=scope['SK'];V=scope['Vector'];piv=scope['pivots']
D=json.loads((R/'selected.json').read_text());report={}
for name in ['chase','lob','fan','slam']:
    c=D['clips'][name];contacts=[]
    for i in range(math.ceil(c['duration']*120)+1):
        t=min(c['duration'],i/120);w=scope['apply'](scope['sample'](c,t));trees={}
        for joint in ['Torso','Head','Hat','Elbow.L','Elbow.R','Wrist.L','Wrist.R','Knee.L','Knee.R','Ankle.L','Ankle.R']:
            vv=[];ff=[]
            for s in G:
                if s['rig_part']!=joint:continue
                offset=len(vv);vv.extend(w[joint]@(V(v)-piv[joint]) for v in s['vertices']);ff.extend(tuple(offset+x for x in f) for f in s['triangles'])
            trees[joint]=BVHTree.FromPolygons(vv,ff,all_triangles=True)
        for limb in ['Elbow.L','Elbow.R','Wrist.L','Wrist.R','Knee.L','Knee.R','Ankle.L','Ankle.R']:
            for body in ['Torso','Head','Hat']:
                if trees[limb].overlap(trees[body]):contacts.append([round(t,4),limb,body])
    report[name]={'samples':i+1,'nonAdjacentLimbBodyContacts':contacts}
(R/'overlap-check.json').write_text(json.dumps(report,indent=2))
print({n:len(r['nonAdjacentLimbBodyContacts']) for n,r in report.items()})
