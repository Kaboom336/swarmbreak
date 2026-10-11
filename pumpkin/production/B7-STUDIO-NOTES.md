# Batch 7 Studio test (Claude, desktop). Note: MCP click y = screenshot y - 58.
Good: pen has no tag clutter; carried pumpkin is an opaque mesh at the chest; nest egg welds gone (welds 4,400 -> 957); objective flow works; Index "!" badge appears.
Fix:
1. Locked slot discs still bunch and overlap in the pen's left/back corner (4-5 grey locked discs overlapping each other and the wooden discs) in Pen2 (owner pen, world from LaunchLook + Lobby). The grid must place each locked disc on its own free slot position; verify against the actual pen fence bounds at runtime (Pen model bounding box), not a hard-coded size.
2. The hatched pet in the pen looks tiny (~2 studs) at the slot: pet must be >= 0.8x the pen pumpkin size (B15) — check scaling is applied to pets placed in pens, not just the reveal.
3. Toasts at the bottom centre ("Steal = PETS!", "Steal a glowing pumpkin!!", "The guard ... your pen!") overlap each other and the Drop button while carrying: stack toasts above the action buttons with spacing, max 2 visible, newest on top.
4. Parts still ~11.6k (scene adds ~2k); BillboardGuis 675; ProximityPrompts 277: cap world billboard MaxDistance and disable prompts on far-away slots if cheap.
