"""Bind final built place, manifest, checks, sources and actual proof images."""
import json,hashlib
from pathlib import Path
H=Path(__file__).parent;O=H.parents[1]/'treasure/map-v4'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
scene=sha(H/'scene.json');audit=json.loads((O/'collision-audit.json').read_text());routes=json.loads((O/'routes-graph.json').read_text());test=json.loads((O/'TUNNEL-TEST.json').read_text())
assert audit['manifest_sha256']==routes['scene_sha256']==scene
assert audit['violation_count_recorded']==routes['dead_end_count']==0 and not routes['unreachable_nodes']
contacts=json.loads((O/'TUNNEL-CONTACTS.json').read_text());assert contacts['scene_sha256']==scene and contacts['exit_mouth_clusters']==2 and contacts['extra_midbranch_surface_contacts']==0
files=[H.parent/'meadow-v4.rbxl',H/'scene.json',H/'TunnelPolicy.luau',H/'TunnelController.luau',H/'Links.server.luau',H.parent/'meadow-v4.project.json']
files += [H/'tunnel-build.py',H/'tunnel-render.py',H/'tunnel-test.luau',H/'tunnel-overlay.ps1',O/'TUNNEL.md']
files += [H/'tunnel-contacts.py',O/'TUNNEL-CONTACTS.json']
files += [H/'tunnel_look.py',H/'tunnel-look-sbs.ps1',O/'build-tunnel-sbs.jpg',O/'TUNNEL-LOOK-CRITIC.json']
files += [H/'geometry.py',H/'tunnel-round2-check.py',O/'TUNNEL-ROUND2-CHECK.json',O/'ROUND5-PLACEMENT-TUNNEL-ROUND2.json',O/'TUNNEL-HILL-CRITIC-1.md',O/'TUNNEL-HILL-CRITIC-2.md']
files += [O/'TUNNEL-HILL.md']
files += [O/'TUNNEL-CRITIC.md']
images=[O/('build-rtunnel-eye-tunnel-'+n+'.png') for n in ['entrance','inside','near-exit','south-exit','from-summit']]+[O/'build-top.jpg']
images += [O/'build-rtunnel-tunnel-overview.png']
assert all(p.exists() and p.stat().st_size>10000 for p in images)
render=json.loads((O/'TUNNEL-RENDER-METADATA.json').read_text());assert render['manifest_sha256']==scene,'proof render is stale'
overlay=json.loads((O/'TUNNEL-OVERLAY-METADATA.json').read_text(encoding='utf-8-sig'));assert overlay['scene_sha256']==scene and overlay['render_sha256']==sha(O/'build-rtunnel-tunnel-top.png'),'top overlay is stale'
guardian=H.parents[1]/'slice-v2/prototype/guardian-greybox.rbxl'
geometry=json.loads((O/'TUNNEL-GEOMETRY.json').read_text());assert geometry['guardian_sha256']==sha(guardian)
protected=json.loads((O/'ROUND5-PROTECTED-HASHES.json').read_text(encoding='utf-8-sig'))
before=next(row['Hash'].lower() for row in protected if row['Path'].endswith('guardian-greybox.rbxl'));assert before==sha(guardian)
result={'state':'PASS_STATIC','scene_sha256':scene,'place_sha256':sha(H.parent/'meadow-v4.rbxl'),'geometry_parts':test['matched_native_parts'],'Lune_assertions':test['assertions'],'clearance_violations':0,'dead_ends':0,'unreachable_nodes':0,'guardian_sha256':sha(guardian),'guardian_before_sha256':before,'guardian_before_source':'ROUND5-PROTECTED-HASHES.json recorded before tunnel changes','protected_guardian_unchanged':True,'files':{str(p.relative_to(H.parents[1])):sha(p) for p in files+images},'images':'Offline actual shipped manifest renders, not Studio screenshots','Studio_runtime':'UNKNOWN','measured_hit_escape_rates':'UNKNOWN','timing_ESTIMATED':{k:v for k,v in geometry.items() if 'ESTIMATED' in k}}
result['state']='STATIC_PASS';result['runtime_state']='RUNTIME_PENDING';result['visual_evidence']='Actual offline shipped manifest; supplemental critic disposition tracked separately'
result['exit_mouth_clusters']=2;result['extra_midbranch_surface_contacts']=0
result['supplemental_look']=json.loads((O/'TUNNEL-LOOK-CRITIC.json').read_text())
hill=json.loads((O/'TUNNEL-ROUND2-CHECK.json').read_text())
assert hill['scene_sha256']==scene and hill['unplanned_ceiling_gaps']==0 and hill['protected_sources_and_guardian_equal']
planting=json.loads((O/'ROUND5-PLACEMENT-TUNNEL-ROUND2.json').read_text())
assert planting['scene_sha256']==scene
counts=['unclassified_prop_parts','overlap_pairs','floating','sunk','unsupported','path_intrusions','flowers_off_path_edge','construction_clipping_parts','disconnected_assemblies','fence_gaps_or_stubs','main_width_errors','jump_pad_errors','tunnel_mushroom_attachment_errors']
assert all(planting[k]==0 for k in counts)
result['hill_revision']=hill;result['surface_prop_audit']={k:planting[k] for k in counts}
(O/'TUNNEL-EVIDENCE.json').write_text(json.dumps(result,indent=2));print(json.dumps({k:v for k,v in result.items() if k!='files'},indent=2))
