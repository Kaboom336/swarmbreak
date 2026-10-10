# R24 plan (arena r23 merged by Claude + Zion's follow-ups)

## 1. Speed upgrades (KEEP, capped) — Zion: "upgradable speed like Pet Simulator"
- "Boots" track in the Shop Upgrades tab: walk speed 16 → 18 / 20 / 22 / 24 / 26 at 500 / 5k / 60k / 600k / 6M candy. Hard cap 26; sprint stays x1.25 on top. Saved; kept on Rebirth.
- Guards chase at 0.9 x (16 + 0.75 x (speed − 16)), so speed helps but guards and their twists still matter.
- Re-run scene/econ-sim.luau with boots bought when affordable; arrivals must stay within ±25% of targets (retune boot prices, not gates).

## 2. The Purge (CHANGE, limited) — BUILD LATER (R25), only after sections 1,3,4,5,6 are tested — Zion: "ghosts and players can steal, lock and bonk like Steal a Brainrot"
- Schedule: at :10 and :50 each hour (King Night is :00/:20/:40; Spooky Hour must not overlap — shift Spooky to :30 only if it collides). 30 s warning banner + siren, lasts 2 min, red-purple tint (light, readable), HUD chip "THE PURGE 1:42".
- Ghosts raid every unprotected base once: take the owner's worst pet (existing raid rules, recoverable stash ghost).
- Players may steal any pet from other players' bases during the Purge except the owner's single best pet; hold E 2 s; one steal per victim per Purge. Owner bonks the thief (existing bonk) within 10 s or before the thief reaches their own pen → pet returns.
- Protections: players in their first 15 min of playtime are immune and can't steal; AFK 45 s+ auto-locks; each player gets one free 60 s lock per Purge (LOCK prompt + HUD button during Purge only).
- Rewards: each successful bonk/defence pays 250 x zone-tier candy; ending the Purge with nothing lost gives a "Purge Survivor" toast + 1 free mystery pumpkin from your best unlocked zone (once per Purge).

## 3. Bigger lobby (KEEP) — "so people have distance"
- Hub grows to 340 x 220 studs (X 1330..1670, Z −70..150); lane mouth stays at Z 150, X 1440..1560. 8 pens 36x30 on a ring around the King with ≥ 50-stud spacing. Built in Studio (scene/Lobby.luau updated by Claude).

## 4. Teleport (CHANGE: everyone, free) — "for low level people"
- A small HUD button (counts as the 3rd always-on button) opening 3 targets: My Pen, Zone Gate (furthest unlocked zone), Shop. Free, 10 s cooldown. Blocked while carrying a stolen or nest pumpkin, while a guard is chasing you, in a FIGHT, or while stealing during the Purge. Also hub pads not needed.

## 5. Pumpkins way bigger + pets roam (Zion)
- Mystery pumpkins: nest size 3-4 studs (Zone 1) up to 6-7.5 studs (late zones); in the pen they scale with rarity + weight to 15-40 studs (height ≈ 0.6 x kg^(1/4) ch, clamp); disc/dome scale with them; carried pumpkin capped at 4 studs.
- Hatched pets roam the whole pen like Steal an Egg: client-side random walk inside the pen Soil bounds (−2 studs), 4-6 studs/s with hop bob, face the move direction, idle 1-3 s between walks; steal prompt and income tag follow the pet.

## 6. Bugs seen while watching Zion
- Rotating order "Hit the King 15 times" (target "king") is dealt when no King is awake, so the banner says "Hit the Pumpkin King!" with nothing to hit. Only deal king orders while King Night is active (or swap the order out when it ends), and never make them the banner goal otherwise.
- Banner sub-line shows raw quest text "[ ] Smash 4/50 [x] Steal [x] Own pet | Next gate -25%": show only the current goal; put zone quest checkboxes in a small panel/tooltip.

Cut: Robux speed above cap, player-to-player teleport, Purge overlapping King Night.


## Build order
R24 = sections 6 (bugs, incl. a sweep of every tutorial/rotating order for targets that may not exist live), 5, 1, 4, 7 (+ lobby by Claude in Studio). R25 = section 2 (The Purge). Re-run econ sim after Boots.

## 7. Arena r24 (merged by Claude): bigger walking King, scythe dash, guard speed by zone
- King Night King 28 studs tall. Phase 1 stays on the plinth. Phase 2 and 3 (below 66% HP): walks between 4 pads on an 80x50 ring around the plinth at 10 studs/s, pauses 3 s at each pad. Attacks only while planted (1.2 s windup, floor decal sized to the hit, stomp sound). Walking contact does no damage. Never chases or leaves the ring.
- Scythe Dash (unlocks with scythe tier 2): 16 studs forward, 5 s cooldown, PC Q / mobile button beside Jump. Server validates distance (raycast-clamped, no wall clipping) and cooldown. Disabled while carrying a nest or stolen pumpkin and during the Purge. Counts as part of the "max 3 buttons" only on mobile.
- Guard chase speed = fraction of the player's current top speed: Z1 0.70, Z2 0.75, Z3 0.80, Z4 0.85, Z5 0.90, Z6 0.93, Z7 0.95 (replaces section 1's formula). A clean runner always escapes; mistakes and twists catch you.
- Zone lengths stay 160 for launch. After launch: longer zones 5-7, Leap (tier 4), King Phase 3 double-ring.
- Re-run econ sim with Boots + dash.
