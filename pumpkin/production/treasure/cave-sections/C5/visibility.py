"""Native convex line visibility and locked-camera projection; not engine evidence."""
import json,math
from pathlib import Path
import numpy as np
H=Path(__file__).resolve().parent
parts=[p for p in json.loads((H/'before.json').read_text())['parts']if p['transparency']<.7]
c=np.array([p['position']for p in parts]);h=np.array([p['size']for p in parts])/2
r=np.array([p['rotation']for p in parts]).reshape(-1,3,3)
wedge=np.array([p['shape']=='Wedge'for p in parts]);out={}
for view in json.loads((H/'CAMERAS.json').read_text())['views'][:3]:
 eye=np.array(view['eye']);forward=np.array(view['target'])-eye;forward/=np.linalg.norm(forward)
 right=np.cross(forward,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,forward)
 origins=np.einsum('nji,nj->ni',r,eye-c)
 candidates=[]
 for x,y,z,height in json.loads((H/'CANDIDATES.json').read_text()):
  if height<20:continue
  visible=[];screens=[]
  for dy in [8,14,20]:
   q=np.array([x,y+dy,z]);d=q-eye;depth=d@forward
   if depth<=0:continue
   sx=(d@right)/(depth*.75);sy=(d@up)/(depth*.421875)
   if abs(sx)>.9 or abs(sy)>.9:continue
   dirs=np.einsum('nji,j->ni',r,d)
   with np.errstate(divide='ignore',invalid='ignore'):
    t1=(-h-origins)/dirs;t2=(h-origins)/dirs
   enter=np.maximum(np.min([t1,t2],axis=0).max(axis=1),0);leave=np.minimum(np.max([t1,t2],axis=0).min(axis=1),1)
   # Wedge y - (hy/hz)z <= 0 clips the box.
   a=origins[:,1]-h[:,1]/h[:,2]*origins[:,2];b=dirs[:,1]-h[:,1]/h[:,2]*dirs[:,2]
   with np.errstate(divide='ignore',invalid='ignore'):t=-a/b
   enter=np.where(wedge&(b<0),np.maximum(enter,t),enter);leave=np.where(wedge&(b>0),np.minimum(leave,t),leave)
   hits=(enter<=leave)&(leave>0)&(enter<1-2/max(np.linalg.norm(d),2))
   if not np.any(hits):visible.append(dy);screens.append([round(sx,2),round(sy,2)])
  if visible:candidates.append(dict(base=[x,y,z],visibleHeights=visible,screen=screens,score=len(visible)*10-abs(screens[0][0])*2))
 candidates.sort(key=lambda v:-v['score']);out[view['name']]=candidates
(H/'VISIBILITY.json').write_text(json.dumps(out,indent=2))
for k,v in out.items():print(k,v[:8])
view=json.loads((H/'CAMERAS.json').read_text())['views'][2]
eye=np.array(view['eye']);forward=np.array(view['target'])-eye;forward/=np.linalg.norm(forward)
right=np.cross(forward,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,forward)
for sx,sy in [[.2,0],[.4,0],[0,.15],[-.2,0],[.6,.3]]:
 d=(forward+right*sx*.75+up*sy*.421875)*100
 origins=np.einsum('nji,nj->ni',r,eye-c);dirs=np.einsum('nji,j->ni',r,d)
 with np.errstate(divide='ignore',invalid='ignore'):t1=(-h-origins)/dirs;t2=(h-origins)/dirs
 enter=np.maximum(np.minimum(t1,t2).max(axis=1),0);leave=np.minimum(np.maximum(t1,t2).min(axis=1),1)
 good=(enter<=leave)&(leave>0);idx=np.argmin(np.where(good,enter,100))
 print('CHAMBER FACE',sx,sy,parts[idx]['name'],parts[idx]['position'],parts[idx]['size'],parts[idx]['rotation'],'hit',(eye+d*enter[idx]).tolist(),'collidable',parts[idx]['collidable'])
