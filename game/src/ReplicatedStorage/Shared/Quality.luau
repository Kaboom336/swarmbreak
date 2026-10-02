--!strict
-- Pure adaptive client-quality policy. Frame times are seconds.

local Quality = {}

export type Choice = "Auto" | "Low" | "High"
export type Tier = "Low" | "High"
export type Budget = {
	FX: number,
	Particles: number,
	Animation: number,
}
export type State = {
	Choice: Choice,
	Tier: Tier,
	Samples: { number },
	NextSample: number,
	SampleCount: number,
	SampleTotal: number,
}

Quality.Choices = { "Auto", "Low", "High" }
Quality.DefaultChoice = "Auto"
Quality.WindowSize = 30
Quality.DowngradeFrameTime = 1 / 40
Quality.RecoveryFrameTime = 1 / 55

Quality.Budgets = {
	Low = {
		FX = 0.5,
		Particles = 0.4,
		Animation = 0.5,
	},
	High = {
		FX = 1,
		Particles = 1,
		Animation = 1,
	},
}

function Quality.sanitizeChoice(value: any): Choice
	if value == "Low" or value == "High" then
		return value
	end
	return Quality.DefaultChoice
end

function Quality.new(choice: any): State
	local cleanChoice = Quality.sanitizeChoice(choice)
	return {
		Choice = cleanChoice,
		Tier = if cleanChoice == "Low" then "Low" else "High",
		Samples = {},
		NextSample = 1,
		SampleCount = 0,
		SampleTotal = 0,
	}
end

function Quality.budget(state: State): Budget
	return Quality.Budgets[state.Tier]
end

-- Adds one frame to the fixed-size rolling average and returns the updated state. The state is
-- updated in place so this per-frame path creates no tables.
function Quality.sample(state: State, frameTime: any): State
	if type(frameTime) ~= "number" or frameTime ~= frameTime or frameTime <= 0 then
		return state
	end
	if state.Choice ~= "Auto" then
		state.Tier = if state.Choice == "Low" then "Low" else "High"
		return state
	end

	if state.SampleCount < Quality.WindowSize then
		state.SampleCount += 1
	else
		state.SampleTotal -= state.Samples[state.NextSample]
	end
	state.Samples[state.NextSample] = frameTime
	state.SampleTotal += frameTime
	state.NextSample = state.NextSample % Quality.WindowSize + 1

	if state.SampleCount == Quality.WindowSize then
		local average = state.SampleTotal / state.SampleCount
		local epsilon = 1e-9
		if state.Tier == "High" and average >= Quality.DowngradeFrameTime - epsilon then
			state.Tier = "Low"
		elseif state.Tier == "Low" and average <= Quality.RecoveryFrameTime + epsilon then
			state.Tier = "High"
		end
	end
	return state
end

return Quality
