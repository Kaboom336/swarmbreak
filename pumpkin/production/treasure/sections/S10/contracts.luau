local fs,luau=require('@lune/fs'),require('@lune/luau')
local source=fs.readFile('treasure/sections/S9/contracts.luau'):gsub('sections/S9','sections/S10')
luau.load(source,{environment=getfenv(),injectGlobals=true})()
