import json,hashlib,math
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent
base=json.loads((H/'r2-baseline-coverage.json').read_text());after=json.loads((H/'r2-after-coverage.json').read_text())
def png(tag):return np.frombuffer((H/(tag+'-mouth.bgra')).read_bytes(),dtype=np.uint8).reshape(720,1280,4)[:,:,:3][:,:,::-1].astype(float)
def neutral(im):
 mx=im.max(2);mn=im.min(2)
 return (mx>=48)&(mx<=224)&((mx-mn)<=.22*mx)
display={tag:float(neutral(png(tag)).mean()*100) for tag in ('after','r2-baseline','r2-after')}
im=png('r2-after');roi=im[310:420,560:650];bright=(roi[:,:,0]>=200)&(roi[:,:,1]>=140)&(roi[:,:,2]>=70)
data=json.loads((H/'r2-after.json').read_text())
eye=np.array([-53,6,115.]);f=np.array([-69,6,86.])-eye;f/=np.linalg.norm(f);right=np.cross(f,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,f)
corners=[]
for p in data['parts']:
 if p.get('section')!='S2' or not ('Mine' in p['name'] or 'Lamp' in p['name']) or p['position'][2]<88:continue
 R=np.array(p['rotation']).reshape(3,3);h=np.array(p['size'])/2;c=np.array(p['position'])
 for sx in (-1,1):
  for sy in (-1,1):
   for sz in (-1,1):
    v=c+R@(h*np.array([sx,sy,sz]))-eye;depth=v@f
    corners.append([640+(v@right)/depth*1280/1.5,360-(v@up)/depth*1280/1.5])
corners=np.array(corners);bounds=[*corners.min(0).tolist(),*corners.max(0).tolist()]
out={'locked_camera_coverage':after,'pale_grey_albedo_definition':'Occlusion-aware source-albedo mask: max RGB >=120; saturation <=20%; Rock/Slate/Concrete/SmoothPlastic; S2 props counted separately. Same renderer/cameras.','pale_grey_albedo_mouth_before_percent':base['mouth']['pale_grey_albedo_visible_percent'],'pale_grey_albedo_mouth_after_percent':after['mouth']['pale_grey_albedo_visible_percent'],'display_neutral_definition':'Full-frame rendered PNG: max channel 48..224 and (max-min)/max <=0.22; measures lit grey pixels, not source materials.','display_neutral_mouth_percent':display,'destination_bright_ROI_xyxy':[560,310,650,420],'destination_bright_definition':'R>=200 G>=140 B>=70 within fixed interior destination ROI','destination_bright_pixels':int(bright.sum()),'facade_and_entrance_lantern_projected_bounds_xyxy':bounds,'facade_fully_inside_mouth_frustum':bool(corners.min()>=0 and corners[:,0].max()<1280 and corners[:,1].max()<720)}
out['goals']={'walk_S2_ge_10':after['walk']['S2_visible_percent']>=10,'mouth_S2_ge_18':after['mouth']['S2_visible_percent']>=18,'mouth_timber_lantern_span_ge_25':after['mouth']['timber_lantern_horizontal_span_percent']>=25,'pale_albedo_at_most_half':out['pale_grey_albedo_mouth_after_percent']<=out['pale_grey_albedo_mouth_before_percent']/2,'display_neutral_at_most_half_original_R1':display['r2-after']<=display['after']/2,'display_neutral_at_most_half_matched_R1':display['r2-after']<=display['r2-baseline']/2,'route_end_bright':int(bright.sum())>0,'facade_in_frame':out['facade_fully_inside_mouth_frustum']}
(H/'METRICS-R2.json').write_text(json.dumps(out,indent=2));print(json.dumps(out,indent=2))
