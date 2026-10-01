--!strict
local SfxMap = load("SfxMap")
local Sounds = load("Sounds")

test("gameplay events use sounds from the sound library", function()
	local expected = {
		["enemy kill"] = "Kill",
		["wave clear"] = "WaveClear",
		["quest done"] = "Coin",
		["kit equip"] = "Buy",
	}

	for eventName, soundName in expected do
		eq(SfxMap.forEvent(eventName), soundName, eventName)
		assert(Sounds[soundName] ~= nil, eventName .. " names a missing sound")
	end
end)

test("events without a sound return nil", function()
	eq(SfxMap.forEvent("wave start"), nil, "unmapped event")
end)
