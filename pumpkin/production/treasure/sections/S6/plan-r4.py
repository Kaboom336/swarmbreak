"""Last three render gaps only. Replace off-screen R3 dressing with visible faces."""
import json,numpy as np,importlib.util
from pathlib import Path
H=Path(__file__).resolve().parent
d=json.loads((H/'r3.json').read_text());old=json.loads((H/'PLAN-R3.json').read_text())
spec=importlib.util.spec_from_file_location('s6geometry',H/'geometry-r34.py');geo=importlib.util.module_from_spec(spec);spec.loader.exec_module(geo)
I=[1,0,0,0,1,0,0,0,1]
def owned(p):
 x,y,z=p['position'];return -65<=x<=125 and -158<=z<=-35 and 0<=y<=54 and not(y>=44 and -32<=x<=32 and -132<=z<=-72)
physical=[p for p in d['parts'] if p['collidable']]
centers=np.array([p['position'] for p in physical]);half=np.array([p['size'] for p in physical])/2
rot=np.array([p['rotation'] for p in physical]).reshape(-1,3,3)
ext=np.einsum('nij,nj->ni',np.abs(rot),half);lo=centers-ext;hi=centers+ext
cv=[geo.convex(p) for p in physical]
lanes=[];lane_lo=[];lane_hi=[]
for p in physical:
 if p.get('lane'):
  q=dict(p);q['position']=(np.array(p['position'])+[0,3.5,0]).tolist();q['size']=(np.array(p['size'])+[2,7,2]).tolist();q['shape']='Block';v=geo.convex(q);lanes.append(v);lane_lo.append(v[0].min(axis=0));lane_hi.append(v[0].max(axis=0))
lane_lo=np.array(lane_lo);lane_hi=np.array(lane_hi)
def clear(c,s,r=I,lane=True):
 p=dict(position=list(c),size=list(s),rotation=r,shape='Block');v=geo.convex(p);e=np.abs(np.array(r).reshape(3,3))@np.array(s)/2
 ids=np.where(np.all(np.minimum(np.array(c)+e,hi)-np.maximum(np.array(c)-e,lo)>.035,axis=1))[0]
 lane_ids=np.where(np.all(np.minimum(np.array(c)+e,lane_hi)-np.maximum(np.array(c)-e,lane_lo)>.035,axis=1))[0] if lane else []
 return not any(geo.overlaps(v,cv[k]) for k in ids) and not any(geo.overlaps(v,lanes[k]) for k in lane_ids)
parts=[];kits=[]
def add(name,c,s,color,mat='SmoothPlastic',r=I,shape='Block'):
 parts.append(dict(name=name,c=list(map(float,c)),s=list(map(float,s)),r=r,color=color,mat=mat,shape=shape))
def ray(eye,direction):
 o=np.einsum('nji,nj->ni',rot,eye-centers);v=np.einsum('nji,j->ni',rot,direction);v=np.where(abs(v)<1e-8,1e-8,v)
 a=(-half-o)/v;b=(half-o)/v;t0=np.minimum(a,b).max(axis=1);t1=np.maximum(a,b).min(axis=1)
 for k,p in enumerate(physical):
  if p['shape']!='Wedge':continue
  ratio=half[k,1]/half[k,2];offset=o[k,1]-ratio*o[k,2];speed=v[k,1]-ratio*v[k,2]
  if speed>1e-8:t1[k]=min(t1[k],-offset/speed)
  elif speed<-1e-8:t0[k]=max(t0[k],-offset/speed)
  elif offset>0:t1[k]=-1
 ts=np.where((t0>0)&(t1>=t0),t0,np.inf);i=int(ts.argmin())
 if not np.isfinite(ts[i]):return None
 local=o[i]+ts[i]*v[i];axis=int(np.abs(np.abs(local)-half[i]).argmin());normal=rot[i,:,axis]*np.sign(local[axis])
 return physical[i],eye+direction*ts[i],normal,float(ts[i])
faces=[]
views=json.loads((H/'CAMERAS.json').read_text())[:2]
for view in views:
 eye=np.array(view['eye'],float);f=np.array(view['target'])-eye;f/=np.linalg.norm(f);right=np.cross(f,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,f)
 for sx in np.linspace(-.95,.95,23):
  for sy in [.65,.35,0,-.25]:
   direction=f+right*sx*.75+up*sy*.75*540/960;direction/=np.linalg.norm(direction);hit=ray(eye,direction)
   if not hit:continue
   p,q,n,dist=hit
   if p['name']!='SolidMountainStone' or abs(n[1])>.01 or not(5<dist<85) or not owned(p):continue
   if any(np.linalg.norm((q-other['q'])[[0,2]])<5 for other in faces):continue
   top=p['position'][1]+p['size'][1]/2;bottom=p['position'][1]-p['size'][1]/2
   start=min(top-.5,q[1]+5,43.3 if -32<=q[0]<=32 and -132<=q[2]<=-72 else 52)
   if start<5:continue
   faces.append(dict(q=q,n=n,start=start,bottom=bottom,view=view['name']))
for i,g in enumerate(faces):
 q,n,start,bottom=g['q'],g['n'],g['start'],g['bottom'];t=np.array([n[2],0,-n[0]])
 for j in range(14):
  c=q.copy();c[1]=start-j*.78;c+=n*.14
  if c[1]<max(1,bottom+.5):break
  if clear(c,[.28,.82,.28]):add('VisibleStem',c,[.28,.82,.28],[59,91,35],'Wood')
  for side in [-1,1]:
   leaf=c+t*side*.34+n*.19
   s=[.7,.8,.22] if n[2] else [.22,.8,.7]
   if clear(leaf,s):add('VisibleLeaf',leaf,s,[[76,119,36],[107,148,45],[128,162,58]][(i+j)%3],shape='Wedge')
 # A clump on each visible wall segment touches the stem, without entering stone.
 c=q.copy();c[1]=start-.5;c+=n*.4
 s=[.8,1.3,2.1] if n[0] else [2.1,1.3,.8]
 if clear(c,s):add('VisibleClump',c,s,[103,145,44],shape='Wedge')
 # Lanterns about 14 studs apart on the retained wall faces.
 if any(np.linalg.norm((q-v)[[0,2]])<13 for v in [f['q'] for f in faces[:i] if f.get('lamp')]):continue
 anchor=q.copy();anchor[1]=min(start-2,max(5,q[1]))
 if not clear(anchor+n*.85,[1.7,2.8,1.7]):continue
 g['lamp']=True
 add('VisiblePlate',anchor+n*.12,[.24,2.4,.6] if n[0] else [.6,2.4,.24],[107,70,39],'Wood')
 add('VisibleArm',anchor+n*.65+[0,.8,0],[1.3,.2,.2] if n[0] else [.2,.2,1.3],[118,79,43],'Wood')
 add('VisibleGlass',anchor+n*1.1+[0,.1,0],[.65,1.2,.65],[255,192,70],'Neon')
 for dy in [-.58,.78]:add('VisibleHood',anchor+n*1.1+[0,dy,0],[.9,.16,.9],[80,58,34],'Wood')
 a=anchor+n*.15+[0,-.25,0];b=anchor+n*1.18+[0,.7,0];z=(b-a)/np.linalg.norm(b-a);x=np.cross([0,1,0],z);x/=np.linalg.norm(x);y=np.cross(z,x)
 add('VisibleBrace',(a+b)/2,[.18,.18,float(np.linalg.norm(b-a))],[110,73,41],'Wood',np.column_stack([x,y,z]).flatten().tolist())
 # A small rock clump tangential to each lit wall, just below the foliage.
 c=q+n*.45;c[1]=max(1,start-10)
 s=[.9,1.3,1.8] if n[0] else [1.8,1.3,.9]
 if clear(c,s):
  idx=len(kits);kits.append(dict(id='VisibleRock'+str(idx),name='quaternius-nature__Rock_Medium_1',x=float(c[0]),y=float(c[1]-.65),z=float(c[2]),size=s,color=[143,126,98]))
  add('VisibleRockAnchor'+str(idx),c,s,[143,126,98],'Rock')
# Reconstruct original edge inclines before fitting the replacement beds.
# Center-only rays can miss an overhanging edge and hit a shelf 24 studs below.
original_edges=[p for p in json.loads((H/'r2.json').read_text())['parts'] if owned(p) and p['name']=='StonePathEdge']
original_joints={}
for i,p in enumerate(original_edges):
 for q in original_edges[:i]:
  delta=np.array(q['position'])-np.array(p['position']);dist=np.linalg.norm(delta[[0,2]])
  if 1<dist<4 and abs(delta[1])<1.5:
   c=(np.array(q['position'])+np.array(p['position']))/2;z=delta/np.linalg.norm(delta);x=np.cross([0,1,0],z);x/=np.linalg.norm(x);y=np.cross(z,x)
   original_joints[(round(c[0],4),round(c[2],4))]=(c,np.column_stack([x,y,z]))
# Replace overlapping axis-aligned caps with tangent connected beds.
for g in old['parts']:
 if g['name']!='KerbJoint':continue
 g=dict(g);g['name']='KerbBed';g['s']=[2.8,.72,g['s'][2]+.15]
 c,r=original_joints[(round(g['c'][0],4),round(g['c'][2],4))]
 g['c']=c.tolist();g['c'][1]-=.12;g['r']=r.flatten().tolist()
 c=np.array(g['c']);r=np.array(g['r']).reshape(3,3);e=np.abs(r)@np.array(g['s'])/2
 ids=np.where(np.all(np.minimum(c+e+[0,4,0],hi)-np.maximum(c-e,lo)>.001,axis=1))[0]
 def collision(dy):
  p=dict(position=c+[0,dy,0],size=g['s'],rotation=g['r'],shape='Block');v=geo.convex(p)
  return any(geo.overlaps(v,cv[k],.001) for k in ids)
 if collision(0):
  a,b=0.,2.
  while collision(b):b+=2
  for _ in range(14):
   m=(a+b)/2
   if collision(m):a=m
   else:b=m
  g['c'][1]+=b
 parts.append(g)
# Short warning posts farther along the existing descent edge, on its kerb.
for x,y,z in [(109.332184,36.12,-105.500824),(115.506958,34.12,-107.333344)]:
 add('DropPost',[x,y+1.52,z],[.5,1.6,.5],[123,77,40],'Wood')
 add('DropCap',[x,y+2.4,z],[.7,.16,.7],[226,168,66],'Wood')
out=dict(parts=parts,kits=kits,faces=[dict(q=g['q'].tolist(),normal=g['n'].tolist(),view=g['view'],lamp=g.get('lamp',False)) for g in faces])
(H/'PLAN-R4.json').write_text(json.dumps(out,indent=2))
base=(H/'r3-Section6.luau').read_text().replace("m.Name='S6_'+g.id","m.Name='S6_'..g.id")
base=base[:base.rindex('return S')]
extra='''
-- R4: three render-recorded gaps; no gameplay or protected geometry edits.
local finalPlan=game:GetService('HttpService'):JSONDecode([==[PLAN_JSON]==])
S.kits={}
for _,g in finalPlan.kits do g.size=V(unpack(g.size));table.insert(S.kits,g) end
local round3Build=S.build
function S.build(root)
 round3Build(root)
 for _,p in root:GetDescendants() do yieldBuild();if p:IsA('BasePart') then
  local v=p.CFrame.Position;local owned=v.X>=-65 and v.X<=125 and v.Z>=-158 and v.Z<=-35 and v.Y>=0 and v.Y<=54 and not(v.Y>=44 and v.X>=-32 and v.X<=32 and v.Z>=-132 and v.Z<=-72)
  local cosmetic=not p.CanCollide and not p.CanQuery and not p.CanTouch and not p:GetAttribute('WalkableLaneFloor') and not p:GetAttribute('LaneId') and #p:GetTags()==0
  local replaced=p.Name:match('^S6_Vine') or p.Name:match('^S6_LipLeaves') or p.Name:match('^S6_Wall') or p.Name:match('^S6_RockAnchor') or p.Name:match('^S6_Kerb') or p.Name:match('^S6_Drop')
  local relief=owned and (p.Name=='Round4ShelfRockRelief' or p.Name=='Round4ShelfLightFacet' or p.Name=='Round4StackedRock' or p.Name=='LookLightRockTop')
  if cosmetic and (replaced or relief) then p:Destroy()
  elseif cosmetic and p.Name=='WindingCobble' and v.X>=112 and v.X<=125 and v.Z>=-98 and v.Z<=-85 and v.Y>=23 and v.Y<=31 then
   p.Color=Color3.fromRGB(248,197,95);p.Material=Enum.Material.Limestone
  end
 end end
 for i,g in finalPlan.parts do
  local name=if g.name:find('RockAnchor') then g.name else g.name..i
  local p=part(root,name,CFrame.new(unpack(g.c))*CFrame.new(0,0,0,unpack(g.r)),V(unpack(g.s)),g.color,Enum.Material[g.mat])
  if g.shape=='Wedge' then
   local wedge=Instance.new('WedgePart');wedge.Name=p.Name;wedge.CFrame=p.CFrame;wedge.Size=p.Size;wedge.Color=p.Color;wedge.Material=p.Material
   wedge.Anchored=true;wedge.CanCollide=false;wedge.CanQuery=false;wedge.CanTouch=false;wedge:SetAttribute('Section','S6');wedge:SetAttribute('Cosmetic',true);wedge.Parent=root;p:Destroy();p=wedge
  end
  if g.name:find('RockAnchor') then p.Transparency=1 end
  if g.name=='VisibleGlass' then
   local l=Instance.new('PointLight');l.Color=Color3.fromRGB(255,207,133);l.Brightness=1.25;l.Range=18;l.Shadows=false;l.Parent=p
  end
 end
end
return S
'''.replace('PLAN_JSON',json.dumps(out,separators=(',',':')))
(H.parents[2]/'prototype/meadow-v4/Section6.luau').write_text(base+extra)
print('R4',len(parts),'native',len(kits),'kits',len(faces),'visible wall groups')
