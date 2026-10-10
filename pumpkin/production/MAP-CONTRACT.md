# Map Contract (summary; full detail in the session transcript of 2026-10-10)
S = Patch.server.luau, C = Patch.client.luau, P = PatchConfig.luau. HANG = WaitForChild with no timeout.

## Must exist
- workspace.Garden (HANG) with: Patches (HANG), Cauldrons (HANG), Market (HANG), GhostSpawns (HANG), Zones, JumpPads (optional), SpawnLocation.
- Do NOT pre-create Loose, Ghosts, Wild (code makes them).
- Patches/<pen> (Model): Soil BasePart (REQUIRED, S:2311); N x Plot (direct children, attr Index 1..N, side-lying cylinder: local X up, disc Y x Z, centre ~0.15 below top; S:1695-1701, C:5207); optional SignPost > OwnerSign > Label; attr Id optional.
- Cauldrons/<c>: Pot + Brew BaseParts; at least 1.
- GhostSpawns: >=1 BasePart children.
- Market: GiantJack (HANG), KingFace (HANG), Plaza (HANG), MeterRing (HANG, client), Sell/Seeds/Upgrades each with PromptPart (HANG; Seeds = tool shop, model/PVInstance), KingGlow optional, LifetimeBoard optional.
- Zones/<ZoneN> for every id in Config.ZoneOrder: descendant BaseParts named Spawn (wild spawns + client zone boxes); gated zones: GateWall + GateSign BaseParts; optional Hoard marker.
- ServerStorage.KitSource.pumpkin_orange / pumpkin_yellow (MeshPart inside); PolishAssets.GhostMesh optional.
- Lighting: Studio values are the day base (client snapshots them).
- Drop raycast only hits Terrain, Patches, Market (S:1471-1475).

## Radial assumptions to change for a lane
claimPatch quadrants (S:2316-2334); 9-plot saves (S:1532-1548); plot geometry; zone centres radius 176 (P:144-160) + locked-zone circle r40 (S:2889-2901); hoard spot from origin (S:3587-3609, 3683-3685); hoard leash via GateWall (S:3692-3700); candy rain at origin (S:5030-5041); King volley within 80 of origin (S:5192); client shake within 60 of origin (C:3152); fallback LifetimeBoard radial (S:5469-5481); kick fallback Plaza+(0,6,30) (S:2883); raycast whitelist (S:1473); ZoneOrder has 4 zones (P:131-216); ghost spawns nearest target plot (S:4463-4469).
