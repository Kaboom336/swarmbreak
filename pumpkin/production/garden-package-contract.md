# Isolated garden package

The user confirmed the old roll world appears in the editor before Play. The previous garden package kept that historical world in Workspace and generated the new garden only at runtime, making the handoff confusing.

Scope: new `garden.project.json`, minimal GardenScene asset-source lookup, local build/checks and Desktop replacement. Preserve historical `default.project.json`, all source assets and gameplay. No publishing, saved-place upload, data reset or commit.

- P1: The garden saved place contains no historical roll map or SpawnLocation in Workspace. Old map assets are stored privately in ServerStorage.GardenArtSource.
- P2: GardenScene resolves its named templates from that private source, with legacy Workspace.PumpkinMap compatibility. All required template names exist in the packaged hierarchy; no indefinite wait for the relocated map.
- P3: Historical default project and source assets remain unchanged. No imported executable art or new Creator Store insertion.
- P4: All relevant source checks and tests pass; Rojo builds garden.project.json; packaged modules match disk; Desktop copy matches artifact hash. Explicitly state that the actual garden is still runtime-generated, not an editable baked scene. Studio boot/visual verification remains pending.
- P5: Garden terrain and spawn are built before requiring Data, whose top-level Studio probe may yield.

Use the existing separated implementation/fresh source review process. Future garden test builds must use `-ProjectFile garden.project.json`; building the historical default project reintroduces the old editor map.
