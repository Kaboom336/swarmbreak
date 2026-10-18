local fs,luau,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/serde")
local path="slice-v2/base/"
local C=require("./Config"); local R=require("./Rules")(C); local D=require("./SaveDomain")(C,R)
local assertions,compiled=0,0
assertions+=require("./earners/check")()
local function check(ok,why) assert(ok,why); assertions+=1 end
local function eq(a,b,why) check(a==b,(why or "equal")..": "..tostring(a).." / "..tostring(b)) end
for _,file in fs.readDir(path) do if file:match("%.luau$") then luau.compile(fs.readFile(path..file)); compiled+=1 end end
for _,file in fs.readDir(path.."earners/") do
	if file:match("%.luau$") then luau.compile(fs.readFile(path.."earners/"..file)); compiled+=1 end
end
eq(#C.Earners,25,"definitions")
eq(#C.Rarities,5,"rarities")
local rolls={0,0,0,0,0}
for n=0,9999 do local tier=R.roll(C.Rarities,(n+0.5)/10000); rolls[tier]+=1 end
for tier,row in C.Rarities do eq(rolls[tier],row.weight*100,"exact rarity stratification") end
eq(R.roll(C.Rarities,0.64999),1,"Common upper edge")
eq(R.roll(C.Rarities,0.65),2,"Rare lower edge")
eq(R.roll(C.Rarities,0.99999),5,"Mythic edge")
check(not pcall(R.roll,C.Rarities,0/0),"reject NaN roll")
check(not pcall(R.roll,C.Rarities,1),"reject out-of-range roll")
local mutations={0,0,0}
for n=0,9999 do local m=R.roll(C.Mutations,(n+0.5)/10000); mutations[m]+=1 end
eq(mutations[1],9600); eq(mutations[2],300); eq(mutations[3],100)
for id,e in C.Earners do
	for mutation=1,3 do
		local income=R.income(id,mutation); local price=R.price(id,mutation)
		check(price/income>=110 and price/income<=200,"payback bounds "..id)
		eq(income,e.rate*C.Mutations[mutation].multiplier,"mutation income")
	end
end
eq(R.income(1,2),7.5); eq(R.income(1,3),10)
eq(R.price(1,1),600); eq(R.price(1,3),1200)
check(R.price(26,1)==nil and R.income(1,0)==nil,"invalid definitions")
local d=D.default(100)
check(D.validate(d),"new profile")
eq(R.firstFree(d),1)
local item={def=1,mutation=1,state="Carpet"}
check(R.canBuy(d,item,12),"starter affordable")
check(not R.canBuy(d,item,12.01),"buy distance")
check(not R.canBuy(d,item,0/0),"NaN distance")
item.state="Delivering"; check(not R.canBuy(d,item,1),"double buy blocked")
item.state="Carpet"; d.cash=599; check(not R.canBuy(d,item,1),"insufficient cash")
d.cash=600
for slot=1,4 do d.owned[tostring(slot)]={def=1,mutation=1,pile=0} end
check(R.firstFree(d)==nil and not R.canBuy(d,item,1),"full base")
d.owned["2"]=nil; eq(R.firstFree(d),2,"first available slot")
check(R.firstFree(d,{[2]=true})==nil,"carry reservation")
eq(R.unlockCost(4),100); eq(R.unlockCost(5),1500); eq(R.unlockCost(9),156250)
check(R.unlockCost(10)==nil,"unlock max")
eq(R.upgradeCost(0),100); eq(R.upgradeCost(1),250); eq(R.upgradeCost(2),625)
check(R.upgradeCost(10)==nil,"upgrade cap"); eq(R.walkSpeed(3),22)
eq(R.lockState(159.9,160,220),"Locked")
eq(R.lockState(160,160,220),"Cooldown")
eq(R.lockState(220,160,220),"Ready")
d.purchases=2; check(not R.canLock(d,0,0,0,1),"lock gated")
d.purchases=3; check(R.canLock(d,0,0,0,1),"third purchase unlock")
check(not R.canLock(d,60,60,120,1),"lock cooldown")
check(not R.canLock(d,120,60,120,13),"lock distance")
local args={thief=1,owner=2,thiefPurchases=3,ownerPurchases=3,locked=false,carrying=false,
	freeSlot=true,state="Placed",distance=12,held=2}
check(R.canSteal(args),"valid steal")
for _,case in {{"thief",2},{"thiefPurchases",2},{"ownerPurchases",2},{"locked",true},
	{"carrying",true},{"freeSlot",false},{"state","Carried"},{"distance",13},{"distance",0/0},{"held",1.99},{"held",math.huge}} do
	local copy=D.copy(args); copy[case[1]]=case[2]
	check(not R.canSteal(copy),"steal reject "..case[1])
end
R.tick(d,1); eq(d.owned["1"].pile,5,"one-second tick")
eq(R.collect(d),15,"collect sum"); eq(d.cash,615)
eq(R.collect(d),0,"collect exactly once")
d.owned["1"].mutation=2
local rate=R.totalRate(d)
eq(R.offline(d,99),0,"future timestamp")
eq(R.offline(d,100),0,"no elapsed time")
eq(R.offline(d,160),rate*60,"one minute offline")
eq(R.offline(d,100+3600),rate*3600,"one hour cap")
eq(R.offline(d,100+36000),rate*3600,"ten hour cap")
local encoded=serde.encode("json",d)
local decoded=serde.decode("json",encoded)
check(D.validate(decoded),"JSON roundtrip valid"); eq(decoded.cash,d.cash)
eq(decoded.owned["1"].mutation,2,"pedestal record")
for _,case in {{"cash",0/0},{"cash",math.huge},{"cash",-1},{"unlocked",11},{"upgrades",-1},{"lastSeen",-1}} do
	local bad=D.copy(d); bad[case[1]]=case[2]; check(not D.validate(bad),"invalid save "..case[1])
end
local bad=D.copy(d); bad.owned["10"]={def=1,mutation=1,pile=0}; check(not D.validate(bad),"locked slot data")
bad=D.copy(d); bad.owned["1"].pile=math.huge; check(not D.validate(bad),"invalid pile")
local store=require("./MockStore")(D)
local p=store:StartSessionAsync("a",100); p.Data=d
check(store:StartSessionAsync("a",100)==nil,"exclusive mock session")
check(p:Save(),"mock save"); p.Data.cash=99; eq(store.records.a.cash,615,"saved data is isolated")
store.failWrites=true; check(not p:EndSession(),"save failure keeps session")
check(p:IsActive(),"failed close remains active")
store.failWrites=false; check(p:EndSession(),"session release")
local p2=store:StartSessionAsync("a",200); eq(p2.Data.cash,99,"mock reload")
-- Exercise the live adapter offline against UpdateAsync semantics, including lease takeover.
local backend={records={},fail=false}
function backend:UpdateAsync(key,fn)
	if self.fail then error("injected outage") end
	local v=fn(D.copy(self.records[key])); if v==nil then return nil end
	self.records[key]=D.copy(v); return D.copy(v)
end
local time=100
local profiles=require("./Profiles")
local a=profiles(C,D,backend,"A",function() return time end)
local b=profiles(C,D,backend,"B",function() return time end)
local pa=a:StartSessionAsync("live",time); check(pa~=nil,"live adapter load")
check(b:StartSessionAsync("live",time)==nil,"live lease excludes second server")
pa.Data.cash=123; check(pa:Save(),"live adapter write")
backend.fail=true; check(not pa:Save(),"DataStore failure observable")
check(a:StartSessionAsync("outage",time)==nil,"outage never makes fresh profile")
backend.fail=false; check(pa:EndSession(),"live adapter release")
check(backend.records.live.lease==nil,"lease actually cleared")
local pb=b:StartSessionAsync("live",time); eq(pb.Data.cash,123,"live roundtrip")
time+=181; check(not pb:IsActive() and not pb:Save(),"expired writer blocked")
local nextSession=a:StartSessionAsync("live",time); check(nextSession~=nil,"expired lease takeover")
check(not pb:Save(),"old token cannot overwrite takeover")
backend.records.corrupt={data={cash=999}}; check(a:StartSessionAsync("corrupt",time)==nil,"corrupt data fails closed")
local sim=require("./Economy")
local result=sim(C,R,D,20261018,1)
check(result.firstBuy and result.firstBuy<30,"first buy under 30 seconds")
check(result.firstPlaced and result.firstPlaced<120,"first earner under two minutes")
check(result.firstCollect and result.firstCollect<30,"first banked reward under 30 seconds")
check(result.firstUnlock and result.firstUnlock<=180,"first pedestal under three minutes")
local maxBuy,maxPlace,maxUnlock=0,0,0
for plot=1,8 do
	local run=sim(C,R,D,20261018+plot,plot)
	check(run.firstBuy and run.firstBuy<30,"plot first buy "..plot)
	check(run.firstPlaced and run.firstPlaced<120,"plot placement "..plot)
	check(run.firstUnlock and run.firstUnlock<=180,"plot unlock "..plot)
	maxBuy=math.max(maxBuy,run.firstBuy); maxPlace=math.max(maxPlace,run.firstPlaced); maxUnlock=math.max(maxUnlock,run.firstUnlock)
end
local report=string.format("PASS %d offline assertions; %d Luau sources compile.\nDeterministic 600s simulation, seed 20261018, plot 1, active collect/buy policy:\nFirst buy %.2fs; first earner placed %.2fs; first collected reward %.2fs; first pedestal unlock %.2fs.\nBanked cash at 2/5/10 min: $%.2f / $%.2f / $%.2f. Final rate $%.2f/s; purchases %d.\nEight-plot seed sweep maxima: buy %.2fs; placed %.2fs; unlock %.2fs.\nEconomy timings are SIMULATED, not measured player behavior.\nStudio EDIT, Play, two-client server, device, visual/fun, live DataStore: NOT RUN.\n",assertions,compiled,result.firstBuy,result.firstPlaced,result.firstCollect,result.firstUnlock,result.cash["120"],result.cash["300"],result.cash["600"],result.rate,result.purchases,maxBuy,maxPlace,maxUnlock)
fs.writeFile(path.."OFFLINE-RESULT.txt",report)
fs.writeFile(path.."ECONOMY-RESULT.json",serde.encode("json",result,true))
print(report)
