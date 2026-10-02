local Settings = load("Settings")
local ProfileSchema = load("ProfileSchema")

test("settings have accessible defaults", function()
	local p = ProfileSchema.default()
	eq(p.MusicVolume, 0.5, "music default")
	eq(p.SfxVolume, 0.5, "SFX default")
	eq(p.MouseLockEnabled, true, "mouse lock default")
	eq(p.AutoAim, true, "auto aim default")
	eq(p.AimAssistStrength, 1, "aim assist default")
	eq(p.UiScale, 1, "UI scale default")
	eq(p.LeftHanded, false, "left-handed default")
	eq(p.ReduceMotion, false, "reduce motion default")
	eq(p.Mute, false, "mute default")
end)

test("volume is clamped to its valid range", function()
	eq(Settings.clamp(-2), 0, "low")
	eq(Settings.clamp(0.25), 0.25, "middle")
	eq(Settings.clamp(4), 1, "high")
	eq(Settings.clampAimAssistStrength(-1), 0, "aim assist low")
	eq(Settings.clampAimAssistStrength(2), 1, "aim assist high")
	eq(Settings.clampUiScale(0.1), Settings.MinUiScale, "UI scale low")
	eq(Settings.clampUiScale(2), Settings.MaxUiScale, "UI scale high")
end)

test("sanitize repairs junk settings", function()
	local p = ProfileSchema.sanitize({
		MusicVolume = "loud",
		SfxVolume = 2,
		MouseLockEnabled = false,
		AutoAim = "yes",
		AimAssistStrength = 9,
		UiScale = -3,
		LeftHanded = true,
		ReduceMotion = "no",
		Mute = true,
	})
	eq(p.MusicVolume, 0.5, "junk music repaired")
	eq(p.SfxVolume, 1, "SFX clamped")
	eq(p.MouseLockEnabled, false, "mouse lock preserved")
	eq(p.AutoAim, true, "junk auto aim repaired")
	eq(p.AimAssistStrength, 1, "aim assist clamped")
	eq(p.UiScale, Settings.MinUiScale, "UI scale clamped")
	eq(p.LeftHanded, true, "left-handed preserved")
	eq(p.ReduceMotion, false, "junk reduce motion repaired")
	eq(p.Mute, true, "mute preserved")

	local q = ProfileSchema.sanitize({
		MusicVolume = -1,
		SfxVolume = 0 / 0,
		MouseLockEnabled = "yes",
	})
	eq(q.MusicVolume, 0, "music clamped")
	eq(q.SfxVolume, 0.5, "NaN repaired")
	eq(q.MouseLockEnabled, true, "junk mouse lock repaired")
end)

test("old profiles safely migrate new settings", function()
	local old = { Version = 1, MusicVolume = 0.25, MouseLockEnabled = false, Gems = 7 }
	local p = ProfileSchema.sanitize(old)
	eq(p.MusicVolume, 0.25, "old music preserved")
	eq(p.MouseLockEnabled, false, "old mouse lock preserved")
	eq(p.AutoAim, Settings.DefaultAutoAim, "auto aim added")
	eq(p.AimAssistStrength, Settings.DefaultAimAssistStrength, "aim assist added")
	eq(p.UiScale, Settings.DefaultUiScale, "UI scale added")
	eq(p.LeftHanded, Settings.DefaultLeftHanded, "left-handed added")
	eq(p.ReduceMotion, Settings.DefaultReduceMotion, "reduce motion added")
	eq(p.Mute, Settings.DefaultMute, "mute added")
	eq(p.Gems, 7, "unrelated saved data preserved")
end)

test("apply returns an immutable settings update", function()
	local p = {
		MusicVolume = 0.2,
		SfxVolume = 0.3,
		MouseLockEnabled = true,
		AutoAim = true,
		AimAssistStrength = 1,
		UiScale = 1,
		LeftHanded = false,
		ReduceMotion = false,
		Mute = false,
		Gems = 10,
	}
	local result = Settings.apply(p, {
		MusicVolume = 0.8,
		SfxVolume = -1,
		MouseLockEnabled = false,
		AutoAim = false,
		AimAssistStrength = 0.4,
		UiScale = 4,
		LeftHanded = true,
		ReduceMotion = true,
		Mute = true,
		Gems = 999,
	})
	assert(result ~= p, "apply returns a new profile")
	eq(p.MusicVolume, 0.2, "original profile unchanged")
	eq(result.MusicVolume, 0.8, "music applied")
	eq(result.SfxVolume, 0, "SFX applied and clamped")
	eq(result.MouseLockEnabled, false, "mouse lock applied")
	eq(result.AutoAim, false, "auto aim applied")
	eq(result.AimAssistStrength, 0.4, "aim assist applied")
	eq(result.UiScale, Settings.MaxUiScale, "UI scale applied and clamped")
	eq(result.LeftHanded, true, "left-handed applied")
	eq(result.ReduceMotion, true, "reduce motion applied")
	eq(result.Mute, true, "mute applied")
	eq(result.Gems, 10, "unrelated fields ignored")
end)
