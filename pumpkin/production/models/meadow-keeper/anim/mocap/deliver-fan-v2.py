"""Deliver the retained baseline and a labelled three-way comparison."""
from pathlib import Path
import shutil,subprocess,json,hashlib
R=Path(__file__).resolve().parent;A=R.parent;O=A/'preview/mocap';FF=A.parents[2]/'concepts/refs3/_tools/ffmpeg.exe'
# Both variant means are below the user-specified 6/10 incumbent threshold.
# Keep production source and package byte-for-byte untouched.
shutil.copyfile(O/'fan-v2-T.gif',O/'fan-v2.gif')
labels={'T':'RETAINED hand-keyed | gate 6/10 | fresh blind 5 and 4', 'M':'Punch Cross + Walk | blind 6.2 and 5 | mean 5.6 | rejected', 'Q':'Sword Attack + Walk | blind 5.7 and 6 | mean 5.85 | rejected'}
rows=[]
for id in ['T','M','Q']:
    path=O/f'fan-v2-{id}-labelled.jpg';rows.append(path)
    vf="pad=iw:ih+36:0:36:color=white,drawtext=fontfile='C\\:/Windows/Fonts/segoeui.ttf':text='"+labels[id]+"':fontcolor=black:fontsize=20:x=8:y=6"
    subprocess.run([str(FF),'-y','-loglevel','error','-i',str(O/f'fan-v2-{id}-strip.jpg'),'-vf',vf,'-frames:v','1',str(path)],check=True)
args=[str(FF),'-y','-loglevel','error']
for path in rows:args+=['-i',str(path)]
subprocess.run(args+['-filter_complex','vstack=inputs=3','-frames:v','1',str(O/'fan-v2-comparison.jpg')],check=True)
for name in ['fan-v2.gif','fan-v2-M.gif','fan-v2-Q.gif']:
    subprocess.run([str(FF),'-v','error','-i',str(O/name),'-f','null','-'],check=True)
manifest={'selected':'T','productionChanged':False,'gate':6,'scores':{'M':[6.2,5],'Q':[5.7,6],'T':[5,4]},'unchangedSources':{name:hashlib.sha256((A/name).read_bytes()).hexdigest() for name in ['clips.json','Clips.luau','MeadowKeeperAnimations.rbxmx']},'preview':'fan-v2.gif','strip':'fan-v2-comparison.jpg'}
(R/'fan-v2-result.json').write_text(json.dumps(manifest,indent=2))
print('Retained baseline; GIFs decoded; three-way strip delivered')
