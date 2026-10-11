# TOOLING-ROBLOX: scout for building top-quality Roblox games faster

Read-only research, 2026-10-11. Nothing installed. Not duplicating the general TOOLING.md list (frontend-design, hookify, playwright, netlify-skills, codex are already installed).
Already available in this setup and NOT re-listed as new: the `Roblox_Studio` MCP (execute_luau, generate_mesh, generate_texture, generate_material, generate_procedural_model, insert_asset, screen_capture, start_stop_play, etc.) and the local `roblox-builder` skill. SearchSkills (roblox, luau, game dev, 3d, ui design, blender) returned nothing; the MCP registry has no Roblox or Blender connector (only SketchUp and a Three.js demo viewer).

Verification key: V = read on the repo page this session; S = search snippet only, confirm before relying; U = not verified.

## Top 10 to adopt now

| # | Item | Pillar | Why | Licence | Risk |
|---|---|---|---|---|---|
| 1 | **Rojo** (rojo-rbx/rojo) + **Wally** + **Selene/StyLua** | workflow | Files-on-disk Luau, git, lint. Lets Claude/Codex edit scripts without the Studio round trip. | Rojo MPL-2.0 (V), Selene MPL-2.0 (V), Wally U | Low. Local CLIs. Keep one source of truth (do not edit scripts in Studio and disk at once). |
| 2 | **ProfileStore** (MadStudioRoblox/ProfileStore) | progression/economy | Session-locked DataStore saves; ProfileService is deprecated in its favour. | Apache-2.0 (V) | Low. Pure ModuleScript. |
| 3 | **Vide** (centau/vide) | UI/HUD | Solid-style reactive UI, typechecked, small. Fastest route to polished HUD and menus in code. | MIT (V) | Low. Pick Vide OR Fusion, not both. |
| 4 | **Sleitnick RbxUtil** (Signal, Trove, Spring, Shake, Timer, TableUtil, Input, PID) | core loop feel, workflow | One repo covers cleanup, springs, camera shake (Shake), input, timers. | MIT (V) | Low. Pull only the modules needed. |
| 5 | **Blink** (1Axen/blink) | combat/boss, workflow | IDL-generated buffer networking: typed, fast, low bandwidth for hit events and boss state. | MIT (V) | Low. Needs a build step; docs at 1axen.github.io/blink. |
| 6 | **Official Roblox Blender plugin** (Roblox/roblox-blender-plugin) | models/art | Sends meshes from Blender straight into Studio via Open Cloud. | Open source (S; licence file U) | Medium: asks you to link your Roblox account and an API key. Use scoped key. |
| 7 | **Kenney + Quaternius packs** | models/art, UI/HUD | Clean, consistent low-poly models, UI kits, SFX. Safe for commercial use, no credit needed. | CC0 (V both) | None. Still re-texture/colour-grade so it does not read as stock. |
| 8 | **Blender MCP** (ahujasid/blender-mcp, 30k stars) | models/art | Claude drives Blender: scene build, renders, Poly Haven/Poly Pizza import, Tripo/Hunyuan gen. | MIT (V) | Medium-High: `execute_blender_code` runs arbitrary Python; socket has no auth (localhost only); telemetry on by default, set `DISABLE_TELEMETRY=true`. Poly Pizza models are ~69% CC-BY (need credit). |
| 9 | **Mixamo** animations | combat/boss, first 5 minutes | Large library of attack, hit, death, locomotion clips; retarget in Blender then import. | Free, no royalty, no attribution; cannot redistribute raw files (S, Adobe FAQ via secondary sources) | Needs free Adobe account (Zion signs in himself). Keep local copies; Roblox needs FBX to Blender to Studio flow. |
| 10 | **Lucide + game-icons.net + Kenney UI** icon sets | UI/HUD | Ready icons for HUD, skills, inventory. Upload as Decals, no AI needed. | Lucide ISC (V), game-icons CC BY 3.0 (V, credit required), Kenney CC0 (V) | game-icons needs an attribution line in the game description. |

Honourable mention for #1 slot of the Studio MCP list: **Chrrxs/robloxstudio-mcp** (MIT, V) adds runtime debugging, eval on server/client, script profiler, micro profiler, memory breakdown, multiplayer playtest. We already have the official Roblox_Studio MCP, so verdict is try (profiling/playtest are the gap).

## Full table

### A. Studio plugins
| Item | What | Pillar | Licence | Risk | Verdict |
|---|---|---|---|---|---|
| Roblox Assistant (built-in) | Script/model help, `/generate_mesh` (Cube 3D, text or image, poly cap default 10k) | models/art, workflow | Built into Studio; free quota unconfirmed | Low | Adopt now (already via MCP generate_mesh) |
| F3X Building Tools | Move/resize/rotate/paint with snapping | map/world | Creator Store, licence U | Plugin runs scripts; install only the verified publisher | Try |
| Brushtool | Paint vegetation/props across terrain | map/world | U | Same | Try |
| GapFill / Archimedes | Close gaps; curved structures | map/world | U | Same | Skip until needed |
| Moon Animator 2 | Keyframe animation, cutscenes, boss intros | combat/boss | Paid (~$29.99, S). GitHub copies exist with unclear licence | Pirated copies are a malware and ToS risk | Try only if bought; else use built-in Animation Editor |
| RigEdit Lite | Custom rigs with extra joints (bosses, creatures) | combat/boss | Free (S) | Low | Try when a non-R15 boss is needed |
| Blender Rig exporter/importer (DevForum community) | Roblox rig to Blender armature | models/art | U; code lives in pastebin/gist | Unvetted code | Skip; use Roblox's documented FBX route |
| Studio built-in: Terrain Editor, Lighting (Future), Atmosphere, Bloom/ColorCorrection/DepthOfField/SunRays, Particle/Beam/Trail editors, Material Variants | Terrain, lighting, VFX | map/world, core loop feel | Built in | None | Adopt now; most "AAA look" is lighting and post effects |

### B. Libraries (Luau)
| Item | What | Pillar | Licence | Risk | Verdict |
|---|---|---|---|---|---|
| Vide | Reactive UI | UI/HUD | MIT (V) | Low | Adopt now |
| Fusion (dphfox/Fusion) | Reactive UI, springs/tweens built in | UI/HUD, core loop feel | MIT (V) | Low | Try (alternative to Vide) |
| React-lua (jsdotlua/react-lua; also Roblox/react-lua) | Port of React 17 | UI/HUD | MIT (V) | Heavier; repo URL moved, confirm | Skip unless a React-trained dev joins |
| Roact | Old React-like UI | UI/HUD | Apache-2.0, archived Dec 2023 (V) | Deprecated | Skip |
| Spr (Fraktality/Spr) | Spring motion for any property, one call | core loop feel | MIT (V) | Low | Adopt now for UI juice (or RbxUtil Spring) |
| RbxUtil Shake | Camera shake and noise | core loop feel, combat/boss | MIT (V) | Low | Adopt now |
| Sleitnick RbxUtil (Signal, Trove, Timer, TableUtil, Input...) | General utilities | workflow | MIT (V) | Low | Adopt now |
| Promise (evaera/roblox-lua-promise) | Async flow | workflow | MIT (V) | Low | Try |
| TopbarPlus (1ForeverHD) | Topbar icons/menus | UI/HUD | LICENSE file present, type U | Low | Try |
| ProfileStore | Saving | progression/economy | Apache-2.0 (V) | Low | Adopt now |
| ProfileService | Old saving | progression/economy | Apache-2.0, deprecated (V) | Deprecated | Skip |
| Blink | Buffer networking IDL | combat/boss, workflow | MIT (V) | Low | Adopt now |
| ByteNet (ffrostfall) | Buffer networking | combat/boss | MIT (V) | 14 open issues, maintenance unclear | Try (Blink first) |
| Red (1Axen/red), Packet (Suphi/other) | Networking | workflow | U (404 on guessed URLs) | n/a | Skip; Blink covers it |
| Particle/VFX kit, sound manager | No single trusted open-source kit found in this pass. Use Studio ParticleEmitter + `SoundService` groups and write a ~50-line SoundManager in-house | core loop feel | n/a | n/a | Build in-house |
| Matter/ECS, Knit | Frameworks | workflow | U | Overhead for small games | Skip |

### C. Claude skills, plugins, MCP
| Item | What | Pillar | Licence | Risk | Verdict |
|---|---|---|---|---|---|
| `Roblox_Studio` MCP (installed) | Official proxy; insert/generate/run | all | Roblox | Runs Luau in the place; use on copies | Adopt now (have) |
| `roblox-builder` skill (installed) | Zion's reference-judge loop | all | Local | None | Adopt now (have) |
| Chrrxs/robloxstudio-mcp | Profilers, playtest, eval, Open Cloud monetization | workflow, core loop feel | MIT (V) | Arbitrary Luau; monetization needs Open Cloud key (skip that tool); `npx @latest` unpinned | Try (pin version) |
| Meganugger/roblox-studio-mcp | Bearer-token auth, localhost bind | workflow | U (S) | Lower than peers | Try if security wanted |
| boshyxd/robloxstudio-mcp | Original, archived by author | workflow | S | Archived | Skip |
| Justice219 / jundayoo / princeofscale / majidmanzarpour Roblox MCPs | Overlap | workflow | MIT for princeofscale (S), others U | Unvetted | Skip |
| Blender MCP | See top 10 #8 | models/art | MIT (V) | See above | Adopt now with caveats |
| SearchSkills / SearchPlugins / MCP registry | Nothing Roblox, Luau or Blender listed | n/a | n/a | n/a | n/a |
| Official Anthropic skills already on box: frontend-design | Layout and type thinking for HUD mockups | UI/HUD | Apache-2.0 | None | Adopt now (have) |

### D. Asset sources
| Item | Licence | Risk | Verdict |
|---|---|---|---|
| Kenney (kenney.nl) | CC0, commercial OK, no credit (V) | None | Adopt now |
| Quaternius | CC0, commercial OK, can modify (V) | None | Adopt now |
| Poly Pizza (10,700+ models) | Mixed CC0 / CC-BY; ~69% CC-BY per Blender MCP docs (S). Site page did not state terms (U) | Must log credit per model | Try, filter to CC0 |
| Poly Haven (via Blender MCP) | CC0 (U, widely known, not fetched) | None | Try for HDRIs and textures |
| Mixamo | See top 10 #9 | Adobe sign-in | Adopt now |
| Roblox Creator Store packs | Per-asset terms; free Roblox-made packs are fine | Hidden scripts/backdoors in community models; MCP insert_asset strips scripts (V on Chrrxs) | Try, meshes/textures/audio only, never take scripts |
| Roblox free audio library | Roblox-hosted, free in-engine | Audio privacy changes can break old IDs | Try, test in a published place |
| game-icons.net | CC BY 3.0, credit required (V) | Credit line needed | Try |
| Lucide | ISC (V) | None | Adopt now |
| Phosphor / Tabler / Material icons | MIT / MIT / Apache-2.0 (U, from general knowledge, not fetched) | None | Try |
| Freesound / Pixabay audio | Mixed CC0, CC-BY, CC-BY-NC (U) | NC clauses block monetized games | Try, CC0 only |

### E. AI tools, free
| Item | What | Pillar | Licence / cost | Risk | Verdict |
|---|---|---|---|---|---|
| Roblox Cube 3D via `generate_mesh` | Text/image to mesh in Studio | models/art | Studio feature, quota/price unconfirmed (S) | Check meshes for count and UV quality | Try |
| Roblox `generate_texture` / `generate_material` | PBR textures in Studio | map/world | Studio feature | Quota | Adopt now (have) |
| Roblox/cube open weights | Local generation | models/art | Licence file not read (U) | GPU needed | Skip until licence read |
| Microsoft TRELLIS | Image to 3D | models/art | MIT (V) | Needs Nvidia GPU 16GB+, Linux-tested | Skip locally; use hosted if needed |
| Tripo / Hunyuan3D / Rodin (via Blender MCP) | Image/text to 3D | models/art | Free tiers (U), Hunyuan licence has regional terms (U) | Needs API key; generated topology is messy | Try for greybox props only |
| AI icon/image generators (Bing Image Creator, Leonardo free tier, etc.) | Icons, loading screens | UI/HUD | Terms vary (U) | Style consistency, commercial terms | Try for concepts, hand-pick finals |

## Notes
- Biggest likely gains per pillar: lighting and post-effects (map), Kenney/Quaternius + re-colour (art), Vide + Spr (UI feel), Blink + Shake (combat feel), ProfileStore (progression).
- No item above requires a purchase. Account-needed items: Adobe (Mixamo), Roblox link (Blender plugin), API keys (optional AI gen in Blender MCP).
- Unverified before use: Poly Pizza licence page, Cube licence, Wally licence (MIT per memory, not read), Phosphor/Tabler/Poly Haven terms, F3X licence.
