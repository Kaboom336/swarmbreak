# Zion's TikTok 1: "Is this the best UI you have ever seen?" (@crypticinvest1), studied 2026-10-05

Source: video Zion uploaded (32 s, 9:16, a phone filming a monitor). Frame sheet: /mnt/project-files/roblox/research/r6-tiktok-card-reveal.jpg (11-17 s, 2 fps).

## What it is
A card-pack opening built in Roblox Studio.
- The first 9 s scroll through a long Luau script, likely AI-written, around 2,000+ lines: TweenService, ContextActionService, UserInputService, "BANNER", "LIFT_PLATES".
- It is played in the device emulator (iPhone 14, Virtual Controller), so it is built mobile-first.
- No gameplay is shown. The "wow" is entirely UI motion design.

## The reveal sequence (about 8 s, every step a separate beat)
1. The pack slides in from off-screen, tilted, with a red neon frame and a glow.
2. It settles with a slight 3D tilt. A light shimmer sweeps diagonally across the face.
3. Sparkle particles twinkle around the edges. Red god rays start behind it.
4. A tear-open: the top strip rips off with a zig-zag edge, and the inside card slides up.
5. A title plate appears: "VORRAK / ULTIMATE EDITION".
6. Stars pop in one at a time above the card (1→5), each with a white flash.
7. The card flips in 3D, showing the full art face.
8. The final card shows illustrated art (a dark armored character, likely AI-generated 2D art), the name, 5 stars, ATTACK/DEFENSE numbers in stat badges, a lore paragraph, a pulsing neon frame, ember particles and rotating rays behind it.

## Why it reads as "best UI"
- **Anticipation then payoff:** the reveal is staged in beats, with nothing shown all at once. The same reason gacha reveals work.
- **One strong colour family** (red/black/white) with neon glow, and very high contrast.
- **Real illustrated 2D art** on the card, instead of flat icons or text.
- **Constant subtle motion:** shimmer, particles, rays, pulsing.
- **Big, centred and phone-sized.**

## What we should copy for Swarm Break
- Our pick-1-of-3 reward cards, Gem crates and weapon unlocks get the same staged reveal:
  - slide-in;
  - shimmer;
  - rarity-colour god rays;
  - stars or rarity pips popping in one by one;
  - a flip to the face;
  - a pulsing frame.
  - Common is quick (0.6 s). Epic and Legendary get the full 2-3 s show, and can be skipped by tap.
- Illustrated card art for every weapon, ability and boss. Each card needs a real image, not a plain coloured panel.
- Rarity drives the whole palette of the reveal: blue rare, purple epic, gold legendary, red mythic.
- The build path is Luau UI only (TweenService, UIGradient sweeps, ImageLabels, ParticleEmitters, or 2D sprite particles in a ViewportFrame). Codex can build it. The art images need an image source; that is an owner or Studio step.
