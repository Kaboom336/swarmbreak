local Invite = load("Invite")

test("invite is only offered to a player alone in the server", function()
	eq(Invite.shouldShow(2, "summary", nil, 1000), false, "two players")
	eq(Invite.shouldShow(5, "death", nil, 1000), false, "many players")
end)

test("the first invite offer is allowed", function()
	eq(Invite.shouldShow(1, "summary", nil, 1000), true, "first summary")
	eq(Invite.shouldShow(1, "death", nil, 1000), true, "first death")
end)

test("invite offers respect the cooldown", function()
	local lastShownAt = 1000
	eq(Invite.shouldShow(1, "death", lastShownAt, 1001), false, "inside cooldown")
	eq(
		Invite.shouldShow(1, "summary", lastShownAt, lastShownAt + Invite.CooldownSec),
		true,
		"cooldown elapsed"
	)
end)

test("unknown moments do not show an invite", function()
	eq(Invite.shouldShow(1, "lobby", nil, 1000), false, "unknown moment")
end)

test("nil lastShownAt means an invite has never been shown", function()
	eq(Invite.shouldShow(1, "summary", nil, 0), true, "never shown")
end)
