--!strict
-- Maps gameplay events to entries in Sounds. Keep event names independent of asset choices.
local soundByEvent: { [string]: string } = {
	["enemy kill"] = "Kill",
	["wave clear"] = "WaveClear",
	["quest done"] = "Coin",
	["kit equip"] = "Buy",
	["wave start"] = "WaveStart",
	["boss spawn"] = "BossRoar",
	["card pick"] = "Buy",
	["crate open"] = "Crate",
	["pickup"] = "Coin",
	["level up"] = "Buy",
	["low hp"] = "Hurt",
	["victory"] = "WaveClear",
	["defeat"] = "GameOver",
}

local SfxMap = {}

function SfxMap.forEvent(eventName: string): string?
	return soundByEvent[eventName]
end

return SfxMap
