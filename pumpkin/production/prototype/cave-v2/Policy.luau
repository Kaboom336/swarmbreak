-- Cave hooks are previews: no Explosion, damage, force, or cargo mutation.
local P = { recoveryHeight = 4.5, spanMinimum = 20, flightSpeed = 24 }
function P.flight(speed)
	return speed >= P.flightSpeed and "Flight" or "Fall"
end
function P.canBlast(busy, lastBreak, now, armed)
	return busy == 0 and now - lastBreak >= P.spanMinimum and not armed
end
function P.canRepair(busy, nearby, age)
	return busy == 0 and not nearby and age >= P.spanMinimum
end
P.previews = {
	TNTHook = { stages = { 1 }, cooldown = 15 },
	DynamiteGuardianHook = { stages = { 1.5, 1 }, cooldown = 7 },
	ShatterCavernHook = { stages = { 1, 0.8, 0.8 }, cooldown = 20 },
}
return P
