# Map-v3 evidence and visual QA

**Complete:** three built-in ImageGen blueprints; three v2-style 3/4 concept images; MAP-V3 arena/reasons/storyboards/risks/cost/judge; six-image contact sheet. The author inspected original and corrected images. A separate critic reviewed topology and A/B/C art, agreeing provisionally with C. No Studio/runtime/fun/device pass is claimed.

## Corrections made

- A: corrected hill/interception heights, explicit external31-run camp ramps, central walking bypass, separate safety entries, D coordinates and visible exposure hatching; removed concept route overlays.
- B: added +12 saddle cross-link and staged descent ramp indications; reduced concept to one throw disc, removed coloured path overlays, added ordinary broad descents.
- C: reversed escape arrows, moved north link/I1 toZ34, made valley dry and bridge optional, corrected decoy callouts, and rotated concept bridge to north–south across east–west ravine.
- Separate text correction: C south camp ramp needs a lateral dog-leg so its26-run footprint does not overlap the bridge approach. This is still a future construction check, not a verified assembled map.

## Remaining limits — use text dimensions, not image pixels

- Raster diagrams are design blueprints with labelled budgets, not CAD or solved part assemblies. Measure slopes, footprints, clearances and walking distances when building. Generated scale bars/grid spacing are approximate.
- C art exaggerates cliff/recovery depth and portrays a sloping wooden span. Build the specified **level12×32 deck atY+6**, with separate13-run ramps and floorY-4, not the exaggerated cliff shape.
- C blueprint's key-dimensions row says “Two final approaches” despite three coloured approaches and its notes specifying three. **Three** govern. C's east D callout sits at the page top while labelling(+64,-44); put the actual meadow in the southeast. Recovery ramps are12wide; diagram's13stud number is horizontal run, not width.
- 3/4 art foreshortens ramps, omits the cyan safety footprint and does not prove separate safety entries. Blueprint/text specify the pad and8-stud apron and three separate arrivals. Do not copy decorative fences where they block walking lanes or recovery.
- B art generalizes the three shelf ramps into broad switchback descents. Keep the +18/+12/+6 staged choices from the blueprint; do not add a slide system or precision stairs.
- Concepts depict nest-position and carried acorn states together for illustration. Runtime has **one** acorn: nest is empty while carried. The images do not establish item/state behavior. D callouts designate open planning meadows, never fixed trap sockets.
- One visible throw disc in each final art scene; blueprint hatching illustrates potential exposure as guardian moves, not simultaneous attacks, fixed range or invisible damage.
- 40s tables model contested play with cutbacks/recovery/handoffs. Pacing and whether bridge camping dominates remain UNKNOWN.

## Reproduction and scope

Built-in tool only: [initial prompts](PROMPTS.json), [correction prompts](CORRECTION-PROMPTS.json), [last A correction](A-LAST-PROMPT.txt). All selected final files were copied into this folder. ImageGen automatically retained originals in its tool-managed `C:/Users/zerha/.codex/generated_images/` cache; that destination is not configurable through the available built-in tool. All authored documents/contact-sheet work stayed under map-v3; no manual write outside it, game code edit, commit or publication.

Sheet assembly uses System.Drawing solely to arrange the six finished images and captions; it does not retouch generated image contents. PowerShell script-file execution is disabled on this machine; assembly ran as reviewed inline commands without changing execution/security settings. No game tests are appropriate to a design-only change; verify actual geometry and multiplayer fun in a separately authorized greybox.
