# Codex L2: runtime art loader for the Landing Pad (2026-10-04)
Base: integrate/wave13 head merged with art/landing-pad at 22d1874. Branch: codex/w26-l2.

Rules:
- Runtime-safe APIs only.
- Failing spec first.
- No scripts from the art.

testcmd: cd game && stylua --check src tests && selene src && lune run tests/run.luau && lune run ../tools/lint_runtime_apis.luau && rojo build default.project.json -o out.rbxl

Inputs:
- Shared/Art/LandingPad.json: 950 entries, each with Kind Floor/Wall/Cover/Prop/Light. Fields: Name, ClassName, MeshId, TextureID, Size, CFrame (12 numbers), Color (RGB 0-255), Material, Transparency, CanCollide, Anchored and CastShadow. Optional: Shape, SurfaceAppearance{ColorMap} and Lights[].
- Shared/Art/LandingPadMood.json.
- Format notes are in game/assets/art/KitImport.md.

1. **ServerStorage/ArtLoader:**
   - Build Workspace/Arena/Art/LandingPad from the JSON at server start.
   - MeshParts use `AssetService:CreateMeshPartAsync(MeshId, { CollisionFidelity = Enum.CollisionFidelity.Default, RenderFidelity = Enum.RenderFidelity.Automatic })` inside a pcall, cached per MeshId and cloned for repeats. **The options table is required; positional Enums crash** (see the r1_rigs spec).
   - Apply the rest of the fields, SurfaceAppearance ColorMap and Lights.
   - Everything is Anchored. Decorative pieces get CanQuery false and CanTouch false (Floor, Wall and Cover keep CanQuery true for combat raycasts).
   - Yield every 50 parts.
   - If a mesh fails, log once and skip that part; never error.
2. **ArenaBuilder:** when Art/LandingPad has loaded, skip building the Landing Pad's primitive floors and props and PropScatter for that zone. Gates, spawns, bridges and the other zones are unchanged. The floor collision must still cover every ArenaLayout.floorRects rect for the Landing Pad (spec it from the JSON: every rect point is under a CanCollide Floor entry, or keep our invisible primitive floor under it as a safety net, whichever is simpler).
3. **Mood:** a Lighting preset `LandingPad` from LandingPadMood.json, applied while players are in the Landing Pad zone (replacing the Station ClockTime 14.5 override there). The Bloom caps from the bible still apply (intensity ≤ 0.5, threshold ≥ 1.5).
4. **Terrain:** it isn't code-managed. It lives in the Studio place (Rojo doesn't touch Terrain); document this in KitImport.md. The loader never clears Terrain.
5. **Specs:**
   - The JSON parses, and every MeshPart entry has a MeshId.
   - The source uses the options-table call form.
   - Gate lanes and the 20-stud core are clear of CanCollide entries.
   - The Landing Pad floor rects are covered.
   - The mood preset respects the bloom caps.
   - The part count is 1,500 or fewer.
