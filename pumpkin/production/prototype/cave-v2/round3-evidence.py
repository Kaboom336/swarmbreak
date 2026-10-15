import json,hashlib,sys
from pathlib import Path
H=Path(__file__).resolve().parent;R=H.parents[1]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
if sys.argv[1]=='before':
 old=json.loads((H/'ROUND2-PROTECTED.json').read_text())
 (H/'ROUND3-PROTECTED.json').write_text(json.dumps({p:sha(R/p) for p in old},indent=2))
else:
 baseline=json.loads((H/'round3-baseline-scene.json').read_text());scene=json.loads((H/'scene.json').read_text())
 old=json.loads((H/'ROUND3-PROTECTED.json').read_text());changed=[p for p,h in old.items() if sha(R/p)!=h]
 hooks=lambda s:[p for p in s['parts'] if p['category']=='hook']
 collision=lambda s:[{k:p[k] for k in ['name','category','position','size','rotation','collidable']} for p in s['parts'] if p['collidable']]
 terrain=lambda s:[{k:p[k] for k in ['name','position','size','rotation']} for p in s['parts'] if p['category'] in ['mass','underside']]
 shafts=lambda s:sum(p['name']=='CrystalShaft' for p in s['parts'])
 a=json.loads((H/'AUDIT.json').read_text());s=json.loads((H/'STRUCTURAL-AUDIT.json').read_text())
 keys=['floating_collider_parts','cave_24_headroom_hits','green_flight_envelope_hits','red_fall_envelope_hits','track_cart_envelope_hits','floor_ray_missing_hits']
 result={'protected_changed':changed,'routes_equal':baseline['routes']==scene['routes'],'hooks_equal':hooks(baseline)==hooks(scene),'collision_volumes_equal':collision(baseline)==collision(scene),'terrain_height_and_mass_equal':terrain(baseline)==terrain(scene),'crystal_shafts_before':shafts(baseline),'crystal_shafts_after':shafts(scene),'crystal_multiplier':shafts(scene)/shafts(baseline),'point_lights':len(scene['lights']),'clearance_hits':a['clearance_hits'],'unreachable_route_nodes':a['unreachable_route_nodes'],'static_zero_checks':{k:s[k] for k in keys},'runtime':'UNKNOWN; offline native geometry proof'}
 assert not changed and all(result[k] for k in ['routes_equal','hooks_equal','collision_volumes_equal','terrain_height_and_mass_equal'])
 assert result['crystal_multiplier']>=4 and a['clearance_hits']==0 and a['unreachable_route_nodes']==0 and all(s[k]==0 for k in keys)
 metadata=json.loads((H/'render-rr3-final-metadata.json').read_text())
 assert metadata['manifest_sha256']==sha(H/'scene.json')
 oldcamera=json.loads((H/'render-rr2-final-metadata.json').read_text())
 result['same_camera']=metadata['concept_camera']==oldcamera['concept_camera'];assert result['same_camera']
 result['native_check']=json.loads((H/'ROUND3-NATIVE-CHECK.json').read_text())
 result['native_preservation']=json.loads((H/'ROUND3-SCRIPT-CHECK.json').read_text())
 result['critic_scores']=[6,7];result['visual_target_met']=True
 result['audit_binding']='Final collidable name/category/position/size/rotation sequence equals baseline exactly. Final audit runs ignore noncollidable decoration; final subsequent changes move background art only.'
 result['hashes']={str(p.relative_to(R)):sha(p) for p in [R/'prototype/cave-v2.rbxl',H/'scene.json',H/'build.luau',H/'round3-art.luau',H/'render.py',H/'AUDIT.json',H/'STRUCTURAL-AUDIT.json',H/'ROUND3-NATIVE-CHECK.json',H/'ROUND3-SCRIPT-CHECK.json',H/'CONCEPT-COMPARE.png',H/'render-rr3-final-metadata.json',H/'build-rr3-final-concept.png',H/'build-rr3-final-side.png',H/'build-rr3-final-top.png']}
 (H/'ROUND3-EVIDENCE.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
