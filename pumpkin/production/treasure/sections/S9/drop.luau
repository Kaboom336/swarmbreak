-- Reuse unchanged production N8 sample lattice, resolver and complete route shards.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local source=fs.readFile('treasure/sections/S7/drop.luau'):gsub('sections/S7','sections/S9')
source=source:gsub("elseif name=='RunService' then return {} end", "elseif name=='RunService' then return {} elseif name=='Workspace' then return place.Workspace end")
local ray=require('../../../prototype/meadow-v4/OfflineRay');local nativeRequire=require
local env=table.clone(getfenv());env.require=function(p)if p=='../../../prototype/meadow-v4/OfflineRay'then return ray end;return nativeRequire(p)end
luau.load(source,{environment=env,injectGlobals=true})()
