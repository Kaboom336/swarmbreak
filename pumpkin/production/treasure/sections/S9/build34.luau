-- Reuse the proven Lune pipeline; only Section9 changes from immediate R2.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local source=fs.readFile('treasure/sections/S9/build.luau')
source=source:gsub("if tag=='r2'then", "if tag~='before'then")
source=source:gsub("if tag=='r2' then", "if tag~='before' then")
-- All existing sources and place state are checked by the original neutralizer.
luau.load(source,{environment=getfenv(),injectGlobals=true})()
