-- Offline geometry authoring. No gameplay script from the existing prototype is changed.
-- Run from production after Rojo builds prototype/meadow-study-seed.rbxl.
local fs = require("@lune/fs")
local rb = require("@lune/roblox")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local V, CF, C, E, I = rb.Vector3, rb.CFrame, rb.Color3, rb.Enum, rb.Instance
local green, rock, stone, wood = C.fromRGB(111,158,85), C.fromRGB(113,122,137), C.fromRGB(180,173,157), C.fromRGB(136,96,61)
local cyan = C.fromRGB(65,220,240)
local sceneSource = fs.readFile("slice-v2/prototype/Scene.luau")
-- Only the inspected native-art helpers are invoked. Layout is unused by these helpers.
local Scene = luau.load(sceneSource, {environment={Vector3=V,CFrame=CF,Color3=C,Enum=E,Instance=I,
    game={GetService=function() return {WaitForChild=function() return {} end} end}, require=function() return {} end}})()
local reports = {}
local function model(parent, name)
    local m=I.new("Model"); m.Name=name; m.Parent=parent; return m
end
local function world(x,y,z) return V.new(x,y,-z) end
local function make(parent,name,size,position,color)
    local p=I.new("Part"); p.Name=name; p.Size=size; p.CFrame=CF.new(position)
    p.Anchored=true; p.Color=color or green; p.Material=E.Material.Grass
    p.TopSurface=E.SurfaceType.Smooth; p.BottomSurface=E.SurfaceType.Smooth; p.Parent=parent
    return p
end
local function deco(parent,name,size,pos,color,material)
    local p=make(parent,name,size,pos,color); p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
    p.Material=material or E.Material.Slate; return p
end
local function box(parent,name,x,z,top,w,d,bottom,color)
    bottom=bottom or 0
    local p=make(parent,name,V.new(w,top-bottom,d),world(x,(top+bottom)/2,z),color or rock)
    p.Material=E.Material.Slate
    local cap=make(parent,name.."Grass",V.new(w,0.5,d),world(x,top-0.25,z),green)
    return p,cap
end
local function path(parent,name,a,b,width,color,solid)
    local av,bv=world(a[1],a[2],a[3]),world(b[1],b[2],b[3])
    local dv=bv-av; local run=V.new(dv.X,0,dv.Z).Magnitude
    assert(run>0 and width>=12, name.." minimum walking width")
    local slope=math.deg(math.atan(math.abs(dv.Y)/run))
    assert(slope<=25.001, name.." ramp slope "..slope)
    local forward=dv.Unit; local right=forward:Cross(V.yAxis).Unit
    local cf=CF.fromMatrix((av+bv)/2,right,right:Cross(forward).Unit,-forward)
    local p=make(parent,name,V.new(width,0.5,dv.Magnitude+0.2),V.zero,color or stone)
    p.Material=E.Material.Cobblestone; p.CFrame=cf*CF.new(0,-0.20,0)
    if a[2]==b[2] and a[2]<=0 then p.CanCollide=false end -- ground trail marking; land provides collision
    p:SetAttribute("LaneWidth",width); p:SetAttribute("SlopeDegrees",slope)
    p:SetAttribute("Start",av); p:SetAttribute("Finish",bv); p:SetAttribute("WalkSurface",true)
    if solid and math.max(a[2],b[2])>0 and a[2]~=b[2] then
        -- Individual filled skirts never rise above the deck. No concealed tunnels.
        local steps=math.ceil(run/3)
        for j=1,steps do
            local t=(j-0.5)/steps; local low=math.min(a[2]+(b[2]-a[2])*(j-1)/steps,a[2]+(b[2]-a[2])*j/steps)-0.6
            if low>0 then
                local q=make(parent,name.."Skirt"..j,V.new(width,low,run/steps+0.12),V.zero,rock)
                q.Material=E.Material.Slate
                q.CFrame=CF.fromMatrix(world(a[1]+(b[1]-a[1])*t,low/2,a[3]+(b[3]-a[3])*t),right,V.yAxis,right:Cross(V.yAxis))
            end
        end
    end
    return p
end
local function route(parent,name,points,width,solid)
    local m=model(parent,name); local length=0
    for j=2,#points do
        path(m,name..j,points[j-1],points[j],width,nil,solid)
        local a,b=points[j-1],points[j]
        length+=(V.new(b[1],b[2],b[3])-V.new(a[1],a[2],a[3])).Magnitude
    end
    return length
end
local function court(parent,name,x,y,z)
    local p=make(parent,name,V.new(24,0.2,24),world(x,y-0.05,z),stone); p.Material=E.Material.Cobblestone
    p:SetAttribute("JunctionWidth",24); return p
end
local function base(parent,w,d,valley,gully)
    local land=model(parent,"OneContinuousLandBase")
    land:SetAttribute("FootprintWidth",w); land:SetAttribute("FootprintDepth",d)
    -- Connected rounded strips: one island, with a shallow traversable valley where requested.
    for z=-d/2+4,d/2-4,8 do
        local endZone=math.max(0,math.abs(z)-d/2+32)
        local width=w-2*math.floor(endZone*0.65/4)*4
        local top=valley and math.abs(z)<16 and -4 or 0
        if gully and z>=gully[3] and z<gully[4] then
            box(land,"GrassLandWest"..z,(-width/2+gully[1])/2,z,top,gully[1]+width/2,8,-12)
            box(land,"GrassLandEast"..z,(width/2+gully[2])/2,z,top,width/2-gully[2],8,-12)
            box(land,"ShallowJumpRecovery"..z,(gully[1]+gully[2])/2,z,gully[5] or -3,gully[2]-gully[1],8,-12)
        else
            box(land,"GrassLand"..z,0,z,top,width,8,-12)
        end
        for _,side in {-1,1} do
            local x=side*(width/2-3)
            local h=22+(math.floor(z/8)%4)*3
            deco(land,"CliffColumn",V.new(6,h,8),world(x,-h/2-2,z),rock)
        end
    end
    -- The interior lower floor joins both banks; no disconnected islets.
    if valley then
        path(land,"WestRecovery",{-40,-4,8},{-40,0,18},18,stone,false)
        path(land,"EastRecovery",{40,-4,-8},{40,0,-18},18,stone,false)
        path(land,"NorthFloorExit",{40,-4,8},{40,0,18},18,stone,false)
        path(land,"SouthFloorExit",{-40,-4,-8},{-40,0,-18},18,stone,false)
    end
    -- Tapered hanging strata kept inside the rounded boundary.
    for j,s in {0.85,0.64,0.39,0.17} do
        deco(land,"FloatingRockStratum"..j,V.new(w*s,13,d*s),world(j%2*4,-19-(j-1)*12,0),rock)
    end
end
local function fence(parent,x,y,z,w)
    for _,dx in {-w/2,0,w/2} do deco(parent,"FencePost",V.new(1.2,4.5,1.2),world(x+dx,y+2.25,z),wood,E.Material.Wood) end
    for _,dy in {1.3,3.2} do deco(parent,"FenceRail",V.new(w,0.6,0.6),world(x,y+dy,z),wood,E.Material.Wood) end
end
local function hill(parent,name,x,z,h,w,d)
    local m=model(parent,name)
    box(m,name.."Terrace",x,z,h,w,d,0)
    local run=math.ceil(h/math.tan(math.rad(25)))+1
    path(m,name.."NorthRamp",{x,h,z+d/2},{x,0,z+d/2+run},16,nil,true)
    path(m,name.."SouthRamp",{x,h,z-d/2},{x,0,z-d/2-run},16,nil,true)
    Scene.tree(m,world(x+w/2-6,h,z),make,0.65)
    fence(m,x,h,z+d/2-2,w)
    return m
end
local function acorn(parent,x,y,z)
    -- Reuse the existing native closed-acorn silhouette, gold material; no asset uploads.
    local m=model(parent,"GoldenAcornAtCamp")
    local body=deco(m,"GoldenShell",V.new(4.5,5,4.5),world(x,y+3.3,z),C.fromRGB(245,186,53),E.Material.Metal)
    body.Shape=E.PartType.Ball
    local cap=deco(m,"AcornCap",V.new(1.2,5.3,5.3),world(x,y+5.2,z),C.fromRGB(167,111,35),E.Material.Metal)
    cap.Shape=E.PartType.Cylinder; cap.CFrame*=CF.Angles(0,0,math.pi/2)
    deco(m,"AcornStem",V.new(0.7,1.5,0.7),world(x,y+6.3,z),wood,E.Material.Wood)
    local nest=deco(m,"Nest",V.new(1,8,8),world(x,y+0.5,z),wood,E.Material.Wood)
    nest.Shape=E.PartType.Cylinder; nest.CFrame*=CF.Angles(0,0,math.pi/2)
    return m
end
local function keeper(parent,x,y,z)
    local m=model(parent,"MeadowKeeperStandIn")
    local skin=C.fromRGB(216,177,111); local brown=C.fromRGB(111,77,48); local straw=C.fromRGB(220,173,73)
    for _,dx in {-1.3,1.3} do deco(m,"Boot",V.new(2,3,2.7),world(x+dx,y+1.5,z),brown,E.Material.Wood) end
    deco(m,"Apron",V.new(5,5,2.8),world(x,y+5.5,z),C.fromRGB(64,113,66),E.Material.Fabric)
    deco(m,"Head",V.new(3.3,3,3.3),world(x,y+9.2,z),skin,E.Material.SmoothPlastic)
    for _,dx in {-3.7,3.7} do deco(m,"Arm",V.new(2,5,2),world(x+dx,y+6,z),brown,E.Material.Fabric) end
    local brim=deco(m,"WideHatBrim",V.new(0.6,11,11),world(x,y+11,z),straw,E.Material.Wood)
    brim.Shape=E.PartType.Cylinder; brim.CFrame*=CF.Angles(0,0,math.pi/2)
    deco(m,"HatCrown",V.new(5,2,5),world(x,y+12,z),straw,E.Material.Wood)
    for _,dx in {-0.8,0.8} do deco(m,"Eye",V.new(0.4,0.6,0.1),world(x+dx,y+9.4,z-1.69),C.fromRGB(35,29,23),E.Material.SmoothPlastic) end
    m:SetAttribute("HatDiameter",11); m:SetAttribute("StandInOnly",true)
end
local function camp(parent,x,z,h,w)
    local m=model(parent,"RaisedTreasureCamp")
    box(m,"CampTerrace",x,z,h,w,w,0)
    acorn(m,x,h,z-3); keeper(m,x+9,h,z+6)
    Scene.tree(m,world(x-w/2+6,h,z+w/2-6),make,0.85)
    fence(m,x,h,z+w/2-1,w-4)
    for _,dx in {-w/2+2,w/2-2} do Scene.lantern(m,world(x+dx,h,z-w/2+3),make) end
    for i=-w/2+4,w/2-4,6 do
        for _,side in {-1,1} do
            deco(m,"CampRockFacet",V.new(3,4,4),world(x+side*(w/2+0.4),h-3.2,z+i),C.fromRGB(104+(i%3)*5,115,132))
            deco(m,"CampRockFacet",V.new(4,4,3),world(x+i,h-3.2,z+side*(w/2+0.4)),rock)
        end
    end
end
local function portal(parent,z,northStart)
    local m=model(parent,"CyanPortalSafety")
    local apron=make(m,"ProtectedApron",V.new(48,0.04,40),world(0,0.035,z),cyan)
    apron.Transparency=0.82; apron.CanCollide=false; apron.CanQuery=false
    local pad=make(m,"PortalPad32x24",V.new(32,0.15,24),world(0,0.06,z),stone)
    pad.Material=E.Material.Cobblestone; pad.CanCollide=false
    Scene.portal(m,world(-7,9,z-4),9,make,false)
    for _,x in {-20,20} do Scene.lantern(m,world(x,0,z-6),make) end
    -- Three routes remain separate until crossing the apron.
    route(parent,"WestSafetyEntry",{{-38,0,z+20},{-38,0,z},{-24,0,z}},18)
    route(parent,"EastSafetyEntry",{{38,0,z+20},{38,0,z},{24,0,z}},18)
    route(parent,"NorthSafetyEntry",{{0,0,northStart or z+34},{0,0,z+20},{0,0,z+10}},16)
end
local function cover(parent,x,z,h)
    box(parent,"OpenRockCutback",x,z,h,8,12,0,rock)
end
local function scenery(parent,w,d,protected)
    local m=model(parent,"NativeMeadowDressing")
    for _,p in {{-w/2+13,0,-d/2+20},{w/2-13,0,-d/2+24},{-w/2+13,0,d/2-18},{w/2-13,0,d/2-18},
        {-w/2+10,0,30},{w/2-10,0,36},{-w/2+10,0,-28},{w/2-10,0,-30}} do
        Scene.tree(m,world(p[1],p[2],p[3]),make,0.7)
    end
    for i=0,11 do
        local a=i*math.pi/6; local x=math.cos(a)*(w/2-10); local z=math.sin(a)*(d/2-10)
        if z>protected+25 or math.abs(x)>28 then
            for j=1,3 do
                deco(m,"ChunkyGrass",V.new(3+j%2,2+j%3,3),world(x+(j-2)*3,1+j%3/2,z),C.fromRGB(99+j*8,150+j*6,68+j*4),E.Material.Grass)
            end
        end
    end
    -- Critic fix: dense chunky rim and broken faces; no new gameplay collision.
    for z=-d/2+4,d/2-4,8 do
        local endZone=math.max(0,math.abs(z)-d/2+32)
        local half=w/2-math.floor(endZone*0.65/4)*4
        for _,side in {-1,1} do
            for j=0,2 do
                deco(m,"RimGrassFringe",V.new(3,1.2+(j%2),3),world(side*(half-2-j*2),0.3+j%2/2,z+j-1),C.fromRGB(94+j*9,151+j*7,65+j*5),E.Material.Grass)
            end
            deco(m,"BrokenCliffFace",V.new(3,5+(math.floor(z/8)%3)*2,5),world(side*(half-1),-4-(math.floor(z/8)%2)*3,z),rock)
        end
    end
    Scene.surroundings(parent,V.zero,make)
    for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.CanCollide=false end end
end
local function optionalJumps(parent,x,z,floorY,count)
    local m=model(parent,"OptionalJumpCutWithWalkingBypass")
    -- Floor is reachable; platforms do not replace the uninterrupted ground lane.
    count=count or 3
    for i=0,count-1 do box(m,"JumpLanding"..i,x+i*16,z, floorY+2+i*2,12,12,floorY) end
    local last=x+(count-1)*16
    if floorY==-4 then
        path(m,"LandingWalkingRamp",{last,floorY+count*2,z-6},{last,floorY,z-15},12,nil,true)
    else
        path(m,"LandingWalkingRamp",{last,floorY+count*2,z+6},{last,floorY,z+20},12,nil,true)
    end
    local bypassZ=floorY==-4 and z+8 or z+14
    path(m,"GroundBypass",{x-8,floorY,bypassZ},{last+8,floorY,bypassZ},12)
    m:SetAttribute("Optional",true); m:SetAttribute("GapStuds",4)
end
local function camera(parent,name,eye,target,fov)
    local c=I.new("Camera"); c.Name=name; c.CFrame=CF.lookAt(eye,target); c.FieldOfView=fov; c.Parent=parent; return c
end
local function buildA(root)
    base(root,192,176,false,{-44,-4,48,88})
    -- Low core shoulders do not obstruct the three thirty-two-stud camp ramps.
    box(root,"CentralRockCore56",0,24,4,56,56,0)
    -- Carve the shoulder under the south ramp by using two side slabs instead.
    for _,p in root:GetChildren() do if p.Name:find("CentralRockCore56") then p:Destroy() end end
    box(root,"CoreWest",-24,20,4,8,56,0); box(root,"CoreEast",24,20,4,8,56,0)
    box(root,"CoreNorth",0,44,4,40,8,0)
    camp(root,0,20,14,40)
    local quick={{0,14,20},{-12,14,0},{-12,14,-8},{-36,0,-32},{-36,0,-44},{0,0,-44},{0,0,-68}}
    local n=route(root,"MainSouthDescent",quick,16,true)
    path(root,"CampWestApron",{-20,14,32},{-20,14,48},16,nil,true)
    path(root,"CampEastApron",{20,14,32},{20,14,48},16,nil,true)
    path(root,"CampWestCorner",{-20,14,48},{-28,14,48},16,nil,true)
    path(root,"CampEastCorner",{20,14,48},{28,14,48},16,nil,true)
    path(root,"CampWestRamp",{-28,14,48},{-60,0,48},16,nil,true)
    path(root,"CampEastRamp",{28,14,48},{60,0,48},16,nil,true)
    hill(root,"WestOrchard",-60,6,8,24,24); hill(root,"EastRidge",60,6,10,24,24)
    route(root,"OuterOrchardRing",{{-60,0,48},{-80,0,48},{-80,0,-48},{-38,0,-48}},18)
    route(root,"OuterRidgeRing",{{60,0,48},{80,0,48},{80,0,-48},{38,0,-48}},16)
    route(root,"NorthInnerLink",{{-40,0,4},{-44,0,-16},{-44,0,-44},{0,0,-44},{36,0,-44},{40,0,4}},12)
    route(root,"SouthCrossLink",{{-48,0,-32},{-48,0,-44},{0,0,-44},{0,0,-32},{48,0,-32}},16)
    court(root,"I1West",-40,0,4); court(root,"I2East",40,0,4); court(root,"I3South",0,0,-32)
    cover(root,-30,4,7); cover(root,-74,-12,6); cover(root,20,-20,7)
    optionalJumps(root,-32,62,-3,2)
    path(root,"JumpRecoveryWest",{-34,-3,76},{-44,0,76},12)
    path(root,"JumpRecoveryEast",{-14,-3,76},{-4,0,76},12)
    portal(root,-68); scenery(root,192,176,-68)
    return quick,n
end
local function buildB(root)
    base(root,176,192,false,{32,72,56,96})
    -- 88-square low core, with a clear southern corridor for the staged descent.
    box(root,"SummitCoreWest",-30,26,0,28,88,-4); box(root,"SummitCoreEast",30,26,0,28,88,-4)
    box(root,"SummitCoreNorth",0,56,0,32,28,-4)
    box(root,"SummitMiddle",0,30,8,40,40,0)
    camp(root,0,26,24,32)
    local spiral=model(root,"GreenSpiral16Wide_OneAndQuarterTurns")
    local points={}
    -- Outer to inner; 450 degrees, distinct lateral spacing at the overlapping turn.
    for j=0,60 do
        local t=j/60; local a=math.rad(90+450*t)
        local r=t<=0.4 and 60-20*t or 52-(22/0.6)*(t-0.4)
        local y=t<=0.4 and 30*t or 12+20*(t-0.4)
        table.insert(points,{math.cos(a)*r,y,26+math.sin(a)*r})
    end
    route(spiral,"Spiral",points,16,true)
    for j=8,#points,3 do
        local p=points[j]; local radial=V.new(p[1],0,p[3]-26).Unit
        deco(spiral,"OuterSpiralRockFacet",V.new(4,5,4),world(p[1]+radial.X*9,p[2]-3.5,p[3]+radial.Z*9),rock)
        deco(spiral,"OuterSpiralGrassTuft",V.new(2,1.5,3),world(p[1]+radial.X*9,p[2]-0.2,p[3]+radial.Z*9),green,E.Material.Grass)
    end
    path(root,"SpiralCampJoin",{-30,24,26},{-16,24,26},16,nil,true)
    local quick={{0,24,26},{0,24,10},{0,18,-3},{0,18,-9},{0,12,-22},{0,12,-30},{0,6,-43},{0,0,-56},{0,0,-76}}
    local n=route(root,"OrangeShelfDescent",quick,16,true)
    -- Wide flat shelves fit outside the camp; step ramps have fourteen horizontal run.
    for _,p in {{-6,18,6},{-26,12,8}} do
        box(root,"SouthGrassShelf",0,p[1],p[2],24,p[3],0)
    end
    -- The third broad shelf is lateral, keeping its mandatory walking ramp outside safety.
    box(root,"Height6FootShelf",-22,-31,6,28,24,0)
    path(root,"Height6ShelfJoin",{0,6,-43},{-22,6,-43},12,nil,false)
    path(root,"Height6ShelfSouthRamp",{-22,6,-43},{-22,0,-56},12,nil,true)
    -- A second complete walking route on the open east flank, outside the spiral footprint.
    route(root,"EastSwitchback12Wide",{{16,24,26},{44.666667,16,26},{70,16,26},{70,16,20},{70,12,10},{70,12,-20},{78,8,-32},{78,4,-44},{78,0,-56},{78,0,-68},{38,0,-68},{38,0,-76}},12,true)
    hill(root,"WestFootHill",-58,-30,8,20,20); hill(root,"EastFootHill",56,-30,10,20,20)
    court(root,"I1SummitFork",0,24,26); court(root,"I2EastLanding",70,12,-2); court(root,"I3FootCourt",-22,6,-31)
    route(root,"FootCrossLink",{{-42,0,-38},{-42,0,-62},{-38,0,-62}},12)
    route(root,"EastFootLink",{{24,0,-38},{24,0,-54},{42,0,-54},{38,0,-56}},16)
    local saddle={}
    for j=25,31 do table.insert(saddle,points[j]) end
    table.insert(saddle,{36,14,-30}); table.insert(saddle,{46,10,-30}); table.insert(saddle,{66,10,-30}); table.insert(saddle,{70,12,-14})
    route(root,"Height12CrossLink",saddle,12,true)
    cover(root,-16,-56,7); cover(root,18,-66,6)
    optionalJumps(root,44,74,-3,2)
    path(root,"JumpRecoveryWest",{42,-3,88},{32,0,88},12)
    path(root,"JumpRecoverySouth",{66,-3,66},{66,0,56},12)
    portal(root,-76,-55.9); scenery(root,176,192,-76)
    return quick,n
end
local function buildC(root)
    base(root,192,192,true,{58,96,-56,-24,-4})
    camp(root,0,62,12,40)
    -- Three camp descents point south/west/east. The south ramp dog-legs on the north bank.
    local quick={{0,12,62},{-15,12,40},{-23,12,40},{-50,0,40},{-50,0,24},{-16,0,24},{-16,0,30},{0,0,30},{0,6,16},{0,6,-16},{0,0,-30},{0,0,-50},{0,0,-70}}
    local n=route(root,"MainBridgeEscape",quick,16,true)
    path(root,"CampWestRamp",{-20,12,74},{-47,0,74},18,nil,true)
    path(root,"CampEastRamp",{20,12,74},{47,0,74},16,nil,true)
    -- Bridge: precisely 12x32, no side walls. Replace only the central sixteen-wide route deck.
    local main=root:FindFirstChild("MainBridgeEscape")
    local deck=main:FindFirstChild("MainBridgeEscape10")
    if deck then deck.Size=V.new(12,0.5,32); deck.Material=E.Material.WoodPlanks; deck.Color=wood; deck:SetAttribute("LaneWidth",12) end
    -- No filled skirt underneath the optional bridge; lower acorns remain recoverable.
    for _,p in main:GetChildren() do if p.Name:find("MainBridgeEscape10Skirt") then p:Destroy() end end
    route(root,"WestCoveredCauseway18",{{-47,0,74},{-80,0,74},{-80,0,18},{-80,-4,8},{-80,-4,-8},{-76,-4,-8},{-66,0,-8},{-66,0,-34},{-38,0,-50}},18,true)
    -- The west crossing covers the valley while all surrounding lower ground stays continuous.
    box(root,"WestCausewayNorthLand",-66,9,0,18,14,-4)
    box(root,"WestCausewaySouthLand",-61.5,-7,0,9,18,-4)
    hill(root,"WestHill",-60,24,8,12,24)
    box(root,"WestHillValleyLanding",-57,-8,0,18,24,-4)
    hill(root,"EastRidge",60,24,10,24,24)
    route(root,"EastWalkingApproach",{{47,0,74},{60,0,74},{60,0,59}},16)
    route(root,"EastSouthExit",{{60,0,-11},{60,0,-20},{52,0,-20},{38,0,-50}},16)
    -- West link climbs through the camp instead of drawing a false ground trail beneath hills.
    route(root,"NorthBankWestCampLink",{{-80,0,34},{-80,0,74},{-47,0,74},{-20,12,74},{0,12,62}},16,true)
    route(root,"NorthBankEastLink",{{0,0,30},{20,0,34},{40,0,34},{40,0,62},{60,0,62}},16)
    route(root,"SouthBankCrossLinkZMinus34",{{-66,0,-34},{0,0,-34},{52,0,-34}},16)
    -- Offset court laterally: its full 24 square cannot occupy the bridge ramp foot.
    court(root,"I1NorthBank",20,0,34); court(root,"I2EastLanding",52,0,-20); court(root,"I3SouthBank",-20,0,-34)
    cover(root,-89,24,7); cover(root,-51,-20,7); cover(root,22,-52,6)
    optionalJumps(root,70,-40,-4,2)
    path(root,"EastJumpRecoveryWest",{68,-4,-32},{58,0,-32},12)
    path(root,"EastJumpRecoveryNorth",{70,-4,-34},{70,0,-24},12)
    portal(root,-70); scenery(root,192,192,-70)
    return quick,n
end
for _,letter in {"A","B","C"} do
    local game=rb.deserializePlace(fs.readFile("prototype/meadow-study-seed.rbxl"))
    local ws=game:GetService("Workspace")
    local root=model(ws,"Meadow"..letter)
    root:SetAttribute("LayoutStudy",true); root:SetAttribute("GameplayTests","NOT RUN: geometry study")
    root:SetAttribute("CoordinateConvention","Map north +Z = world -Z")
    local points,length=({A=buildA,B=buildB,C=buildC})[letter](root)
    local spawn=I.new("SpawnLocation"); spawn.Name="CampWalkStart"; spawn.Anchored=true; spawn.Size=V.new(4,0.2,4)
    spawn.CFrame=CF.new(world(points[1][1]-8,points[1][2]+0.1,points[1][3])); spawn.Transparency=1; spawn.CanCollide=false
    spawn.Neutral=true; spawn.Duration=0; spawn.Parent=ws
    local views=I.new("Folder"); views.Name="ReviewCameras"; views.Parent=ws
    camera(views,"Top",world(0,900,-0.1),world(0,0,0),16)
    local view=camera(views,"ThreeQuarter",world(-135,125,-220),world(0,7,8),54)
    ws.CurrentCamera=view
    local light=game:GetService("Lighting")
    light.Ambient=C.fromRGB(126,139,107); light.OutdoorAmbient=C.fromRGB(161,172,139)
    local sky=I.new("Sky"); sky.Parent=light
    local maxSlope=0; local ramps=0; local parts=0
    for _,p in root:GetDescendants() do
        if p:IsA("BasePart") then parts+=1 end
        local slope=p:GetAttribute("SlopeDegrees")
        if slope then maxSlope=math.max(maxSlope,slope); ramps+=1 end
    end
    local file="prototype/meadow-"..letter..".rbxl"
    fs.writeFile(file,rb.serializePlace(game))
    local roundtrip=rb.deserializePlace(fs.readFile(file))
    assert(roundtrip:GetService("Workspace"):FindFirstChild("Meadow"..letter),"place roundtrip")
    reports[letter]={file=file,parts=parts,routeStuds=length,walkSecondsEstimated=length/15,walkLabel="ESTIMATED at 15 studs/s; no character walk",maxSlope=maxSlope,
        routeSegments=ramps,mainRoute=points,studioCapture="BLOCKED: Computer Use not approved for Roblox Studio",runtime="NOT RUN"}
    print(letter..": "..parts.." parts; max ramp "..string.format("%.2f",maxSlope).." deg; route "..string.format("%.1f",length).." studs")
end
fs.writeFile("treasure/map-v3/ingame/build-evidence.json",serde.encode("json",reports,true))
