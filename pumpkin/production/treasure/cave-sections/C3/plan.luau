return function(round)
 local a={}
 local function add(name,c,s,col,mat,kit,shape,yaw)
  local g={name='C3_'..name,c=c,s=s,color=col or {64,76,98},material=mat or 'Slate',kit=kit or nil,shape=shape,yaw=yaw};table.insert(a,g);return g
 end
 -- R1: supported large forms only; preserved verbatim in later rounds.
 add('LeftShoulder',{68,32.06,-77},{8,16,8},nil,nil,true,'Wedge')
 add('RightShoulder',{110,39.06,-47},{8,14,8},{68,79,99},nil,true,'Wedge')
 add('CourtShoulder',{128,48.06,-59},{8,16,8},{57,70,92},nil,true,'Wedge')
 add('UpperShoulder',{92,56.06,-95},{8,16,8},{62,72,94},nil,true,'Wedge')
 local wood={113,75,45}
 add('StationPlatform',{140,48.46,-71},{8,.8,8},wood,'Wood')
 for _,x in {137,143}do add('StationPost'..x,{x,57.46,-68},{1.4,17.2,1.4},wood,'Wood')end
 add('StationHeader',{140,66.76,-68},{9,1.4,2},wood,'Wood')
 if round~='r1'then
  local sign=add('RideBoard',{140,63.3,-68},{8,4.6,1},{91,55,33},'Wood');sign.text='RIDE'
  for i=0,7 do add('DockPlank'..i,{136.5+i,48.94,-71},{.92,.1,7.8},{135+i%2*12,89+i%2*8,49},'Wood')end
  for _,x in {137,143}do
   add('LampPost'..x,{x,53.2,-72},{.7,8.4,.7},wood,'Wood')
   local lamp=add('LampGlow'..x,{x,58.1,-72},{1.6,2.2,1.6},{255,172,65},'Neon');lamp.light=true
   for _,y in {56.9,59.3}do add('LampCap'..x..y,{x,y,-72},{2,.3,2},{38,44,58},'Metal')end
  end
  for i=0,4 do add('OrePile'..i,{139+(i%3)*1.3,49.7+math.floor(i/3)*.6,-70+i%2},{1.8,1.5,1.8},{75+i*5,86+i*4,107+i*3},'Slate',nil,'Wedge',i*30)end
  for group,g in {{68,40.08,-77},{110,46.08,-47}}do
   for i=1,3 do
    local x,y,z=g[1]+(i-2)*1.8,g[2],g[3]+(i%2)*.8;local h=({5,9,6})[i]
    local col=group==1 and {63,192,224}or{145,82,217}
    add('Flash'..group..'Shaft'..i,{x,y+h*.4,z},{1.5,h*.8,1.5},col,'Neon')
    add('Flash'..group..'Tip'..i,{x,y+h*.9,z},{1.5,h*.2,1.5},col,'Neon',nil,'Wedge')
   end
  end
 end
 if round=='r3'or round=='r4'then
  for _,g in a do
   if g.name=='C3_RideBoard'then g.c[2]=55.8 end
   if g.name:match('^C3_Flash2')then g.c[1]-=18;g.c[2]-=10;g.c[3]+=12 end
  end
  add('MidShoulder',{92,30.06,-35},{8,12,8},{66,77,97},nil,true,'Wedge')
 end
 if round=='r4'then
  for _,g in a do
   if g.name=='C3_RideBoard'then g.c={134,55.8,-74};g.yaw=-45 end
   if g.name=='C3_MidShoulder'then g.c[1]=80;g.s={5,12,3.5}end
   if g.name:match('^C3_Flash2')then g.c[1]-=12 end
  end
  add('SignArm',{135.5,58.5,-71},{.8,.8,6.71},wood,'Wood',nil,nil,26.565)
  for _,g in table.clone(a)do
   if g.name:match('^C3_Flash')and g.name:find('Tip')then
    local x,y,z=g.c[1],g.c[2],g.c[3];local h=g.s[2]/.2
    g.s={1.5,h*.4,.75};g.c={x,y+h*.1,z-.375}
    for j=1,3 do local t=j*math.pi/2
     add(g.name:sub(4)..'Facet'..j,{x-math.sin(t)*.375,y+h*.1,z-math.cos(t)*.375},{1.5,h*.4,.75},g.color,'Neon',nil,'Wedge',j*90)
    end
   elseif g.name:match('^C3_Flash')and g.name:find('Shaft')then
    local col={math.floor(g.color[1]*.4),math.floor(g.color[2]*.5),math.floor(g.color[3]*.65)}
    add(g.name:sub(4)..'Inset',{g.c[1],g.c[2],g.c[3]-.76},{1.35,g.s[2]*.94,.03},col,'SmoothPlastic')
   end
  end
 end
 return a
end
