"""Measure candidate or selected poses; JSON report, no source mutations."""
import json,math,sys
from pathlib import Path
from mathutils import Vector,Matrix
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parent;A=R.parent
D=json.loads((R/('selected.json' if '--selected' in sys.argv else 'candidates.json')).read_text());S=json.loads((A/'skeleton.json').read_text());G=json.loads((A/'throw-geometry.json').read_text())
piv={n:Vector(v) for n,v in S['pivots'].items()}
def cf(v):return Matrix.Translation(Vector(v[:3]))@Matrix.Rotation(math.radians(v[3]),4,'X')@Matrix.Rotation(math.radians(v[4]),4,'Y')@Matrix.Rotation(math.radians(v[5]),4,'Z')
def world(p):
    w={}
    for n in S['jointOrder']:
        par=S['parents'][n];w[n]=(w[par] if par!='Root' else Matrix.Identity(4))@Matrix.Translation(piv[n]-(piv[par] if par!='Root' else Vector()))@cf(p[n])
    return w
def vertices(w,sections):return [w[s['rig_part']]@(Vector(v)-piv[s['rig_part']]) for s in sections for v in s['vertices']]
def socket(w):
    r=w['Wrist.R']@Vector(S['hand']);l=w['Wrist.L']@Vector(S['hand']);m=(r+l)/2
    blend=max(0,min(1,(m.y-7)/2.6));d=Vector((0,.2+.8*blend,1-.95*blend)).normalized();half=(r-l)/2;cross=Vector((0,half.y,half.z))
    if cross.length>.001:d-=cross.normalized()*d.dot(cross.normalized())
    return m+d.normalized()*math.sqrt(max(0,9-cross.length_squared))
report={}
for name,c in D['clips'].items():
    footmin=100;report[name]={};contacts=[]
    checked=list(c['frames'])
    # Every baked key plus regular 120 Hz in-betweens, using runtime easing/slerp.
    for i in range(math.ceil(c['duration']*120)+1):
        t=min(c['duration'],i/120)
        left,right=next((l,r) for l,r in zip(c['frames'],c['frames'][1:]) if l['t']<=t<=r['t'])
        a=(t-left['t'])/(right['t']-left['t']);style=right['ease']
        a=(1-math.cos(math.pi*a))/2 if style=='sine' else a*a if style=='in' else 1-(1-a)**2 if style=='out' else a
        p={}
        for n in S['jointOrder']:
            l,r=cf(left['pose'][n]),cf(right['pose'][n])
            p[n]=list(l.translation.lerp(r.translation,a))+[math.degrees(v) for v in l.to_quaternion().slerp(r.to_quaternion(),a).to_euler('ZYX')]
        checked.append({'t':t,'pose':p})
    for left,right in zip(c['frames'],c['frames'][1:]):
        p={}
        for n in S['jointOrder']:
            a,b=cf(left['pose'][n]),cf(right['pose'][n]);q=a.to_quaternion().slerp(b.to_quaternion(),.5)
            p[n]=list(a.translation.lerp(b.translation,.5))+[math.degrees(v) for v in q.to_euler('ZYX')]
        checked.append({'t':(left['t']+right['t'])/2,'pose':p})
    for f in checked:
        assert set(f['pose'])==set(S['jointOrder'])
        assert all(math.isfinite(v) for p in f['pose'].values() for v in p)
        w=world(f['pose']);footmin=min(footmin,min(v.y for v in vertices(w,[s for s in G if s['rig_part'].startswith('Ankle.')])))
        if name=='lob' and .2<=f['t']<=.62:
            center=socket(w);lv=[center+Vector((x,3*math.cos(i*math.tau/12),3*math.sin(i*math.tau/12))) for x in [-4,4] for i in range(12)]
            faces=[[i,(i+1)%12,12+(i+1)%12,12+i] for i in range(12)]+[list(range(12)),list(range(12,24))]
            logtree=BVHTree.FromPolygons(lv,faces)
            for s in G:
                if s['rig_part'] in ('Head','Hat'):
                    vv=vertices(w,[s]);tree=BVHTree.FromPolygons(vv,s['triangles'],all_triangles=True)
                    if logtree.overlap(tree):contacts.append([f['t'],s['name']])
        if name=='lob' and f['t'] in [.55,.62]:
            center=socket(w);top=max(v.y for v in vertices(w,[s for s in G if s['rig_part'] in ('Head','Hat')]))
            report[name][str(f['t'])]={'logBottom':center.y-3,'headHatTop':top,'overheadMargin':center.y-3-top,'socket':list(center)}
    report[name]['minimumBootY']=footmin
    report[name]['checkedSamples']=len(checked)
    if name=='lob':report[name]['heldLogHeadHatTriangleContacts']=contacts
    assert c['frames'][0]['t']==0 and abs(c['frames'][-1]['t']-c['duration'])<1e-6
    if c['loop']:assert c['frames'][0]['pose']==c['frames'][-1]['pose']
    if name in ('lob','slam','chase','fan'):assert footmin>-.04,(name,footmin)
    if name=='lob':assert not contacts,contacts
(R/('selected-check.json' if '--selected' in sys.argv else 'candidate-check.json')).write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
