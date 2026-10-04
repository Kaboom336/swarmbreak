# Enemy pool hitch shot list

Run this in a local Play session with the MicroProfiler open; no capture is produced by the
headless acceptance gate.

1. Start recording before the wave 8 final pack dies, keeping the enemy count and frame-time
   graphs visible.
2. Record continuously through the wave 9 intermission/refill and every wave 9 spawn burst.
3. Continue through the wave 10 intro and its largest simultaneous gate burst.
4. Export the trace, find the worst frame between the first wave 8 burst and the last wave 10
   burst, and capture that frame expanded around Heartbeat.
5. Log the worst-frame duration, wave, alive count, queued spawn count, device, and graphics
   quality beside the screenshot so before/after runs use the same conditions.

The pass shot is the expanded worst frame plus a wide gameplay frame showing the matching wave
and alive count. Compare it with the unpooled 275 ms / 27-alive observation from Play.
