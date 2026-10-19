# Steal a Treasure - look round 2 (last round)

Implemented only the three requested visual gaps. No Studio, commit, publish, external assets, or new dependencies. Reused the existing scene and controllers. Existing gameplay collection, money, movement, pedestal positions, prompts, save schema, and lock collision remain unchanged. Claude's BaseTest Brightness upper bound **3.5** is retained.

## Evidence and comparison

Inspected Claude's real `r1-outside.jpg` and `r1-inside.jpg` alongside `ref-map-overview.png` and `ref-base-inside.png`. Best-in-class target: **Steal a Brainrot**, as represented by those supplied refs. This is a source/geometry comparison after inspecting R1 screenshots; no R2 engine image was generated or scored.

| Gap seen in R1 against reference | R2 change |
| --- | --- |
| Large overlapping labels fill the base frontage and interior | Scene action labels reduced from 200x56 to 100x28 pixels; 30-stud range; AlwaysOnTop false. Name stays on wooden board, with 80-stud range and AlwaysOnTop false. |
| Every locked slot has a price; empty slots repeat the pooled bank | Only the next locked pedestal shows `Unlock $X`. Empty slots have no Collect label. Placed earners get a small 80x28, 14px `Collect $X` pad label using their actual record.pile, refreshed with existing server state. Labels hide during delivery/carry and on owner departure. |
| Earner text can render through the scene | Server registration applies AlwaysOnTop false and 45-stud range to detailed carpet labels, retaining name, rarity colour, price and income. Detailed labels hide after purchase; placed earners use their Collect pad label. Tutorial arrow and money pops also respect occlusion; pops are half size with 30-stud range. |
| Main red lane dominates the outside shot | Main lane narrowed from 18 to 15 studs; white edges moved to +/-7.65. Earners still walk at X=0. Per-base entry carpets retained and extended inward to meet the narrowed lane. |
| Narrow interior red strip leaves most of the floor grey | Interior red carpet expanded from 55x13 to 54x44 studs over the existing 56x48 floor. Dark wall margins and pedestal blocks remain; unlocked Collect pads stay green, locked pads stay grey. White edging stays at entries instead of crossing the expanded interior. |

Per-pedestal pads remain decorative: the existing green Collect action pad still collects the whole base bank. Displaying the real individual balance adds no collection trigger or new money contract. Runtime label changes happen in BaseServer, so its factory's serialized preview is normalized on registration. Visibility updates use the existing refresh cadence (up to roughly one second).

## Verification

- `lune run slice-v2/base/check.luau`: **PASS**, 680 offline assertions; 20 Luau sources compile.
- `lune run slice-v2/base/build.luau`: **PASS**, 927 serialized-place assertions; 327 offline presentation assertions; 18 Luau sources plus embedded LookVisuals compile.
- Existing adapter checks updated for hidden empty labels. Added checks execute the actual server refresh, registration label setup and state transition source: next unlock through slots 5-10, individual balance/reset, absent/delivering/restored labels, carpet details and occlusion settings.
- The default Rokit shim failed with `ERROR home directory not found`. Commands passed with a process-local PowerShell `lune` function forwarding to the already installed `C:/Users/zerha/.rokit/tool-storage/lune-org/lune/0.10.5/lune.exe`. No persistent tool configuration changed.
- Built `slice-v2/base/steal-a-treasure-base.rbxl`: 39,154 bytes; 895 whole-map BaseParts.
- SHA256: `40318500E798C005422D3EAEE85685315AC92A03D64E3B9F784410C7A7312B2E`.
- **R2 Studio rendering, Play, multiplayer, wall occlusion and camera readability: NOT RUN.** Runtime appearance is inferred from changed source and offline state tests. Existing transparent window bands remain transparent.
- No independent agent review was run; this pass is a scoped source audit against the supplied images. The named Keystone Roblox Process Playbook was not available through connected tools/local searches; its full contents remain UNKNOWN, as in R1. Read the installed Roblox production skill and its production gates.

## Lessons

- When the base repeats across the map, hide empty and future-slot labels because reducing text size alone leaves repeated clutter.
- When each earner already stores a pile, display that value because mirroring a pooled total into every slot misstates the individual reward.
- When narrowing a shared lane, reconnect its entry carpets because leaving their old endpoints creates grass gaps.
