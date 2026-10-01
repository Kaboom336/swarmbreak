## R2: Retention, monetization and discovery (researched 2026-10-01)

Evidence limits: devforum, x.com, reddit, youtube are blocked, so Roblox announcements are quoted via secondary blogs. Review/complaint evidence for Final Swarm-likes is THIN: wikis and code sites do not carry player complaints (searches returned none). Treat section 4 as inference, not data.

### 1. How discovery works now (2026)
- Roblox's "Recommended For You" (RFY) moved from a 7-day to a 28-day retention view, in three buckets: Day 1, Days 2-7, Days 8-28. Games that spike and fade are penalised. https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox and https://zehn-studio26.com/news/recommended-for-you-retention-update/
- Signals tracked (organic RFY traffic only, ads excluded): playtime, play days, qualified play sessions, intentional co-play days, spend days, Robux spent; qualified play-through rate was split into play-through rate plus first-play bounce. Co-play ranks as high value. Source: zehn-studio26 link above (secondary blog).
- A second blog lists: 7-day play days per user, playtime capped at 60 min/day per experience, spend signal, co-play (friend invites), D1/D7. Myth-busting: CCU does not drive ranking, return frequency does; one long session then no return reads as churn. https://gmmarket.me/community/post/how-the-roblox-discovery-algorithm-actually-works-in-2026-myths-debunked (low-authority; the 60 min cap is unverified).
- Creator Analytics now shows each game's own signal-importance ranking, so read it after launch (Roblox newsroom link above).
- Honest thumbnails matter: bounce on first play hurts distribution (zehn-studio26).

### 2. Benchmarks (conflicting, treat as ranges)
- bloxg.com: D1 good 20% / great 30% / excellent 40%+; D7 good 8% / great 15%; D30 good 3%. https://bloxg.com/guides/roblox-player-retention
- gmmarket.me: target D1 about 12%, D7 about 2.9% (much lower, more realistic for cold traffic). Pick the lower numbers as the launch bar and the bloxg ones as the stretch goal.
- bloxg claims friends-playing players retain 3-5x better than solo (unsourced assertion, direction plausible given the co-play signal).

### 3. Tactics and pricing norms
- Escalating daily reward calendar with day 7/14/30 milestones, streak reset; 3-5 rotating daily quests mixing 5-minute and 15-20 minute goals; weekly/bi-weekly limited events (bloxg link above).
- Game pass tiers: 25-75 R$ impulse, 100-250 R$ "considered" sweet spot, 400-1000+ R$ only for established games. Developer cut is 70%; 100 R$ pass is about $0.27 net. Dev products: tiered bundles with a "best value" tier mid-to-top. Never hard-code prices in UI (regional pricing; read via GetProductInfo). https://generalistprogrammer.com/tutorials/roblox-game-pass-pricing-guide
- First purchase price 25-50 R$ (gmmarket link); 3-4% conversion cited as a healthy signal (same source, unverified).
- Final Swarm live data (Rolimons, 2026-10-01): 50.9M visits, 244k favourites, 97.3% like ratio (177,045 up / 4,953 down), 20 players per server, updated 1 day ago, ~2,400 players at fetch time. Passes: Quick Chest Open 149 R$, VIP 799 R$, Lucky Grading 99 R$. https://www.rolimons.com/game/99521272836282 . Lesson: all three passes are convenience/luck, none sell raw power.
- Final Swarm content cadence: "Mythicals" chest update, Nightmare mode, three difficulty modes, quests, group-reward prompts, codes (unofficial tracker: https://finalswarm.org/updates/ ; details unverified by that site itself).
- Survive The Swarm: codes (Essence, Gold), optional Robux to double end-of-run rewards, 49-unit 30-second team-invincibility and stun-all shop powerups, multiple heroes, in-run level picks. https://survive-the-swarm.wiki/wiki/ . Codes pages: https://beebom.com/survive-the-swarm-codes/

### 4. Player complaints (inference only, no direct quotes found)
- Searches for Final Swarm/Survive The Swarm complaints returned no review text. The 97.3% like ratio suggests few strong complaints on the core loop. Likely friction (unverified): luck-gated chests (hence the "Lucky Grading" and "Quick Chest Open" passes sell relief from it), code-tracker confusion (finalswarm.org notes conflicting trackers), and grind in chest/mythic acquisition. Action: before launch, read Roblox game page comments directly in a browser or ask testers.

### 5. Prioritized changes for Swarm Break (10)
1. Pick-1-of-3 upgrade each level (known gap in COMPARISON.md). Survive The Swarm's in-run picks (wiki link above); it also lifts session quality. Effort M.
2. Friend invite / party hooks and "play with friends" bonus (+% coins when a friend is in the arena), since intentional co-play is a high-weight signal. https://zehn-studio26.com/news/recommended-for-you-retention-update/ Effort M.
3. 7-day escalating daily reward with a day-7 milestone plus streak display. https://bloxg.com/guides/roblox-player-retention Effort S.
4. 3 daily quests (one 5-minute, one 15-minute) paying Gems; also gives a reason to return on days 2-7. Same source. Effort S-M.
5. Fix first 5 minutes: honest thumbnail/icon, no menu before first fight (already 3 s), and a guaranteed first-run win or first evolution to cut bounce. https://zehn-studio26.com/news/recommended-for-you-retention-update/ Effort S.
6. Weekly dated event (limited skin/weapon, 7-day window) to feed the Day 8-28 bucket; planned weekly drop. Roblox newsroom link. Effort M, recurring.
7. Pass lineup copying the proven pattern: Quick-open crate 149 R$, Lucky crate 99 R$, VIP 799 R$ (x2 coins, cosmetic tag), plus a 25-50 R$ starter pack as first purchase; no pay-for-power. Rolimons + generalistprogrammer links. Effort S.
8. "Double end-of-run rewards" dev product, as Survive The Swarm does (wiki link). Repeatable, low price, no balance impact. Effort S.
9. Redeem-codes system plus group reward, seeded at launch (cheap return trigger; codes are the top-searched content for both games, e.g. beebom/dexerto code pages). Effort S.
10. Instrument D1/D7/D28, session length, run count and purchase funnel via analytics events from day one, and compare with Creator Analytics signal rankings. Roblox newsroom link. Effort S-M.

Not recommended yet: trading (needs anti-dupe work, L effort, no evidence it matters for this genre) and private servers (arenas are 8-player; low value until the lobby exists).
