# Crow visual iteration critique

Evidence: opened all six supplied reference images, actual iteration front/three-quarter/side renders, scale lineups, and side-by-side reference sheets. Approved style is owner-reported **Pup A**; the quality benchmark is the supplied **Pet Simulator 99** frame. Concept v6 reinforces chunky pumpkin forms, block silhouettes and stems; v4 reinforces strong pet identity. Crow C/F provide the waving-wing and black/purple starting language.

## Iteration 1 — 1,980 triangles

Readable silhouette at small size: yes, the large unified head, short body and orange feet remain clear. Face: recognisable but too neutral, with undersized washer-like eyes. Chibi proportions: yes. Roblox character rather than primitive stack: the rounded brick head and tapered bib are coherent, but wings read as bent arms and the hat reads as a puck. Against Pup A it lacks intentional brick accents; against Pet Sim the eye hierarchy is weak. Fix: widen head, enlarge eyes to roughly 40% of face width each, integrate feather steps into each wing, raise one wave, add restrained top studs, restore orange saturation.

## Iteration 2 — 2,260 triangles

Small-size silhouette: improved, with three readable feather steps and an asymmetrical wave. Face: larger eyes are cute and easier to read, but their depth creates a plastic-goggle effect. Chibi proportions: maintained; body and feet stay small. Roblox character: softened bricks and a few studs now relate more closely to Pup A, while the bold eyes approach Pet Sim's readable colour blocks. Weaknesses: clipped white reflections, broad duck-like bill, and a slightly dominant purple bib. Fix: flatten eyes without shrinking them, shift gaze a little up and inward, taper/shorten bill, reduce bib and soften sheen.

## Iteration 3 — 2,362 triangles — keep

Small-size silhouette: strongest, with the same unified stepped wings and compact torso. Face: thin white sclera, very large dark pupils and two matched highlights keep a clear hierarchy; tapered bill and tiny seam improve the bird read. Chibi proportions: 3.2 studs tall with the head occupying 54.8% of height. Roblox character: deliberate rounded blocks, integrated feather silhouettes, colour blocks and restrained studs avoid the lumpy primitive-stack construction the owner previously rejected. Geometry cleanup welds coincident bevel vertices without changing the intended silhouette.

Independent critic also selects iteration 3; see `independent-critique.md`. Remaining limitations: the cap is still fairly flat, the expression is simpler than Pup A's layered face, and some front-view hat highlights wash toward white. These are visible limitations, not proof of owner approval. Studio import and in-game appearance are UNKNOWN; local FBX re-import and JSON geometry checks pass.

## Lessons

- When a small pet lacks character, refine its outer silhouette first, because integrated feather steps survive thumbnail scale.
- When huge eyes resemble goggles, reduce their depth before their size, because large clean eyes carry the cute read.
- When beveling thin mesh plates, weld coincident vertices before export, because clamping can create zero-area triangles.
