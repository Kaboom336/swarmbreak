-- Reuse existing contracts/lattice without changing assertions or tolerances.
local fs,luau,process=require('@lune/fs'),require('@lune/luau'),require('@lune/process')
local mode=process.args[1]
local path=if mode=='drop' then 'prototype/s2r4-drop.luau' elseif mode=='contracts' then 'treasure/sections/S4/contracts.luau' else 'prototype/s2r4-behavior.luau'
local source=fs.readFile(path)
if mode=='drop' then source=source:gsub('treasure/sections/S2/','prototype/yield-evidence/'):gsub('r4','final') end
if mode=='contracts' then
 source=fs.readFile('treasure/sections/S2/contracts.luau')
 source=source:gsub('treasure/sections/S2/CONTRACTS.json','prototype/yield-evidence/CONTRACTS.json')
 source=source:gsub("q:GetAttribute%('Section'%)=='S2'", "(q:GetAttribute('Section')=='S2' or q:GetAttribute('Section')=='S4')")
end
local env=table.clone(getfenv());local nativeRequire=require
env.require=function(p)
 if p=='@lune/process' and mode=='drop' then return {args={process.args[2]}} end
 return nativeRequire(p)
end
luau.load(source,{environment=env,injectGlobals=true})()
