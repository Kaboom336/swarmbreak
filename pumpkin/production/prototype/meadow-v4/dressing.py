"""Native voxel detail shared by Roblox export and Blender proof; no external assets."""
import math
def enrich(parts,routes,part,specpart,dist_segment,rng):
    edges=[(a,b,r['width']/2+4) for r in routes.values() for a,b in zip(r['points'],r['points'][1:])]
    def clear(x,z,margin=0):
        if abs(x)+abs(z)>267 or abs(x)>165 or abs(z)>165:return False
        if abs(x)<30 and -164<z<-108:return False
        if abs(x)<23 and 83<z<135:return False
        return all(dist_segment(x,z,a,b)>w+margin for a,b,w in edges)
    # Dense small leaves and turf colour: all travel envelopes keep their full width.
    greens=[(57,137,28),(74,155,31),(103,182,32),(117,196,38),(82,164,25)]
    for x in range(-160,161,5):
        for z in range(-160,161,5):
            if not clear(x,z):continue
            floor=-4 if abs(x)<64 and abs(z)<16 else 0
            for n in range(2):
                xx=x+rng.uniform(-1.5,1.5);zz=z+rng.uniform(-1.5,1.5)
                h=rng.uniform(.25,.9)
                specpart('VoxelMeadowTurf','grass',xx,zz,floor+h/2,rng.uniform(.7,1.8),rng.uniform(.7,1.8),h,rng.choice(greens))
            if rng.random()<.10:
                specpart('CreamPetal','flower',x,z,floor+1.05,.65,.65,.28,(255,241,167))
                specpart('FlowerStem','grass',x,z,floor+.5,.18,.18,1,(59,129,24))
    # Chunky open rock groups give texture and cover, without hiding sockets.
    for x,z in [(-134,92),(-118,55),(-130,10),(-125,-48),(-100,-112),(131,87),(138,25),(131,-123),(-57,15),(58,-10),(-20,-49),(36,-99)]:
        if not clear(x,z,5):continue
        floor=-4 if abs(x)<64 and abs(z)<16 else 0
        for dx,dz,w,h in [(-3,0,6,7),(3,2,5,5),(0,-4,4,3)]:
            specpart('ChunkyMeadowRock','cover',x+dx,z+dz,floor+h/2,w,w,h,(rng.randint(91,119),rng.randint(104,128),rng.randint(112,139)),material='Slate',collide=True)
            specpart('RockMossCap','grass',x+dx,z+dz,floor+h+.12,w+.15,w+.15,.3,rng.choice(greens))
    # Staggered, irregular stones break the otherwise mechanical grid of paving.
    for p in parts:
        if p['category']=='paving':
            p['size'][0]*=rng.uniform(.86,1)
            p['size'][2]*=rng.uniform(.88,1)
            p['position'][1]+=rng.uniform(.006,.018)
            if rng.random()<.18:p['color']=[188,163,124]
    # Native planks on the optional bridge, on top of its smooth collider.
    for z in range(-15,16,2):
        specpart('BridgeTimberPlank','paving',0,z,6.22,17.4,1.82,.18,(140+rng.randint(-10,10),91+rng.randint(-8,8),46+rng.randint(-5,5)),material='Wood')
    # The red disc is a visible test landmark, no simulated throw or combat result.
    for i in range(32):
        a=i/32*2*math.pi
        specpart('OptionalBridgeTellStub','test_marker',math.cos(a)*4,math.sin(a)*4,6.37,.7,.7,.10,(255,48,29),material='Neon')
    # Tall banners stay beyond the camp's central 24x24 swept court.
    for x in [-22,22]:
        specpart('CampBannerPole','banner',x,128,31,.7,.7,14,(125,76,34),material='Wood')
        specpart('CampLeafBanner','banner',x+3,128,33,5,.4,7,(28,105,47))
        specpart('BannerLeafMark','banner',x+3,127.7,33,2,.3,2,(161,216,83))
    # More organic stepped skirts on distant islands, same native-part vocabulary.
    for p in list(parts):
        if p['name']=='BackgroundIslandGrass':
            x,y,wz=p['position'];s=p['size'][0];z=-wz
            for j in range(8):
                a=j/8*math.pi*2
                h=14+rng.randrange(3)*5
                specpart('BackgroundRockTooth','background',x+math.cos(a)*s*.37,z+math.sin(a)*s*.37,y-h/2-4,s*.18,s*.18,h,(101,118,131))
