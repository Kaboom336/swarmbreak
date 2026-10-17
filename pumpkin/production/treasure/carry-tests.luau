-- Reuse existing offline assertions unchanged; isolate this investigation's outputs.
local fs,luau,process=require('@lune/fs'),require('@lune/luau'),require('@lune/process')
local mode=process.args[1]
local source
if mode=='contracts' then
 source=fs.readFile('treasure/sections/S2/contracts.luau')
 source=source:gsub('treasure/sections/S2/CONTRACTS.json','treasure/carry-evidence/CONTRACTS.json')
 source=source:gsub("q:GetAttribute%('Section'%)=='S2'", "(q:GetAttribute('Section')=='S2' or q:GetAttribute('Section')=='S3' or q:GetAttribute('Section')=='S4')")
elseif mode=='drop' then
 source=fs.readFile('treasure/sections/S4/drop.luau')
 source=source:gsub('treasure/sections/S4/','treasure/carry-evidence/')
else source=fs.readFile('prototype/s2r4-behavior.luau') end
local env=table.clone(getfenv());local nativeRequire=require
env.require=function(p)
 if p=='@lune/process' and mode=='drop' then return {args={process.args[2]}} end
 if p:sub(1,12)=='./meadow-v4/' then return nativeRequire('../prototype/'..p:sub(3)) end
 if p:sub(1,7)=='./core/' then return nativeRequire('../prototype/'..p:sub(3)) end
 if p=='../../../prototype/meadow-v4/OfflineRay' then return nativeRequire('../prototype/meadow-v4/OfflineRay') end
 return nativeRequire(p)
end
fs.writeDir('treasure/carry-evidence')
luau.load(source,{environment=env,injectGlobals=true})()
