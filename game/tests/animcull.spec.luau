local AnimCull = load("AnimCull")

test("near on-screen enemies always update", function()
	for frame = 1, AnimCull.FarEvery * 2 do
		eq(
			AnimCull.shouldUpdate(AnimCull.FullDistance - 1, true, 1, frame),
			true,
			"frame " .. frame
		)
	end
end)

test("far enemies update exactly once every FarEvery frames", function()
	local updates = 0
	for frame = 1, AnimCull.FarEvery do
		if AnimCull.shouldUpdate(AnimCull.FullDistance + 1, true, 1, frame) then
			updates += 1
		end
	end
	eq(updates, 1, "one update")
end)

test("far enemy updates are staggered by enemy index", function()
	local firstFrame = nil
	local secondFrame = nil
	for frame = 1, AnimCull.FarEvery do
		if AnimCull.shouldUpdate(AnimCull.FullDistance + 1, true, 1, frame) then
			firstFrame = frame
		end
		if AnimCull.shouldUpdate(AnimCull.FullDistance + 1, true, 2, frame) then
			secondFrame = frame
		end
	end
	assert(firstFrame ~= nil, "first enemy must update")
	assert(secondFrame ~= nil, "second enemy must update")
	assert(firstFrame ~= secondFrame, "far enemies must update on different frames")
end)

test("off-screen far enemies never update", function()
	for frame = 1, AnimCull.FarEvery * 2 do
		eq(
			AnimCull.shouldUpdate(AnimCull.FullDistance + 1, false, 1, frame),
			false,
			"frame " .. frame
		)
	end
end)

test("exactly FullDistance is near", function()
	for frame = 1, AnimCull.FarEvery do
		eq(
			AnimCull.shouldUpdate(AnimCull.FullDistance, true, 1, frame),
			true,
			"boundary frame " .. frame
		)
		eq(
			AnimCull.shouldUpdate(AnimCull.FullDistance, false, 1, frame),
			true,
			"off-screen boundary frame " .. frame
		)
	end
end)
