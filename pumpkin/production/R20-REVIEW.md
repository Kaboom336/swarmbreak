# R20 review findings to fix (verified by a reviewer; paths under pumpkin/giant/src/)
1. Swap and Sell prompts collide on E with Pick up (Patch.server.luau ~2716-2731). Swap = Q / ButtonX, Sell = E, Exclusivity AlwaysShow on both; hide PickupPrompt while carrying with a full pen (client refreshPrompts ~2740).
2. Fight is won by tap rate; an autoclicker always wins (server ~3996-4072). Roll on the server: won = math.random() < chance * clamp(taps / Config.Fight.expectedTaps, 0.25, 1); chance capped at 0.9.
3. SellPerIncome 30 -> 1800 is global (Config:190; server 1222, 2222, 2457, 4516, 4632, 5213). Give the full-pen sell and Witch sell their own constant (about 300 s of the pet's income); keep StealOwnerShare and refunds on 30 s. Re-check gate costs against pet income.
4. Carried items are lost on leave (server ~990-1005, snapshot ~1060): on PlayerRemoving put carried Jack/Hoard pumpkins back on free plots (or save them in snapshot and restack on load); remove the dead migration or make it real.
5. Tier 3+ scythe shrinks main swing reach (server ~3086-3132): pick the main target with the old 11-stud / dot > -0.2 rule; arc range and dot >= 0.5 only for the extra targets.
6. Center message queue can freeze forever (client ~550-554, 4899-4901): pcall the body of banner()/showDaily() and always Center.release().
7. A second guardian stalls while a fight runs (server ~3985-3988, 4285-4299): if fights[player] is set, the other guardian gives up (giveUp(g, false)); handle the "stun" state in Heartbeat with the inOwnBase and leash checks.
8. Fallback pets sink into the pedestal (server ~1984-1986): after resizing, CFrame = plot top + (0.15 + newY/2) before dressJack.
9. Wild pumpkins have no refill safety net (server ~3044-3047): add a slow loop every 8 s calling Wild.spawnOne per zone up to its cap.
10. Death during the wake cutscene leaves the camera on the dead body (client ~5628-5640): if saved.subject is gone, use the new Humanoid and CameraType Custom.
11. RotatingOrders that need carried farm pumpkins (Sell 10 pumpkins, Sell a stack of 5, Sell a brewed pumpkin, Brew a Candy or Cursed): remove them from the pool.
12. Tutorial step 1 reward 120 makes the Iron Scythe instant (Config ~585): set the reward to 20.
13. Pens-full logic hardcodes 6 (client objective): use the real plot count; only show it for nest/Jack items.
