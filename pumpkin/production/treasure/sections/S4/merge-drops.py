"""Merge disjoint workers executing the unchanged complete N8 drop lattice."""
import json
from pathlib import Path
H=Path(__file__).resolve().parent
reports=[json.loads((H/f'final-DROPS-{i}.json').read_text()) for i in (1,2,3)]
expected=set(reports[0]['allRouteNames']);seen=set()
for i,r in enumerate(reports,1):
 assert r['worker']==i and r['state']=='PASS' and not r['failures']
 assert set(r['allRouteNames'])==expected
 routes=set(r['shardRoutes']);assert not seen&routes;seen|=routes
assert seen==expected
total=sum(r['samples'] for r in reports);assert total==31824
out={'state':'PASS','samples':total,'failures':[],'categories':{},'workers':reports,
 'all_routes_executed_exactly_once':sorted(seen),
 'method':'Same existing production Swap/resolver N8 lattice; route-name ASCII sum modulo 3 partitions routes, without changing a route, segment, eight along-segment samples, three edge offsets or three knock offsets.',
 'Studio':'UNKNOWN'}
(H/'final-DROPS.json').write_text(json.dumps(out,indent=2))
(H/'final-drop-final.log').write_text(f'PASS {total} samples 0 failures; three disjoint complete-route workers; see final-drop-1/2/3.log\n')
print(f'PASS {total} samples 0 failures; {len(seen)} routes, exact disjoint coverage')
