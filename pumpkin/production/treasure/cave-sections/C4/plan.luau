return function(round)
 local a={}
 local function add(name,c,s,col,mat,kit,shape,yaw)
  local g={name='C4_'..name,c=c,s=s,color=col or {61,70,91},material=mat or 'Slate',kit=kit or nil,shape=shape,yaw=yaw};table.insert(a,g);return g
 end
 -- R1: full-footprint supported masses from measured POCKETS; frozen later.
 add('PitShoulder',{-40,-2.95,20},{8,32,8},nil,nil,true,'Wedge')
 add('LandingShoulder',{-50,27.19139,40},{8,32,8},{67,76,96},nil,true,'Wedge')
 add('FarBackdrop',{5,45.02,60},{8,24,8},{58,67,88},nil,true,'Wedge')
 add('RecoveryShoulder',{-80,24.049995,10},{8,16,8},{66,75,94},nil,true,'Wedge')
 add('LaunchShoulder',{50,31.049995,5},{8,30,8},{61,72,94},nil,true,'Wedge')
 if round~='r1'then
  for group,v in {{-50,43.21139,40},{5,57.04,60}}do
   for i=1,3 do
    local h=({4,7,5})[i];local x,z=v[1]+(i-2)*1.8,v[3]+(i%2)*.7
    local col=group==1 and {59,187,220}or{135,80,206}
    add('Flash'..group..'Shaft'..i,{x,v[2]+h*.35,z},{1.3,h*.7,1.3},col,'Neon')
    add('Flash'..group..'Tip'..i,{x,v[2]+h*.85,z},{1.3,h*.3,1.3},col,'Neon',nil,'Wedge')
   end
  end
  for i,v in {{-40,13.11,20},{-80,32.109995,10}}do
   add('RecoveryLampFoot'..i,{v[1],v[2]+1.2,v[3]},{.8,2.4,.8},{108,71,43},'Wood')
   local g=add('RecoveryLampGlow'..i,{v[1],v[2]+3.25,v[3]},{1.4,1.6,1.4},{255,168,64},'Neon');g.light=true
   for _,dy in {2.35,4.15}do add('RecoveryLampCap'..i..dy,{v[1],v[2]+dy,v[3]},{1.9,.2,1.9},{35,42,56},'Metal')end
  end
 end
 if round=='r3'or round=='r4'then
  for _,g in a do
   if g.name:match('^C4_Flash1')then g.c[2]-=6;g.c[3]-=3 end
   if g.name:match('^C4_Flash2')then g.c[2]-=11;g.c[3]-=2 end
   if g.name:find('RecoveryLamp')then
    if g.name:match('RecoveryLamp%a+(%d)')=='1'then g.c[2]-=32.06;g.c[3]+=5
    else g.c[1]+=5;g.c[2]-=16.06 end
   end
  end
 end
 if round=='r4'then
  for _,g in a do if g.name:match('^C4_Flash2')then g.c[2]-=5 end end
  for _,g in table.clone(a)do
   if g.name:match('^C4_Flash')and g.name:find('Tip')then
    local x,y,z=g.c[1],g.c[2],g.c[3];local h=g.s[2]
    g.s={1.3,h,.65};g.c[3]=z-.325
    for j=1,3 do local t=j*math.pi/2
     add(g.name:sub(4)..'Facet'..j,{x-math.sin(t)*.325,y,z-math.cos(t)*.325},{1.3,h,.65},g.color,'Neon',nil,'Wedge',j*90)
    end
   end
  end
 end
 return a
end
