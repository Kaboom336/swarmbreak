# Swarm Break game bible v3 (2026-10-04, from Zion's direction PDF)
This supersedes v2 wherever they conflict. v2's look rules, kill feel, budgets and "no blood" rule still apply.

## The game in one line
You build up yourself and your base, then raid **Swarm Cores** (themed dungeons from anywhere in the multiverse) to bring back gems and gold.

## Loop
1. **Lobby:**
   - Your own base plot: energy/power, an equipment factory, a home, and pets/robots.
   - The hub centre: Play, Shop, Upgrade, Enchant, Tech Shop, Subclass Station, Gym, Bank, and a PvP Arena (later).
2. **Raid a Core:**
   - Rooms, paths, ladders, stairs and unlockables, stitched procedurally from hand-made room pieces for that core's theme.
   - Waves of that core's creatures, and a boss.
   - Run-only upgrades (the current level-up cards) last for that raid only.
3. **Bring back currency:**
   - Gems (inside every creature) and Gold (from kills).
   - Spend them on permanent stats and on your base. XP from mobs levels you up.
4. **Loot:** mainly from playing. Some items can be bought with Robux, Gold or Gems.

## Cores (each tells the story of where its civilisation gets its energy)
| Core | Look | Enemies | Boss |
|---|---|---|---|
| Fantasy | castles, forests | dragons, elves, small trolls | a dragon |
| Tech | clean labs, an AI voice narrating | robots, tech ball spiders | a giant transformer, plus an aircraft carrier flyer that drops its own swarm |
| Mars | a withered factory outpost | martian creatures (our Nest bugs fit here) | the Swarm Queen |
| Elemental | forest spawn, then a crystal cave with dwarf miners and falling rocks, then an underwater city, then a volcano | wolves, tree golems, fire birds, ice penguins, dwarfs, water creatures | the volcano energy miners |

Each core has its own rooms, palette, drops and story beats. Nothing is added without a story reason.

## Art style (Zion 10/04 17:06Z): cartoon/anime, sharp and cool, bright, high saturation
- **Shapes:** chunky cartoon proportions with crisp, sharp silhouettes: hard bevels, clean edges, bold readable shapes. No mushy low-poly blobs.
- **Colour:**
  - High saturation, bright base colours, each core with its own 3-colour key. Mars: hot orange and red ground, teal goo, gold loot.
  - Shadows are tinted (purple or blue), never grey or black.
  - ColorCorrection Saturation +0.25 to +0.35 and Contrast +0.15. Bloom stays capped (intensity ≤ 0.5, threshold ≥ 1.5) so bright never means blinding.
- **Outlines:** a dark outline on characters, enemies and key props via a Highlight (OutlineOnly, DepthMode Occluded, dark tint, transparency 0.3-0.5).
  - Characters, enemies and bosses always get one; key props only near the camera.
  - Respect the Highlight limit with a pool that gives outlines to the nearest 20.
- **VFX:** anime-style shapes.
  - Sharp slash arcs, speed lines on dash and ultimates, star or impact-frame flashes (a single 1-2 frame white or ink flash, never a strobe), bold sparkles, and chunky goo splats.
  - Flipbook sprites with hard edges, not soft blurry glows.
- **Ultimates:** anime impact frames. A 2-frame high-contrast silhouette flash, speed-line backdrop and bold kanji-free text callouts (the ability name in LuckiestGuy).
- **UI:** bold rounded fonts, thick outlines and saturated buttons, matching the world.
- **On-screen effects** follow the same style:
  - Anime hit markers, damage numbers with thick outlines and a pop-scale, speed lines at the screen edge on dash, a bright low-HP vignette pulse (never red blood), and bold banners.
  - Effects never cover the centre of the screen for longer than 0.3 s.
- **Boss health bar:**
  - A wide top bar with a thick outline, the boss portrait icon and name plate, phase notches (for example, the Queen at 55%), and a white "damage trail" that drains after the red/teal fill.
  - It shakes slightly on big hits (UI only, never the camera), flashes when a phase changes, and plays an entry animation when the boss intro ends.
  - The bar shows the boss's colours.
- **Judging:** "does it look like a bright, sharp anime action game?" next to Hunty Zombie and other top anime-styled Roblox games.

## Base and lobby (Zion 10/04 15:54Z)
- **Lobby:** a decently big town map you can explore. Base plots are spread out so nobody is too close.
- **Bases are built from rooms, not blocks.** Unlock or buy a room, then pick its skin.
- **Customise mode:** a top-down camera you slide to move. Tap a room and swap its look. It should feel easy, smooth and satisfying.
- **Suggest a room:** a corner button in customise mode where players send room ideas, to add later as skins.
- **Base themes:**
  - The Starter Factory is free.
  - Clearing a core's campaign (stage 15, the hardest, with its boss) unlocks that core's base theme: Mars outpost, Tech flying base, Fantasy mountain base, Elemental underground bunker, and so on.
  - Each theme then gets its own room layout and skins.
  - Important parts (generator, factory, armoury) upgrade in levels.
- **Campaign per core:** 15 stages of rising difficulty, each with its own boss beat, plus 3 difficulties (Normal, Hard, Nightmare); each harder difficulty unlocks after clearing the one below. This pattern is inferred from similar Roblox wave and tower-defence games and should be checked against the top games before tuning.
- **Launch:** Mars is built first, but it isn't the first map at launch. We launch with 2 or more cores.
- **Robux:** never pay-to-win. Sell cosmetics (room skins, base themes early, weapon skins, emotes), convenience items (extra loadout slots, auto-deposit) and a VIP pass. Power only comes from playing.

## Movement and feel
- Sprint is always on. Clean dash, double jump and slide.
- Every frequent action (dash, double jump, slide) has 3 animation variants played at random.
- Classes and gear add movement perks: extra jumps, water walking, faster swimming.
- Build abilities: place quick walls or ramps to escape the swarm.
- Clean, simple weapon animations. Short, clean cutscenes between areas and for ultimate abilities.
- Difficulty is semi-hard: starter cores are easy and higher difficulties are challenging, but always fair.

## Cinematic combat (Zion 10/04 16:40Z)
- **Combat camera:** during swarm rounds the camera shifts gently.
  - It pulls wider when a crowd builds and tilts slightly lower and closer on elite and boss fights.
  - It always eases and never cuts while the player is aiming. The control feel comes first.
- **Ability cinematics:** each ultimate gets a 1-2 s action-movie shot. Example: a scythe dash-spin with an orbit camera, a brief time slow for the user only, then a snap back to the play camera.
  - Server time never stops.
  - Players can skip it or set it to "short" in settings.
- **Weapons:** clean, smooth animations per weapon class (idle, attack combo, heavy, ultimate). Each weapon gets 2-3 abilities, chosen from a pool through the skill tree, so fights don't get stale.
- **Mobile is a first-class platform.** Most Roblox players are on phones.
  - Cinematics are auto-play and short, and never take control mid-fight except during an ultimate the player chose to use.
  - The camera changes only frame the action; aiming stays auto-aim.
  - Big touch buttons: attack, dash, jump, slide, 2 abilities and the ultimate.
  - Test every build at phone size.

## Character
- Shown through equipment, tools, class and subclass (from the skill tree and your core path).
- **Races (Claude's call):** not at launch. Class plus gear gives the same perks with fewer models to make well. Revisit after the first two cores.

## Build order (each step must look good before the next)
1. **M1 Movement:** always-sprint, dash, double jump and slide, with 3 variants each (Codex, code only).
2. **K1 Combat camera and the first weapon kit** (a scythe with dash-spin and an ultimate cinematic), mobile-first. Codex.
3. **Mars Core v1:** Outpost 9 becomes the Mars Core, with the kit art (after the Studio importer upload), the Nest creatures as martians, and the Queen as its boss.
3. **Lobby hub v1:** the hub centre built from the space kit, with Play, Shop and Upgrade working. Base plots come later.
4. Persistent Gems and Gold with stat upgrades. The skill tree and subclass come after.
5. The second core (Tech, which reuses the most kit art), then base building, then Fantasy and Elemental.
