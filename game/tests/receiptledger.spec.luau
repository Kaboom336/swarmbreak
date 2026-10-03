local ReceiptLedger = load("ReceiptLedger")
local Monetization = load("Monetization")

test("purchase ids must be bounded nonblank strings", function()
	eq(ReceiptLedger.isValidPurchaseId("purchase-1"), true, "normal id")
	eq(ReceiptLedger.isValidPurchaseId(""), false, "empty")
	eq(ReceiptLedger.isValidPurchaseId("   "), false, "blank")
	eq(ReceiptLedger.isValidPurchaseId(123), false, "number")
	eq(
		ReceiptLedger.isValidPurchaseId(string.rep("x", ReceiptLedger.MaxPurchaseIdLength + 1)),
		false,
		"too long"
	)
end)

test("duplicate delivery is acknowledged without another grant", function()
	local history = {}
	eq(ReceiptLedger.decide(history, "purchase-1", true, true), "Grant", "first delivery")
	history = ReceiptLedger.record(history, "purchase-1")
	eq(ReceiptLedger.decide(history, "purchase-1", true, true), "AlreadyGranted", "retry")
	eq(#history, 1, "one ledger entry")
end)

test("oldest receipts are evicted in delivery order", function()
	local history = {}
	for index = 1, ReceiptLedger.MaxEntries + 2 do
		history = ReceiptLedger.record(history, "purchase-" .. index)
	end
	eq(#history, ReceiptLedger.MaxEntries, "bounded")
	eq(history[1], "purchase-3", "oldest retained")
	eq(history[#history], "purchase-" .. ReceiptLedger.MaxEntries + 2, "newest retained")
end)

test("corrupt history is sanitized and newest duplicate wins", function()
	local history = ReceiptLedger.sanitize({
		"old",
		42,
		"",
		"duplicate",
		"middle",
		"duplicate",
		string.rep("x", ReceiptLedger.MaxPurchaseIdLength + 1),
	})
	eq(#history, 3, "only valid unique ids")
	eq(history[1], "old", "oldest")
	eq(history[2], "middle", "middle")
	eq(history[3], "duplicate", "newest duplicate position")
	eq(#ReceiptLedger.sanitize("broken"), 0, "non-table")
end)

test("unavailable players and unknown products stay retryable", function()
	eq(ReceiptLedger.decide({}, "purchase-1", true, false), "Retry", "player")
	eq(ReceiptLedger.decide({}, "purchase-1", false, true), "Retry", "product")
	eq(ReceiptLedger.decide({}, nil, true, true), "Retry", "purchase id")
end)

test("every granted product kind gets duplicate protection", function()
	local expectedKinds = {
		Coins500 = "Coins",
		Coins1500 = "Coins",
		WeaponCrate = "BasicCrate",
		EpicCrate = "EpicCrate",
		Revive = "Revive",
	}
	for key, kind in expectedKinds do
		eq(ReceiptLedger.productKind(key, Monetization.DeveloperProducts[key]), kind, key)
		local purchaseId = "purchase-" .. key
		local history = ReceiptLedger.record({}, purchaseId)
		eq(ReceiptLedger.decide(history, purchaseId, true, true), "AlreadyGranted", key)
	end
	eq(
		ReceiptLedger.productKind(
			"DoubleRunRewards",
			Monetization.DeveloperProducts.DoubleRunRewards
		),
		nil,
		"unimplemented product"
	)
end)
