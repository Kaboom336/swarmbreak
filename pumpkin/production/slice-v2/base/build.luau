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
lighting.Ambient=rb.Color3.fromRGB(135,140,150)
lighting.OutdoorAmbient=rb.Color3.fromRGB(170,175,185)
lighting.GlobalShadows=true; lighting.FogEnd=10000
local atmosphere=node("Atmosphere","DaylightAtmosphere",lighting)
atmosphere.Density=0.15; atmosphere.Offset=0.1; atmosphere.Haze=0.4; atmosphere.Glare=0
atmosphere.Color=rb.Color3.fromRGB(210,230,255); atmosphere.Decay=rb.Color3.fromRGB(225,235,255)
local sky=node("Sky","DaylightSky",lighting)
for property,suffix in {SkyboxBk="bk",SkyboxDn="dn",SkyboxFt="ft",SkyboxLf="lf",SkyboxRt="rt",SkyboxUp="up"} do
	sky[property]="rbxasset://textures/sky/sky512_"..suffix..".tex"
end
local correction=node("ColorCorrectionEffect","DaylightColor",lighting)
correction.Saturation=0.08; correction.Contrast=0.02
local shared=node("Folder","TreasureBase",rs); shared:SetAttribute("LegendaryIn",300)
local function mount(class,name,file,parent)
	local p=node(class,name,parent); p.Source=fs.readFile(base..file); return p
end
for _,name in {"Config","Rules","SaveDomain","EarnerModel"} do mount("ModuleScript",name,name..".luau",shared) end
local earners=node("Folder","Earners",shared)
for _,name in {"VoxelKit","CopperCompass","Registry","Walk"} do
	luau.compile(fs.readFile(base.."earners/"..name..".luau")); compiled+=1
	mount("ModuleScript",name,"earners/"..name..".luau",earners)
end
luau.compile(fs.readFile(base.."earners/EarnerVisual.client.luau")); compiled+=1
mount("LocalScript","EarnerVisual","earners/EarnerVisual.client.luau",scripts)
for _,name in {"Profiles","MockStore","BaseTest"} do mount("ModuleScript",name,name..".luau",sss) end
mount("Script","BaseServer","Base.server.luau",sss)
mount("LocalScript","BaseClient","Base.client.luau",scripts)
sss:SetAttribute("BaseUseDataStoreInStudio",false)
sss:SetAttribute("BaseRuntimeTest","NOT RUN")
for _,name in {"Action","State","Toast","Pop"} do node("RemoteEvent",name,shared) end
local env={Instance=rb.Instance,Vector2=rb.Vector2,Vector3=rb.Vector3,Color3=rb.Color3,CFrame=rb.CFrame,
	UDim2=rb.UDim2,Enum=rb.Enum,Font=rb.Font}
local function load(file) return luau.load(fs.readFile(base..file),{environment=env,injectGlobals=true})() end
-- Use the same instance-based imports as Roblox, including nested earner modules.
local cache={}
local function moduleRequire(module)
	if cache[module] then return cache[module] end
	local moduleEnv=table.clone(env); moduleEnv.script=module; moduleEnv.require=moduleRequire
	local value=luau.load(module.Source,{environment=moduleEnv,injectGlobals=true})()
	cache[module]=value; return value
end
local C=require("./Config"); local R=require("./Rules")(C)
local world=load("Scene.luau")(ws,C)
luau.compile(world.LookVisuals.Source)
moduleRequire(shared.EarnerModel)(C,R).create(world.Earners,"StarterPreview",1,1,rb.Vector3.new(0,2,-8),"Carpet")
assert(#world.Plots:GetChildren()==8)
local bytes=rb.serializePlace(place)
local roundtrip=rb.deserializePlace(bytes)
assert(roundtrip.ServerScriptService.BaseServer.Source==fs.readFile(base.."Base.server.luau"))
assert(#roundtrip.Workspace.TreasureBase.Plots:GetChildren()==8)
-- Execute the actual EDIT test with a local require shim against the serialized place.
local testEnv=table.clone(env); testEnv.require=moduleRequire
local test=luau.load(fs.readFile(base.."BaseTest.luau"),{environment=testEnv,injectGlobals=true})()
local assertions=test(roundtrip)
-- Execute the actual adapter with offline signal doubles and serialized visual parts.
-- This checks state mapping, not engine scheduling/replication (Studio remains NOT RUN).
local function signal()
	local handlers={}
	return {Connect=function(_,fn) table.insert(handlers,fn) end,
		fire=function() for _,fn in handlers do fn() end end}
end
local original=roundtrip.Workspace.TreasureBase.Plots.Plot1
local barrierChanged,titleChanged,bankChanged=signal(),signal(),signal()
local barrier={CanCollide=false,Transparency=1}
function barrier:GetChildren() return original.Barrier:GetChildren() end
function barrier:GetPropertyChangedSignal() return barrierChanged end
local title={Text="Unclaimed base",GetPropertyChangedSignal=function() return titleChanged end}
local bank={Text="Collect $0",GetPropertyChangedSignal=function() return bankChanged end}
local pedestalDoubles={}
for _,ped in original.Pedestals:GetChildren() do
	local changed=signal()
	local double={Block=ped.Block,CollectPad=ped.CollectPad,unlocked=ped:GetAttribute("Unlocked"),changed=changed}
	function double:GetAttribute() return self.unlocked end
	function double:GetAttributeChangedSignal() return self.changed end
	table.insert(pedestalDoubles,double)
end
local plotDouble={Barrier=barrier,Floor={Sign={Text=title}},Collect={Sign={Text=bank}},
	Pedestals={GetChildren=function() return pedestalDoubles end}}
local visualEnv=table.clone(env)
visualEnv.script={Parent={Plots={GetChildren=function() return {plotDouble} end}}}
luau.load(world.LookVisuals.Source,{environment=visualEnv,injectGlobals=true})()
local visualAssertions=0
local function visualCheck(ok,why) assert(ok,why); visualAssertions+=1 end
for _,locked in {true,false,true,false} do
	barrier.CanCollide=locked; barrier.Transparency=locked and 0.5 or 1; barrierChanged:fire()
	visualCheck(barrier.CanCollide==locked and barrier.Transparency==1,"adapter preserves collision and hides sheet")
	for _,laser in barrier:GetChildren() do visualCheck(laser.Transparency==(locked and 0 or 1),"laser follows lock") end
end
for _,unlocked in {true,false,true} do
	for _,ped in pedestalDoubles do
		ped.unlocked=unlocked; ped.changed:fire()
		visualCheck(not ped.CollectPad.PadLabel.Enabled,"adapter leaves empty-slot labels hidden")
		visualCheck(ped.Block.Color==rb.Color3.fromRGB(unlocked and 60 or 100,unlocked and 65 or 100,unlocked and 75 or 100),"block remains dark after unlock")
		visualCheck(ped.CollectPad.Color==(unlocked and rb.Color3.fromRGB(75,200,60) or rb.Color3.fromRGB(100,100,100)),"pad follows unlock transitions")
	end
end
title.Text="Zion's base"; titleChanged:fire()
visualCheck(title.Text=="Zion's Base","live owner name on board")
title.Text="Unclaimed base"; titleChanged:fire()
visualCheck(title.Text=="Unclaimed Base","unclaim name on board")
bank.Text="Collect $123.5"; bankChanged:fire()
for _,ped in pedestalDoubles do visualCheck(ped.CollectPad.PadLabel.Text.Text=="Collect $0","adapter never mirrors pooled money into every slot") end
-- Exercise the actual server presentation function without starting gameplay services.
local serverSource=fs.readFile(base.."Base.server.luau")
local refreshSource=assert(serverSource:match("(local function refresh%(s%).-)\nlocal function save"))
local placed={owner="owner",slot=1,state="Placed",record={pile=7.5}}
local presentationEnv=table.clone(env)
presentationEnv.C=C; presentationEnv.R=R; presentationEnv.items={placed}
presentationEnv.pedestal=function(s,n) return s.plot.Pedestals["Pedestal"..n] end
local refresh=luau.load(refreshSource.."\nreturn refresh",{environment=presentationEnv,injectGlobals=true})()
local data={purchases=0,owned={["1"]=placed.record},unlocked=4,upgrades=0}
local session={player={DisplayName="Zion"},plot=original,data=data}
placed.owner=session.player
for unlocked=4,10 do
	data.unlocked=unlocked; refresh(session)
	for _,ped in original.Pedestals:GetChildren() do
		local slot=ped:GetAttribute("Slot")
		local sign=ped:FindFirstChild("Sign")
		if sign then visualCheck(sign.Enabled==(slot==unlocked+1),"only next locked slot has a price") end
		visualCheck(ped.CollectPad.PadLabel.Enabled==(slot==1),"only placed earner has collect label")
	end
end
visualCheck(original.Pedestals.Pedestal1.CollectPad.PadLabel.Text.Text=="Collect $7.5","real per-earner balance")
placed.record.pile=0; refresh(session)
visualCheck(original.Pedestals.Pedestal1.CollectPad.PadLabel.Text.Text=="Collect $0.0","collection clears displayed balance")
for _,state in {"Carried","Delivering"} do
	placed.state=state; refresh(session)
	visualCheck(not original.Pedestals.Pedestal1.CollectPad.PadLabel.Enabled,"no collect label while absent or delivering")
end
placed.state="Placed"; refresh(session)
visualCheck(original.Pedestals.Pedestal1.CollectPad.PadLabel.Enabled,"restored earner regains collect label")
local setStateSource=assert(serverSource:match("(local function setState%(item,value%).-)\nlocal function pedestal"))
local setState=luau.load(setStateSource.."\nreturn setState",{environment=env,injectGlobals=true})()
local preview=roundtrip.Workspace.TreasureBase.Earners.StarterPreview
local registerPrefix=assert(serverSource:match("(local function register%(part%).-)\n\tpart.BuyPrompt.Triggered"))
local registerEnv=table.clone(env); registerEnv.items={}
local registerLabel=luau.load(registerPrefix.."\nend\nreturn register",{environment=registerEnv,injectGlobals=true})()
local name,rarity,price=preview.Label.Line1.Text,preview.Label.Line2.Text,preview.Label.Line3.Text
registerLabel(preview)
visualCheck(not preview.Label.AlwaysOnTop and preview.Label.MaxDistance==45,"carpet label distance and wall occlusion after registration")
visualCheck(preview.Label.Line1.Text==name and preview.Label.Line2.Text==rarity and preview.Label.Line3.Text==price,"carpet name rarity price and income retained")
local stateItem={part=preview}
for _,state in {"Carpet","Delivering","Placed","Carried","Placed","Carpet"} do
	setState(stateItem,state)
	visualCheck(preview.Label.Enabled==(state=="Carpet"),"detailed earner label only on carpet")
end
local partCount=0
for _,item in roundtrip.Workspace:GetDescendants() do
	if item:IsA("BasePart") then partCount+=1 end
end
assert(partCount<2500,"whole-map part budget")
fs.writeFile(base.."steal-a-treasure-base.rbxl",bytes)
local report=string.format("PASS build: %d Luau sources + embedded LookVisuals compile; %d serialized-place structure assertions; %d offline presentation state assertions; %d bytes; %d whole-map BaseParts (budget <2500).\nStudio EDIT execution: NOT RUN (same module run offline against serialized DataModel).\nStudio Play, multiplayer, live DataStore, visual/fun: NOT RUN.\n",compiled,assertions,visualAssertions,#bytes,partCount)
fs.writeFile(base.."BUILD-RESULT.txt",report)
print(report)
