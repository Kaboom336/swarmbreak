# U1 HUD Studio check (Claude, desktop 1684x1080), shot: pumpkin/production/shots/u1-hud.jpg
1. Right column tiles (orange, yellow, purple) show no icons/labels: blank squares. Each needs a readable glyph/model icon AND a short label under it (Pets / Quests / Daily or whatever the spec says).
2. Candy counter is tiny (~30 px icon, number in a small circle-ish outline) and the "0/3" carry text floats above it: counter must be ~5.5% of screen height, gold heavy italic number with thick dark stroke, icon same height, carry shown as a small pill next to it.
3. Bottom-right timers ("King in 3m 38s", "in 2m 23s") are tiny thin text with no chip background; the second line has no label (what is "in 2m 23s"?). One chip per timer with icon + label, readable at phone size.
4. Objective text at top ("Steal a Pumpkin!") is small and floats with no backing; make it the spec's objective pill, ~3.5% screen height.
5. Index button icon is a plain purple rectangle; Shop icon OK-ish. Use the spec's icons.
6. Settings gear at top-right corner is tiny and clipped by the window edge.
7. Sprint [Shift] button is huge relative to everything else and keyboard-labelled on desktop; on desktop make it small or hide (Shift works), on touch a round icon button.
8. Overall text sizes too small at 1684x1080: verify TextScaled/UIScale use AbsoluteSize of the screen.
