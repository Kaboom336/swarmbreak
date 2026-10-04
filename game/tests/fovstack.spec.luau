local FovStack = load("FovStack")

local function near(a: number, b: number, epsilon: number, message: string)
	if math.abs(a - b) > epsilon then
		error(string.format("%s: expected %.4f, got %.4f", message, b, a), 2)
	end
end

test("FOV kicks add and decay independently to base", function()
	local stack = FovStack.new(70)
	FovStack.add(stack, 6, 1, 10)
	FovStack.add(stack, 12, 2, 10)

	near(FovStack.valueAt(stack, 10), 88, 1e-6, "both kick offsets add")
	near(FovStack.valueAt(stack, 11), 73, 1e-6, "first kick ends while second continues")
	near(FovStack.valueAt(stack, 12), 70, 1e-6, "all kicks return to base")
end)
