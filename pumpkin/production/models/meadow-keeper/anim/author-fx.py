"""Emit an apply_patch; all authored text mutation goes through apply_patch."""
import json, copy
from pathlib import Path
R=Path(__file__).resolve().parent
d=json.loads((R/'clips.json').read_text())
for f in d['clips']['lob']['frames']:
    t=f['t'];p=f['pose']
    # Raise the outside hand above the hat, while leaving the release exact.
    if t < .57:
        p['Arm.R'][0]+=3.7
        p['Arm.R'][1]+=2.6 if t>=.34 else 1.5
        if t in (.34,.5): p['Arm.R'][3]=145;p['Arm.R'][5]=48
    if t in (.57,.62,.71): p['Arm.R'][0]+=2.7
    if t>=.71: p['Hat'][3]+=6 if t==.71 else -3
for f in d['clips']['slam']['frames']:
    t=f['t'];p=f['pose']
    if t in (.18,.38):
        p['Torso'][1]-=.85;p['Torso'][3]+=9
        for side in ['Leg.L','Leg.R']: p[side][1]+=.4;p[side][3]-=15
    if t==.5: p['Torso'][1]=1.2
    if t==.64: p['Torso'][1]=3.8
    if t==.74: p['Torso'][1]=1.6
    if t==.8:
        p['Torso'][1]=-1.65;p['Torso'][3]=28
        p['Leg.L'][1]=.62;p['Leg.R'][1]=.62;p['Hat'][3]=18
    if t==.89: p['Hat'][3]=-14;p['Arm.L'][3]-=10
def frame(t,lean,y,arms,hat,leg=0):
    p={n:[0,0,0,0,0,0] for n in d['jointOrder']}
    p['Torso']=[0,y,0,lean,0,0];p['Head']=[0,0,0,-lean*.35,0,0]
    p['Arm.L']=[-.3,0,0,arms,0,-22];p['Arm.R']=[.3,0,0,arms+7,0,22]
    p['Hat']=[0,.05,0,hat,0,0]
    p['Leg.L']=[-.3,0,.15,leg,0,-5];p['Leg.R']=[.3,0,-.15,-leg,0,5]
    return dict(t=t,ease='sine',pose=p)
d['clips']['dash']=dict(duration=1,loop=False,markers=[dict(t=.5,name='Charge')],frames=[
    frame(0,0,0,0,0),frame(.15,-18,-.45,24,6,14),frame(.32,-29,-.65,40,10,-18),
    frame(.5,-35,-.65,60,-7,24),frame(.65,-33,-.5,48,8,-24),frame(.8,-34,-.6,58,-5,24),frame(1,-12,-.2,18,7,0)])
new=json.dumps(d,separators=(',',':'))
luau='local data = game:GetService("HttpService"):JSONDecode([==['+new+']==])\nfor _, clip in pairs(data.clips) do\n for _, frame in ipairs(clip.frames) do\n  for name, v in pairs(frame.pose) do\n   frame.pose[name] = CFrame.new(v[1],v[2],v[3]) * CFrame.Angles(math.rad(v[4]),math.rad(v[5]),math.rad(v[6]))\n  end\n end\nend\nreturn data\n'
print('*** Begin Patch')
for filename,content in [('clips.json',new+'\n'),('Clips.luau',luau)]:
    print('*** Update File: '+str(R/filename).replace('\\','/'));print('@@')
    for line in (R/filename).read_text().splitlines(): print('-'+line)
    for line in content.splitlines(): print('+'+line)
print('*** End Patch')
