# Magic garden playtest

Open Desktop `PUMPKIN-TEST.rbxl` in Roblox Studio and press Play. No terminal steps. Use the build hash in the latest garden evidence report to identify the submission.

The dedicated build uses `garden.project.json`. Its historical roll assets live in ServerStorage as private art sources, so the editor does not show the old roll map. The new garden is still generated when Play starts; an empty editor Workspace is expected for this prototype. After a file update, reopen it from disk rather than testing an already-open old Studio tab. This file update does not publish or replace a Roblox cloud place.

## First outing

1. Spawn beside your two owned vines. Walk to the ready pumpkin and use **Harvest** (E / controller X / touch button).
2. Use **Cast**. Walk toward a floating ghost: the pumpkin follows your direction. Each contact frees a ghost, earns 5 gold and exposes shell cracks. Three contacts finish a small pumpkin. **Recall** brings an active pumpkin close; **Burst** (Q / controller Y / touch button) finishes early.
3. Repeat until you have 60 gold. Approach the scarecrow's **Grow bigger** display and use the nearby prompt (F / controller B / touch prompt). Leave a vine growing for 28 seconds from its last harvest to reach big size, then harvest that pumpkin. Big pumpkins should visibly dwarf small ones and survive five contacts.
4. Watch the shared shrine gain lanterns as ghosts are freed. Ghosts return after nine seconds. Your vines grow while you are away.

## With a friend

Use Studio's Server & Clients test with two clients. Each person must have their own crops and gold. Bring both awakened pumpkins into the orchard, then burst within 18 studs and 2.5 seconds of each other. A cyan arc should connect them; nearby extra ghosts should credit both players once. One player's burst must never force the other pumpkin to burst.

Reset during an outing, join late, and leave one client during play. No stuck controls, duplicate gold, orphan pumpkins or ownership theft should occur. Persistence needs a published test place with DataStore access; unpublished Studio may use the existing in-memory fallback, so stopping that session does not prove saved progression.

## Evidence to send

One short clip from spawn through the first burst, a screenshot of small versus big, and a friend-chain clip are enough for the first visual/feel review. A phone emulator view helps assess the HUD and buttons. Judge whether you understand the next action without reading this document.

## Current quality gates

Local syntax/tests/lint/build can prove source and packaging checks. They cannot prove playability, sound availability, mesh loading, terrain alignment, phone readability or fun. Those remain pending until actual Studio/user evidence is reviewed. The first slice reuses bundled meshes; custom split-shell geometry, cinematic spell animation, additional pumpkin forms and a finished sound palette remain later work.
