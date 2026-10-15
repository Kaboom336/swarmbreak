import json,hashlib
from pathlib import Path
H=Path(__file__).parent;R=H.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
scene=json.loads((H/'scene.json').read_text());meta=json.loads((H/'readable-balance-final-cameras.json').read_text())
assert meta['manifest_sha256']==sha(H/'scene.json')
before=json.loads((H/'readable-r3-final-cameras.json').read_text())
assert meta['views']==before['views'],'six camera frames changed'
art=json.loads((H/'BALANCE-ALL-CRYSTAL-AUDIT.json').read_text())
assert not art['new_crystal_margin_hits'] and not art['new_landmark_walkway_body_hits']
audit=json.loads((H/'AUDIT.json').read_text());struct=json.loads((H/'STRUCTURAL-AUDIT.json').read_text())
zero={k:v for k,v in audit.items() if k in ['clearance_hits','unreachable_route_nodes']}
zero.update({k:struct[k] for k in ['floating_collider_parts','cave_24_headroom_hits','green_flight_envelope_hits','red_fall_envelope_hits','track_cart_envelope_hits','floor_ray_missing_hits']})
assert all(v==0 for v in zero.values()) and struct['mountain_connected_components']==1
files=[R/'prototype/cave-v2.rbxl',H/'scene.json',H/'build.luau',H/'balance-art.luau',H/'balance-render.py',H/'balance-check.luau',H/'balance-audit.py',H/'balance-sheet.ps1',H/'balance-evidence.py',H/'BALANCE.md',H/'READABILITY.md',H/'READABLE-SHEET.jpg',H/'BALANCE-BEFORE-AFTER-01.jpg',H/'BALANCE-NATIVE-CHECK.json',H/'BALANCE-ALL-CRYSTAL-AUDIT.json',H/'BALANCE-CRITIC-R1.md',H/'BALANCE-CRITIC-R2.md']
files+=[H/f'readable-balance-final-{v}.png' for v in meta['views']]
report={'native':json.loads((H/'BALANCE-NATIVE-CHECK.json').read_text()),'all_crystal_clearance':art,'same_six_cameras':True,'zero_checks':zero,'mountain_components':1,'camera_metadata':meta,'before_binary_sha256':sha(H/'balance-before.rbxl'),'before_scene_sha256':sha(H/'balance-before-scene.json'),'before_view01_sha256':sha(H/'balance-before-01.png'),'concept_reference_sha256':sha(R/'treasure/cave-v2/concept-v2.1.png'),'hashes':{str(p.relative_to(R)):sha(p) for p in files},'limits':'Offline native-manifest Cycles render; sky, material appearance and illumination approximate Roblox. Top route lines review-only. Studio runtime and measured 3-second new-player navigation UNKNOWN.'}
(H/'BALANCE-EVIDENCE.json').write_text(json.dumps(report,indent=2))
print('PASS same six cameras, source/artifact/render hashes, unchanged protected geometry, all crystal margins and zero static counts')
