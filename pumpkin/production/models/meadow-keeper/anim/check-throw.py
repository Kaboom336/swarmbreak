"""Offline sampled geometry evidence using the same CFrame hierarchy as the renderer."""
import json,math,sys
from pathlib import Path
from mathutils import Matrix,Vector
from mathutils.geometry import closest_point_on_tri
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parent
data=json.loads((R/'clips.json').read_text());sk=json.loads((R/'skeleton.json').read_text());geo=json.loads((R/'throw-geometry.json').read_text())
if '--candidate' in sys.argv:
    key=sys.argv[sys.argv.index('--candidate')+1];variants=json.loads((R/'variants-throw.json').read_text())
    kind='lob' if key in ['K','R'] else 'fan';data['clips'][kind]=variants['clips'][key]
    if kind=='fan':data['clips']['throw']=variants['clips'][key]
def cf(v):return Matrix.Translation(Vector(v[:3]))@Matrix.Rotation(math.radians(v[3]),4,'X')@Matrix.Rotation(math.radians(v[4]),4,'Y')@Matrix.Rotation(math.radians(v[5]),4,'Z')
def sample(c,t):
    a,b=c['frames'][0],c['frames'][-1]
    for i in range(1,len(c['frames'])):
        if t<=c['frames'][i]['t']:a,b=c['frames'][i-1:i+1];break
    u=(t-a['t'])/(b['t']-a['t']);e=b['ease']
    u=(1-math.cos(math.pi*u))/2 if e=='sine' else u*u if e=='in' else 1-(1-u)**2 if e=='out' else u
    p={}
    for n in sk['jointOrder']:
        l,r=cf(a['pose'][n]),cf(b['pose'][n]);m=l.to_quaternion().slerp(r.to_quaternion(),u).to_matrix().to_4x4();m.translation=l.translation.lerp(r.translation,u);p[n]=m
    return p
def world(p):
    w={'Root':Matrix.Identity(4)}
    for n in sk['jointOrder']:
        par=sk['parents'][n];off=Vector(sk['pivots'][n])-(Vector(sk['pivots'][par]) if par!='Root' else Vector())
        w[n]=w[par]@Matrix.Translation(off)@p[n]
    return w
def vertices(w,s):return [w[s['rig_part']]@(Vector(v)-Vector(s['pivot'])) for v in s['vertices']]
for kind in ['lob','fan','throw']:
    c=data['clips'][kind];footmin=math.inf;headmin=math.inf;heldmin=math.inf;surfaceMin=math.inf;support=0;leadMax=0
    worstFoot=0;worstHeld=0
    for i in range(221):
        t=c['duration']*i/220;w=world(sample(c,t));right=w['Wrist.R']@Vector(sk['hand']);left=w['Wrist.L']@Vector(sk['hand'])
        leadMax=max(leadMax,w['Ankle.L'].translation.y-.75)
        center=right
        if kind=='lob':
            half=(right-left)/2;direction=Vector((0,.2,1))
            if half.length>.001:direction-=half.normalized()*direction.dot(half.normalized())
            center=(left+right)/2+direction.normalized()*math.sqrt(max(0,sk['lobRadius']**2-half.length**2))
        for s in geo:
            vs=vertices(w,s)
            if s['rig_part'].startswith(('Ankle.','Knee.','Leg.')):
                vmin=min(v.y for v in vs)
                if vmin<footmin:footmin=vmin;worstFoot=t
            if s['rig_part'] in ['Head','Hat'] and (.20 if kind=='lob' else 0)<=t<.62:
                lo=[min(v[a] for v in vs) for a in range(3)];hi=[max(v[a] for v in vs) for a in range(3)]
                nearest=Vector([max(lo[a],min(hi[a],center[a])) for a in range(3)]);margin=(center-nearest).length-(sk['lobRadius'] if kind=='lob' else 1.2)
                if margin<heldmin:heldmin=margin;worstHeld=t
                for tri in s['triangles']:
                    q=closest_point_on_tri(center,*[vs[j] for j in tri]);sm=(center-q).length-(sk['lobRadius'] if kind=='lob' else 1.2)
                    if sm<surfaceMin:
                        surfaceMin=sm;surfaceWorst=(t,s['name'],tuple(center),tuple(q))
        if kind=='lob' and .20<=t<.62:
            support=max(support,abs((right-center).length-sk['lobRadius']),abs((left-center).length-sk['lobRadius']))
    print('CHECK',kind,'lowest foot surface',round(footmin,3),'at',worstFoot,'held/head conservative AABB margin',round(heldmin,3),'at',worstHeld,'surface margin',round(surfaceMin,3),'two-hand radial deviation',round(support,3))
    print('SURFACE WORST',surfaceWorst)
    intersections=0
    for t in sorted(set([round(c['duration']*i/60,6) for i in range(61)]+[.62])):
        for yaw in ([0] if kind=='lob' else [-.45,0,.45]):
            p=sample(c,t);p['Head']=p['Head']@Matrix.Rotation(yaw,4,'Y');w=world(p)
            headVertices=[];headTriangles=[]
            for s in geo:
                if s['rig_part'] in ['Head','Hat']:
                    off=len(headVertices);headVertices.extend(vertices(w,s));headTriangles.extend([[off+j for j in tri] for tri in s['triangles']])
            headTree=BVHTree.FromPolygons(headVertices,headTriangles,all_triangles=True)
            for s in geo:
                if s['material']=='Gloves':
                    gloveTree=BVHTree.FromPolygons(vertices(w,s),s['triangles'],all_triangles=True)
                    if gloveTree.overlap(headTree):
                        intersections+=1
                        if intersections<=8:print('CONTACT',kind,t,yaw,s['name'])
    print('MESH INTERSECTIONS gloves/head with live yaw samples',kind,intersections)
    assert intersections==0,kind+' glove crosses head/hat mesh'
    assert footmin>=-.01,kind+' sinks through flat ground'
    assert surfaceMin>0,kind+' held prop contacts head/hat'
    assert support<.001,kind+' unsupported heavy prop'
    if kind!='lob':
        print('CHECK planted lead sole maximum height',kind,leadMax)
        assert leadMax<.12,kind+' lead foot loses its brace'
    for f in c['frames']:
        if f['t'] in [.4,.495,.62,.74]:
            w=world({n:cf(v) for n,v in f['pose'].items()});print('KEY',f['t'],'footY',min(v.y for s in geo if s['rig_part'].startswith('Ankle.') for v in vertices(w,s)),'ankle up',tuple(w['Ankle.L'].col[1]),'hands',tuple(w['Wrist.R']@Vector(sk['hand'])),tuple(w['Wrist.L']@Vector(sk['hand'])))
print('PASS sampled throwing meshes, planted fan lead foot, two-hand support and actual triangle clearance; Studio UNKNOWN')
