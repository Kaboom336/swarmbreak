# R2: Roblox games made with AI help, and how (researched 2026-10-01)

Builds on RESEARCH.md / PLAYBOOK.md (Blender-by-script, Lune tests, judge rounds). Everything below is sourced; numbers are
quoted from the source, not estimated. Where a source is a vendor blog (BloxBot, Roxlit, Obby) it is marked as such.

## 1. The state of play (what Roblox itself says)
- **44% of the top 1,000 creators** (ranked by Robux spend, measured Mar 6 - Apr 7 2026) use Roblox Assistant or third-party
  AI via MCP to plan, build and test. Source: Roblox, "Roblox Studio is Going Agentic", 2026-04-15
  (https://about.roblox.com/newsroom/2026/04/roblox-studio-going-agentic ; method detail via
  https://thisweekinvideogames.com/news/roblox-says-44-of-its-top-1000-creators-use-ai-tools-to-make-their-games/).
- Same announcement: Planning Mode (reads code + data model, asks questions, writes a reviewable plan / task manifest),
  Mesh Generation (textured meshes from text, live), Procedural Models (parametric instances rebuilt by a Luau Generator
  Module when attributes change, "coming soon"), **Playtesting Agent beta** (tests against the plan, reads logs, simulates a
  player), a self-correcting plan-build-test loop, and a **built-in Studio MCP server** for Claude, Cursor, Codex.
  Procedural-model detail: https://www.bloxbot.ai/guide/whats-new-roblox-ai-2026 (vendor blog).
- Creator quote in that post, Malt (creator of **Solo Hunters**): "community members could surface bugs or feature requests
  and my AI system could review and complete tasks overnight. When I wake up, all I have to do is check the pull requests."
  Solo Hunters scale for context (Rolimons): 61.0M visits, all-time peak 84,523 CCU, created 2025-03-17
  (https://www.rolimons.com/game/136599248168660). It is a dungeon RPG with a PR-based AI workflow: the closest documented
  "real hit game run with an AI agent" we found. How much of it was AI-built is NOT documented.
- **4D generation (Cube foundation model)**, beta Feb 2026: schemas Car-5 (body + 4 working wheels) and Body-1 (single mesh);
  scripts are retargeted to each generated object's size. In **Wish Master** (dev Laksh) players wish objects into the game:
  160,000+ objects generated in early access and "a 64% increase in play time" for players who used it
  (https://about.roblox.com/newsroom/2026/02/accelerating-creation-powered-roblox-cube-foundation-model).
  Lesson: the one hard AI number on Roblox is AI as a *gameplay feature*, not AI as the art department.
- Roblox Build (mobile, July 2026; demoed RDC 2026): one prompt gave a 6-NPC neon farm in 10-15 min. Reviewer: functional but
  "weird"; devs worry about low-quality floods; a studio dev says players still crave "that human element"
  (https://www.pockettactics.com/roblox/ai-build ; https://techcrunch.com/2026/07/16/roblox-launches-an-ai-powered-game-creation-feature-in-its-mobile-app/).
- Thumbnail personalization (not AI-made art, but the marketing loop AI art feeds): up to 5 active thumbnails, multi-armed
  bandit on qualified play-through rate, hourly reallocation; average **+8.5% qPTR, some +50%**
  (https://gamesbeat.com/roblox-will-let-game-devs-personalize-thumbnails-to-attract-more-players/).

## 2. Model quality on Luau (benchmarks)
- Roblox's **OpenGameEval** (https://github.com/Roblox/open-game-eval/blob/main/LLM_LEADERBOARD.md): 87-eval set, best Pass@1
  is Claude Fable 5 at 50.34%, Opus 4.6 48.05%, Gemini 3.5 Flash 48.05%. Debug set: Fable 5 64.67%, Gemini 3.1 Pro 56.67%,
  GPT-5.4 (M) 51.33%. So even the best model fails about half of open Studio tasks on the first try.
- BloxBot analysis (vendor blog, https://www.bloxbot.ai/guide/opengameeval-fable-5-bounded-tasks): bounded debug tasks (one
  script, one observable failure, what may change, how to verify) scored 30+ points higher than open-ended generation.
  "A weaker model with a precise target and a test can be more useful than the benchmark leader facing a vague request."

## 3. Documented case studies
| Case | Tools | Worked | Failed |
|---|---|---|---|
| "Mining Tycoon", solo dev, ~11 h MVP (https://medium.com/@andy.a.g/i-built-a-roblox-game-using-only-ai-agents-heres-what-happened-ed57b553facc) | Claude via a 54-tool Studio MCP; 130-line design doc then a 970-line implementation plan before any build | "absurdly good at writing Roblox server scripts": mining, 10-tier loot, selling, upgrades, saves (~90% logic success, author's figure); 500 procedural blocks in seconds | "zero visual feedback": portal placement, block animations, UI layout needed a human; many 30-60 s visual fix cycles |
| Obby built by Codex vs Claude Opus vs Claude Fable from one prompt (https://note.com/hottarita/n/nb972e1eb21db?hl=en) | Official Studio MCP + a shared manual of **28 known pitfalls** and numeric spacing rules | All three ran Play tests themselves and fixed issues; Codex most game-like (8 stages, 1,200 studs); Fable best UX (checkpoints, timer) | Codex: rotating bar broken, overlapping UI. Opus: no timer/checkpoints, goal marker followed the player. "Difficulty adjustment is something humans still need to do." |
| Rojo + Claude Code guide (https://roxlit.dev/blog/how-to-use-claude-code-with-roblox, vendor blog) | Rojo file sync, CLAUDE.md with Luau rules + anti-patterns, paste Studio errors back | Specific prompts; matching existing style; checkpoint system in 15 min vs "a couple hours" | Without CLAUDE.md the model drifts to JS / vanilla Lua; vague "make a save system" prompts; trusting client data |
| Claude workflows overview (https://www.obby.fun/blog/claude-ai-roblox-studio, vendor blog) | Chat copy-paste or Studio MCP | Multi-script architecture, refactors to typed Luau, reasoning from stack traces | Cannot see Explorer/terrain/UI; recommends one bounded edit at a time, backups / version control |
| ChatGPT for Blender Python, pro character artist Mihai Dobrin (https://www.creativebloq.com/how-to/use-blender-to-level-up-your-video-game-assets) | ChatGPT writing bpy scripts | "the code generated for Blender works well, unlike that for Maya"; good when the problem is stated algorithmically | Needs the user to describe the problem as an algorithm |
| Codex skill "blender-lowpoly-assets" (https://github.com/0x0bug/blender-lowpoly-assets) | Codex + bpy: reference analysis, blockout, silhouette review, detail, cleanup, GLB export | Renders front/side/3-4/game-camera previews; a validator audits tris, normals, materials, transforms; export reimports and keeps the old GLB if validation fails; rejects stale preview renders; ~1,500 tris, 4 texture-free materials | Excludes rigs and shaders; says artistic fidelity and intersection-free geometry still need human review |

Not found (searched, no documented source): a front-page Roblox hit stating its 3D art was AI-generated, or any documented AI
sound/music pipeline for a Roblox hit. Steal a Brainrot (25.4M CCU peak) is built on the Italian-brainrot meme, but its
Wikipedia page does not say its assets were AI-made (https://en.wikipedia.org/wiki/Steal_a_Brainrot). The AI-art backlash
is real both ways ("AI slop" accusations against devs: https://www.creativebloq.com/ai/ai-slop-has-become-a-harmful-insult-hurled-around-with-no-evidence-game-developers-claim).
devforum.roblox.com (thumbnail-AI tools, 4D beta thread) is blocked from the container; only titles were seen.

## 4. Patterns across the cases
1. Code is the solved part; space, look and feel are not. Every case says server logic works, visual placement and UI do not
   without eyes on the result.
2. Plans before prompts. The successful builds wrote a design doc plus a long plan (130 + 970 lines) or used Planning Mode.
3. A pitfalls file is the single biggest quality lever (28-pitfall manual; CLAUDE.md with anti-patterns).
4. Agents that playtest themselves catch their own bugs, but not difficulty or fun.
5. Bounded tasks (one target, one failure, one check) beat open requests by a wide margin.
6. 3D by code works when the asset is constrained (tri budget, palette, pivots) and judged from renders against references.
7. The measurable wins come from shipping-side loops: bandit-tested thumbnails, AI as a player-facing feature.

## 5. Practices to adopt in the Swarm Break pipeline (10)
1. **Pitfalls file per domain.** Add `game/PITFALLS-LUAU.md` and `tools/blender/PITFALLS.md` (numbered, one line each, with the
   bad output and the fix), loaded into every Codex/Claude task. Grow it after each judge round. (Hottarita; Roxlit.)
2. **Every Codex task is bounded.** Template: target file(s), the failing test or observable symptom, files allowed to change,
   the exact check (`stylua --check && selene && lune run tests/run.luau`). No "build the weapon system" tasks. (OpenGameEval.)
3. **Plan file before code.** For each feature, a short spec plus a step plan in the repo, reviewed before Codex runs; the
   judge later scores the result against that plan, not against taste. (Mining Tycoon; Planning Mode.)
4. **Give the model eyes.** Keep the render-from-script loop as the only way to accept art: front, side, 3/4 and the actual
   game camera (top-down, at enemy scale), next to the reference sheet. Reject a judge verdict that cites a stale render.
   (blender-lowpoly-assets; "zero visual feedback".)
5. **Validator gates before judges.** Script checks first (tri budget, material count, normals, applied transforms, pivot at
   feet, bounding size in studs); only passing meshes go to the visual judge. Export to temp, reimport, keep the last good
   file on failure.
6. **Layout as data, not as placement.** Put arena layout, spawn rings and UI anchors in Luau tables with numeric rules
   (min spacing, safe zones) and test them in Lune, because spatial guesswork is where agents fail.
7. **Laptop playtest checklist for Zion.** The cloud cannot run Studio; once Studio MCP is on the laptop, let an agent run
   Play and read the Output log, but tuning (difficulty, wave pacing, feel) stays a human call each build.
8. **PR-style overnight queue.** Bugs and requests go in as small issues; the agent opens one change per issue with its test;
   Zion reviews diffs, not code dumps (Malt's model).
9. **Thumbnails as a pipeline output.** Render 5 distinct thumbnails from the Blender scene (different hero, enemy colour,
   camera) and run them in thumbnail personalization from day one; read qPTR, replace the losers. Avoid generic AI-image
   look; our own renders keep the game honest and avoid "AI slop" accusations.
10. **Scope AI-generated meshes to props, test them.** If we try Roblox Mesh Generation or 4D, use it for one-off props or a
    player-facing feature (e.g. a "summon" pickup), not for enemies or the hero, which must match our faceted style sheet.
11. **Model routing.** Codex for well-specified Luau and test writing; a second model as debugger/judge on failing tests
    (debug Pass@1 is far higher than open generation). Record which model fixed what in the gauntlet log.
