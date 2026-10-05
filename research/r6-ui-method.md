# UI method from Zion's TikTok (@cuhfilme, "How to get claude to actually generate good looking ui"), relayed 2026-10-05

Source: relayed by the coordinator. The video was not viewed here.

- **Reference screenshots first:** screenshot a top-chart game's UI (e.g. Steal An Egg's shop panel and item cards), give the screenshots to the builder as the target, and rebuild in Studio to match. Matching a reference beats describing a style.
- SyphoDev's tutorial (youtube.com/watch?v=afuKhenJldY) does the same with a UI skill trained on screenshots of top games.
- **Depth stack on every panel:**
  - a blue-shifted drop shadow;
  - a gradient face (UIGradient);
  - a top highlight line;
  - one outline thickness used everywhere (UIStroke).
- **Checker:** render every screen at 4 sizes (phone portrait/landscape, tablet, desktop), and fail on overlap, clipping or text under 14 px.
- **Rules file:** every playtest fix becomes a written rule, fed to every UI task.

## For Swarm Break (rebuild list)
- A UI pass driven by reference screenshots:
  - Play captures the top games' shop, cards, HUD and reward screens (Hunty Zombie, Steal An Egg, Anime Vanguards);
  - Codex rebuilds ours to match them.
- A shared UI rules file, `research/UI-RULES.md`:
  - the depth stack;
  - one stroke width;
  - the palette;
  - minimum tap size 44 px;
  - a 4-size check.
  - Every Codex UI task carries it, plus a spec that checks the depth stack on every panel.
- Combine this with the staged card reveal (r6-tiktok-card-reveal.md).
