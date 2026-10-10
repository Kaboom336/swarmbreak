# UI rework spec (Patch.client.luau)
Evidence: `refs/aspects/ui/REFERENCES-2.md`. Ranked by impact. Scale only; Y = top edge, X centred unless stated.

1. **Give every element its own zone.**
   - Objective: y 0.012, size (0.32, 0.065).
   - Zone line: y 0.08.
   - Boss bar: y 0.125.
   - Drop/RUN: y 0.70.
   - Toasts: stack upward from y 0.80, at most 3.
   - Delete the King info box.
2. **Candy counter.**
   - Anchor (0,1) at (0.012, 0.975), 0.055h tall.
   - Icon, then the number in #44FF2F italic with a 3 px #0B2A06 stroke.
   - The number rolls up via a NumberValue.
   - Above it, a single white line at 0.028h: scythe and carry.
   - The "+X" gain floats to the right of the counter.
3. **Panels.**
   - Size (0.44, 0.54), aspect ratio 1.45.
   - Header strip 0.12h with a gradient and an icon:
     - Shop: #FFB347 to #FF7A00
     - Index: #B57BFF to #7B2FF7
     - Daily: #8DF816 to #6BF103
     - Haunt: #FF5A5A to #C0101A
   - Body #1C1430, stroke #F28C1A.
   - Close button: red X #DB2730 in the header.
   - 0.3 s Back pop, dim 0.5.
   - Hide left buttons and counter while open.
4. **King bar.**
   - It is the only HP readout. Delete the bottom-right King line and the flat bar.
   - Size (0.46, 0.04) at y 0.125.
   - Track #2A0A12, fill #C8192D to #FF783C.
   - Crown cap, with "PUMPKIN KING 390/390" inside.
5. **Fight.**
   - Replaces the centre modal with a bar (0.30, 0.035) at y 0.62, plus a pulsing "TAP!".
   - Bar is lime when winning, red when losing.
   - On mobile, tapping anywhere counts.
6. **Buttons (3 at most).**
   - Shop and Index pills (0.085, 0.065) at x 0.012, y 0.42 and 0.50.
   - Use icon images, not emoji.
   - Red #E0204A "!" badge.
   - Daily appears only when claimable.
7. **Timers.**
   - Anchor (1,1) at (0.988, 0.975).
   - Moon line 0.04h. Turns red in the last 10 s.
   - Spooky line 0.028h #C59BFF. While Spooky is active it shows "x2" in pulsing orange.
   - Boost tray to the left, 0.045h icons.
8. **Fonts.**
   - FredokaOne by default. LuckiestGuy for RUN!! and TAP!.
   - Stroke #1A1030, 3 px (2 px on small text).
9. **Mobile.**
   - UIScale = clamp(vpY/720, 0.75, 1.15).
   - Timers move to the top right.
   - Buttons become icon-only squares.
   - Keep x > 0.72, y > 0.62 clear.
10. **Admin.**
   - **Who sees it.** The server sets `IsAdmin` when UserId = 405476801 or the session is Studio. The gear button (0.045, 0.07) shows only when `IsAdmin` is set.
   - **Panel buttons** (grey #8A8A8A header):
     - Reset my progress: the first click turns it into "Sure? Click again" for 3 s.
     - Give candy.
     - Unlock all zones.
     - Start King Night.
     - Start Spooky Hour.
   - **Server side.** `RemoteFunction "Admin"(action, amount)`:
     - Re-check `IsAdmin`, rate-limit to 1/s, then reuse the PatchDebug actions `candy`, `zone`, `king`, `spooky`.
     - Reset steps: `Bases.clear`, clear the carry, `applyData(player, {purchases=receiptsOf[player]})`, `savePlayer`, respawn.
