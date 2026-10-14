"""One bounded post-critic warning revision; emit source patch only."""
import json
from pathlib import Path
R=Path(__file__).resolve().parent
d=json.loads((R/'clips.json').read_text())
for f in d['clips']['warn']['frames']:
    p=f['pose'];t=f['t']
    if .1<=t<=.5:
        p['Torso'][1]=-.55 if t<.3 else .25
        p['Torso'][3]=12 if t<.3 else -9
        p['Arm.L'][3]=-38;p['Arm.L'][5]=-42
        p['Arm.R'][3]=-55;p['Arm.R'][5]=48
        p['Head'][3]=-8;p['Hat'][3]=8 if t<.3 else -7
    if .5<t<1.3:
        p['Arm.R'][3]-=12;p['Arm.L'][3]-=5;p['Hat'][3]+=5
new=json.dumps(d,separators=(',',':'))
luau='local data = game:GetService("HttpService"):JSONDecode([==['+new+']==])\nfor _, clip in pairs(data.clips) do\n for _, frame in ipairs(clip.frames) do\n  for name, v in pairs(frame.pose) do\n   frame.pose[name] = CFrame.new(v[1],v[2],v[3]) * CFrame.Angles(math.rad(v[4]),math.rad(v[5]),math.rad(v[6]))\n  end\n end\nend\nreturn data\n'
print('*** Begin Patch')
for file,content in [('clips.json',new+'\n'),('Clips.luau',luau)]:
    print('*** Update File: '+str(R/file).replace('\\','/')+'\n@@')
    print('\n'.join('-'+line for line in (R/file).read_text().splitlines()))
    print('\n'.join('+'+line for line in content.splitlines()))
print('*** End Patch')
