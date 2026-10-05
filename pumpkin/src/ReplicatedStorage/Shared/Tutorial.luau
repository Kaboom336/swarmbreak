--!strict
local Config = require(script.Parent.Config)

local Tutorial = {}

function Tutorial.banner(size: number, tutorialDone: boolean): string?
	if tutorialDone then
		return nil
	end
	if math.max(0, size) >= Config.TutorialRollSize then
		return "FOLLOW THE ARROW - STEP ON THE START PAD!"
	end
	return "Grow to 10 then roll!"
end

return Tutorial
