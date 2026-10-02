# R4: How people use AI to build good Roblox games and 3D art (2025-2026)

EVIDENCE LIMIT: WebSearch returned only titles and URLs (no snippets) and WebFetch is banned. So "evidence" below is
what each URL's title proves exists. Anything about contents is marked [inference] or [unverified]. No numbers invented.
Local context read: research/import-plan.md (models never uploaded; fix = Open Cloud upload + InsertService:LoadAsset).

## 1. What exists (title-level evidence)
- Roblox Cube: core generative 3D/4D system, announced 2025-03; open-source model; mesh generation API for creators.
  https://about.roblox.com/newsroom/2025/03/introducing-roblox-cube
  https://devforum.roblox.com/t/beta-cube-3d-generation-tools-and-apis-for-creators/3558947
  https://techcrunch.com/2025/03/17/roblox-releases-its-open-source-model-that-can-create-3d-objects-using-ai/
- Studio is "going agentic" (2026-04); Studio has a built-in MCP server, external LLM support for Assistant, playtest
  automation agent, multi-agent routing to a specific Studio, "connected AI clients".
  https://about.roblox.com/newsroom/2026/04/roblox-studio-going-agentic
  https://devforum.roblox.com/t/assistant-updates-studio-built-in-mcp-server-and-playtest-automation/4474643
  https://devforum.roblox.com/t/studio-mcp-server-updates-and-external-llm-support-for-assistant/4415631
  https://devforum.roblox.com/t/studio-beta-studio-assistant-mcp-playtest-agent/4566767
  https://devforum.roblox.com/t/studio-mcp-multi-agent-improvements-and-connected-ai-clients/4820583
- Known friction: a DevForum bug thread "Roblox Studio MCP not working with Codex" (title only; cause unverified).
  https://devforum.roblox.com/t/roblox-studio-mcp-not-working-with-codex/4862473
- Third-party Studio MCP servers for Claude Code/Codex/Cursor: weppy-roblox-mcp (scripts, terrain, assets, lighting, sync),
  boshyxd/robloxstudio-mcp, 6xvl/robloxstudio-mcp-server, ZubeidHendricks/roblox-studio-mcp-claude-code.
  https://github.com/hope1026/weppy-roblox-mcp  https://github.com/boshyxd/robloxstudio-mcp
  Walkthroughs: https://luismori.dev/article/roblox-game-development-with-mcp/ , https://useloadout.com/blog/roblox-mcp-server-setup/ ,
  https://www.obby.fun/blog/claude-ai-roblox-studio
- AI textures/materials: Roblox Texture Generator (beta) and Material Generator (GA to everyone) inside Studio;
  third-party PBR generators (playtex.ai, aitexture.ai).
  https://devforum.roblox.com/t/texture-generator-beta/2880635
  https://devforum.roblox.com/t/material-generator-is-now-available-for-everyone/3145555
- Image/text-to-3D generators with a Roblox import guide: Meshy (help article on importing to Roblox; compare vs Tripo),
  Tripo (several Roblox/FBX/scale posts), Rodin not searched. All are vendor marketing: treat quality claims as unverified.
  https://help.meshy.ai/en/articles/11973241-import-meshy-models-into-any-engine-unity-unreal-roblox-godot
  https://www.meshy.ai/blog/roblox-3d-model
  https://www.tripo3d.ai/blog/export-ai-3d-model-to-roblox
  https://www.tripo3d.ai/blog/roblox-3d-model-maker
- Roblox import/limits: official Importer doc, Open Cloud Assets API usage guide, DevForum "How to get MeshId from Model
  upload (Cloud Assets API)" (a model upload gives a Model asset; mesh ids need extra steps), "Open Cloud upload support
  for more asset types", tri-limit threads, Blender export doc.
  https://create.roblox.com/docs/art/modeling/3d-importer
  https://create.roblox.com/docs/cloud/guides/usage-assets
  https://devforum.roblox.com/t/how-to-get-meshid-from-model-upload-cloud-assets-api/3226166
  https://devforum.roblox.com/t/open-cloud-upload-support-for-more-asset-types/4022082
  https://devforum.roblox.com/t/whats-roblox-current-mesh-triangle-limit/2414597
  https://create.roblox.com/docs/art/accessories/creating-rigid/exporting
- Blender + AI: blender-asset-mcp (agent renders, checks, fixes, validates against engine budgets, exports GLB/FBX);
  emeryporter/blender-mcp; a Japanese write-up "Operating Blender with AI instructions alone to create 3D assets for
  Roblox: what worked and didn't" (read it first, closest to our setup).
  https://github.com/yi00it/blender-asset-mcp
  https://note.com/takfuj/n/ned24b1760a17?hl=en
- Polish vs cheap: DevForum "What makes a roblox game polished", "Developer Intelligence: best AI for Roblox Studio in 2026",
  customuse "Best AI for building Roblox games: asset generation test", soonlab "make a Roblox game with AI without a bug pile".
  https://devforum.roblox.com/t/what-makes-a-roblox-game-polished-like-features-wise/2453981
  https://devforum.roblox.com/t/developer-intelligence-the-best-ai-for-roblox-studio-in-2026/4514838
  https://customuse.com/learn/best-ai-for-building-roblox-games
  https://www.soonlab.ai/blog/how-to-make-a-roblox-game-with-ai/

## 2. Fit to our setup (cloud Blender via script, Codex on laptop, Studio on laptop)
- Studio MCP (built-in or weppy-style) runs next to Studio on the laptop, so it fits the Codex-on-laptop thread, not the
  cloud box. Value for us: Codex can insert uploaded assets, set Lighting/Atmosphere IN EDIT MODE, screenshot, and run the
  playtest agent, closing the "looked grey in edit mode" gap in import-plan.md. [inference]
- Our Blender-by-script pipeline already matches the blender-asset-mcp pattern (render, inspect, validate budgets, export).
  Missing step in ours: nobody looked at the result inside Roblox. Render gallery != in-engine look.
- Cube/Meshy/Tripo: good for quick props/rocks/debris/background clutter [inference]; weak for rigged enemies with
  our Motor6D part names (our EnemyAnimator relies on named parts). Keep enemies/weapons hand-scripted in Blender;
  trial generators only for static arena dressing. Quality is unverified: test 3 props before adopting.
- Textures: use Studio Material Generator / SurfaceAppearance for arena surfaces instead of flat colors [inference].

## 3. What separates polished from cheap (only partly evidenced)
Titles show polish discussed as features/feel, not model count; the Japanese Blender-AI write-up and the DevForum
polish thread are must-reads to confirm. My inference: cheap AI games = default lighting, untextured parts, no feedback
juice, unverified assets; polished = one coherent palette, lighting/post-processing, textured meshes, audio/VFX feedback,
and a human looking at in-engine screenshots every iteration.

## 4. Recommended pipeline change
1. FIRST unblock: upload the 40 FBX (import-plan step A) and confirm ids render in Play. Nothing else matters until then.
2. Add an in-engine screenshot gate: Codex+Studio MCP (or manual F5 capture) posts a Play-mode screenshot per milestone;
   Claude reviews that instead of Blender renders.
3. Set lighting/atmosphere/post-FX statically in the place file (not only at runtime) so edit mode looks right.
4. Verify upload type: Open Cloud returns Model assets; check whether MeshId extraction is needed (devforum 3226166).
5. Trial 3 AI-generated static props (Cube API or Meshy) through the same upload path; keep only if they pass the gate.
6. Texture via SurfaceAppearance/Material Generator for arena floor/walls.

## Must-read later (unread, only titles seen)
- https://note.com/takfuj/n/ned24b1760a17?hl=en  (Blender+AI for Roblox, worked/didn't)
- https://devforum.roblox.com/t/how-to-get-meshid-from-model-upload-cloud-assets-api/3226166
- https://devforum.roblox.com/t/assistant-updates-studio-built-in-mcp-server-and-playtest-automation/4474643
- https://devforum.roblox.com/t/roblox-studio-mcp-not-working-with-codex/4862473
- https://devforum.roblox.com/t/what-makes-a-roblox-game-polished-like-features-wise/2453981
- https://customuse.com/learn/best-ai-for-building-roblox-games
- https://create.roblox.com/docs/cloud/guides/usage-assets
- https://github.com/yi00it/blender-asset-mcp
