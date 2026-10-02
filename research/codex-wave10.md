# Codex wave 10: Hunty Zombie lead-reference features (+ watch round 2)
Base: main after wave 8/9 merge (until then, branch from integrate/wave8). Sources: /mnt/project-files/swarmbreak-hunty-zombie-deep.md, swarmbreak-watch-round2.md, research/BEST-OF.md.
Rules: failing spec first, listed files only, no blood (bug goo is teal/green, never red), all prices 0.
testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && rojo build default.project.json -o out.rbxl

## A1 Start Here pad + SELECT panel (Hunty #1)
Base lobby pad "Start Here" opens one panel: map, difficulty, mode, party size (1-8), friends only, CREATE. Joins/creates an arena party and teleports (reuse existing matchmaking/TeleportService code). Shared/PartyConfig.luau pure validation.
Spec tests/partyconfig.spec.luau: party size clamps 1-8; friends-only flag respected; invalid map/difficulty rejected.

## A2 Left icon column + giant money counter (Hunty #2)
Left column of square colour-coded icons with hotkeys (Inventory, Kits, Quests, Shop, Settings); right column Codes, Pass, Rewards, Guides. Shared/HudLayout.luau entries (extends wave 9 T6).
Spec: hotkeys unique; icons >= 44 px at 1334x750; no overlap with T6 elements.

## A3 Boss poster intro (Hunty #5)
Full-screen poster card (boss name, title line, element colour) with a 1.5-2 s slam-in animation before boss waves; skippable after first view. Extend BossIntro.
Spec: duration in range; each boss has poster data.

## A4 Weapon mastery card (Hunty #6)
Always-visible small card: current weapon, mastery level, progress bar; mastery XP per kill with that weapon; unlocks a cosmetic tier per level. Shared/Mastery.luau pure.
Spec tests/mastery.spec.luau: XP curve monotonic; level-up at thresholds; save shape stable.

## A5 Juice extras (Hunty #3 + Battlegrounds)
Floor goo decals that fade (teal/green), ground cracks + debris burst on boss slams and big-bug landings, coin bursts that fly to the player. Extend VfxDefs (wave 9 T2) with Goo, Crack, Debris, CoinBurst.
Spec: decals fade out <= 6 s; max live decals cap; colours never red.

## A6 Reactor core + objective line + threat banner (99 Nights, Forsaken, Brainrot)
Station reactor core charged by wave clears, big floating counter (e.g. "Core 3/5"); one objective line always visible under the timer; red banner "The swarm is breaching the core!" when enemies reach it. Shared/Objectives.luau pure.
Spec: objective text exists for every wave state; banner fires once per breach with cooldown.

Order: A1, A3, A4, A2, A5, A6.
