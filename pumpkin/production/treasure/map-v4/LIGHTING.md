# Meadow v4 Studio lighting A/B

Open `prototype/guardian-greybox.rbxl`. Backup: `prototype/guardian-greybox.pre-look.rbxl`.
Set the **ServerScriptService string attribute `LightingPreset`** to `GardenWarm`,
`EggClear` or `PetPop`. GardenWarm is the saved default. During Play, server
attribute changes apply immediately; before Play the controller applies at start.
To preview in Edit mode, use the SERVER Command Bar:
`require(game.ServerScriptService.LightingPresets).apply(game.Lighting, game.ServerScriptService:GetAttribute("LightingPreset"))`.
Missing/invalid names fall back to GardenWarm. Check Lighting.AppliedLightingPreset.

All three use **Future**, GlobalShadows=true. Future is serialized in the project
and place, because Technology is restricted at runtime and deprecated in current
[Roblox Lighting documentation](https://create.roblox.com/docs/reference/engine/classes/Lighting).
Studio versions showing unified lighting should retain its equivalent realistic
rendering mode; visual compatibility is UNKNOWN until tested in that version.
The module reuses its serialized Atmosphere/ColorCorrection/Bloom/SunRays effects,
including the previous HomeArtColour, preventing accumulated grading. Lighting
affects Home as well as Meadow; Home art/gameplay sources remain byte-identical.
The replicated preset module and client controller mirror the selected Lighting
attribute; Scene.environment skips its old portal grading when that attribute
exists. Without it, the original Home/Meadow path and tests remain unchanged.

## Reference comparison

These are authored style approximations, **not extracted private game settings**.
Game listings were checked; reference gameplay lighting was not tested. No
external code, models, sky textures or licensed assets were imported. Reused the
inspected repo-native emitter, builder, renderer and audits.

| Preset | Reference | Visual target copied / comparison with this island |
|---|---|---|
| GardenWarm | [Grow a Garden](https://www.roblox.com/games/126884695634066/Grow-a-Garden) | Warm daylight, green vegetation, soft readable shade; the island keeps its darker cave and five rock tones. Default reference bar. |
| EggClear | [Steal An Egg](https://www.roblox.com/games/107778070777162/Steal-An-Egg) | Clear blue daylight and low haze for pursuit readability; cool shadows help separate warm cave exits. |
| PetPop | [Pet Simulator 99](https://www.roblox.com/games/8737899170/Pet-Simulator-99) | Brighter pastel fill, stronger colour and gentle bloom; check that acorn/telegraphs retain contrast. |

## Exact values (RGB 0–255)

| Lighting | GardenWarm | EggClear | PetPop |
|---|---|---|---|
| ClockTime / Brightness | 14 / 2.8 | 13 / 3 | 14.5 / 3.2 |
| Ambient | 138,126,107 | 126,139,158 | 151,143,172 |
| OutdoorAmbient | 175,181,153 | 170,188,207 | 192,191,221 |
| Diffuse / Specular scale | .8 / .45 | .85 / .5 | .9 / .65 |
| ShadowSoftness | .4 | .3 | .5 |
| Atmosphere Density / Offset | .22 / .15 | .16 / .1 | .18 / .2 |
| Atmosphere Color (sky) | 199,224,255 | 181,218,255 | 203,214,255 |
| Atmosphere Decay (horizon) | 255,226,180 | 210,232,255 | 248,216,255 |
| Atmosphere Glare / Haze | .12 / .7 | .05 / .35 | .16 / .5 |
| Correction Brightness / Contrast / Saturation | .01 / .06 / .16 | .015 / .09 / .12 | .02 / .08 / .23 |
| Correction TintColor | 255,248,231 | 241,250,255 | 255,242,255 |
| Bloom Intensity / Size / Threshold | .12 / 20 / 1.25 | .08 / 16 / 1.4 | .18 / 24 / 1.2 |
| SunRays Intensity / Spread | .035 / .75 | .02 / .8 | .025 / .85 |

Sky colours use Atmosphere Color/Decay and OutdoorAmbient, retaining the existing
sky background. See [Roblox environment effects](https://create.roblox.com/docs/environment).
No texture download is required.

## Geometry and evidence

The visible tunnel turf uses native triangular prisms sharing landform vertices,
over the preserved invisible collision supports. Hill trees, bushes, boulders,
flowers and skylight outcrops attach to that same landform. Rock groups use five
tones: grey-purple (108,104,128), warm grey (124,119,109), mossy (88,103,91),
cool grey (97,107,119), light warm grey (143,135,121). Spatial groups alternate
Slate/Rock/Basalt. Sparse lighter caps, moss colonies and smaller shoulder
fragments complement existing large blocks without altering route collision.

`build-look.jpg` compares before/after 3/4 and hill views with **matched offline
Cycles illumination**, using the shipped manifest. It proves geometry/colour
changes; it does not simulate Roblox Future, Atmosphere or post-processing.
Use Studio to judge all three presets at the same camera, graphics level and
time. Runtime appearance, FPS and the three live test outcomes remain UNKNOWN.

Machine evidence: LOOK-GEOMETRY.json, LOOK-PRESERVATION.json,
LOOK-PLACEMENT.json, LOOK-HILL-AUDIT.json, collision-audit.json,
routes-graph.json and prototype/MERGE-V4-OFFLINE.json. Test Sources,
expectations, route data, ownership, Keeper and Home art are preserved.
The final [independent critic](LOOK-CRITIC.md) accepts the offline geometry look;
local cave/rock joins remain visible. All required offline checks pass. The two
pre-existing historical Home preservation tests still fail on the earlier
authorized Meadow merge; their old restrictions were already superseded in
MERGE-V4-STUDIO-CHECKS.md. No new PASS is claimed for those historical tests.
No commit or publish. Keystone Roblox Process Playbook was sought locally and
through the connected knowledge search but was unavailable; the supplied rules
(real art, retained core greybox, named reference comparison) were applied.

Lessons: When softening native terrain, share surface vertices because overlapping
planes expose seams. When adding an A/B preset, reuse owned grading effects
because stacked correction invalidates comparisons. When refreshing art, preserve
the collision contract because unchanged gameplay tests depend on it.
