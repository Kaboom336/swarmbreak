local fs,luau=require('@lune/fs'),require('@lune/luau')
local source=fs.readFile('treasure/sections/S7/drop.luau'):gsub('S7','S8')
-- Bind the native relative import at file scope; nested luau.load cannot resolve it.
local ray=require('../../../prototype/meadow-v4/OfflineRay')
local nativeRequire=require
local env=table.clone(getfenv())
env.require=function(p)
 if p=='../../../prototype/meadow-v4/OfflineRay' then return ray end
 return nativeRequire(p)
end
luau.load(source,{environment=env,injectGlobals=true})()
