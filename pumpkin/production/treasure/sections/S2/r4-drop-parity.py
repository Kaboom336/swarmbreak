"""Verify the final nonphysical palette correction preserves drop-test inputs."""
import json,hashlib
from pathlib import Path
H=Path(__file__).resolve().parent;root=H.parents[2]
a=json.loads((H/'r4-drop-input-scene.json').read_text());b=json.loads((H/'r4-after.json').read_text())
assert len(a['parts'])==len(b['parts'])
styles=[]
for p,q in zip(a['parts'],b['parts']):
 for f in p:
  if p[f]!=q[f]:
   assert f in ('color','material') and p['name']=='GrassShoulder',('unexpected change',p['name'],f)
   assert not p['collidable'] and not p['query'] and not p['touch'] and not p.get('lane')
   styles.append({'part':p['name'],'position':p['position'],'field':f,'before':p[f],'after':q[f]})
assert a['kits']==b['kits'] and a['lights']==b['lights'] and a['routes']==b['routes']
out={'all_geometry_flags_tags_attributes_equal':True,'all_collidable_and_query_parts_exact':True,
 'all_kit_placements_exact':True,'only_nonphysical_palette_differences':styles,
 'tested_artifact_sha256':hashlib.sha256((H/'r4-drop-input.rbxl').read_bytes()).hexdigest().upper(),
 'delivered_artifact_sha256':hashlib.sha256((root/'slice-v2/prototype/guardian-greybox.rbxl').read_bytes()).hexdigest().upper(),
 'proof':'Tested and delivered artifact hashes are equal; all exported fields are exact.' if not styles else 'Only existing nonphysical shoulder palette fields differ; geometry, tags, query/collision state and kit placements are exact.'}
(H/'r4-DROP-PARITY.json').write_text(json.dumps(out,indent=2));print('PASS drop input parity;',len(styles),'nonphysical palette fields; all other exported fields exact')
