--!strict
-- Ordered first-run tutorial state. Completion is stored in profile Flags.

export type Step = {
	Id: string,
	Name: string,
	Hint: string,
}

local Tutorial = {}

Tutorial.FlagPrefix = "Tut_"
Tutorial.Steps = {
	{ Id = "Move", Name = "Move", Hint = "Use WASD to move" },
	{ Id = "Shoot", Name = "Shoot", Hint = "Click to shoot" },
	{ Id = "Dash", Name = "Dash", Hint = "Press Shift to dash" },
	{ Id = "Pick", Name = "Pick a reward card", Hint = "Pick a reward card" },
	{ Id = "Upgrade", Name = "Buy an upgrade", Hint = "Buy an upgrade" },
	{ Id = "Crate", Name = "Open a crate", Hint = "Open a crate" },
} :: { Step }

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
