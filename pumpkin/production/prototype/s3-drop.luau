-- Reuse the complete existing N8 production lattice and disjoint workers unchanged.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local source=fs.readFile('prototype/s2r4-drop.luau'):gsub('treasure/sections/S2/','treasure/sections/S3/'):gsub('r4','final')
local env=table.clone(getfenv());local nativeRequire=require;env.require=function(p)
 if p=='./meadow-v4/OfflineRay' then return nativeRequire('./meadow-v4/OfflineRay') end
 return nativeRequire(p)
end
luau.load(source,{environment=env,injectGlobals=true})()
