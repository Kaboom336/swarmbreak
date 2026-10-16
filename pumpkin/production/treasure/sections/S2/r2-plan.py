import json
from pathlib import Path
H=Path(__file__).resolve().parent
v=json.loads((H/'r2-visible.json').read_text())
def key(p):return p['name']+'@'+','.join(f'{x:.2f}' for x in p['position'])
remove=[];stone=[]
for a in v:
 p=a['part'];n=p['name']
 if p.get('lane') or p.get('category')=='cover':continue
 if p['collidable'] and n in ('TunnelHillEarth','TunnelRockCourse','TunnelInnerRockFacet','SolidMountainStone','R5BoulderFoot'):
  stone.append(p)
 elif not p['collidable'] and (n.startswith(('TunnelExitArchShoulderVoxel','Fix1AmethystCrystal','TunnelBlueCrystal','Fix1HillSlateBacking','TunnelStalactite','TunnelArchedRockRib','TunnelMouthCliffFaceVoxel'))):remove.append(p)
lines=['-- R2 locked-camera ray-visible identity whitelist. Physical entries permit palette only.','local r2Remove={']
lines += [' ['+json.dumps(key(p))+']=true,' for p in remove]
lines+=['}','local r2Stone={']+[' ['+json.dumps(key(p))+']=true,' for p in stone]+['}']
lines+=['local function r2Key(p) local v=p.CFrame.Position;return p.Name..string.format("@%.2f,%.2f,%.2f",v.X,v.Y,v.Z) end']
patch='*** Begin Patch\n*** Update File: prototype/meadow-v4/Section2.luau\n@@\n local V=Vector3.new\n'+''.join('+'+s+'\n' for s in lines)+'*** End Patch\n'
print(patch)
