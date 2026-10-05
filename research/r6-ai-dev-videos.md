# R6: "I made a Roblox game with AI" videos (2026-10-05)

I read the transcripts through YouTube's transcript panel and looked at the gameplay through sampled frame sheets. Full per-video notes are in `ai-videos-notes.md`; frame sheets are `ai-v2-*` and `ai-v3-*`.

| # | Video | Tools | Time | Done by hand | Result / look |
|---|---|---|---|---|---|
| V1 | Duckable, "I Tested Every Roblox AI" (560K) | Roblox Assistant, Super Bullet, Lemonade.gg, Forge GUI, then Claude over MCP | ~30 min per prompt (Assistant) | Map and models (with Claude) | The AI-only tools came out bare-bones or broken. Super Bullet's nice demos are **pre-made systems by hired devs**. |
| V2 | Scuppy, "Opus 5.5 dream game" (19K, 1 day) | Claude Opus 5.5 over MCP, plus Claude making Blender models | ~3 h, needed Max | Idea, playtests | Cartoon taxi game with outlines and a polished title/UI. Fun comes from systemic gags (potholes spill pizza, flat tyres). |
| V3 | AI PILLED, "ChatGPT vs Claude" (127K) | Codex with GPT-6 Astra (code), Claude Design (3D hammer .glb), ChatGPT images, Fish Audio voices, **an existing VFX pack** | Multi-day | Dev products, concept choice | Glossy simulator: hovering podiums, gradient-stroke fonts, announcer voice lines. Built from a **concept image**. Ads at $40/day. |
| V4 | LanceyPoo, "Viral Roblox game with AI" (339K) | Claude Code over MCP, Claude Design for models, ChatGPT icons | Days | Bread models, dev products | Clean low-poly look. **Ads: $6.24 for 83K impressions, poor CTR, 0 players after a day.** Players quit after the tutorial when they couldn't afford the next egg. |
| V5 | SyphoDev, "Claude Opus 5.5 Full Tutorial" (9.9K, 9 h) | Claude Code (Opus), Studio MCP plus Rojo, Open Cloud, Flux on Cloudflare, Hi3DGen on Kaggle, headless Blender | Ongoing | Skill design, training data | One skill per discipline, each with its own checker (see below). |

## What the good results have in common
1. **Art doesn't come from code-built parts.** It comes from meshes:
   - Blender;
   - image-to-3D, decimated with the detail baked into a texture (V5);
   - Claude Design .glb (V3, V4);
   - bought kits.

   These are styled from **reference screenshots or concept images** of a target game.
2. **VFX is reused or crafted, not generated.**
   - V3 used an existing pack.
   - V5 harvests free toolbox VFX packs, recombines the pieces, and checks them with a **"phase freeze"**: freeze the particles at start, middle and end, then screenshot each.
3. **The UI "depth stack"** (V5):
   - a blue-shifted drop shadow;
   - a gradient face;
   - a top highlight;
   - **one outline thickness everywhere**;
   - generated icons, never emojis;
   - checks at 4 screen sizes.
4. **Voice and announcer lines** for every milestone (V3, Fish Audio).
5. **The first minute matters most** (V4). The tutorial must lead straight to an affordable first purchase or win, or players leave.
6. **Ads only work with a high-CTR thumbnail** (V4).
7. Workflow hygiene **already matches ours**: Rojo files as the source, config folders, tests and lint gates, a single remotes file (V5).

## What we're missing compared with them
- **Mesh-based, styled environments.** Ours started as parts; the kit swap helped (art-final2: "close").
- A **VFX library** (packs or an artist) and a phase-freeze checker.
- An **image-to-3D pipeline** for custom props and enemies. Our generate_mesh rigs are weak.
- A **UI depth-stack pass** with generated icons.
- **Announcer and voice SFX.**
- A tighter **first 60 s**.
