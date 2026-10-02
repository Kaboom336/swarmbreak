local Settings = load("Settings")
local ProfileSchema = load("ProfileSchema")

test("settings default to half volume", function()
	local p = ProfileSchema.default()
	eq(p.MusicVolume, 0.5, "music default")
	eq(p.SfxVolume, 0.5, "SFX default")
	eq(p.MouseLockEnabled, true, "mouse lock default")
end)

test("volume is clamped to its valid range", function()
	eq(Settings.clamp(-2), 0, "low")
	eq(Settings.clamp(0.25), 0.25, "middle")
	eq(Settings.clamp(4), 1, "high")
end)

test("sanitize repairs junk settings", function()
	local p = ProfileSchema.sanitize({
		MusicVolume = "loud",
		SfxVolume = 2,
		MouseLockEnabled = false,
	})
	eq(p.MusicVolume, 0.5, "junk music repaired")
	eq(p.SfxVolume, 1, "SFX clamped")
	eq(p.MouseLockEnabled, false, "mouse lock preserved")

	local q = ProfileSchema.sanitize({
		MusicVolume = -1,
		SfxVolume = 0 / 0,
		MouseLockEnabled = "yes",
	})
	eq(q.MusicVolume, 0, "music clamped")
	eq(q.SfxVolume, 0.5, "NaN repaired")
	eq(q.MouseLockEnabled, true, "junk mouse lock repaired")
end)

test("apply changes only settings", function()
	local p = { MusicVolume = 0.2, SfxVolume = 0.3, MouseLockEnabled = true, Gems = 10 }
	local result = Settings.apply(
		p,
		{ MusicVolume = 0.8, SfxVolume = -1, MouseLockEnabled = false, Gems = 999 }
	)
	eq(result, p, "same profile")
	eq(p.MusicVolume, 0.8, "music applied")
	eq(p.SfxVolume, 0, "SFX applied and clamped")
	eq(p.MouseLockEnabled, false, "mouse lock applied")
	eq(p.Gems, 10, "unrelated fields ignored")
end)
