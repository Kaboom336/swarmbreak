--!strict
local ReceiptLedger = {}

function ReceiptLedger.process(
	receipts: { [string]: boolean },
	purchaseId: string,
	grant: () -> boolean?
): (boolean, boolean)
	if receipts[purchaseId] then
		return true, false
	end

	-- Reserve first so a duplicate callback cannot grant twice.
	receipts[purchaseId] = true
	local ok, result = pcall(grant)
	if not ok or result == false then
		receipts[purchaseId] = nil
		return false, false
	end
	return true, true
end

return ReceiptLedger
