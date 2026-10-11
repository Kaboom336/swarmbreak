# R24 Studio smoke test (Claude)
Works: loads clean, no console errors; pen claimed; placing a nest pumpkin works (+62/s); new HUD (gear, Shop/Index/Teleport, candy bottom-left, timers bottom-right); wooden discs + padlocks show.
Fix:
1. Locked-disc and Upgrade prices show raw "$18507000" / "$318000": use the short candy format with the candy icon ("🍬 18.5M"), and price billboards overlap each other from the pen gate — show only the next locked disc's price (others: padlock only), MaxDistance 60.
2. "+62/s" sits far right of the candy number and "+63" floats in the middle bottom; keep both next to the number.
3. "Zone quests" button is tiny and empty-looking at top-right; make it a small pill matching Shop style under the timers, or hide until a zone quest exists.
4. Teleport pill is as big as Shop/Index; make it a smaller square icon button.
5. Objective "Run to your pen!" shows while standing in the hub with a carried pumpkin: fine, but the sub-line repeats "Place it in your pen!" — make the sub-line the distance ("42 studs").

# R26 Studio notes (Claude, after Gotham + voxel models)
- Moon timer icon shows as an empty box with Gotham (emoji glyph missing): use an ImageLabel icon or keep emoji text in FredokaOne for icon-only labels.
- "+8" candy pop still overlaps the carry line ("Rusty Scythe +8 arry 0/2").
