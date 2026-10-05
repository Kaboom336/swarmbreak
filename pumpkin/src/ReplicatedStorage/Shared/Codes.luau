--!strict
local Codes = {}

function Codes.normalize(input: string): string
	return string.upper((string.gsub(input, "^%s*(.-)%s*$", "%1")))
end

function Codes.redeem(
	redeemed: { [string]: boolean },
	codeList: { [string]: any },
	input: string
): (boolean, any?, string)
	local code = Codes.normalize(input)
	if code == "" or codeList[code] == nil then
		return false, nil, "INVALID"
	end
	if redeemed[code] then
		return false, nil, "USED"
	end
	redeemed[code] = true
	return true, codeList[code], "OK"
end

return Codes
