local fs,luau=require('@lune/fs'),require('@lune/luau')
local source=fs.readFile('treasure/sections/S7/contracts.luau'):gsub('S7','S8'):gsub('Section7','Section8')
luau.load(source,{environment=getfenv(),injectGlobals=true})()
