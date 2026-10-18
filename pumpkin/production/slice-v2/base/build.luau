-- lune run slice-v2/base/build.luau -- copied fresh-DataModel pattern from heists.
local fs,rb,luau=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau")
local base="slice-v2/base/"
local compiled=0
for _,file in fs.readDir(base) do
	if file:match("%.luau$") then luau.compile(fs.readFile(base..file)); compiled+=1 end
end
local function node(class,name,parent)
	local p=rb.Instance.new(class); p.Name=name; p.Parent=parent; return p
end
local place=rb.Instance.new("DataModel")
local ws=node("Workspace","Workspace",place); ws.Gravity=196.2; ws.StreamingEnabled=false
local rs=node("ReplicatedStorage","ReplicatedStorage",place)
local sss=node("ServerScriptService","ServerScriptService",place)
local starter=node("StarterPlayer","StarterPlayer",place)
local scripts=node("StarterPlayerScripts","StarterPlayerScripts",starter)
local lighting=node("Lighting","Lighting",place); lighting.ClockTime=14; lighting.Brightness=2
local shared=node("Folder","TreasureBase",rs); shared:SetAttribute("LegendaryIn",300)
local function mount(class,name,file,parent)
	local p=node(class,name,parent); p.Source=fs.readFile(base..file); return p
end
for _,name in {"Config","Rules","SaveDomain","EarnerModel"} do mount("ModuleScript",name,name..".luau",shared) end
for _,name in {"Profiles","MockStore","BaseTest"} do mount("ModuleScript",name,name..".luau",sss) end
mount("Script","BaseServer","Base.server.luau",sss)
mount("LocalScript","BaseClient","Base.client.luau",scripts)
sss:SetAttribute("BaseUseDataStoreInStudio",false)
sss:SetAttribute("BaseRuntimeTest","NOT RUN")
for _,name in {"Action","State","Toast","Pop"} do node("RemoteEvent",name,shared) end
local env={Instance=rb.Instance,Vector3=rb.Vector3,Color3=rb.Color3,CFrame=rb.CFrame,
	UDim2=rb.UDim2,Enum=rb.Enum}
local function load(file) return luau.load(fs.readFile(base..file),{environment=env,injectGlobals=true})() end
local C=require("./Config"); local R=require("./Rules")(C)
local world=load("Scene.luau")(ws,C)
load("EarnerModel.luau")(C,R).create(world.Earners,"StarterPreview",1,1,rb.Vector3.new(0,2,-8),"Carpet")
assert(#world.Plots:GetChildren()==8)
local bytes=rb.serializePlace(place)
local roundtrip=rb.deserializePlace(bytes)
assert(roundtrip.ServerScriptService.BaseServer.Source==fs.readFile(base.."Base.server.luau"))
assert(#roundtrip.Workspace.TreasureBase.Plots:GetChildren()==8)
-- Execute the actual EDIT test with a local require shim against the serialized place.
local cache={}
local function moduleRequire(module)
	if cache[module] then return cache[module] end
	local value=luau.load(module.Source,{environment=env,injectGlobals=true})()
	cache[module]=value; return value
end
local testEnv=table.clone(env); testEnv.require=moduleRequire
local test=luau.load(fs.readFile(base.."BaseTest.luau"),{environment=testEnv,injectGlobals=true})()
local assertions=test(roundtrip)
fs.writeFile(base.."steal-a-treasure-base.rbxl",bytes)
local report=string.format("PASS build: %d Luau sources compile; %d serialized-place structure assertions; %d bytes.\nStudio EDIT execution: NOT RUN (same module run offline against serialized DataModel).\nStudio Play, multiplayer, live DataStore, visual/fun: NOT RUN.\n",compiled,assertions,#bytes)
fs.writeFile(base.."BUILD-RESULT.txt",report)
print(report)
