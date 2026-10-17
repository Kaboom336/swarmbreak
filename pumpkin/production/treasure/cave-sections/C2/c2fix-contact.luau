-- Same conservative OBB SAT and .035 tolerance as contact.py, using Lune.
local fs,rb,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local H='treasure/cave-sections/C2/'
local data=serde.decode('json',fs.readFile(H..'c2fix.json'))
local V=rb.Vector3
local old,new={},{}
for _,p in data.parts do
 local r=p.rotation
 p.center=V.new(unpack(p.position));p.half=V.new(unpack(p.size))/2
 p.axes={V.new(r[1],r[4],r[7]),V.new(r[2],r[5],r[8]),V.new(r[3],r[6],r[9])}
 local function extent(axis)return math.abs(axis.X)*p.half.X+math.abs(axis.Y)*p.half.Y+math.abs(axis.Z)*p.half.Z end
 p.extent=V.new(extent(V.new(r[1],r[2],r[3])),extent(V.new(r[4],r[5],r[6])),extent(V.new(r[7],r[8],r[9])))
 if p.collidable then table.insert(old,p)elseif p.name:match('^C2_')then table.insert(new,p)end
end
local function radius(p,axis)
 return math.abs(p.axes[1]:Dot(axis))*p.half.X+math.abs(p.axes[2]:Dot(axis))*p.half.Y+math.abs(p.axes[3]:Dot(axis))*p.half.Z
end
local function penetration(a,b,delta)
 local function separated(axis)
  local norm=axis.Magnitude
  if norm<1e-7 then return false end
  axis=axis/norm
  return math.abs(delta:Dot(axis))>=radius(a,axis)+radius(b,axis)-.035
 end
 for _,axis in a.axes do if separated(axis)then return false end end
 for _,axis in b.axes do if separated(axis)then return false end end
 for _,x in a.axes do for _,y in b.axes do if separated(x:Cross(y))then return false end end end
 return true
end
local errors={}
for _,a in new do
 for _,b in old do
  local delta=b.center-a.center;local ext=a.extent+b.extent
  if math.abs(delta.X)>ext.X-.035 or math.abs(delta.Y)>ext.Y-.035 or math.abs(delta.Z)>ext.Z-.035 then continue end
  if penetration(a,b,delta)then table.insert(errors,{new=a.name,old=b.name,at=b.position})end
 end
 require('@lune/task').wait()
end
local report={state=#errors==0 and'PASS'or'FAIL',tolerance=.035,cosmetic_envelopes=#new,protected_solids=#old,contact=#errors,errors=errors,
 place_sha256=serde.hash('sha256',fs.readFile('prototype/cave-v2.rbxl')),method='contact.py conservative OBB SAT translated to Lune; same .035 tolerance'}
fs.writeFile(H..'CONTACT-c2fix.json',serde.encode('json',report,true))
print('C2 fix contact',#errors,'cosmetics',#new,'protected solids',#old)
assert(#errors==0,'cosmetic contact with protected solids')
