# SECTION-GAMEPLAY: feel, first 10 minutes, events (round 3)
Verified against current code (giant/src, HEAD 85592b0) and play_000.mp4 (t=40, 80, 160, 240, 300 s). Evidence tags: PC = PatchConfig.luau, CL = Patch.client.luau, SV = Patch.server.luau, V = video time.

## Already fixed since the audit (do not re-report)
- Smash pays: zone candy ladder 8/80/250/1200/6000/30000/150000 (PC:1402); big x6, golden 1/40 x20 (PC:301-311).
- Gates 2.5k/100k/900k/9M/80M/540M, arrivals 0/3/10/18/30/48/75 min (PC:1170-1197, 1469).
- Tutorial order steal, place, smash 50, Iron, Graveyard (PC:916-945). Context-aware objective banner + world arrow (CL:6514-6623).
- Smash juice: hit-pause 45/110/130 ms, shake, shards, flying candy with rising pitch, golden wash, merged damage number (CL:5135-5330, 277-330). Raids disabled (Raid.grace=1e9, PC:1199). King HP scales so a solo fight is about 75-95 s (SV:7075, PC:1412).
- King reward = 1800 s of farm income + crates, pity every 5th (SV:8694-8730). Guard speed adapts to the thief and ends at base/safe line (SV:5780-5830).

## 1. Flaws still present (ordered by impact)
1. **Tutorial steps 4/5 send the player at things they cannot afford.** Step 4 "Buy the Iron Scythe!" (150 candy) and step 5 "Unlock the Graveyard!" (2,500) have no affordability check (CL:6551-6561 return before the candyValue checks at 6575+). Player walks to the stall, is refused, loses the thread. Step 3 only pays 50 candy, so the Iron gap is real. Steps 1, 2, 4 reward `{}` (PC:921-937): no payoff for the first steal or first hatch.
2. **Zone quest panel collides with HUD** (old W1 still true). Desktop panel at (0.67, 0.09), right-anchored, 28% x 12% (CL:6054-6056) overlaps the ZoneLine (x 0.25-0.75, y 0.075-0.11, CL:5760) and the combo counter; V=40 s shows "Next gate -25%" clipped under "x7 COMBO". ASCII "[ ]"/"[x]" boxes. "Next gate -25%" is shown even after earned and on Zone7 (should say Rebirth) (CL:6065).
2b. **Two identical rotating orders stacked** at V=160 s ("Place a Ghost pumpkin! 4.7k candy" and "13.1k candy"), against the one-order rule (SV:977-990). Verify in a fresh save.
3. **Debug text leaks over the objective banner**: "IDLE mid swing swingam" (V=300), "RETURN! HARVEST!slam" (V=80). Not in game source, so likely a Studio pose-tester plugin; confirm it cannot ship.
4. **Two clocks in the bottom-right HUD**: "King in 10m 18s" and "Nests respawn in 1m 15s" (V=40..300). Checklist wants one event chip (R3/O3). King chip shows before King is unlocked (reads as locked content). No always-on gate progress bar (R5).
5. **Delivery toast collides with the objective sub-line** (V=80 s: "You delivered a Pumpkin to your pen!" over the banner); banner still reads "Steal a Pumpkin!" with no acknowledgement of the 6 s hatch wait.
6. **Hatch escalation weak**: owner flash is BackgroundTransparency 0.92 (about 8% white, CL:7966); FOV punch to 85 and shake 0.5 fire for every hatch including Commons, so Rare+ does not stand out except for the card. Hatch timer is only a floating "Mystery Pumpkin 0:06" label (V=80, 160).
7. **Sound reuse/muddy mix**: Bonk and HitA are the same asset 71589018126132 (PC:1139-1140). Growl 9113980319 = guardian wake, King rise, King attack, Roar. Reveal = hatch, Index, Purge, Golden. Pop = hatch and delivery. Delivery (the biggest beat) has no unique cue. No audio for gate unlock, tool purchase, guard "safe", crate open.
8. **King Fight entry friction**: only wall-clock :00/:20/:40 (PC:1210-1213, SV:6085): a player who hits the 10 min unlock can wait up to 20 min. Join needs Hold E and is refused while carrying or chased (SV:8830-8836). Unlock constant is split (PC:167 = 1800, override PC:1407 = 600) with hard-coded "10 minutes" hint text.
9. **No visible pity or odds** (P5/P6): `KingCrates` is published but nothing in CL reads it; no odds screen.
10. **No offline "welcome back" card** (R1 = 0); AFK vs active ratio unchecked (L6).
11. **Guard chase tension low when sprinting**: guardian speed is 0.88-0.97 x thief's observed speed (PC:1536, SV:5815-5826); catch only after 3 s and within 3.5 studs. Only a `GuardGap` attribute exists; no proximity-scaled vignette/heartbeat.
12. **Zone-quest "own pet" ticks silently**; only the 3-of-3 completion announces (SV:8195-8210).

## 2. What top games do
- Steal a Brainrot: the steal is the clip; chase has a siren, screen-edge red that grows with proximity, a loud stolen sting, and an instant big first reward.
- Steal an Egg / Pet Sim 99: every tutorial step ends with a visible payout (coin burst, counter jump, ding); banner names the exact missing amount ("Need 90 more").
- Grow a Garden: one timer chip, always-on progress bar to next goal, away summary on join.
- Hit games: persistent boss HP bar + damage board, one hero reward reveal; hatch reveals scale in time and sound with rarity (common about 1 s, legendary 3 s with silence then sting).

## 3. Fix spec, by impact
1. **Tutorial gating + payouts (S).** CL:6551-6561: step 4, if candyValue < Config.Tools[2].cost return "Smash pumpkins!", "Need " .. short(cost - candy) .. " more for the Iron Scythe", zone. Step 5 same with gateCost. PC:916-945 rewards: step 1 `{candy=60}`, step 2 `{candy=90}` (so Iron 150 is reachable soon after step 3's 3B). Use the existing orderDone toast plus candy burst.
2. **Quest panel (S).** Move to left rail under Index: AnchorPoint (0,0), Position (0.01, 0.34) desktop / (0.01, 0.40) mobile, Size (0.20, 0.13); nothing in x 0.25-0.75. Three rows with check icons (done 57 200 100, todo 120 120 140). Last row: "Gate -25% earned" when complete, "Rebirth ready" on Zone7. Keep hidden when KingActive or Carry > 0.
3. **Single-order guarantee (S).** After tutorial assert `#o.list <= 1`, dedupe by id in `nextOrders`.
4. **Strip debug overlays (S).** Find the pose-text instance (Studio plugin or Workspace/PlayerGui label); ensure it is not in the published place.
5. **One event chip + gate bar (M).** Merge to a single bottom-right chip "KING 10:18" (gold 255 190 40) only after King unlock (before: "King unlocks 10:00"); drop the Nests timer from HUD (keep on the nest billboard, HoardRefill 30 s). Add a gate progress bar above the candy counter: height 6% of the counter, fill 255 201 51, label "NN% to Graveyard".
6. **Hatch escalation (M).** Owner flash alpha: Common 0.85, Rare 0.7, Epic+ 0.45 then tint to rarity colour, 0.25 s fade. FOV punch 85 only for Rare+, Common 76. Pet pop scale 1.0 -> 1.25 -> 1.0 over 0.35 s. Rare+: 0.6 s dim (lights -40%) before pop; confetti burst 24/40/70 by rarity. Replace "0:06" text with a ring fill on the pedestal.
7. **Sound pass (M, free assets only).** Unique ids: delivery coin cascade 1.0 s, gate unlock fanfare, tool buy, guard "safe" chime, hatch-common pop, hatch-rare riser 1.5 s + sting; Bonk != HitA. Duck Music to 0.15 for 1.5 s on hatch/delivery. Keep SoundMix SFX 0.6.
8. **King flow (M).** One constant `Config.Unlocks.King = 600` read by the hint text; if no wake within 8 min of a player reaching unlock, pull the next wake forward once (cap one pull-forward per 20 min). Join prompt hold 0.3 s. Allow join while carrying by auto-dropping at the throne. Results card reuses the hatch card at Epic styling for the crate.
9. **Pity + odds (S).** Chip "Crate pity N/5" from `KingCrates % 5`; Odds row in Index footer: 70% / 27% / 3% (+5% finisher, PC:1230).
10. **Offline card (M).** On join: seconds away capped 2 h x 25% of pen income, one Claim button, shown 2 s after load, never mid-action.
11. **Chase tension (S/M).** Red vignette alpha 0.15 -> 0.45 as GuardGap falls from 40 to 8 studs; heartbeat loop pitch 1.0 -> 1.4; 0.5 s roar + 0.15 shake on wake. Keep catch rules.
12. **Quest ticks (S).** Toast "Quest 1/3: Smash 50" (bg 25 20 40, text 255 214 80) on each completion.

## 4. Acceptance test (5 lines)
1. Fresh save: steps 4 and 5 banners show the missing candy and the arrow points at pumpkins until affordable; steps 1 and 2 pay candy with a burst.
2. In Zone 2 with a combo running: nothing overlaps zone name, objective, combo or chips; one clock chip only; gate bar visible.
3. Hatch a Common then a Rare: Rare is clearly bigger in flash, burst and sound; delivery sound differs from hatch sound.
4. Steal and sprint 20 s: vignette and heartbeat track guard gap; reaching the base ends it with a "safe" cue.
5. Wait for King: banner at T-60 s, join works while carrying, results show candy + crate + "pity N/5", solo fight lasts at least 60 s.
