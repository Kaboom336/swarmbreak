--!strict
local ExperienceRules = require(script.Parent.ExperienceRules)

local Tutorial = {}

function Tutorial.banner(size: number, tutorialDone: boolean): string?
	return ExperienceRules.tutorialStep(size, tutorialDone, false, tutorialDone)
end

function Tutorial.canLaunch(size: number): (boolean, number)
	return ExperienceRules.canLaunch(size)
end

return Tutorial
