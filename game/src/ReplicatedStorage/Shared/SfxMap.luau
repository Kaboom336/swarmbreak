--!strict
-- Maps gameplay events to entries in Sounds. Keep event names independent of asset choices.
local soundByEvent: { [string]: string } = {
	["enemy kill"] = "Kill",
	["wave clear"] = "WaveClear",
	["quest done"] = "Coin",
	["kit equip"] = "Buy",
}

local SfxMap = {}

function SfxMap.forEvent(eventName: string): string?
	return soundByEvent[eventName]
end

return SfxMap
