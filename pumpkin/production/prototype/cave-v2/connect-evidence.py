"""Bind deliverables after render, composition and independent visual review."""
from pathlib import Path
import json,hashlib
H=Path(__file__).parent
audit=json.loads((H/'CONNECT-AUDIT.json').read_text());native=json.loads((H/'CONNECT-NATIVE-CHECK.json').read_text());riser=json.loads((H/'CONNECT-RISERS.json').read_text())
assert all(audit['after'][k]==0 for k in ('unconnected','gaps','overlaps'))
assert riser['failed_riser_ends']==0 and riser['main_navigation_components']==1 and riser['cart_landing_connected_to_track']
assert native['collision_geometry_equal'] and native['gameplay_sources_equal'] and native['native_hook_attributes_equal']
camera=json.loads((H/'readable-connect-final-cameras.json').read_text())
assert camera['manifest_sha256']==hashlib.sha256((H/'scene.json').read_bytes()).hexdigest()
files=[H.parent/'cave-v2.rbxl',H/'connect-before.rbxl',H/'connect-before-scene.json',H/'scene.json']
names=['connect-generate.py','connect-art.luau','ConnectArt.server.luau','build.luau','connect-check.luau','connect-audit.py','connect-riser-check.py','connect-render.py','connect-sheet.ps1','CONNECT-KIT.json','CONNECT-PLACED.json','CONNECT-AUDIT.json','CONNECT-ENDS.json','CONNECT-BEFORE-ENDS.json','CONNECT-RISERS.json','CONNECT-NATIVE-CHECK.json','AUDIT.json','STRUCTURAL-AUDIT.json','CONNECT-SHEET.jpg','CONNECT-JOINTS.jpg','CONNECT-BLIND-B.jpg','CONNECT-CRITIC.md','CONNECT-CRITIC-R1.md','connect-r1-joint-5.png','connect-r1-joint-6.png','CONNECT.md','readable-connect-final-cameras.json']
files.extend(H/n for n in names)
for round in ('before','final'):
 for name in ('portal','main-eye','cart-eye','cave-eye','far','top-routes','joint-1','joint-2','joint-3','joint-4','joint-5','joint-6'):files.append(H/f'readable-connect-{round}-{name}.png')
bound={str(p.relative_to(H.parent)):dict(bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in files}
out=dict(joints=audit['after'],before=audit['before'],riser_ends=riser['riser_ends'],native=native,artifacts=bound,studio='UNKNOWN; final look judged in Studio')
(H/'CONNECT-EVIDENCE.json').write_text(json.dumps(out,indent=2));print('PASS: binary, manifest, audit, source, 24 images, sheets and critic hashes bound')
