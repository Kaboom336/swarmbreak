"""Capture protected files and cave baseline; bind final generated evidence."""
import json, hashlib, sys
from pathlib import Path
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
if sys.argv[1]=='before':
    files=[]
    for folder in [ROOT/'prototype/meadow-v4',ROOT/'treasure/map-v4',ROOT/'prototype/core']:
        files.extend(p for p in folder.rglob('*') if p.is_file())
    files.extend(ROOT.glob('prototype/*guardian*'))
    files.extend(ROOT.glob('prototype/meadow-v4.rbxl'))
    files.extend([HERE/'Cart.server.luau',HERE/'Loop.server.luau',ROOT/'treasure/cave-v2/ROUTES.json'])
    hashes={str(p.relative_to(ROOT)):sha(p) for p in files if p.is_file()}
    (HERE/'ROUND2-PROTECTED.json').write_text(json.dumps(hashes,indent=2))
    for name in ['scene.json','build.luau']:
        (HERE/('round2-baseline-'+name)).write_bytes((HERE/name).read_bytes())
    print('Captured',len(hashes),'protected hashes and cave baseline')
else:
    baseline=json.loads((HERE/'round2-baseline-scene.json').read_text())
    current=json.loads((HERE/'scene.json').read_text())
    hashes=json.loads((HERE/'ROUND2-PROTECTED.json').read_text())
    changed=[p for p,h in hashes.items() if sha(ROOT/p)!=h]
    hooks=lambda s:[p for p in s['parts'] if p['category']=='hook']
    audit=json.loads((HERE/'AUDIT.json').read_text())
    structural=json.loads((HERE/'STRUCTURAL-AUDIT.json').read_text())
    native=json.loads((HERE/'ROUND2-NATIVE-CHECK.json').read_text())
    zero_keys=['floating_collider_parts','cave_24_headroom_hits','green_flight_envelope_hits','red_fall_envelope_hits','track_cart_envelope_hits','floor_ray_missing_hits']
    assert audit['clearance_hits']==0 and audit['unreachable_route_nodes']==0
    assert all(structural[k]==0 for k in zero_keys) and structural['mountain_connected_components']==1
    assert json.loads((HERE/'render-rr2-final-metadata.json').read_text())['manifest_sha256']==sha(HERE/'scene.json')
    final_files=[ROOT/'prototype/cave-v2.rbxl',HERE/'scene.json',HERE/'build.luau',HERE/'render.py',HERE/'audit.py',HERE/'structural-audit.py',HERE/'AUDIT.json',HERE/'STRUCTURAL-AUDIT.json',HERE/'ROUND2-NATIVE-CHECK.json',HERE/'CONCEPT-COMPARE.png',HERE/'render-rr2-final-metadata.json']
    final_files.extend(HERE.glob('build-rr2-*.png'))
    report={'protected_count':len(hashes),'protected_changed':changed,
            'route_dictionaries_equal':baseline['routes']==current['routes'],
            'hooks_equal':hooks(baseline)==hooks(current),'runtime':'UNKNOWN; offline native geometry proof',
            'static_zero_checks':{k:structural[k] for k in zero_keys},'clearance_hits':audit['clearance_hits'],
            'native_check':native,'critic_scores':[4.5,4,5.5],'visual_target_met':False,
            'hashes':{str(p.relative_to(ROOT)):sha(p) for p in final_files}}
    (HERE/'ROUND2-EVIDENCE.json').write_text(json.dumps(report,indent=2))
    assert not changed and report['route_dictionaries_equal'] and report['hooks_equal'],report
    print('PASS protected files, routes and hooks unchanged')
