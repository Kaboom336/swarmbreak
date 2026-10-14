"""Explicit centerline surface-contact classification; entrance plus exactly2 mouths.
This is geometric graph evidence, not continuous-body/Studio egress simulation.
"""
import json,math
from pathlib import Path
H=Path(__file__).parent;O=H.parents[1]/'treasure/map-v4'
g=json.loads((O/'routes-graph.json').read_text());nodes={n['id']:n for n in g['nodes']};routes={k:set() for k in nodes}
for e in g['edges']:routes[e['from']].add(e['route']);routes[e['to']].add(e['route'])
centers={'entrance':[-76,27,0],'near':[-76,-78,0],'south':[-61.8671875,-98.953125,0]};contacts=[];seen=set();extra=[]
for key,names in routes.items():
 if not(any(n.startswith('tunnel_') for n in names) and any(not n.startswith('tunnel_') for n in names)):continue
 p=nodes[key]['spec_xzy'];mouth=min(centers,key=lambda n:math.dist(p,centers[n]));distance=math.dist(p,centers[mouth])
 row={'point':p,'routes':sorted(names),'cluster':mouth if distance<=1 else 'EXTRA','distance_to_cluster':distance};contacts.append(row)
 if distance>1:extra.append(row)
 else:seen.add(mouth)
report={'state':'PASS' if not extra and seen==set(centers) else 'FAIL','scene_sha256':g['scene_sha256'],'method':'Route graph centerline contacts; endpoint cluster tolerance1stud. Two exits excluding entrance. Full-width static collision audit separate; Studio continuous egress UNKNOWN.','exit_mouth_clusters':len(seen-{'entrance'}),'extra_midbranch_surface_contacts':len(extra),'contacts':contacts}
(O/'TUNNEL-CONTACTS.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2));assert report['state']=='PASS'
