## V1 Duckable: "I Tested Every Roblox AI" (21:18, 560K views, 3 weeks ago), youtube.com/watch?v=MBRNAqkDEFA
- **Setup:** one game idea (a card-shop organiser) given to 4 AI tools, then his own Claude workflow.
- **Roblox Assistant (built into Studio):**
  - Made a bright, basic build.
  - Card spawn and pickup worked after some tweaking.
  - Each prompt took about 30 minutes and the daily limit cut him off.
  - On a later day it finished the shelves, the highlight abilities and a 3-card upgrade pick. He called it "insanely bare bones", with bad building and bad UI.
  - It was the only one of the four that finished.
- **Super Bullet:**
  - Broke with its own tool errors and went to −25,000 tokens.
  - On the paid tier ($20) it kept pushing marketplace templates. Its showcase combat systems are **pre-made by hired developers and dropped in**, not generated.
  - It crashed mid-task with "token expired" and produced nothing usable.
- **Lemonade.gg:**
  - A slick UI with graphs and nodes that do nothing.
  - Broken shelf placement. Ran out of credits.
- **Forge GUI:**
  - Fast, but the trial ran dry after 1 prompt, then a $16 paywall and dark patterns when cancelling.
  - Many tiny new YouTube channels advertise it.
- **Sponsors:** AI tools pay small creators 8–12× under market rate.
- **What worked for him: Claude connected to Studio over MCP, with him in the loop.**
  - He **built the map and models by hand** (the card shop and the card franchises).
  - Tip 1: ask Claude for directions and follow the breadcrumbs.
  - Tip 2: always read what it writes.
  - Tip 3: type the code out yourself rather than pasting it.
  - Tip 4: be polite.
  - The result was a small working card game with a hand-built look.
- **Takeaway:** the AI-only tools make bare-bones, ugly games. Good-looking AI-assisted games have **hand-built (or bought) art and systems**, with AI doing the glue code.

## V2 Scuppy: "I Asked Opus 5.5 To Make My DREAM Game!" (16:20, 19K views, 1 day ago), youtube.com/watch?v=IFtKCN8jw6o
- **Tools:** Claude Opus 5.5 ("extra" effort) connected to Studio over MCP, with Claude also making **Blender models** (taxi with interior, props, buildings, monsters, hair and hats).
  - The 5x Pro limit ran out after 2 hours, so he bought Max.
- **Time:** about 3 hours for the first playable, plus a polish pass.
- **By hand:** idea, prompting, playtests, design calls. He asked for a Dead Rails / A Dusty Trip style of random-generated road.
- **By AI:** all the code and models, the UI ("make the UI look like a billion-dollar company made it"), a cartoon restyle with **black outlines on buildings and the taxi**, the title and loading screens, a Robux store and a thumbnail.
- **Look:** bright cartoon city and desert road, chunky low-poly taxi with outlines, a polished menu and title.
  - Interiors and physics are still rough (backwards speedometer, grass physics).
  - Features are fun: pizza on the seat spills over potholes, flat tyres, a spare in the trunk, radio stations, night monsters.
- **Takeaway:** the fun comes from **systemic little interactions** (potholes, spills, tyres) and a **strong one-line hook**, not from VFX. Claude can model in Blender over MCP. He released it the same day.

## V3 AI PILLED: "ChatGPT vs Claude Make A Viral Roblox Game" (15:35, 127K views, Sep 28), youtube.com/watch?v=elqpTtfFD40
- **Game:** "Chop to Mog", a clicker plus NPC duels.
- **Tools:**
  - **GPT-6 Astra in Codex** for most of the code.
  - **Claude Fable 5.1 in Claude Design** for a 3D hammer, exported as .glb and brought in with Studio's Import.
  - ChatGPT images for the character, faces and dev-product icons.
  - **Fish Audio** AI voices (announcer: "LEVEL UP", "REBIRTH READY", 3-2-1-GO, "MOGGED"), generated through its API by Codex.
  - Both models connected to Studio over MCP.
- **Process:**
  1. Prototype from one long prompt plus a reference image.
  2. Codex reskins one base hammer into a tier set and builds rank body templates.
  3. **A VFX pack he already had** ("I also have all these VFX") is applied by Codex to each hammer and treadmill.
  4. Map: Codex made 3 **concept images** first, then both models built the chosen one. GPT built a richer lobby (checkered floor, statues, foliage) and Fable's was "bland".
  5. Dev products uploaded by hand; IDs given to Codex to hook up.
- **Cinematic:** the duel has a camera pan from player to NPC and a zoom-out, and the loser is **flung through walls**.
- **Launch:** Roblox ads at $40/day for 3 days. Players arrived, but revenue was only 19 R$ at first (about 7k R$ on his previous game).
- **Look:** saturated simulator style:
  - glowing tiered podiums that hover and spin;
  - stroked gradient fonts;
  - moving-arrow treadmills;
  - emoji particles flying to the XP bar.
- **Takeaway:**
  - Concept image → build-to-image.
  - Reuse VFX packs.
  - Voice lines for every milestone.
  - A juicy reward-feedback loop (particles fly to the bar, the button pulses).
  - Spend on ads.

## V4 LanceyPoo: "I Tried Making a Viral Roblox Game With AI" (21:54, 339K views, Aug 11), youtube.com/watch?v=xxeNaxrfRVs
- **Game:** "My Duck Empire", a simulator copy of My Fish Empire.
- **Tools:**
  - **Claude Code connected to Studio over MCP**, plus **Claude Design for 3D models** (a duck exported as .glb and imported).
  - ChatGPT for UI icons. Claude even prompted ChatGPT for images by itself.
- **Process:**
  1. Claude breaks the game loop into steps.
  2. A small concept build.
  3. **Reference images of a low-poly style** sent to steer the art. Claude spawned all the terrain in one go.
  4. Duck variants generated **procedurally from one base mesh** (accessories, VFX, materials, palettes).
  5. Hand-made 3D bread pickups that act as physics objects with gravity.
  6. Dev products set up by hand, then playtests with friends found bugs and mobile problems.
- **Result:**
  - Looked clean in a low-poly style.
  - **Ads: $6.24 bought 83K impressions, with a poor click-through rate.**
  - Players left right after the tutorial when they couldn't afford the next egg.
  - 0 players after one day.
- **Takeaway:** a good look isn't enough. **The first minute decides it**: tutorial → first purchase must be instant and rewarding. Low CTR thumbnails kill the ads.

## V5 SyphoDev: "How to Make a Roblox Game With AI (Claude Opus 5.5 Full Tutorial)" (24:46, 9.9K views, 9 hours ago), youtube.com/watch?v=afuKhenJldY
**The most relevant to us. It is close to our setup and says exactly why AI games "all look the same".**
- **Core point:** most AI-made games ask one AI to write *everything as code* (map, UI, models), so they look like part piles. He instead gives **each discipline its own skill, tools and checker**.
- **Stack:**
  - Claude Code (Opus) on his own PC.
  - Studio's built-in MCP (it can test in play mode), with a 3rd-party MCP as fallback.
  - Rojo with files as the source of truth.
  - Open Cloud API key for uploads. He tells Claude to store it as a secret env var and never pastes it into chat.
- **Code skill:**
  - Rules and numbers live in a plain config folder that can be tested outside Roblox.
  - 4 gates before Studio: rojo build, tests, linter, formatter. Every remote is named in one file.
  - "Traps that cost me days" are written down. Same as our approach.
- **UI skill:**
  - One spec produces a preview image, the UI file and a Studio build script.
  - Every panel gets a **"depth stack"**: a slightly blue-shifted drop shadow, a gradient face, a top highlight, and the **same outline thickness everywhere**. "Mixed outline thickness is the biggest giveaway of beginner or AI UI."
  - Icons are generated with Flux (Cloudflare Workers AI, free tier), never emojis.
  - Checked at 4 screen sizes: thumb-size tap targets, nothing overlapping, centring within 1.5 px, a minimum text size, no stray boxes.
  - The UI style is **trained on screenshots of top Roblox games** and kept as a template.
- **Map skill:**
  - Measured with raycasts against the game's real movement numbers.
  - 9 checks: floating platforms, tops you can't stand on, unreachable high ground, reachable-but-shouldn't, pits with no way out, sight lines, overlaps, ring spacing, fall heights.
  - **Visuals are meshes, not parts** (Blender or the 3D skill), styled from **screenshots of a reference game**. He used one with an anime-stylised texture look.
  - Every model has a triangle budget.
- **3D skill:**
  - Flux image → Claude checks it → **Hi3DGen (MIT, open source) on Kaggle's free GPU (30 h/week, ~100 s per asset)** → about 600K faces.
  - Blender runs headless and decimates to 6–10K, **baking the lost detail into a texture**. Hard-edged items (crates, guns) are modelled directly in Blender.
  - Upload via Open Cloud.
  - He rejected Hunyuan3D because its licence excludes the UK.
- **VFX skill:**
  - Doesn't generate VFX. It **harvests free toolbox VFX packs**, classifies the parts (ball, flame, beam…) and recombines them into new effects.
  - Checks with a **"phase freeze"**: fire the effect, freeze the particles at start, middle and end, and screenshot each.
- **Sound:**
  - Open Cloud audio uploads are capped per month, so he reuses a library of harvested, named sounds (boom, fire, gunshot) and layers them.
- **Animation skill:**
  - Poses as joint data → Blender renders R15/R6 frames into a contact sheet → Claude checks it.
  - Claude is weak at this, so it is trained on real Roblox animations.
- **Manager skill "create Roblox game":** research → design → assigns jobs to the other skills → assembles the game.
