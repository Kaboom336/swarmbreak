import json,hashlib,importlib.util
from pathlib import Path
H=Path(__file__).parent;O=H.parents[1]/'treasure/map-v4'
spec=importlib.util.spec_from_file_location('pa',H/'placement-audit.py');pa=importlib.util.module_from_spec(spec);spec.loader.exec_module(pa)
for name,file,legacy in [('PLACEMENT','scene.json',False),('LEGACY-BEFORE','round6-baseline-scene.json',True),('LEGACY-AFTER','scene.json',True)]:
 raw=(H/file).read_bytes();r=pa.audit(json.loads(raw),legacy_tunnel_lights=legacy);r['scene_sha256']=hashlib.sha256(raw).hexdigest()
 (O/f'ROUND6-{name}.json').write_text(json.dumps(r,indent=2));print(name,{k:v for k,v in r.items() if isinstance(v,int)},flush=True)
