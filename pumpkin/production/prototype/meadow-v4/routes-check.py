"""Derive endpoint/junction graph from the emitted route centerlines + goal court bounds.
Width-aware endpoint snaps are documented, jump edges are explicit with physical pads.
"""
import json,math,hashlib
from pathlib import Path
P=Path(__file__).parent;out=P.parents[1]/'treasure/map-v4'
s=json.loads((P/'scene.json').read_text());routes=s['routes'];nodes={};cuts={n:[] for n in routes};edges=[]
def node(p,label=None):
    # Shared goal court is a traversable single graph node, not a path termination.
    if abs(p[0])<=24.01 and abs(p[1]+136)<=20 and abs(p[2])<.8:key='PORTAL'
    elif abs(p[0])<.1 and abs(p[1]-108)<.1 and abs(p[2]-48)<.8:key='SUMMIT'
    else:
        key=next((k for k,v in nodes.items() if math.dist(p,v['spec_xzy'])<1),None) or 'N'+str(len(nodes)+1)
    nodes.setdefault(key,{'id':key,'spec_xzy':list(p),'reason':label or ('portal destination' if key=='PORTAL' else 'summit treasure objective' if key=='SUMMIT' else 'route junction')})
    return key
endpoints=[]
for name,r in routes.items():
    for i in [0,len(r['points'])-1]:
        p=r['points'][i];nid=node(p);cuts[name].append((float(i),nid));endpoints.append((name,i,p,nid))
contacts=[]
for name,i,p,nid in endpoints:
    if nid in {'PORTAL','SUMMIT'}:continue
    candidates=[]
    for other,r in routes.items():
        if other==name:continue
        for j,(a,b) in enumerate(zip(r['points'],r['points'][1:])):
            dx,dz=b[0]-a[0],b[1]-a[1];den=dx*dx+dz*dz
            if den<.01:continue
            t=max(0,min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dz)/den));q=[a[k]+(b[k]-a[k])*t for k in range(3)]
            d=math.hypot(p[0]-q[0],p[1]-q[1]);dy=abs(p[2]-q[2])
            if d<=r['width']/2 and dy<=.75:candidates.append((d,other,j+t,q,dy))
    if candidates:
        d,other,t,q,dy=min(candidates)
        cuts[other].append((t,nid));contacts.append({'endpoint_route':name,'endpoint_index':i,'target_route':other,'horizontal_snap':round(d,3),'height_difference':round(dy,3),'node':nid})
# Genuine planar crossings add shared nodes if vertical difference <= support tolerance.
for ni,(name,r) in enumerate(routes.items()):
    for other,rr in list(routes.items())[ni+1:]:
        for i,(a,b) in enumerate(zip(r['points'],r['points'][1:])):
            dx,dz=b[0]-a[0],b[1]-a[1]
            for j,(c,d) in enumerate(zip(rr['points'],rr['points'][1:])):
                ex,ez=d[0]-c[0],d[1]-c[1];den=dx*ez-dz*ex
                if abs(den)<1e-7:continue
                t=((c[0]-a[0])*ez-(c[1]-a[1])*ex)/den;u=((c[0]-a[0])*dz-(c[1]-a[1])*dx)/den
                if not(.001<t<.999 and .001<u<.999):continue
                p=[a[k]+(b[k]-a[k])*t for k in range(3)];y=c[2]+(d[2]-c[2])*u
                if abs(p[2]-y)>.75:continue
                nid=node(p);cuts[name].append((i+t,nid));cuts[other].append((j+u,nid))
for name,cc in cuts.items():
    cc=sorted(set(cc))
    for (a,na),(b,nb) in zip(cc,cc[1:]):
        if b-a<.0001 or (na==nb and name!='ravine_floor_loop'):continue
        edges.append({'id':'E'+str(len(edges)+1),'from':na,'to':nb,'route':name,'kind':'walk','width':routes[name]['width'],'span_indices':[round(a,3),round(b,3)]})
# Three real twelve-stud pads on the ridge, separated by four-stud jump gaps.
pads=[]
for i in range(3):pads.append(node([148,-24-i*16,20+i*2],'optional ridge jump landing'))
for a,b in zip(pads,pads[1:]):edges.append({'id':'E'+str(len(edges)+1),'from':a,'to':b,'route':'ridge_jumps','kind':'jump','gap_studs':4,'rise_studs':2})
degree={k:0 for k in nodes};adj={k:set() for k in nodes}
for e in edges:
    degree[e['from']]+=1;degree[e['to']]+=1;adj[e['from']].add(e['to']);adj[e['to']].add(e['from'])
seen={'PORTAL'};queue=['PORTAL']
while queue:
    for k in adj[queue.pop()]-seen:seen.add(k);queue.append(k)
dead=[k for k,v in degree.items() if v<2 and k not in {'PORTAL','SUMMIT'}];unreachable=sorted(set(nodes)-seen)
report={'state':'PASS' if not dead and not unreachable else 'FAIL','scene_sha256':hashlib.sha256((P/'scene.json').read_bytes()).hexdigest(),'method':'Endpoint-to-centerline snaps <=target half-width and height tolerance0.75; genuine 2D segment intersections with matching height; explicit supported jump pads; portal goal court contracts to one node. Physical full-width clearance independently checked by collision-audit.json. This graph is geometric connectivity, not a Studio locomotion simulation.','node_count':len(nodes),'edge_count':len(edges),'dead_end_count':len(dead),'dead_ends':dead,'unreachable_nodes':unreachable,'nodes':[{**v,'degree':degree[k]} for k,v in nodes.items()],'edges':edges,'endpoint_contacts':contacts}
(out/'routes-graph.json').write_text(json.dumps(report,indent=2))
lines=['# Round 3 route graph check','',f"**{report['state']} — {len(nodes)} nodes, {len(edges)} edges, dead ends = {len(dead)}; unreachable nodes = {len(unreachable)}.**",'',report['method'],'','Coordinates below are source X,Z,Y; Roblox uses X,Y,-Z. Portal and summit are purposeful goals, not dead ends. Ridge gaps are optional jump edges with continuous walked ridge fallback. Floor loop joins one long physical exit ramp; both old isolated recovery lanes are removed.','','## Every node','','| Node | Source X,Z,Y | Degree | Purpose |','|---|---|---:|---|']
for k,v in nodes.items():lines.append(f"| {k} | {', '.join(str(round(x,2)) for x in v['spec_xzy'])} | {degree[k]} | {v['reason']} |")
lines+=['','## Every edge','','| Edge | Nodes | Route | Kind |','|---|---|---|---|']
for e in edges:lines.append(f"| {e['id']} | {e['from']} <-> {e['to']} | {e['route']} | {e['kind']} |")
lines+=['','## Gameplay read','', '- West: retained surface fallback and Hollow Oak landmark;14-wide cave trunk plus south branch, two exits joined to existing graph.', '- Tunnel: mud, telegraphed knock-drop rocks, escalating rumble and one predicted surface Keeper intercept; balance rates/timing ESTIMATED until Studio.', '- Bridge: open timber deck and twin amber beacons over a 32-stud gorge; losing the acorn costs the long walkout.', '- East: high ridge, Split Spire landmark, optional three-pad jump sequence with walked fallback.', '', '## Evidence and limitations','',f"Scene SHA256: `{report['scene_sha256']}`. Graph and clearance are machine-derived. Policy/syntax/native artifact checks are recorded separately in TUNNEL-TEST.json. Pickup, real humanoid falling, competing players retrieving the dropped acorn and walking the ramp remain **UNKNOWN in Studio** until a playtest."]
(out/'ROUTES-CHECK.md').write_text('\n'.join(lines)+'\n')
print(json.dumps({k:v for k,v in report.items() if k not in ['nodes','edges','endpoint_contacts','method']},indent=2))
if dead or unreachable:raise SystemExit(1)

