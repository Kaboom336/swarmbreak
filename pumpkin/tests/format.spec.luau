--!strict
local Format = load("Format")

test("abbreviates HUD numbers without trailing zeroes", function()
	eq(Format.abbrev(48), "48", "whole number")
	eq(Format.abbrev(48.0), "48", "whole-valued decimal")
	eq(Format.abbrev(1_200), "1.2K", "thousands")
	eq(Format.abbrev(3_400_000), "3.4M", "millions")
	eq(Format.abbrev(1_000), "1K", "exact suffix")
	eq(Format.abbrev(2_000_000_000), "2B", "billions")
end)

test("rounds unsuffixed HUD numbers to whole numbers", function()
	eq(Format.abbrev(47.6), "48", "positive decimal")
	eq(Format.abbrev(-47.6), "-48", "negative decimal")
end)
