# Copper Compass — one-earner check

Decision: show this one Common earner to Zion before making any of the other 24. This is an offline self-judge, not an independent critic or an in-engine approval.

## Reference and evidence

Best-in-class reference for this task: **Steal a Brainrot**, the terracotta **Ta Ta Ta Sahur** kettle character on a pedestal. Inspected the supplied `C:/dev/codex-lab/refs/videos/steal-a-brainrot-sheets/s001.jpg`, then selected the clearer individual `C:/dev/codex-lab/refs/videos/steal-a-brainrot-frames/f_008s.png`. The individual frame and contact sheet show different moments at their 00:08 labels; the individual frame is the actual comparison source. No claim about video chronology beyond that filename.

Crop: source pixels **x=135, y=130, width=115, height=126**; saved as `reference-crop.png`. This includes the kettle body, handle, spout, legs and pedestal. Source compression and resolution limit facial detail. The footage is comparison evidence only, not adopted game art; redistribution rights are UNKNOWN.

`SBS-copper-compass.jpg` puts that crop left and the three variants right. `before-normal.png` and the other `before-*` images preserve the initial pass. `final-normal.png`, `final-gold.png`, `final-diamond.png` and `final-40stud.png` are offline Blender renders, not Roblox captures. Camera orientation is an image-based estimate: about 18 degrees to the front and 19 degrees down; original camera metadata is UNKNOWN. The comparison crops the renders to compare character scale. No claim of calibrated pixel matching.

## Initial self-judge: three biggest gaps

| Gap versus reference | Evidence | One fix round |
|---|---|---|
| Treasure identity is weaker | The kettle's handle and spout identify it immediately. Our unclosed top notch resembles ears. | Close the loop with a grid bridge; keep a visible one-cell hole. |
| Face competes with the object symbol | The reference separates its face from the kettle's main shape. Our long central cross reads like a cross/nose before a compass needle. | Angle the needle northeast above the eyes; replace the lower shaft with a small copper mouth. |
| Lighting is a poor match | The reference is bright and flat; initial render makes the copper muddy and the carpet very dark. | Use a bright neutral environment. Also lower the installed visual by 0.2 studs to seat its feet on the actual pedestal top. |

Exactly **one model design fix round**. No content expansion. The revised character is 6 studs tall on a 0.5-stud grid; eyes each occupy exactly one grid cell, not one full stud. During proof QA, the renderer's vertical cell indexing was corrected so simulated studs touch the surface instead of floating. This changed only the offline stud approximation, not the Roblox model or its exported boxes.

## Gaps left for Zion

1. The symmetric dial can still read as a pocket clock. The compass needle and suspension loop need Zion's recognition check before expanding the set.
2. Our stubby legs and simple square eyes have less personality than the kettle's long legs, handle and spout. The constrained voxel style deliberately keeps fewer cues; this is not evidence of matching the reference's charm.
3. Offline lighting, stud cylinders and emissive Diamond material approximate the engine. Actual mutation contrast, 40-stud readability, replication and walking feel in Roblox are **NOT RUN**. The 40-stud image is a camera-distance preview, not a runtime pass.

## Implementation and reuse

- Task constraints: `pumpkin/patch-panic`; no Studio, commit, publish, account, spend, asset upload or messages. Output stays in the requested folder, with the existing base build outputs in their established location.
- Reused the user-named `giant/scene/VoxelKit.luau` greedy rectangle builder. Original demo source is retained in `source/VoxelKit.luau`; runtime `VoxelKit.luau` returns the builder instead of creating unrelated demo characters, and disables collisions, queries and touches. The originals were not edited.
- Copied `giant/scene/VoxelModels.luau` into this folder as the local reference for grid/palette authoring. It retains its old command-bar side effects and is intentionally **not mounted or executed**. The new character uses the copied kit's +Z convention; no legacy 180-degree facing correction is inherited accidentally.
- No project-level open-source licence was found in the inspected project root. These are internal project sources reused under Zion's explicit instruction, not claimed to be externally licensed assets. No downloaded kit or reference geometry was used.
- `Registry.luau` selects def 1 only. `EarnerModel.luau` retains the authoritative Part and its prompts/attributes; its child `Visual` holds the anchored grid model. Other definitions retain their placeholders.
- `EarnerVisual.client.luau` follows replicated server movement locally. Only Carpet/Delivering movement advances the two-frame distance-based leg bob. Placed/Carried states reset it. No remote or gameplay position is written by the client visual.
- Normal: copper, cream, black. Gold: gold, pale gold, black. Diamond: blue, pale ice, black, plus one cyan neon needle. All use identical geometry.
- Export: `parts.json` comes from the actual Luau factory; `render.py` emits the corresponding `normal/gold/diamond.obj` and `.mtl`. Render-only studs approximate SurfaceType. They are not additional Roblox Parts. `.blend` files preserve the proof scenes.

## Checks and limits

Read `CHECK-RESULT.txt`, `../OFFLINE-RESULT.txt` and `../BUILD-RESULT.txt` for measured counts and final pass totals. Tests cover the <250 budget including both invisible roots, anchored/non-colliding parts, identical mutation transforms/sizes/counts, 1x1 black eyes, top studs, Diamond-only neon, both walk frames, idle reset and placeholder fallback. The rebuilt place is `../steal-a-treasure-base.rbxl`.

The Rokit `lune` shim was attempted and failed with `home directory not found`; the installed **0.10.5** binary is the fallback used for verification. Blender is the existing `C:/dev/codex-lab/tools/blender/blender.exe` installation. Reproduce from production:

```powershell
& 'C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe' run slice-v2/base/check.luau
& 'C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe' run slice-v2/base/build.luau
& 'C:/dev/codex-lab/tools/blender/blender.exe' -b -t 4 -P slice-v2/base/earners/render.py -- final
& ./slice-v2/base/earners/compose.ps1
```

Read the Roblox production skill and the local `C:/dev/codex-lab/pumpkin-loop/PLAYBOOK.md`. The exact Keystone note **Roblox Process Playbook** could not be located through available local evidence/tools; its exact contents are UNKNOWN. Applied the user's supplied voxel lesson and make-one checkpoint. Studio, Play, multiplayer, mobile, actual client replication, runtime walk and fun: **NOT RUN**.

## Lessons

1. When a server moves a single anchored Part, attach a visual through a separate client pose hook, because changing that authority contract would spread an art task into gameplay code.
2. When proving a scripted grid, export the actual factory output, because a second manually authored render model can hide differences from the shipped geometry.
3. When comparing to gameplay footage, match light and apparent character scale before judging detail, because a dark, smaller render exaggerates the quality gap.
