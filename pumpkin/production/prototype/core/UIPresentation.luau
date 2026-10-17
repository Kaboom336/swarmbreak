-- Pure display decisions. No Roblox services, mutation or gameplay authority.
local UI = {}
function UI.objective(s)
	if s.carry then
		if s.cave or s.phase == "Run" then
			return "Escape to the portal!"
		end
		return "Place your acorn on your plot"
	end
	if s.cave then
		return s.secured and "Geode secured!" or "Steal the Crystal Geode"
	end
	if s.goal and s.goal:find("Action refused:", 1, true) == 1 then
		return s.goal
	end
	if s.phase == "Run" then
		return "Steal the Golden Acorn"
	end
	local goal = s.goal or "Enter the central portal"
	if goal:lower():find("enter", 1, true) then
		return "Enter the central portal"
	end
	return goal:gsub("%.$", "")
end
function UI.timer(carry, deadline, now, caveSeconds)
	if not carry then
		return nil
	end
	local remaining = type(deadline) == "number" and deadline - now or caveSeconds
	if type(remaining) ~= "number" or remaining ~= remaining then
		return nil
	end
	return math.max(0, remaining)
end
function UI.gain(previous, current)
	return type(previous) == "number" and type(current) == "number" and math.max(0, current - previous) or 0
end
function UI.plate(raw, keeper, ownSlot)
	if keeper then
		raw = raw:gsub("^>%s*", "")
		if raw:find("CHARGE", 1, true) then
			return "Charge! Step aside"
		end
		if raw:find("JUMP", 1, true) then
			return "Jump! Shockwave"
		end
		local warning = raw:match("^>?%s*([!?])")
		if warning then
			return raw:gsub("%s*/%s*", " · ")
		end
		if not raw:find("GUARDIAN", 1, true) then
			return raw:gsub("%s*/%s*", " · ")
		end
		if raw:find("BURST", 1, true) then
			return "Keeper · Sprinting!"
		end
		return "Keeper"
	end
	local slot, owner = raw:match("^>?%s*Pen (%d+) / (.*)$")
	if not slot then
		return nil
	end
	if owner == "vacant" then
		return "", false
	end
	return tonumber(slot) == ownSlot and "Your plot" or owner .. "'s plot", true
end
function UI.bannerWidth(safeWidth)
	return math.max(120, math.min(460, safeWidth - 24))
end
return UI
