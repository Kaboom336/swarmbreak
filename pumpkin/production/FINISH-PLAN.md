# Finish plan: Steal a Pumpkin, 10 hours (2026-10-11 06:30 -> 16:30 UTC)

## Identity: why play this and not Steal an Egg
Borrow SaE only for readability (studded blocky base, steal -> run -> pen loop). Our own hooks, which every screen and the store page should push:
1. **Scythe farming**: a 3-swing combo that smashes pumpkins for candy, with 7 scythe tiers you can see and feel. SaE has nothing like it.
2. **Pumpkins hatch into pets**: a stolen pumpkin hatches in your pen with a reveal.
3. **The Pumpkin King**: a walking boss fight every 20 minutes for crates.
4. **Halloween zones**: each zone has its own guard and colour (scarecrow, skeleton, vampire...).
Rule for every change: if it makes us look more like SaE without adding one of these, cut it.

## Usage budget (checked 06:25 UTC)
- Claude: 5-hour window 11% used; weekly 70% used with 3.5 days left. So Claude only designs, judges, reviews diffs and tests in Studio. Helper agents run on Sonnet, one judge per arena, one auditor for all playtest clips.
- Codex: does all code, one batch at a time, each with a tight task file. Its quota was not checked (UNKNOWN); if Codex hits a limit, Claude takes the smallest batches.
- Each batch is gated: compile-check + selene + econ-sim, a Sonnet reviewer for big diffs only, and a Studio smoke test by Claude.

## Schedule
| UTC | Work | Who |
|---|---|---|
| 06:30-07:30 | Arenas judged: UI, scythe, graphics -> one merged spec each. One auditor reviews Zion's playtest clips. | Sonnet judge + auditor, Claude merges |
| 07:30-09:00 | G1 graphics: LaunchLook4 (studded, bright, Halloween palette, keep King statue) + client day/night reads Base* lighting | Codex, Claude runs it in Studio |
| 08:00-09:30 | S1 scythes: 7 blocky tier models + procedural swing set (both arms, torso, trail, arc) | Codex (after G1 merges if it touches the client) |
| 09:30-11:30 | U1 UI system: tokens, icons (ViewportFrame renders + simple vector frames, no uploads), HUD, Shop, Index, Daily, toasts, hatch card | Codex in 2 tasks; blind critic vs refs |
| 11:30-12:30 | P1 playtest fixes from the audit + Zion's notes | Codex |
| 12:30-13:30 | Identity pass: store text, the scythe/King/hatch moments pushed in HUD copy and thumbnails | Claude + Codex small |
| 13:30-14:30 | Full review + 15-minute Studio playtest by Claude, fix round | Sonnet reviewer + Codex |
| 14:30-15:30 | Zion playtest (laptop), last fixes | Zion + Claude |
| 15:30-16:30 | Zion's launch clicks: Ctrl+S, publish private, API access, rejoin test, public | Zion |

## Cut list (not in the next 10 hours)
Offline income, NPC pens, Purge, night look, new zones, new pets, uploaded animations.
