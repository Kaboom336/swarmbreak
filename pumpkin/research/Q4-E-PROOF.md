# Q4-E implementation proof

Q4-E closes the audit items that were not owned by the ride, colour, or art passes. Automated contracts live in `tests/experience_rules.spec.luau`, `tests/challenges.spec.luau`, `tests/monetization.spec.luau`, and the existing economy/layout specs.

## Action-feedback matrix

The executable matrix is `ExperienceRules.ActionFeedback`. Every accepted core verb has at least two immediate channels and one named result state. Rejections use the magenta `NEED N SIZE` response and do not consume Size or play success feedback.

| Verb | Immediate channels | Result |
|---|---|---|
| Grow | squash, seeds/dust, pitched pop | Size changes |
| Launch | latch/launch motion, rolling bed | ride state |
| Steer / settle | shell lean, lane UI, rolling sound | authoritative lane |
| Pickup / dodge | world burst, pitch step, pending-bank/combo UI | pending Wins/combo |
| Hit | bump, impact chips/flash, thud | speed loss/combo reset |
| Finish | cash-out pop, stinger, coin/bank UI | exact banked Wins |
| Hatch / equip | model motion, confetti/pop, card/toast | persisted pet/equip state |
| Unlock / rebirth / delivery | rare-tier pop, sound where applicable, result copy | persisted progression/item |

## Effects and performance budgets

`ExperienceRules.EffectTiers` is the shared hard budget: high/reduced particle caps 90/36, popup caps 10/7, debris caps 28/12, sound caps 16/8, and light caps 12/6. Recurring UI, debris, wall popups, coins, and bonus shapes use fixed pools. Reused grow popups cancel their old tweens. Distant ride playback is omitted beyond 650 studs; local rides always render. Streaming is enabled at 256/768-stud radii and committed ride endpoints are requested before playback.

The themed vocabulary is dust/leaves, pumpkin seeds, candy stars, gold sparks, impact chips, speed wisps, hatch confetti, and rarity aura. Its timing grammar is 0.15 s anticipation, one rendered-frame contact, and 0.55 s result. The reduced-effects setting is persistent.

## Required device/play evidence

The automated gate verifies source, pure rules, responsive rectangles, and build output without Studio. The next permitted real-device/Studio pass uses this fixed evidence list without changing code or prices:

1. 667×375, tall/notched phone, tablet, and 1920×1080: first grow, all modal close/back paths, ride controls, hatch cards, and no center-corridor overlap.
2. Spawn → ten accepted grows → blocked sub-10 pad attempt → launch → pickup/dodge → hit/reset → finish/cash-out → first-free egg.
3. Sun, tunnel, and finish audio/visual states with high and reduced effects.
4. Ten-minute four-rider/worst-pet soak: after effects settle, record FPS/frame time, InstanceCount, LuaHeap, particles, sounds, debris, and lights; counts must return to a stable band and the baseline device target remains 60 FPS/16.67 ms.
5. Fixed screenshots: first spawn, first grow, rider inside, obstacle/combo, tunnel, hit/reset, finish, shop, pet hatch, and 667×375 HUD.

No Studio capture is fabricated here; this task's hard limit forbids Studio. The code/build gate is the acceptance evidence for this change.
