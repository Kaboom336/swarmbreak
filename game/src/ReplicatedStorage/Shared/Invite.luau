--!strict
-- Rules for offering a friend invite without repeatedly interrupting the player.

local Invite = {}

Invite.CooldownSec = 300 -- placeholder

function Invite.shouldShow(
	playersInServer: number,
	moment: "summary" | "death",
	lastShownAt: number?,
	now: number
): boolean
	if playersInServer ~= 1 then
		return false
	end
	if moment ~= "summary" and moment ~= "death" then
		return false
	end
	if lastShownAt == nil then
		return true
	end
	return now - lastShownAt >= Invite.CooldownSec
end

return Invite
