# Mite v4 (Studio generate_mesh) and rig, shot in the b5257eb arena

Prompt: v3 prompt plus "big glowing teal eyes, small curved mandibles, two-tone shell lighter violet top with darker plum underside, thin orange stripe on the shell rim". Size 5x3x6 studs.

| Variant | Settings | Asset ID | Notes |
|---|---|---|---|
| A | auto parts, max 2000 tris (the first attempt failed with "Generated model download failed"; retried) | 95704530005689 | shell + legs + eyes parts; tusk mandibles, teal eyes, cream rim |
| B | auto parts, max 3000 | 80566052020268 | shell + legs + eyes; small, with a horn-like antenna |
| **C (picked)** | explicit parts: body, head, leg 1..6; max 3000 | 131985817622116 | Two-tone violet/plum shell, orange rim stripe, teal eyes, mandible teeth, **6 separate legs**, so it's riggable |

In 00-v4-three-variants.png the camera looks +Z, so screen-left is C, the centre is B and the right is A.

Rig (`game/assets/rigs/Mite.rbxm`, model "Mite", about 3.6x3.0x3.9 studs):
- `Body` is the root (PrimaryPart). It is anchored in the file, so unanchor it when spawning.
- `Head` and `Leg_1`..`Leg_6` are children of the model, joined by Motor6Ds parented to Body: `Neck` and `Hip_1`..`Hip_6`. C0/C1 are set at each leg's top centre (the hip).
- Two `Eye_Glow` parts: Neon teal balls welded to Head.
- Attributes: Role=Mite, Front=-Z, SourceAssetId=131985817622116.
- Mesh and texture refs are rbxassetid URLs generated under Zion's account.

Caveat: the file was written by Roblox's own SerializationService (same format as Studio "Save to File"). **Rojo 7.4.4 can't read it** ("MeshPart.Tags should be SharedString"). Insert it with Studio's Insert From File, or upgrade Rojo before using it via `$path`.

Shots: 01 is the rig next to the player avatar (Zion's own avatar, the default spawn). 02 is a 5-Mite crowd.
