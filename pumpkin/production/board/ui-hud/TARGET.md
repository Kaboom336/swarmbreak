# Pillar: ui-hud (HUD layout, currency, buttons, icons, fonts, panels, popups, toasts, reveal)

## Chosen game
**Pet Simulator 99 (Halloween update, upload 2026-10-06; source video "I Spent 24 HOURS in Pet Sim 99 Halloween Update!", youtube hKdUr4K5c5Q).**
Why: PS99 has the most finished UI language on Roblox: one chunky rounded font with a thick dark stroke, one glossy 3D-bevel button style, every panel with a coloured title bar and red X, rarity shown by border colour plus star/crown badges, tooltips on everything, and a themed (Halloween) re-skin of the same kit without losing readability. Steal an Egg (checked, upload 2026-10-10) has a leaner HUD closer to ours (2 pills left, 2 icons right, currency bottom-left) but a plain UI; it is the secondary benchmark for HUD density only.
Frames are 480p source upscaled to 1280 wide (some are editor zoom crops, so UI sizes below are measured on the 1280x720 frames).

## Reference frames (ref-1..ref-5.jpg, 1280 wide)
1. **ref-1** HUD at rest (Halloween zone). Left stack of square icon tiles (gift timer, tools, 2x3 grid) at x 0-0.09, three currency lines stacked bottom-left, numbered hotbar bottom-centre, quest list top-right as plain text with no box, boss billboard in world. Notice how little of the screen is covered: about 12% left, 5% bottom.
2. **ref-2** "Exclusive Shop!" panel, Halloween skin. Title overlaps the top edge, red X on the corner, price buttons are big and labelled (FREE green / grey), items are framed cards with a crown/star badge and "x50" count, a themed illustrated banner (bats, fence, moon) inside the panel, and a tooltip card that explains the item on hover.
3. **ref-3** "Upgrades!" list panel. Rows are white cards with icon left, bold name, one-line effect "x1 to x1.25", segmented progress bar, cost with a currency icon, and a square green arrow button on the right (grey when unaffordable). Affordable green vs unaffordable grey is readable at a glance.
4. **ref-4** Reward popup "Your pumpkin burst open into 9 rewards!". Light blue title bar, near-black text on white, item tiles with a pastel rarity splash behind each icon, star count badge top-left and "x3" top-right of every tile, giant green "Ok!" button, rarity tooltip (name, rarity word in rarity colour, description, "436b Exist", price).
5. **ref-5** "New Item!" toast grid plus hotbar tooltip. Each drop is an orange tile with yellow "New Item!" text and a dark stroke popping over the player; hotbar slots are numbered 1-6 with a count ("x10") and the tooltip card shows name, rarity, effect, supply and "Untradable".

## Ours must... (measurable, at 1920x1080 reference, scale with UIScale)
1. One font family (FredokaOne/Fredoka, weight 700) for all text; every text has a UIStroke Contextual 3 px (2 px for text under 14 px, 4-5 px for banners) in a colour about 40% darker than the fill; no unstroked text anywhere.
2. HUD covers at most 15% of screen width on the left and 8% height at the bottom; no persistent dark box wider than 0.2w except the objective pill.
3. Left menu: 2 columns x 3 rows of square icon tiles, each 0.045w x 0.083h (about 86 px) with a 3 px stroke, label under the tile in 14 px, and a red "!" notification dot (12 px) on tiles with something new. Today's 2 wide pills are replaced or supplemented.
4. Currency lines: icon 0.03h + number 0.04h tall (about 43 px) with 3 px stroke, stacked 3 lines at x 0.01, y 0.74-0.93; numbers abbreviate (1.2K, 3.4M) and count up over 0.5 s with a 1.25x icon pop (0.15 s Back).
5. Every panel: centred, 0.5w x 0.62h at 16:9 with UIAspectRatioConstraint, coloured title bar 0.13 of panel height with the title overlapping the top edge by 25%, red rounded-square X (0.035w) overlapping the top-right corner, corner radius 0.08, 4 px outer stroke, drop shadow; opens with UIScale 0 to 1 in 0.3 s Back Out and closes 1 to 0 in 0.18 s.
6. Buttons: gradient fill top-lighter 15%, 3D bottom lip 4 px darker, text 0.55 of button height; green = affordable/confirm, grey = locked/unaffordable, purple = secondary, red = close. Hover 1.08 scale, press 0.9, click sound pitch 1.0-1.1.
7. Item/pet cards: rarity colour as fill splash plus a star count (1-4) badge top-left and quantity "xN" top-right; unknown items show a black silhouette with "???" (our index already does this; add the badges and a rarity word colour).
8. Tooltip on hover/long-press for every pet, scythe and item: name 22 px, rarity word in rarity colour, 1-line effect, "N exist" supply, price; appears within 0.1 s, never covers the pointed item.
9. Reveal/popup: hatched pet card pops in 0.6 s Back Out, rays rotate behind at 1 turn per 4 s, rarity word stamps in at 0.2 s, "Ok!/Collect" green button 0.28w x 0.09h; a multi-reward popup shows up to 9 tiles in a 3x3 or a row of 4, each 0.09w square.
10. Toasts: "New Item!"/"+1 Pumpkin" in yellow #FFE14A, 28 px, 3 px dark stroke, rise 40 px and fade over 1.2 s; max 4 on screen, newest at the bottom, stacked at y 0.65-0.75 centre. Objective text is plain white text with stroke and no box.

## Ours today (honest)
- HUD is clean but sparse and flat: 2 wide pills left, 3 labelled icons right, text timers in dark pills bottom-right; currency is tiny (0/3 and a 0 next to a candy icon) and the bottom-left has no stack, no hotbar, no red notification dots.
- Panels (u2-shop, index-v1) have a good coloured header and rarity colour cards, but are flat: no 3D button lip, no title overlap, no star/quantity badges, no tooltips, no item illustration banners, header text is not stroke-weighted like PS99; the shop shows 6 scythe cards with plain name text and thin buttons.
- No popups, toasts or reveal screen at PS99 quality exist yet (no reward card, no "New Item!" toasts, no rays, no rarity stamp); the dark navy top objective pill and the SELL text at the top corners feel like placeholders next to this kit.

## Assets needed (do not insert; Creator Store, free, no scripts)
1. **UI kit (buttons, frames, panels)**: search "cartoon gui kit", "halloween ui pack", "simulator ui buttons". Take only images/decals, no scripts.
2. **Icon pack (currency, menu tiles, rarity stars/crown, red X, arrow)**: "halloween icons", "pumpkin icon", "rarity star badge".
3. **Fonts / text styling**: built-in Fredoka One; for banners also "Luckiest Guy" via Enum.Font (no asset needed). Search "halloween font" only if wanted.
4. **Panel backdrops / banners (illustrated Halloween header art)**: "halloween bats banner", "spooky graveyard background", "haunted moon sky".
5. **UI sound pack (click, open, close, toast pop, reveal stamp)**: "ui click", "cartoon pop", "level up fanfare".
6. **Hero piece (reveal rays/shine texture)**: "sunburst rays", "light rays texture", "sparkle star".
