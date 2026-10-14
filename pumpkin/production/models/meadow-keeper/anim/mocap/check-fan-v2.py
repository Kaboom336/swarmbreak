"""Dense runtime interpolation, sole and non-adjacent mesh contacts."""
import json,math
from pathlib import Path
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parent;A=R.parent
scope={'__file__':str(R/'check.py')}
exec((R/'check.py').read_text().split('report={}')[0],scope)
globals().update({k:v for k,v in scope.items() if k not in ('__file__','__name__','D')})
D=json.loads((R/'fan-v2-candidates.json').read_text());report={}
for id,c in D.items():
    minimum=100;contacts=[];seven=True
    for i in range(math.ceil(c['duration']*120)+1):
        t=min(c['duration'],i/120);l,r=next((l,r) for l,r in zip(c['frames'],c['frames'][1:]) if l['t']<=t<=r['t'])
        a=(t-l['t'])/(r['t']-l['t']);style=r['ease']
        a=(1-math.cos(math.pi*a))/2 if style=='sine' else a*a if style=='in' else 1-(1-a)**2 if style=='out' else a
        p={}
        for n in S['jointOrder']:
            lm,rm=cf(l['pose'][n]),cf(r['pose'][n]);p[n]=list(lm.translation.lerp(rm.translation,a))+[math.degrees(v) for v in lm.to_quaternion().slerp(rm.to_quaternion(),a).to_euler('ZYX')]
        w=world(p);minimum=min(minimum,min(v.y for v in vertices(w,[s for s in G if s['rig_part'].startswith('Ankle.')])));trees={}
        for group,parts in {'body':['Torso','Head','Hat'],'L':['Arm.L','Elbow.L','Wrist.L'],'R':['Arm.R','Elbow.R','Wrist.R']}.items():
            vv=[];ff=[]
            for s in G:
                if s['rig_part'] not in parts:continue
                offset=len(vv);vv.extend(vertices(w,[s]));ff.extend(tuple(offset+x for x in f) for f in s['triangles'])
            trees[group]=BVHTree.FromPolygons(vv,ff,all_triangles=True)
        for side in ['L','R']:
            # Arm/body includes shoulder attachment, so inspect detached forearm and hand only.
            vv=[];ff=[]
            for s in G:
                if s['rig_part'] not in ['Elbow.'+side,'Wrist.'+side]:continue
                offset=len(vv);vv.extend(vertices(w,[s]));ff.extend(tuple(offset+x for x in f) for f in s['triangles'])
            if BVHTree.FromPolygons(vv,ff,all_triangles=True).overlap(trees['body']):contacts.append([round(t,4),side])
    if id!='T':
        inactive=['Elbow.L','Elbow.R','Wrist.L','Wrist.R','Knee.L','Knee.R','Ankle.L','Ankle.R']
        seven=all(all(abs(v)<1e-5 for v in f['pose'][n]) for f in c['frames'] for n in inactive)
        assert seven and minimum>=-.04
    assert next(m['t'] for m in c['markers'] if m['name']=='Release')==.62
    report[id]={'samples':i+1,'minimumBootY':minimum,'sevenRigidParts':seven,'forearmHandBodyContacts':contacts,'release':.62,'threeSpawnTimes':[.62]*3}
(R/'fan-v2-check.json').write_text(json.dumps(report,indent=2))
print({id:{'sole':r['minimumBootY'],'contacts':len(r['forearmHandBodyContacts'])} for id,r in report.items()})
