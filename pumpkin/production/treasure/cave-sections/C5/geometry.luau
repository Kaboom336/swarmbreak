-- Native triangular face construction; no uploaded mesh or external dependency.
local rb=require('@lune/roblox');local V=rb.Vector3
local G={}
local function item(name,center,size,right,up,back,color)
 return {name='C5_'..name,c={center.X,center.Y,center.Z},s={size.X,size.Y,size.Z},r={right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z},color=color,material='Neon',shape='Wedge'}
end
function G.triangle(out,name,a,b,c,color)
 local ab,ac,bc=b-a,c-a,c-b
 if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then a,c=c,a
 elseif ac.Magnitude>bc.Magnitude then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit;local back=bc.Unit;local up=back:Cross(right).Unit
 local h=math.abs(ab:Dot(up))
 table.insert(out,item(name..'A',(a+b)/2,V.new(.045,h,math.abs(ab:Dot(back))),right,up,back,color))
 table.insert(out,item(name..'B',(a+c)/2,V.new(.045,h,math.abs(ac:Dot(back))),-right,up,-back,color))
end
function G.beam(out,name,a,b,color)
 local back=(a-b).Unit;local seed=math.abs(back.Y)>.98 and V.xAxis or V.yAxis
 local right=seed:Cross(back).Unit;local up=back:Cross(right).Unit
 local q=item(name,(a+b)/2,V.new(.12,.12,(b-a).Magnitude),right,up,back,color);q.shape=nil;table.insert(out,q)
end
return G
