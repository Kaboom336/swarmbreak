# Enemy roster rigs (Studio generate_mesh, explicit parts), b5257eb arena

Shared style prompt: purple chitin, big glowing teal eyes, small curved mandibles, a two-tone shell (lighter violet top, darker plum underside), a thin orange stripe on the shell rim, stylized low poly, no blood.

| Role | Asset ID | Parts | Size (studs) | Joints |
|---|---|---|---|---|
| Mite | 131985817622116 | Body, Head, Leg_1..6, Eye_Glow x2 | 3.6 x 3.0 x 3.9 (unchanged) | Neck, Hip_1..6 |
| Runner | 107100632849306 | Body, Head, Leg_1..6, Eye_Glow x2 | 5.5 x 3.6 x 5.1 | Neck, Hip_1..6 |
| Shooter | 77762049228079 | Body, Head, Sac, Leg_1..4, Eye_Glow x2 | 3.9 x 4.3 x 6.7 | Neck, SacJoint, Hip_1..4 |
| Tank | 73455430617871 | Body, Head, Leg_1..6, Eye_Glow x2 | 6.8 x 6.2 x 10.0 | Neck, Hip_1..6 |
| Flyer | 112004521386766 | Body, Head, Wing_L, Wing_R, Leg_1..4, Eye_Glow x2 | 6.0 x 4.0 x 4.8 | Neck, WingJoint_L/R, Hip_1..4 |

- Every rig has Body as its root (PrimaryPart). Body is anchored in the file, so unanchor it on spawn. All other parts are unanchored, Massless and CanCollide false.
- Motor6Ds are parented to Body, with Part0 = Body. C0/C1 sit at each hip (the top of the leg), the neck (between head and body), and each wing root.
- Eye_Glow parts are Neon teal (40,235,220) balls welded to Head.
- Attributes: Role, SourceAssetId, Front (about -Z). The Flyer also has HoverHeight=8.
- The size bands were applied to the largest dimension: Runner 5.5, Shooter 6.5 (6.7 including the eyes), Tank 10, Flyer 6 (with hover height 8 as an attribute).
- `game/assets/rigs/<Role>.json` holds each part (Name, ClassName, MeshId, TextureID, Size, Color, Material, Transparency, Shape for Part, CFrame relative to Body as 12 numbers), each Motor6D (Name, Part0, Part1, C0, C1 as 12 numbers), and the welds.

What I noticed:
- **Tank's "legs" came out as wheels.** It reads as a turtle-car (02-roster-close, left). Regenerate it with "insect legs, no wheels" if that's not wanted.
- The Shooter's sac came out as a teal barrel/canister on its back, which reads well as a ranged enemy.
- The Runner reads as long-legged and spidery. The Flyer's wings are translucent teal.
- Same .rbxm caveat as Mite: the files come from Roblox's SerializationService, which Rojo 7.4.4 can't parse. Insert them via Studio, or upgrade Rojo.

The player in the shots is Zion's spawn avatar (about 5 studs tall).

## Tank v3 (regenerated 2026-10-04)

- The prompt for v2 ("...beetle tank... insect legs, no wheels...") still produced wheels, so I dropped the word "tank" and added "organic animal / living animal, no machinery".
- There are 2 candidates (03-tank-v3-candidates.png; the camera looks +Z, so screen-left is candidate 1):
  - Candidate 1 (asset 140399947563019) is a horned rhino beetle with an orange belt stripe.
  - **Candidate 2 (asset 118746674016905, picked)** is a tall plated dome with mandibles and 6 legs.
- The picked rig is about 9.5 studs tall, 10.5 x 9.5 x 9.1. Joints: Neck and Hip_1..6, plus 2 Eye_Glow parts. See 04-tank-v3-rigged.png.
