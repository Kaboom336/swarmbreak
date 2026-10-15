-- Real vendored ProfileStore.Mock contract check, isolated from player records.
return function(folder)
	local PS=require(folder.Packages.ProfileStore)
	local store=PS.New("CoreLoopTest_"..game:GetService("HttpService"):GenerateGUID(false),{}).Mock
	local Config,Domain,Profiles=require(folder.Config),require(folder.Domain),require(folder.Profiles)
	local adapter=Profiles.new(store,Config,Domain,"studio-fixture",os.time,task.wait)
	local data=assert(adapter:load("fixture"))
	assert(adapter:transaction("fixture",function(nextData)
		nextData.coins=17
		return true
	end))
	assert(adapter.sessions.fixture.profile.LastSavedData.data.coins==17,"real Mock acknowledgement")
	local ended=false
	adapter.sessions.fixture.profile.OnSessionEnd:Connect(function() ended=true end)
	assert(adapter:save("fixture",true))
	local deadline=os.clock()+10
	while not ended and os.clock()<deadline do task.wait(.05) end
	assert(ended,"real Mock EndSession")
	local restored=Profiles.new(store,Config,Domain,"rejoin",os.time,task.wait)
	assert(restored:load("fixture").coins==17,"real Mock roundtrip")
	assert(restored:save("fixture",true))
	return "real ProfileStore.Mock save/acknowledgement/release/rejoin PASS"
end
