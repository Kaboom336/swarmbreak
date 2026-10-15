"""Sampled native OBB clearance audit, not Roblox physics or exhaustive navmesh.
Every route is sampled at <= 2 studs with a 4x7 avatar envelope. Decorative
non-colliders and intentional floor seams are excluded, ceilings are included.
"""
import json,math
from pathlib import Path
ROOT=Path(__file__).parent
data=json.loads((ROOT/'scene.json').read_text())
def xyz(a):return [a[0],a[2],-a[1]]
def local(p,q):
 d=[q[i]-p['position'][i] for i in range(3)];r=p['rotation']
 return [sum(r[j*3+i]*d[j] for j in range(3)) for i in range(3)]
def contains(p,q,margin=0):
 v=local(p,q)
 return all(abs(v[i])<p['size'][i]/2+margin for i in range(3))
for p in data['parts']:
 r=p['rotation'];s=p['size'];p['bounds']=[sum(abs(r[i*3+j])*s[j]/2 for j in range(3)) for i in range(3)]
violations=[];samples=0;max_grade=0
for name,route in data['routes'].items():
 if name=='cartRail':continue
 for index,(a,b) in enumerate(zip(route['points'],route['points'][1:])):
  length=math.dist(a,b);run=math.hypot(b[0]-a[0],b[1]-a[1]);grade=math.degrees(math.atan2(abs(b[2]-a[2]),run));max_grade=max(max_grade,grade)
  for j in range(math.ceil(length/2)+1):
   t=j/math.ceil(length/2);center=xyz([a[i]+(b[i]-a[i])*t for i in range(3)]);
   dx,dz=b[0]-a[0],b[1]-a[1];run=max(.001,math.hypot(dx,dz))
   for lateral in (-7,0,7):
    q=[center[0]-dz/run*lateral,center[1],center[2]-dx/run*lateral];samples+=1
    for p in data['parts']:
     if not p['collidable']:continue
     if any(abs(q[i]+(3.5 if i==1 else 0)-p['position'][i])>p['bounds'][i]+(3.5 if i==1 else 2) for i in range(3)):continue
     hit=False
     for y in (3.5,6.8):
      for ox,oz in ((0,0),(2,0),(-2,0),(0,2),(0,-2)):
       if contains(p,[q[0]+ox,q[1]+y,q[2]+oz],-.02):hit=True;break
      if hit:break
     if hit:violations.append({'route':name,'segment':index,'t':round(t,3),'lateral':lateral,'part':p['name'],'position':q});break
   continue
   for p in data['parts']:
    if not p['collidable']:continue
    if any(abs(q[i]+(3.5 if i==1 else 0)-p['position'][i])>p['bounds'][i]+(3.5 if i==1 else 2) for i in range(3)):continue
    # Sample bottom, middle, head and cardinal avatar body envelope.
    hit=False
    for y in (3.5,6.8):
     for dx,dz in ((0,0),(1.8,0),(-1.8,0),(0,1.8),(0,-1.8)):
      if contains(p,[q[0]+dx,q[1]+y,q[2]+dz],-.02):hit=True;break
     if hit:break
    if hit:violations.append({'route':name,'segment':index,'t':round(t,3),'part':p['name'],'position':q});break
# Shared-point graph: every route node must reach an apron endpoint.
graph={}
for name,r in data['routes'].items():
 if name=='cartRail':continue
 for a,b in zip(r['points'],r['points'][1:]):
  aa,bb=tuple(a),tuple(b);graph.setdefault(aa,set()).add(bb);graph.setdefault(bb,set()).add(aa)
seeds=[q for q in graph if abs(q[0]+150)<=24 and abs(q[1]+120)<=20 and q[2]==0]
seen=set(seeds);todo=list(seeds)
while todo:
 q=todo.pop()
 for neighbor in graph[q]-seen:seen.add(neighbor);todo.append(neighbor)
report={'method':'<=2-stud longitudinal samples; lateral avatar centers -7/0/+7 plus cardinal 2 radius at body heights3.5/6.8 =18-stud tested corridor. Against all native collision OBBs. Noncolliders excluded. Footstep seams, full headroom, cart and jump envelopes remain UNKNOWN.','clearance_hits':len(violations),'samples':samples,'maximum_grade_degrees':round(max_grade,2),'unreachable_route_nodes':len(set(graph)-seen),'dead_ends':'0 unreachable graph nodes is connectivity only; physical movement pending','float_clip':'UNKNOWN: geometric support and seam audit pending','violations':violations[:200]}
(ROOT/'AUDIT.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k!='violations'},indent=2))
