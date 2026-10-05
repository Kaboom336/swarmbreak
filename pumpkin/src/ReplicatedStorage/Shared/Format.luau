--!strict

local Format = {}

local SUFFIXES = {
	{ value = 1e12, suffix = "T" },
	{ value = 1e9, suffix = "B" },
	{ value = 1e6, suffix = "M" },
	{ value = 1e3, suffix = "K" },
}

local function trimDecimal(value: string): string
	return (value:gsub("%.0$", ""))
end

function Format.abbrev(value: number): string
	local absolute = math.abs(value)
	for _, entry in SUFFIXES do
		if absolute >= entry.value then
			return trimDecimal(string.format("%.1f", value / entry.value)) .. entry.suffix
		end
	end
	local rounded = if value >= 0 then math.floor(value + 0.5) else math.ceil(value - 0.5)
	return tostring(rounded)
end

return Format
