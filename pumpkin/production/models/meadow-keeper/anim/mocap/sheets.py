"""Make contact sheets and GIFs with the existing local ffmpeg; no policy changes."""
from pathlib import Path
import subprocess
R=Path(__file__).resolve().parent;O=R.parent/'preview/mocap';FF=R.parents[3]/'concepts/refs3/_tools/ffmpeg.exe'
ids=list('ABCDEFGH')
if '--extras' in __import__('sys').argv:
    ids=[n+('' if '--selected' in __import__('sys').argv else '-candidate') for n in ['idle','patrol','return','stun','celebrate','warn','dash']]
for id in ids:
    subprocess.run([str(FF),'-y','-loglevel','error','-framerate','24','-i',str(O/(id+'-%03d.png')),'-vf','split[a][b];[a]palettegen[p];[b][p]paletteuse','-loop','0',str(O/(id+'.gif'))],check=True)
    subprocess.run([str(FF),'-y','-loglevel','error','-i',str(O/(id+'-pose-%02d.png')),'-vf','scale=240:240,tile=7x1','-frames:v','1',str(O/(id+'-strip.jpg'))],check=True)
if ids==list('ABCDEFGH'):
    args=[str(FF),'-y','-loglevel','error']
    for id in ids:args+=['-i',str(O/(id+'-strip.jpg'))]
    subprocess.run(args+['-filter_complex','vstack=inputs=8','-frames:v','1',str(O/'blind-comparison.jpg')],check=True)
print('Built',len(ids),'GIFs and contact sheets')
