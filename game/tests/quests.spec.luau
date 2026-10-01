local Quests = load("Quests")
local ProfileSchema = load("ProfileSchema")

local DAY = 86400

local function stateWith(id)
	return { Day = 10, Ids = { id }, Progress = {}, Claimed = {} }
end

test("daily quest picks are deterministic per player", function()
	local a = Quests.forDay(20000, 12345)
	local b = Quests.forDay(20000, 12345)
	eq(#a, 3, "three picks")
	for i = 1, 3 do
		eq(a[i], b[i], "same pick " .. i)
	end
end)

test("daily quest picks are distinct known ids", function()
	local ids = Quests.forDay(20001, 98765)
	eq(#ids, 3, "three picks")
	for i, id in ids do
		assert(Quests.Defs[id], "known quest " .. id)
		for j = i + 1, #ids do
			assert(id ~= ids[j], "duplicate quest " .. id)
		end
	end
end)

test("a new UTC day resets ids progress and claims", function()
	local old = {
		Day = 10,
		Ids = { "Clear the Crowd" },
		Progress = { ["Clear the Crowd"] = 12 },
		Claimed = { ["Clear the Crowd"] = true },
	}
	local fresh = Quests.evaluate(old, 11 * DAY, 44)
	eq(fresh.Day, 11, "new day")
	eq(#fresh.Ids, 3, "new picks")
	eq(next(fresh.Progress), nil, "progress cleared")
	eq(next(fresh.Claimed), nil, "claims cleared")
	eq(old.Day, 10, "input untouched")
end)

test("progress caps at the quest target without mutating input", function()
	local old = stateWith("Clear the Crowd")
	local advanced = Quests.progress(old, "Kills", 500)
	eq(advanced.Progress["Clear the Crowd"], Quests.Defs["Clear the Crowd"].Target, "cap")
	eq(old.Progress["Clear the Crowd"], nil, "input untouched")
end)

test("wave progress records the highest wave", function()
	local old = stateWith("Climb the Waves")
	local atSix = Quests.progress(old, "Wave", 6)
	local stillSix = Quests.progress(atSix, "Wave", 4)
	eq(stillSix.Progress["Climb the Waves"], 6, "does not go backward or add")
end)

test("a complete quest can be claimed only once", function()
	local id = "Finish a Run"
	local complete = Quests.progress(stateWith(id), "Runs", 1)
	local claimed, gems = Quests.claim(complete, id)
	eq(gems, Quests.Defs[id].Gems, "first payout")
	eq(claimed.Claimed[id], true, "marked claimed")
	local again, secondGems = Quests.claim(claimed, id)
	eq(secondGems, 0, "no second payout")
	eq(again.Claimed[id], true, "claim stays set")
	local incomplete, noGems = Quests.claim(stateWith("Clear the Crowd"), "Clear the Crowd")
	eq(noGems, 0, "incomplete does not pay")
	eq(incomplete.Claimed["Clear the Crowd"], nil, "incomplete not claimed")
end)

test("profile sanitize repairs junk quest state", function()
	local p = ProfileSchema.sanitize({
		Quests = {
			Day = 123.9,
			Ids = { "Clear the Crowd", "Bogus", "Clear the Crowd", "Finish a Run", 42 },
			Progress = { ["Clear the Crowd"] = 999, ["Finish a Run"] = -2, Bogus = 5 },
			Claimed = { ["Clear the Crowd"] = true, ["Finish a Run"] = true, Bogus = true },
		},
	})
	eq(p.Quests.Day, 123, "day floored")
	eq(#p.Quests.Ids, 2, "junk and duplicates removed")
	eq(p.Quests.Progress["Clear the Crowd"], Quests.Defs["Clear the Crowd"].Target, "capped")
	eq(p.Quests.Progress["Finish a Run"], nil, "negative dropped")
	eq(p.Quests.Progress.Bogus, nil, "unknown progress dropped")
	eq(p.Quests.Claimed["Clear the Crowd"], true, "known claim kept")
	eq(p.Quests.Claimed["Finish a Run"], nil, "incomplete claim dropped")
	eq(p.Quests.Claimed.Bogus, nil, "unknown claim dropped")

	local clean = ProfileSchema.sanitize({ Quests = "junk" }).Quests
	eq(clean.Day, 0, "default day")
	eq(#clean.Ids, 0, "default ids")
end)
