return function(round)
 local a={
  {name='C2_RearLeft',c={150,58.03,-162},s={10,20,10},color={58,70,91},kit=true,shape='Wedge'},
  {name='C2_RearRight',c={170,55.03,-164},s={10,14,10},color={71,80,103},kit=true,shape='Wedge'},
  {name='C2_EastFrame',c={220,58.03,-138},s={10,20,10},color={60,75,96},kit=true,shape='Wedge'},
 }
 if round~='r1'then
  table.insert(a,{name='C2_EastShoulder',c={220,61.03,-150},s={10,26,10},color={67,79,102},kit=true,shape='Wedge'})
 end
 if round=='r3'or round=='r4'then
  for i,g in {
   {140,57.03,-152,8,18,10},{190,93.03,-154,8,26,8},
   {190,89.03,-142,8,18,8},
  }do
   table.insert(a,{name='C2_CampRock'..i,c={g[1],g[2],g[3]},s={g[4],g[5],g[6]},color={61+i*4,70+i*4,91+i*4},kit=true,shape='Wedge',yaw=i%2==0 and 12 or -9})
  end
 end
 return a
end
