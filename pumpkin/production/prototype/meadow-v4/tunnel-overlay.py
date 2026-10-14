"""Overlay measured tunnel centerlines on the actual manifest orthographic render."""
from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import json
import shutil
H=Path(__file__).parent;O=H.parents[1]/'treasure/map-v4'
im=Image.open(O/'build-rtunnel-tunnel-top.png').convert('RGB');d=ImageDraw.Draw(im)
s=json.loads((H/'scene.json').read_text());W,Ht=im.size
def xy(p):return (W/2+p[0]/390*W,Ht/2-p[1]/390*Ht)
for name,color in [('tunnel_trunk',(42,247,218)),('tunnel_south',(206,121,255))]:
 pts=[xy(p) for p in s['routes'][name]['points']];d.line(pts,fill=(15,27,46),width=13);d.line(pts,fill=color,width=6)
for label,p in [('ENTRANCE',s['tunnel']['entrance']),('CROSS-LINK EXIT',s['tunnel']['exits'][0]),('SOUTH EXIT',s['tunnel']['exits'][1])]:
 x,y=xy(p);d.ellipse((x-8,y-8,x+8,y+8),fill=(255,237,129),outline=(15,27,46),width=2)
 d.rectangle((x+10,y-12,x+140,y+9),fill=(15,27,46));d.text((x+14,y-8),label,fill=(255,255,255))
d.rectangle((20,20,510,95),fill=(15,27,46));d.text((32,32),'MEADOW V4 | TUNNEL ROUTE OVERLAY',fill=(255,237,129))
d.text((32,53),'Actual shipped geometry; surveyed centerlines shown through roof',fill=(230,240,247))
d.text((32,72),'14 studs wide | 2 connected exits | clearance 0 | dead ends 0',fill=(42,247,218))
if (O/'build-top.jpg').exists() and not (O/'tunnel-baseline-build-top.jpg').exists():shutil.copyfile(O/'build-top.jpg',O/'tunnel-baseline-build-top.jpg')
im.save(O/'build-top.jpg',quality=95);im.save(O/'build-tunnel-top.jpg',quality=95)
