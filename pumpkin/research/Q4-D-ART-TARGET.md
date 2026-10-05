# Q4-D in-engine art target: bright Halloween toy chute

This is the source-of-truth prop kit for the fallback map. It uses only locally authored Roblox Instances; no store model is inserted. The finished vertical slice is the Pumpkin Patch path from compact spawn plaza, through its giant candy start arch, jack-o'-lantern/fence route dressing and bounded warm lamps, to the candy finish set piece.

## Shape language

- Chunky, rounded, exaggerated silhouettes readable at ride speed: five-lobed pumpkins, bead-built candy arches, wide gravestones, thick split-rail fences and lanterns with oversized glowing heads.
- Friendly spooky faces and candy shapes; no gore, sharp horror detail or realistic decay.
- Every hero prop uses at least three value bands: a dark underside/crease, saturated base, and light-facing highlight, plus one semantic accent where useful.
- Near-black separation is for form. Coloured Highlight fill/outline is reserved for pickup, hazard, egg and rare-pet state.

## Palette and hierarchy

- Pumpkin orange `#FF6B00`: hero pumpkin, primary Patch prop.
- Electric purple `#8B2CFF`: panels, castle/candy secondary form.
- Acid lime `#B7FF1A`: success and Forest identity.
- Turbo cyan `#00D9FF`: speed and Graveyard identity.
- Hot magenta `#FF2D95`: danger/rare state only.
- Candy yellow `#FFD400`: reward, face and lamp cores.
- Ink `#171225`: creases, outlines and enclosure shadow.

Scenery uses quieter derived orange, purple, teal and green. Neon is limited to lamp/face cores, lane state and rarity. Interactables remain the most saturated objects.

## Approved materials

1. `SmoothPlastic` for toy pumpkin, egg and candy faces.
2. `Wood`/`WoodPlanks` for fence, stem and lamp-adjacent structure.
3. `Slate`/`Rock` for track, gravestones, canyon and enclosing cliffs.

`Neon` is an accent, not a fourth base family. PointLights are capped at 12, range 18, brightness 1.35 and cast no shadows.

## Zone identities

- Pumpkin Patch: giant jack-o'-lantern, orange pumpkin/fence family, teal chute, candy finish.
- Haunted Forest: moon gate, crooked dark trunks, lime crowns and fences.
- Graveyard: crypt landmark, clustered three-band gravestones and cyan identity.
- Witch Castle: oversized candy-castle gate, purple identity and repeated candy arches.

Each zone retains the same controls and deterministic chute while changing landmark, prop family, accent and finish read.
