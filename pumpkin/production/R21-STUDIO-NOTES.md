# R21 Studio smoke test (Claude, 2026-10-10)
- Loads clean, no console errors; 280 wild pumpkins; tutorial step 1 shows.
- King Night via debug: warning + JOIN RAID button + big HP bar + telegraph lanes work.
- Fix: King Night tint is too dark/red (hard to read, against daytime rule). Use a lighter red-orange ColorCorrection (TintColor ~#FFC9B8, Brightness 0), keep the sky blue-purple, not black.
- Fix: King HP shown 3 times (small billboard over the King, big top bar, bottom-right chip). Keep the big top bar only during the fight; hide the chip and billboard bar.
- Fix: "15 hits OR 3% damage" board text is cut off behind the King's plinth; move it beside the plaza.
