local fs,luau=require('@lune/fs'),require('@lune/luau')
local nativeRequire=require;local env=table.clone(getfenv())
env.require=function(p)
 if p:sub(1,7)=='./core/'then return nativeRequire('../../../prototype/'..p:sub(3))end
 if p:sub(1,12)=='./meadow-v4/'then return nativeRequire('../../../prototype/'..p:sub(3))end
 if p:sub(1,3)=='../'then return nativeRequire('../../../prototype/'..p)end
 return nativeRequire(p)
end
luau.load(fs.readFile('treasure/pvpflake-tests.luau'),{environment=env,injectGlobals=true})()
