return function(round)
 local a={}
 local function add(name,c,s,col,mat,kit,shape,yaw)
  local g={name='C5_'..name,c=c,s=s,color=col or {61,72,94},material=mat or 'Slate',kit=kit or nil,shape=shape,yaw=yaw};table.insert(a,g);return g
 end
 -- R1 silhouette only. Native-supported full envelopes; actual CC0 rocks.
 for i,v in {{195,-7.95000885,40},{175,-7.95000885,50},{155,-7.95000885,25},{135,.04999878,20},{120,-7.95000885,60},{100,-2.04999207,20},{75,-7.95000885,20}}do
  add('Shoulder'..i,{v[1],v[2]+6,v[3]},{6,12,6},({{58,68,89},{68,76,100},{77,79,109}})[1+(i%3)],'Slate',true,'Wedge')
 end
 if round~='r1'then
  for group,v in {{195,-7.95000885,40},{155,-7.95000885,25},{100,-2.04999207,20}}do
   for i,h in {14,22,17}do
    local x,z=v[1]+(i-2)*1.75,v[3]+(i%2)*.5
    local col=group==3 and {129,76,202}or{49,163,192}
    local base=v[2]+1.5
    add('Crystal'..group..'Shaft'..i,{x,base+h*.35,z},{1.55,h*.7,1.55},col,'SmoothPlastic')
    for j=0,3 do local t=j*math.pi/2
     add('Crystal'..group..'Tip'..i..'F'..j,{x-math.sin(t)*.3875,base+h*.85,z-math.cos(t)*.3875},{1.55,h*.3,.775},col,'Neon',nil,'Wedge',j*90)
    end
   end
  end
  for i,v in {{175,-7.95000885,50},{120,-7.95000885,60},{75,-7.95000885,20}}do
   add('LampFoot'..i,{v[1],v[2]+5,v[3]},{.65,10,.65},{91,64,43},'Wood')
   local g=add('LampGlow'..i,{v[1],v[2]+10.7,v[3]},{1.25,1.4,1.25},{255,169,72},'Neon');g.light=true
   for j,h in {9.9,11.5}do add('LampCap'..i..j,{v[1],v[2]+h,v[3]},{1.7,.2,1.7},{37,43,56},'Metal')end
  end
  -- Attached to new rock envelopes; never draw across the playable floor.
  for i,v in {{195,-7.95000885,40},{155,-7.95000885,25},{100,-2.04999207,20}}do
   for j=1,3 do
    add('Vein'..i..j,{v[1]+(j%2)*.45,v[2]+3+j*2.1,v[3]-1.1},{.12,2.2,.12},{98,95,184},'Neon')
   end
  end
 end
 if round=='r3'or round=='r4'then
  -- R2 gap 1: camera-visible side positions, native bearing retained.
  for _,g in a do
   if g.name:match('^C5_Crystal2')then g.c[1]-=35;g.c[3]+=35 end
   if g.name:match('^C5_Crystal3')then g.c[1]-=45;g.c[2]-=5.90001678;g.c[3]+=25 end
   if g.name:match('^C5_Vein2')then g.c[1]-=35;g.c[3]+=35 end
   if g.name:find('Lamp')then
    local index=tonumber(g.name:match('Lamp%a+(%d)'))
    if index==3 then g.c[1]-=20;g.c[3]+=25 end
    if g.name:find('Foot')then g.s[2]+=6;g.c[2]+=3 else g.c[2]+=6 end
   end
  end
  add('ChamberRock',{55,-3.95000885,45},{6,8,6},{66,70,96},'Slate',true,'Wedge')
  -- R2 gap 2: smaller broad caps + needle pair from existing crystal recipe.
  for _,g in table.clone(a)do
   if g.name:find('Tip')then g.c[2]-=g.s[2]*.2;g.s[2]*=.6 end
   local group,index=g.name:match('Crystal(%d)Shaft(%d)')
   if group then
    local h=g.s[2]/.7;local base=g.c[2]-h*.35
    for j=0,1 do
     add('Crystal'..group..'Needle'..index..j,{g.c[1],base+h*.94,g.c[3]+(j==0 and -.1125 or .1125)},{.45,h*.12,.225},g.color,'Neon',nil,'Wedge',j*180)
    end
   end
  end
 end
 if round=='r4'then
  local rb=require('@lune/roblox');local V=rb.Vector3;local G=require('./geometry')
  local keep={}
  for _,g in a do if not(g.name:find('Tip')or g.name:find('Needle')or g.name:find('Vein'))then table.insert(keep,g)end end
  a=keep
  for _,g in table.clone(a)do
   local group,index=g.name:match('Crystal(%d)Shaft(%d)')
   if group then
    local h=g.s[2]/.7;local base=g.c[2]-h*.35;local x,z=g.c[1],g.c[3]
    local ring={V.new(x-.775,base+h*.7,z-.775),V.new(x+.775,base+h*.7,z-.775),V.new(x+.775,base+h*.7,z+.775),V.new(x-.775,base+h*.7,z+.775)}
    for j=1,4 do G.triangle(a,'Crystal'..group..'Facet'..index..j,V.new(x,base+h,z),ring[j],ring[j%4+1],g.color)end
   end
   if g.name:match('^C5_Lamp%a+3')then g.c[1]+=2;g.c[3]+=1.6 end
  end
  require('./veins')(a)
 end
 return a
end
