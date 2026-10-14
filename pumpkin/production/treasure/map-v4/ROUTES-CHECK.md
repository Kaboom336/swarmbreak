# Round 3 route graph check

**PASS — 24 nodes, 37 edges, dead ends = 0; unreachable nodes = 0.**

Endpoint-to-centerline snaps <=target half-width and height tolerance0.75; genuine 2D segment intersections with matching height; explicit supported jump pads; portal goal court contracts to one node. Physical full-width clearance independently checked by collision-audit.json. This graph is geometric connectivity, not a Studio locomotion simulation.

Coordinates below are source X,Z,Y; Roblox uses X,Y,-Z. Portal and summit are purposeful goals, not dead ends. Ridge gaps are optional jump edges with continuous walked ridge fallback. Floor loop joins one long physical exit ramp; both old isolated recovery lanes are removed.

## Every node

| Node | Source X,Z,Y | Degree | Purpose |
|---|---|---:|---|
| SUMMIT | 0, 108, 48 | 1 | summit treasure objective |
| N2 | 30, 108, 48 | 3 | route junction |
| N3 | -0.0, 58.0, 0 | 2 | route junction |
| N4 | 0, 42, 0 | 5 | route junction |
| N5 | 37, 72, 0 | 2 | route junction |
| PORTAL | -24, -136, 0 | 5 | portal destination |
| N7 | 0, -42, 0 | 2 | route junction |
| N8 | 110, 18, 0 | 2 | route junction |
| N9 | 110, -60, 20 | 4 | route junction |
| N10 | -76.0, 27.0, 0.0 | 2 | route junction |
| N11 | 69, 28, 0 | 3 | route junction |
| N12 | -76.0, -78.0, 0.0 | 2 | route junction |
| N13 | 0.0, -78.0, 0.0 | 3 | route junction |
| N14 | -22, 0, -32 | 3 | route junction |
| N15 | 0, -100, 0 | 5 | route junction |
| N16 | 148, -24, 20 | 2 | route junction |
| N17 | 148, -56, 24 | 2 | route junction |
| N18 | -76, -54, 0 | 3 | route junction |
| N19 | -61.87, -98.95, 0 | 3 | route junction |
| N20 | 22.07, 46.02, 0.0 | 6 | route junction |
| N21 | -45.18, 47.42, 0.0 | 4 | route junction |
| N22 | 1.62, -83.55, 0.0 | 4 | route junction |
| N23 | 3.21, -102.04, 0.0 | 4 | route junction |
| N24 | 148, -40, 22 | 2 | optional ridge jump landing |

## Every edge

| Edge | Nodes | Route | Kind |
|---|---|---|---|
| E1 | SUMMIT <-> N2 | summit_radial | walk |
| E2 | N2 <-> N3 | spiral | walk |
| E3 | N3 <-> N4 | fork_link | walk |
| E4 | N2 <-> N5 | shelf | walk |
| E5 | N5 <-> N20 | shelf_link | walk |
| E6 | N20 <-> N4 | shelf_link | walk |
| E7 | N4 <-> N21 | west | walk |
| E8 | N21 <-> PORTAL | west | walk |
| E9 | N4 <-> N7 | bridge | walk |
| E10 | N7 <-> N13 | bridge_south | walk |
| E11 | N13 <-> N22 | bridge_south | walk |
| E12 | N22 <-> N15 | bridge_south | walk |
| E13 | N15 <-> PORTAL | bridge_south | walk |
| E14 | N4 <-> N20 | east | walk |
| E15 | N20 <-> N11 | east | walk |
| E16 | N11 <-> N8 | east | walk |
| E17 | N8 <-> N9 | east_climb | walk |
| E18 | N9 <-> PORTAL | east_descent | walk |
| E19 | N10 <-> N21 | north_crosslink | walk |
| E20 | N21 <-> N20 | north_crosslink | walk |
| E21 | N20 <-> N11 | north_crosslink | walk |
| E22 | N12 <-> N19 | south_crosslink | walk |
| E23 | N19 <-> N15 | south_crosslink | walk |
| E24 | N15 <-> N23 | south_crosslink | walk |
| E25 | N23 <-> PORTAL | south_crosslink | walk |
| E26 | N13 <-> N22 | portal_north | walk |
| E27 | N22 <-> N23 | portal_north | walk |
| E28 | N23 <-> PORTAL | portal_north | walk |
| E29 | N14 <-> N15 | ravine_ramp | walk |
| E30 | N14 <-> N14 | ravine_floor_loop | walk |
| E31 | N9 <-> N16 | jump_access | walk |
| E32 | N17 <-> N9 | jump_recovery | walk |
| E33 | N10 <-> N18 | tunnel_trunk | walk |
| E34 | N18 <-> N12 | tunnel_trunk | walk |
| E35 | N18 <-> N19 | tunnel_south | walk |
| E36 | N16 <-> N24 | ridge_jumps | jump |
| E37 | N24 <-> N17 | ridge_jumps | jump |

## Gameplay read

- West: retained surface fallback and Hollow Oak landmark;14-wide cave trunk plus south branch, two exits joined to existing graph.
- Tunnel: mud, telegraphed knock-drop rocks, escalating rumble and one predicted surface Keeper intercept; balance rates/timing ESTIMATED until Studio.
- Bridge: open timber deck and twin amber beacons over a 32-stud gorge; losing the acorn costs the long walkout.
- East: high ridge, Split Spire landmark, optional three-pad jump sequence with walked fallback.

## Evidence and limitations

Scene SHA256: `7b8fffdcb0ab7b90f20ba1f3024a63d2297726eb4f43c65cf3e86a0dacd2d286`. Graph and clearance are machine-derived. Policy/syntax/native artifact checks are recorded separately in TUNNEL-TEST.json. Pickup, real humanoid falling, competing players retrieving the dropped acorn and walking the ramp remain **UNKNOWN in Studio** until a playtest.
