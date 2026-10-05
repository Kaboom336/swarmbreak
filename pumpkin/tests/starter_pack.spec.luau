--!strict
local StarterPack = load("StarterPack")

test("starter pack grants only once across repeated purchase callbacks", function()
	local grants = 0
	local completed, granted = StarterPack.purchase(false, function()
		grants += 1
		return true
	end)
	eq(completed, true, "first receipt completed")
	eq(granted, true, "first receipt granted")
	completed, granted = StarterPack.purchase(true, function()
		grants += 1
		return true
	end)
	eq(completed, true, "repeat receipt completed")
	eq(granted, false, "repeat did not grant")
	eq(grants, 1, "one grant total")
end)

test("starter pack does not mark a failed grant complete", function()
	local completed, granted = StarterPack.purchase(false, function()
		return false
	end)
	eq(completed, false, "failed grant retries")
	eq(granted, false, "failed grant")
end)
