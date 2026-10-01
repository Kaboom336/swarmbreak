# r2-look: the look of front-page Roblox games, and a spec diff for Swarm Break

Date: 2026-10-01. Angle: art direction, HUD, icons/thumbnails, lighting. Builds on RESEARCH.md section 3 and game/tools/blender/RECIPE.md; does not repeat them.

## 0. Evidence quality (read first)
Visual descriptions of the front-page games are scarce in text. YouTube, DevForum and Reddit are blocked, and the review sites WebFetch could read (Pocket Tactics, The Spike, Wikipedia) say almost nothing about art direction. Pocketgamer's best-looking page was not fetchable (permission timeout). So: sourced items carry a URL; everything marked ESTIMATE is my read from general knowledge of the genre or from the sourced rules, and must be checked with screenshots on Zion's laptop (Roblox page galleries) before it becomes a hard rule. No visit/CCU/revenue numbers are used here beyond those quoted.

## 1. What the sources actually say

| Finding | Source |
|---|---|
| Grow a Garden (the biggest 2025-26 hit) uses "studded textures reminiscent of old-school Roblox games"; one reviewer called it "more like a prototype than a finished game". Look is plain on purpose. Its retention is weekly events, not graphics. | [Wikipedia: Grow a Garden](https://en.wikipedia.org/wiki/Grow_a_Garden) |
| Steal a Brainrot: one big square, 8 players, own base each; the loud part is event sequences (blackout, strobing, screen wobble); rarity tiers (common up to "Brainrot God") drive how distinct a character looks. Lesson: spectacle moments and rarity-by-look, not refined UI. | [PC Gamer](https://www.pcgamer.com/games/sim/one-of-robloxs-biggest-experiences-right-now-is-a-bizarre-italian-brainrot-character-stealing-simulator-and-lord-help-me-i-now-understand-why-its-so-popular/) |
| Grow a Garden-style UI kits are sold as "attractive and playful", for "casual, quirky" games, with frames for shops, inventories, hotbars, notifications, settings. Themed, not neutral. | [GaG UI pack](https://adrianart.itch.io/gag-ui-pack) |
| Survive The Swarm: third person, auto-attack, gems fill an XP bar, level-up shows "holographic upgrade cards" (weapon tier +1 or stat picks), enemy bullets read as "red dots", store icon on the right edge, dark site theme (#0e0c16). Enemies are "cube insects" per RESEARCH.md. | [STS beginner guide](https://survivetheswarm.wiki/progression/survive-the-swarm-beginner-guide) |
| Genre warning: "most Vampire Survivors clones did a poor job of distinguishing the player from the visual clutter" (Rock Paper Shotgun, quoted on Wikipedia). Player and projectile readability is THE genre problem. | [Wikipedia: VS-like](https://en.wikipedia.org/wiki/Vampire_Survivors%E2%80%93like) |
| Final Swarm's Roblox page thumbnail is fantasy artwork with magical elements, matching its class (wizard) branding in the title; the game is sold as class fantasy, not sci-fi. | [Final Swarm](https://www.roblox.com/games/99521272836282/Final-Swarm) |
| Hellreaver Arena is a 2020 FPS (10 players, 10.4M+ visits, peak 2,902 CCU): it is NOT a current front-page game, so I treat it as a "cheap-looking game that still lasted" data point (movement, Lightning Gun, cosmetic gamepass weapon skins). | [Rolimons](https://www.rolimons.com/game/5523314295) |
| Official icon rules: 512x512 minimum, square, shown as small as ~150x150; ambiguous graphics confuse; match the genre; bright saturated colour for fantasy, high contrast for horror. | [Roblox Creator docs: icons](https://create.roblox.com/docs/production/publishing/experience-icons) |
| Click rules: single focal point; saturated colour with strong subject/background separation, add rim light or outline; text only 2-4 huge words; expressive action poses beat static logos; design for tiny first (most players see it at feed size); keep icon, gallery and socials consistent. Top games reach ~3.6% qualified play-through, typical 2-2.4% (vendor-reported, treat as indicative). | [Vizzbees](https://vizzbees.com/blog/how-to-make-a-roblox-thumbnail) |
| Better icon = character PLUS context (fighting a boss with a visible health bar beats a smoky close-up); show genre tells; test at 128x128 on a phone; avoid "twelve elements competing". | [CreatorXP](https://creatorxp.gg/guides/roblox-game-icon-mistakes) |
| Fisch: Lego collaboration ("bricky beasts") shows the front page rewards event-skinned content. 99 Nights: described only as horror ("creepy deer-like entity"). | [Pocket Tactics](https://www.pockettactics.com/roblox/games) |

Not found (gap): HUD layouts of Rivals, Blade Ball, Dead Rails, Forsaken, 99 Nights; Final Swarm's HUD. Do not claim them.

## 2. Pattern read (ESTIMATE, consistent with sources above)
1. The chart toppers are not graphically rich. Grow a Garden is studded and "prototype-like"; the brainrots are meme art. What converts is a clear promise, a loud hook and event spectacle. Our Blender polish is above the bar for the niche; the risk is readability and juice, not fidelity.
2. In a swarm game the screen is 80% enemies. Silhouette, colour-coding and a visible player beat model detail. RECIPE.md already says one glyph per enemy at 40 studs; add a distance test (section 4).
3. Rarity and tier are expressed by look (Brainrot rarity tiers, our weapon rarity). Keep one rarity colour ladder across weapons, cards, crates, drops, HUD.
4. Genre UI is themed, chunky, rounded and bright-on-dark (GaG kits, STS holographic cards). Default Roblox grey panels are the main "amateur" tell.
5. Events are visual: blackout/strobe/boss intros. We have a 4 s boss card; push it.

## 3. Spec diff: HUD (ESTIMATE layouts, sourced conventions marked)
Current state is unknown to me in detail; check game/src client UI before applying. Proposed:
- Top centre: wave counter big ("WAVE 7") with a thin enemies-left bar under it; boss health bar replaces it on boss waves (matches CreatorXP "visible health bar" convention).
- Bottom centre: health bar (green to red, big, numbers inside), XP/shield bar thin above it; hotbar of weapon icons below, rarity-coloured frames, key hints on desktop.
- Left or top left: coins and gems, small icon plus number, animated count-up on pickup. Right edge: shop / crate / settings icon column (STS puts store on the right).
- Mid-run card pick (design gap in COMPARISON.md): three tall cards, dark glass panel (#0e0c16-ish), rarity-coloured top edge, big icon, 2-word title, one line of text. Name them in plain words (PLAYBOOK rule).
- Minimap: skip for v1 (single arena; ESTIMATE that it adds clutter). Instead a small edge arrow for off-screen boss/gate.
- Damage numbers: white small for normal, yellow big for crit, short pop-and-rise, cap count per second to protect readability and frame time.
- Mobile: all touch targets >= 44 px equivalent, HUD inside safe area, hotbar at most 5 visible. (Standard practice, ESTIMATE.)
- Style: one font (chunky rounded), 2 px dark outline on all HUD text, rounded corners, one accent colour per element class. Same palette in icon art and thumbnail (CreatorXP/Vizzbees consistency rule).

## 4. Spec diff: enemies, weapons, arena (add to RECIPE.md)
Enemies
- Add a "40 stud rule": render each enemy as a 64x64 silhouette on the arena floor colour; a judge must name it. Fail = redo the glyph.
- Each enemy gets a unique accent hue and never reuses another enemy's hue in the same wave; player-side colours (cyan/white) and enemy projectile colour (red/magenta, like STS "red dots") must never overlap. Player projectiles: cool and bright; enemy projectiles: warm and large with dark outline.
- Telegraph attacks with a ground ring or glow charge-up in the enemy's accent (0.4-0.6 s); this is the readability tool crowded swarm games lack.
- Hit feedback: white flash 0.08 s, scale pop, burst into accent-coloured sparks on death (already no-blood rule). Keep particle count budgeted per enemy.
- Optional cheap outline: a back-face-extruded black shell part per enemy (Blender inverted-hull) gives the cel look without a shader; ESTIMATE that it helps against bright floors. Test on one enemy first.
Weapons
- Rarity ladder in colour AND silhouette: Common grey/white, Rare blue, Epic purple, Legendary gold body (RECIPE already says gold body), same hues on UI frames and drops.
- Muzzle flash and projectile trail per element (4 shard elements = 4 hues), bright core plus dim halo, 2-3 frames; big hit spark. Weapon icons for hotbar rendered from the 3D model on a flat rarity-colour disc, 3/4 view, consistent angle.
Arena and lighting
- Dark floor, mid-value so both dark chitin enemies and bright accents read: the risk is dark enemies on dark tiles. Keep floor value clearly lighter than enemy body or add the rim light. ESTIMATE.
- Lighting recipe (RESEARCH.md lists post effects as missing): ClockTime night, Atmosphere light haze, Bloom (low threshold, moderate intensity), ColorCorrection (contrast +, saturation +), SunRays off, ambient purple-blue, Nest glow and lamps as the only warm lights. Test on mobile: Future lighting off for performance.
- Event beats: wave 5/10 boss intro gets a screen tint, a short slow-mo/shake, and a pulse of arena lights (Brainrot-style spectacle, tamed: no strobing, avoid motion sickness noted by PC Gamer).

## 5. Spec diff: icon and thumbnails
- Icon 512x512, one focal point: our hero in mid-fire, a big glowing weapon beam, a swarm silhouette behind, one boss eye/jaw looming. Saturated accent (cyan or orange) on dark purple, rim light on hero. Max 2-3 words only if any: "SWARM BREAK" in big outlined letters, or none.
- Show context: boss health bar or wave counter in the thumbnail, as CreatorXP suggests, signals "wave survival shooter" instantly.
- Genre tell: many small enemies plus one giant one is the swarm promise; match STS/Final Swarm without copying their art (CreatorXP warns copying backfires).
- Gallery (1920x1080): 1 hero action, 2 swarm crowd, 3 weapon rarity lineup, 4 boss, 5 lobby with friends (friends-first), 6 evolution. Same palette as icon.
- Test: view at 128x128 and 150x150 on a phone before upload; make 3 icon variants and A/B via Roblox's thumbnail tools once live (Creator Hub has thumbnail testing; ESTIMATE that it is available to us). Track qPTR, aim above the 2-2.4% typical (vendor figure).
- Zion does the upload (PLAYBOOK rule).

## 6. Priority list (cheapest first)
1. Lighting pass (Bloom, ColorCorrection, Atmosphere, rim) - one script, biggest look change.
2. Projectile/telegraph colour rules plus hit flash - biggest readability change.
3. HUD theme (one font, outline, rounded dark glass, rarity ladder) and level-up cards.
4. Silhouette test added to RECIPE.md; fix failing enemies.
5. Icon and thumbnail set, tested at 128 px.
6. Boss-intro spectacle.
7. Optional inverted-hull outline experiment on one enemy.

## 7. Open questions for Zion
- Screenshots of Final Swarm, Survive The Swarm, Rivals, Dead Rails HUDs from the Roblox game pages (blocked here) would turn my ESTIMATE lines into sourced ones.
- Sci-fi (ours) vs fantasy (Final Swarm thumbnail): keep sci-fi; it differentiates, but icon must still signal "waves of enemies".
