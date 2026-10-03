--!strict
-- Pure helpers for remembering developer-product receipts without letting profiles grow forever.
local ReceiptLedger = {
	MaxEntries = 50,
	MaxPurchaseIdLength = 128,
	Decisions = {
		Grant = "Grant",
		AlreadyGranted = "AlreadyGranted",
		Retry = "Retry",
	},
}

export type Decision = "Grant" | "AlreadyGranted" | "Retry"
export type ProductKind = "Coins" | "BasicCrate" | "EpicCrate" | "Revive"

-- Classifies only products this server can actually fulfill. A configured but unimplemented
-- product must remain retryable instead of being acknowledged without its reward.
function ReceiptLedger.productKind(productKey: any, product: any): ProductKind?
	if type(productKey) ~= "string" or type(product) ~= "table" then
		return nil
	end
	if type(product.Coins) == "number" and product.Coins > 0 then
		return "Coins"
	elseif productKey == "WeaponCrate" then
		return "BasicCrate"
	elseif productKey == "EpicCrate" then
		return "EpicCrate"
	elseif productKey == "Revive" then
		return "Revive"
	end
	return nil
end

function ReceiptLedger.isValidPurchaseId(value: any): boolean
	return type(value) == "string"
		and #value > 0
		and #value <= ReceiptLedger.MaxPurchaseIdLength
		and not value:match("^%s*$")
end

-- Returns a new oldest-to-newest list. The newest occurrence of a duplicate wins.
function ReceiptLedger.sanitize(raw: any): { string }
	if type(raw) ~= "table" then
		return {}
	end

	local reversed = {}
	local seen = {}
	for index = #raw, 1, -1 do
		local purchaseId = raw[index]
		if ReceiptLedger.isValidPurchaseId(purchaseId) and not seen[purchaseId] then
			seen[purchaseId] = true
			table.insert(reversed, purchaseId)
			if #reversed == ReceiptLedger.MaxEntries then
				break
			end
		end
	end

	local clean = {}
	for index = #reversed, 1, -1 do
		table.insert(clean, reversed[index])
	end
	return clean
end

function ReceiptLedger.contains(history: any, purchaseId: any): boolean
	if not ReceiptLedger.isValidPurchaseId(purchaseId) then
		return false
	end
	for _, existing in ReceiptLedger.sanitize(history) do
		if existing == purchaseId then
			return true
		end
	end
	return false
end

-- Returns a new list with purchaseId newest. Old entries fall off the front at the bound.
function ReceiptLedger.record(history: any, purchaseId: any): { string }
	local clean = ReceiptLedger.sanitize(history)
	if not ReceiptLedger.isValidPurchaseId(purchaseId) then
		return clean
	end

	local nextHistory = {}
	for _, existing in clean do
		if existing ~= purchaseId then
			table.insert(nextHistory, existing)
		end
	end
	table.insert(nextHistory, purchaseId)
	if #nextHistory > ReceiptLedger.MaxEntries then
		table.remove(nextHistory, 1)
	end
	return nextHistory
end

-- The server acknowledges duplicates, grants only new known receipts, and retries everything else.
function ReceiptLedger.decide(
	history: any,
	purchaseId: any,
	productAvailable: boolean,
	playerAvailable: boolean
): Decision
	if
		not productAvailable
		or not playerAvailable
		or not ReceiptLedger.isValidPurchaseId(purchaseId)
	then
		return ReceiptLedger.Decisions.Retry
	end
	if ReceiptLedger.contains(history, purchaseId) then
		return ReceiptLedger.Decisions.AlreadyGranted
	end
	return ReceiptLedger.Decisions.Grant
end

return ReceiptLedger
