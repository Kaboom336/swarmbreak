"""Expose every 24 fps rendered frame chronologically for visual review."""
import json,math,subprocess
from pathlib import Path
R=Path(__file__).resolve().parent;O=R.parent/'preview/mocap'
FF=R.parents[3]/'concepts/refs3/_tools/ffmpeg.exe'
D=json.loads((R/'selected.json').read_text())
for name,id in [('lob','A'),('fan','C'),('slam','E'),('chase','G')]:
    count=max(20,math.ceil(D['clips'][name]['duration']*24));rows=math.ceil(count/8)
    vf="scale=180:180,drawtext=fontfile='C\\:/Windows/Fonts/segoeui.ttf':text='%{n}':fontcolor=black:fontsize=14:x=4:y=4,tile=8x"+str(rows)
    subprocess.run([str(FF),'-y','-loglevel','error','-i',str(O/(id+'-%03d.png')),'-vf',vf,'-frames:v','1',str(O/(name+'-all-frames.jpg'))],check=True)
print('Every selected rendered frame assembled in temporal order')
