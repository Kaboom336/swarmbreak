## R2 process: how hits get made, and a release plan + game-feel checklist for Swarm Break

Date: 2026-10-01. Evidence-first. Sources are third-party summaries where devforum is blocked; those are marked (secondary). No CCU/revenue numbers are claimed.

### A. What the Roblox algorithm rewards (builds on RESEARCH.md "friends first")
- Roblox's own docs list: play-through rate, first-play bounce rate (negative), play days and playtime per user in D1 / D2-7 / D8-28 windows, co-play, spend days, Robux spent. Improving retention/engagement/monetization "directly enhances" recommendation signals. Test with new cohorts first (explore), expand if signals hold. https://create.roblox.com/docs/discovery
- The "Recommended For You" window grew from 7 to 28 days; QPTR was replaced by PTR plus first-play bounce (secondary, verify in Creator Analytics yourself). Only organic RFY joins count: ad traffic and referrals are excluded from those signals. Data lives at Creator Analytics > Acquisition > Home Recommendations. https://zehn-studio26.com/news/recommended-for-you-retention-update/
- Earlier (Apr 2025) version counted 7-day playtime (benefit capped at first 60 min/day), play days, spend days and **intentional co-play days** (invites, friend joins, private servers; not random matchmaking). https://www.maxpowergaming.co/post/why-roblox-s-new-discovery-algorithm-favors-games-that-bring-friends-together (secondary)
- Implication: the first minute (bounce), D1/D7/D28 return, and friend-invites matter more than raw visits. Paid ads buy visits but do not feed these signals.
- Thumbnails: Roblox uses a multi-arm bandit ("thumbnail personalization"), up to 5 thumbnails (min 2), picks winners by qPTR within hours; Roblox reported avg +8.5% qPTR. https://gamesbeat.com/roblox-will-let-game-devs-personalize-thumbnails-to-attract-more-players/ Docs: https://create.roblox.com/docs/production/publishing/thumbnails (not fetched). Icon/title A/B is only a devforum feature request (not built-in): https://devforum.roblox.com/t/add-ab-testing-and-stats-for-titles-icons/4778726 (blocked, title only).
- Retention logic of CCU: CCU ~ plays/hour x session length; add hooks at 3, 10, 30 min; push marketing in the 4-9 PM window. Rough (unverified) benchmarks: new game 20-50 CCU month one, 100-500 after marketing, 1,000+ for featured. https://bloxg.com/problems/roblox-game-low-ccu (estimates from a guide, treat as rough)
- Growth playbook topics (ads ROI, update cadence, Discord/codes, influencers) exist at https://rolearn.dev/guidance/scaling-1k-to-100k/ but the page body was not readable; no numbers taken from it.

### B. What survivor-likes teach (power fantasy, curve)
- Vampire Survivors: "0 to 100 power fantasy in every run"; growth must be seen and heard (screen density, audio); first decision within ~1-2 min; reward cadence so "few seconds" never pass without a win; mix chosen upgrades with random chest windfalls; one verb (movement). Weak spot: repetitive early minutes and grind toward permanent upgrades. https://www.kokutech.com/blog/gamedev/design-patterns/power-fantasy/vampire-survivors
- Difficulty is a pre-authored, learnable wave table tied to the clock (429 rows documented), 30-min runs, slot limits (6 weapons / 6 passives), evolutions as mastery; cheap death + gold for permanent unlocks. https://teemo.dev/game-design/vampire-survivors/
- Gambling-psychology angle (variable rewards, near-constant drops) in Vampire Survivors: https://theconversation.com/vampire-survivors-how-developers-used-gambling-psychology-to-create-a-bafta-winning-game-203613 (search result only, not opened). Halls of Torment/Brotato write-ups were only found as reviews (https://en.wikipedia.org/wiki/Halls_of_Torment), no design numbers: gap.
- Gap vs our COMPARISON.md: we still lack pick-1-of-3 per level. That is the single biggest survivor-like feel and decision lever.

### C. Game-feel checklist (14 items; tune as Studio playtests, values are starting points)
1. Hit stop: freeze 40-80 ms on heavy hits only (bosses, big crits), not on every shot. https://egmatic.com/blog/how-to-make-your-game-feel-good
2. Scale every effect to event size (pistol vs rocket vs boss death); juice is transient, not a resting state. https://egmatic.com/blog/how-to-make-your-game-feel-good
3. Stack 5-8 tiny responses inside ~100 ms per hit (flash, sound, particle, number, knockback, squash). https://atskills.one/gamedev-skills/game-feel
4. Screen shake: small, fast-settling, scaled; short to avoid motion sickness; add an off/low setting. https://egmatic.com/blog/how-to-make-your-game-feel-good
5. Knockback / recoil on enemies, tiny on player; swarms should visibly part and pile. https://atskills.one/gamedev-skills/game-feel
6. Damage numbers: pooled, color-coded (normal/crit/heal), pop then drift; cap count per second so a swarm stays readable. https://mtw1man2.itch.io/godot-4-combat-hit-feel-toolkit-hitstop-screen-shake-damage-numbers
7. Kill feedback: burst into light/sparks in enemy color (no blood, PLAYBOOK rule), plus a distinct kill sound; pitch up on chained kills. https://github.com/stxtxm/bitbrawler/issues/457
8. Layered audio: separate fire, impact, kill, pickup and level-up layers; slight random pitch so rapid fire is not repetitive. https://www.kokutech.com/blog/gamedev/design-patterns/power-fantasy/vampire-survivors (audio as "symphony of destruction")
9. Pickup vacuum: XP/coin magnet with a satisfying "suck-in" and rising pitch; a rare screen-wide vacuum item. https://www.kokutech.com/blog/gamedev/design-patterns/power-fantasy/vampire-survivors
10. Visible power growth: new weapon/evolution must change the screen (bigger arcs, more projectiles) within seconds of picking it. same source.
11. First decision in 1-2 min, fighting within 3 s (we do: Config.WaveStartDelay). same source.
12. Reward cadence: something lights up every few seconds (kills, drops, level bar, wave clear banner); bigger payoffs at boss and every 5 waves. same source.
13. Input forgiveness: buffer button presses and allow late inputs, windows well under 150 ms. https://egmatic.com/blog/how-to-make-your-game-feel-good
14. Telegraphs and legibility: clear enemy wind-ups, one health bar style, keep the player readable inside the swarm. https://teemo.dev/game-design/vampire-survivors/ ("legibility")
15. Death and retry cheap: instant restart, show what you earned, one "one more run" prompt. https://teemo.dev/game-design/vampire-survivors/

### D. Release process for Swarm Break (today 2026-10-01 to launch + 1 month)
Phase 0, now to week 1: finish a playable slice. Pick-1-of-3 level-up, hit-stop + damage numbers + kill burst (items 1-7), lobby place, 8-player arena via TeleportService. Zion does first Publish to a private/unlisted place. Exit test: a stranger fights in 3 s and understands the loop without text.
Phase 1, week 1-2: prototype playtests. 5 friends/family kids on private servers, one session each, watch silently; log where they quit (first 60 s, wave 3, first boss). Fix top 3 each loop, re-test within 48 h. Instrument events (wave reached, quit time, upgrade picked) before opening wider.
Phase 2, week 2-3: closed test with Discord. Create Discord + Roblox group, invite 20-50 players, private-server play, collect friend-invite behaviour (co-play is a ranking signal). Add an in-game invite-friends prompt and a small shared-run bonus (also helps session length).
Phase 3, week 3-4: soft launch. Public but unadvertised; set accurate title/description/genre, upload 3-5 distinct thumbnails and enable thumbnail personalization; icon from one clear action shot of the swarm. Watch Creator Analytics: D1 retention, first-play bounce, average session, PTR/qPTR, and the Home Recommendations tab. Gate for scaling: do not buy ads until bounce and D1 look healthy (thresholds are ours to set from our own first data, no published ones). Placeholder prices until data (PLAYBOOK).
Phase 4, launch week: ship a content drop (new boss/weapon pack + a world or class), post codes in Discord, short clips for TikTok/Shorts (gameplay of the biggest screen-filling moment). Time pushes 4-9 PM in the main audience time zone (secondary guide above). Small sponsored-ads test only after retention check; ads are excluded from the organic RFY signals, so treat them as a boost, not the ranking engine.
Phase 5, month 1 cadence: weekly update (plan from COMPARISON.md), each with a code and a patch-note post; read analytics every Monday; on D7/D28 retention compare cohorts before and after each update; drop or fix features that raise bounce. Add the 28-day lens: aim at returning players on days 8-28 (daily quest, evolution shards, class unlock), not just day 1.
Kill / pivot rule: if after 2 weeks of soft launch and 2 content updates D1 and bounce are not improving, fix the first 3 minutes before any more content.

### E. Unknowns / caveats
- Exact thresholds for good D1/D7 on Roblox: not found in a readable source. Use own baseline.
- devforum announcements (Recommended For You, thumbnails) blocked; algorithm facts come from Roblox docs plus secondary writeups with differing details (7 vs 28 day, QPTR vs PTR). Check Creator Analytics for which metrics your account shows.
- Hit-stop/shake numbers are generic game-dev guidance, not Roblox-specific; Roblox cannot freeze time, so emulate by pausing enemy animations/velocity for the duration.
