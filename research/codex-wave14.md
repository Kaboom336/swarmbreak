# Codex wave 14 (Swarm Break, 2026-10-02): first playtest fixes

Base: integrate/wave13 0e19333. The freeze is over, so Hud.client, WaveManager and DeathFlow may be edited where a task says so.

Zion 10/2 16:27: "enemies are way too small, shooting might wanna be auto aim like Final Swarm, I didn't get an upgrade, no weapon model or animation, no good animations on anything, models need work."

## Rules (every task)
- Failing spec first. Touch only the listed files plus one spec.
- No blood: goo is teal or green. Prices stay 0. Plain names. No new dependencies.
- Runtime-safe only: no settings(), Lighting.Technology writes, StudioService, plugin, Selection, ChangeHistoryService or TakeScreenshot in game/src.
- In StarterPlayerScripts, always require sibling ModuleScripts via script.Parent:WaitForChild("Name").
- Rojo can't check these at runtime, so list in RESULT (your final summary) every new Instance path the code waits on.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

## G1 Enemies 2-3x bigger, sized by height
Cause: EnemyBuilder.buildImported fits each mesh inside the whole Size box (smallest axis ratio wins), so wide meshes shrink. The camera sits 12 back, so a player-height Walker reads as small.
- Enemies.luau: new heights in studs (player = 5): Walker 10, Runner 8, Spitter 9, Flyer 6 (hovering at 6), Tank 13, Brute 18, Queen 22, Warden 22. Keep footprints roughly proportional.
- EnemyBuilder: scale imported models by height (Fit.sizeForRelativeHeight or a height-only scale). Size the invisible root and hitbox from the scaled extents.
- Check that spawn spacing and WaveManager's wave-1 jitter (±6) still keep bodies apart. Widen to ±10 if needed.
- Spec tests/enemyscale.spec.luau (pure): each type's height ratio to the player is within 10% of target; a wide mesh (10x4x2) fitted to Walker comes out 10 tall.

## G2 Auto-aim and auto-fire, Final Swarm style (on by default)
- Shared/AutoAim.luau (pure): pick a target among enemies within the weapon's Range and in line of sight. Score = distance, weighted toward enemies closing in and bosses. Stick to the current target until it dies or leaves range (hysteresis 15%).
- Shooting.client.luau: when Settings.AutoFire is true (default), fire at FireRate toward the target with no click. The upper body turns toward the target. Manual click aiming stays as an override. Auto-fire is off while a card panel is open.
- Settings.luau: AutoFire (default true). Hud.client: a toggle in settings.
- The server FireGuard is unchanged; auto-fire must fit its cadence.
- Melee: auto-swing when the target is within Range+2.
- Spec tests/autoaim.spec.luau: closest wins; a boss within 1.3x of the closest's distance wins; the current target is kept unless a new one is 15% closer; out of range or blocked means no target; cadence never beats 1/FireRate.

## G3 Weapon in hand, with recoil and swing
Causes: attachWeapon runs right after Humanoid exists, often before RightHand loads, so WeaponModels.attach silently returns. Imported weapon meshes are never scaled.
- WeaponModels.attach: wait for RightHand (or Right Arm) up to 5 s, and re-attach on CharacterAppearanceLoaded.
- Scale imported weapons to a target length per Kind: gun 2.6, rifle 3.4, melee 4.5, orbital emitter 1.2.
- New WeaponFeel.client.luau (procedural, no uploaded animations):
  - Hold pose through right shoulder/elbow Motor6D.Transform, aiming the arm at the target or mouse.
  - Each shot: recoil kick (back 0.25 studs, up 6°, 80 ms out, 120 ms back), a muzzle flash part plus a light for 50 ms, and a small camera kick through Feel.luau.
  - Melee: 80 ms wind-up, 160 ms swing arc, a trail on the blade.
  - Driven from the existing FX remote, or a local shot event.
- Shared/WeaponPose.luau (pure): recoil and swing curves.
- Spec tests/weaponpose.spec.luau: curves start and end at 0, peak at the stated values, and target lengths per Kind match the list.

## G4 Enemy animation: walk, attack, hit and death
Cause: imported enemies are welded statues (WeldConstraints to the root), so EnemyAnimator finds no Motor6Ds.
- EnemyBuilder.buildImported: join limbs with Motor6Ds named the way EnemyAnimator expects (Hip_L/R, Shoulder_L/R, Neck, Jaw, Wing_n, Leg_n), using part names from ModelParts. If a mesh lacks limb parts, fall back to the part-built rig at the G1 height, and name the types that fell back in RESULT.
- EnemyAnimator.client:
  - Walk cycle speed scales with velocity.
  - Attack: a wind-up that matches EnemyTells timing, then a lunge.
  - Hit flinch: 0.12 s squash plus a white flash (existing highlight).
  - Death: collapse, a teal goo burst, then dissolve over 0.6 s (never red).
  - Respect the AnimCull distance.
- Shared/EnemyAnimCurves.luau (pure).
- Spec tests/enemyanim.spec.luau: walk phase advances with speed; the attack wind-up equals the tell duration; the death sequence totals <= 1.0 s; the curves are bounded.

## G5 Player animation feel
- New PlayerFeel.client.luau (procedural Motor6D.Transform layered on top of the default Animate):
  - Lean into the run direction up to 8°.
  - Dash: stretch, lean forward 15°, and a short trail.
  - Hit: flinch 0.1 s.
  - Level-up: a pop with a ring burst.
- Shared/PlayerPose.luau (pure).
- Spec tests/playerpose.spec.luau: lean is bounded and decays to 0 at rest; the dash pose returns to neutral within 0.3 s.

## G6 Sounds and Studio telemetry
- Sounds.luau: Swing and Dash use rbxasset://sounds/swoosh.wav, which Studio reports as "not approved". Point both at an asset ID already used and working elsewhere in Sounds.luau, with a different Pitch, and leave a TODO for a proper sound.
- Telemetry.luau: when RunService:IsStudio(), also print("[funnel] " .. name, fields-as-text) so playtests show run_start, first_hit, first_kill and first_levelup in Output.
- Spec: Sounds has no rbxasset://sounds/swoosh.wav; every Id is "rbxassetid://<n>" or on an allowed list; the telemetry formatter is pure and stable.

## L1 add-on (L1b)
Extend the L1 lint: in StarterPlayerScripts, flag require(script.Parent.X) without WaitForChild.

## M1 Humanoid enemies as real R15 rigs (art track, after G1)
Why: Hunty Zombie's enemies are R15 humanoid rigs with stylized parts, so they get real walk and attack animation for free.
- Walker, Runner, Spitter and Brute: build them with Players:CreateHumanoidModelFromDescription(HumanoidDescription), with body colors from Theme. Attach our uploaded meshes as accessories (head, back spikes, glow parts). Then Model:ScaleTo the G1 height.
- Play Roblox's default R15 walk and run through an Animator, with the G4 procedural overlays for attack, flinch and death.
- Flyer, Tank, Queen and Warden stay on G4 creature rigs.
- Spec tests/humanoidenemy.spec.luau (pure config): each humanoid type has a description table, body colors with contrast >= 3 against the floor, and the G1 target heights.

Order: G1, then G2 and G3 in sequence (both touch Shooting and FX), then G4, then G5 and G6, then M1. After the wave lands, the Roblox game thread combines and reviews it, and the laptop replays the 2-minute test.
