# R2 review -> R3, author review
Cart player image inspected; complete board/other views checked before R3 mount.
1. Dominant protected wall planes remain exposed; frozen squat rocks improve
   only lower/peripheral edges. Keep this unresolved; no extra filler.
2. Cart now has an approach-facing CART EXIT cue; foot and cave have no new
   supported cue. R3 reuse two existing fence posts for small occluded-by-world
   BillboardGui labels, without changing either post or adding physical geometry.
   Labels face the player automatically; C1 apron remains untouched.
3. The offline CART EXIT lettering overruns its board because the reused renderer
   uses fixed font size while the actual GUI has TextScaled=true. Correct only
   the offline proxy to fit the real board; verify actual mounted GUI behavior.
R3 changes only new presentation/lettering. All original native fields/source,
carts/lanes/blasts/geode/guardian/suites remain exact.
