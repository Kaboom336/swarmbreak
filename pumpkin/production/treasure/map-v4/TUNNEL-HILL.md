# Tunnel hill revision

Artifact: `prototype/meadow-v4.rbxl`. Scope: tunnel appearance only. No commit,
publish or guardian-greybox edit. No external asset or dependency adopted; reused
the inspected local native-part emitter, renderer and audits.

The complete trunk and south branch sit under a broad grassy mound. Turf planes
follow both gradients of the landform rather than creating repeated slope ribs.
Native collidable earth/rock supports the grass; reserved surface/tunnel travel
envelopes retain their original clearance. Hill trees, shrubs and grass use the
same shipped manifest as the render. Rock arches, moss and vines frame the
retained mouths. Paired tilted wedges form pointed blue and amber crystals;
hidden native PointLights provide warm exit lighting without visible light cubes.

The original route has **one entrance and two exits**. All three contacts remain;
the requested two exits were not reduced to one to force a two-opening facade.
The original 14-stud tunnel widths, route waypoints, policy, controller and Links
source are unchanged. Guardian equality is checked against a hash captured at
the beginning of this revision, independently of Git's pre-existing dirty state.

Static evidence: `TUNNEL-ROUND2-CHECK.json`, `TUNNEL-TEST.json`,
`collision-audit.json`, `routes-graph.json`, `TUNNEL-CONTACTS.json`, and
`ROUND5-PLACEMENT-TUNNEL-ROUND2.json`. The roof check samples 132 centerline
positions outside the deliberate skylight apertures. It checks two open shafts
through collidable roof and hill, and emitted native lighting brightness.
The clearance audit separately samples the full width of every route. Surface
prop audit scope remains unchanged; attached hill vegetation and cave crystals
are construction scenery. Studio traversal, human dodge rates and multiplayer
balance remain **UNKNOWN**.

`build-tunnel-sbs.jpg` has six before/after pairs: the same five player-eye views
plus a matched 3/4 overview. These are offline Cycles renders of shipped native
parts, not Studio captures. Before files and the starting place/manifest are
preserved separately. The latest `TUNNEL-EVIDENCE.json` binds final build,
manifest, render, audits and blind review hashes.

Visual standard: Minecraft cave readability and Zelda: Breath of the Wild grassy
cave entrances. Blind review 1 scored 6/10. Its corrections concern terrain
repetition, an architectural mouth, weak exit/skylight lighting and post-shaped
crystals. The final independent review and current disposition are recorded in
`TUNNEL-HILL-CRITIC-2.md` and `TUNNEL-LOOK-CRITIC.json`; these supersede earlier
look scores in the historical tunnel notes. Two blind rounds maximum.

Final disposition: **STATIC PASS; LOOK FAIL 6.5/10; RUNTIME UNKNOWN.** The
requested 7/10 was not achieved within the two-round cap. The final critic sees
the hill, vegetation, enclosure, two skylights and crystals, but still finds
roof-like grass panels, assembled doorway rocks, a straight corridor and weak
warm exit light. This is the current result, not a claimed visual acceptance.

Lessons:
- When a cave is visible from above, build its landform first, because roof
  dressing cannot change a freestanding-building silhouette.
- When terrain varies in two directions, tilt turf in both, because one-axis
  tiles produce repeated ribs along the mound.
- When crystals glow, retain pointed facets and moderate lighting, because
  saturated flat faces look like placeholder posts.
