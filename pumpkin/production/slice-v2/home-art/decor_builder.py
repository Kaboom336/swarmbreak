"""Original voxel HOME dressing. Cosmetic geometry, never placement slots."""
import math
import random
import bpy
import artlib as a

def populate(box):
    rng=random.Random(71)
    def mesh(n, verts, faces, mat):
        return a.mesh(n, [(x,-z,y) for x,y,z in verts], faces, mat)
    def ring(n,x,y,z,r,thick,mat,nseg=16):
        for i in range(nseg):
            t=2*math.pi*i/nseg; u=2*math.pi*(i+1)/nseg
            verts=[(x+rr*math.cos(tt),y+rr*math.sin(tt),zz)
                   for zz in [z-1.4,z+1.4] for rr in [r-thick,r] for tt in [t,u]]
            mesh(n,verts,[(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)],mat)
    def disc(n,x,y,z,r,mat):
        verts=[(x,y,z)]+[(x+r*math.cos(i*math.tau/48),y+r*math.sin(i*math.tau/48),z) for i in range(48)]
        mesh(n,verts,[(0,i+1,(i+1)%48+1) for i in range(48)],mat)
    def tree(x,y,z,s=1,snow=False,palm=False):
        box('Tree',(x,y+7*s,z),(2.8*s,14*s,2.8*s),'Wood',.08)
        if palm:
            for dx,dz in [(8,0),(-8,0),(0,8),(0,-8)]:
                box('PalmFrond',(x+dx*s/2,y+14*s,z+dz*s/2),((abs(dx)+2)*s,1.8*s,(abs(dz)+2)*s),'Leaf',.18)
        else:
            for dx,dy,dz,w in [(0,16,0,12),(-4,14,0,8),(4,15,1,8),(0,22,0,7)]:
                box('TreeCrown',(x+dx*s,y+dy*s,z+dz*s),(w*s,6*s,w*s),'Snow' if snow else 'Leaf',.1)
    def bush(x,y,z,s=1):
        box('BlockBush',(x,y+2.5*s,z),(5*s,5*s,5*s),'Leaf',.06)
        box('BushTop',(x,y+5.3*s,z),(4.6*s,.6*s,4.6*s),'Lime',.02)
    def lantern(x,y,z):
        box('LampFoot',(x,y+.5,z),(4,1,4),'Slate',.06)
        box('LampPost',(x,y+3.5,z),(1.8,7,1.8),'Wood',.1)
        box('LampGlow',(x,y+7.5,z),(3.2,3.5,3.2),'LampLight',.1)
        box('LampHat',(x,y+9.6,z),(5,1,5),'Wood',.12)
        for dx in [-1.6,1.6]:
            box('LampFrame',(x+dx,y+7.5,z),(0.4,4,.4),'Wood',0)
    # Match the complete gameplay plot roots: back rows rise by 3.5 studs.
    box('GrassSkin',(0,.035,0),(216,.06,320),'Grass',0)
    for row,z in enumerate([96,32,-32,-96]):
        top=row*3.5
        for side in [-1,1]:
            x=side*52
            # Terrace shoulder outside the playable footprint; plot itself stays flat.
            # A broken shoulder profile exposes the tier's front and cliff faces.
            for zz in range(-28,29,8):
                outer=100+(zz//8)%3*3
                box('TerraceVoxel',(side*outer,top-2,z+zz),(12,4,7.9),'Grass',0)
                box('ShoulderStone',(side*(outer+2),top-5,z+zz),(11,6,7.9),'Slate',0)
            for zz in range(-28,29,8):
                h=15+(zz//8)%3*4
                box('CliffVoxel',(side*(106+(zz//8)%2*2),top-h/2-2,z+zz),(8,h,8),'Slate',0)
                box('VoxelGrassLip',(side*108,top-.3,z+zz),(10,1.6,8),'Grass',0)
                if (zz+28)%16==0: bush(side*99,top,z+zz,1.2)
            for zz in [-28,28]:
                for dx in [88,96,104]:
                    bush(side*dx,top,z+zz,.9)
            # Distinct stepped grass fascia between plots, outside all placement bounds.
            for dx in [88,96,104]:
                box('TierGrassEdge',(side*dx,top-1,z+30),(7.9,2,4),'Grass',0)
                box('TierRockFace',(side*dx,top-3,z+31),(7.9,3,2),'Slate',0)
            box('PlotRockRiser',(x,top/2-1.8,z),(66,top+3.2,50),'Slate',0)
            box('PlotGrassRiser',(x,top-.65,z),(66,1.7,50),'Grass',0)
            box('PlotSkin',(x,top+.215,z),(64,.025,48),'Grass',0)
            # Exposed chunky front face, under each full plot, rather than edge-only tiers.
            for dx in range(-30,31,6):
                box('RiserStone',(x+dx,top-2,z+25.4),(5.8,2.5+rng.random(),1.5),'Stone' if dx%3 else 'Slate',.08)
                box('RiserGrassLip',(x+dx,top-.2,z+25.5),(6,1.0,2),'Grass',0)
            for i in range(48):
                dx=rng.uniform(-30,30);dz=rng.uniform(-22,22)
                box('GrassMottle',(x+dx,top+.242,z+dz),(rng.uniform(1,3),.024,rng.uniform(1,3)),'GrassLight',0)
            for dx in [-23,-8,8,23]:
                for dz in [-10,10]:
                    box('PadRim',(x+dx,top+.30,z+dz),(12.5,.16,14),'Stone',.18)
                    box('PadSlate',(x+dx,top+.41,z+dz),(11.5,.08,13),'Slate',.12)
            for dz in [-24,24]:
                for yy in [1.5,3.6]: box('FenceRail',(x,top+yy,z+dz),(64,1.6,2),'Wood',.1)
                for dx in [-32,-16,0,16,32]:
                    box('FencePost',(x+dx,top+2.6,z+dz),(3.4,5.2,3.4),'Wood',.15)
                    box('FenceCap',(x+dx,top+5.35,z+dz),(3.8,.55,3.8),'DarkWood',.07)
            for yy in [1.5,3.6]:
                box('OuterFence',(x+side*32,top+yy,z),(2,1.6,48),'Wood',.1)
                for dz in [-15,15]: box('GateRail',(x-side*32,top+yy,z+dz),(2,1.6,18),'Wood',.1)
            for dz in [-24,-6,6,24]: box('GatePost',(x-side*32,top+2.6,z+dz),(3.4,5.2,3.4),'Wood',.1)
            for dx in [-24,0,24]: bush(x+dx,top+.2,z-29,.9)
    # Front cliff teeth beneath the grass lip, visible from the unchanged camera.
    for x in range(-108,109,8):
        h=15+rng.randrange(4)*4
        box('FrontCliff',(x,-h/2-1,137+(x//8)%3*2),(8,h,12),'Slate',0)
        box('FrontGrassLip',(x,-.4,135),(8,1.6,12),'Grass',0)
        if abs(x)>26: bush(x,0,131,.9)
    # Raised back row, with individual stairs, segmented stone rings and padlocks.
    box('BackTerrace',(0,7,-145),(216,14,30),'Grass',0)
    for x in [-66,-22,22,66]:
        for i in range(6):
            box('PortalSteps',(x,(i+1)*.8,-121-i*3),(28,(i+1)*1.6,3),'Stone',.06)
        disc('LockedDisc',x,20,-145,9.8,'Ink')
        ring('LockedStoneRing',x,20,-146,13,3.2,'Slate')
        box('ArchPedestal',(x,10.6,-145),(29,1.2,9),'Slate',.1)
        box('LockBody',(x,19,-142.8),(4.3,4.2,1),'Snow',.25)
        ring('LockShackle',x,22,-143,2.2,.65,'Snow',12)
        box('Keyhole',(x,19,-142.1),(.7,1.8,.1),'Ink',.05)
        box('PortalNameBoard',(x,36,-146),(32,4.5,1),'Ink',.1)
    for x in [-93,-44,0,44,93]: tree(x,10,-151,.6)
    # Hero portal ring aligned with the unchanged trigger/landing.
    disc('HeroDisc',0,19,0,15,'PortalGreen')
    ring('HeroRing',0,19,0,20,5,'Slate',16)
    ring('HeroRingBack',0,19,-3,20,5,'Stone',16)
    for i in range(8):
        t=math.tau*i/8
        o=box('GreenInset',(17*math.cos(t),19+17*math.sin(t),1.5),(3.5,3,1),'PortalGreen',.1)
        o.rotation_euler[1]=-t
    verts=[]
    for i in range(121):
        t=i/120;theta=t*math.pi*4;radius=.5+12.5*t
        for side in [-1,1]: verts.append(((radius+side*.35)*math.cos(theta),19+(radius+side*.35)*math.sin(theta),1.8))
    mesh('PortalSpiral',verts,[(2*i,2*i+1,2*i+3,2*i+2) for i in range(120)],'PortalLight')
    for x in [-24,24]:
        for z in [30,126]: lantern(x,0,z)
    # Hexagonal pink stone course, seams and alternating entry stripes.
    box('PathUnderlay',(0,.09,0),(40,.08,252),'PinkStone',0)
    for row,z in enumerate(range(-118,127,5)):
        for x in [-16,-8,0,8,16]:
            xx=x+(row%2)*4
            if xx>19: continue
            # Non-overlapping, upward-facing faces prevent ray-shadow speckling.
            verts=[(xx+3.85*math.cos(i*math.tau/6),.145,z+2.75*math.sin(i*math.tau/6)) for i in range(6)]
            mesh('HexPaving',verts,[tuple(reversed(range(6)))],'PinkStone' if (row+x)%3 else 'Path')
    for i in range(8): box('EntryStripe',(-17.5+i*5,.3,112),(5,.3,12),'Green' if i%2 else 'Snow',0)
    # Four original themed floating vistas, situated inside the stored camera frustum.
    for theme,x,y,z,w in [('Snow',-139,37,-190,42),('Volcano',137,40,-198,45),('Crystal',118,27,-144,30),('Palm',135,8,-62,36)]:
        mat='Snow' if theme=='Snow' else 'Sand' if theme=='Palm' else 'DarkRock' if theme=='Volcano' else 'Grass'
        box('VistaCap',(x,y-2,z),(w,4,w),mat,0)
        for layer in range(4):
            box('VistaCore',(x,y-8-layer*9,z),(w*(1-layer*.22),10,w*(1-layer*.22)),'Slate',0)
        for i in range(9):
            theta=math.tau*i/9;h=14+i%3*7
            box('VistaTeeth',(x+math.cos(theta)*w*.4,y-h/2-3,z+math.sin(theta)*w*.4),(6,h,6),'Slate',0)
        if theme=='Snow':
            for i in range(4): box('SnowMountain',(x,y+4+i*6,z),(30-i*6,8,28-i*6),'Snow',0)
            for dx,dz in [(-13,10),(14,8),(-8,-10)]: tree(x+dx,y,z+dz,.45,True)
            box('IceWaterfall',(x+8,y-17,z+w/2),(5,38,1),'Cyan',0)
        elif theme=='Volcano':
            for i in range(4): box('VolcanoPeak',(x,y+4+i*5,z),(34-i*7,7,30-i*6),'DarkRock',0)
            box('LavaMouth',(x,y+22,z),(7,1,6),'Lava',.1)
            box('LavaFall',(x+7,y-8,z+w/2),(4,48,1),'Lava',0)
            for i in range(4): box('LavaChannel',(x+4,y+4+i*5,z+14-i*3),(3,6,1),'Lava',0)
        elif theme=='Crystal':
            for dx,h,dz in [(-8,15,4),(0,25,0),(8,19,-5),(6,10,8)]:
                a.rings('Crystal',[(3,0),(3,h*.7),(0,h)],'Crystal',n=5)
                a.objects[-1].location=(x+dx,-(z+dz),y)
        else:
            box('Lagoon',(x,y+.1,z),(20,.2,19),'Cyan',.05)
            for dx,dz in [(-12,9),(12,7),(-9,-11),(10,-11)]: tree(x+dx,y,z+dz,.7,palm=True)
    for x,y,z in [(-125,30,-105),(110,60,-210),(-80,65,-230),(60,55,-220),(-144,4,10)]:
        box('Cloud',(x,y,z),(14,6,8),'Snow',.5)
