--!strict
-- Ordered first-run tutorial state. Completion is stored in profile Flags.

export type Context = "arena" | "cards" | "shop"
export type Platform = "keyboard" | "touch" | "gamepad"

export type Step = {
	Id: string,
	Name: string,
	Hint: string,
	Hints: { [Platform]: string },
	Context: Context,
	Optional: boolean?,
}

local Tutorial = {}

Tutorial.FlagPrefix = "Tut_"
Tutorial.Steps = {
	{
		Id = "Move",
		Name = "Move",
		Hint = "Use WASD to move",
		Hints = {
			keyboard = "Use WASD to move",
			touch = "Drag to move",
			gamepad = "Use the left stick to move",
		},
		Context = "arena",
	},
	{
		Id = "Shoot",
		Name = "Shoot",
		Hint = "Click to shoot",
		Hints = {
			keyboard = "Click to shoot",
			touch = "Tap to shoot",
			gamepad = "Press the right trigger to shoot",
		},
		Context = "arena",
	},
	{
		Id = "Dash",
		Name = "Dash",
		Hint = "Press Shift to dash",
		Hints = {
			keyboard = "Press Shift to dash",
			touch = "Tap DASH to dash",
			gamepad = "Press B to dash",
		},
		Context = "arena",
		Optional = true,
	},
	{
		Id = "Pick",
		Name = "Pick a reward card",
		Hint = "Pick a reward card",
		Hints = {
			keyboard = "Pick a reward card",
			touch = "Tap a reward card",
			gamepad = "Select a reward card",
		},
		Context = "cards",
	},
	{
		Id = "Upgrade",
		Name = "Buy an upgrade",
		Hint = "Buy an upgrade",
		Hints = {
			keyboard = "Buy an upgrade",
			touch = "Tap an upgrade to buy it",
			gamepad = "Select an upgrade to buy it",
		},
		Context = "shop",
	},
	{
		Id = "Crate",
		Name = "Open a crate",
		Hint = "Open a crate",
		Hints = {
			keyboard = "Open a crate",
			touch = "Tap a crate to open it",
			gamepad = "Select a crate to open it",
		},
		Context = "shop",
		Optional = true,
	},
} :: { Step }
Tutorial.DelaySeconds = { Move = 8, Shoot = 6, Pick = 5 } :: { [string]: number } -- placeholder
Tutorial.DefaultDelaySeconds = 5 -- placeholder

function Tutorial.flagKey(stepId: string): string
	return Tutorial.FlagPrefix .. stepId
end

function Tutorial.next(flags: { [string]: boolean }): Step?
	for _, step in Tutorial.Steps do
		if flags[Tutorial.flagKey(step.Id)] ~= true then
			return step
		end
	end
	return nil
end

function Tutorial.pick(flags: { [string]: boolean }, context: Context): Step?
	for _, optional in { false, true } do
		for _, step in Tutorial.Steps do
			if
				step.Context == context
				and (step.Optional == true) == optional
				and flags[Tutorial.flagKey(step.Id)] ~= true
			then
				return step
			end
		end
	end
	return nil
end

function Tutorial.shouldShow(stepId: string, secondsInContext: number): boolean
	local delay = Tutorial.DelaySeconds[stepId] or Tutorial.DefaultDelaySeconds
	return secondsInContext >= delay
end

function Tutorial.hintFor(stepId: string, platform: Platform): string
	for _, step in Tutorial.Steps do
		if step.Id == stepId then
			return step.Hints[platform]
		end
	end
	return ""
end

-- Return a copy so callers can safely replace profile Flags without mutating old state.
function Tutorial.complete(flags: { [string]: boolean }, stepId: string): { [string]: boolean }
	local completed = table.clone(flags)
	for _, step in Tutorial.Steps do
		if step.Id == stepId then
			completed[Tutorial.flagKey(stepId)] = true
			break
		end
	end
	return completed
end

return Tutorial
