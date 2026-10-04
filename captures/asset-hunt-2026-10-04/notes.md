# Toolbox asset hunt, 2026-10-04 (free only, nothing published or bought)

Scope after Zion picked "Mix": (a) a cartoon bug enemy set, (b) a sci-fi outpost or sky-island prop kit.
Everything was inserted into a scratch copy of the f96b4f8 build in Edit mode, which was never saved. Screenshots use the place's edit-time lighting, not the runtime presets.

## Verdict

**No free Creator Store asset clears Zion's quality bar, and none forms a coherent cartoon bug set.**
- The search results are dominated by keyword-stuffed re-uploads.
- Several of those re-uploads carry hidden scripts. One was **obfuscated backdoor code** ("Obfuscated/Alternative method that avoids static filters").
- I recommend not sourcing enemies or the map from free Toolbox models. Better options:
  1. Use the repo's own Blender assets in `assets/models/`.
  2. Generate meshes with Studio's generate_mesh and texture tools to an art bible.
  3. Buy a vetted paid pack (needs Zion's OK).

## (a) Bug enemies (screenshots: enemies-row-a.jpg, enemies-row-b.jpg)

| Asset | ID | Notes |
|---|---|---|
| bug pack 3 (krysuspl) | 14638453028 | Best of the lot: several spiders, semi-stylized, 432 parts, no scripts. Not cartoon, and the scale is inconsistent. |
| ants (Epzno) | 755133700 | Simple part-built ants (black, fire, bullet, etc.), 85 parts, no scripts. Usable as a grey-box only. |
| Leafcutter queen (Pfrisk123) | 4783660571 | Big red ant, 46 parts, no scripts. Possible boss silhouette, but crude. |
| [Bee Swarm Sim] all Aphids (MrsBovain) | 4840139018 | Cute and readable, but **ripped from Bee Swarm Simulator**, so it's an IP risk. Don't use. |
| Mecha Spider Quad Leg Rigged (j4yyt2008) | 93008945116276 | Rigged, but untextured pink parts. Keyword-stuffed listing. |
| Insects Kit (AlguienXDXD8) | 18867968592 | Tiny (5 studs total), realistic textures; doesn't read at combat distance. |
| Low Poly Beetle (HerbieTurbinado1300) | 9816803549 | **30 scripts inside a 29-part model.** Suspicious; scripts removed. Avoid. |
| Mint The Centipede | 14122124130 | 4 scripts (hitbox theme); not stylized. Avoid. |

## (b) Environment (screenshots: env-station-kits.jpg, env-floating-islands.jpg)

| Asset | ID | Notes |
|---|---|---|
| Space Station Modular Kit (Hub / Habitat) | 135077316783927 / 140348736873561 | **The same model re-uploaded under different spam accounts.** 1,515 parts. Its scripts (door, "PoseTexture", "TextureConfiguration") imitate known libraries. Treat as untrusted. Looks generic. |
| Massive Floating Island Sky Terra Realm | 88719595373167 | **Contains an obfuscated backdoor** ("avoids static filters"). 42k parts. Deleted; never use. |
| Floating Island Sky Realm Cloud Map | 130999434562327 | 3 parts plus a fake "LightConfig" script framework. Not a real kit. |
| Centaur's Low Poly Floating Island | 138472723124278 | 2-part mesh, clean, no scripts. Single prop only. |
| Low Poly Floating Island (marin773) | 5565039117 | 2-part mesh, clean, no scripts. Single prop only. |
| Low Poly Floating Island Base (FelinG0re) | 135113645221575 | 1 huge mesh (1,321 studs wide), clean. Could serve as a sky-island arena base; it needs our own props. |
| Sci-Fi Platform (AdamRed1111) | 14053291516 | 15 parts, clean, small. |

Weapons and animations were skipped per the narrowed scope. One note for later: animation assets only play in our game if they're re-uploaded under our account, so free animation packs need that step too.
