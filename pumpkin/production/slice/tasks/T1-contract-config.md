# T1 — Slice contract and final config

Status: DRAFT coder handoff; do not execute as part of drafting. No commit, publish, spending, account creation or unapproved asset upload.
Read ../SLICE-SPEC.md, ../../concepts/CONCEPTS.md and the relevant boards/Bible first. Current concept locks prevail over older board density/colour targets.

## Own files

- `pumpkin/giant/src/ReplicatedStorage/PatchConfig.luau`
- `pumpkin/production/slice/CONTRACT.md` (new)
- `pumpkin/production/slice/evidence/T1-config.md` (new)

Do not edit server/client/scene/Rojo files. First task; hand off immutable contract before T2/T3/T5 start. Later shared config edits belong to T6.

## Build

1. Read the whole returned config, especially overrides around Economy.gateCosts, rarity mutations, Movement, MysterySizes and buildScythe. Separate old-profile compatibility tables from slice-active tables/feature flags.
2. Define explicit Slice mode and an isolated save namespace contract; only Zone1 spawns, Zone2 gate/preview, no scheduled King/raid/Daily/pass/quest/mutation/sell/fuse/rebirth. Keep existing IDs and fields loadable; do not remove future-zone records from old saves.
3. Set final slice gate1000, Iron150, Rusty damage5/Iron15, cooldown.55, HP13, first tutorial break1/subsequent8 (proposed), income Pup1/Crow4, HoardMult1, Claim200 once. Record first-smash flag persistence and no compulsory Claim. Mark proposed tuning distinctly.
4. Match six rarity tokens and 12-entry visible Index. Keep all 15 legacy pet IDs outside that visible list. Define previews as models OR rendered portraits, not a requirement to generate 15 fallback pets.
5. Lock dimensions, world datum, pen slots8, carry3, guard11, shell scales3/4/8, pet rarity heights, wait6/8/20 and reveal beats0/.3/.6/1/1.5/2.2. Define exact feature flags to disable income during pending hatch and late-system effects.
6. CONTRACT.md specifies assets (`PetModels`, `GuardModels`, shell/rind/candy/tools/portraits), model front=-Z, ground pivot/invisible root, named Grip/BladeRoot/BladeTip/TrailRoot/TrailTip attachments, shell fragment transform ownership and Eye hooks. Do not apply VoxelModel 180-degree correction twice to imported models.
7. Freeze server/client attributes/events and pen states Carried->Seated->Waiting->Hatched; retain existing PatchRemotes where possible. Specify server-owned hatch deadline, client beat start, pending hatch save fields, idempotent purchase/Claim, isolated QA profile and truthful timer policy. Include GateWall/UnlockPrompt and safe preview ownership semantics.
8. Record asset package layout for T2/T4 and later Rojo mapping by T6. Do not add a mapping to a directory that does not exist yet.

## Acceptance

- Config loader checks final returned values, not text in first table. All seven scythe prices remain concept-correct, only first two buyable; no gate2500 override leaks.
- Compile at optimization0/1/2 with Studio debugLevel2; data-only offline config load remains valid.
- Contract names/types agreed by T3/T5; no ad hoc remote for each UI feature. Asset adapters support imported multi-MeshPart models around invisible root.
- Count budget matches spec; unresolved owner decisions are labelled, not silently decided by coder. Q1 default three shells/one operational; Q2 default King later; Q3 timings measured/Bible hard bounds.
- Provide concise evidence of final-loaded values and handoff. UNKNOWN: runtime until T6. Do not report production gate passed from config checks.
