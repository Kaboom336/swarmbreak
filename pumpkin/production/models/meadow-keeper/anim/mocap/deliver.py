"""Name final GIFs and label the matched old/library comparison artifact."""
from pathlib import Path
import shutil,subprocess
R=Path(__file__).resolve().parent;O=R.parent/'preview/mocap';FF=R.parents[3]/'concepts/refs3/_tools/ffmpeg.exe'
winners={'lob':'A','fan':'C','slam':'E','chase':'G'}
for name,id in winners.items():shutil.copyfile(O/(id+'.gif'),O/(name+'.gif'))
rows=[]
for name,old,new in [('lob','B','A'),('fan','C','D'),('slam','F','E'),('chase','G','H')]:
    for id,recipe in [(old,'old hand-keyed'),(new,'library-derived')]:
        label=name.upper()+' | '+recipe+(' | SELECTED' if winners[name]==id else ' | candidate')
        target=O/(id+'-labelled.jpg');rows.append(target)
        vf="pad=iw:ih+32:0:32:color=white,drawtext=fontfile='C\\:/Windows/Fonts/segoeui.ttf':text='"+label+"':fontcolor=black:fontsize=20:x=8:y=4"
        subprocess.run([str(FF),'-y','-loglevel','error','-i',str(O/(id+'-strip.jpg')),'-vf',vf,'-frames:v','1',str(target)],check=True)
args=[str(FF),'-y','-loglevel','error']
for path in rows:args+=['-i',str(path)]
subprocess.run(args+['-filter_complex','vstack=inputs=8','-frames:v','1',str(O/'OLD-VS-LIBRARY.jpg')],check=True)
for path in [O/(n+'.gif') for n in winners]+[O/(n+'-candidate.gif') for n in ['idle','patrol','return','stun','celebrate','warn','dash']]:
    subprocess.run([str(FF),'-v','error','-i',str(path),'-f','null','-'],check=True)
print('Named four selected attack/move GIFs; labelled comparison; decoded 11 GIFs')
