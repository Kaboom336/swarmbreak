## R3 social: invites, friends, sharing (2026-10-01)

Method: 8 WebSearch calls (result titles/URLs only; most pages not readable), 1 WebFetch (bloxg.com, already used in r2). Claims marked "title only" rest on a search-result title, not page text. Not repeated: co-play coin multiplier (backlog #6, Task 7 in r2-codex-tasks.md), codes with requirements (#1), group/Discord gap (r2-critique item 5).

### 1. What the evidence says
- Roblox ships three first-party social hooks. (a) Invite prompts via SocialService (title only: https://create.roblox.com/docs/production/promotion/invite-prompts, API https://create.roblox.com/docs/reference/engine/classes/SocialService). (b) A Friend Referral System that lets a creator reward players who bring friends, "like bonus currency or rewards" (https://x.com/Bloxy_News/status/1915125179195519358; docs title: https://create.roblox.com/docs/production/promotion/referral-system; announcement https://devforum.roblox.com/t/announcing-the-new-friend-referral-system-for-your-experiences/3623795). (c) A Friend Rewards terms page (title only: https://en.help.roblox.com/hc/en-us/articles/35146071523604-In-Experience-Friend-Rewards-Program-Terms). Payout/eligibility rules are UNREAD: must-read below.
- Ranking: intentional co-play (invites, friend joins, private servers) counted in discovery (https://www.maxpowergaming.co/post/why-roblox-s-new-discovery-algorithm-favors-games-that-bring-friends-together, secondary; also r2-retention.md). So an invite is worth more than the reward it costs.
- Creator Rewards pays for engagement and growth (title only: https://create.roblox.com/docs/creator-rewards, https://rolearn.dev/insights/roblox-creator-rewards-payout-guide/). No rate quoted here; do not plan revenue from it yet.
- Community: a Discord community retains "3-5x" non-community players and buys 4x more (claim by https://bloxg.com/guides/roblox-community-building; unverified, treat as est.). It advises a Discord join button in-game, a #gameplay clips channel, and giveaways to drive invites at 100-500 members.
- Rewarding Discord joins is a policy question (thread: https://devforum.roblox.com/t/is-awarding-the-player-with-in-game-rewards-for-joinning-a-discord-group-allowed/1814996, devforum blocked, content unread). Safe path: reward Roblox group membership (title only: https://devforum.roblox.com/t/how-do-i-reward-players-when-they-join-group/1147132), not Discord.
- Clips: Roblox is building short-form video and "Moments" inside the platform (https://www.tubefilter.com/2025/09/09/roblox-is-entering-its-tiktok-era/, https://tech.yahoo.com/gaming/articles/roblox-announces-tiktok-short-form-211205198.html). Codes spread as TikTok content (#robloxcodes, https://www.tiktok.com/tag/robloxcodes, title only). Promo tactics: https://bloxg.com/promote-roblox-game (title only). No Swarm-genre numbers found; the clip value is est.

### 2. What our code does today (game/src)
- PlayerData.endRun (ServerStorage/PlayerData.luau ~l.560-577): only the "Friendly Backup" quest (Shared/Quests.luau l.85) ticks when a friend is in the server. It pays nothing during the run and shows no prompt.
- Revive is Robux-only: Shop.server.luau canRevive (l.35) and Hud.client.luau reviveBtn (l.844). A dead player waits for the wave to end; no teammate can revive. WaveManager.server.luau hum.Died (l.167) and respawnAll (l.137) own death handling.
- Run summary panel exists (Hud.client.luau l.871) and has no invite button. No SocialService, referral or group code anywhere (grep: none).
- Shared/Codes.luau does not exist yet (backlog #1).

### 3. What to add first (ranking, est.)
1. Invite button on the run summary and on death (cheapest, uses a platform feature, feeds the co-play signal). Show only when the player is alone in the server.
2. Teammate revive (hold E near a downed ally, 5 s, full-wave cooldown). It makes friends matter in the run, creates clip moments, and frees the Robux revive to be the fallback (keep it; a free revive lowers its sales, so test both, est.).
3. Friend referral reward via the Roblox system: invitee-joined grants the inviter crate/gems once per friend, capped per day. Needs the unread docs first.
4. Group-join code and "follow/like" codes inside Codes.luau, with a hype code before each weekly drop (r2 #1).
5. Clip hooks: a "Wave X cleared" end card with a screen-safe layout for recording, a boss-kill flash, a hide-HUD toggle. Cheap and helps TikTok/Shorts.
6. Creator Rewards and influencer outreach after launch metrics hold (see release step 5 in COMPARISON.md).

### 4. Changes (4-8)
1. Invite prompt on run summary + death screen. Build: Shared/Invite.luau pure `shouldShow(playersInServer, lastShownAt, now, cooldown)`; Hud.client.luau button calls SocialService:PromptGameInvite; guard with CanSendGameInviteAsync in pcall. Evidence: https://create.roblox.com/docs/production/promotion/invite-prompts. Effort S. Codex (rules + test), Claude (button look).
2. Teammate revive. Build: Shared/Revive.luau `canRescue(distance, rescuerAlive, targetDowned, secondsHeld)`; WaveManager.server.luau intercepts Died to enter a 20 s "downed" state (est.) before respawn; ProximityPrompt on the body. Evidence: co-play is a ranking signal (https://zehn-studio26.com/news/recommended-for-you-retention-update/) and Robux revive already exists (Shop.server.luau l.35). Effort M. Codex.
3. Friend referral reward. Build: ServerScriptService/Referral.server.luau + Shared/ReferralRewards.luau `rewardFor(count, today)` with a daily cap; ProfileSchema field `Referred`. Evidence: https://x.com/Bloxy_News/status/1915125179195519358, rules at https://create.roblox.com/docs/production/promotion/referral-system (read first). Effort M. Codex.
4. Friend-in-run payoff, not just quest. Build: extend Task 7 CoPlay.coinMult to also give a one-time "squad up" gem bonus after a wave-10 win with a friend; wire PlayerData.endRun l.570 to it. Evidence: r2-retention.md co-play weighting. Effort S. Codex.
5. Group-join reward code. Build: Codes.luau entry type "group" checking Player:IsInGroup(groupId) server-side; one-time crate; a "Join our group" line in the lobby. Evidence: https://devforum.roblox.com/t/how-do-i-reward-players-when-they-join-group/1147132 (title only); avoid Discord-gated rewards pending policy. Effort S. Codex.
6. Hide-HUD / clip mode + end card. Build: Settings.luau `ClipMode` flag; Hud.client.luau hides the HUD except damage numbers; a wave-cleared card on summaryPanel. Evidence: clip culture, https://www.tubefilter.com/2025/09/09/roblox-is-entering-its-tiktok-era/. Effort S. Claude.
7. Lobby community board. Build: Roblox group link text, "latest code" line, weekly board (WeeklyBoard.luau) shown at lobby. Evidence: https://bloxg.com/guides/roblox-community-building (3-5x retention, est.). Effort S. Claude.
8. Social analytics. Build: Telemetry events invite_shown, invite_sent, revive_given, referral_joined, to learn which hook works. Evidence: https://create.roblox.com/docs/discovery (via r2-process.md). Effort S. Codex.

### Must-read later
- https://create.roblox.com/docs/production/promotion/invite-prompts
- https://create.roblox.com/docs/production/promotion/referral-system
- https://en.help.roblox.com/hc/en-us/articles/35146071523604-In-Experience-Friend-Rewards-Program-Terms
- https://devforum.roblox.com/t/announcing-the-new-friend-referral-system-for-your-experiences/3623795
- https://create.roblox.com/docs/creator-rewards
- https://rolearn.dev/insights/roblox-creator-rewards-payout-guide/
- https://gameranx.com/updates/id/536206/article/roblox-updates-friend-referral-system-for-games/
