local fs,luau=require('@lune/fs'),require('@lune/luau')
local src=fs.readFile('prototype/fix2-check.luau')
src=src:gsub('script=node,require=load,Vector3=V,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance',
 [[script=node,require=load,Vector3=V,Vector2=rb.Vector2,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,warn=warn,
 game={GetService=function(_,name) if name=='ReplicatedStorage' then return place.ReplicatedStorage elseif name=='RunService' then return {} end;assert(name=='HttpService');return {JSONDecode=function(_,s)return serde.decode('json',s)end} end}]])
src=src:gsub('prototype/FIX2%-CLEARANCE.json','treasure/sections/S2/r4-CLEARANCE.json')
local env=table.clone(getfenv());local nativeRequire=require;env.require=function(p)return nativeRequire(p)end
luau.load(src,{environment=env,injectGlobals=true})()
