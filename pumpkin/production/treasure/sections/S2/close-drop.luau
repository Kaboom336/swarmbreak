-- Reuse the complete existing N8 lattice and disjoint route workers unchanged.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local src=fs.readFile('prototype/s2r4-drop.luau'):gsub('r4','close')
local env=table.clone(getfenv());local nativeRequire=require
env.require=function(path)
 if path=='./meadow-v4/OfflineRay' then return nativeRequire('../../../prototype/meadow-v4/OfflineRay') end
 return nativeRequire(path)
end
luau.load(src,{environment=env,injectGlobals=true})()
