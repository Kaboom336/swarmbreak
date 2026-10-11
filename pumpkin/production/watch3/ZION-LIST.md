# Zion's list, round 3 (every item gets answered; nothing dropped)
Z1 Scythe is held backwards on his body. (14:48)
Z2 Colours on everything are terrible. (14:48)
Z3 UI/HUD doesn't look like other games; go into specific detail. (14:48)
Z4 Research TikTok on how to make a good Roblox game + his TikTok favorites. (14:48)
Z5 Research game theory. (14:48)
Z6 Make it all a system (skill/playbook/Obsidian). (14:48)
Z7 His super-critic list: (pending, he is playing)
## Claude watch notes
W1 Zone quest panel overlaps the gate sign: "2 new pets + New/pets" garbled, "Next gate -25%" negative.
W2 Lime floor + orange walls + blue walls + purple trim all clash.
Z1 evidence (live read of Zion's R15 avatar, idle): handle is 1 stud in FRONT of the root (rel z=-1.0) while every blade part is 2-3 studs BEHIND the body at chest height (rel z=+2..+3.2, x=-0.3..-1.7). So the blade trails behind and points backward. Fix: idle with the blade high and in front/above the head, cutting edge facing forward and down (like a reaper), and swings that sweep the blade through the space in front of the player.

## Zion's critic list (15:12 UTC) -> owner section
Z8  Boss fight needs improvement and a better combat system -> BOSS
Z9  Enemies should have better attacks -> BOSS/ENEMIES
Z10 The frog walks backwards; the candy is just 3 coloured blocks -> ENEMIES (facing) + MODELS (candy)
Z11 The screen is really bright compared to other games -> PALETTE/LIGHTING
Z12 The font looks bad and low quality -> FONT arena
Z13 Pumpkins have a block in them; the candy on top looks bad -> MODELS
Z14 Models around the map have no thought behind them (one sub-agent per section/model, arena, use Codex more) -> WORLD LAYOUT
Z15 Hold E everywhere is bad and prompts overlap -> INTERACTION
Z16 Some floating text is inside things -> UI/BILLBOARDS
Z17 Things are placed anywhere instead of planned -> WORLD LAYOUT
Z18 UI icons are terrible -> ICONS
Z19 Swing should hit multiple pumpkins at a time; lucrative and satisfying -> FARMING
Z20 Quest panel covers the screen -> UI (in progress)
Z21 Review all enemies; none walking backwards -> ENEMIES
Z22 Watch the recording yourself, review everything, organize, plan, use Obsidian -> Claude

## Claude's own review of the recording (rec play_000-004, sheets)
C1 Zone quest box stacks on top of objective + gate sign + combo text + "Fuse/Witch merchant" signs: 4-5 texts overlap at screen top (4:12-4:28). Same as Z13/Z16.
C2 Wild pumpkins in zones 2-3 are pastel blobs (pink/blue/white) with a candy-cane icon floating on every one: reads as clouds, not pumpkins (Z6/Z13).
C3 Guard "ZzZ" and "!" icons fine, but the guards are small blocky trees (TreeEnt) the same size as props; no wind-up before catching.
C4 King Fight (10:36-10:52): King just stands on the throne; HP bar huge at top while the Index panel is open; "Hold E at ..." text clipped by boss; "TOP BONKERS" leaderboard text tiny; damage numbers "800" repeat; no attacks, no phases (Z8).
C5 Index panel opens on top of the fight; panels don't close on events.
C6 At 17:42-17:58 the camera sits still for 16 s showing a giant tilted "PUMPKIN PATCH" banner clipping through a purple tower and "MVP" text floating in the air: world signs placed randomly and overlapping geometry (Z10/Z14/Z16).
C7 Bright lime floor + white paths + saturated purple: very bright overall (Z11).
- Z-ICONS: Zion approved (15:14 UTC) uploading a small set of generated icon images to his Roblox account.

## Claude Studio check after round 3 build (16:2x UTC)
- Studio had OLD scripts (Rojo not connected after Studio reopened); pushed current sources via HTTP + ScriptEditorService. Zion's 14:48 playtest may have been on the older build.
- Scythe now held in front with the blade up (HRP space blade z -3.3..-4.2, y ~5): fixes Z1.
- Fixed: UI.box used parent.ZIndex on a BillboardGui (gate sign error).
- Open: objective sub-line truncated ("Swing or tap at the"); right column shows Pets + Daily only (Quests tile gone because the quest panel moved bottom-left - OK); candy counter still small; WorldPlan v2 pending (props).
