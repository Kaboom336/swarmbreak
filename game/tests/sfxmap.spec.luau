--!strict
local SfxMap = load("SfxMap")
local Sounds = load("Sounds")

test("gameplay events use sounds from the sound library", function()
	local expected = {
		["enemy kill"] = "Kill",
		["wave clear"] = "WaveClear",
		["quest done"] = "Coin",
		["kit equip"] = "Buy",
		["wave start"] = "WaveStart",
		["boss spawn"] = "BossRoar",
		["card pick"] = "CardPick",
		["crate open"] = "Crate",
		["pickup"] = "Coin",
		["level up"] = "LevelUp",
		["low hp"] = "Hurt",
		["victory"] = "WaveClear",
		["defeat"] = "GameOver",
	}

	for eventName, soundName in expected do
		eq(SfxMap.forEvent(eventName), soundName, eventName)
		assert(Sounds[soundName] ~= nil, eventName .. " names a missing sound")
	end
end)

test("unknown events return nil", function()
	eq(SfxMap.forEvent("not a real event"), nil, "unknown event")
end)
