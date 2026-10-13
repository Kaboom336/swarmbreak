# Golden Acorn — owner review

Kept saved round 4. Inspected approved Crow final-34, Pup A LEFT, containers.png, and treasure/v2 PNG references. Existing local artlib.py and build_acorn.py read before reuse; project-authored tooling, no external meshes or licensed third-party assets introduced.

| Round | Visual critique against supplied container/reveal references |
|---|---|
| 1 | Narrow shell; open halves too close. |
| 2 | Fuller shoulder and larger reveal gap; cap edge still weak. |
| 3 | Broader cap rim; hollow interiors; one half reads too edge-on. |
| 4 — kept | Turned halves expose both hollow interiors; clean three-piece reveal silhouette. |

Compared with containers.png: broad brown cap, gold tapered body and brick stem match. Compared with open-reveal.png: two actual hollow halves plus cap, no extra bowls. Flat materials, no textures. The intentionally simple cap lacks the reference's decorative tile seams. Owner approval remains UNKNOWN. Independent read-only critic inspected both final acorn renders against the supplied references: owner-review-ready candidate; cap simpler and more faceted than references. No owner approval claimed.

Checked via verify.py: closed 300 triangles / 3 studs; open 456 triangles / 3.78 studs in exploded pose. Each under 1,500. Closed surfaces, positive signed volumes, valid nonzero triangles and indices. JSON has three unique RGB colour parts; Y-up studs, front +Z, CCW preserved by a rotation with determinant +1. FBX re-import matches triangle counts and vertex positions within 0.000001 studs. Roblox Studio import UNTESTED.

Files: golden-acorn.blend / .fbx / _parts.json; golden-acorn-open equivalents; final-front.png, final-34.png, final-open-front.png, final-open-34.png; iterations.jpg; validation.json. Open FBX retains separate left/right halves, cap and stem; JSON intentionally groups disconnected components by colour.

Keystone Roblox Process Playbook was not available through callable tools or the searched local coordination files. Followed the user's supplied art/reference/iteration requirements. No game code, commits, publication or outside-folder writes.

Lesson: When open shells are shown in three-quarter view, turn each toward the camera because a hollow half can otherwise read as a flat shard.
