-- Art-only additions. All inherited collision volumes and gameplay data stay intact.
return function(e)
 local part,box,slab,frame,xyz,nearest,crystal,glow=e.part,e.box,e.slab,e.frame,e.xyz,e.nearest,e.crystal,e.glow
 local V,C,rock,wood,cyan,violet=e.V,e.C,e.rock,e.wood,e.cyan,e.violet
 local tops={};local cells={}
 for _,p in e.parts do if p.name=='StackedMesaRock' then
  local x,z=p.position[1],-p.position[3];local key=x..':'..z;local y=p.position[2]+p.size[2]/2
  if not tops[key] or y>tops[key].y then tops[key]={x=x,z=z,y=y};end
 end end
 for _,q in tops do table.insert(cells,q) end
 table.sort(cells,function(a,b)return a.x==b.x and a.z<b.z or a.x<b.x end)
 local function safe(x,z,margin)
  for _,pts in e.routes do if nearest(x,z,pts)<margin then return false end end
  return true
 end
 local groups=0
 local function cluster(x,z,y,s,down,seed,count)
  groups+=1
  for i=1,count or 5 do
   local angle=i*2.399+seed*.73;local radius=2+(i%3)*2.2
   crystal(x+math.cos(angle)*radius,z+math.sin(angle)*radius,y,s*({.45,.72,1,.59,.38,.8,.51})[i],(i+seed)%3==0 and cyan or violet,down,(i-3)*.07,i==3)
  end
 end
 -- Every exterior and stepped cliff face gets an irregular vein, with exposed
 -- ledges selected from the existing terrain. No terrain heights are changed.
 local edgeIndex=0
 for _,q in cells do
  local edge=false
  for _,d in {{10,0},{-10,0},{0,10},{0,-10}} do local n=tops[(q.x+d[1])..':'..(q.z+d[2])];if not n or q.y-n.y>12 then edge=true end end
  if edge then
   edgeIndex+=1
   if edgeIndex%3==1 and safe(q.x,q.z,24) then cluster(q.x,q.z,q.y-2,12+(edgeIndex%5)*3,false,edgeIndex,3+edgeIndex%5) end
   if edgeIndex%2==0 then
    local angle=math.atan2(q.z,q.x);local ox,oz=math.cos(angle)*4,math.sin(angle)*4
    box('CliffSteppedLedge','rock-detail',{q.x+ox,q.z+oz,q.y-8-(edgeIndex%4)*7},{7+(edgeIndex%3)*2,7,5},rock[2+edgeIndex%3],false)
    box('CliffInsetBlock','rock-detail',{q.x+ox*.6,q.z+oz*.6,q.y-23-(edgeIndex%3)*8},{5,6,8},rock[1+edgeIndex%3],false)
   end
   -- Shallow voxel skin refines existing exposed cliff faces without replacing
   -- or moving any terrain collider. Each bay is inset/offset independently.
   for _,d in {{-10,0},{0,-10},{10,0},{0,10}} do
    local n=tops[(q.x+d[1])..':'..(q.z+d[2])];local drop=n and q.y-n.y or 32
    if drop>12 then for level=1,math.min(7,math.floor(drop/4)) do for col=-1,1 do
     local dx,dz=d[1]*.49,d[2]*.49
     if d[1]==0 then dx=col*3.3 else dz=col*3.3 end
     box('R3CliffVoxelSkin','rock-detail',{q.x+dx,q.z+dz,q.y-level*4+1.5},{d[1]==0 and 3.1 or 1.1,d[2]==0 and 3.1 or 1.1,3.7},rock[1+(edgeIndex+level+col+3)%3],false)
    end end end
   end
  end
  if safe(q.x,q.z,24) and (q.x+q.z)%30==0 then
   for dx=-2.5,2.5,5 do for dz=-2.5,2.5,5 do box('R3RockTopChips','rock-detail',{q.x+dx,q.z+dz,q.y+.12},{4.8,4.8,.4},rock[3+(math.abs(q.x+q.z+dx)>90 and 1 or 0)],false) end end
  end
 end
 -- Mixed hanging veins across the underside, rather than only at lobe tips.
 for ring=1,3 do for i=1,22 do
  local a=i/22*math.pi*2+ring*.16;local r=({204,145,81})[ring]
  cluster(math.cos(a)*r+math.sin(i)*4,math.sin(a)*r*.76,-({53,93,138})[ring]-(i%4)*8,20+(i%5)*5,true,i+ring*23,4+i%4)
 end end
 -- Path shoulders are sampled on every segment; use the exact terrain top so
 -- crystals emerge from ledges instead of floating above lower route crossings.
 for name,pts in e.routes do if name~='cartRail' then
  for k=1,#pts-1 do
   local aa,bb=xyz(pts[k]),xyz(pts[k+1]);local len=(bb-aa).Magnitude
   for j=1,math.max(1,math.floor(len/30)) do
    local cf=frame(aa:Lerp(bb,j/(math.floor(len/30)+1)),bb)
    local side=(j+k)%2==0 and 1 or -1;local p=(cf*C.new(side*25,0,0)).Position
    local x,z=math.floor(p.X/10+.5)*10,math.floor(-p.Z/10+.5)*10;local q=tops[x..':'..z]
    if q and safe(x,z,23) then cluster(x,z,q.y-2,10+(k%3)*3,false,j+k,5) end
   end
  end
 end end
 for _,a in {{190,-25,0},{-20,-70,0},{80,-35,0}} do
  for side=-1,1,2 do cluster(a[1]+side*19,a[2]-7,0,19,false,side+4,7) end
  cluster(a[1],a[2]-3,33,10,true,7,5)
 end
 for i=1,5 do local a=i*1.25;cluster(163+math.cos(a)*24,153+math.sin(a)*24,48,15,false,i,5) end
 local function lantern(x,z,y)
  box('R3LanternPost','prop',{x,z,y+4},{1.3,1.3,9},wood,false,'Wood')
  local p=box('R3LanternAmber','light',{x,z,y+9},{3,3,4},{255,164,53},false,'Neon');glow(p,5,32)
  for h=7,11,4 do box('R3LanternCap','prop',{x,z,y+h},{4,4,.7},{48,40,54},false,'Metal') end
 end
 for name,pts in e.routes do if name~='cartRail' then
  for k=2,#pts-1 do
   local cf=frame(xyz(pts[k]),xyz(pts[k+1]))
   for side=-1,1,2 do local p=(cf*C.new(side*12,0,0)).Position;lantern(p.X,-p.Z,p.Y) end
  end
 end end
 -- Visible scaffold bays on cliff faces, with diagonal ties and boarded decks.
 for i,a in {{-211,-85,-12},{-172,-137,-12},{-100,-160,-12},{-181,47,15},{-159,107,39},{83,149,31},{207,12,-12},{203,-83,-12},{132,-120,-12}} do
  for bay=-1,1 do local x=a[1]+bay*14
   for off=-6,6,12 do box('R3ScaffoldUpright','prop',{x+off,a[2],a[3]+8},{1.8,2,28},wood,false,'Wood') end
   for h=-4,18,11 do box('R3ScaffoldCrossBeam','prop',{x,a[2],a[3]+h},{15,2,1.8},wood,false,'Wood') end
   slab('R3ScaffoldXBrace','prop',{x-6,a[2]-1,a[3]-4},{x+6,a[2]-1,a[3]+18},1.2,1.2,wood,false,'Wood')
   for j=-2,2 do box('R3ScaffoldDeckPlank','prop',{x,a[2]+j*1.8,a[3]+18},{15,1.6,.7},{174,117,65},false,'Wood') end
  end
  lantern(a[1],a[2]-4,a[3]+18)
 end
 for _,a in {{-172,-103,0},{-181,51,24},{98,145,24},{180,137,48},{190,-8,0},{-87,-84,0},{-151,-138,0}} do
  for i=0,2 do
   box('R3SupplyCrate','prop',{a[1]+i*6,a[2],a[3]+3},{5.5,5.5,6},wood,false,'Wood')
   for off=-2,2,4 do box('R3CrateBinding','prop',{a[1]+i*6+off,a[2]-2.9,a[3]+3},{.7,.4,6.2},{184,131,76},false,'Wood') end
   box('R3TNTStack','prop',{a[1]+i*1.7,a[2]-7,a[3]+1.5},{1.5,5,3},{198,57,65},false,'Wood')
  end
 end
 for _,a in {{-166,-133,0},{-134,-133,0},{139,143,48},{191,138,48}} do
  box('R3BannerPole','prop',{a[1],a[2],a[3]+12},{1.5,1.5,25},wood,false,'Wood')
  box('R3MiningBanner','prop',{a[1]+5,a[2],a[3]+16},{9,.6,13},violet,false,'Fabric')
  box('R3BannerGem','prop',{a[1]+5,a[2]-.5,a[3]+16},{3,.5,5},cyan,false,'Neon','Wedge')
 end
 -- Two readable work yards on near shelves: loaded carts, timber gantries,
 -- stacked crates and ore piles. Keep the eighteen-stud route corridor open.
 for index,a in {{-174,-80,0},{-151,61,24},{105,143,24},{175,-83,0}} do
  box('R3OreCartFloor','prop',{a[1],a[2],a[3]+2},{9,12,2},{61,69,86},false,'Metal')
  for side=-1,1,2 do
   box('R3OreCartSide','prop',{a[1]+side*4,a[2],a[3]+5},{1,12,6},{112,115,139},false,'Metal')
   box('R3OreCartEnd','prop',{a[1],a[2]+side*5.5,a[3]+5},{8,1,6},{88,92,112},false,'Metal')
   for dz=-4,4,8 do box('R3OreCartWheel','prop',{a[1]+side*5,a[2]+dz,a[3]+1.5},{2,3,3},{37,35,45},false,'Metal','Ball') end
  end
  cluster(a[1],a[2],a[3]+4,6,false,index,5)
  for side=-1,1,2 do box('R3YardGantryPost','prop',{a[1]+side*13,a[2]+9,a[3]+11},{2,3,22},wood,false,'Wood') end
  box('R3YardGantryHeader','prop',{a[1],a[2]+9,a[3]+22},{29,4,3},{165,107,64},false,'Wood')
  for i=0,2 do
   box('R3YardCrate','prop',{a[1]+14+i%2*6,a[2]-4,a[3]+3+math.floor(i/2)*6},{5.8,5.8,6},wood,false,'Wood')
   for off=-2,2,4 do box('R3YardCrateBand','prop',{a[1]+14+i%2*6+off,a[2]-7,a[3]+3+math.floor(i/2)*6},{.7,.4,6.2},{184,131,76},false,'Wood') end
  end
  lantern(a[1]-13,a[2]-6,a[3]);lantern(a[1]+13,a[2]-6,a[3])
 end
 -- Small distant islands and sagging lantern rope bridges. Noncollidable art.
 local islands={{-325,240,-22},{-215,314,7},{-65,331,-11},{302,225,-27},{500,120,160},{530,330,200},{360,530,250},{40,680,285},{-250,620,245},{-450,440,160}}
 for i,a in islands do
  for k=0,4 do local r=29-k*4.5;box('R3DistantIsland','background',{a[1]+k,a[2],a[3]-k*12},{r*2,r*1.5,15},rock[1+k%3],false) end
  cluster(a[1],a[2],a[3]+7,21,false,i,7);cluster(a[1]+3,a[2],a[3]-53,22,true,i,5)
  lantern(a[1]-15,a[2]-5,a[3]+7);lantern(a[1]+15,a[2]-5,a[3]+7)
  if i<3 or i==5 or i==7 or i==8 then
   local b=islands[i+1];local last
   for j=0,20 do local t=j/20;local q={a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t+7-14*4*t*(1-t)}
    if last then
     slab('R3RopeBridgePlank','background',last,q,7,.5,{170,116,67},false,'Wood')
     for side=-1,1,2 do slab('R3RopeBridgeCable','background',{last[1]+side*4,last[2],last[3]+5},{q[1]+side*4,q[2],q[3]+5},.35,.35,{184,144,94},false,'Wood') end
    end
    if j%4==0 then lantern(q[1],q[2],q[3]) end
    last=q
   end
  end
 end
 print('Round3 mixed crystal groups: '..groups)
end
