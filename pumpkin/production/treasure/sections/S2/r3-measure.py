"""Run inside Blender after final renders: occlusion-aware masks, source albedo connectivity."""
import bpy,json,sys
import numpy as np
from pathlib import Path
H=Path(__file__).resolve().parent
tag=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'r3-after'
def mask(path):
 im=bpy.data.images.load(str(path),check_existing=False)
 a=np.array(im.pixels[:]).reshape(im.size[1],im.size[0],4)[:,:,0]>.5
 bpy.data.images.remove(im)
 return a
def largest(a):
 # Run-length union-find: exact 4-connected regions at native 1280x720 resolution.
 sizes=[];parents=[];previous=[]
 def find(i):
  while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
  return i
 for row in a:
  edges=np.diff(np.r_[False,row,False].astype(int));runs=list(zip(np.where(edges==1)[0],np.where(edges==-1)[0]));current=[]
  for start,end in runs:
   i=len(parents);parents.append(i);sizes.append(int(end-start))
   for left,right,j in previous:
    if left<end and right>start:
     r=find(j);s=find(i)
     if r!=s:parents[r]=s;sizes[s]+=sizes[r]
   current.append((start,end,i))
  previous=current
 return max([sizes[i] for i in range(len(parents)) if find(i)==i],default=0)
coverage=json.loads((H/(tag+'-coverage.json')).read_text())
walls={}
for i in (5,6,7):
 a=mask(H/(tag+'-mouth-id'+str(i)+'-0001.png'));walls[str(i)]=largest(a)/a.size*100
lanterns={}
data=json.loads((H/(tag+'.json')).read_text())
lamp_count=sum(p['name']=='S2_LampGlass' for p in data['parts'])
for view in ('walk','mouth'):
 counts={p.name:int(mask(p).sum()) for i in range(100,100+lamp_count) for p in [H/(tag+'-'+view+'-id'+str(i)+'-0001.png')]}
 lanterns[view]={'count':sum(v>0 for v in counts.values()),'visible_core_pixels':counts}
im=bpy.data.images.load(str(H/(tag+'-mouth.png')),check_existing=False)
im.colorspace_settings.name='Non-Color'
rgb=np.array(im.pixels[:]).reshape(720,1280,4)[::-1,:,:3]*255
roi=rgb[310:420,560:650];bright=int(((roi[:,:,0]>=200)&(roi[:,:,1]>=140)&(roi[:,:,2]>=70)).sum())
out={'coverage':coverage,'flat_wall_definition':'Largest 4-connected occlusion-aware source-colour wall region / full 1280x720 frame. Three wall albedo ID masks, including retained solid planes; original kit FBX occludes wall pixels. No light/shadow fragmentation.','wall_color_largest_connected_percent':walls,'flat_wall_share_percent':max(walls.values()),'lanterns':lanterns,'lantern_definition':'Individual shipped lantern glass core ID with >=1 visible pixel after actual geometry occlusion; destination glow is excluded.','destination_bright_pixels_fixed_R2_ROI':bright,'goals':{'walk_ge10':coverage['walk']['S2_visible_percent']>=10,'mouth_ge18':coverage['mouth']['S2_visible_percent']>=18,'span_ge25':coverage['mouth']['timber_lantern_horizontal_span_percent']>=25,'flat_wall_le12':max(walls.values())<=12,'mouth_lanterns_4_to8':4<=lanterns['mouth']['count']<=8,'walk_lanterns_4_to8':4<=lanterns['walk']['count']<=8,'bright_destination':bright>0,'pale_grey_at_most_half_R1':coverage['mouth']['pale_grey_albedo_visible_percent']<=19.0252/2}}
# The original facade frustum check includes both posts, bases, header, braces and facade lamps.
eye=np.array([-53,6,115.]);forward=np.array([-69,6,86.])-eye;forward/=np.linalg.norm(forward)
right=np.cross(forward,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,forward)
corners=[]
for p in data['parts']:
 if p.get('section')!='S2' or not ('Mine' in p['name'] or 'Lamp' in p['name']) or p['position'][2]<88:continue
 R=np.array(p['rotation']).reshape(3,3);h=np.array(p['size'])/2;c=np.array(p['position'])
 for sx in (-1,1):
  for sy in (-1,1):
   for sz in (-1,1):
    v=c+R@(h*np.array([sx,sy,sz]))-eye;depth=v@forward
    corners.append([640+(v@right)/depth*1280/1.5,360-(v@up)/depth*1280/1.5])
corners=np.array(corners)
out['facade_projected_bounds_xyxy']=[*corners.min(0).tolist(),*corners.max(0).tolist()]
out['goals']['facade_in_frame']=bool(corners.min()>=0 and corners[:,0].max()<1280 and corners[:,1].max()<720)
(H/'METRICS-R3.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
