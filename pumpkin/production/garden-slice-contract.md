# First playable magic garden — 2026-10-06

The user's “continue the process and improve or change when needed” authorizes this bounded playable slice. This supersedes the design-only hold for this slice. It does not approve the quality of untested gameplay or authorize a commit/publication.

Source design: `research/MAGIC-DIRECTION-PROPOSAL.md`, `research/GARDEN-ART-COLLECTION-DESIGN.md`. Timing, prices and charge counts are playtest hypotheses.

## Acceptance criteria

- G1: Garden mode runs alone; historical roll/catapult/Coop gameplay and UI stay gated off and preserved.
- G2: Each player has two owned automatic crops, an immediately harvestable small starter, visible growth and a gold GROW BIGGER upgrade enabling big pumpkins. Other players cannot harvest owned crops.
- G3: Harvest/Cast/Recall and movement-facing guidance require no launcher or aiming panel. Ghost contacts spend shell charges, show damage and earn gold; last charge automatically bursts and a manual burst is possible.
- G4: Server validates loaded/alive state, action rates, proximity and reward conditions. Clients cannot supply rewards, currency, crop ownership or unrestricted target hits. Contacts, purchases and chains cannot duplicate grants.
- G5: Two different players' nearby, near-simultaneous bursts connect with bounded shared benefit and visible shrine progress. Solo outings work. A chain never forces another player's burst.
- G6: Reset/death/removal/loading/shutdown clean up transient ownership and stop rewards before releasing data. Saves/releases are serialized; a departing player whose load completes late is released.
- G7: Compact keyboard, touch and gamepad controls explain the next action without old HUD overlap. Reduced-effects and volume settings are respected.
- G8: The garden uses inspected bundled mesh art, readable paths, small/big pumpkin silhouettes, shell stages and a visible shared shrine. Imported descendants are scrubbed before parenting. No new Creator Store insertion.
- G9: Relevant tests, all-source syntax, lint, format and Rojo build pass with raw output and artifact hashes. Runtime, visual, audio, multiplayer, phone readability and fun remain pending until direct Studio/user evidence exists.

## Roles and evidence

Separate gameplay and scene implementers own nonoverlapping code. Root coordinates and packages. Fresh critics inspect direct source/check evidence; a separate authority/persistence critic reviews G4–G6. Repair any actionable defect and obtain fresh review. Record absent runtime evidence explicitly, never as acceptance.

Build destination: `C:\Users\zerha\OneDrive\Desktop\PUMPKIN-TEST.rbxl`. Preserve old source and do not commit until the user says it is good. No purchases/publication. Free verified art only.
