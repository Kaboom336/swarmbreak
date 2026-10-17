local fs,luau=require('@lune/fs'),require('@lune/luau')
local s=fs.readFile('treasure/rock/offline-contracts.luau'):gsub('treasure/rock/','treasure/rock4/')
luau.load(s,{environment=getfenv(),injectGlobals=true})()
