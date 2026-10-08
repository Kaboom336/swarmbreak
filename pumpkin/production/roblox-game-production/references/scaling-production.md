# Scaling production

Use this reference when project size creates coordination, content, data or operational risks. Bigger art/content volume, players per server, total concurrent players, number of places, team size and update frequency are separate dimensions. Record which actually matters. Do not prescribe an MMO architecture merely because the user wants a successful game.

## Choose the minimum useful structure

| Current situation | Add now | Evidence that it works |
|---|---|---|
| Solo prototype | Brief, source ledger, one playable slice, local checks | A new player completes the loop and understands the payoff |
| Several interdependent systems | System boundaries, typed contracts, dependency map, integration scenarios | A change to one system preserves its consumers and saved data |
| Many maps/items/animations | Content schemas, reusable packages, import validation, measurable asset budgets | A new content entry works without copied gameplay scripts |
| Several contributors | Ownership, scoped work, integration order, review and handoff notes | Changes combine cleanly and a different contributor can resume them |
| Multiple places or cross-server state | Versioned shared contracts, transfer recovery, separate staging experience | Real-client transfers and mixed-version operation are verified |
| Live economy or frequent updates | Migration rehearsal, release manifest, telemetry, feature switches and recovery procedure | A failed release can be disabled or recovered without losing legitimate player progress |

Add a control when the matching condition exists. Keep a small game small. Replace a control if it creates overhead without catching an actual failure.

## Architecture and durable project state

Organize by gameplay responsibilities: authoritative state, gameplay rules, presentation, UI, persistence and content definitions. Identify the owner of each state transition. Define narrow module/remote contracts: inputs, outputs, invariants, failure behavior, lifetime and compatibility. Keep shared configuration separate from server secrets and authority. Avoid both a giant all-purpose game script and a framework built before requirements are known.

Document consequential decisions with context, chosen option, alternatives, migration cost and reconsideration trigger. Treat imported frameworks as dependencies that need an upgrade/removal path, not permanent architecture. Reuse stable components across games only after more than one real use demonstrates their boundary.

Maintain a current milestone ledger: outcome, dependency, owner where relevant, acceptance evidence, status and next action. A feature is done when its intended behavior and material integration checks pass, not when all proposed subtasks have files. Keep a compact handoff containing current source/build revision, open risks, relevant paths, last results and exact next step. A future session should be able to continue without reconstructing the whole chat.

For larger work, identify a critical path and implement risky dependencies early: a teleport, save migration or content import experiment may matter more than another polished menu. Split milestones into reviewable vertical slices. Use bounded spikes with a question and stopping condition for uncertainty; do not indefinitely research "everything."

## Content and asset production

Define data schemas for items, enemies, upgrades, zones and events when volume warrants it. Validate IDs, references, values and required assets; avoid duplicated scripts for every content variant. Keep naming/pivots, collider rules, animation events, UI tokens, localization keys and source provenance consistent. Separate mechanical parameters from cosmetic variants.

Set budgets from representative low-end device measurements: texture memory, mesh detail, active physics, lights, particles, sounds, animation and network traffic. Validate the crowded case, not just an empty map. Keep source art and export/import settings so assets remain editable. Track approved package versions and permissions across places; a package change must not silently alter an untested live map.

Use a representative final-quality asset early to prove the pipeline. Then batch content creation and inspect samples for consistency, while automatically validating every entry's mechanical references. Track creation time and memory cost: a content plan that cannot fit either budget must change before mass production.

## Team integration

Use the project's existing Git/Studio collaboration model and identify the source of truth for scripts, maps and assets. Avoid overwriting Studio edits from Rojo or exporting stale place files over newer changes. Give each contributor clear system/file ownership and contracts; coordinate shared-file edits and dependency order. Delegate only when the user or applicable instructions authorize it.

Agree on merge criteria proportional to the change: relevant automated checks, interface compatibility, asset/license evidence and targeted runtime review. Prefer small integrations over a large end-of-project merge. New team members need a working setup and reproducible build, not oral knowledge of one developer's computer. Secrets remain outside source and build artifacts.

## Persistence and service failures

Separate local/test, staging and production data and permissions. Staging places in the same experience may still access shared experience data; naming a place "test" is not isolation. Describe persistent schema versions, session ownership, atomic boundaries and idempotency for rewards, trades or purchases where present. Do not assume atomic transactions across unrelated keys.

Rehearse migrations on representative old profiles, including interrupted/repeated migration. Design mixed-version read/write compatibility while old servers still run. Additive migrations often reduce risk; destructive changes need a specific recovery plan. Record unknown write outcomes and prevent an old retry from overwriting newer state. Bound retries and provide an appropriate player recovery path instead of silently treating save failure as success.

Reduce unnecessary requests before scaling infrastructure. Measure hot keys and service budgets; temporary coordination and persistent ownership are different needs. Observe save failures and latency. Rehearse restore with test records; a backup that has never been restored is unproven.

## Multiple places and realistic load

Define what stays local to a server, what persists per player, and what must coordinate across servers. Treat transient messages as notifications, not the sole durable proof of a reward. Recover safely from stale/duplicate application events and unavailable services. Record release compatibility for shared modules and data schemas.

For travel, test party preservation, failed transfer, reconnect, destination capacity, incompatible versions and safe return. Verify teleports with actual Roblox clients in a permitted published test experience: Studio playtesting alone is insufficient. Do not accept client-supplied transfer data as authoritative currency/inventory.

Distinguish per-server load from aggregate experience load. Several Studio clients can verify replication but do not prove thousands of concurrent players or service throughput. Use permitted staged tests and measured capacity estimates, and explicitly label untested scale. Choose target load, duration, latency and failure thresholds before interpreting results.

## Build, release and operate

For multiple places, maintain a build manifest listing place, source revision, artifact/hash, package/config versions, schema version and required checks. Build and test each affected place plus shared-contract integrations. A single passing Lune runner is not an experience-wide release certificate. Use CI when it removes recurrent integration failures; retain a documented local equivalent.

Separate immutable build creation from publication. Before an authorized rollout, rehearse the riskiest feature or migration in staging. Use a limited release or feature switch when appropriate. Define observation window, rollback/disable thresholds and who acts. Avoid relying on rollback to old code if the new schema cannot be read by it; disable the feature or use a compatible repair instead. Restoring every player's older data can erase legitimate progress and needs a specific recovery decision.

Track technical health alongside gameplay outcomes: save/load failures, server/client errors, transfer failures, frame times and economy anomalies, plus first-session and repeat-play behavior. Establish baselines before declaring improvement. Alert on actionable failures rather than noisy events. Keep short incident notes with impact, repair and one evidenced prevention change.

Plan content events with expiry, cleanup and compatibility, not just a launch date. Maintain dependency/asset provenance, accessible controls and localization as content grows. Reserve capacity for maintenance and recovery rather than allocating every milestone to new features.

## Review the workflow itself

Try these scenarios when revising this skill: a small solo game, a content-heavy RPG, a team-built multi-place game, and a live economy update. Confirm each uses only the relevant controls, keeps user preferences local, preserves existing work and marks unavailable evidence honestly. These desk reviews do not substitute for executing a real project. Retain lessons that improve a measurable outcome: player comprehension, iteration time, build reliability, performance or recovery.

## Primary references to verify during implementation

- [Projects, packages and collaboration](https://create.roblox.com/docs/projects)
- [Data store practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)
- [Teleporting](https://create.roblox.com/docs/projects/teleport)
- [Cross-server messaging](https://create.roblox.com/docs/cloud-services/cross-server-messaging)

Checked 2026-10-06. Read current documentation when implementing relevant services; this workflow intentionally contains no permanent quota numbers or mandatory third-party framework.
