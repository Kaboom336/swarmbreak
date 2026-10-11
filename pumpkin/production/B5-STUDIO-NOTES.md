# Batch 5 HUD Studio test (Claude, desktop 1509x863)
1. Left buttons are off by one: clicking "Shop" opens the Index, clicking "Index" opens Daily. (Hit areas/handlers shifted; check button order vs callbacks and any invisible overlay frames.)
2. Two settings gears top-right (one dark square, one plain): keep one.
3. Candy counter is tiny (icon ~25 px, number ~25 px), not ~5% of screen height; income line, next-gate bar, "Rusty Scythe / Carry" line are not visible at all.
4. Buttons: icon tiny and text right-aligned; make icon ~60% of button height on the left and text left-aligned next to it; buttons ~1.25x wider/taller.
5. Objective pill is a long thin bar wider than its text; sub-line tiny; zone label small: pill should hug the text (AutomaticSize X with padding), title ~3.5% screen height.
6. Daily Reward panel is empty under the title (no reward tiles/claim button) and has a huge empty white area.
7. Old text-list Index still shown (batch 6 replaces it).
8. World stall titles "SHOP"/"SELL" billboards are huge at screen top from spawn; cap their size / MaxDistance (scene/world: note for later).
