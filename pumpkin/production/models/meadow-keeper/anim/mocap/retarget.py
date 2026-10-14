"""Quaternius GLB data -> existing Keeper CFrame joints. Generated artifacts only.
Run Blender -b -P this file. Vendor directory remains read-only.
"""
import bpy, json, math, copy
from pathlib import Path
from mathutils import Matrix, Vector
R=Path(__file__).resolve().parent; A=R.parent
P=Path('C:/dev/codex-lab/vendor/quaternius-ual/Universal Animation Library[Standard]')
baseline=R/'hand-keyed.json'
old=json.loads((baseline if baseline.exists() else A/'clips.json').read_text()); sk=json.loads((A/'skeleton.json').read_text())
geometry=json.loads((A/'throw-geometry.json').read_text())
if not baseline.exists():baseline.write_text(json.dumps(old,separators=(',',':')))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(P/'Unreal-Godot/UAL1_Standard.glb'))
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
rig.animation_data_create()
# Source left is +X, source front -Y; Keeper left -X and front +Z.
# Reflection is applied to directions and conjugated rotation matrices, never quaternions.
C=Matrix(((-1,0,0),(0,0,1),(0,-1,0))); CI=C.inverted()
order=sk['jointOrder']; piv={n:Vector(v) for n,v in sk['pivots'].items()}
parents={n:None if v=='Root' else v for n,v in sk['parents'].items()}
def euler(m): return [round(math.degrees(x),5) for x in m.to_euler('ZYX')]
def cf(v): return Matrix.Translation(Vector(v[:3]))@Matrix.Rotation(math.radians(v[3]),4,'X')@Matrix.Rotation(math.radians(v[4]),4,'Y')@Matrix.Rotation(math.radians(v[5]),4,'Z')
def fk(p):
    w={}
    for n in order:
        par=parents[n];w[n]=(w[par] if par else Matrix.Identity(4))@Matrix.Translation(piv[n]-(piv[par] if par else Vector()))@cf(p[n])
    return w
def assign(action,frame):
    rig.animation_data.action=bpy.data.actions[action]
    if hasattr(rig.animation_data,'action_slot') and rig.animation_data.action.slots: rig.animation_data.action_slot=rig.animation_data.action.slots[0]
    bpy.context.scene.frame_set(int(frame),subframe=frame-int(frame));bpy.context.view_layer.update()
def delta(b):
    bone=rig.data.bones[b];return C@(rig.pose.bones[b].matrix.to_3x3()@bone.matrix_local.to_3x3().inverted())@CI
mapping={'Pelvis':'pelvis','Torso':'spine_03','Head':'Head'}
for s in ['L','R']:
    for target,source in [('Arm','upperarm'),('Elbow','lowerarm'),('Wrist','hand'),('Leg','thigh'),('Knee','calf'),('Ankle','foot')]:mapping[target+'.'+s]=source+'_'+s.lower()
def pose(action,phase):
    a=bpy.data.actions[action];assign(action,a.frame_range[0]+phase*(a.frame_range[1]-a.frame_range[0]))
    p={n:[0.0]*6 for n in order};absolute={}
    for n in order:
        par=parents[n]; parentrot=absolute.get(par,Matrix.Identity(3))
        if n=='Hat': rot=parentrot
        elif n.startswith(('Arm.','Elbow.','Leg.','Knee.')):
            b=mapping[n];pb=rig.pose.bones[b]
            child={'Arm':'Elbow','Elbow':'Wrist','Leg':'Knee','Knee':'Ankle'}[n.split('.')[0]]+'.'+n[-1]
            direction=C@(rig.pose.bones[mapping[child]].head-pb.head)
            rest=piv[child]-piv[n]
            rot=rest.rotation_difference(direction).to_matrix()
        else:rot=delta(mapping[n])
        local=parentrot.inverted()@rot
        q=local.to_quaternion();q.angle*=1.2
        p[n][3:]=euler(q.to_matrix());absolute[n]=parentrot@q.to_matrix()
    # Vertical pelvis movement only; game controller owns planar locomotion.
    rest=rig.data.bones['pelvis'].head_local
    p['Pelvis'][1]=round((rig.pose.bones['pelvis'].head.z-rest.z)*3.1,5)
    p['Hat'][3]=-p['Torso'][3]*.22+math.sin(phase*math.tau-.5)*3
    p['Hat'][5]=-p['Torso'][5]*.25+math.sin(phase*math.tau-.8)*2
    return p
def ik(p,s,target,pole):
    w=fk(p);ch=w['Torso']; shoulder=w['Arm.'+s].translation
    u=piv['Elbow.'+s]-piv['Arm.'+s]; f=Vector((0,-1.96,.06))
    d=Vector(target)-shoulder; dist=min(d.length,u.length+f.length-.01);d.normalize()
    bend=Vector(pole)-shoulder;bend-=d*bend.dot(d);bend.normalize()
    along=(u.length_squared+dist*dist-f.length_squared)/(2*dist)
    elbow=shoulder+d*along+bend*math.sqrt(max(0,u.length_squared-along*along)); end=shoulder+d*dist
    ru=u.rotation_difference(ch.to_3x3().inverted()@(elbow-shoulder)).to_matrix()
    p['Arm.'+s]=[0,0,0]+euler(ru)
    rf=f.rotation_difference((ch.to_3x3()@ru).inverted()@(end-elbow)).to_matrix()
    p['Elbow.'+s]=[0,0,0]+euler(rf)
    p['Wrist.'+s]=[0,0,0,0,0,0]
def mix(a,b,x):
    p={}
    for n in order:
        ma,mb=cf(a[n]),cf(b[n]);q=ma.to_quaternion().slerp(mb.to_quaternion(),x)
        p[n]=list(ma.translation.lerp(mb.translation,x))+euler(q.to_matrix())
    return p
neutral=old['clips']['idle']['frames'][0]['pose']
# The library has no throw event. For the spell surrogate, measure the furthest
# forward hand extension, then put that actual source pose on the server deadline.
extensions=[]
for i in range(101):
    assign('Spell_Simple_Shoot',bpy.data.actions['Spell_Simple_Shoot'].frame_range[1]*i/100)
    extensions.append((-rig.pose.bones['hand_r'].head.y,i/100))
release_phase=max(extensions)[1]
sources={'idle':'Idle_Loop','patrol':'Walk_Loop','return':'Walk_Formal_Loop','chase':'Sprint_Loop','stun':'Hit_Head','celebrate':'Dance_Loop','warn':'Spell_Simple_Enter','dash':'Sprint_Loop','fan':'Spell_Simple_Shoot','throw':'Spell_Simple_Shoot','lob':'PickUp_Table','slam':'Jump_Start'}
result=copy.deepcopy(old); provenance={}
for name,action in sources.items():
    clip=copy.deepcopy(old['clips'][name]);duration=clip['duration'];count=80 if name=='chase' else 40
    times=sorted(set([round(duration*i/count,6) for i in range(count+1)]+[m['t'] for m in clip.get('markers',[])]))
    if name in ('lob','fan','throw'):times=sorted(set(times+[.2,.46,.55,.62,.71]))
    if name=='slam':times=sorted(set(times+[.38,.64,.8,.89]))
    frames=[]
    for t in times:
        phase=t/duration
        if name in ('fan','throw'):
            phase=release_phase*max(0,min(1,(t-.35)/.27)) if t<=.62 else release_phase+(1-release_phase)*min(1,(t-.62)/.18)
        if name=='lob':phase=min(1,t/.55)
        p=pose(action,phase)
        if name in ('stun','warn'):p=mix(p,neutral,max(0,(phase-.3)/.7))
        if name=='dash' and t<.5:
            p=pose('Crouch_Fwd_Loop',t/.5);p['Torso'][3]=-18
        if name=='slam':
            p=pose('Jump_Start',min(1,t/.38)) if t<.38 else pose('Jump_Loop',min(1,(t-.38)/.42)) if t<.8 else pose('Jump_Land',min(1,(t-.8)/(duration-.8)))
            p['Pelvis'][1]=(-.65*math.sin(math.pi*t/.38) if t<.38 else 3.8*math.sin(math.pi*(t-.38)/.42) if t<.8 else -.8*math.sin(math.pi*min(1,(t-.8)/.3)))
        if name=='lob':
            # Standard has no heave. Retain captured body gather; solve both hands around
            # an authored overhead support path. Never translate shoulders off the body.
            keys=[(0,4.6,3.5),(.2,5.3,4.0),(.38,8.4,3.0),(.46,10.15,1.1),(.55,10.45,.4),(.62,10.4,1.1),(.71,6.0,4.2),(duration,3.6,1.1)]
            for left,right in zip(keys,keys[1:]):
                if left[0]<=t<=right[0]:
                    x=(t-left[0])/(right[0]-left[0]);height=left[1]*(1-x)+right[1]*x;z=left[2]*(1-x)+right[2]*x;break
            p['Pelvis'][1]=-.5*math.sin(math.pi*min(1,t/.46)) if t<.46 else .45*math.sin(math.pi*min(1,(t-.46)/.25))
            p['Pelvis'][3:]=[0,0,0]
            p['Torso'][3:]=[8 if t<.46 else 0,0,0]
            tuck=max(0,min(1,(t-.05)/.15))*max(0,min(1,(.78-t)/.1))
            p['Head'][3]=-10-55*tuck;p['Hat'][3]=58*tuck-4*math.sin(t*math.tau/duration-.4)
            for s,sgn in [('L',-1),('R',1)]:
                goal=Vector((sgn*2.2,height,z));corrected=goal.copy()
                for iteration in range(5):
                    ik(p,s,corrected,(sgn*5,7,2))
                    actual=fk(p)['Wrist.'+s]@Vector(sk['hand']);corrected+=goal-actual
        if name in ('fan','throw'):
            # Extend captured spell hand at release; no fingers on the mitten rig.
            if .55<=t<=.71:
                accent=math.sin(math.pi*(t-.55)/.16);p['Torso'][4]+=accent*18
                ik(p,'R',(3.2,5.0,3.0+accent*1.0),(5,6,1))
        if not clip['loop']:
            p=mix(neutral,p,min(1,t/.12))
            if t>duration-.18:p=mix(p,neutral,(t-duration+.18)/.18)
        # Match the lowest sole to the floor after proportional retargeting.
        # Keep jump height only in the airborne slam phase; planar travel is gameplay.
        w=fk(p)
        low=min((w[s['rig_part']]@(Vector(v)-piv[s['rig_part']])).y for s in geometry if s['rig_part'].startswith('Ankle.') for v in s['vertices'])
        airborne=3.8*math.sin(math.pi*(t-.38)/.42) if name=='slam' and .38<t<.8 else 0
        p['Pelvis'][1]+=airborne-low
        frames.append({'t':t,'pose':p,'ease':'linear'})
    # Parent quaternion interpolation can dip a sole even with grounded keys.
    # Correct the root envelope at quarter/mid samples, retaining all limb motion.
    for iteration in range(2):
        for left,right in zip(frames,frames[1:]):
            dip=0
            for alpha in [.25,.5,.75]:
                w=fk(mix(left['pose'],right['pose'],alpha))
                low=min((w[s['rig_part']]@(Vector(v)-piv[s['rig_part']])).y for s in geometry if s['rig_part'].startswith('Ankle.') for v in s['vertices'])
                dip=max(dip,-low)
            if dip>0:
                left['pose']['Pelvis'][1]+=dip+.001;right['pose']['Pelvis'][1]+=dip+.001
    if clip['loop']:
        frames[0]['pose']['Pelvis'][1]=max(frames[0]['pose']['Pelvis'][1],frames[-1]['pose']['Pelvis'][1])
        frames[-1]['pose']=copy.deepcopy(frames[0]['pose'])
    clip['frames']=frames;result['clips'][name]=clip
    provenance[name]={'source':action,'gap':name in ('lob','fan','throw','celebrate','warn','dash'),'release':.62 if name in ('lob','fan','throw') else .8 if name=='slam' else None,'sourceReleasePhase':release_phase if name in ('fan','throw') else None}
(R/'candidates.json').write_text(json.dumps(result,separators=(',',':')))
(R/'provenance.json').write_text(json.dumps({'mapping':mapping,'clips':provenance,'note':'CC0 keyframed animation library; recording method UNKNOWN. Mocap-based means library-derived, not verified optical capture.'},indent=2))
print('RETARGETED',len(sources),'clips',flush=True)
