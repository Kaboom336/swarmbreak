"""Whole-lane OBB support/headroom audit, at <=1 stud along and across each lane.
Checks actual source solids, not waypoint assertions. Studio motion remains pending.
"""
import json, math, hashlib
from pathlib import Path
HERE=Path(__file__).resolve().parent
data=json.loads((HERE/'scene.json').read_text())
parts=data['parts']; grid={}
def corners(p):
    r=p['rotation'];s=p['size'];o=p['position']
    return [[o[i]+sum(r[i*3+j]*s[j]*v[j]/2 for j in range(3)) for i in range(3)] for v in [(x,y,z) for x in [-1,1] for y in [-1,1] for z in [-1,1]]]
for i,p in enumerate(parts):
    if not p['collidable']:continue
    c=corners(p)
    for x in range(math.floor(min(v[0] for v in c)/16),math.floor(max(v[0] for v in c)/16)+1):
        for z in range(math.floor(min(v[2] for v in c)/16),math.floor(max(v[2] for v in c)/16)+1):grid.setdefault((x,z),[]).append(i)
def vertical(p,x,z):
    # Inverse orthogonal transform of vertical world ray. Slab intersection yields exact Y interval.
    r=p['rotation'];o=p['position'];s=p['size'];lo=-1000;hi=1000
    for j in range(3):
        origin=r[j]*(x-o[0])+r[3+j]*(-o[1])+r[6+j]*(z-o[2]);d=r[3+j]
        if abs(d)<1e-9:
            if abs(origin)>s[j]/2+.001:return None
        else:
            a=(-s[j]/2-origin)/d;b=(s[j]/2-origin)/d
            lo=max(lo,min(a,b));hi=min(hi,max(a,b))
            if hi<lo:return None
    return lo,hi
violations=[];count=0;slopes=[];route_stats={};actual_heights={};nominal_differences=[]
def sample(name,x,z,y):
    global count
    count+=1;hits=[]
    for i in grid.get((math.floor(x/16),math.floor(-z/16)),[]):
        hit=vertical(parts[i],x,-z)
        if hit:hits.append((hit[0],hit[1],i))
    support=[h for h in hits if abs(h[1]-y)<=.75]
    overhead=[h for h in hits if h[1]>y+.75 and h[0]<y+20 and h[1]>y+.1]
    actual=[h[1] for h in hits if abs(h[1]-y)<=4]
    if actual:
        top=max(actual); actual_heights[(name,round(x,3),round(z,3))]=round(top,3)
        if abs(top-y)>.75: nominal_differences.append({'route':name,'point':[round(x,2),round(z,2)],'nominal':round(y,3),'actual':round(top,3)})
    if not support or overhead:
        if len(violations)<2000:violations.append({'route':name,'point':[round(x,2),round(z,2),round(y,2)],'type':'obstruction' if overhead else 'missing support','parts':[parts[h[2]]['name'] for h in overhead[:4]]})
for name,route in data['routes'].items():
    width=route['width'];length=0;assert width>=12
    for a,b in zip(route['points'],route['points'][1:]):
        dx=b[0]-a[0];dz=b[1]-a[1];dy=b[2]-a[2];run=math.hypot(dx,dz)
        if run<.01:continue
        grade=math.degrees(math.atan(abs(dy)/run));slopes.append({'route':name,'degrees':grade})
        length+=math.hypot(run,dy)
        if grade>25.001:violations.append({'route':name,'type':'grade','degrees':grade})
        n=math.ceil(run);across=math.ceil(width)
        for step in range(n+1):
            t=step/n
            for j in range(across+1):
                side=-width/2+width*j/across
                sample(name,a[0]+dx*t-dz/run*side,a[1]+dz*t+dx/run*side,a[2]+dy*t)
    route_stats[name]={'length_studs':round(length,3),'seconds_at_16_ESTIMATED':round(length/16,3),'width':width}
for name,x,z,y in [('camp',0,108,48),('fork',0,42,0),('ridge',110,-60,20)]:
    for ix in range(-12,13):
        for iz in range(-12,13):sample(name,x+ix,z+iz,y)
report={'state':'PASS' if not violations else 'FAIL','method':'Exact vertical OBB intervals; full width at <=1 stud sample spacing; nominal support tolerance0.75 and 20 stud headroom. Intersecting shoulder/junction slabs remain FAIL even if potentially walkable; Studio motion cannot be inferred. Does not simulate NPC swept bounds or continuous physics.','manifest_sha256':hashlib.sha256((HERE/'scene.json').read_bytes()).hexdigest(),'part_count':len(parts),'sample_count':count,'violation_count_recorded':len(violations),'nominal_surface_difference_count':len(nominal_differences),'max_ramp_degrees':max(s['degrees'] for s in slopes),'routes':route_stats,'violations':violations}
out=HERE.parents[1]/'treasure/map-v4/collision-audit.json';out.write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k not in ['routes','violations']},indent=2))
print(json.dumps(violations[:12],indent=2))
