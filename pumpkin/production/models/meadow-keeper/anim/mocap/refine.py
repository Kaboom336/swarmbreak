"""Reviewer correction; reuse CC0 hybrid and original chase. Emit source patches."""
import json, math, copy, sys
from pathlib import Path
from mathutils import Matrix, Vector
R=Path(__file__).resolve().parent; A=R.parent
scope={'__file__':str(R/'check.py')}
exec((R/'check.py').read_text().split('report={}')[0],scope)
cf=scope['cf']; fk=scope['world']; S=scope['S']; G=scope['G']; piv=scope['piv']
d=json.loads((R/'pre-review-candidates.json').read_text()); old=json.loads((R/'hand-keyed.json').read_text())
def angles(m):return [math.degrees(v) for v in m.to_euler('ZYX')]
def ik(p,s,goal):
    # Existing articulated two-bone solver, with actual mitten centre correction.
    for _ in range(7):
        w=fk(p); sh=w['Arm.'+s].translation; chest=w['Torso'].to_3x3()
        u=piv['Elbow.'+s]-piv['Arm.'+s]; f=Vector((0,-1.96,.06))
        target=goal if _==0 else target+goal-(w['Wrist.'+s]@Vector(S['hand']))
        delta=target-sh; dist=min(delta.length,u.length+f.length-.01); delta.normalize()
        pole=Vector((-5 if s=='L' else 5,7,2))-sh; pole-=delta*pole.dot(delta);pole.normalize()
        along=(u.length_squared+dist*dist-f.length_squared)/(2*dist)
        elbow=delta*along+pole*math.sqrt(max(0,u.length_squared-along*along))
        ru=u.rotation_difference(chest.inverted()@elbow).to_matrix()
        rf=f.rotation_difference((chest@ru).inverted()@(delta*dist-elbow)).to_matrix()
        p['Arm.'+s]=[0,0,0]+angles(ru);p['Elbow.'+s]=[0,0,0]+angles(rf)
def low(p):
    w=fk(p)
    return min((w[s['rig_part']]@(Vector(v)-piv[s['rig_part']])).y for s in G if s['rig_part'].startswith('Ankle.') for v in s['vertices'])
for frame in d['clips']['lob']['frames']:
    t=frame['t'];p=frame['pose']
    if .12<t<.94:
        spread=max(0,min(1,(t-.12)/.08))*max(0,min(1,(.94-t)/.16))
        w=fk(p)
        for s in ['L','R']:
            goal=w['Wrist.'+s]@Vector(S['hand'])
            goal.x+=(-1 if s=='L' else 1)*1.35*spread
            ik(p,s,goal)
    if .46<=t<=.94:
        ramp=max(0,min(1,(t-.46)/.16));recover=max(0,min(1,(.94-t)/.23));step=ramp*recover
        w=fk(p); goals={s:w['Wrist.'+s]@Vector(S['hand']) for s in ['L','R']}
        p['Pelvis'][2]+=.65*step;p['Torso'][3]+=18*step
        p['Leg.L'][3]-=18*step;p['Knee.L'][3]+=10*step
        p['Leg.R'][3]+=8*step
        snap=max(0,min(1,(t-.585)/.035))*max(0,min(1,(.78-t)/.16))
        for s in ['L','R']:ik(p,s,goals[s]+Vector((0,.25*step,1.25*snap)))
    p['Pelvis'][1]+=max(0,-low(p))+.015
selected=json.loads((R/'selected.json').read_text())
selected['clips']['chase']=copy.deepcopy(old['clips']['chase'])
chase=selected['clips']['chase']; keys=chase['frames']; frames=[]
for i in range(81):
    t=chase['duration']*i/80
    l,r=next((l,r) for l,r in zip(keys,keys[1:]) if l['t']<=t<=r['t'])
    a=(t-l['t'])/(r['t']-l['t']);style=r['ease']
    a=(1-math.cos(math.pi*a))/2 if style=='sine' else a*a if style=='in' else 1-(1-a)**2 if style=='out' else a
    p={}
    for n in S['jointOrder']:
        lm,rm=cf(l['pose'][n]),cf(r['pose'][n])
        p[n]=list(lm.translation.lerp(rm.translation,a))+angles(lm.to_quaternion().slerp(rm.to_quaternion(),a).to_matrix())
    p['Pelvis'][1]+=max(0,-low(p))+.02
    frames.append({'t':t,'pose':p,'ease':'linear'})
frames[-1]['pose']=copy.deepcopy(frames[0]['pose']);chase['frames']=frames
selected['clips']['lob']=d['clips']['lob']
(R/'refined-candidates.json').write_text(json.dumps(d,separators=(',',':')))
(R/'refined-selected.json').write_text(json.dumps(selected,separators=(',',':')))
for path,data in [(R/'candidates.json',d),(R/'selected.json',selected),(A/'clips.json',selected),(A/'Clips.luau',selected)]:
    original=path.read_text();result=json.dumps(data,separators=(',',':'))
    if path.suffix=='.luau':result=original[:original.index('[==[')+4]+result+original[original.index(']==]'):]
    print('*** Begin Patch\n*** Update File: '+str(path).replace('\\','/')+'\n@@\n'+'\n'.join('-'+v for v in original.splitlines())+'\n'+'\n'.join('+'+v for v in result.splitlines())+'\n*** End Patch')
