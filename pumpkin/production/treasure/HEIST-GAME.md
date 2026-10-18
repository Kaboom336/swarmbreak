# Steal a Treasure: Heists

2026-10-18. Owner-authorized direction; gameplay proposal plus one greybox proof.
Pitch: **Steal ridiculous toys. Escape with friends. Fill your vault.**

## The game

Your hideout is a public bragging space around a heist board. Walk up, pick a toy,
and break in immediately, alone or alongside friends. Each heist aims for a 2–4 minute
run; this is a pacing hypothesis, not measured playtime. No lobby vote or mandatory
party. Return through the getaway with the actual haul, bank it, and see it in your
vault. Repeat because you have a different stunt in mind.

Shared structure: **break in → grab the toy → make a chaotic getaway → bank haul**.
The acquisition and escape verbs differ by toy. The board is a doorway to play,
not a list of chores. One run clock, one bank balance, one contextual action.

## First two shipping heists

| Heist | What you DO | Guardian and getaway | Friends / reversal |
|---|---|---|---|
| **1. Roll Up the Vault** | Push a physical gold ball; sweep coins, then goblets, chairs, safes, crowns and the baron's hat as it grows. Shove it into a route or another ball. | Baron Bumble shouts and locks a red charge lane before bowling forward. Bait him into cover, scoop the spill, or shove your haul through the wide escape. | Each thief has a ball in the shared room. Help push a friend's ball or ram a rival so a few attachments spill. Anyone can collect loose loot; the old owner can take it back. |
| **2. Steal the King's Bed** | Grab a bed handle, pull quickly solo, carve turns, release to surf down a ramp, catch the bed again. | The king is the cargo. Crashes bounce his crown and wake him; an awake king grabs the mattress while thieves steer toward escape. | Two handles add control, not a required second player. Both contributing thieves share the actual team award (split value, no duplicate currency). Either can cause and rescue a bad corner. |

Only Roll is implemented in this lane. Bed waits for Zion's Roll verdict and its
own single proof before more content. Greybox geometry is intentional; lane 2 owns
the improved visual direction. Art cannot establish whether rolling is enjoyable.

## Board expansion, after those proofs

| Toy | Repeated expressive action | Funny consequence / solo route |
|---|---|---|
| Screaming Diamond | Toss, aim, pass, fake a pass, lure, steal back. | The gem announces its carrier and redirects pursuit. Catch is voluntary; a solo thief banks it off lure pads. A miss leaves it loose instead of trapping the recipient. |
| Cannonball Burglars | Aim the chest cannon, launch, bounce, grab, aim a return shot. | Smash into a vault and bounce the chest home; rivals intercept loose cargo. Retry from the cannon without a long reload walk. |
| Trojan Statue (later) | Disguise, wiggle, reveal, grab, flee. | Greedy rivals carry the thief into their vault. An NPC curator keeps solo play active; no waiting for a human to accept bait. |
| Granny's Teeth (later) | Wear, whistle, throw a bone, redirect the dog, snatch. | The stolen dentures become a prank tool. The dog bowls furniture and loose loot around Granny's yard. |

## Greed, friends and bragging

Roll supports solo from the same board with the same responsive push and shove.
Friends create rescue, robbery and retaliation stories without changing rules.
Attached loot cannot silently change owners. A physical bump first makes a small
amount loose; both thieves can react. The vault and saved trophies are safe.
No paid protection, damage upgrades or permanent theft of banked progress.

At extraction show the real heap and **+$actual haul** large. The hideout vault
shows the owner's bank, best run and a recovered-heap trophy. A server board ranks
best hauls; a later persistent world leaderboard must use verified saved records.
Large values are denominations (100 per coin), not fake multipliers or revenue.
Trophy shelves later display memorable objects: the hat, the bed, an absurdly full
ball. The first playable displays one best-haul heap using simple parts.

Progression proposal: first bank funds cosmetic vault displays; completed Roll
opens Bed, then bigger layouts remix the toy. Gadget unlocks add an action:
spring ramp, grappling tow, decoy hat. They must create different routes or pranks,
not force speed grinding before the toy is fun. First playable has no gadget shop
or unlock grind. Price and unlock pacing remain UNKNOWN pending Zion's testing.

Cut: parry exams, zone recommendations, hatch waits, pets, daily popups, multiple
currencies, mandatory teams, base locks, holds for every pickup, and a loss rule
that erases the bank. Timeout ends the attempt and spills unbanked cargo; retry
immediately. A player may bank early; 2–4 minutes is an intended greedy run,
not a minimum wait.

## Evidence and comparison before expanding

Read FUN-REVIEW, ROBLOX-HIT-GAME-BIBLE, TIKTOK-ROBLOX-LESSONS,
GAME-THEORY-CHECKLIST and the ten BIBLE studies/template in C:/dev/codex-lab/refs.
Those are local research reports, not freshly watched or played references.
The exact Keystone Roblox Process Playbook was not available in the checked local
active-work and refs directories; its full text is UNKNOWN. Applied the supplied
real-art/core-greybox/reference-arena rules. No Studio Play started.

| Best comparison bar | Reported reference behavior | This proof / honest gap |
|---|---|---|
| Steal an Egg: theft clarity | Sleeping guardian wakes at the steal; nearby player causes a trap and ragdoll. | Visible ball, angry guardian, red lane, getaway. Does Zion understand the goal without explanation? Runtime clarity UNKNOWN. |
| Katamari: rolling toy | Acknowledged mechanical inspiration in FUN-REVIEW; no new footage inspected here. | Collection grows a physical, visibly attached heap. Responsive control and delight remain UNKNOWN until Zion plays. |
| Grow a Garden: visible possession | Exceptional Gold object and a crowded owned plot sell magnitude. Study starts mid-game. | Actual haul becomes a vault heap and real best-haul number. This greybox has no comparable art quality yet. |
| Steal a Brainrot: social desire | Coveted visible objects, theft alerts and counterplay. Study starts established. | Ball rams expose loose loot, with immediate steal-back. Banked progress stays safe to keep the joke reversible. |
| Huss Valley / 99 Nights: witnessed contribution | Rescue/failure stories and shared camp progress in the studied sessions. | Friends can rescue a runaway ball; Bed must later make both handles meaningful. Not evidence of tested co-op fun. |

The Bible's short-loop/earner defaults are superseded by this owner's explicit
2–4 minute toy-heist direction. Keep fast physical pickup feedback, a tiny HUD,
one obvious next goal and quick retries. Do not inherit unrelated monetization,
new-player income timing or unverified virality claims.

Review card for Zion/Claude: compare desire → player-caused surprise → bank at
phone size, muted. Does a second run invite a deliberate new route? Does a bump
create retaliation instead of helplessness? Rework steering before adding Bed if
the ball fights the player. Widen/remove any door that softlocks a full ball.
Independent critic and fun verdict: **PENDING**, not simulated as a pass.

## Reuse and constraints

Inspected local LootRules, KeeperAttacks, Profiles, MockStore, UIStyle and vendored
ProfileStore code/licence. Old one-item/hold/parry rules do not fit a rolling heap;
retain their ownership/conservation principle, not a fork. Mount shared Profiles,
MockStore, UIStyle and ProfileStore directly from prototype/core in the new build.
ProfileStore is the existing Apache-2.0 dependency with its licence embedded in the
place. No new downloaded code, assets, purchases, accounts, publishing or commits.
Separate save namespace; no old economy migration. All testing belongs to Zion;
Codex performs build, compile and offline contracts only.

Lessons: when a treasure is a toy, let acquisition change its behavior because
the repeated verb must entertain before payout. When a save can fail after writing,
keep the same bank operation pending because retrying must not duplicate the haul.
