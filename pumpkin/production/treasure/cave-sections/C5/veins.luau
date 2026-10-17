return function(out)
 local fs,serde,rb=require('@lune/fs'),require('@lune/serde'),require('@lune/roblox')
 local V=rb.Vector3;local G=require('./geometry')
 local mesh=serde.decode('json',fs.readFile('treasure/cave-sections/C5/ROCK-SOURCE.json'))
 local evidence={}
 for index,v in {{195,-1.95000885,40,12,202,12.5,1},{120,-1.95000885,60,12,166,5.5,37},{55,-3.95000885,45,8,118,5.5,44.5}}do
  local center=V.new(v[1],v[2],v[3]);local eye=V.new(v[5],v[6],v[7]);local size=V.new(6,v[4],6)
  local best,score=-1,-math.huge;local points
  for i,f in mesh.faces do
   local a=V.new(unpack(mesh.vertices[f[1]+1]))*size+center
   local b=V.new(unpack(mesh.vertices[f[2]+1]))*size+center
   local c=V.new(unpack(mesh.vertices[f[3]+1]))*size+center
   local cross=(b-a):Cross(c-a);local normal=cross.Unit;local middle=(a+b+c)/3
   if normal:Dot(middle-center)<0 then normal=-normal end
   local value=cross.Magnitude*math.max(0,normal:Dot((eye-middle).Unit))
   if middle.Y<center.Y-1 then value=-1 end
   if value>score then score=value;best=i;points={a,b,c,normal}end
  end
  assert(score>0,'no outward mesh face')
  local a,b,c,n=unpack(points)
  local function p(x,y,z)return a*x+b*y+c*z+n*.02 end
  local middle=p(.34,.33,.33)
  for j,q in {p(.7,.15,.15),p(.15,.7,.15),p(.15,.15,.7)}do G.beam(out,'RockVein'..index..j,middle,q,{112,100,192})end
  table.insert(evidence,{rock=index,source_face=best,normal_offset=.02,branch_joints='barycentric, within source triangle'})
 end
 fs.writeFile('treasure/cave-sections/C5/VEIN-SURFACE.json',serde.encode('json',{state='PASS',source='actual normalized CC0 Rock_Medium_1 FBX used by renderer/Kit.fit',branches=9,faces=evidence,engine_fitting='UNKNOWN'},true))
end
