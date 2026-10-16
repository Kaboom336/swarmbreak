"""Tie final visual proof to the exact source installed in the delivered artifact."""
from pathlib import Path
from collections import Counter
import json,hashlib
H=Path(__file__).resolve().parent;ROOT=H.parents[2]
render=json.loads((H/'r2.json').read_text());final=json.loads((H/'deliver.json').read_text())
encode=lambda p:json.dumps(p,sort_keys=True)
for field in ('parts','lights','kits'):assert Counter(map(encode,render[field]))==Counter(map(encode,final[field])),field
source=(ROOT/'prototype/meadow-v4/Section4.luau').read_bytes()
assert source==(H/'r2-Section4.luau').read_bytes()==(H/'deliver-Section4.luau').read_bytes()
out=dict(status='PASS',rendered_R2_parts=len(render['parts']),native_S4_parts=sum(p.get('section')=='S4' for p in render['parts']),all_native_parts_duplicate_sensitive_equal=True,all_light_emitters_equal=True,all_existing_kit_placements_equal=True,rendered_source_equals_delivered_source=True,source_sha256=hashlib.sha256(source).hexdigest(),artifact_sha256=hashlib.sha256((ROOT/'slice-v2/prototype/guardian-greybox.rbxl').read_bytes()).hexdigest(),runtime_mesh_and_renderer_parity='UNKNOWN; see RENDER-LIMITS.md')
(H/'PARITY.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
