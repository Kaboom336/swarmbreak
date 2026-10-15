"""Native modular surface kit. Bundled NumPy; no additional packages.
Convex clipping and native WedgeParts.
All coordinates here are Roblox XYZ. Collision floors remain the accepted baseline.
"""
import json, math, itertools
from pathlib import Path
import numpy as np
H=Path(__file__).parent
base=json.loads((H/'connect-before-scene.json').read_text())
parts=[]; modules=[]; posts={}; contacts=[]
EPS=1e-7
def v(p):return np.array(p,dtype=float)
def unit(p):return p/max(np.linalg.norm(p),EPS)
def xyz(p):return v([p[0],p[2],-p[1]])
def part(name,cat,pos,size,R,col,mat,shape='Block',bridge=False):
    parts.append(dict(name=name,category=cat,position=list(pos),size=list(size),rotation=list(np.asarray(R).reshape(9)),color=col,material=mat,shape=shape,bridge=bridge))
    return len(parts)-1
def beam(name,cat,a,b,width,height,col,mat,bridge=False):
    a,b=v(a),v(b);back=unit(a-b);right=unit(np.cross([0,1,0],back));up=np.cross(back,right)
    return part(name,cat,(a+b)/2,[width,height,np.linalg.norm(b-a)],np.column_stack([right,up,back]),col,mat,bridge=bridge)
def wedge_triangle(name,cat,a,b,c,col,mat,thick=.18,bridge=False):
    # Split at altitude on longest side; canonical wedge YZ triangle is
    # (-Y,-Z),(-Y,+Z),(+Y,+Z). X is the extrusion normal.
    a,b,c=map(v,(a,b,c));pairs=[(a,b,c),(b,c,a),(c,a,b)]
    a,b,c=max(pairs,key=lambda p:np.linalg.norm(p[1]-p[0]))
    axis=unit(b-a);foot=a+axis*np.dot(c-a,axis);height=np.linalg.norm(c-foot)
    if height<EPS:return []
    yy=unit(c-foot);out=[]
    for tip in (a,b):
        length=np.linalg.norm(foot-tip)
        if length<EPS:continue
        zz=unit(foot-tip);xx=unit(np.cross(yy,zz));R=np.column_stack([xx,yy,zz])
        center=(tip+c)/2
        # Top face exactly on supplied surface; extrusion only downward.
        center-=xx*(thick/2)*(1 if xx[1]>0 else -1)
        out.append(part(name,cat,center,[thick,height,length],R,col,mat,'Wedge',bridge))
    return out
def area(poly):return sum(a[0]*b[2]-b[0]*a[2] for a,b in zip(poly,poly[1:]+poly[:1]))/2
def cross2(a,b):return a[0]*b[2]-a[2]*b[0]
def clean(poly):
    q=[]
    for p in poly:
        if not q or np.linalg.norm(p-q[-1])>1e-6:q.append(p)
    if len(q)>1 and np.linalg.norm(q[0]-q[-1])<1e-6:q.pop()
    return q if len(q)>=3 and abs(area(q))>1e-6 else []
def clip(poly,a,b,inside=True):
    if not poly:return []
    out=[];d=b-a
    for s,e in zip(poly,poly[1:]+poly[:1]):
        ds=cross2(d,s-a);de=cross2(d,e-a)
        si=ds>=-EPS if inside else ds<=EPS;ei=de>=-EPS if inside else de<=EPS
        if si:out.append(s.copy())
        if si!=ei:out.append(s+(e-s)*(ds/(ds-de)))
    return clean(out)
def subtract(poly,cutter):
    if area(cutter)<0:cutter=cutter[::-1]
    remain=poly;out=[]
    for a,b in zip(cutter,cutter[1:]+cutter[:1]):
        outside=clip(remain,a,b,False)
        if outside:out.append(outside)
        remain=clip(remain,a,b,True)
        if not remain:break
    return out
def height(poly,x,z):
    a=poly[0]
    for j in range(1,len(poly)-1):
        n=np.cross(poly[j]-a,poly[j+1]-a)
        if abs(n[1])>EPS:return a[1]-(n[0]*(x-a[0])+n[2]*(z-a[2]))/n[1]
    return a[1]
def overlap(a,b):
    aa=np.asarray(a);bb=np.asarray(b)
    if aa[:,0].max()<bb[:,0].min()-EPS or bb[:,0].max()<aa[:,0].min()-EPS or aa[:,2].max()<bb[:,2].min()-EPS or bb[:,2].max()<aa[:,2].min()-EPS:return []
    q=a
    if area(b)<0:b=b[::-1]
    for x,y in zip(b,b[1:]+b[:1]):q=clip(q,x,y)
    return q
surfaces=[];stair_risers=[]
def surface(ident,poly,kind='path',mat='Cobblestone',col=None,dynamic=False):
    poly=list(map(v,poly));poly=poly if area(poly)>0 else poly[::-1]
    for j in range(1,len(poly)-1):
        triangle=[poly[0],poly[j],poly[j+1]]
        if abs(area(triangle))<1e-6:continue
        if area(triangle)<0:triangle=triangle[::-1]
        surfaces.append(dict(id=ident+f':t{j}',polygon=triangle,kind=kind,material=mat,color=col or [224,199,151],dynamic=dynamic))
def smooth(pts):
    # Arc-sized quadratic corner pieces stay inside the accepted 18-stud floor.
    out=[pts[0]]
    for a,b,c in zip(pts,pts[1:],pts[2:]):
        ab=np.linalg.norm(b-a);bc=np.linalg.norm(c-b);cut=min(10,ab*.35,bc*.35)
        left=b+unit(a-b)*cut;right=b+unit(c-b)*cut
        out.append(left)
        for j in range(1,5):
            t=j/4;out.append((1-t)**2*left+2*t*(1-t)*b+t*t*right)
    out.append(pts[-1]);q=[out[0]]
    for a,b in zip(out,out[1:]):
        n=max(1,math.ceil(np.linalg.norm(b-a)/9))
        q.extend(a+(b-a)*j/n for j in range(1,n+1))
    return q
def profiles(pts,width):
    dirs=[unit(v([b[0]-a[0],0,b[2]-a[2]])) for a,b in zip(pts,pts[1:])]
    sides=[np.cross(d,[0,1,0]) for d in dirs];q=[]
    for i,p in enumerate(pts):
        side=sides[0] if i==0 else sides[-1] if i==len(pts)-1 else unit(sides[i-1]+sides[i])
        scale=width/2 if i in (0,len(pts)-1) else width/2/max(.5,np.dot(side,sides[i]))
        q.append((p-side*scale,p+side*scale))
    return q
routes={n:[xyz(p) for p in r['points']] for n,r in base['routes'].items()}
# Track deck owns the footprint at crossings, so light paving cannot bury a rail.
rail=routes['cartRail'];lengths=[np.linalg.norm(b-a) for a,b in zip(rail,rail[1:])];gapstart=sum(lengths[:3])+lengths[3]/2-8;gapend=gapstart+16
def rail_at(t):
    for a,b,l in zip(rail,rail[1:],lengths):
        if t<=l+EPS:return a+(b-a)*t/l
        t-=l
    return rail[-1]
stations=[0.];dist=0
for l in lengths:
    n=math.ceil(l/6);stations.extend(dist+l*j/n for j in range(1,n+1));dist+=l
stations=sorted(set(stations+[gapstart,gapend]));track=[rail_at(t) for t in stations];deck=profiles(track,10.5)
for i,(a,b) in enumerate(zip(deck,deck[1:])):
    dynamic=stations[i]>=gapstart-EPS and stations[i+1]<=gapend+EPS
    surface(f'trackDeck:{i:03}',[q+v([0,.025,0]) for q in (a[0],b[0],b[1],a[1])],'bridge','WoodPlanks',[143,88,46],bool(dynamic))
# Flat destination / junction pads emitted first; subsequent strips trim to them.
for name in ('GeodeCamp','SafetyApron','PitFloor','BroadLanding','PaddedSidingFloor'):
    p=next(p for p in base['parts'] if p['name']==name);x,y,z=p['position'];sx,sy,sz=p['size'];y+=sy/2+.025
    surface(name,[[x-sx/2,y,z-sz/2],[x+sx/2,y,z-sz/2],[x+sx/2,y,z+sz/2],[x-sx/2,y,z+sz/2]],'pad')
route_modules={}
for name,pts in routes.items():
    if name=='cartRail':continue
    points=smooth(pts);edges=profiles(points,12);ids=[]
    for i,(pa,pb) in enumerate(zip(edges,edges[1:])):
        poly=[pa[0],pb[0],pb[1],pa[1]];poly=[p+v([0,.025,0]) for p in poly]
        # Full-width timber only where the accepted path crosses the pit.
        mid=(points[i]+points[i+1])/2;trestle=abs(mid[0])<52 and -35<mid[2]<70 and mid[1]>7
        ident=f'{name}:{i:03}';ids.append(ident)
        dy=points[i+1][1]-points[i][1]
        # A 4-stud side stair beside an 8-stud ramp on long climbing flights.
        # Route center remains on the smooth ramp; side stairs have real risers.
        near_junction=False
        for other,polyline in routes.items():
            if other==name or other=='cartRail':continue
            for a,b in zip(polyline,polyline[1:]):
                d=b-a;t=np.clip(np.dot((mid-a)[[0,2]],d[[0,2]])/max(EPS,np.dot(d[[0,2]],d[[0,2]])),0,1);q=a+d*t
                if np.linalg.norm((q-mid)[[0,2]])<20 and abs(q[1]-mid[1])<4:near_junction=True
        stair=not trestle and not near_junction and name=='main' and abs(dy)>.8 and np.linalg.norm(points[i+1]-points[i])>7
        if stair:
            a0,b0,b1,a1=poly;am=a0+(a1-a0)/3;bm=b0+(b1-b0)/3
            surface(ident,[am,bm,b1,a1],'ramp')
            n=math.ceil(abs(dy)/.4);last_y=a0[1]
            for j in range(n):
                t0=j/n;t1=(j+1)/n
                aa=a0+(b0-a0)*t0;bb=a0+(b0-a0)*t1;cc=am+(bm-am)*t1;dd=am+(bm-am)*t0
                y=a0[1]+dy*(j+1)/n
                tread=[v([q[0],y,q[2]]) for q in (aa,bb,cc,dd)]
                surface(ident+f':step{j}',tread,'stair')
                # Vertical riser at the shared tread boundary; ends meet both treads.
                stair_risers.append((aa.copy(),dd.copy(),last_y,y));last_y=y
        else:surface(ident,poly,'bridge' if trestle else 'ramp' if abs(dy)>.1 else 'path','WoodPlanks' if trestle else 'Cobblestone',[166,110,62] if trestle else None)
    route_modules[name]=ids
# Clip coplanar/same-height intersections into shared junction profiles, not overlaps.
finished=[]
for s in surfaces:
    chunks=[s['polygon']]
    for old in finished:
        op=old['polygon'];new=[]
        for p in chunks:
            q=overlap(p,op)
            if q:
                center=np.mean(q,axis=0)
                # Different-level crossings remain distinct routes.
                threshold=4 if old['id'].startswith('trackDeck:') else 2
                if min(abs(height(p,point[0],point[2])-height(op,point[0],point[2])) for point in q+[center])<threshold:
                    for fragment in subtract(p,op):
                        for vertex in fragment:
                            for a,b in zip(op,op[1:]+op[:1]):
                                d=b-a;t=np.clip(np.dot((vertex-a)[[0,2]],d[[0,2]])/max(EPS,np.dot(d[[0,2]],d[[0,2]])),0,1)
                                if np.linalg.norm((vertex-a-d*t)[[0,2]])<1e-5:
                                    vertex[1]=height(op,vertex[0],vertex[2]);break
                        for j in range(1,len(fragment)-1):
                            triangle=[fragment[0],fragment[j],fragment[j+1]]
                            if abs(area(triangle))>1e-6:new.append(triangle)
                    continue
            new.append(p)
        chunks=new
        if not chunks:break
    for j,p in enumerate(chunks):
        for k in range(1,len(p)-1):
            triangle=[p[0],p[k],p[k+1]]
            if abs(area(triangle))<1e-6:continue
            entry=dict(s);entry['polygon']=triangle;entry['id']=s['id']+f'/{j}-{k}';finished.append(entry)
for s in finished:
    ids=[];p=s['polygon']
    for j in range(1,len(p)-1):ids+=wedge_triangle('ConnectSurface_'+s['id'],'connect-path',p[0],p[j],p[j+1],s['color'],s['material'],bridge=s['dynamic'])
    modules.append(dict(id=s['id'],kind=s['kind'],polygon=[list(p) for p in p],part_indices=ids))
# Accepted support colliders can peek through a rounded decorative ramp. Keep
# their exact collision volume, but fit the visible top course below the deck.
hidden_supports=[];support_skins=[]
surface_bounds=[(min(q[0] for q in s['polygon']),max(q[0] for q in s['polygon']),min(q[2] for q in s['polygon']),max(q[2] for q in s['polygon'])) for s in finished]
for baseline_index,p in enumerate(base['parts']):
    if p['name']!='RouteRockButtress':continue
    x,y,z=p['position'];sx,sy,sz=p['size'];top=y+sy/2;bottom=y-sy/2;floor=top
    rectangle=[v([x+dx*sx/2,0,z+dz*sz/2]) for dx,dz in ((-1,-1),(1,-1),(1,1),(-1,1))]
    for s,bounds in zip(finished,surface_bounds):
        if bounds[1]<x-sx/2 or bounds[0]>x+sx/2 or bounds[3]<z-sz/2 or bounds[2]>z+sz/2:continue
        q=overlap(s['polygon'],rectangle)
        if q:
            minimum=min(point[1] for point in q)
            if top-4<minimum<top+.08:floor=min(floor,minimum-.08)
    if floor<top-.01:
        hidden_supports.append(baseline_index)
        if floor>bottom+.02:
            index=part('ConnectFittedButtressSkin','connect-support-skin',[x,(floor+bottom)/2,z],[sx,floor-bottom,sz],np.eye(3),p['color'],p['material'])
            support_skins.append(index)
for a,b,old_y,new_y in stair_risers:
    aa=a.copy();bb=b.copy();aa[1]=bb[1]=(old_y+new_y)/2
    beam('ConnectStoneStepRiser','connect-step',aa,bb,.05,abs(new_y-old_y),[190,164,120],'Cobblestone')

# Find exposed boundary intervals, including T intersections which split a long edge.
edges=[]
for i,s in enumerate(finished):
    for a,b in zip(s['polygon'],s['polygon'][1:]+s['polygon'][:1]):edges.append((i,a,b))
boundary=[];seams=[]
for i,a,b in edges:
    length=np.linalg.norm(b-a);axis=unit(b-a);cuts=[0.,length]
    neighbors=[]
    for j,c,d in edges:
        if i==j:continue
        if max(a[0],b[0])+1e-4<min(c[0],d[0]) or max(c[0],d[0])+1e-4<min(a[0],b[0]) or max(a[2],b[2])+1e-4<min(c[2],d[2]) or max(c[2],d[2])+1e-4<min(a[2],b[2]):continue
        if max(np.linalg.norm(np.cross(c-a,axis)),np.linalg.norm(np.cross(d-a,axis)))>1e-4:continue
        lo,hi=sorted([np.dot(c-a,axis),np.dot(d-a,axis)]);lo=max(0,lo);hi=min(length,hi)
        if hi-lo>1e-5:cuts.extend([lo,hi]);neighbors.append((lo,hi,j))
    cuts=sorted(set(round(t,6) for t in cuts))
    for lo,hi in zip(cuts,cuts[1:]):
        if hi-lo<1e-5:continue
        mid=(lo+hi)/2;target=next((j for l,h,j in neighbors if l-1e-4<=mid<=h+1e-4),None)
        aa=a+axis*lo;bb=a+axis*hi
        if target is None:boundary.append((i,aa,bb))
        elif i<target:seams.append(dict(a=finished[i]['id'],b=finished[target]['id'],profile=[list(aa),list(bb)]))
def post(q):
    key=tuple(round(float(x),4) for x in q)
    if key not in posts:
        idx=part('ConnectFencePost','connect-fence',q+v([0,1.7,0]),[.55,3.4,.55],np.eye(3),[94,65,43],'WoodPlanks')
        posts[key]=(idx,q)
    return posts[key]
def ray_ground(q,ceiling):
    best=-1e9;hit=None
    for i,p in enumerate(base['parts']):
        if i in hidden_support_ids:continue
        if not p['collidable'] or p['category'] not in ('mass','underside','support','lane'):continue
        R=np.array(p['rotation']).reshape(3,3);o=R.T@(q-v(p['position']));d=R.T@v([0,1,0]);low=-1e9;high=1e9
        for k in range(3):
            h=p['size'][k]/2
            if abs(d[k])<EPS:
                if abs(o[k])>h:low=1e9;break
            else:
                l,r=sorted([(-h-o[k])/d[k],(h-o[k])/d[k]]);low=max(low,l);high=min(high,r)
        top=q[1]+high
        if low<=high and top<ceiling and top>best:best=top;hit=i
    skin=None
    for i in support_skins:
        p=parts[i];x,y,z=p['position'];sx,sy,sz=p['size'];top=y+sy/2
        if abs(q[0]-x)<=sx/2 and abs(q[2]-z)<=sz/2 and best<top<ceiling:best=top;skin=i
    if hit is None and skin is None:raise ValueError(f'No ground at {q}')
    return best,hit,skin
hidden_support_ids=set(hidden_supports)
# Continuous raised stones are boundary bands; no through-fences at entrances/pads.
for idx,(i,a,b) in enumerate(boundary):
    s=finished[i];length=np.linalg.norm(b-a)
    if length<.2:continue
    mid=(a+b)/2;internal=False
    for j,other in enumerate(finished):
        if j==i:continue
        p=other['polygon']
        if all(cross2(y-x,mid-x)>=-1e-5 for x,y in zip(p,p[1:]+p[:1])) and abs(height(p,mid[0],mid[2])-mid[1])<2:
            internal=True;break
    if internal:continue
    # Edging ends at the surface boundary, and each course has a shared profile.
    n=max(1,math.ceil(length/3));d=unit(b-a);inward=unit(np.cross(d,[0,1,0]))
    for j in range(n):
        aa=a+(b-a)*j/n;bb=a+(b-a)*(j+1)/n
        beam('ConnectRaisedEdging','connect-edge',aa+inward*.38+v([0,.2,0]),bb+inward*.38+v([0,.2,0]),.76,.4,[159,137,99],'Cobblestone')
    if s['kind'] in ('pad','stair'):continue
    # Boundary line is the spline. Cap it at posts; no rail can have a free end.
    n=max(1,math.ceil(length/7));nodes=[a+(b-a)*j/n for j in range(n+1)]
    for aa,bb in zip(nodes,nodes[1:]):
        if np.linalg.norm(bb-aa)<1.1:continue
        crossing=False
        for t in (0,.25,.5,.75,1):
            q=aa+(bb-aa)*t
            for ra,rb in zip(rail,rail[1:]):
                d=rb-ra;u=np.clip(np.dot((q-ra)[[0,2]],d[[0,2]])/np.dot(d[[0,2]],d[[0,2]]),0,1);rp=ra+d*u
                if np.linalg.norm((q-rp)[[0,2]])<5.6 and abs(q[1]-rp[1])<4:crossing=True
        if crossing:continue
        # Keep low stone edges on terrain; tall timber only on exposed crossings.
        if s['kind']=='pad':continue
        ia,qa=post(aa);ib,qb=post(bb);dir=unit(bb-aa)
        # Intersection with axis-aligned post face, not a guessed half-width.
        trim=.45/max(abs(dir[0]),abs(dir[2]))
        for y in (1.1,2.6):
            ra=aa+v([0,y,0]);rb=bb+v([0,y,0]);side=unit(np.cross(dir,[0,1,0]))*.15
            full=[ra-side,rb-side,rb+side,ra+side]
            if area(full)<0:full=full[::-1]
            chunks=[full];targets=[]
            for target,q in ((ia,aa),(ib,bb)):
                square=[v([q[0]+x*.275,0,q[2]+z*.275]) for x,z in ((-1,-1),(1,-1),(1,1),(-1,1))]
                chunks=[piece for polygon in chunks for piece in subtract(polygon,square)]
                targets.append((target,q))
            ids=[]
            for poly in chunks:
                for j in range(1,len(poly)-1):ids+=wedge_triangle('ConnectFenceRail','connect-fence',poly[0],poly[j],poly[j+1],[127,86,52],'WoodPlanks',.3)
            for target,q in targets:
                profile=[]
                for poly in chunks:
                    for point in poly:
                        delta=np.abs((point-q)[[0,2]])
                        if max(delta)<=.275001 and abs(max(delta)-.275)<1e-5 and not any(np.linalg.norm(point-old)<1e-5 for old in profile):profile.append(point)
                if not profile:raise ValueError('fence post lacks mating profile')
                p=parts[target];low=min(p['position'][1]-p['size'][1]/2,min(q[1] for q in profile)-.35);high=max(p['position'][1]+p['size'][1]/2,max(q[1] for q in profile)+.35)
                p['position'][1]=(low+high)/2;p['size'][1]=high-low
                contacts.append(dict(kind='fence',parts=ids,target=target,profile=[list(point) for point in profile]))

# Rail strips use mitered matching profiles at every centerline node.
rail=routes['cartRail'];lengths=[np.linalg.norm(b-a) for a,b in zip(rail,rail[1:])];gapstart=sum(lengths[:3])+lengths[3]/2-8;gapend=gapstart+16
def rail_at(t):
    for a,b,l in zip(rail,rail[1:],lengths):
        if t<=l+EPS:return a+(b-a)*t/l
        t-=l
    return rail[-1]
stations=[0.];dist=0
for l in lengths:
    n=math.ceil(l/6)
    stations.extend(dist+l*j/n for j in range(1,n+1));dist+=l
stations=sorted(set(stations+[gapstart,gapend]));track=[rail_at(t) for t in stations];track_profiles=profiles(track,6)
rail_modules=[]
for i,(a,b) in enumerate(zip(track,track[1:])):
    dynamic=stations[i]>=gapstart-EPS and stations[i+1]<=gapend+EPS
    for side in (0,1):
        ca=track_profiles[i][side]+v([0,.9,0]);cb=track_profiles[i+1][side]+v([0,.9,0])
        # Narrow, properly mitered native polygon rail heads; wedge strip has no end overlap.
        offa=unit(track_profiles[i][1]-track_profiles[i][0])*.325;offb=unit(track_profiles[i+1][1]-track_profiles[i+1][0])*.325
        poly=[ca-offa,cb-offb,cb+offb,ca+offa];ids=[]
        for j in (1,2):ids+=wedge_triangle('ConnectSteelRail','connect-track',poly[0],poly[j],poly[j+1],[36,42,51],'Metal',.6,dynamic)
        rail_modules.append(dict(id=f'rail:{side}:{i}',kind='rail',polygon=[list(p) for p in poly],part_indices=ids,bridge=dynamic))
    cfback=unit(a-b);right=unit(np.cross([0,1,0],cfback));up=np.cross(cfback,right)
    # Each span carries discrete sleepers; planks/stringers are genuinely supported.
    n=max(1,math.ceil(np.linalg.norm(b-a)/2.7))
    for j in range(n):
        q=a+(b-a)*(j+.5)/n
        part('ConnectRailSleeper','connect-track',q+up*.25,[9,.5,.95],np.column_stack([right,up,cfback]),[166,99,49],'WoodPlanks',bridge=dynamic)
    for side in (-1,1):beam('ConnectRailStringer','connect-track',a+right*side*4-v([0,1,0]),b+right*side*4-v([0,1,0]),.9,1.5,[100,65,40],'WoodPlanks',dynamic)
    if True:
        q=(a+b)/2
        for side in (-1,1):
            top=q+right*side*4-v([0,1.75,0]);ground,hit,skin=ray_ground(top,top[1]-.2)
            k=part('ConnectGroundedTrestle','connect-support',[top[0],(top[1]+ground)/2,top[2]],[1.1,top[1]-ground,1.1],np.eye(3),[100,65,40],'WoodPlanks',bridge=bool(dynamic))
            contact=dict(kind='trestle',part=k,end='bottom',point=[top[0],ground,top[2]])
            if skin is None:contact['target_baseline']=hit
            else:contact['target']=skin
            contacts.append(contact)
# Terminal track profiles meet real metal stop plates.
for j,q in enumerate((track[0],track[-1])):
    direction=unit((track[1]-track[0]) if j==0 else (track[-1]-track[-2]));right=unit(np.cross(direction,[0,1,0]));back=direction if j==0 else -direction;up=np.cross(back,right)
    part('ConnectRailTerminal','connect-track',q+v([0,.9,0])+back*.15,[8,1.6,.3],np.column_stack([right,up,back]),[56,64,76],'Metal')
payload={'parts':parts,'modules':modules,'rail_modules':rail_modules,'seams':seams,'contacts':contacts,'route_modules':route_modules,'hidden_supports':[base['parts'][i] for i in hidden_supports],'gap':[float(gapstart),float(gapend)],'method':'convex surface clipping; native WedgePart tessellation; ground ray into visible accepted OBBs or fitted support skin'}
(H/'CONNECT-KIT.json').write_text(json.dumps(payload,indent=2,default=lambda x:x.item()))
print(f'{len(parts)} kit parts; {len(modules)} fitted surface pieces; {len(seams)} matched surface joints; {len(contacts)} explicit contacts')
