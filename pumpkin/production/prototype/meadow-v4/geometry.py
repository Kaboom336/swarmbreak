"""Native-part Meadow v4. Spec coordinates are (X,Z,Y); manifest uses Roblox XYZ.
Deterministic offline authoring; no dependencies, imported models or gameplay scripts.
Run with Python to emit shared render/audit JSON, Rojo model, and runtime data.
"""
import json, math, random, pathlib, xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent
R = random.Random(41013)
PARTS, ROUTES = [], {}
GREEN=(99,172,44); LIME=(135,205,48); ROCK=(106,119,133)
CREAM=(214,193,149); WOOD=(118,73,37); CYAN=(18,224,250)
IDENTITY=[1,0,0,0,1,0,0,0,1]

def part(name, cat, pos, size, color, material='SmoothPlastic', collide=False, rotation=None, shape='Block', transparency=0):
    p=dict(name=name, category=cat, position=list(pos), size=list(size), color=list(color),
           material=material, collidable=collide, rotation=rotation or IDENTITY, shape=shape, transparency=transparency)
    PARTS.append(p)
    return p

def specpart(name,cat,x,z,y,sx,sz,sy,color,**kw):
    return part(name,cat,(x,y,-z),(sx,sy,sz),color,**kw)

def surface(name,x,z,y,sx,sz,cat='ground'):
    lift={'court':.04,'portal':.06,'protected':.03,'jump':.04}.get(cat,0)
    specpart(name,cat,x,z,y-1+lift,sx,sz,2,GREEN,material='Grass',collide=True)

def segment(name,a,b,width=18,cat='lane',pave=True,thickness=1.2):
    # Local Z follows the route. Sloped collision is one seamless inclined slab.
    ax,az,ay=a; bx,bz,by=b; dx=bx-ax; dz=bz-az; dy=by-ay
    run=math.hypot(dx,dz); length=math.hypot(run,dy)
    if length < .01: return
    ux=dx/run; uz=-dz/run; c=run/length; s=dy/length
    vx,vy,vz=-ux*s,c,-uz*s
    rot=[uz,vx,ux*c, 0,vy,s, -ux,vz,uz*c]
    # Tiny intentional surface lift resolves coincident ground/path faces.
    lift=.12+(sum(ord(ch) for ch in name)%13)*.0007 if cat in ['lane','bridge','jump_access'] else 0
    center=((ax+bx)/2-vx*thickness/2,(ay+by)/2-vy*thickness/2+lift,-(az+bz)/2-vz*thickness/2)
    part(name,cat,center,(width,thickness,length+.25),GREEN,'Grass',True,rot)
    if pave:
        rows=max(1,int(run/3.2)); cols=5
        for i in range(rows):
            t=(i+.5)/rows
            for j in range(cols):
                off=(j-2)*2.7
                pos=(ax+dx*t+uz*off+vx*.06,ay+dy*t+vy*.06+lift,-az-dz*t-ux*off+vz*.06)
                color=tuple(min(255,v+R.randint(-14,14)) for v in CREAM)
                part(name+'_Cobble', 'paving',pos,(2.5,.12,min(3.1,length/rows)),color,'Cobblestone',False,rot)

def route(name,points,width=18,cat='lane'):
    ROUTES[name]={'points':points,'width':width,'category':cat}
    for i,(a,b) in enumerate(zip(points,points[1:])): segment(name+str(i),a,b,width,cat)

def tree(x,z,y=0,scale=1):
    specpart('OakTrunk','tree',x,z,y+7*scale,3*scale,3*scale,14*scale,WOOD,material='Wood')
    for ox,oz,h,w in [(0,0,17,12),(-5,0,15,8),(5,1,16,8),(0,-5,16,8),(0,4,19,9),(0,0,22,7)]:
        specpart('VoxelOakCrown','tree',x+ox*scale,z+oz*scale,y+h*scale,w*scale,w*scale,6*scale,(R.randint(38,65),R.randint(133,181),R.randint(30,48)))

def lantern(x,z,y=0):
    specpart('LanternPost','lantern',x,z,y+3.75,1.2,1.2,7.5,WOOD,material='Wood')
    specpart('LanternAmber','light',x,z,y+7.5,2.2,2.2,2.8,(255,189,46),material='Neon')
    for h in [6,9]: specpart('LanternCap','lantern',x,z,y+h,3,3,.6,WOOD)

def fence(a,b,y=0):
    ax,az=a; bx,bz=b; n=max(1,int(math.hypot(bx-ax,bz-az)/9))
    for i in range(n+1):
        t=i/n; specpart('FencePost','fence',ax+(bx-ax)*t,az+(bz-az)*t,y+2.5,1.3,1.3,5,WOOD,material='Wood')
    for h in [1.6,3.7]: segment('FenceRail',(ax,az,y+h),(bx,bz,y+h),.55,'fence',False,.6)
    for p in PARTS:
        if p['category']=='fence': p['collidable']=False; p['color']=list(WOOD); p['material']='Wood'

def dist_segment(x,z,a,b):
    dx=b[0]-a[0]; dz=b[1]-a[1]; t=max(0,min(1,((x-a[0])*dx+(z-a[1])*dz)/(dx*dx+dz*dz)))
    return math.hypot(x-a[0]-dx*t,z-a[1]-dz*t)

def build():
    # 352-square connected bedrock, subdivided grass surface with shallow valley cut.
    for x in range(-168,177,16):
        for z in range(-168,177,16):
            if abs(x)+abs(z)>280:continue
            floor=-4 if (-64<x<64 and -16<z<16) or (24<=abs(x)<=56 and abs(z)==24) else 0
            surface('MeadowGrass',x,z,floor,16,16)
            specpart('ConnectedRockTile','base',x,z,-13,14.5,14.5,16,ROCK,material='Slate',collide=True)
            edge=abs(x)==168 or abs(z)==168 or abs(x)+abs(z)>264
            if edge:
                h=R.randint(22,38)
                specpart('ExteriorVoxelCliff','cliff',x,z,-h/2-2,14.5,14.5,h,tuple(v+R.randint(-9,9) for v in ROCK),material='Slate')
                for q in range(9):
                    specpart('CliffGrassLip','grass',x+R.uniform(-7,7),z+R.uniform(-7,7),.4,R.uniform(1,3),R.uniform(1,3),R.uniform(.4,1.5),LIME)
                for dx,dz in [(-1,0),(1,0),(0,-1),(0,1)]:
                    nx=x+dx*16;nz=z+dz*16
                    if abs(nx)<=168 and abs(nz)<=168 and abs(nx)+abs(nz)<=280:continue
                    for along in [-5,0,5]:
                        for layer in range(4):
                            xx=x+dx*6.8+(along if dz else 0);zz=z+dz*6.8+(along if dx else 0)
                            shade=R.randint(-16,15)
                            specpart('CliffMasonry','cliff',xx,zz,-5-layer*7,4.8 if dz else 2.3,4.8 if dx else 2.3,6.75,tuple(v+shade for v in ROCK),material='Slate')
    for scale,y,h in [(.72,-32,20),(.58,-50,16),(.34,-65,16)]:
        specpart('HangingIslandStratum','cliff',0,0,y,352*scale,352*scale,h,ROCK,material='Slate')
    # The 32x32 bounding terrace has trimmed corners: square corners would
    # intersect the specified radius30, width18 spiral (inner edge radius21).
    # A full 24x24 flat throwing court remains intact at the nest.
    surface('SummitCampNS',0,108,24,24,32,'court')
    surface('SummitCampEW',0,108,24.003,32,24,'court')
    specpart('CampRockMassNS','summit_cliff',0,108,10,24,32,24,ROCK,material='Slate',collide=True)
    specpart('CampRockMassEW','summit_cliff',0,108,10,32,24,24,ROCK,material='Slate',collide=True)
    for side in [-1,1]:
        for along in [-9,-3,3,9]:
            for y in [3,9,15,21]:
                color=tuple(v+R.randint(-13,13) for v in ROCK)
                specpart('SummitCutStone','summit_cliff',side*15.9,108+along,y,1.7,5.7,5.7,color,material='Slate')
                specpart('SummitCutStone','summit_cliff',along,108+side*15.9,y,5.7,1.7,5.7,color,material='Slate')
            specpart('SummitMossLip','grass',side*16.3,108+along,23.8,1.6,3.8,1.5,LIME)
            specpart('SummitMossLip','grass',along,108+side*16.3,23.8,3.8,1.6,1.5,LIME)
    route('summit_radial',[(0,108,24),(30,108,24)])
    spiral=[]
    for i in range(73):
        angle=i/72*math.pi*1.5
        # Flat tangent entry/exit avoids the radial slab crossing a lower arc.
        height=24*max(0,min(1,(math.pi*1.5-.42-angle)/(math.pi*1.5-.84)))
        spiral.append((30*math.cos(angle),108+30*math.sin(angle),height))
    route('spiral',spiral)
    route('fork_link',[(0,78,0),(0,54,0)])
    surface('ForkCourt',0,54,0,32,32,'court')
    # Shelf pads are separate from the four thirteen-stud ramp runs.
    shelf=[(0,100,24),(0,91,24),(23,91,24),(36,91,18),(37,91,18),(50,91,12),(59,91,12),(59,73,12),(50,73,12),(37,73,6),(36,73,6),(23,73,0),(14,73,0),(0,54,0)]
    route('shelf',shelf)
    # The nine-stud tangent pads on both rows form the east turnaround.
    route('west',[(0,54,0),(-76,30,0),(-100,-24,0),(-76,-76,0),(-24,-136,0)])
    route('bridge',[(0,54,0),(0,29,0),(0,16,6),(0,-16,6),(0,-29,0),(0,-116,0)],cat='bridge')
    route('east',[(0,54,0),(70,39,0),(76,30,0),(90,9,10),(96,0,10),(96,-24,10),(96,-76,10),(90,-83,10),(72,-104,0),(66,-111,0),(24,-136,0)])
    surface('RidgeThrowCourt',96,-24,10,24,24,'court')
    route('north_crosslink',[(-76,54,0),(0,54,0),(76,54,0)])
    route('south_crosslink',[(-76,-76,0),(0,-76,0),(70,-76,0)])
    for x,z in [(-76,54),(76,54),(-76,-76),(0,-76),(70,-76)]:
        surface('CrosslinkTurningCourt',x,z,0,24,24,'court')
    for x in [-40,40]:
        route('recovery'+str(x),[(x,-25,0),(x,-16,-4),(x,16,-4),(x,25,0)])
    # Optional east gap sequence, independent of the eighteen-wide walking route.
    for i in range(3): surface('OptionalJumpLanding'+str(i),125,-29-i*16,10+i*2,12,12,'jump')
    route('jump_access',[(96,-24,10),(125,-29,10)],cat='jump_access')
    route('jump_recovery',[(125,-61,14),(146,-61,14),(146,-70,14),(146,-103,0),(146,-112,0),(107,-112,0)],cat='jump_access')
    surface('PortalPad',0,-136,0,32,24,'portal')
    surface('ProtectedPortalApron',0,-136,0,48,40,'protected')
    route('portal_north',[(0,-76,0),(0,-136,0)])
    # Under-path rock buttresses express the summit/ridge elevation without decks.
    for route_name in ['spiral','east','shelf']:
        pts=ROUTES[route_name]['points']
        for a,b in zip(pts,pts[1:]):
            run=math.hypot(b[0]-a[0],b[1]-a[1]);n=max(1,int(run/6))
            for i in range(n):
                t=(i+.5)/n;x=a[0]+(b[0]-a[0])*t;z=a[1]+(b[1]-a[1])*t;y=a[2]+(b[2]-a[2])*t
                if y<=3:continue
                h=y-2
                specpart('TerraceRockButtress','summit_cliff',x,z,h/2,7,7,h,tuple(v+R.randint(-10,10) for v in ROCK),material='Slate')
    # Cliff faces alongside summit descent: narrow pillars stay outside travel and courts.
    for i in range(36):
        a=i/36*math.pi*1.5; x=19*math.cos(a);z=108+19*math.sin(a);h=24*(1-i/36)
        if z<96 and x>5: continue
        specpart('SpiralInnerRock','summit_cliff',x,z,h/2-1,3,3,max(2,h),ROCK,material='Slate')
    # Cyan native-part arch: ring segments face south with an open centre.
    for i in range(18):
        a=i/18*math.pi*2;x=10*math.cos(a);y=11+10*math.sin(a)
        c=math.cos(a);s=math.sin(a);rot=[c,-s,0,s,c,0,0,0,1]
        part('PortalStone','portal_arch',(x,y,136),(3.8,3,4),ROCK,'Slate',False,rot)
        part('CyanArchRune','portal_glow',(x*.91,11+(y-11)*.91,138.1),(2.2,1.2,.3),CYAN,'Neon',False,rot)
    part('PortalLightDisc','portal_glow',(0,11,137),(.25,17,17),CYAN,'Neon',False,shape='Cylinder',transparency=.28,
         rotation=[0,1,0,0,0,1,1,0,0])
    for r in [2,4.5,7]:
        for i in range(20):
            a=i/20*math.pi*2
            part('PortalSpiral','portal_glow',(r*math.cos(a),11+r*math.sin(a),139),(1.2,1.2,.3),(153,255,245),'Neon')
    # Camp treasure and recognizable wide-hat green-apron stand-in; no guardian code.
    for i in range(20):
        a=i/20*6.283; specpart('AcornNest','treasure',math.cos(a)*3,108+math.sin(a)*3,24.5,1.4,1.4,1,WOOD)
    specpart('GoldenAcorn','treasure',0,108,27,3.8,3.8,4.5,(255,182,26),shape='Ball')
    specpart('AcornCap','treasure',0,108,29,4.3,4.3,1.3,(181,116,23))
    specpart('AcornStem','treasure',0,108,30.2,.7,.7,1.2,(255,192,49))
    for x in [-9,-5]: specpart('KeeperBoot','keeper',x,114,25.5,2.5,3,3,(83,53,32))
    specpart('KeeperCoat','keeper',-7,114,29,6,3.5,5,(107,69,38))
    specpart('KeeperGreenApron','keeper',-7,111.9,29.2,4.5,.5,5.4,(31,121,68))
    specpart('KeeperHead','keeper',-7,114,33.4,3.6,3.6,3.6,(238,187,112))
    specpart('KeeperHatBrim','keeper',-7,114,35.7,10,8,.8,(227,165,38))
    specpart('KeeperHatCrown','keeper',-7,114,37,5.5,4.5,2.5,(239,183,53))
    for x in [-8,-6]: specpart('KeeperEye','keeper',x,112.1,33.7,.45,.2,.8,(28,29,24))
    for x in [-11,-3]: specpart('KeeperArm','keeper',x,114,29.2,2,2,5,(238,187,112))
    # Exclude every lane with its full width plus an explicit four-stud shoulder.
    def clear(x,z,margin=5):
        if abs(x)+abs(z)>268:return False
        if abs(x)<28 and -160<z<-112:return False
        if abs(x)<22 and 86<z<130:return False
        for route_data in ROUTES.values():
            for a,b in zip(route_data['points'],route_data['points'][1:]):
                if dist_segment(x,z,a,b)<route_data['width']/2+margin:return False
        return True
    # Covered west causeway: rocks outside the 18-wide clear lane, 6–8 tall.
    for x,z in [(-112,5),(-83,0),(-117,-39),(-80,-47),(-110,-66),(-64,-47)]:
        if clear(x,z,1):
            h=R.randint(6,8);specpart('WestThrowCover','cover',x,z,h/2,8,8,h,ROCK,material='Slate',collide=True)
    for x,z in [(-138,130),(-100,141),(103,140),(144,109),(-142,70),(132,65),(-146,-16),(154,-26),(-135,-104),(136,-128),(-70,-147),(73,-151),(-110,-142),(125,115),(-65,150)]:
        if clear(x,z,14): tree(x,z,0,R.uniform(.85,1.25))
    for x in range(-156,157,12):
        for z in range(-156,157,12):
            if clear(x,z,6) and R.random()<.34:
                specpart('GrassTuft','grass',x+R.uniform(-2,2),z+R.uniform(-2,2),R.uniform(.3,.8),R.uniform(.7,2),R.uniform(.7,2),R.uniform(.6,1.6),LIME)
                if R.random()<.3: specpart('MeadowFlower','flower',x,z,1.3,.55,.55,.55,(255,226,94))
            if clear(x,z,9) and R.random()<.06:
                h=R.randint(3,7);specpart('MeadowBoulder','cover',x,z,h/2,6,6,h,ROCK,material='Slate',collide=True)
    for x,z,y in [(-20,128,24),(20,128,24),(-40,129,18),(44,136,20),(-42,78,4),(72,87,12),(-20,54,0),(20,54,0),(-117,-10,0),(-81,-59,0),(113,-5,10),(113,-76,10),(-14,17,6),(14,-17,6),(-26,-111,0),(26,-111,0),(-22,-153,0),(22,-153,0)]:lantern(x,z,y)
    for a,b in [((-128,-140),(-86,-140)),((86,-140),(128,-140)),((-96,152),(-42,152)),((42,152),(96,152)),((-162,100),(-162,60)),((162,100),(162,65))]:fence(a,b)
    # Remote decorative islands deliberately outside the playable envelope.
    for x,z,y,s in [(-260,160,30,44),(260,150,40,46),(-260,-80,-5,28),(265,-70,5,30),(-160,280,55,34),(160,280,62,35)]:
        specpart('BackgroundIslandGrass','background',x,z,y,s,s,3,GREEN)
        for k in range(3):specpart('BackgroundIslandRock','background',x,z,y-8-k*9,s*(1-k*.24),s*(1-k*.24),12,ROCK)
        tree(x,z,y+1,.55)
    from dressing import enrich
    enrich(PARTS,ROUTES,part,specpart,dist_segment,R)

def emit():
    scene={'version':4,'coordinates':'Roblox XYZ; spec X,Z,Y maps to X,Y,-Z','parts':PARTS,'routes':ROUTES,
           'protected':{'x':[-24,24],'z':[-156,-116]},'envelope':[-176,176],'summit':[0,108,48]}
    (ROOT/'scene.json').write_text(json.dumps(scene,separators=(',',':')),encoding='utf8')
    def lua(v):
        if isinstance(v,dict):return '{'+','.join('['+json.dumps(k)+']='+lua(x) for k,x in v.items())+'}'
        if isinstance(v,list) or isinstance(v,tuple):return '{'+','.join(lua(x) for x in v)+'}'
        if isinstance(v,bool):return 'true' if v else 'false'
        if v is None:return 'nil'
        return json.dumps(v)
    (ROOT/'MeadowV4Data.luau').write_text('-- Generated by geometry.py; shared with offline audit/render.\nreturn '+lua(PARTS)+'\n',encoding='utf8')
    root=ET.Element('roblox',version='4'); model=ET.SubElement(root,'Item',{'class':'Model','referent':'MeadowV4'})
    props=ET.SubElement(model,'Properties');ET.SubElement(props,'string',name='Name').text='MeadowV4'
    for i,p in enumerate(PARTS):
        item=ET.SubElement(model,'Item',{'class':'WedgePart' if p['shape']=='Wedge' else 'Part','referent':'MV4'+str(i)});pr=ET.SubElement(item,'Properties')
        ET.SubElement(pr,'string',name='Name').text=p['name']
        for key,val in [('Anchored',True),('CanCollide',p['collidable']),('CanTouch',False),('CanQuery',p['collidable'])]:ET.SubElement(pr,'bool',name=key).text=str(val).lower()
        for key,vals in [('size',p['size'])]:
            el=ET.SubElement(pr,'Vector3',name=key)
            for k,v in zip(['X','Y','Z'],vals):ET.SubElement(el,k).text=str(v)
        cf=ET.SubElement(pr,'CoordinateFrame',name='CFrame')
        for k,v in zip(['X','Y','Z'],p['position']):ET.SubElement(cf,k).text=str(v)
        for k,v in zip(['R00','R01','R02','R10','R11','R12','R20','R21','R22'],p['rotation']):ET.SubElement(cf,k).text=str(v)
        c=ET.SubElement(pr,'Color3',name='Color')
        for k,v in zip(['R','G','B'],p['color']):ET.SubElement(c,k).text=str(v/255)
        materials={'SmoothPlastic':272,'Grass':1280,'Slate':800,'Rock':896,'Basalt':788,'Wood':512,'Neon':288,'Cobblestone':880}
        ET.SubElement(pr,'token',name='Material').text=str(materials[p['material']])
        if p['shape']!='Wedge':ET.SubElement(pr,'token',name='shape').text=str({'Block':1,'Ball':0,'Cylinder':2}[p['shape']])
        ET.SubElement(pr,'float',name='Transparency').text=str(p['transparency'])
        if p['category']=='light' or p.get('point_light'):
            light=ET.SubElement(item,'Item',{'class':'PointLight','referent':'MV4Light'+str(i)})
            lp=ET.SubElement(light,'Properties')
            ET.SubElement(lp,'string',name='Name').text='WarmLanternLight'
            ET.SubElement(lp,'float',name='Brightness').text=str(p.get('light_brightness',1.5))
            ET.SubElement(lp,'float',name='Range').text='18'
            lc=ET.SubElement(lp,'Color3',name='Color')
            for k,v in zip(['R','G','B'],p['color']):ET.SubElement(lc,k).text=str(v/255)
    ET.ElementTree(root).write(ROOT/'meadow-v4.rbxmx',encoding='utf8',xml_declaration=True)
    print('Generated',len(PARTS),'parts;',len(ROUTES),'routes')

if __name__=='__main__': build();emit()
