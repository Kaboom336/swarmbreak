-- Extend the existing runtime fixture with the new cosmetic module dependency.
-- All original kit staging/failure/retry/lane/frozen-R1 assertions run unchanged.
local fs,luau=require('@lune/fs'),require('@lune/luau')
local H='treasure/cave-sections/C2/'
local source=fs.readFile(H..'runtime-check.luau')
local insertion=[[local dress=luau.load(node.Dress.Source,{environment={Instance=rb.Instance,Vector3=rb.Vector3,CFrame=rb.CFrame,Color3=rb.Color3,Enum=rb.Enum,task={wait=function()end}}})()
local waits,warnings=0,0]]
source=source:gsub('local waits,warnings=0,0',function()return insertion end,1)
source=source:gsub('if n==node.Presentation then return apply elseif', 'if n==node.Dress then return dress elseif n==node.Presentation then return apply elseif',1)
local proxy=table.clone(fs)
proxy.writeFile=function(path,value)
 if path==H..'RUNTIME.json'then path=H..'RUNTIME-R34.json'end
 return fs.writeFile(path,value)
end
local originalRequire=require;local env=table.clone(getfenv())
env.require=function(path)if path=='@lune/fs'then return proxy end;return originalRequire(path)end
luau.load(source,{environment=env,injectGlobals=true})()
