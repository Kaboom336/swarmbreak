"""Blend inspected CC0 GLB data; seven rigid parts in the existing joint schema.
Only generated animation artifacts are written. Source installation emits a patch.
"""
import bpy, json, math, copy, sys, hashlib
from pathlib import Path
from mathutils import Matrix, Vector
R=Path(__file__).resolve().parent; A=R.parent
scope={'__file__':str(R/'retarget.py')}
exec((R/'retarget.py').read_text().split('neutral=')[0],scope)
globals().update({k:v for k,v in scope.items() if k not in ('__file__','__name__')})
current=json.loads((A/'clips.json').read_text())
zero={n:[0.0]*6 for n in order}
def rigid(action,phase):
    act=bpy.data.actions[action]
    assign(action,act.frame_range[0]+phase*(act.frame_range[1]-act.frame_range[0]))
    p=copy.deepcopy(zero); body=delta('spine_03')
    p['Torso'][3:]=euler(body)
    for side in ['L','R']:
        s=side.lower()
        for joint,first,last,end in [('Arm','upperarm','hand',piv['Wrist.'+side]+Vector(sk['hand'])),('Leg','thigh','foot',piv['Ankle.'+side])]:
            direction=C@(rig.pose.bones[last+'_'+s].head-rig.pose.bones[first+'_'+s].head)
            absolute=(end-piv[joint+'.'+side]).rotation_difference(direction).to_matrix()
            p[joint+'.'+side][3:]=euler((body.inverted() if joint=='Arm' else Matrix.Identity(3))@absolute)
    p['Head'][3:]=euler(body.inverted()@delta('Head'))
    return p
def forward_peak(action):
    scores=[]
    for i in range(101):
        act=bpy.data.actions[action];assign(action,act.frame_range[0]+i/100*(act.frame_range[1]-act.frame_range[0]))
        d=C@(rig.pose.bones['hand_r'].head-rig.pose.bones['upperarm_r'].head)
        scores.append((d.z,i/100))
    return max(scores)[1]
def curve(keys,t):
    for (ta,va),(tb,vb) in zip(keys,keys[1:]):
        if ta<=t<=tb:
            x=(t-ta)/(tb-ta);return va+(vb-va)*x
    return keys[-1][1]
def direct(p,side,target,weight):
    w=fk(p); d=Vector(target)-w['Arm.'+side].translation
    rest=piv['Wrist.'+side]+Vector(sk['hand'])-piv['Arm.'+side]
    absolute=rest.rotation_difference(d).to_matrix()
    local=w['Torso'].to_3x3().inverted()@absolute
    q=cf(p['Arm.'+side]).to_quaternion().slerp(local.to_quaternion(),weight)
    p['Arm.'+side][3:]=euler(q.to_matrix())
def lowest(p):
    w=fk(p)
    return min((w[s['rig_part']]@(Vector(v)-piv[s['rig_part']])).y for s in geometry if s['rig_part'].startswith('Ankle.') for v in s['vertices'])
result={};provenance={}
for id,action,step_phase,gain in [('M','Punch_Cross',.14,1.0),('Q','Sword_Attack',.36,1.2)]:
    peak=forward_peak(action); clip=copy.deepcopy(current['clips']['fan']);duration=clip['duration']
    times=sorted(set([round(duration*i/96,6) for i in range(97)]+[.2,.42,.52,.58,.62,.66,.72,.84,1.02]+[m['t'] for m in clip['markers']]))
    frames=[]
    for t in times:
        # Deliberate anticipation hold, 100ms acceleration, 220ms cross-body finish.
        phase=curve([(0,0),(.2,.06),(.42,peak*.3),(.52,peak*.38),(.62,peak),(.84,min(1,peak+.28)),(duration,1)],t)
        arm=rigid(action,phase);legs=rigid('Walk_Loop',(step_phase+curve([(0,0),(.42,.08),(.62,.24),(.84,.3),(duration,.4)],t))%1)
        p=mix(legs,arm,.72)
        for n in ['Leg.L','Leg.R']:p[n]=legs[n]
        load=curve([(0,0),(.2,.45),(.42,1),(.52,1),(.62,-.45),(.72,-1),(.84,-.8),(duration,0)],t)
        p['Torso'][4]+=load*-30*gain
        p['Torso'][3]+=curve([(0,0),(.42,-7),(.52,-9),(.62,10),(.72,15),(.84,8),(duration,0)],t)
        p['Torso'][5]+=load*5
        # Compress captured hand path onto the short rigid mitten arm; preserve 35% library direction.
        x=curve([(0,3.2),(.2,4.5),(.42,5.2),(.52,5.0),(.62,2.6),(.72,-.8),(.84,-2.2),(duration,3.2)],t)
        y=curve([(0,3.5),(.42,6.2),(.52,6.0),(.62,5.4),(.72,4.7),(.84,4.2),(duration,3.5)],t)
        z=curve([(0,1.0),(.42,-2.0),(.52,-1.8),(.62,4.2),(.72,4.0),(.84,2.9),(duration,1.0)],t)
        if id=='Q':y+=1.5*max(0,min(1,t/.42))*max(0,min(1,(.72-t)/.2))
        direct(p,'R',(x,y,z),.65)
        direct(p,'L',(-4.4,4.4,2.6 if t<.52 else -.4),.45)
        p['Head'][3:]=[-p['Torso'][3]*.55,-p['Torso'][4]*.65,-p['Torso'][5]*.5]
        p['Hat'][3]=-p['Torso'][3]*.22;p['Hat'][5]=math.sin(t*8-1)*4*math.sin(math.pi*t/duration)
        envelope=min(1,t/.18)*min(1,(duration-t)/.28)
        p=mix(zero,p,max(0,envelope))
        # No independent elbow/knee/wrist/ankle or pelvis rotations: exactly seven moving rigid parts.
        p['Pelvis'][1]=max(0,-lowest(p))+.012
        frames.append({'t':t,'pose':p,'ease':'linear'})
    clip['frames']=frames;result[id]=clip
    provenance[id]={'arm':action,'legs':'Walk_Loop','sourceExtensionPhase':peak,'libraryArmWeight':.35,'release':.62,'rigidParts':7}
result['T']=copy.deepcopy(current['clips']['fan'])
(R/'fan-v2-candidates.json').write_text(json.dumps(result,separators=(',',':')))
(R/'fan-v2-provenance.json').write_text(json.dumps(provenance,indent=2))
print('Built two data-blended rigid variants; production source untouched',flush=True)
