"""Blender math authoring; emit apply_patch only. Original meshes stay untouched."""
import json, copy, math, sys
from pathlib import Path
from mathutils import Vector, Matrix
R=Path(__file__).resolve().parent
base=json.loads((R/'backup-pre-throw/clips.json').read_text())
geo=json.loads((R.parent/'blender/meadow-keeper_parts.json').read_text())
pivots={s['rig_part']:s['pivot'] for s in geo}
pivots['Pelvis']=pivots['Torso'][:]
for side,sgn in [('L',-1),('R',1)]:
    pivots['Elbow.'+side]=[sgn*3.14,5.05,0]
    pivots['Wrist.'+side]=[sgn*3.14,3.85,0]
    pivots['Knee.'+side]=[sgn*1.1910828,1.55,0]
    pivots['Ankle.'+side]=[sgn*1.1910828,.75,0]
order=['Pelvis','Torso','Leg.L','Knee.L','Ankle.L','Leg.R','Knee.R','Ankle.R','Arm.L','Elbow.L','Wrist.L','Arm.R','Elbow.R','Wrist.R','Head','Hat']
parents={'Pelvis':None,'Torso':'Pelvis','Leg.L':'Pelvis','Leg.R':'Pelvis','Knee.L':'Leg.L','Knee.R':'Leg.R','Arm.L':'Torso','Arm.R':'Torso','Elbow.L':'Arm.L','Elbow.R':'Arm.R','Wrist.L':'Elbow.L','Wrist.R':'Elbow.R','Head':'Torso','Hat':'Head'}
parents.update({'Ankle.L':'Knee.L','Ankle.R':'Knee.R'})
def clip_poly(poly,y,above):
    out=[]
    for a,b in zip(poly,poly[1:]+poly[:1]):
        ia=(a[1]>=y) if above else (a[1]<=y)
        ib=(b[1]>=y) if above else (b[1]<=y)
        if ia:out.append(a)
        if ia!=ib:
            q=a.lerp(b,(y-a[1])/(b[1]-a[1]));out.append(q)
    return out
geometry=[]
for s in geo:
    j=s['rig_part'];zones=[(j,None,None)]
    if j.startswith('Arm.'):
        side=j[-1];zones=[(j,5.05,None),('Elbow.'+side,3.85,5.05),('Wrist.'+side,None,3.85)]
    if j.startswith('Leg.'):
        zones=[(j,1.55,None),('Knee.'+j[-1],.75,1.55),('Ankle.'+j[-1],None,.75)]
        if s['material'] in ['Boots','BootEdge','Cuff']:zones=[('Ankle.'+j[-1],None,None)]
    for joint,low,high in zones:
        verts=[];tris=[];boundary={}
        for tri in s['triangles']:
            poly=[Vector(s['vertices'][i]) for i in tri]
            if low is not None:poly=clip_poly(poly,low,True)
            if high is not None:poly=clip_poly(poly,high,False)
            if len(poly)<3:continue
            start=len(verts);verts.extend([list(v) for v in poly])
            tris.extend([[start,start+i,start+i+1] for i in range(1,len(poly)-1)])
            for y in [low,high]:
                if y is not None:
                    points=boundary.setdefault(y,{})
                    for v in poly:
                        if abs(v.y-y)<1e-5:points[tuple(round(x,5) for x in v)]=v
        # Close cut planes so elbow/knee bends don't reveal hollow sleeves.
        for y,points in boundary.items():
            ring=list(points.values())
            if len(ring)<3:continue
            center=sum(ring,Vector())/len(ring)
            ring.sort(key=lambda v:math.atan2(v.z-center.z,v.x-center.x))
            start=len(verts);verts.extend([list(center)]+[list(v) for v in ring])
            for i in range(len(ring)):
                tri=[start,start+1+i,start+1+(i+1)%len(ring)]
                tris.append(tri if y==low else tri[::-1])
        if verts:
            unique=[];lookup={};remap=[]
            for v in verts:
                key=tuple(round(x,5) for x in v)
                if key not in lookup:lookup[key]=len(unique);unique.append(list(key))
                remap.append(lookup[key])
            verts=unique;tris=[[remap[i] for i in tri] for tri in tris]
            q=copy.deepcopy(s);q.update(name=s['name']+'_'+joint,rig_part=joint,pivot=pivots[joint],vertices=verts,triangles=tris);geometry.append(q)
def cf(v):
    return Matrix.Translation(Vector(v[:3]))@Matrix.Rotation(math.radians(v[3]),4,'X')@Matrix.Rotation(math.radians(v[4]),4,'Y')@Matrix.Rotation(math.radians(v[5]),4,'Z')
def angles(m):return [round(math.degrees(a),5) for a in m.to_euler('ZYX')]
def world(p):
    w={}
    for j in order:
        par=parents[j];off=Vector(pivots[j])-(Vector(pivots[par]) if par else Vector())
        w[j]=(w[par] if par else Matrix.Identity(4))@Matrix.Translation(off)@cf(p[j])
    return w
idle=base['clips']['idle']['frames'][0]['pose']
def blank():
    p={j:[0]*6 for j in order}
    p['Pelvis']=idle['Torso'][:]
    for j in idle:
        if j!='Torso':p[j]=idle[j][:]
    return p
def ik(p,side,target,bend):
    # Two-bone solve in chest space; glove remains a separate wrist joint.
    w=world(p);chest=w['Torso'];shoulder=chest@Vector(pivots['Arm.'+side])-chest@Vector(pivots['Torso'])+chest.translation
    # Actual shoulder is FK carrier (not world-pivot addition).
    shoulder=w['Arm.'+side].translation
    upper=Vector(pivots['Elbow.'+side])-Vector(pivots['Arm.'+side])
    hand=Vector(((-1 if side=='L' else 1)*3.14,3.09,.06))
    fore=hand-Vector(pivots['Elbow.'+side])
    a,b=upper.length,fore.length;delta=Vector(target)-shoulder;dist=min(delta.length,a+b-.02)
    direction=delta.normalized();pole=Vector(bend)-direction*Vector(bend).dot(direction)
    if pole.length<.01:pole=Vector((0,1,0))
    pole.normalize();along=(a*a+dist*dist-b*b)/(2*dist);height=math.sqrt(max(0,a*a-along*along))
    elbow=shoulder+direction*along+pole*height;end=shoulder+direction*dist
    rotU=upper.rotation_difference(chest.to_3x3().inverted()@(elbow-shoulder)).to_matrix()
    p['Arm.'+side]=[0,0,0]+angles(rotU)
    rotF=fore.rotation_difference((chest.to_3x3()@rotU).inverted()@(end-elbow)).to_matrix()
    p['Elbow.'+side]=[0,0,0]+angles(rotF)
def candidate(kind,style):
    # load, stride, hips lead, chest follows, elbow leads, release, overlap, recoil, recover
    ts=[0,.20,.40,.495,.535,.575,.62,.66,.74,.90,1.10]
    load=[0,.55,1,1,.75,.4,0,0,0,0,0]
    hip=[0,-18,-38,-12,16,34,42,44,30,10,0]
    chest=[0,-10,-20,-46,-39,-20,-9,3,10,3,0]
    y=[0,-.22,-.25,-.25,-.10,.15,.35,-.12,-.25,-.10,0] if kind=='lob' else [0,-.12,-.22,-.20,-.30,-.35,-.35,-.32,-.30,-.12,0]
    lean=[0,-3,-8,-7,-2,4,12,20,27,13,0]
    if kind=='lob':
        hip=[0,-8,-16,-8,8,14,18,20,12,5,0]
        chest=[0,4,14,-2,-16,-18,-18,-16,-8,-3,0]
    else:
        hip=[-v for v in hip];chest=[-v for v in chest]
    step=[0,0,.35,.85,1,1,1,1,.9,.5,0]
    fs=[]
    for i,t in enumerate(ts):
        p=blank();l=load[i];s=step[i];variation=1.0 if style==0 else 1.24
        p['Pelvis']=[.40*l,y[i],-.85*l+(1.05 if kind=='lob' else 1.5)*s,0,hip[i]*variation,0]
        p['Torso']=[0,0,0,lean[i],chest[i]*variation,0]
        # Legs counter hip yaw; grounded lead foot moves forward while rear heel drags.
        # Two-bone planted soles: the step belongs to the opposite (left) foot.
        for side,sign in [('L',-1),('R',1)]:
            w=world(p);hipPos=w['Leg.'+side].translation
            hop=(.40 if i==5 else .50 if i==6 else 0) if kind=='lob' else 0
            sole=Vector((sign*1.1910828,.77+hop+(max(0,s)*.48 if side=='R' and i>=6 else 0),(1.65*s if side=='L' else -.6*l+.3*s)))
            upper=Vector(pivots['Knee.'+side])-Vector(pivots['Leg.'+side]);lower=Vector((0,-.8,0))
            delta=sole-hipPos;a,b=upper.length,lower.length;dist=min(delta.length,a+b-.005);direction=delta.normalized()
            pole=Vector((0,0,1));pole=(pole-direction*pole.dot(direction)).normalized()
            along=(a*a+dist*dist-b*b)/(2*dist);knee=hipPos+direction*along+pole*math.sqrt(max(0,a*a-along*along));end=hipPos+direction*dist
            parentRot=w['Pelvis'].to_3x3();rot=upper.rotation_difference(parentRot.inverted()@(knee-hipPos)).to_matrix()
            p['Leg.'+side]=[0,0,0]+angles(rot)
            p['Knee.'+side]=[0,0,0]+angles(lower.rotation_difference((parentRot@rot).inverted()@(end-knee)).to_matrix())
            ankleRot=world(p)['Knee.'+side].to_3x3().inverted()
            p['Ankle.'+side]=[0,0,0]+angles(ankleRot)
        w=world(p)
        # Inverse chest orientation: eyes remain forward even during pelvis separation.
        p['Head']=[0,0,0]+angles(w['Torso'].to_3x3().inverted())
        hat=[0,-2,3,2,-4,-7,-5,9,7,-3,0][i]
        if kind=='lob':hat=[0,-3,-12,-18,-25,-38,-42,-42,-10,-3,0][i]
        p['Hat']=[0,0,0,hat,0,-hat*.25]
        if kind=='lob':
            heights=[3.10,5.1,6.9,7.3,7.8,8.8,9.0,8.2,4.5,3.6,3.1]
            fronts=[.06,2.4,3.7,3.7,3.8,3.8,4.0,5.2,4.0,1,.06]
            spread=[3.14,2.1,1.5,1.4,1.3,1.1,1.1,3.4,2.6,2.9,3.14]
            for side,sign in [('L',-1),('R',1)]:
                target=(sign*spread[i],heights[i]+y[i],fronts[i]+.65*s)
                ik(p,side,target,(sign*(1.5 if style==0 else 2.5),-.3,-1))
                p['Wrist.'+side]=[0,0,0,(-12 if i<6 else 24 if i==6 else 8 if i==7 else 0),0,sign*4*l]
        else:
            targets=[(3.14,3.09,.06),(3.5,4.5,-1.0),(3.8,5.0,-2.0),(4.3,4.7,-2.1),(4.5,4.8,-.7),(4.6,4.65,1.5),(3.0,4.9,3.65),(.0,4.5,3.2),(-.4,3.4,2.1),(1.8,3.1,1),(3.14,3.09,.06)]
            target=targets[i];ik(p,'R',(target[0],target[1]+y[i],target[2]+.65*s),(0,1,-2 if style==0 else -3))
            support=[(-3.14,3.09,.06),(-2.7,5.4,2.2),(-2,5.9,3.1),(-1.8,6.0,3.2),(-1.8,5.0,2.4),(-1.6,4.8,1.2),(-1.6,4.6,.8),(-1.7,4.7,.6),(-2.1,4,.4),(-2.6,3.5,.3),(-3.14,3.09,.06)][i]
            ik(p,'L',(support[0],support[1]+y[i],support[2]+.65*s),(-1,-1,-1))
            p['Wrist.R']=[0,0,0,0,[-0,-12,-28,-28,-24,-18,24,16,7,0,0][i],0]
        if i in [0,len(ts)-1]:p=blank()
        fs.append(dict(t=t,ease='in' if i in [1,4,5] else 'linear' if i==6 else 'out',pose=p))
    # Bake constrained ankle carriers at 60 fps. Interpolating parent/local rotations
    # alone creates a false sinking arc even when both endpoint poses are planted.
    dense=[]
    times=sorted(set([round(i/60,6) for i in range(67)]+ts))
    for t in times:
        a,b=fs[0],fs[-1]
        for n in range(1,len(fs)):
            if t<=fs[n]['t']:a,b=fs[n-1:n+1];break
        u=(t-a['t'])/(b['t']-a['t']);styleEase=b['ease'];u=u*u if styleEase=='in' else 1-(1-u)**2 if styleEase=='out' else u
        p={}
        for j in order:
            ma,mb=cf(a['pose'][j]),cf(b['pose'][j]);m=ma.to_quaternion().slerp(mb.to_quaternion(),u).to_matrix().to_4x4();m.translation=ma.translation.lerp(mb.translation,u)
            p[j]=list(m.translation)+angles(m)
        wa,wb=world(a['pose']),world(b['pose'])
        for side,sign in [('L',-1),('R',1)]:
            handOffset=Vector((0,-.76,.06));goal=(wa['Wrist.'+side]@handOffset).lerp(wb['Wrist.'+side]@handOffset,u);corrected=goal.copy()
            for iteration in range(3):
                ik(p,side,corrected,(sign*1.5,-.3,-1) if kind=='lob' else (0,1,-2) if side=='R' else (-1,-1,-1))
                end=world(p)['Wrist.'+side]@handOffset;corrected+=goal-end
        for side in ['L','R']:
            name='Ankle.'+side;current=world(p)[name];target=wa[name].translation.lerp(wb[name].translation,u)
            # Pose-space ankle correction keeps the boot solidly connected to its calf.
            # Solve thigh and calf again against the interpolated planted ankle target.
            w=world(p);hp=w['Leg.'+side].translation;upper=Vector(pivots['Knee.'+side])-Vector(pivots['Leg.'+side]);lower=Vector((0,-.8,0));aLen,bLen=upper.length,lower.length
            delta=target-hp;dist=min(delta.length,aLen+bLen-.005);direction=delta.normalized();pole=Vector((0,0,1));pole=(pole-direction*pole.dot(direction)).normalized()
            along=(aLen*aLen+dist*dist-bLen*bLen)/(2*dist);knee=hp+direction*along+pole*math.sqrt(max(0,aLen*aLen-along*along));end=hp+direction*dist
            par=w['Pelvis'].to_3x3();ru=upper.rotation_difference(par.inverted()@(knee-hp)).to_matrix();rf=lower.rotation_difference((par@ru).inverted()@(end-knee)).to_matrix()
            p['Leg.'+side]=[0,0,0]+angles(ru);p['Knee.'+side]=[0,0,0]+angles(rf);p[name]=[0,0,0]+angles((par@ru@rf).inverted())
        if t in [0,1.10]:p=fs[0 if t==0 else -1]['pose']
        dense.append(dict(t=t,ease='linear',pose=p))
    return dict(duration=1.10,loop=False,markers=[dict(t=0,name='AimLock'),dict(t=.62,name='Release')],frames=dense)
data=copy.deepcopy(base);data['jointOrder']=order
for clip in data['clips'].values():
    for f in clip['frames']:
        old=f['pose'];p={j:[0]*6 for j in order};p.update(old);p['Pelvis']=p['Torso'];p['Torso']=[0]*6;f['pose']=p
variants=copy.deepcopy(data);variants['clips']={}
for name,kind,style in [('K','lob',1),('M','fan',0),('R','lob',0),('T','fan',1)]:variants['clips'][name]=candidate(kind,style)
if '--select' in sys.argv:
    li,fi=sys.argv[sys.argv.index('--select')+1:sys.argv.index('--select')+3]
    data['clips']['lob']=variants['clips'][li];data['clips']['fan']=variants['clips'][fi]
else:
    data['clips']['lob']=candidate('lob',0);data['clips']['fan']=candidate('fan',0)
data['clips']['throw']=copy.deepcopy(data['clips']['fan'])
sk=dict(jointOrder=order,parents={k:v or 'Root' for k,v in parents.items()},pivots=pivots,hand=[0,-.76,.06],lobRadius=2.7)
def module(d):return 'return game:GetService("HttpService"):JSONDecode([==['+json.dumps(d,separators=(',',':'))+']==])\n'
compact=json.dumps(data,separators=(',',':'))
clips='local data = game:GetService("HttpService"):JSONDecode([==['+compact+']==])\nfor _, clip in pairs(data.clips) do\n for _, frame in ipairs(clip.frames) do\n  for name, v in pairs(frame.pose) do\n   frame.pose[name] = CFrame.new(v[1],v[2],v[3]) * CFrame.Angles(math.rad(v[4]),math.rad(v[5]),math.rad(v[6]))\n  end\n end\nend\nreturn data\n'
files={'clips.json':compact+'\n','Clips.luau':clips,'Skeleton.luau':module(sk),'skeleton.json':json.dumps(sk,indent=2)+'\n','throw-geometry.json':json.dumps(geometry,separators=(',',':'))+'\n','Geometry.luau':module(geometry),'variants-throw.json':json.dumps(variants,separators=(',',':'))+'\n'}
print('*** Begin Patch')
for name,content in files.items():
    if '--file' in sys.argv and name!=sys.argv[sys.argv.index('--file')+1]:continue
    dest=R/name
    if dest.exists() and dest.read_text()==content:continue
    print('*** '+('Update' if dest.exists() else 'Add')+' File: '+str(dest).replace('\\','/'))
    if dest.exists():
        print('@@')
        for line in dest.read_text().splitlines():print('-'+line)
    for line in content.splitlines():print('+'+line)
print('*** End Patch')
