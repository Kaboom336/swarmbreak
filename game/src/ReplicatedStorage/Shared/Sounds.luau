--!strict
-- Sound library. Every entry is a Roblox built-in client sound (rbxasset://sounds/...), which ships
-- with the Roblox client, needs no upload and no license check. Swap any entry for a Creator Store
-- asset id ("rbxassetid://123") after checking it in Studio. Verify the built-in names on the laptop
-- (Studio prints a warning for a bad path); see ../../ASSETS.md.
local Sounds = {
	-- weapons
	ShotPistol = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Pitch = 1.2 },
	ShotSmg = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.25, Pitch = 1.6 },
	ShotShotgun = { Id = "rbxasset://sounds/Rocket shot.wav", Volume = 0.5, Pitch = 1.3 },
	ShotRifle = { Id = "rbxasset://sounds/Shoulder fired rocket.wav", Volume = 0.4, Pitch = 1.5 },
	ShotEnergy = { Id = "rbxasset://sounds/flashbulb.wav", Volume = 0.4, Pitch = 1.1 },
	ShotCannon = { Id = "rbxasset://sounds/Launching rocket.wav", Volume = 0.6, Pitch = 0.9 },
	-- TODO: Replace these placeholders with a proper approved swoosh sound.
	Swing = { Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.6, Pitch = 1.4 },
	Slam = { Id = "rbxasset://sounds/impact_explosion_02.mp3", Volume = 0.7, Pitch = 1.2 },
	Orb = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.15, Pitch = 2.0 },
	Beam = { Id = "rbxasset://sounds/flashbulb.wav", Volume = 0.2, Pitch = 0.6 },
	-- feedback
	Hit = { Id = "rbxasset://sounds/hit.wav", Volume = 0.3, Pitch = 1.4 },
	Kill = { Id = "rbxasset://sounds/splat.wav", Volume = 0.5, Pitch = 1.0 },
	Hurt = { Id = "rbxasset://sounds/uuhhh.mp3", Volume = 0.5, Pitch = 1.0 },
	Dash = { Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.5, Pitch = 1.8 },
	Jump = { Id = "rbxasset://sounds/action_jump.mp3", Volume = 0.4, Pitch = 1.0 },
	Coin = { Id = "rbxasset://sounds/switch.wav", Volume = 0.3, Pitch = 1.8 },
	Buy = { Id = "rbxasset://sounds/button.wav", Volume = 0.5, Pitch = 1.0 },
	Deny = { Id = "rbxasset://sounds/collide.wav", Volume = 0.4, Pitch = 0.7 },
	Crate = { Id = "rbxasset://sounds/snap.wav", Volume = 0.6, Pitch = 1.0 },
	-- waves / bosses
	WaveStart = { Id = "rbxasset://sounds/bass.wav", Volume = 0.7, Pitch = 0.8 },
	WaveClear = { Id = "rbxasset://sounds/victory.wav", Volume = 0.7, Pitch = 1.0 },
	BossRoar = { Id = "rbxasset://sounds/HalloweenGhost.wav", Volume = 0.9, Pitch = 0.6 },
	BossThunder = { Id = "rbxasset://sounds/HalloweenLightning.wav", Volume = 0.8, Pitch = 0.9 },
	EnemySpawn = { Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.25, Pitch = 0.8 },
	Explosion = { Id = "rbxasset://sounds/impact_explosion_01.mp3", Volume = 0.8, Pitch = 1.0 },
	GameOver = { Id = "rbxasset://sounds/HalloweenLightning.wav", Volume = 0.8, Pitch = 0.5 },
	-- music: 0 = none yet. Pick a Roblox-licensed track from the Creator Store on the laptop.
	Music = { Id = "", Volume = 0.25, Pitch = 1.0 },
}

-- Which shot sound a weapon uses.
Sounds.ForWeapon = {
	Starter = "ShotPistol",
	Burst = "ShotSmg",
	Blade = "Swing",
	Scatter = "ShotShotgun",
	Marksman = "ShotRifle",
	Hammer = "Slam",
	Guardian = "Orb",
	Arc = "ShotEnergy",
	Hornet = "ShotCannon",
	Saber = "Swing",
	Storm = "Orb",
	Ion = "Beam",
	Nova = "ShotCannon",
	Reaper = "Swing",
	Halo = "Orb",
}

return Sounds
