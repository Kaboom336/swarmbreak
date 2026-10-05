# Swarm Break rebuild plan v1 (draft, 2026-10-05)

Sources:
- r5-wide.md (web titles only);
- r6-tiktok-card-reveal.md and r6-ui-method.md (Zion's TikToks);
- research/r6 branch: r6-tiktok-refs.md, r6-ai-dev-videos.md, r6-handson-swarmbreak-baseline.md.

Hands-on notes for Hunty Zombie, Dead Rails, Anime Vanguards and Sailor Piece are still pending. Fold them in when they land.

## Core diagnosis
Games that look great are not built from code-generated parts and effects. They use:
- specialist VFX (packs or an artist): crescent and slash meshes, debris, world-darken, white-hot cores in one hue per move;
- mesh art from reference images;
- UI copied from top-game screenshots with a strict depth stack;
- a tight first minute.

AI does the glue. Our build has the systems but almost no hit feedback: a new player saw no damage numbers, no shake and no hit-freeze. The game is also won by auto-fire alone.

## Top 10, ranked by impact on feel
1. **Hit feedback that actually fires (bug check first).**
   - U1 and FX1 added damage numbers, shake and hit-stop, but the baseline playthrough saw none. Find out why first.
   - Then build one HitFeedback call per hit: flash, layered sound, sparks, damage number, hit-stop 0.04-0.08 s, knockback, camera nudge, hit marker, all in the same frame.
   - A spec checks that every weapon routes through it.
2. **Real VFX, not code-built streaks.**
   - Play harvests free toolbox VFX packs in Studio, script-free only. Inspect every insert for scripts and delete any found; never keep a store item that carries scripts.
   - Build a slash-crescent, shockwave, debris and impact library, recoloured to one hue per weapon.
   - Add a phase-freeze checker: start, middle and end screenshots.
   - Ultimates darken the world, then add debris and a screen-filling core.
3. **Combat that needs the player.**
   - Auto-fire stays as mobile assist, but a target cone replaces the full auto-aim win.
   - Enemies telegraph attacks the player must dodge (dash), and stage 1 must be losable if the player stands still.
   - No idle auto-restart loop.
4. **Lobby with direction.**
   - The spawn faces the START ring, with an arrow or beam and a glowing path.
   - Flat text boards become a styled stage-select panel.
   - Fix the rocks clipping into the lobby edge.
5. **UI depth-stack pass from reference screenshots.**
   - Play captures the HUD, shop, cards and reward screens from top games, and Codex matches them.
   - UI-RULES.md: a blue-shifted shadow, a gradient face, a top highlight, one stroke width, 44 px taps, generated icons and no emojis, and a 4-screen-size check.
6. **Staged reveals** (Zion's TikTok) for level-up cards, crates and weapon unlocks:
   - slide-in, shimmer, rarity rays, pips one by one, flip, pulsing frame;
   - illustrated art on every card.
7. **Announcer and voice lines plus layered SFX:** "Wave clear!", "Boss incoming!", level-up and ultimate callouts.
8. **The first 60 s:**
   - The first wave is a spectacular, guaranteed win: big kill payoff, one level-up.
   - Then an affordable first purchase or upgrade within 2 minutes.
   - No popups before the first kill.
9. **Mesh art for enemies and props from reference images.** Use the free path: Hi3DGen image-to-3D on Kaggle, then a headless Blender decimate and texture bake (SyphoDev). Our generated-mesh rigs are weak.
10. **Retention layer:** a daily reward calendar, a codes box, an always-visible quest panel, and a "next update" timer. Use Roblox analytics funnels for the first session.

Bugs to carry:
- Enemies chasing a player off the west edge fall about 47 studs: add a kill plane or a navmesh clamp.
- The boss watchdog from R2 still needs verifying in a real playthrough.

## Needs Zion (decision, not now)
- Buying a pro kit or VFX pack (BuiltByBit, Fiverr) is the fastest route to front-page polish, but it costs money and the card is about $6. The free route comes first: harvest script-free toolbox packs plus our own work. Revisit when a money lane pays.

## How we test from now on
- Play plays like a real player: real input only, no teleports and no state edits.
- It logs time to first kill, deaths and fps.
- Zion plays when a build visibly beats the last one.
