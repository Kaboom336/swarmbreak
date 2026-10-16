-- Run the existing N8 production DropSample offline lattice with the complete
-- dressing environment (the older harness predates UIStyle and Section2).
local fs,luau=require('@lune/fs'),require('@lune/luau')
local src=fs.readFile('prototype/fix6-check.luau')
src=src:gsub('script=node,require=load,Vector3=V,CFrame=C,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance',
 [[script=node,require=load,Vector3=V,Vector2=rb.Vector2,CFrame=C,Color3=rb.Color3,Enum=rb.Enum,Instance=rb.Instance,UDim2=rb.UDim2,NumberSequence=rb.NumberSequence,ColorSequence=rb.ColorSequence,warn=warn,
 game={GetService=function(_,name) if name=='ReplicatedStorage' then return place.ReplicatedStorage elseif name=='RunService' then return {} end;assert(name=='HttpService');return {JSONDecode=function(_,s)return serde.decode('json',s)end} end}]])
src=src:gsub('prototype/FIX6%-DROPS.json','treasure/sections/S5/final-DROPS.json')
local worker=tonumber(require('@lune/process').args[1])
if worker then
 assert(worker>=1 and worker<=3 and worker%1==0)
 src=src:gsub('for name,route in R do', 'local allRouteNames,shardRoutes={},{};for name in R do table.insert(allRouteNames,name) end\nfor name,route in R do\n local partition=0;for i=1,#name do partition+=string.byte(name,i) end\n if partition%%3+1~='..worker..' then continue end\n table.insert(shardRoutes,name)')
 src=src:gsub('local report={state=', 'local report={worker='..worker..',allRouteNames=allRouteNames,shardRoutes=shardRoutes,state=')
 src=src:gsub('final%-DROPS.json','final-DROPS-'..worker..'.json')
end
-- Each worker records the exact immutable canonical input it actually tested.
src=src:gsub('local report={', "local report={input_sha256=serde.hash('sha256',fs.readFile('slice-v2/prototype/guardian-greybox.rbxl')),")
local env=table.clone(getfenv());local nativeRequire=require;env.require=function(p) if p=='./meadow-v4/OfflineRay' then return nativeRequire('../../../prototype/meadow-v4/OfflineRay') end;return nativeRequire(p)end
luau.load(src,{environment=env,injectGlobals=true})()
