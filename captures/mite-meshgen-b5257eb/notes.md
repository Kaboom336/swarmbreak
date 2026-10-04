# Mite: Studio AI mesh generation test (b5257eb arena)

- Prompt: "chunky cartoon alien bug, purple chitin shell plates, glowing teal eyes, six short legs, stylized low poly game asset, no blood"
- Bounding box: 5x3x6 studs.
- Screens: b5257eb playtest, arena near PlayerSpawn, midday lighting, HUD hidden. The stand-in player is a default R15 rig from a blank HumanoidDescription, which renders black.
- **Note:** Studio's generate_mesh uploads each result as an asset under the signed-in account (it returns a `publishedAssetId`). Nothing was published to a game, and the scratch place wasn't saved.

| Variant | Settings | Triangles | Asset ID | Result |
|---|---|---|---|---|
| v1 | single mesh, max 3000 | 2,972 | 80170350433620 | Round purple shell "pill bug" with **teal goggle eyes**, cute and readable. Only 4 stubby legs are visible, not six. The best match for "chunky cartoon". |
| v2 | explicit parts (body, head, left legs, right legs), max 6000 | 5,348 (4 parts) | 72113755441326 | **Broken:** the legs came out as loose pieces, separate from a box-like body. Not usable without rework. |
| v3 | auto parts, max 1500 | 1,500 (3 parts) | 138386611904560 | Best bug silhouette: domed purple chitin shell and six jointed legs. **The eyes are missing or not glowing.** It reads more beetle than cartoon. |

Takeaways:
- The silhouettes are on-brief, and the matte purple reads well against the midday arena.
- Neither good variant has the glowing teal eyes as asked. They'd need an emissive eye part added in Studio (a Neon part or a SurfaceAppearance).
- None is rigged or animated. Legs need rigging (Studio auto-rig or Blender) before they can walk.
- Pick: **v3** for the body and leg count, with v1-style teal eyes added. Or regenerate v1 with "six legs" stressed.
