-- Copied and extended from heists/SaveDomain: deep copy and strict finite validation.
return function(C,R)
	local D={}
	function D.copy(value)
		if type(value)~="table" then return value end
		local out={}
		for k,v in value do out[k]=D.copy(v) end
		return out
	end
	function D.default(now)
		return {version=1,cash=C.StartCash,owned={},unlocked=C.StartUnlocked,upgrades=0,
			purchases=0,discovered={},tutorial=1,lastSeen=now}
	end
	function D.validate(d)
		if type(d)~="table" or d.version~=1 or type(d.owned)~="table" or type(d.discovered)~="table" then return false end
		if not R.finite(d.cash) or d.cash<0 or d.cash>9e15 then return false end
		for _,s in {{d.unlocked,C.StartUnlocked,C.PedestalCount},{d.upgrades,0,C.MaxUpgrade},
			{d.purchases,0,1e9},{d.tutorial,1,4},{d.lastSeen,0,9e15}} do
			if not R.integer(s[1],s[2],s[3]) then return false end
		end
		for key,item in d.owned do
			local slot=type(key)=="string" and tonumber(key)
			if not slot or not R.integer(slot,1,d.unlocked) or tostring(slot)~=key or type(item)~="table"
				or not R.income(item.def,item.mutation) or not R.finite(item.pile) or item.pile<0 or item.pile>9e15 then return false end
		end
		for key,v in d.discovered do
			if type(key)~="string" or not R.integer(tonumber(key),1,#C.Earners) or v~=true then return false end
		end
		return true
	end
	return D
end
