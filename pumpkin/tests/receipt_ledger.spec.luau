--!strict
local ReceiptLedger = load("ReceiptLedger")

test("receipt ledger records before grant and grants only once", function()
	local receipts = {}
	local grants = 0
	local function grant()
		eq(receipts.purchase_1, true, "receipt reserved before grant")
		grants += 1
		return true
	end

	local ok, granted = ReceiptLedger.process(receipts, "purchase_1", grant)
	eq(ok, true, "first receipt succeeds")
	eq(granted, true, "first receipt grants")
	ok, granted = ReceiptLedger.process(receipts, "purchase_1", grant)
	eq(ok, true, "duplicate is already complete")
	eq(granted, false, "duplicate does not grant")
	eq(grants, 1, "exactly one grant")
end)

test("failed receipt grants release their reservation for retry", function()
	local receipts = {}
	local ok = ReceiptLedger.process(receipts, "purchase_2", function()
		return false
	end)
	eq(ok, false, "failed grant")
	eq(receipts.purchase_2, nil, "reservation released")
end)
