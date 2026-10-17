-- Preserve the existing production N8 sampler, shard partition and tolerances.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local s=fs.readFile('treasure/rock3-drop.luau'):gsub('treasure/rock3/','treasure/rockcolor/')
local nativeRequire=require;local env=table.clone(getfenv())
env.require=function(p)if p=='../prototype/meadow-v4/OfflineRay'then return nativeRequire('../prototype/meadow-v4/OfflineRay')end;return nativeRequire(p)end
luau.load(s,{environment=env,injectGlobals=true})()
