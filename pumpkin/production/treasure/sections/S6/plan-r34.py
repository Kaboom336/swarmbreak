"""Measured tangent wall dressing, grounded cosmetic kerbs. No collider edits."""
import json,math,numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'r2.json').read_text()); ps=d['parts']
I=[1,0,0,0,1,0,0,0,1]
def owned(p):
 x,y,z=p['position'];return -65<=x<=125 and -158<=z<=-35 and 0<=y<=54 and not(y>=44 and -32<=x<=32 and -132<=z<=-72)
physical=[p for p in ps if p['collidable']]
def bounds(p):
 c=np.array(p['position']);e=np.abs(np.array(p['rotation']).reshape(3,3))@np.array(p['size'])/2;return c-e,c+e
lo=np.array([bounds(p)[0] for p in physical]);hi=np.array([bounds(p)[1] for p in physical])
def clear(c,s):
 c=np.array(c);e=np.array(s)/2
 return not np.any(np.all(np.minimum(c+e,hi)-np.maximum(c-e,lo)>.03,axis=1))
parts=[];kits=[]
def add(name,c,s,color,mat='SmoothPlastic',rotation=I):
 parts.append(dict(name=name,c=list(map(float,c)),s=list(map(float,s)),color=color,mat=mat,r=rotation))
# Native foliage uses tapered, paired leaves and connected stems; all tangent.
walls=[p for p in physical if p['name']=='SolidMountainStone' and owned(p)]
faces=[]
for w in walls:
 c=np.array(w['position'],dtype=float);a,b=bounds(w);top=b[1]
 if top<12:continue
 for axis,sign in [(0,1),(0,-1),(2,1),(2,-1)]:
  n=np.zeros(3);n[axis]=sign;point=c.copy();point[axis]=(b if sign==1 else a)[axis]
  # Only exposed faces with real continuous wall span and a safe clear envelope.
  point[1]=min(top-2, max(6,a[1]+4))
  envelope=[.8,5,2.8] if axis==0 else [2.8,5,.8]
  if not clear(point+n*.4,envelope):continue
  if any(np.linalg.norm((point-q['p'])[[0,2]])<6 for q in faces):continue
  faces.append(dict(p=point,n=n,top=top,bottom=a[1]))
for i,f in enumerate(faces):
 p,n,top=f['p'],f['n'],f['top'];t=np.array([n[2],0,-n[0]])
 length=min(12,max(4,top-max(0,f['bottom'])-1));start=top-.3
 for j in range(int(length/.85)):
  y=start-j*.85;center=p.copy();center[1]=y;center+=n*.13
  ss=[.26,.94,.26]
  if clear(center,ss):add('VineStem',center,ss,[57,91,38],'Wood')
  for side in [-1,1]:
   leaf=center+t*(side*.34)+n*.17
   size=[.55,.68,.2] if n[2] else [.2,.68,.55]
   if clear(leaf,size):add('VineLeaf',leaf,size,[[72,118,40],[100,145,48],[124,161,57]][(i+j)%3])
 # Rooted clumps across the lip, touching the solid's top face.
 for j in [-1,0,1]:
  c=p.copy();c[1]=top+.35;c-=n*.4;c+=t*j*.65
  if clear(c,[.9,.7,.9]):add('LipLeaves',c,[.9,.7,.9],[96+j*12,141+j*8,48])
 # Lantern on a wooden plate tangent to the face, with a supporting bracket.
 if all(np.linalg.norm((p-g['p'])[[0,2]])>=13 for g in faces[:i] if g.get('lamp')):
  y=min(top-2,max(p[1],top-9));q=p.copy();q[1]=y
  extent=[1.2,3.1,1.2]
  if clear(q+n*.6,extent):
   f['lamp']=True
   plate=q+n*.12;size=[.24,2.5,.6] if n[0] else [.6,2.5,.24]
   add('WallPlate',plate,size,[110,73,41],'Wood')
   add('WallArm',q+n*.65+[0,.8,0],[1.3,.2,.2] if n[0] else [.2,.2,1.3],[118,79,43],'Wood')
   if i%2==0:
    a=q+n*.15+[0,-.25,0];b=q+n*1.18+[0,.7,0];z=(b-a)/np.linalg.norm(b-a);x=np.cross([0,1,0],z);x/=np.linalg.norm(x);up=np.cross(z,x)
    add('WallBrace',(a+b)/2,[.18,.18,float(np.linalg.norm(b-a))],[110,73,41],'Wood',np.column_stack([x,up,z]).flatten().tolist())
   add('WallGlass',q+n*1.1+[0,.1,0],[.65,1.2,.65],[255,192,70],'Neon')
   for dy in [-.58,.78]:add('WallHood',q+n*1.1+[0,dy,0],[.9,.16,.9],[80,58,34],'Wood')
 # CC0 rock cluster touching the same face, never buried in the solid.
 if i%3==0:
  size=np.array([.9,1.5,2.3] if n[0] else [2.3,1.5,.9]);c=p+n*(size[int(np.argmax(np.abs(n)))]/2);c[1]=max(.75,f['bottom']+.75)
  if clear(c,size):
   kits.append(dict(id='WallRock'+str(i),name='quaternius-nature__Rock_Medium_1',x=float(c[0]),y=float(c[1]-.75),z=float(c[2]),size=size.tolist(),color=[145,127,99]))
   add('RockAnchor'+str(i),c,size,[145,127,99],'Rock')
# Reuse each original cosmetic edge footprint and connect adjacent stones.
# New kerbs are surface trim, intentionally in the old edging envelope.
edges=[p for p in ps if owned(p) and p['name']=='StonePathEdge']
for i,p in enumerate(edges):
 c=np.array(p['position']);size=np.array(p['size']);size[1]=.42
 # Original base is supported by the same protected floor; lower the visual top.
 c[1]-=.14
 add('Kerb',c,size,[158,143,112],'Limestone')
 for j,q in enumerate(edges[:i]):
  v=np.array(q['position'])-np.array(p['position']);dist=np.linalg.norm(v[[0,2]])
  if 1<dist<4 and abs(v[1])<1.5:
   # Preserve exact incline between neighboring existing edge centers.
   n=v/np.linalg.norm(v);x=np.cross([0,1,0],n);x/=np.linalg.norm(x);y=np.cross(n,x)
   r=np.column_stack([x,y,n]);cc=(np.array(q['position'])+np.array(p['position']))/2;cc[1]-=.14
   add('KerbJoint',cc,[1.65,.42,float(np.linalg.norm(v))+.05],[158,143,112],'Limestone',r.flatten().tolist())
# Place warning posts on measured real upper-shelf shoulders outside the lane.
for x,z in [(86.625,-100.657608),(93.125,-100.658646),(99.598556,-100.582504)]:
 add('DropPost',[x,37.94,z],[.6,2.8,.6],[126,80,39],'Wood')
 add('DropCap',[x,39.49,z],[.85,.3,.85],[219,161,66],'Wood')
# Fit each cosmetic kerb's underside to the actual retained floor plane.
def support(g):
 c=np.array(g['c']);answers=[]
 ids=np.where((lo[:,0]<=c[0])&(hi[:,0]>=c[0])&(lo[:,2]<=c[2])&(hi[:,2]>=c[2]))[0]
 for k in ids:
  p=physical[k];r=np.array(p['rotation']).reshape(3,3);h=np.array(p['size'])/2
  normal=r@np.array([0,1,-h[1]/h[2]]) if p['shape']=='Wedge' else r[:,1]
  if normal[1]<.1:continue
  at=np.array(p['position'],dtype=float)
  if p['shape']!='Wedge':at+=r[:,1]*h[1]
  y=at[1]-(normal[0]*(c[0]-at[0])+normal[2]*(c[2]-at[2]))/normal[1]
  local=r.T@(np.array([c[0],y,c[2]])-np.array(p['position']))
  if abs(local[0])<=h[0]+.02 and abs(local[2])<=h[2]+.02 and y<=c[1]+2:answers.append((y,normal/np.linalg.norm(normal)))
 if not answers:return False
 y,up=max(answers,key=lambda q:q[0]);r=np.array(g['r']).reshape(3,3)
 z=r[:,2];z=z-up*np.dot(z,up);z/=np.linalg.norm(z);x=np.cross(up,z)
 r=np.column_stack([x,up,z]);c[1]=y+g['s'][1]/2/up[1]
 g['c']=c.tolist();g['r']=r.flatten().tolist();return True
parts=[g for g in parts if not g['name'].startswith('Kerb') or support(g)]
# Adjacent wedge/junction overlaps must also clear the whole trim envelope.
import importlib.util
spec=importlib.util.spec_from_file_location('s6geometry',H/'geometry-r34.py');geo=importlib.util.module_from_spec(spec);spec.loader.exec_module(geo)
solid_convex=[geo.convex(p) for p in physical]
for g in parts:
 if not g['name'].startswith('Kerb'):continue
 c=np.array(g['c']);r=np.array(g['r']).reshape(3,3);e=np.abs(r)@np.array(g['s'])/2
 ids=np.where(np.all(np.minimum(c+e+[0,2,0],hi)-np.maximum(c-e,lo)>.001,axis=1))[0]
 def collision(dy):
  cc=c+[0,dy,0];p=dict(position=cc,size=g['s'],rotation=g['r'],shape='Block');cv=geo.convex(p)
  return any(geo.overlaps(cv,solid_convex[k],.001) for k in ids)
 if collision(0):
  low,high=0.,2.
  while collision(high):high+=2
  for _ in range(15):
   mid=(low+high)/2
   if collision(mid):low=mid
   else:high=mid
  g['c'][1]+=high
out=dict(parts=parts,kits=kits,faces=len(faces),lamps=sum(bool(f.get('lamp')) for f in faces))
(H/'PLAN-R3.json').write_text(json.dumps(out,indent=2))
print('planned',len(parts),'native parts',len(kits),'kits',len(faces),'faces',out['lamps'],'lamps')
base=(H/'r2-Section6.luau').read_text().replace('local S = {}','local S = {kits={}}')
base=base[:base.rindex('return S')]
extra='''
-- R3: only Claude's three recorded wall/kerb/drop gaps.
local plan=game:GetService('HttpService'):JSONDecode([==[PLAN_JSON]==])
for _,g in plan.kits do g.size=V(unpack(g.size));table.insert(S.kits,g) end
function S.spawnKits(root,kit)
 if root:GetAttribute('S6KitsLoaded') then return end
 local origin=root:GetAttribute('MeadowOrigin') or V(0,0,0)
 for _,g in S.kits do
  yieldBuild();local frame=CFrame.new(origin+V(g.x,g.y,g.z))
  local m=assert(kit.spawn(g.name,'meadow',frame,g.size),'S6 kit missing '..g.id)
  assert(kit.fit(m,g.size,frame),'S6 fit failed');m.Name='S6_'+g.id
  for _,p in m:GetDescendants() do yieldBuild();if p:IsA('BasePart') then
   p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
   p.Color=Color3.fromRGB(unpack(g.color));p.Material=Enum.Material.Rock
   p:SetAttribute('Section','S6');p:SetAttribute('Cosmetic',true)
  end end
  m.Parent=root
 end
 root:SetAttribute('S6KitsLoaded',#S.kits)
end
local previousBuild=S.build
function S.build(root)
 previousBuild(root)
 for _,p in root:GetDescendants() do yieldBuild();if p:IsA('BasePart') then
  local v=p.CFrame.Position;local owned=v.X>=-65 and v.X<=125 and v.Z>=-158 and v.Z<=-35 and v.Y>=0 and v.Y<=54 and not(v.Y>=44 and v.X>=-32 and v.X<=32 and v.Z>=-132 and v.Z<=-72)
  local cosmetic=not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('LaneId') and #p:GetTags()==0
  if owned and cosmetic and (p.Name=='StonePathEdge' or (v.X>=75 and p.Name=='Round4PaleRockTop')) then p:Destroy()
  elseif cosmetic and p.Name=='WindingCobble' and v.X>=112 and v.X<=125 and v.Z>=-98 and v.Z<=-85 and v.Y>=23 and v.Y<=25 then
   p.Color=Color3.fromRGB(239,192,103);p.Material=Enum.Material.Limestone
  elseif owned and (p.Name=='SolidMountainStone' or (cosmetic and (p.Name=='Round4ShelfRockRelief' or p.Name=='Round4ShelfLightFacet' or p.Name=='Round4StackedRock'))) then
   local top=v.Y+p.Size.Y/2
   if p.Name~='SolidMountainStone' or (top<=54 and not(v.X>=-32 and v.X<=32 and v.Z>=-132 and v.Z<=-72)) then
    local tone=(math.floor(v.X/4)+math.floor(v.Z/4))%4
    p.Color=Color3.fromRGB(144+tone*7,129+tone*6,105+tone*5);p.Material=Enum.Material.Sandstone
   end
  end
 end end
 for i,g in plan.parts do
  local p=part(root,if g.name:find('RockAnchor') then g.name else g.name..i,CFrame.new(unpack(g.c))*CFrame.new(0,0,0,unpack(g.r)),V(unpack(g.s)),g.color,Enum.Material[g.mat])
  if g.name:find('RockAnchor') then p.Transparency=1 end
  if g.name=='WallGlass' then
   local l=Instance.new('PointLight');l.Color=Color3.fromRGB(255,207,133);l.Brightness=1.25;l.Range=18;l.Shadows=false;l.Parent=p
  end
 end
 if task then task.defer(function()
  while not root:GetAttribute('MeadowOrigin') do task.wait() end
  local ok,err=pcall(function() S.spawnKits(root,require(game:GetService('ServerScriptService').KitLibrary)) end)
  if not ok then warn('[S6] kits skipped: '..tostring(err)) end
 end) end
end
return S
'''.replace('PLAN_JSON',json.dumps(out,separators=(',',':')))
(H.parents[2]/'prototype/meadow-v4/Section6.luau').write_text(base+extra)
