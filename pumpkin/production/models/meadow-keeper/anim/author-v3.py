"""Authored recipes. Emit text for apply_patch; do not mutate sources here.
Variant renders are generated artifacts, not edits to approved geometry.
"""
import copy, json, math, sys
from pathlib import Path
R = Path(__file__).resolve().parent
base = json.loads((R/'clips.json').read_text())
names = base['jointOrder']
def pose(**kwargs):
    p = {n:[0,0,0,0,0,0] for n in names}
    for n,v in kwargs.items(): p[n.replace('_','.')]=v
    return p
def frame(t,p,e='sine'): return dict(t=t,pose=p,ease=e)
def clip(duration, frames, loop=False, markers=None):
    return dict(duration=duration,loop=loop,markers=markers or [],frames=frames)
def idle(style):
    fs=[]
    for i in range(9):
        phase=i*math.pi/4
        fs.append(frame(round(i*.6,4),pose(
            Torso=[.04*math.sin(phase),.09*(1-math.cos(phase)),0,1.5*math.sin(phase),0,1.2*math.sin(phase)],
            Arm_L=[0,0,0,2*math.sin(phase-.3),0,-7],Arm_R=[0,0,0,2*math.sin(phase+.3),0,7],
            Head=[0,0,0,-2, (9 if style==0 else 19)*math.sin(phase),-1*math.sin(phase)],
            Hat=[0,.015*(1-math.cos(phase)),0,1.2*math.sin(phase-.6),0,-1.4*math.sin(phase-.5)])))
    fs[-1]['pose']=copy.deepcopy(fs[0]['pose'])
    return clip(4.8,fs,True)
def chase(style):
    fs=[]
    for i in range(9):
        ph=i*math.pi/4;s=math.cos(ph); lift=math.sin(ph)
        fs.append(frame(round(i*.08,4),pose(
            Torso=[.10*s,-.15-.13*abs(s),.20,-15 if style==0 else -25,4*s,4*s],
            Leg_L=[0,.32*max(0,lift),.12*s,-42*s,0,-5],Leg_R=[0,.32*max(0,-lift),-.12*s,42*s,0,5],
            Arm_L=[-.12,0,0,(-32 if style==0 else -50)*s,0,-16],Arm_R=[.12,0,0,(32 if style==0 else 50)*s,0,16],
            Head=[0,0,0,13,-3*s,-2*s],Hat=[0,.03*abs(lift),0,4*math.sin(ph-.5),0,-4*math.cos(ph-.5)]),'linear'))
    fs[-1]['pose']=copy.deepcopy(fs[0]['pose'])
    return clip(.64,fs,True)
def attack(kind,style):
    # Rigid-arm side load keeps the large hat/face clear; no overhead rock.
    wide=1 if style==0 else 1.35
    def p(y=0,tx=0,twist=0,right=0,left=0,spread=18,hat=0,z=0):
        return pose(Torso=[0,y,z,tx,twist,0],
            Leg_L=[-.24,-y*.40,.25,-tx*.25,0,-5],Leg_R=[.24,-y*.40,-.25,tx*.25,0,5],
            Arm_L=[-.2*wide,0,0,left,0,-spread*wide],Arm_R=[.45*wide,0,0,right,0,spread*wide],
            Head=[0,0,0,-tx*.7,-twist,0],Hat=[0,max(0,abs(hat)*.006),0,hat,0,-hat*.4])
    if kind=='lob':
        fs=[frame(0,p()),frame(.16,p(-.45,10,15,30,-25,24,-3),'in'),
            frame(.34,p(-.35,6,32,75,-38,45,4),'out'),frame(.50,p(-.38,8,35,85,-32,48,1)),
            frame(.57,p(-.10,-12,8,-75,25,65,-6,.35),'in'),
            frame(.62,p(-.18,-20,-20,-65,35,58,6,.65),'linear'),
            frame(.71,p(-.36,-27,-30,-38,55,65,9,.75),'out'),
            frame(1.02,p(-.22,-14,-12,-15,25,32,-4,.3)),frame(1.32,p(-.06,3,5,-8,-8,20,2)),frame(1.52,p())]
        return clip(1.52,fs,markers=[dict(t=0,name='AimLock'),dict(t=.62,name='Release')])
    if kind=='fan':
        fs=[frame(0,p()),frame(.14,p(-.3,8,-20,15,-25,25,-3),'in'),
            frame(.34,p(-.24,5,-35,-20,-35,28,3),'out'),frame(.50,p(-.26,7,-38,-25,-40,30,0)),
            frame(.57,p(-.12,-8,-10,-55,-15,55,-5,.25),'in'),
            frame(.62,p(-.16,-12,25,-60,25,72,6,.45),'linear'),
            frame(.71,p(-.25,-18,36,-32,40,80,8,.55),'out'),
            frame(.96,p(-.14,-7,12,-18,12,38,-4,.20)),frame(1.32,p())]
        return clip(1.32,fs,markers=[dict(t=0,name='AimLock'),dict(t=.62,name='Release')])
    fs=[frame(0,p()),frame(.18,p(-.65,14,0,30,30,24,-4),'in'),
        frame(.38,p(-.78,18,0,38,38,32,3)),frame(.50,p(.55,-7,0,-35,-35,65,-6),'out'),
        frame(.64,p(1.50,-8,0,-45,-45,75,5)),frame(.74,p(.65,8,0,-55,-55,55,8),'in'),
        frame(.80,p(-.85,20,0,-35,-35,38,11,.25),'in'),frame(.89,p(-.58,12,0,-25,-25,40,-7,.18),'out'),
        frame(1.16,p(-.30,5,0,-10,-10,22,4)),frame(1.50,p(-.10,2,0,0,0,18,-2)),frame(1.72,p())]
    return clip(1.72,fs,markers=[dict(t=.50,name='Takeoff'),dict(t=.80,name='Land')])
recipes={k:[idle(i) if k=='idle' else chase(i) if k=='chase' else attack(k,i) for i in range(2)] for k in ['idle','chase','lob','fan','slam']}
# Deterministic shuffled neutral IDs; mapping is withheld from critic.
ids={'idle':['Q','M'],'chase':['V','J'],'lob':['D','X'],'fan':['H','B'],'slam':['N','S']}
if '--variants' in sys.argv:
    data=copy.deepcopy(base);data['clips']={ids[k][i]:recipes[k][i] for k in recipes for i in range(2)}
elif '--final' in sys.argv:
    selection=dict(zip(recipes, map(int,sys.argv[sys.argv.index('--final')+1].split(','))))
    data=copy.deepcopy(base)
    for k,i in selection.items(): data['clips'][k]=recipes[k][i]
    # Post-blind polish: outward release, low fan fist, heavier planted landing.
    for k in ('lob','fan'):
        for f in data['clips'][k]['frames']:
            p=f['pose'];t=f['t']
            if .50 <= t <= .71:
                p['Arm.R'][0] += 1.25 if k=='lob' else .50
                if k=='fan':
                    p['Arm.R'][1] -= 2.0
                    p['Arm.R'][3] += 30
                    p['Arm.R'][5] -= 15
                    p['Arm.L'][1] -= .65
            if t==.71:
                p['Hat'][3]=10;p['Arm.L'][3]+=8
    for f in data['clips']['slam']['frames']:
        if f['t']==.80:
            f['pose']['Torso'][1]=-1.15
            f['pose']['Leg.L'][1]=.42;f['pose']['Leg.R'][1]=.42
            f['pose']['Hat'][3]=12
        if f['t']==.89: f['pose']['Hat'][3]=-9
    for f in data['clips']['chase']['frames']:
        if f['t'] in (0,.32,.64): f['pose']['Torso'][1]-=.06
else: raise SystemExit('Use --variants or --final JSON-selection')
if '--luau' in sys.argv:
    print('local data = game:GetService("HttpService"):JSONDecode([==['+json.dumps(data,separators=(',',':'))+']==])\nfor _, clip in pairs(data.clips) do\n for _, frame in ipairs(clip.frames) do\n  for name, v in pairs(frame.pose) do\n   frame.pose[name] = CFrame.new(v[1],v[2],v[3]) * CFrame.Angles(math.rad(v[4]),math.rad(v[5]),math.rad(v[6]))\n  end\n end\nend\nreturn data')
else: print(json.dumps(data,separators=(',',':')))
