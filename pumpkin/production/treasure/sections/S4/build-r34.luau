-- Reuse the canonical source-mount/export pipeline, preserving serialized kits/Workspace.
-- Never deliver a plain Rojo reconstruction of the Meadow place.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local src=fs.readFile('treasure/sections/S4/build.luau')
src=src:gsub('guardian%-greybox.pre%-s4.rbxl','guardian-greybox.pre-s4r3.rbxl')
src=src:gsub('kind=p.ClassName,position',"kind=p.ClassName,section=p.Parent:GetAttribute('Section'),shadows=p.Shadows,position")
src=src:gsub("local s=rb.Instance.new%('ModuleScript'%);s.Name='Section4';", "local s=place.ReplicatedStorage.MeadowV4.Section4;")
src=src:gsub("export%(old,'before'%)", "export(old,'r3-start')")
src=src:gsub('signatures.before', "signatures['r3-start']")
src=src:gsub("if mode=='deliver' then", "if mode=='r3' or mode=='r4' then")
local first=assert(src:find(" local rojo=",1,true))
local last=assert(src:find(' fs.writeFile(main,bytes)',first,true))
src=src:sub(1,first-1)..src:sub(last)
luau.load(src,{environment=getfenv(),injectGlobals=true})()
