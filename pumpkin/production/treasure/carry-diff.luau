local fs,s=require('@lune/fs'),require('@lune/serde')
local function read(n)return s.decode('json',fs.readFile('treasure/carry-'..n..'.json'))end
local function sig(p,material)
 local attrs={};for k,v in p.attributes do table.insert(attrs,{k,v}) end;table.sort(attrs,function(x,y)return x[1]<y[1] end)
 table.sort(p.tags)
 return s.encode('json',{p.name,p.cf,p.size,p.collide,p.query,p.touch,if material then p.material else nil,attrs,p.tags})
end
local a,b=read('before'),read('current')
for _,material in {false,true} do
 local bag={};for _,p in a do if p.collide or p.query then local k=sig(p,material);bag[k]=(bag[k] or 0)+1 end end
 local add,del={},{}
 for _,p in b do if p.collide or p.query then local k=sig(p,material);if (bag[k] or 0)>0 then bag[k]-=1 else table.insert(add,p) end end end
 for k,v in bag do for i=1,v do table.insert(del,s.decode('json',k)) end end
 print('physical diff material='..tostring(material),'added',#add,'removed',#del)
 fs.writeFile('treasure/carry-physical-'..tostring(material)..'.json',s.encode('json',{added=add,removed=del},true))
 if #add<100 then print(s.encode('json',add)) end
end
