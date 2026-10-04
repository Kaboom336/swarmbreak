--!strict
-- Sound library. rbxassetid entries are verified-creator Creator Store clips picked on the laptop
-- (10/2, H8); confirm each loads in Studio Output. The rest are Roblox built-in client sounds (rbxasset://sounds/...), which ships
-- with the Roblox client, needs no upload and no license check. Swap any entry for a Creator Store
-- asset id ("rbxassetid://123") after checking it in Studio. Verify the built-in names on the laptop
-- (Studio prints a warning for a bad path); see ../../ASSETS.md.
local Sounds = {
	-- weapons
	ShotPistol = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.35, Pitch = 1.2 },
	ShotSmg = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.25, Pitch = 1.6 },
	ShotShotgun = { Id = "rbxasset://sounds/Rocket shot.wav", Volume = 0.5, Pitch = 1.3 },
	ShotRifle = { Id = "rbxasset://sounds/Shoulder fired rocket.wav", Volume = 0.4, Pitch = 1.5 },
	ShotEnergy = { Id = "rbxassetid://137510557013265", Volume = 0.4, Pitch = 1.0 },
	ShotCannon = { Id = "rbxasset://sounds/Launching rocket.wav", Volume = 0.6, Pitch = 0.9 },
	Swing = { Id = "rbxassetid://15674975792", Volume = 0.6, Pitch = 1.0 },
	Slam = { Id = "rbxasset://sounds/impact_explosion_02.mp3", Volume = 0.7, Pitch = 1.2 },
	Orb = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.15, Pitch = 2.0 },
	Beam = { Id = "rbxasset://sounds/flashbulb.wav", Volume = 0.2, Pitch = 0.6 },
	-- feedback
	Hit = { Id = "rbxassetid://98609496290942", Volume = 0.3, Pitch = 1.0 }, -- alt 131554175554758
	HitMarker = { Id = "rbxassetid://110940518591889", Volume = 0.25, Pitch = 1.0 },
	Kill = { Id = "rbxassetid://116062165012558", Volume = 0.5, Pitch = 1.0 }, -- alt 9119559518
	KillCrunch = { Id = "rbxassetid://116062165012558", Volume = 0.5, Pitch = 0.86 },
	KillGoo = { Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.35, Pitch = 0.8 },
	KillTick = { Id = "rbxassetid://110940518591889", Volume = 0.35, Pitch = 1.15 },
	Hurt = { Id = "rbxasset://sounds/uuhhh.mp3", Volume = 0.5, Pitch = 1.0 },
	Dash = { Id = "rbxassetid://119573908217733", Volume = 0.5, Pitch = 1.0 }, -- alt 15674975792
	Jump = { Id = "rbxasset://sounds/action_jump.mp3", Volume = 0.4, Pitch = 1.0 },
	Coin = { Id = "rbxassetid://135483737426662", Volume = 0.3, Pitch = 1.0 },
	LevelUp = { Id = "rbxassetid://112485797063762", Volume = 0.6, Pitch = 1.0 },
	CardPick = { Id = "rbxassetid://3406813517", Volume = 0.5, Pitch = 1.0 },
	Buy = { Id = "rbxasset://sounds/button.wav", Volume = 0.5, Pitch = 1.0 },
	Deny = { Id = "rbxasset://sounds/collide.wav", Volume = 0.4, Pitch = 0.7 },
	Crate = { Id = "rbxasset://sounds/snap.wav", Volume = 0.6, Pitch = 1.0 },
	-- waves / bosses
	WaveStart = { Id = "rbxassetid://6085123331", Volume = 0.7, Pitch = 1.0 },
	WaveClear = { Id = "rbxasset://sounds/victory.wav", Volume = 0.7, Pitch = 1.0 },
	BossRoar = { Id = "rbxasset://sounds/HalloweenGhost.wav", Volume = 0.9, Pitch = 0.6 },
	BossThunder = { Id = "rbxasset://sounds/HalloweenLightning.wav", Volume = 0.8, Pitch = 0.9 },
	EnemySpawn = { Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.25, Pitch = 0.8 },
	Explosion = { Id = "rbxasset://sounds/impact_explosion_01.mp3", Volume = 0.8, Pitch = 1.0 },
	GameOver = { Id = "rbxasset://sounds/HalloweenLightning.wav", Volume = 0.8, Pitch = 0.5 },
	-- Music: Roblox licensed-partner tracks picked on the laptop (10/03). Backups: fight
	-- 1837768143 "Big League (c)", lobby 102758532653468 "Grand Lobby Calm".
	Music = { Id = "rbxassetid://1837768013", Volume = 0.25, Pitch = 1.0 }, -- "Rise to the Top (c)", APM
	LobbyMusic = { Id = "rbxassetid://101945305370690", Volume = 0.2, Pitch = 1.0 }, -- "ROBOTS DREAMING OF RAIN"
}

-- Fight loop in the arena, calm loop in the lobby (InArena is set by LobbyBuilder).
function Sounds.musicFor(inArena: boolean): { Id: string, Volume: number, Pitch: number }
	return if inArena then Sounds.Music else Sounds.LobbyMusic
end

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
